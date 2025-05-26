# frozen_string_literal: true

module Promptly
  module CliActions
    # Handles the logic for viewing a specific prompt.
    class ViewAction
      # Initializes a new ViewAction.
      #
      # @param ui [Promptly::UI] The UI service for output.
      # @param manager [Promptly::Manager] The prompt management service.
      # @param _config [Hash] The application configuration (currently unused by view).
      def initialize(ui, manager, _config = $config)
        @ui = ui
        @manager = manager
      end

      # Executes the view action for a given prompt name.
      #
      # @param params [Hash] Expected to contain :prompt_name.
      #   e.g., { prompt_name: String }
      # @return [Hash] A result hash, e.g.,
      #   { success: true, data: { prompt: Promptly::Prompt } } or
      #   { success: false, message: String, data: { suggestions: Array<String> } }
      def execute(params = {})
        prompt_name = params[:prompt_name]
        unless prompt_name
          return { success: false, message: "Please provide a prompt name to view." }
        end

        prompt = @manager.find_by_name(prompt_name)

        if prompt
          @ui.display_prompt_details(prompt)
          { success: true, data: { prompt: prompt.to_h } } # Convert to hash for data
        else
          message = "Prompt '#{prompt_name}' not found."
          suggestions = suggest_similar_prompts(prompt_name)
          if suggestions.any?
            suggestion_text = "\\nDid you mean one of these?\\n" + suggestions.map { |p_name| "  - #{p_name}" }.join("\\n")
            # The CLI will be responsible for displaying this part of the message via UI if desired.
            message += suggestion_text
          end
          { success: false, message: message, data: { suggestions: suggestions } }
        end
      rescue Promptly::ParseError => e
        { success: false, message: e.message }
      rescue StandardError => e
        # Consider logging e.backtrace here for debugging
        { success: false, message: "Failed to view prompt '#{prompt_name}': #{e.message}" }
      end

      private

      def suggest_similar_prompts(name)
        all_prompts = @manager.list_all
        all_prompts.select { |p| p.name.downcase.include?(name.downcase) }.map(&:name)
      end
    end
  end
end