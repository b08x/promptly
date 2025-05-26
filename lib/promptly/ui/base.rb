# frozen_string_literal: true

require 'tty-editor'
require 'tty-markdown'
require 'tty-pager'
require 'tty-table'

ENV['COLUMNS'] = '80'

# The Promptly module provides tools for managing and using text prompts,
# particularly those with YAML front matter and Markdown content.
module Promptly
  # Handles user interface interactions, such as displaying information,
  # tables, errors, and prompting the user for input.
  # It leverages TTY toolkit components for a rich terminal experience.
  class UI
    # @!attribute [r] prompt
    #   @return [TTY::Prompt] The TTY::Prompt instance for interactive input.
    attr_reader :prompt

    # Initializes a new UI instance.
    def initialize
      @prompt = TTY::Prompt.new
      @markdown = TTY::Markdown
    end

    # Displays a list of prompts in a formatted table.
    def display_prompt_table(prompts)
      if prompts.empty?
        display_info('No prompts found.')
        return
      end

      clear_screen

      table = TTY::Table.new(
        header: %w[Name Description Variables File],
        rows: prompts.map do |prompt|
          [
            prompt.name,
            truncate_text(prompt.description, 40),
            prompt.variable_count,
            File.basename(prompt.filepath || 'unknown')
          ]
        end
      )

      puts table.render(:unicode, padding: [0, 1])
    end

    # Displays a detailed view of a single prompt, including its metadata and body.
    def display_prompt_details(prompt)
      clear_screen
      # Display metadata in a box
      metadata_content = build_metadata_content(prompt)
      puts TTY::Box.frame(
        title: { top_left: " #{prompt.name} " },
        padding: 1,
        style: {
          fg: :bright_blue,
          border: {
            fg: :bright_blue
          }
        }
      ) { metadata_content }

      # Display body using TTY::Markdown if there's content
      if prompt.body && !prompt.body.strip.empty?
        puts '\\n'
        puts @markdown.parse(prompt.body)
      else
        puts '\\n(No content)'
      end
    end

    # Displays a success message to the user, typically in a styled box.
    def display_success(message)
      puts TTY::Box.success(message)
    end

    # Displays an error message to the user, typically in a styled box.
    def display_error(message)
      puts TTY::Box.error(message)
    end

    # Displays an informational message to the user, typically in a styled box.
    def display_info(message)
      puts TTY::Box.info(message)
    end

    # Displays a warning message to the user, typically in a styled box.
    def display_warning(message)
      puts TTY::Box.warn(message)
    end

    # Asks the user for a yes/no confirmation.
    def confirm(message)
      @prompt.yes?(message)
    end

    # Prompts the user to select one option from a list of choices.
    def select(message, choices, options = {})
      @prompt.select(message, choices, options)
    end

    private

    def clear_screen
      system('clear') || system('cls')
    end

    # Builds a string containing formatted metadata for a given prompt.
    def build_metadata_content(prompt)
      content = []
      content << "Description: #{prompt.description || 'N/A'}"
      content << if prompt.has_variables?
                   "Variables: #{prompt.variables.join(', ')}"
                 else
                   'Variables: None'
                 end

      content << "File: #{prompt.filepath || 'Unknown'}"
      content.join('\\n')
    end

    # Truncates a given text string to a maximum length, appending "..." if truncated.
    def truncate_text(text, max_length)
      return 'N/A' if text.nil? || text.empty?

      text.length > max_length ? "#{text[0...max_length]}..." : text
    end
  end
end
