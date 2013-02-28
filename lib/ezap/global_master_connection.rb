module Ezap

=begin
  unless self.methods.include?(:config)
    Ezap.instance_eval do
      def config
        o = Object.new
        def o.global_master_address
          'tcp://127.0.0.1:43691'
        end
        o
      end
    end
  end
=end

  module GlobalMasterConnection
    def gm_request *args
      gm_addr = Ezap.config.global_master_address
      sock = make_socket(:req)
      sock.connect(gm_addr)
      #puts "sending gm"
      sock.send_obj(args)
      #puts "receiving gm"
      asw = sock.recv_obj
      sock.close
      asw
    end
  end
end
