# lib/promptly/ui/scrollable_box.rb
# frozen_string_literal: true

require "tty-box"
require "tty-screen"
require "io/console" # Needed for STDIN.getch

module Promptly
  class UI
    # Provides methods for creating and displaying side-by-side scrollable boxes.
    module ScrollableBox
      module_function

      # Creates and displays two scrollable boxes side-by-side for comparison.
      def side_by_side_boxes(text1, text2, title1: "Box 1", title2: "Box 2")
        screen_width = TTY::Screen.width
        screen_height = TTY::Screen.height
        # Ensure boxes fit side-by-side with a gap
        box_width = (screen_width / 2) - 2
        box_height = screen_height - 6 # Leave space for prompts/status

        # Ensure minimum dimensions
        box_width = [box_width, 30].max
        box_height = [box_height, 10].max

        box1 = create_scrollable_box(text1, box_width, box_height, title1)
        box2 = create_scrollable_box(text2, box_width, box_height, title2)

        display_boxes(box1, box2, box_height)
      end

      private

      # Creates a scrollable box data structure.
      def create_scrollable_box(text, width, height, title)
        lines = text.to_s.split("\n")
        page_height = height - 2 # -2 for box borders
        total_pages = [(lines.length.to_f / page_height).ceil, 1].max # At least 1 page
        {
          title: title,
          lines: lines,
          width: width,
          height: height,
          page_height: page_height,
          total_pages: total_pages,
          current_page: 1
        }
      end

      # Displays the scrollable boxes and handles user navigation.
      def display_boxes(box1, box2, box_height)
        loop do
          system("clear") || system("cls")
          print_boxes(box1, box2, box_height)
          print_navigation_info(box1, box2)

          input = STDIN.getch
          # Handle CTRL+C for exit
          break if input == "\u0003"

          case input.downcase
          when "q" then break
          when "a" then box1[:current_page] = [1, box1[:current_page] - 1].max
          when "d" then box1[:current_page] = [box1[:total_pages], box1[:current_page] + 1].min
          when "j" then box2[:current_page] = [1, box2[:current_page] - 1].max
          when "l" then box2[:current_page] = [box2[:total_pages], box2[:current_page] + 1].min
          end
        end
      end

      # Prints the scrollable boxes to the console.
      def print_boxes(box1, box2, box_height)
        start_line1 = (box1[:current_page] - 1) * box1[:page_height]
        start_line2 = (box2[:current_page] - 1) * box2[:page_height]

        box1_content_lines = box1[:lines][start_line1, box1[:page_height]] || []
        box2_content_lines = box2[:lines][start_line2, box2[:page_height]] || []
        # Pad lines to ensure equal height for zipping
        max_h = [box1_content_lines.size, box2_content_lines.size, box1[:page_height]].max
        box1_content_lines += [""] * (max_h - box1_content_lines.size)
        box2_content_lines += [""] * (max_h - box2_content_lines.size)

        box1_content = box1_content_lines.join("\n")
        box2_content = box2_content_lines.join("\n")

        box1_frame = TTY::Box.frame(width: box1[:width], height: box_height, title: { top_left: box1[:title] }) do
          box1_content
        end
        box2_frame = TTY::Box.frame(width: box2[:width], height: box_height, title: { top_left: box2[:title] }) do
          box2_content
        end

        puts box1_frame.split("\n").zip(box2_frame.split("\n")).map { |a, b| "#{a}  #{b}" }.join("\n")
      end

      # Prints navigation information.
      def print_navigation_info(box1, box2)
        puts "Box 1: Page #{box1[:current_page]}/#{box1[:total_pages]} | Box 2: Page #{box2[:current_page]}/#{box2[:total_pages]}"
        puts "(A/D to scroll Box 1) | (J/L to scroll Box 2) | (Q to exit)"
      end
    end
  end
end