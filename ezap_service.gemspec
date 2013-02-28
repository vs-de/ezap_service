# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ezap/version'

Gem::Specification.new do |gem|
  gem.name          = "ezap_service"
  gem.version       = EzapService::VERSION
  gem.authors       = ["Valentin Schulte"]
  gem.email         = ["valentin.schulte@wecuddle.de"]
  gem.description   = %q{ezap service layer. Let's your app act as an ezap_service. Brings global master and ezap-executable}
  gem.summary       = %q{ezap service layer.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency('redis', '~> 3.0.2')
  gem.add_dependency('ffi-rzmq', '~> 1.0.0')
  gem.add_dependency('msgpack', '~> 0.5.3')

end
