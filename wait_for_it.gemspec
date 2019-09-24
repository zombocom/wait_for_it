# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wait_for_it/version'

Gem::Specification.new do |spec|
  spec.name          = "wait_for_it"
  spec.version       = WaitForIt::VERSION
  spec.authors       = ["schneems"]
  spec.email         = ["richard.schneeman@gmail.com"]

  spec.summary       = %q{ Stop sleeping in your tests, instead wait for it... }
  spec.description   = %q{ Make your complicated integration tests more deterministic with wait for it}
  spec.homepage      = "https://github.com/zombocom/wait_for_it"
  spec.license       = "MIT"



  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
