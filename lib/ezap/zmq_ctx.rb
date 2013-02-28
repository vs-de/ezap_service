class Ezap::ZmqCtx
  def self.get
    @ctx ||= ZMQ::Context.new
  end
  
  def self.close
    unless @ctx
      $stderr.puts "warn: no context to close"
    else
      @ctx.terminate
    end
  end

end
def Ezap::ZmqCtx
  Ezap::ZmqCtx.get
end
   
