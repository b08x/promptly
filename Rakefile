#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rake/clean'
require 'rake/testtask'

require 'rdoc/task'

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

require 'swagger/blocks'

namespace :docs do
  # RDoc Configuration
  RDoc::Task.new(:rdoc) do |t|
    t.main = "README.md"
    t.rdoc_files.include("README.md", "lib/**/*.rb", "guides/Usage.md")
    t.options << "--format=markdown"
    t.options << "--markup=markdown"
    t.rdoc_dir = "doc"
    t.title = "#{ENV['GEM_NAME'] || 'RubyGem'} Documentation"
  end

  # Swagger-blocks Configuration
  namespace :openapi do
    desc 'Generate OpenAPI specification'
    task :generate do
      require "your_swagger_definition" # Point to your swagger-blocks file

      swagger_data = Swagger::Blocks.build_root_json(YourSwaggerDefinitions::SWAGGERED_CLASSES)
      mkdir_p "public/api_docs/v1"
      File.write("public/api_docs/v1/swagger.json", JSON.pretty_generate(swagger_data))
    end

    desc 'Validate OpenAPI specs'
    task validate: :generate do
      sh "npx @redocly/cli lint public/api_docs/v1/swagger.json" do |ok|
        abort("OpenAPI validation failed") unless ok
      end
    end
  end

  # Docusaurus Integration
  desc 'Build documentation site'
  task docusaurus: %i[rdoc openapi:validate] do
    cp_r "doc/.", "docs/docs/rdoc", remove_destination: true
    cp_r "public/api_docs", "docs/static/api_docs", remove_destination: true

    Dir.chdir('docs') do
      sh "npm install --quiet --no-progress"
      sh "npm run build -- --quiet"
    end
  end

  desc 'Serve documentation locally'
  task :serve do
    Dir.chdir('docs') do
      sh "npm start"
    end
  end

  desc 'Clean generated artifacts'
  task :clean do
    rm_rf ["doc", "public/api_docs", "docs/build", "docs/node_modules"]
  end
end

task docs: ['docs:rdoc', 'docs:openapi:validate', 'docs:docusaurus']
task clobber: ['docs:clean']

RSpec::Core::RakeTask.new(:spec)

task default: :spec
