#####
# Copyright 2013, Valentin Schulte, Leipzig, Germany
# This file is part of Ezap.
# Ezap is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 3 
# as published by the Free Software Foundation.
# You should have received a copy of the GNU General Public License
# in the file COPYING along with Ezap. If not, see <http://www.gnu.org/licenses/>.
#####

module Ezap::Service::Base
  include Ezap::Base
  include Ezap::GlobalMasterConnection
  include Ezap::WrappedZeroExtension
  #include Ezap::SubscriptionListener
  
  DEFAULT_CONFIG_FILE = 'ezap_service.yml'
  @sockets ||= []
  #@child_classes = []

  class << self
    #attr_reader :child_classes, :remote_tree
    attr_reader :ezap_remote_tree
  end

  # adapter_ids might be utilized for ezap_guids in combination with object_id
  attr_reader :properties, :adapters

  #(TODO: remove this after test-phase?)
  @ezap_remote_tree = {}

  @@container_list = []

  def self.included base
    base.instance_variable_set('@ezap_remote_tree', {})
    class << base
      attr_reader :ezap_remote_tree
    end
    @@container_list << base
    @@container_list.uniq!
    base.extend ExportCM

    ## app cfg
    base.send(:include, Ezap::AppConfig)
    base.default_app_config_name DEFAULT_CONFIG_FILE
    unless base.infiltrate base, 2
      puts "no #{DEFAULT_CONFIG_FILE} found, using auto/default settings"
    end
    ## app cfg
  end

  def self.container_list
    @@container_list
  end
  
  def initialize
    @adapters = []
    service_init!
  end

  def service_init! name=nil
    name ||= self.class.to_s.to_sym
    #TODO: must be from yml
    #TODO: maybe it can be received over gm-connection as default
    @properties = self.class.app_config

    unless @properties[:host]
      host = auto_ip
      puts "auto-using addr: #{host}"
      @properties[:host] = host
    end
    build_loop_sock
    #cfg = Ezap.config[name] || {}
    @properties.merge!(name: name)
    @properties.merge!(sign_on!).symbolize_keys!
  end

  def gm_ip
    Ezap.config.global_master_address.match(/:\/\/(.*):.*/)[1]
  end

  def auto_ip
    port = gm_request(:auto_ip)
    s = TCPSocket.new(gm_ip, port)
    ip = s.read
  end

  def build_loop_sock
    @loop_sock = make_socket(:rep)
    @loop_sock.bind("tcp://#{@properties[:host]}:0")
    addr = ''
    @loop_sock.getsockopt(ZMQ::LAST_ENDPOINT, addr)
    addr[-1] = '' if addr[-1] == "\u0000"
    @properties[:address] = addr
  end

  def sign_on!
    asw = gm_request(:svc_reg, @properties).symbolize_keys!
    #unless asw[:address]
    #  raise "requested address - received #{asw}"
    #end
    @properties.merge!(asw)
  end
  
  def sign_off!
    asw = gm_request(:svc_unreg, self.class.to_s)
    raise "signed off - received #{asw}" unless asw == 'ack'
  end

  def start
    start_rep_loop
  end

  def start_rep_loop
    _prepare_loop
    state!(:running)
    _rep_loop
  end

  def restart
    stop
    service_init!
    start
  end

  def stop
    sign_off!
    state!(:halt)
    close_sockets
  end

  def _prepare_loop
    puts "listen on #{@properties[:address]}"
    @dispatcher = self.class::Dispatcher.new(self)
  end

  def _rep_loop
    while _running?
      _rep_loop_body
    end
  end
  
  def state!(st)
    @state = st.to_sym
  end

  ##TODO: should be working over network like shutdown is
  #def running?
  #end

  def _running?
    @state == :running
  end

  def _par_rep_loop_body
    
  end

  def _rep_loop_body
    req = @loop_sock.recv_obj
    disp = _dispatch_request(req)
    print "sending...";$stdout.flush
    @loop_sock.send_obj(disp.has_key?(:reply) ? disp[:reply] : disp)
    puts "sent"
    hook = disp[:after_response]
    hook && send(hook)
  end

  def _dispatch_request req
    return {error: "wrong request data format"} unless req.is_a?(Array)
    cmd = req.shift
    print "recvd cmd:#{cmd}|"
    raise 'initializer is forbidden' if cmd == 'initialize'
    #TODO: we ignore the adapter-id here for now
    if cmd.start_with?('adp_')
      @dispatcher.send(cmd.sub(/^adp_/,''), *(req[(1..-1)]))
    else
      @dispatcher.send(cmd, *req)
    end
  rescue Exception => e
    puts "Exception: #{e.message}"
    puts e.backtrace.join("\n")
    {error: e.message}
  end

  module ExportCM
    def _add_service_object_class klass
      @ezap_remote_tree.merge!(
        klass.top_class_name => {class: klass, models: {}} #models -> instances
      )
    end
  end

  def _add_service_object o
    hsh = self.class.ezap_remote_tree[o.class.top_class_name][:models]
    new_key = hsh.keys.max.to_i+1
    hsh[new_key] = o
    new_key
  end

  def _remove_service_object i
    hsh = self.class.ezap_remote_tree[o.class.top_class_name][:models]
    hsh.delete(i)
  end

  def _add_adapter
    @adapters.push(@adapters.max.to_i.succ).last
  end

  def _remove_adapter i
    @adapters.delete(i)
  end

  def object_hash
    self.class.ezap_remote_tree
  end

  def detailed_status
    <<STATUS
    state: #{@state}
