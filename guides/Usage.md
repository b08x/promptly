---
sidebar_position: 2
---

## Overview

Promptly is a Ruby gem designed for managing text prompts stored as Markdown files with YAML front matter. It provides both a command-line interface (CLI) and a programmatic API for listing, viewing, editing, and managing these prompts.

This document explains how to use Promptly as a gem in your Ruby applications, allowing you to leverage its prompt management capabilities programmatically.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'promptly'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install promptly
```

## Basic Usage

### Command-line Interface

While Promptly's primary value as a gem is its programmatic API, it also provides a command-line interface:

```bash
# Show interactive menu
$ promptly

# List all prompts
$ promptly list

# View a specific prompt
$ promptly view prompt_name

# Edit a prompt (or create if it doesn't exist)
$ promptly edit prompt_name

# Manage configuration
$ promptly config list
$ promptly config get key
$ promptly config set key value

# View documentation
$ promptly docs
```

### Programmatic API

To use Promptly in your Ruby code:

```ruby
require 'promptly'

# Initialize a manager to work with prompts
manager = Promptly::Manager.new

# List all available prompts
prompts = manager.list_all

# Find a specific prompt
prompt = manager.find_by_name('my_prompt')

# Access prompt properties
puts prompt.name
puts prompt.description
puts prompt.body
```

## Core Components

### Promptly::Prompt

The `Prompt` class represents a single prompt with its metadata and content:

```ruby
# Create a new prompt programmatically
prompt = Promptly::Prompt.new(
  name: 'example_prompt',
  description: 'An example prompt',
  variables: ['name', 'topic'],
  body: 'Hello {{name}}, let\'s talk about {{topic}}.'
)

# Convert a prompt to markdown format (for saving to file)
markdown = prompt.to_markdown

# Check if a prompt has variables
if prompt.has_variables?
  puts "This prompt has #{prompt.variable_count} variables"
end
```

### Promptly::Manager

The `Manager` class handles loading prompts from the filesystem:

```ruby
# Initialize with custom configuration
custom_config = { prompts_directory: '/path/to/prompts' }
manager = Promptly::Manager.new(custom_config)

# List all prompts
all_prompts = manager.list_all

# Find a prompt by name
prompt = manager.find_by_name('example_prompt')

# Get the filepath for a prompt
filepath = manager.find_filepath('example_prompt')
```

### Promptly::UI

The `UI` class provides terminal display capabilities:

```ruby
ui = Promptly::UI.new

# Display information
ui.display_info("This is an informational message")

# Display success
ui.display_success("Operation completed successfully")

# Display warning
ui.display_warning("This is a warning message")

# Display error
ui.display_error("An error occurred")

# Display a prompt's details
ui.display_prompt_details(prompt)

# Display a table of prompts
ui.display_prompt_table(prompts)

# Interactive selection
choice = ui.select("Choose an option:", ["Option 1", "Option 2", "Option 3"])

# Confirmation
if ui.confirm("Are you sure?")
  # User confirmed
end
```

## Configuration

Promptly uses a global `$config` object for configuration, but you can also create and pass your own configuration:

```ruby
require 'tty-config'

# Create a custom configuration
config = TTY::Config.new
config.set(:prompts_directory, value: '/path/to/prompts')
config.set(:default_editor, value: 'vim')

# Use the custom configuration
manager = Promptly::Manager.new(config)
```

## Prompt File Format

Prompts are stored as Markdown files with YAML front matter:

```markdown
---
name: example_prompt
description: An example prompt for demonstration
variables: [name, topic]
---

# Example Prompt

Hello {{name}}, let's talk about {{topic}}.

This is the body of the prompt, written in Markdown.
```

## Example: Creating a Custom Prompt Manager

Here's an example of creating a custom application that uses Promptly to manage prompts:

```ruby
require 'promptly'

