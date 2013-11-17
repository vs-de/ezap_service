#####
# Copyright 2013, Valentin Schulte, Leipzig
# This File is part of Ezap.
# It is shared to be part of wecuddle from Lailos Group GmbH, Leipzig.
# Before changing or using this code, you have to accept the Ezap License in the Ezap_LICENSE.txt file 
# included in the package or repository received by obtaining this file
#####

module Ezap::Service::Base
  include Ezap::Base
  include Ezap::GlobalMasterConnection
  include Ezap::WrappedZeroExtension
  #include Ezap::SubscriptionListener
  
  @sockets ||= []
  #@child_classes = []

  class << self
    #attr_reader :child_classes, :remote_tree
    attr_reader :remote_tree
  end

  # adapter_ids might be utilized for ezap_guids in combination with object_id
  attr_reader :properties, :adapters

  #(TODO: remove this after test-phase?)
  @remote_tree = {}
  
  def self.inherited base
    #@child_classes << base
    base.instance_variable_set('@remote_tree', {})
  end
  
  def initialize
    @adapters = []
    service_init!
  end

  def service_init! name=nil
    name ||= self.class.to_s.to_sym
    #TODO: must be from yml
    #TODO: maybe it can be received over gm-connection as default
    @properties = {host: '127.0.0.1'}
    #cfg = Ezap.config[name] || {}
    @properties.merge!(name: name)
    @properties.merge!(sign_on!).symbolize_keys!
  end

  def sign_on!
    asw = gm_request(:svc_reg, @properties).symbolize_keys!
    unless asw[:address]
      raise "requested address - received #{asw}"
    end
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
    @loop_sock = make_socket(:rep)
    @loop_sock.bind(@properties[:address])
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

  def self._add_service_object_class klass
    @remote_tree.merge!(
      klass.top_class_name => {class: klass, models: {}} #models -> instances
    )
  end

  def _add_service_object o
    hsh = self.class.remote_tree[o.class.top_class_name][:models]
    new_key = hsh.keys.max.to_i+1
    hsh[new_key] = o
    new_key
  end

  def _remove_service_object i
    hsh = self.class.remote_tree[o.class.top_class_name][:models]
    hsh.delete(i)
  end

  def _add_adapter
    @adapters.push(@adapters.max.to_i.succ).last
  end

  def _remove_adapter i
    @adapters.delete(i)
  end

  def object_hash
    self.class.remote_tree
  end

  def detailed_status
    <<STATUS
    state: #{@state}
----adapters:
    #{adapters.inspect} 
----known service classes:
    #{Ezap::Service::Base.subclasses.inspect}
----service_objects:
    #{object_hash.inspect}
STATUS
  end

  def model_creation_reply _class, *args 
    {m_id: self._add_service_object(_class.new(*args)), args: args}
  end

  def model_list_creation_reply _class, args_list
    args_list.inject([]) do |arr,args|
      args = [args].flatten
      arr << model_creation_reply(_class, *args)
    end
  end

  class ServiceObject
    def self.inherited base
      service_class = Ezap::Service::Base.subclasses.find do |klass|
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

    def _adp_sign_on
      {reply: @service._add_adapter}
    end
    
    def _adp_sign_off adp_id
      @service._remove_adapter adp_id
      {reply: :ack}
    end

    def ping
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

    def _adp_model_send model_class, id, cmd, *arg
      @service.get_model(model_class, id).send(cmd, *args)
    end

    def _detailed_status
      {reply: @service.detailed_status}
    end
    
    def stop
      #@service.stop
      {reply: :ack, after_response: :stop}
    end

  end

  class Dispatcher < CoreDispatcher
  end
end

