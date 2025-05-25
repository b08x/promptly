# frozen_string_literal: true

module Promptly
  # Handles displaying documentation using TTY::Prompt for menu
  # and TTY::Pager for content viewing.
  class DocsViewer
    attr_reader :pages

    # Initializes the viewer, locating and loading docs.
    def initialize(docs_path = nil)
      @prompt = TTY::Prompt.new(interrupt: :exit)
      @pager = TTY::Pager.new
      @docs_path = docs_path || File.expand_path('../../docs', __dir__)
      @pages = load_docs

      raise "No documentation files (*.md) found in #{@docs_path}" if @pages.empty?
    end

    # Main entry point to show the documentation viewer menu.
    def show
      loop do
        system 'clear' or system 'cls'
        choices = @pages.map { |p| { name: p[:title], value: p } }
        choices << { name: '(Exit Docs)', value: :exit } # Add an exit option

        selected = @prompt.select(
          'Select a documentation topic to view:',
          choices,
          cycle: true,
          per_page: 15, # Show more items, adjust as needed
          filter: true # Allow filtering by typing
        )

        break if selected == :exit

        display_page_with_pager(selected)
      end
    rescue TTY::Reader::InputInterrupt
      system 'clear' or system 'cls'
      puts "\nExiting docs viewer. Goodbye!"
    end

    private

    # Scans the docs directory, loads, and parses markdown files.
    def load_docs
      Dir.glob(File.join(@docs_path, '*.md')).sort.map do |filepath|
        content = File.read(filepath)
        title = extract_title(content) || format_filename(filepath)
        { title: title, content: content }
      end
    rescue Errno::ENOENT
      [] # Return empty if directory doesn't exist
    end

    # Extracts H1 title (# Title) from markdown content.
    def extract_title(content)
      first_line = content.lines.find { |line| line.strip.start_with?('# ') }
      first_line ? first_line.sub('# ', '').strip : nil
    end

    # Creates a title from a filename.
    def format_filename(filepath)
      File.basename(filepath, '.md')
          .gsub(/^\d+-/, '')
          .tr('_-', ' ')
          .strip
          .capitalize
    end

    # Displays the selected page content using TTY::Pager.
    # @param page_data [Hash] The page hash { title: String, content: String }.
    def display_page_with_pager(page_data)
      # Parse markdown first for better formatting within the pager.
      # We render it with TTY::Markdown before passing to the pager.
      formatted_content = TTY::Markdown.parse(
        page_data[:content],
        width: TTY::Screen.width - 2 # Adjust width slightly for pager
      )

      # Use TTY::Pager to display the formatted text.
      # The pager will handle scrolling and quitting.
      @pager.page(text: formatted_content)
    end
  end
end
