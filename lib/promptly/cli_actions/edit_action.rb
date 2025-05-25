# frozen_string_literal: true

require 'tty-editor'
require 'fileutils'

module Promptly
  module CliActions
    # Handles the logic for editing an existing prompt or creating a new one.
    class EditAction
      # Initializes a new EditAction.
      #
      # @param ui [Promptly::UI] The UI service for output.
      # @param manager [Promptly::Manager] The prompt management service.
      # @param config [Hash] The application configuration.
      def initialize(ui, manager, config = $config)
        @ui = ui
        @manager = manager
        @config = config
      end

      # Executes the edit/create action for a given prompt name.
      #
      # @param params [Hash] Expected to contain :prompt_name.
      #   Can also contain :force_create (Boolean, defaults to false).
      #   If :force_create is true, it will create the prompt if it doesn't exist
      #   (after confirming the name if it was interactively provided).
      #   If :force_create is false and prompt doesn't exist, it will ask to create.
      #   e.g., { prompt_name: String, force_create: Boolean }
      # @return [Hash] A result hash, e.g.,
      #   { success: true, status: :updated/:created, prompt_name: String }
      #   { success: true, status: :saved_with_issues, prompt_name: String, message: String }
      #   { success: false, message: String, cancelled: Boolean }
      def execute(params = {})
        prompt_name = params[:prompt_name]
        force_create = params.fetch(:force_create, false)

        unless prompt_name&.strip&.empty? == false
          return { success: false, message: "Please provide a prompt name." }
        end

        prompt = @manager.find_by_name(prompt_name)
        filepath = nil
        action_status = :updated # Assume update initially

        if prompt
          filepath = prompt.filepath
          @ui.display_info("Editing existing prompt: #{prompt.name}")
        else
          prompts_dir = @config.fetch(:prompts_directory)
          filepath = File.join(prompts_dir, "#{prompt_name}.md")
          action_status = :created

          if force_create # Coming from "Create New" or similar direct intent
            # If name was from user input, good to confirm, but plan implies CLI handles this.
            # For now, assume prompt_name is confirmed if force_create is true.
            # Or, if this action is also used by interactive "Create New", it might ask name here.
            # Let's assume prompt_name is final.
          else # Coming from "edit <name>" where name might not exist
            unless @ui.confirm("Prompt '#{prompt_name}' not found. Create new prompt?")
              return { success: false, message: "Edit cancelled: Prompt not created.", cancelled: true }
            end
          end
          # Create the file with a template
          template_content = create_prompt_template(prompt_name)
          FileUtils.mkdir_p(File.dirname(filepath))
          File.write(filepath, template_content)
          @ui.display_success("Created new prompt file: #{filepath}")
        end

        editor_command = @config.fetch(:default_editor, nil)
        opened = TTY::Editor.open(filepath, command: editor_command)

        unless opened
          return { success: false, message: "Failed to open editor for #{filepath}." }
        end

        # Check prompt after edit
        begin
          updated_prompt = @manager.find_by_name(prompt_name) # Re-load to check for parse errors
          if updated_prompt
            @ui.display_success("Successfully #{action_status} prompt: #{prompt_name}")
            return { success: true, status: action_status, prompt_name: prompt_name }
          else
            # This case implies the file exists but couldn't be parsed into a Prompt object,
            # or was deleted/renamed during edit in a way find_by_name fails.
            message = "Prompt file saved for '#{prompt_name}', but it could not be loaded/parsed correctly after edit."
            @ui.display_warning(message)
            return { success: true, status: :saved_with_issues, prompt_name: prompt_name, message: message }
          end
        rescue Promptly::ParseError => e
          message = "Prompt file saved for '#{prompt_name}', but it has parsing errors: #{e.message}"
          @ui.display_warning(message)
          return { success: true, status: :saved_with_issues, prompt_name: prompt_name, message: message }
        end

      rescue Promptly::ParseError => e # Should be caught by inner block, but as fallback
        { success: false, message: "Parse error: #{e.message}" }
      rescue StandardError => e
        # Consider logging e.backtrace here
        { success: false, message: "Failed to edit prompt '#{prompt_name}': #{e.message}" }
      end

      private

      # Creates a basic template string for a new prompt.
      # This method was moved from Promptly::CLI.
      # @param name [String] The name of the prompt.
      # @return [String] The template content.
      def create_prompt_template(name)
        <<~TEMPLATE
          ---
          name: #{name}
          description: A brief description of what this prompt does
          variables: []
          ---

          # #{name.capitalize} Prompt

          Write your prompt content here...
        TEMPLATE
      end
    end
  end
end