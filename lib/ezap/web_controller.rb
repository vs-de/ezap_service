class Ezap::WebController

  #don't take this approach too serious...
  def self.config
    Ezap.config
  end
  $: << File.join(config.root, 'external', 'innate', 'lib')
  require "innate"

  include Innate::Node

  #def self.included base

  #end

  def config
    self.class.config
  end

  def start
    #Innate.start(started: true, root: config.root)
  end

  def start!
    #Innate.start(root: config.root)
    #Innate.start(adapter: :webrick)
    Innate.start(adapter: :mizuno)
  end

  def host
    request.env['HTTP_HOST']
  end

end

