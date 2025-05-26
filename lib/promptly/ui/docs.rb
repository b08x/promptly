# frozen_string_literal: true

module Promptly
  # Handles displaying documentation in an interactive TUI (side-by-side).
  # With manual scrolling for the content panel.
  class DocsViewer
    attr_reader :pages

    MAX_WIDTH = 120
    MIN_HEIGHT = 15

    def initialize(docs_path = nil)
      @prompt = TTY::Prompt.new(interrupt: :exit)
      @docs_path = docs_path || File.join(APP_ROOT, 'docs')
      @pages = load_docs_structure
      @current_index = 0
      @content_scroll_offset = 0
      @current_content_lines = []
      @box_content_height = 0 # Will be set during render

      raise "No documentation files (*.md) found in #{@docs_path}" if @pages.empty?

      load_page_content(0) # Load initial page
    end

    # Scans and returns page titles and raw content.
    def load_docs_structure
      Dir.glob(File.join(@docs_path, '*.md')).sort.map do |filepath|
        content = File.read(filepath)
        title = extract_title(content) || format_filename(filepath)
        { title: title, content: content }
      end
    rescue Errno::ENOENT
      []
    end

    # Loads and parses the content for a specific page index.
    def load_page_content(index, width = TTY::Screen.width)
      return unless @pages[index]

      @current_index = index
      @content_scroll_offset = 0
      page_data = @pages[index]
      # Calculate a reasonable width for parsing
      content_width = ([width, MAX_WIDTH].min * 0.7) - 5
      @current_content_lines = TTY::Markdown.parse(
        page_data[:content],
        width: [content_width.to_i, 10].max # Ensure width > 0
      ).lines.map(&:chomp)
    end

    # Main entry point to show the viewer.
    def show
      loop do
        render_page(@current_index)
        handle_input
      end
    rescue TTY::Reader::InputInterrupt
      system 'clear' or system 'cls'
      puts "\nExiting docs viewer. Goodbye!"
    end

    # ... (extract_title and format_filename remain the same) ...
    def extract_title(content)
      first_line = content.lines.find { |line| line.strip.start_with?('# ') }
      first_line ? first_line.sub('# ', '').strip : nil
    end

    def format_filename(filepath)
      File.basename(filepath, '.md')
          .gsub(/^\d+-/, '')
          .tr('_-', ' ')
          .strip
          .capitalize
    end

    # Renders the page.
    def render_page(index)
      system 'clear' or system 'cls'

      page_data = @pages[index]
      term_width = TTY::Screen.width
      term_height = TTY::Screen.height

      outer_width = [term_width, MAX_WIDTH].min
      outer_height = [term_height - 2, MIN_HEIGHT].max
      padding_width = [(term_width - outer_width) / 2, 0].max
      padding = ' ' * padding_width

      inner_width = outer_width - 4
      inner_height = outer_height - 2

      toc_width = [30, (inner_width * 0.3).to_i].max
      content_width = inner_width - toc_width - 1

      # Set instance variable for use in handle_input
      @box_content_height = inner_height - 4 # -2 border, -2 padding

      toc_content = build_toc(index, @box_content_height)
      page_content = build_page_content(content_width, @box_content_height) # No args needed now
      scroll_indicator = build_scroll_indicator

      toc_box_str = TTY::Box.frame(
        toc_content,
        title: { top_left: ' SFL Concepts ' },
        width: toc_width,
        height: inner_height,
        padding: 1,
        style: { border: { fg: :blue } }
      )
      content_box_str = TTY::Box.frame(
        page_content,
        title: {
          top_left: " #{page_data[:title]} ",
          bottom_right: scroll_indicator
        },
        width: content_width,
        height: inner_height,
        padding: [1, 2],
        style: { border: { fg: :green } }
      )

      toc_lines = toc_box_str.lines.map(&:chomp)
      content_lines = content_box_str.lines.map(&:chomp)
      toc_lines = (toc_lines + ([' ' * toc_width] * inner_height)).take(inner_height)
      content_lines = (content_lines + ([' ' * content_width] * inner_height)).take(inner_height)

      inner_layout = inner_height.times.map do |i|
        (toc_lines[i] || '') + ' ' + (content_lines[i] || '')
      end.join("\n")

      outer_box_str = TTY::Box.frame(
        inner_layout,
        title: { top_left: ' Promptly Docs ' },
        width: outer_width,
        height: outer_height,
        padding: 1,
        style: { border: { fg: :yellow } }
      )

      outer_box_str.lines.each { |line| puts padding + line.chomp }

      nav_line = 'Nav: (n/p)topic | (↑/↓/PgUp/PgDn)scroll | (t)oc | (v)full | (q)uit'
      puts "\n" + padding + nav_line.center(outer_width)
    end

    # Builds ToC. (No change)
    def build_toc(current_idx, height)
      lines = @pages.map.with_index do |page, idx|
        if idx == current_idx
          " > \e[1;36m#{page[:title]}\e[0m"
        else
          "   #{page[:title]}"
        end
      end
      lines.take(height).join("\n")
    end

    # Builds *visible* part of content based on scroll offset.
    def build_page_content(_width, height)
      # Ensure offset is valid (might change if content reloads)
      max_offset = [@current_content_lines.size - height, 0].max
      @content_scroll_offset = [[@content_scroll_offset, max_offset].min, 0].max

      visible_lines = @current_content_lines[@content_scroll_offset, height] || []
      # Pad with empty lines if content is shorter than the box
      visible_lines += [''] * (height - visible_lines.size)
      visible_lines.join("\n")
    end

    # Calculates scroll percentage.
    def build_scroll_indicator
      total_lines = @current_content_lines.size
      view_height = @box_content_height
      return '[ --- ]' if total_lines <= view_height

      percentage = total_lines - view_height == 0 ? 100 : (@content_scroll_offset.to_f * 100 / (total_lines - view_height)).round
      "[ #{percentage}% ]"
    end

    # Handles user input, now including scrolling.
    def handle_input
      key = @prompt.keypress(echo: false)
      total_lines = @current_content_lines.size
      view_height = @box_content_height
      max_offset = [total_lines - view_height, 0].max

      case key
      when 'n', 'j' # Next topic
        load_page_content((@current_index + 1) % @pages.size)
      when 'p', 'k' # Previous topic
        load_page_content((@current_index - 1 + @pages.size) % @pages.size)
      when "\e[B" # Down arrow
        @content_scroll_offset = [@content_scroll_offset + 1, max_offset].min
      when "\e[A" # Up arrow
        @content_scroll_offset = [@content_scroll_offset - 1, 0].max
      when "\e[6~" # Page Down
        @content_scroll_offset = [@content_scroll_offset + view_height, max_offset].min
      when "\e[5~" # Page Up
        @content_scroll_offset = [@content_scroll_offset - view_height, 0].max
      when 't', ' ' # Show ToC selection
        select_from_toc
      when 'v' # View full in pager
        view_current_page_in_pager
      when 'q' # Quit
        raise TTY::Reader::InputInterrupt
      else
        # Don't re-render unless a valid key was pressed
        handle_input # Keep listening
      end
    end

    # Shows interactive ToC selection.
    def select_from_toc
      system 'clear' or system 'cls'
      choices = @pages.map { |p| p[:title] }
      selected_key = @prompt.select(
        'Select a topic:', choices, cycle: true, per_page: 10, filter: true
      )
      new_index = @pages.index { |p| p[:title] == selected_key }
      load_page_content(new_index) # Load new content and reset scroll
    end

    # View full page in TTY::Pager.
    def view_current_page_in_pager
      page_data = @pages[@current_index]
      formatted_content = TTY::Markdown.parse(
        page_data[:content], width: TTY::Screen.width - 2
      )
      DocsViewer.view_content_paged(formatted_content)
    end

    # Class method for TTY::Pager.
    def self.view_content_paged(content)
      pager_commands = ['less -R', 'less', 'more', 'pg']
      TTY::Pager.page(command: pager_commands) do |pager|
        pager.write(content)
      end
    rescue TTY::Pager::PagerClosed
    rescue TTY::Pager::NoPagerError
      puts 'Could not find a pager.'
      sleep 1
    rescue StandardError => e
      puts "Paging error: #{e.message}"
      sleep 1
    end
  end
end
