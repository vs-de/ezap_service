module Ezap::DirectZeroExtension
  def make_socket type
    type = ZMQ.const_get(type.to_s.upcase) unless type.is_a? Fixnum
    (@socks ||= []) << (sock = Ezap::ZmqCtx.socket(type))
    sock
  end

  def zmq_stop
    @socks.each(&:close) if @socks
    Ezap::ZmqCtx.close
  end
end
