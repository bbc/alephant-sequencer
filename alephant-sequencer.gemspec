# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "alephant/sequencer/version"

Gem::Specification.new do |spec|
  spec.name          = "alephant-sequencer"
  spec.version       = Alephant::Sequencer::VERSION
  spec.authors       = ["BBC News"]
  spec.email         = ["FutureMediaNewsRubyGems@bbc.co.uk"]
  spec.summary       = %q{Adds sequencing functionality to Alephant.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rake-rspec"
  spec.add_development_dependency "rspec-nc"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  # listen added as newer version breaks bundle update
  # due to requiring ruby_dep or ruby > 2.2
  spec.add_development_dependency "listen", "< 3.1.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-remote"
  spec.add_development_dependency "pry-nav"

  spec.add_runtime_dependency "aws-sdk", "~> 1.0"
  spec.add_runtime_dependency "alephant-logger"
  spec.add_runtime_dependency "alephant-support"
  spec.add_runtime_dependency "jsonpath"
  spec.add_runtime_dependency "dalli-elasticache"
end
