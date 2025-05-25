# frozen_string_literal: true

module PromptMark
  # Represents a prompt with YAML front matter and Markdown body
  class Prompt
    attr_reader :name, :description, :variables, :body, :filepath

    def initialize(name:, description: nil, variables: [], body: '', filepath: nil)
      @name = name
      @description = description
      @variables = variables || []
      @body = body
      @filepath = filepath
    end

    # Create a Prompt from parsed front matter data
    def self.from_parsed_data(parsed_data, filepath = nil)
      front_matter = parsed_data.front_matter || {}

      new(
        name: front_matter['name'] || File.basename(filepath, '.md'),
        description: front_matter['description'],
        variables: front_matter['variables'] || [],
        body: parsed_data.content,
        filepath: filepath
      )
    end

    # Convert prompt back to markdown format with front matter
    def to_markdown
      front_matter = {
        'name' => name,
        'description' => description,
        'variables' => variables
      }.compact

      yaml_content = front_matter.empty? ? '' : "#{YAML.dump(front_matter)}---\n"
      "---\n#{yaml_content}\n#{body}"
    end

    def has_variables?
      !variables.empty?
    end

    def variable_count
      variables.size
    end
  end
end
