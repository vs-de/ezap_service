#####
# Copyright 2013, Valentin Schulte, Leipzig
# This File is part of Ezap.
# It is shared to be part of wecuddle from Lailos Group GmbH, Leipzig.
# Before changing or using this code, you have to accept the Ezap License in the Ezap_LICENSE.txt file 
# included in the package or repository received by obtaining this file.
#####
module Ezap
  class Sock #just simple zmq wrapper

    attr_accessor :zs #zmq socket

    def initialize  _type, opts={}
      type = _type.is_a?(Fixnum) ? _type : ZMQ.const_get(_type.to_s.upcase) 
      @zs = Ezap::ZmqCtx().socket(type)
      @zs.extend(InnerSockMethods)
      [:close,  :bind, :recvmsg, :recv_string, :sendmsg, :send_string, :connect, :setsockopt].each do |m|
        define_singleton_method(m) do |*args|
          @zs.raise_error_wrap(m, *args)
        end
      end
      extend OuterSockMethods

    end

    module InnerSockMethods
      #check return value fitting to zmq-ffi gem
      def raise_error_wrap fname, *args
        ret = __send__(fname, *args)
        unless ZMQ::Util.resultcode_ok?(ret)
          msg = ZMQ::Util.error_string
          raise "#{fname}: returned #{ret}: #{msg}"
        end
        ret
      end
      
    end

    module OuterSockMethods
      def recv fl=0
        str = ''
        recv_string(str, fl)
        str
      end

      def send str, fl=0
        send_string(str, fl)
      end

      def send_obj obj
        self.send(MessagePack.pack(obj))
      end

      def recv_obj
        MessagePack.unpack(self.recv)
      end
    end

    def close
      @zs.terminate
    end

    #def bind arg
    #  @zs.bind arg
    #end
  end
end
