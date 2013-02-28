#####
# Copyright 2013, Valentin Schulte, Leipzig
# This File is part of Ezap.
# It is shared to be part of wecuddle from Lailos Group GmbH, Leipzig.
# Before changing or using this code, you have to accept the Ezap License in the Ezap_LICENSE.txt file 
# included in the package or repository received by obtaining this file.
#####
module Ezap
  require 'bundler'
  Bundler.require
  CFG_FILE_NAME = 'main.yml'
  CFG_PATH = 'config'
 
  def self.load_lib *x
    require File.join(EZAP_LIB_PATH, *x)
  end

  def self.load_lib_dir p
    Dir.glob(File.join(EZAP_LIB_PATH, p, '*.rb')) do |f|
      load f
    end
  end

  #order matters here 
  load_lib_dir '../ruby_ext'
  load_lib 'config'
  @@config = Config.new

  def self.config
    @@config
  end

  load_lib 'base'
  load_lib 'zmq_ctx'
  load_lib 'sock'
  load_lib 'direct_zero_extension'
  load_lib 'wrapped_zero_extension'
  load_lib 'sub_listener'
  load_lib 'global_master_connection'
  load_lib 'service'
  load_lib 'service', 'master'
  load_lib_dir 'service'
  #load_lib 'web_controller'
end
