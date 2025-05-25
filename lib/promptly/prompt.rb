# frozen_string_literal: true

# The Promptly module provides tools for managing and using text prompts,
# particularly those with YAML front matter and Markdown content.
module Promptly
  # Represents a prompt, typically read from a Markdown file with YAML front matter.
  # It encapsulates the prompt's metadata (name, description, variables) and its main content (body).
  # Represents a prompt with YAML front matter and Markdown body
  class Prompt
    # @!attribute [r] name
    #   @return [String] The name of the prompt.
    # @!attribute [r] description
    #   @return [String, nil] An optional description of the prompt.
    # @!attribute [r] variables
    #   @return [Array<String>] A list of variable names expected by the prompt.
    # @!attribute [r] body
    #   @return [String] The main content or template of the prompt.
    # @!attribute [r] filepath
    #   @return [String, nil] The original file path from which the prompt was loaded, if applicable.
    attr_reader :name, :description, :variables, :body, :filepath

    # Initializes a new Prompt object.
    #
    # @param name [String] The name of the prompt.
    # @param description [String, nil] An optional description for the prompt. Defaults to `nil`.
    # @param variables [Array<String>] A list of variable names. Defaults to an empty array.
    # @param body [String] The main content of the prompt. Defaults to an empty string.
    # @param filepath [String, nil] The file path of the prompt. Defaults to `nil`.
    def initialize(name:, description: nil, variables: [], body: '', filepath: nil)
      @name = name
      @description = description
      @variables = variables || []
      @body = body
      @filepath = filepath
    end

    # Creates a new Prompt instance from parsed data, typically from a file.
    #
    # @param parsed_data [Object] An object responding to `front_matter` (a Hash) and `content` (a String).
    #   `front_matter` is expected to contain keys like 'name', 'description', and 'variables'.
    # @param filepath [String, nil] The path to the file from which the data was parsed.
    #   If `parsed_data.front_matter['name']` is not present, the basename of `filepath` (sans '.md') is used as the name.
    # @return [Promptly::Prompt] A new Prompt object.
    def self.from_parsed_data(parsed_data, filepath = nil)
      front_matter = parsed_data.front_matter || {}

      # Use filename as name when name is not present in front matter
      name = front_matter['name']
      name = File.basename(filepath, '.md') if name.nil? && filepath

      new(
        name: name,
        description: front_matter['description'],
        variables: front_matter['variables'] || [],
        body: parsed_data.content,
        filepath: filepath
      )
    end

    # Converts the Prompt object back into a Markdown string representation,
    # including YAML front matter.
    #
    # @return [String] The Markdown representation of the prompt with YAML front matter.
    def to_markdown
      front_matter = {
        'name' => name,
        'description' => description,
        'variables' => variables
      }.compact

      yaml_content = front_matter.empty? ? '' : "#{YAML.dump(front_matter)}---\n"
      "---\n#{yaml_content}\n#{body}"
    end

    # Checks if the prompt has any variables defined.
    #
    # @return [Boolean] `true` if variables are present, `false` otherwise.
    def has_variables?
      !variables.empty?
    end

    # Returns the number of variables defined for the prompt.
    #
    # @return [Integer] The count of variables.
    def variable_count
      variables.size
    end
  end
end
