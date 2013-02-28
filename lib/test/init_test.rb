#require File.join(File.expand_path('..', __FILE__), '..', 'init_file')
#->replaced by the new easy:
require_relative('../init_file')

Bundler.require(:default, :test)
require 'riot/rr'
