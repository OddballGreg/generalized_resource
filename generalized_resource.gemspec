lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'generalized_resource/version'

Gem::Specification.new do |s|
  s.name          = 'generalized_resource'
  s.version       = GeneralizedResource::VERSION
  s.date          = '2018-04-03'
  s.summary       = "A gem to interact with Generalized API Applications"
  s.description   = "A gem to interact with Generalized API Applications"
  s.authors       = ["Gregory Havenga"]
  s.email         = ""
  s.homepage      = ""
  s.files         = Dir["./**/*.rb"]
  s.require_paths = ["lib"]
  s.add_development_dependency "pry"
  s.add_dependency "httparty"
  s.add_dependency "activesupport"
end
