# Ezap! applications with ease

# general stuff

EZAP_ROOT = File.expand_path('../..', __FILE__)
EZAP_LIB_PATH = File.join(EZAP_ROOT, 'lib', 'ezap')
require 'ffi-rzmq'
require 'msgpack'
require 'redis'
require File.join(EZAP_LIB_PATH)

extend Ezap::DirectZeroExtension
