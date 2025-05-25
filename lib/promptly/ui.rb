# frozen_string_literal: true

ENV['COLUMNS'] = '80'
# The Promptly module provides tools for managing and using text prompts,
# particularly those with YAML front matter and Markdown content.
module Promptly
  # Handles user interface interactions, such as displaying information,
  # tables, errors, and prompting the user for input.
  # It leverages TTY toolkit components for a rich terminal experience.
  class UI
    # Initializes a new UI instance.
    # This sets up instances of `TTY::Prompt` for user input and
    # `TTY::Markdown` for rendering Markdown content.
    def initialize
      @prompt = TTY::Prompt.new
      @markdown = TTY::Markdown
    end

    # Displays a list of prompts in a formatted table.
    # @param prompts [Array<Promptly::Prompt>] An array of {Promptly::Prompt} objects to display.
    def display_prompt_table(prompts)
      if prompts.empty?
        display_info('No prompts found.')
        return
      end

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
    # Metadata is shown in a styled box, and the body is rendered as Markdown.
    # @param prompt [Promptly::Prompt] The {Promptly::Prompt} object to display.
    def display_prompt_details(prompt)
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
        puts "\n"
        puts @markdown.parse(prompt.body)
      else
        puts "\n(No content)"
      end
    end

    # Displays a success message to the user, typically in a styled box.
    # @param message [String] The success message to display.
    def display_success(message)
      puts TTY::Box.success(message)
    end

    # Displays an error message to the user, typically in a styled box.
    # @param message [String] The error message to display.
    def display_error(message)
      puts TTY::Box.error(message)
    end

    # Displays an informational message to the user, typically in a styled box.
    # @param message [String] The informational message to display.
    def display_info(message)
      puts TTY::Box.info(message)
    end

    # Displays a warning message to the user, typically in a styled box.
    # @param message [String] The warning message to display.
    def display_warning(message)
      puts TTY::Box.warn(message)
    end

    # Asks the user for a yes/no confirmation.
    # @param message [String] The question to ask the user.
    # @return [Boolean] `true` if the user confirms (yes), `false` otherwise (no).
    def confirm(message)
      @prompt.yes?(message)
    end

    # Prompts the user to select one option from a list of choices.
    # @param message [String] The message to display before the list of choices.
    # @param choices [Array, Hash] The choices available for selection.
    #   Can be an array of strings or a hash where keys are display names and values are the return values.
    # @return [Object] The value associated with the user's selected choice.
    def select(message, choices)
      @prompt.select(message, choices)
    end

    private

    # Builds a string containing formatted metadata for a given prompt.
    # This includes description, variables, and filepath.
    #
    # @param prompt [Promptly::Prompt] The prompt whose metadata is to be formatted.
    # @return [String] A newline-separated string of the prompt's metadata.
    def build_metadata_content(prompt)
      content = []
      content << "Description: #{prompt.description || 'N/A'}"
      # NOTE: The `prompt.filepath` might be nil if the prompt was not loaded from a file.
      # The `File.basename` call in `display_prompt_table` handles this with `|| 'unknown'`,
      # a similar consideration might be useful here if a more user-friendly default is desired
      # instead of just "Unknown".

      content << if prompt.has_variables?
                   "Variables: #{prompt.variables.join(', ')}"
                 else
                   'Variables: None'
                 end

      content << "File: #{prompt.filepath || 'Unknown'}"
      content.join("\n")
    end

    # Truncates a given text string to a maximum length, appending "..." if truncated.
    # Returns "N/A" if the text is nil or empty.
    #
    # @param text [String, nil] The text to truncate.
    # @param max_length [Integer] The maximum desired length of the text.
    # @return [String] The truncated text, or "N/A".
    def truncate_text(text, max_length)
      return 'N/A' if text.nil? || text.empty?

      text.length > max_length ? "#{text[0...max_length]}..." : text
    end
  end
end
