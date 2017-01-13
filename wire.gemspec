require_relative 'lib/wire'
Gem::Specification.new do |s|
  s.name        = 'wire-framework'
  s.version     = Wire::VERSION
  s.date        = '2017-01-13'
  s.summary     = 'Wire Framework'
  s.description = 'Wire is a DSL and Rack interface for quickly building web applications, without the needless complexity of Rails'
  s.authors     = ['Bryan T. Meyers']
  s.email       = 'bmeyers@datadrake.com'
  s.files       =  Dir.glob('lib/**/*') + %w(LICENSE README.md)
  s.homepage    = 'http://rubygems.org/gems/wire'
  s.license     = 'GPL v2'
  s.add_runtime_dependency 'awesome_print'
  s.add_runtime_dependency 'cobravsmongoose'
  s.add_runtime_dependency 'docile'
	s.add_runtime_dependency 'lmdb'
  s.add_runtime_dependency 'nokogiri'
  s.add_runtime_dependency 'nori'
  s.add_runtime_dependency 'sequel'
  s.add_runtime_dependency 'rack'
  s.add_runtime_dependency 'rest-less'
  s.add_runtime_dependency 'tilt'
  s.add_runtime_dependency 'wiki-this'
end