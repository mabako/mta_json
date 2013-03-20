# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mta_json/version'

Gem::Specification.new do |spec|
  spec.name          = "mta_json"
  spec.version       = MtaJson::VERSION
  spec.authors       = ["Marcus Bauer"]
  spec.email         = ["mabako@gmail.com"]
  spec.description   = "Wraps calls by MTA's callRemote"
  spec.summary       = "MTA-Wrapper for JSON"
  spec.homepage      = "https://github.com/mabako/mta_json"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
