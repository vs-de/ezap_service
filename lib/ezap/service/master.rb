class Ezap::Service::Master
  include Ezap::Base
  include Ezap::GlobalMasterConnection
  include Ezap::WrappedZeroExtension

  module ClassMethods

    def start opts={}
      @pub = make_socket(:pub)
      @rep = make_socket(:rep)
      @req = make_socket(:req)
      bind :rep
      bind :pub
      state!(:running)
      loop_rep
    end
   
    #1 sock per type looks a bit poor, but probably sufficiant for a master
    def bind type
      addr = get_addr_of type
      puts "bind #{type} addr: #{addr}"
      instance_variable_get("@#{type}").bind(addr)
    end
    
    def get_addr_of sock_type
      @config[:sockets][sock_type.to_sym][:addr]
    end

  end

  extend ClassMethods
  #def initialize cfg
  #  self.config= cfg
  #end
  #

end
