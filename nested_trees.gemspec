$:.push File.expand_path("../lib", __FILE__)
require File.join(File.dirname(__FILE__), 'lib/version')

Gem::Specification.new do |s|
  s.name = 'nested_trees'
  s.version = NestedTrees::VERSION.dup
  s.platform = Gem::Platform::RUBY
  s.summary = 'Realization of NestedSets model for database.'
  s.email = 'anex.work@gmail.com'
  s.description = 'Realization of NestedSets model for database.'
  s.author = 'Alex Anzelm'
  
  s.require_paths = ['lib']
  s.files = Dir['lib/**/*.rb']
  s.test_files = Dir['test/**/*.rb']
  
  s.add_dependency 'squeel', '~>1.0'
end
