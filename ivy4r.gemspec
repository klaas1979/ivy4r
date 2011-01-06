# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ivy4r/version"

Gem::Specification.new do |s|
  s.name        = "ivy4r"
  s.version     = Ivy4r::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Klaas Reineke"]
  s.email       = ["klaas.reineke@googlemail.com"]
  s.homepage    = "http://github.com/klaas1979/ivy4r"
  s.summary = %q{Ivy4r Apache Ivy dependency management for Ruby}
  s.description     = %q{Ivy4r is a Ruby interface for Apache Ivy dependency management library. Offers support for using Ivy with Buildr and Rake.}

  s.rubyforge_project = "ivy4r"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  #s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'facets', '>= 2.9.0'
  s.add_dependency 'Antwrap', '>= 0.7.0'
  s.add_dependency 'ivy4r-jars', '>= 1.2.0'

  s.add_development_dependency 'rspec', '>= 2.0.0'
  s.add_development_dependency 'mocha', '>= 0.9.8'
  s.add_development_dependency 'rr' # for old functional tests
end
