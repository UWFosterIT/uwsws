# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'uw_sws/version'

Gem::Specification.new do |spec|
  spec.name          = "uw_sws"
  spec.version       = UwSws::VERSION
  spec.authors       = ["Nogbit"]
  spec.email         = ["milesm@uw.edu"]
  spec.description   = %q{Interfaces with UW Student Web Service}
  spec.summary       = %q{Wraps most of the rest endpoints}
  spec.homepage      = "https://github.com/UWFosterIT/uwsws"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "rest-client", ">= 1.6.7"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry-byebug"
end
