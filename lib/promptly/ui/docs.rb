# frozen_string_literal: true

module Promptly
  # Handles displaying documentation in an interactive TUI (side-by-side).
  # With manual line-by-line layout for better control.
  class DocsViewer
    attr_reader :pages

    MAX_WIDTH = 120 # Set a max width for the TUI
    MIN_HEIGHT = 15 # Set a minimum height

    # Initializes the viewer, locating and loading docs.
    def initialize(docs_path = nil)
      @prompt = TTY::Prompt.new(interrupt: :exit)
      @docs_path = docs_path || File.expand_path('../../../docs/sfl', __dir__)
      @pages = load_docs
      @current_index = 0

      raise "No documentation files (*.md) found in #{@docs_path}" if @pages.empty?
    end

    # Main entry point to show the documentation viewer.
    def show
      loop do
        render_page(@current_index)
        handle_input
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
      []
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

    # Renders the current page with ToC and content, applying centering.
    def render_page(index)
      system 'clear' or system 'cls'

      page_data = @pages[index]
      term_width = TTY::Screen.width
      term_height = TTY::Screen.height

      # Calculate UI dimensions
      ui_width = [term_width, MAX_WIDTH].min
      ui_height = [term_height - 2, MIN_HEIGHT].max # -2 for nav + prompt
      padding_width = [(term_width - ui_width) / 2, 0].max
      padding = ' ' * padding_width

      # Calculate box dimensions
      toc_width = [30, (ui_width * 0.3).to_i].max
      content_width = ui_width - toc_width - 1 # -1 for the space between boxes
      box_content_height = ui_height - 4 # -2 border, -2 padding

      # Build content strings
      toc_content = build_toc(index, box_content_height)
      page_content = build_page_content(page_data, content_width, box_content_height)

      # Render boxes into strings first
      toc_box_str = TTY::Box.frame(
        toc_content,
        title: { top_left: ' SFL Concepts ' },
        width: toc_width,
        height: ui_height,
        padding: 1,
        style: { border: { fg: :blue } }
      )

      content_box_str = TTY::Box.frame(
        page_content,
        title: { top_left: " #{page_data[:title]} " },
        width: content_width,
        height: ui_height,
        padding: [1, 2],
        style: { border: { fg: :green } }
      )

      # Split into lines and ensure equal height
      toc_lines = toc_box_str.lines.map(&:chomp)
      content_lines = content_box_str.lines.map(&:chomp)

      # Ensure both arrays have exactly ui_height lines
      toc_lines = (toc_lines + [" " * toc_width] * ui_height).take(ui_height)
      content_lines = (content_lines + [" " * content_width] * ui_height).take(ui_height)

      # Print line by line with padding
      ui_height.times do |i|
        puts padding + toc_lines[i] + " " + content_lines[i]
      end

      # Print the navigation line, also centered
      nav_line = "Navigate: (n)ext | (p)revious | (t)oc | (q)uit"
      puts "\n" + padding + nav_line.center(ui_width)
    end

    # Builds the Table of Contents string, truncating if necessary.
    def build_toc(current_idx, height)
      lines = @pages.map.with_index do |page, idx|
        if idx == current_idx
          " > \e[1;36m#{page[:title]}\e[0m" # Highlight current - Bold Cyan
        else
          "   #{page[:title]}"
        end
      end
      lines.take(height).join("\n")
    end

    # Builds formatted content, truncating height and adding indicator.
    def build_page_content(page_data, width, height)
      # Ensure width is at least 1 for TTY::Markdown
      render_width = [width - 4, 1].max # -4 for padding
      full_content = TTY::Markdown.parse(page_data[:content], width: render_width)
      lines = full_content.lines.map(&:chomp)

      if lines.size > height
        lines.take(height - 1).join("\n") + "\n[... Content Truncated ...]" # Removed italics
      else
        lines.join("\n")
      end
    rescue StandardError => e
      "Error parsing Markdown:\n#{e.message}"
    end

    # Handles user input for navigation.
    def handle_input
      key = @prompt.keypress(echo: false)

      case key.downcase
      when 'n', 'j', "\e[B"
        @current_index = (@current_index + 1) % @pages.size
      when 'p', 'k', "\e[A"
        @current_index = (@current_index - 1 + @pages.size) % @pages.size
      when 't', ' '
        select_from_toc
      when 'q'
        raise TTY::Reader::InputInterrupt
      else
        handle_input
      end
    end

    # Shows an interactive ToC selection menu.
    def select_from_toc
      system 'clear' or system 'cls'
      choices = @pages.map { |p| p[:title] }
      selected_key = @prompt.select(
        "Select a topic:",
        choices,
        cycle: true,
        per_page: 10,
        filter: true
      )
      @current_index = @pages.index { |p| p[:title] == selected_key }
    end
  end
end