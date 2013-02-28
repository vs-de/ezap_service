#####
# Copyright 2013, Valentin Schulte, Leipzig
# This File is part of Ezap.
# It is shared to be part of wecuddle from Lailos Group GmbH, Leipzig.
# Before changing or using this code, you have to accept the Ezap License in the Ezap_LICENSE.txt file 
# included in the package or repository received by obtaining this file.
#####
class Ezap::Service::GlobalMaster < Ezap::Service::Master
  include Ezap::GlobalMasterConnection

  PUB_CHANNELS = Hash.new{|h,k|"/gms/#{k}"}.merge({}
    #main: '/gms/main/'
    #debug: 'gms/log/debug'
    #oob: = '/oob/'
  )

  def initialize
    raise "global master cannot have an instance!"
  end

  class <<self
    attr_accessor :state, :services
  end

  PID_FILE=File.join(Ezap.config.root, 'var', 'pids', 'global_master.pid')
  LOG_FILE=File.join(Ezap.config.root, 'log', 'global_master.log')

  #TODO: 
  #     1) use a logger object
  #     2) use cache-system
  #service identifier:
  #type/id/
  #should sign off

  @services = {}
  
  #States: 
  # -running
  # -stopped

  @config = Ezap.config.global_master_service
  @state = :stopped
  @log_file
  
  module ClassMethods
    include Ezap::WrappedZeroExtension

    def daemonize
      raise "Error: pidfile already exists!" if File.exists?(PID_FILE)
      Process.daemon
      f = File.open(PID_FILE, 'w');f.write(Process.pid);f.close
      @log_file = File.open(LOG_FILE, 'a')
      $stdout = $stderr = @log_file
    end

    def start opts={}
      opts = {:daemon => true}.merge(opts.symbolize_keys!)
      puts "ezap global master starting..."
      daemonize if opts[:daemon]
      super
    end

    def close_log
      @log_file && @log_file.close
    end

    def state!(st)
      @state = st.to_sym
    end

    #TODO: should be working over network like shutdown is
    def running?
      @state == :running
    end

    def loop_rep
      #exit_state = false
      puts "GM starting loop rep" if running?
      while running? do
        loop_rep_body
      end
    end

    def loop_rep_body
      #puts "start inner loop_rep"
      req = @rep.recv_obj
      disp = dispatch_request(req)
      print "|sending...";$stdout.flush
      @rep.send_obj(disp[:reply] || disp)
      puts "sent"
      hook = disp[:after_response]
      hook && send(hook)
    rescue => e
      state!(:failure)
      raise "GM Fatal: #{e.message}"
    end

    def dispatch_request req
      return {error: "wrong request data format"} unless req.is_a?(Array)
      cmd = req.shift
      print "recvd:#{cmd}|"
      GmDispatcher.send(cmd, *req) 
    rescue Exception => e
      {error: e.message}
    end

    def service_count
      @services.values.map(&:size).sum
    end

    #sends to running instance
    #TODO:
    #crude hack, undry
    #see service gm_request
    #maybe should all be initialized when class is used, see start
    def shutdown
      sock = make_socket(:req)
      sock.connect(Ezap.config.global_master_address)
      sock.send(MessagePack.pack([:shutdown]))
      puts "stop asw: #{MessagePack.unpack(sock.recv)} "
      sock.close
    end

    def send_public channel, obj
      chan = PUB_CHANNELS[channel]
      puts "GM: send pub: #{chan}"
      @pub.send(chan+MessagePack.pack(obj))
    end

    def shutdown_system
      @pub.send()
    end
    
    def assign_service_port rs
      range = @config[:opts][:sub_port_range] rescue nil
      raise "no port range defined but requested" unless range
      @assigned_ports ||= []
      min = range[:start]
      max = range[:end]
      cur = min
      while @assigned_ports.include?(cur);cur+=1;end
      raise "port range exceeded" if cur > max
      @assigned_ports << cur
      rs.set_port(cur)
    end

    def stop
      state!(:stopped)
      puts "stopping GM."
      close_sockets
      puts "sockets closed."
      close_log
      File.delete(PID_FILE)
    end

    #should respond with an overview of the current state/config
    def summarize
      services
    end

  end

  extend ClassMethods

  class GmDispatcher
    module Commands
      GM = Ezap::Service::GlobalMaster

      def state
        {reply: GM.state}
      end

      def shutdown
        {reply: 'ack', after_response: 'stop'}
      end

      def svc_reg opts
        opts.symbolize_keys_rec!
        name = opts[:name]
        unless name
          return {error: "service requires at least a name"}
        end
        if (rs = GM.services[name])
          if rs.healthy?
            return {error: "service with name '#{name}' already registered and healthy"}
          else
            print 're- ' #;)
          end
        end
        print "adding service: #{name}"
        new_rs = RemoteService.new(opts)
        GM.services[name] = new_rs
        {reply: {service_number: GM.services.keys.size, address: new_rs.address}}
      end

      def svc_unreg name
        puts "removing service: #{name}"
        GM.services[name] = nil
        {reply: :ack}
      end

      def locate_service name
        print "addr request for #{name.inspect}"
        #puts "services: #{GM.services.inspect}"
        rs = GM.services[name]
        return {reply: {}} unless rs
        {reply: {address: rs.address}}
        
      end

      def send_public obj
        GM.send_public("services", obj)
        {reply: 'ack'}
      end
    end
    extend Commands
  end

  #remote as seen from globalmaster
  #TODO: that's just very roughly hacked here
  class RemoteService
    GM = Ezap::Service::GlobalMaster
    attr_accessor :address, :properties

    def initialize opts
      @properties = opts
      @proto = opts[:proto] || 'tcp'
      if @host = opts[:host]
        GM.assign_service_port(self)
      end
    end

    #TODO: fill
    def healthy?
      true
    end

    #TODO: probably wrong for other transports
    def rebuild_address
      @address = "#{@proto}://#{@host}:#{@port}"
    end

    def set_port p
      @port = p
      rebuild_address
    end
  end

end
