# frozen_string_literal: true

require 'gli' # Ensure GLI is required
require 'tty-prompt' # Ensure TTY-Prompt is available
require_relative 'cli_actions/list_action'
require_relative 'cli_actions/view_action'
require_relative 'cli_actions/edit_action'
require_relative 'cli_actions/config_action'

# The Promptly module serves as a namespace for all the classes and modules
# that make up the Promptly application.
module Promptly
  # The CLI class is the main entry point for the command-line interface.
  # It uses the GLI gem to define commands, options, and arguments.
  class CLI
    extend GLI::App

    program_desc 'Markdown Prompt Viewer/Editor CLI'
    version Promptly::VERSION

    # --- Entry Point ---
    # Call this from your executable (e.g., bin/promptly).
    # NOTE: Ensure $config is loaded before calling this method.
    def self.start(argv)
      if argv.empty?
        show_interactive_menu
      else
        run(argv) # Use GLI's run method
      end
    end

    # --- Interactive Menu ---
    def self.show_interactive_menu
      ui = Promptly::UI.new
      manager = Promptly::Manager.new # Instantiate once, $config is used by Manager's default

      list_action_service = Promptly::CliActions::ListAction.new(ui, manager)
      view_action_service = Promptly::CliActions::ViewAction.new(ui, manager)
      edit_action_service = Promptly::CliActions::EditAction.new(ui, manager, $config) # EditAction uses config
      config_action_service = Promptly::CliActions::ConfigAction.new(ui, manager, $config) # ConfigAction uses config

      loop do
        puts '\\n--- Promptly Menu ---'
        # Added 'List' to menu as it's a common action, was missing from interactive
        choice = ui.select('Choose an action:', %w[List View Edit Config Docs Exit], cycle: true, per_page: 10)
        puts '' # Add a newline for spacing

        case choice
        when 'List'
          result = list_action_service.execute
          ui.display_error(result[:message]) unless result[:success]
          # display_info for total count is handled by ListAction

        when 'View'
          prompts = manager.list_all # Still need to list for selection
          if prompts.empty?
            ui.display_info('No prompts available to view.')
            next
          end
          choices = prompts.map { |p| { name: p.name, value: p.name } }
          choices << { name: '(Cancel)', value: :cancel }
          prompt_name = ui.select('Select a prompt to view:', choices, filter: true)

          next if prompt_name == :cancel

          if prompt_name
            result = view_action_service.execute(prompt_name: prompt_name)
            ui.display_error(result[:message]) unless result[:success]
            # Detailed display or error message (including suggestions) is handled by ViewAction or its result
          end

        when 'Edit'
          edit_sub_choice = ui.select('Action:', %w[Edit_Existing Create_New Cancel], cycle: true)
          prompt_name_to_edit = nil
          force_create_flag = false

          case edit_sub_choice
          when 'Edit_Existing'
            prompts = manager.list_all
            if prompts.empty?
              ui.display_info('No prompts available to edit.')
              next
            end
            choices = prompts.map { |p| { name: p.name, value: p.name } }
            choices << { name: '(Cancel)', value: :cancel }
            prompt_name_to_edit = ui.select('Select a prompt to edit:', choices, filter: true)
            next if prompt_name_to_edit == :cancel
          when 'Create_New'
            prompt_name_to_edit = ui.prompt.ask('Enter the name for the new prompt:') do |q|
              q.required true
              q.modify :strip
            end
            next unless prompt_name_to_edit # Back to main menu if empty/cancelled
            force_create_flag = true # Indicate direct intent to create
          when 'Cancel'
            next
          end

          if prompt_name_to_edit
            result = edit_action_service.execute(prompt_name: prompt_name_to_edit, force_create: force_create_flag)
            # EditAction handles UI feedback for success/warning/error internally
            # It returns { cancelled: true } if user cancels mid-action (e.g., "prompt not found, create?" -> no)
            next if result[:cancelled]
            # If not successful and not cancelled, it's an operational error the action couldn't recover from
            ui.display_error(result[:message]) if !result[:success] && !result[:cancelled]
          end

        when 'Config'
          loop do
            puts '\\n--- Configuration Menu ---'
            config_sub_choice = ui.select('Configure:', %w[List Get Set Back], cycle: true)
            config_params = { sub_action: config_sub_choice.downcase.to_sym }

            case config_sub_choice
            when 'Get'
              key_str = ui.prompt.ask('Enter key:')
              next unless key_str
              config_params[:key] = key_str
            when 'Set'
              key_str = ui.prompt.ask('Enter key:')
              next unless key_str
              value_str = ui.prompt.ask("Enter value for #{key_str}:")
              # Allow empty string for value, but not nil if cancelled
              next if value_str.nil? # User cancelled value input
              config_params[:key] = key_str
              config_params[:value] = value_str
            when 'Back'
              break
            end

            result = config_action_service.execute(config_params)
            # ConfigAction handles its own UI output for list/get/set success.
            # It will return success:false and a message for errors.
            ui.display_error(result[:message]) unless result[:success]

            puts ''
            ui.prompt.keypress('Press any key to return to Config menu...') unless config_sub_choice == 'Back'
            system 'clear' or system 'cls' # Original screen clearing
          end

        when 'Exit'
          ui.display_info('Exiting Promptly. Goodbye!')
          break
        end

        next if choice == 'Exit'

        puts ''
        ui.prompt.keypress('Press any key to return to the menu...')
        system 'clear' or system 'cls'
      end
    end

    # --- GLI Command Definitions ---

    desc 'View interactive documentation (SFL Concepts)'
    command :docs do |c|
      c.action do |_global_options, _options, _args|
        # This command remains unchanged as it uses a specific DocsViewer
        Promptly::DocsViewer.new.show
      rescue StandardError => e
        # Keep UI instantiation local for commands if they don't share state
        ui = Promptly::UI.new
        ui.display_error("Failed to view docs: #{e.message}\n#{e.backtrace.join("\n")}")
        exit_now!(1)
      end
    end

    desc 'List all available prompts'
    command :list do |c|
      c.action do |_global_options, _options, _args|
        ui = Promptly::UI.new
        manager = Promptly::Manager.new
        action = Promptly::CliActions::ListAction.new(ui, manager)
        result = action.execute

        # ListAction handles its own display, including total count.
        # It returns success:false on error.
        unless result[:success]
          ui.display_error(result[:message] || 'Failed to list prompts.')
          exit_now!(1)
        end
      end
    end

    desc 'View details of a specific prompt'
    arg_name 'name'
    command :view do |c|
      c.action do |_global_options, _options, args|
        ui = Promptly::UI.new
        if args.empty?
          ui.display_error('Please provide a prompt name.')
          exit_now!(1)
        end

        manager = Promptly::Manager.new
        action = Promptly::CliActions::ViewAction.new(ui, manager)
        prompt_name = args.first
        result = action.execute(prompt_name: prompt_name)

        # ViewAction handles displaying the prompt or an error message (including suggestions).
        unless result[:success]
          ui.display_error(result[:message] || "Failed to view prompt '#{prompt_name}'.")
          exit_now!(1)
        end
      end
    end

    desc 'Edit a prompt'
    arg_name 'name'
    command :edit do |c|
      c.action do |_global_options, _options, args|
        ui = Promptly::UI.new
        if args.empty?
          ui.display_error('Please provide a prompt name.')
          exit_now!(1)
        end

        manager = Promptly::Manager.new
        action = Promptly::CliActions::EditAction.new(ui, manager, $config)
        prompt_name = args.first
        # For GLI 'edit', force_create is false by default in EditAction,
        # so it will ask to create if the prompt doesn't exist.
        result = action.execute(prompt_name: prompt_name)

        # EditAction handles most UI feedback internally.
        # It returns { cancelled: true } if user cancels mid-action.
        if result[:cancelled]
          # ui.display_info(result[:message] || "Edit operation cancelled.") # Optional, EditAction might have said enough
          exit_now!(0) # Not an error, user cancelled
        elsif !result[:success]
          ui.display_error(result[:message] || "Failed to edit prompt '#{prompt_name}'.")
          exit_now!(1)
        end
        # Success messages are handled by EditAction
      end
    end

    desc 'Configuration management'
    command :config do |c|
      c.desc 'Get configuration value'
      c.arg_name 'key'
      c.command :get do |get_cmd|
        get_cmd.action do |_global_options, _options, args|
          ui = Promptly::UI.new
          if args.empty?
            ui.display_error('Please provide a configuration key.')
            exit_now!(1)
          end

          manager = Promptly::Manager.new # Not strictly needed by ConfigAction but consistent
          action = Promptly::CliActions::ConfigAction.new(ui, manager, $config)
          key_str = args.first
          result = action.execute(sub_action: :get, key: key_str)

          # ConfigAction:get handles its own success display.
          unless result[:success]
            ui.display_error(result[:message] || "Failed to get config key '#{key_str}'.")
            exit_now!(1)
          end
        end
      end

      c.desc 'Set configuration value'
      c.arg_name 'key value'
      c.command :set do |set_cmd|
        set_cmd.action do |_global_options, _options, args|
          ui = Promptly::UI.new
          if args.size < 2
            ui.display_error('Please provide both key and value.')
            exit_now!(1)
          end

          manager = Promptly::Manager.new
          action = Promptly::CliActions::ConfigAction.new(ui, manager, $config)
          key_str = args[0]
          value = args[1..].join(' ') # Handle values with spaces
          result = action.execute(sub_action: :set, key: key_str, value: value)

          # ConfigAction:set handles its own success display.
          unless result[:success]
            ui.display_error(result[:message] || "Failed to set config key '#{key_str}'.")
            exit_now!(1)
          end
        end
      end

      c.desc 'List all configuration values'
      c.command :list do |list_cmd|
        list_cmd.action do |_global_options, _options, _args|
          ui = Promptly::UI.new
          manager = Promptly::Manager.new
          action = Promptly::CliActions::ConfigAction.new(ui, manager, $config)
          result = action.execute(sub_action: :list)

          # ConfigAction:list handles its own display.
          unless result[:success]
            ui.display_error(result[:message] || 'Failed to list configurations.')
            exit_now!(1)
          end
        end
      end
    end
    # Removed private clear_screen method as it was unused.
    # Removed self.create_prompt_template method as it was moved to EditAction.
  end
end
