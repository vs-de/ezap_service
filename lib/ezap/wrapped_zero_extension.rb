#####
# Copyright 2013, Valentin Schulte, Leipzig
# This File is part of Ezap.
# It is shared to be part of wecuddle from Lailos Group GmbH, Leipzig.
# Before changing or using this code, you have to accept the Ezap License in the Ezap_LICENSE.txt file 
# included in the package or repository received by obtaining this file.
#####
module Ezap::WrappedZeroExtension
  
  def make_socket type, opts={}
    (@sockets ||= []) << (sock = Ezap::Sock.new(type, opts))
    sock
  end

  def close_sockets
    @sockets.each(&:close) if @sockets
  end

end
