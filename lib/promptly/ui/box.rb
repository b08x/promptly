# lib/promptly/ui/box.rb
# frozen_string_literal: true

require "tty-box"
require "tty-screen"

module Promptly
  class UI
    # Provides methods for creating and displaying pre-styled boxes.
    module Box
      module_function

      TITLE_WIDTH = 80 # Define the missing constant

      # Creates a box containing two texts side-by-side for comparison.
      # NOTE: Original code did vertical (box1 + box2). Changed to array.
      def comparison_box(text1, text2, title1: "Text 1", title2: "Text 2")
        screen_width = TTY::Screen.width - 2
        # Adjusted width calc for side-by-side
        box_width = [(screen_width / 2) - 2, 40].max # Each box ~half screen, min 40

        box1 = TTY::Box.frame(width: box_width, title: { top_left: title1 }, padding: 1) { text1 }
        box2 = TTY::Box.frame(width: box_width, title: { top_left: title2 }, padding: 1) { text2 }

        # For actual side-by-side display, the caller needs to handle layout.
        # This method can return both boxes for the caller to arrange.
        [box1, box2]
      end

      def eval_result_box(result, title: "Evaluation Result")
        TTY::Box.success(
          result,
          title: { top_left: title },
          width: 80,
          height: [(TTY::Screen.height / 1.25).round, 10].max, # Min height 10
          padding: 1
        )
      end

      def exception_box(message)
        TTY::Box.error(
          message,
          title: { top_left: "Error" },
          width: [TTY::Screen.width - 2, TITLE_WIDTH].min,
          padding: 1
        )
      end

      def info_box(message, title: "Info")
        TTY::Box.info(
          message,
          title: { top_left: title },
          width: [TTY::Screen.width - 2, 50].min,
          padding: 1
        )
      end

      def multi_column_box(data, titles)
        return TTY::Box.frame("No data provided.", width: 30) if data.empty?

        max_widths = data.transpose.map { |col| col.map(&:to_s).map(&:length).max }
        # Ensure titles width is also considered
        titles.each_with_index { |t, i| max_widths[i] = [max_widths[i], t.length].max }

        total_width = max_widths.sum + (3 * (max_widths.size - 1)) + 4

        rows = data.map do |row|
          row.zip(max_widths).map { |cell, width| cell.to_s.ljust(width) }.join(" | ")
        end

        header = titles.zip(max_widths).map { |title, width| title.to_s.ljust(width) }.join(" | ")
        separator = max_widths.map { |w| "-" * w }.join("-+-")

        content = [header, separator, rows.join("\n")].join("\n")

        TTY::Box.frame(content, width: [total_width, TTY::Screen.width - 2].min, padding: 1)
      end
    end
  end
end