class MyPromptManager
  def initialize(prompts_dir = nil)
    config = { prompts_directory: prompts_dir || "#{Dir.home}/.my_app/prompts" }
    @manager = Promptly::Manager.new(config)
    @ui = Promptly::UI.new
  end

  def list_prompts
    prompts = @manager.list_all
    @ui.display_prompt_table(prompts)
    prompts
  end

  def create_prompt(name, description, content)
    prompt = Promptly::Prompt.new(
      name: name,
      description: description,
      body: content
    )
    
    # Save to file
    filepath = File.join(@manager.instance_variable_get(:@config)[:prompts_directory], "#{name}.md")
    File.write(filepath, prompt.to_markdown)
    
    @ui.display_success("Created prompt: #{name}")
    prompt
  end

  def get_prompt(name)
    prompt = @manager.find_by_name(name)
    if prompt
      @ui.display_prompt_details(prompt)
    else
      @ui.display_error("Prompt not found: #{name}")
    end
    prompt
  end
end

# Usage
manager = MyPromptManager.new
manager.list_prompts
manager.create_prompt("greeting", "A friendly greeting", "Hello, world!")
manager.get_prompt("greeting")
```

## Example: Using Promptly in a Rails Application

You can integrate Promptly into a Rails application to manage templates or AI prompts:

```ruby
# In config/initializers/promptly.rb
require 'promptly'

# Configure Promptly
$promptly_config = TTY::Config.new
$promptly_config.set(:prompts_directory, value: Rails.root.join('app', 'prompts'))

# Create a global prompt manager
$prompt_manager = Promptly::Manager.new($promptly_config)

# In app/services/prompt_service.rb
class PromptService
  def self.get_prompt(name)
    $prompt_manager.find_by_name(name)
  end
  
  def self.render_prompt(name, variables = {})
    prompt = get_prompt(name)
    return nil unless prompt
    
    content = prompt.body
    variables.each do |key, value|
      content = content.gsub("{{#{key}}}", value.to_s)
    end
    
    content
  end
end

# In a controller
class AiController < ApplicationController
  def generate
    prompt_text = PromptService.render_prompt('ai_assistant', {
      user_name: current_user.name,
      query: params[:query]
    })
    
    # Use the rendered prompt with an AI service
    # ...
    
    render json: { result: ai_response }
  end
end
```

## Extending Promptly

### Creating Custom Prompt Types

You can extend the `Prompt` class to create custom prompt types:

```ruby
module MyApp
  class AiPrompt < Promptly::Prompt
    attr_reader :temperature, :max_tokens
    
    def initialize(name:, description: nil, variables: [], body: '', filepath: nil, temperature: 0.7, max_tokens: 1000)
      super(name: name, description: description, variables: variables, body: body, filepath: filepath)
      @temperature = temperature
      @max_tokens = max_tokens
    end
    
    def self.from_parsed_data(parsed_data, filepath = nil)
      prompt = super
      
      front_matter = parsed_data.front_matter || {}
      prompt.instance_variable_set(:@temperature, front_matter['temperature'] || 0.7)
      prompt.instance_variable_set(:@max_tokens, front_matter['max_tokens'] || 1000)
      
      prompt
    end
    
    def to_markdown
      front_matter = {
        'name' => name,
        'description' => description,
        'variables' => variables,
        'temperature' => temperature,
        'max_tokens' => max_tokens
      }.compact
      
      yaml_content = front_matter.empty? ? '' : "#{YAML.dump(front_matter)}---\n"
      "---\n#{yaml_content}\n#{body}"
    end
  end
end
```

### Custom Manager

You can also extend the `Manager` class to add custom functionality:

```ruby
module MyApp
  class AiPromptManager < Promptly::Manager
    def load_prompt_from_file(filepath)
      parsed = FrontMatterParser::Parser.parse_file(filepath)
      MyApp::AiPrompt.from_parsed_data(parsed, filepath)
    end
    
    def find_by_category(category)
      prompts = list_all
      prompts.select { |p| p.front_matter&.dig('category') == category }
    end
  end
end
```

## Conclusion

Promptly provides a flexible framework for managing text prompts in Ruby applications. By using Promptly as a gem, you can leverage its prompt management capabilities to handle templates, AI prompts, or any other text-based content that benefits from structured storage and metadata.

The gem's modular design allows for easy extension and customization, making it adaptable to a wide range of use cases beyond its core CLI functionality.