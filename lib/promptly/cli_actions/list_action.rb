# frozen_string_literal: true

module Promptly
  module CliActions
    # Handles the logic for listing all available prompts.
    class ListAction
      # Initializes a new ListAction.
      #
      # @param ui [Promptly::UI] The UI service for output.
      # @param manager [Promptly::Manager] The prompt management service.
      # @param _config [Hash] The application configuration (currently unused by list).
      def initialize(ui, manager, _config = $config)
        @ui = ui
        @manager = manager
      end

      # Executes the list action.
      # Fetches all prompts, displays them in a table, and shows a total count.
      #
      # @param _params [Hash] (optional) Not used by this action.
      # @return [Hash] A result hash, e.g.,
      #   { success: true, data: { count: Integer } } or
      #   { success: false, message: String }
      def execute(_params = {})
        prompts = @manager.list_all
        @ui.display_prompt_table(prompts)
        @ui.display_info("\\nTotal: #{prompts.size} prompt(s) found") if prompts.any?
        { success: true, data: { count: prompts.size } }
      rescue StandardError => e
        { success: false, message: "Failed to list prompts: #{e.message}" }
      end
    end
  end
end