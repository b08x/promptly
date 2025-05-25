# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__), 'lib', 'promptmark', 'version.rb'])
Gem::Specification.new do |s|
  s.name = 'promptmark'
  s.version = Promptmark::VERSION
  s.author = 'Robert Pannick'
  s.email = 'rwpannick@gmail.com'
  s.homepage = 'https://b08x.github.io/projects/promptmanager'
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 3.1'
  s.summary = 'A description of your project'
  s.files = `git ls-files`.split("\n")
  s.require_paths << 'lib'
  s.extra_rdoc_files = ['README.rdoc', 'promptmark.rdoc']
  s.rdoc_options << '--title' << 'promptmark' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'promptmark'
  s.add_development_dependency('minitest')
  s.add_development_dependency('pry')
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('rspec')
  s.add_runtime_dependency('gli', '~> 2.22.2')
  s.add_runtime_dependency('reline')
end
