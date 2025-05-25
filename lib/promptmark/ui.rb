# frozen_string_literal: true

module PromptMark
  # Handles user interface display using TTY components
  class UI
    def initialize
      @prompt = TTY::Prompt.new
      @markdown = TTY::Markdown
    end

    # Display a table of prompts
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

    # Display detailed view of a single prompt
    def display_prompt_details(prompt)
      # Display metadata in a box
      metadata_content = build_metadata_content(prompt)
      puts TTY::Box.frame(
        title: { top_left: " #{prompt.name} " },
        content: metadata_content,
        padding: 1,
        style: {
          fg: :bright_blue,
          border: {
            fg: :bright_blue
          }
        }
      )

      # Display body using TTY::Markdown if there's content
      if prompt.body && !prompt.body.strip.empty?
        puts "\n"
        puts @markdown.parse(prompt.body)
      else
        puts "\n(No content)"
      end
    end

    # Display success message
    def display_success(message)
      puts TTY::Box.success(message)
    end

    # Display error message
    def display_error(message)
      puts TTY::Box.error(message)
    end

    # Display info message
    def display_info(message)
      puts TTY::Box.info(message)
    end

    # Display warning message
    def display_warning(message)
      puts TTY::Box.warn(message)
    end

    # Confirm an action with the user
    def confirm(message)
      @prompt.yes?(message)
    end

    # Ask user to select from options
    def select(message, choices)
      @prompt.select(message, choices)
    end

    private

    def build_metadata_content(prompt)
      content = []
      content << "Description: #{prompt.description || 'N/A'}"

      content << if prompt.has_variables?
                   "Variables: #{prompt.variables.join(', ')}"
                 else
                   'Variables: None'
                 end

      content << "File: #{prompt.filepath || 'Unknown'}"
      content.join("\n")
    end

    def truncate_text(text, max_length)
      return 'N/A' if text.nil? || text.empty?

      text.length > max_length ? "#{text[0...max_length]}..." : text
    end
  end
end
