#####
# Copyright 2013, Valentin Schulte, Leipzig
# This File is part of Ezap.
# It is shared to be part of wecuddle from Lailos Group GmbH, Leipzig.
# Before changing or using this code, you have to accept the Ezap License in the Ezap_LICENSE.txt file 
# included in the package or repository received by obtaining this file.
#####
class Ezap::SubscriptionListener
  include Ezap::Base
  include Ezap::WrappedZeroExtension

  attr_accessor :threads
  def  initialize config={}#scope, addr, config={}
    @handler_class = config[:handler] || EventHandler
    #subscribe scope, addr
    #start scope, addr
    @threads = []
  end

  def subscribe scope, addr
    @sock.setsockopt(ZMQ::SUBSCRIBE, scope)
    @sock.connect(addr)
  end

  #TODO: context creation not needed, just socket must be thread-owned
  def start scope, addr
    @threads << Thread.new do
      ctx = ZMQ::Context.new
      sock = ctx.socket ZMQ::SUB
      #subscribe scope, addr
      sock.setsockopt(ZMQ::SUBSCRIBE, scope)
      sock.connect(addr)
      puts "listening on #{sock}:"
      while true do
        raw_event = sock.recv
        print "thread received obj: "
        obj = MessagePack.load(raw_event[(scope.size..-1)])
        puts obj.inspect
        break if obj == ['quit']
        #eh = EventHandler.new(obj)
        eh = @handler_class.new(obj)
        eh.process!
      end
      sock.close
      ctx.close
    end
  end

  def recv
    #@sock.recv
  end

  def fall_back_handler
  
  end

  def stop
    #@sock.close
  end

  class EventHandler
    def initialize obj
      @obj = obj
    end

    def process!
      puts "working on #{@obj.inspect}"
    end
  end

end
