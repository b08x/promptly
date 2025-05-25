#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rake/clean'
require 'rake/testtask'

require 'rdoc/task'

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc","lib/**/*.rb","bin/**/*")
  rd.title = 'Promptly'
end

# Rake::TestTask.new do |t|
#   t.libs << "test"
#   t.test_files = FileList['test/*_test.rb']
# end

# task :default => :test

RSpec::Core::RakeTask.new(:spec)

task default: :spec
