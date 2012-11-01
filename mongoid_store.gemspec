# encoding: UTF-8
require File.expand_path('../lib/mongoid_store/version', __FILE__)

Gem::Specification.new do |s|
  s.name         = 'mongoid_store'
  s.version      = MongoidStore::Version
  s.platform     = Gem::Platform::RUBY
  s.authors      = ['Andre Meij']
  s.email        = ['andre@socialreferral.com']
  s.homepage     = 'http://github.com/socialreferral/mongoid_store'
  s.summary      = 'ActiveSupport Mongoid 3 Cache store.'
  s.description  = 'ActiveSupport Mongoid 3 Cache store.'

  s.add_dependency 'mongoid',       '~> 3.0'
  s.add_dependency 'activesupport', '~> 3.2'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end