----adapters:
    #{adapters.inspect} 
----known service classes:
    #{Ezap::Service::Base.container_list.inspect}
----service_objects:
    #{object_hash.inspect}
STATUS
  end

  def model_creation_reply _class, *args 
    {m_id: self._add_service_object(_class.new(*args)), args: args}
  end

  #TODO: define model not found exception
  def get_model _class, id
    model = object_hash[_class][:models][id] rescue nil
    return model if model
    raise "model requested could not be found [class#id]: [#{_class.inspect}##{id.inspect}]"
  end

  def model_list_creation_reply _class, args_list
    args_list.inject([]) do |arr,args|
      args = [args].flatten
      arr << model_creation_reply(_class, *args)
    end
  end

  class ServiceObject
    def self.inherited base
      service_class = Ezap::Service::Base.container_list.find do |klass|
        base.to_s.split('::').reverse.any?{|p|klass.to_s.split('::').reverse.include?(p)}
      end
      raise "error: No service-class found in any parent module of #{base}" unless service_class
      service_class._add_service_object_class base
    end

    def initialize *args
      
    end

    #def self.create service, *args
    #  service._add_service_object(new(*args))
    #end
    
  end

  class CoreDispatcher
    attr_reader :service
    def initialize srv
      @service = srv
    end

    def ping
      {reply: :ack}
    end
    
    def stop
      #@service.stop
      {reply: :ack, after_response: :stop}
    end

    def _adp_sign_on
      {reply: @service._add_adapter}
    end
    
    def _adp_sign_off adp_id
      @service._remove_adapter adp_id
      {reply: :ack}
    end

    def _adp_model_init adp_id, model_class, *args
      m = @service.object_hash[model_class][:class].new
      puts "adding model..."
      oid = @service._add_service_object(m)
      {reply: oid}
    end

    def _eval str
      obj = eval(str)
      {reply: obj.respond_to?(:to_msgpack) ? obj : obj.inspect}
    end

    def _adp_model_send adp_id, model_class, id, cmd, *args
      {reply: @service.get_model(model_class, id).send(cmd, *args)}
    end

    def _detailed_status
      {reply: @service.detailed_status}
    end
    
  end

  class Dispatcher < CoreDispatcher
  end
end

