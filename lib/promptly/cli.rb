# frozen_string_literal: true

require 'gli' # Ensure GLI is required
require 'tty-prompt' # Ensure TTY-Prompt is available

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
      manager = Promptly::Manager.new # Instantiate once

      loop do
        puts '\\n--- Promptly Menu ---'
        choice = ui.select('Choose an action:', %w[View Edit Config Docs Exit], cycle: true, per_page: 10)
        puts '' # Add a newline for spacing

        case choice
        # when 'List'
        #   # --- Duplicated 'list' action ---
        #   begin
        #     # manager and ui are already available
        #     prompts = manager.list_all
        #     ui.display_prompt_table(prompts)
        #     puts "\\nTotal: #{prompts.size} prompt(s) found" if prompts.any?
        #   rescue StandardError => e
        #     ui.display_error("Failed to list prompts: #{e.message}")
        #     # Don't exit, just loop back
        #   end
        #   # --- End Duplicated 'list' action ---

        when 'View'
          # --- Duplicated 'view' action (with prompt) ---
          prompts = manager.list_all
          if prompts.empty?
            ui.display_info('No prompts available to view.')
            next # Go back to main menu
          end
          choices = prompts.map { |p| { name: p.name, value: p.name } }
          choices << { name: '(Cancel)', value: :cancel }
          prompt_name = ui.select('Select a prompt to view:', choices, filter: true)

          next if prompt_name == :cancel # Go back if cancelled

          args = [prompt_name] # Simulate args

          begin
            prompt = manager.find_by_name(prompt_name)

            if prompt
              ui.display_prompt_details(prompt)
            else
              ui.display_error("Prompt '#{prompt_name}' not found")
              all_prompts = manager.list_all
              suggestions = all_prompts.select { |p| p.name.downcase.include?(prompt_name.downcase) }
              if suggestions.any?
                puts '\\nDid you mean one of these?'
                suggestions.each { |p| puts "  - #{p.name}" }
              end
            end
          rescue Promptly::ParseError => e
            ui.display_error(e.message)
          rescue StandardError => e
            ui.display_error("Failed to view prompt: #{e.message}")
          end
          # --- End Duplicated 'view' action ---

        when 'Edit'
          # --- Duplicated 'edit' action (with prompt) ---
          action = ui.select('Action:', %w[Edit_Existing Create_New Cancel], cycle: true)
          prompt_name = nil

          case action
          when 'Edit_Existing'
            prompts = manager.list_all
            if prompts.empty?
              ui.display_info('No prompts available to edit.')
              next # Back to main menu
            end
            choices = prompts.map { |p| { name: p.name, value: p.name } }
            choices << { name: '(Cancel)', value: :cancel }
            prompt_name = ui.select('Select a prompt to edit:', choices, filter: true)
            next if prompt_name == :cancel

          when 'Create_New'
            prompt_name = ui.prompt.ask('Enter the name for the new prompt:') do |q|
              q.required true
              q.modify :strip
            end
            next unless prompt_name # Back to main menu if empty/cancelled

          when 'Cancel'
            next # Back to main menu
          end

          next unless prompt_name # Ensure we have a name

          args = [prompt_name] # Simulate args

          begin
            prompt = manager.find_by_name(prompt_name)
            filepath = nil

            if prompt
              filepath = prompt.filepath
              ui.display_info("Editing existing prompt: #{prompt.name}")
            else
              prompts_dir = $config.fetch(:prompts_directory)
              filepath = File.join(prompts_dir, "#{prompt_name}.md")

              next unless ui.confirm("Prompt '#{prompt_name}' not found. Create new prompt?")

              template_content = create_prompt_template(prompt_name)
              File.write(filepath, template_content)
              ui.display_success("Created new prompt file: #{filepath}")

              # User cancelled creation, go back to menu

            end

            editor = TTY::Editor
            editor_command = $config.fetch(:default_editor)

            opened = editor_command ? editor.open(filepath, command: editor_command) : editor.open(filepath)

            if opened
              begin
                updated_prompt = manager.find_by_name(prompt_name)
                if updated_prompt
                  ui.display_success("Successfully updated prompt: #{prompt_name}")
                else
                  ui.display_warning('Prompt saved, but there may be parsing issues')
                end
              rescue Promptly::ParseError => e
                ui.display_warning("Prompt saved, but has parsing errors: #{e.message}")
              end
            else
              ui.display_error('Failed to open editor')
            end
          rescue Promptly::ParseError => e
            ui.display_error("Parse error: #{e.message}")
          rescue StandardError => e
            ui.display_error("Failed to edit prompt: #{e.message}\\n#{e.backtrace.join("\n")}")
          end
          # --- End Duplicated 'edit' action ---

        when 'Config'
          # --- Sub-Menu for Config ---
          loop do
            puts '\\n--- Configuration Menu ---'
            config_choice = ui.select('Configure:', %w[List Get Set Back], cycle: true)
            case config_choice
            when 'List'
              # --- Duplicated 'config list' ---
              begin
                config_hash = $config.to_h
                if config_hash.empty?
                  ui.display_info('No configuration values set')
                else
                  table = TTY::Table.new(
                    header: %w[Key Value],
                    rows: config_hash.map { |k, v| [k, v] }
                  )
                  puts table.render(:unicode, padding: [0, 1])
                end
              rescue StandardError => e
                ui.display_error("Failed to list configuration: #{e.message}")
              end
              # --- End Duplicated 'config list' ---

            when 'Get'
              # --- Duplicated 'config get' (with prompt) ---
              key_str = ui.prompt.ask('Enter key:')
              next unless key_str # Go back if cancelled

              key = key_str.to_sym
              begin
                value = $config.fetch(key)
                puts "#{key}: #{value}"
              rescue KeyError
                ui.display_error("Configuration key '#{key}' not found")
                puts '\\nAvailable configuration keys:'
                $config.to_h.keys.each { |k| puts "  - #{k}" }
              rescue StandardError => e
                ui.display_error("Failed to get configuration: #{e.message}")
              end
              # --- End Duplicated 'config get' ---

            when 'Set'
              # --- Duplicated 'config set' (with prompt) ---
              key_str = ui.prompt.ask('Enter key:')
              next unless key_str # Go back if cancelled

              value = ui.prompt.ask("Enter value for #{key_str}:")
              next unless value # Go back if cancelled

              key = key_str.to_sym
              begin
                $config.set(key, value: value)
                config_file = File.join(Dir.home, '.config', 'promptly', 'config.yml')
                FileUtils.mkdir_p(File.dirname(config_file))
                $config.write(config_file, format: :yaml, force: true)
                ui.display_success("Set #{key} = #{value}")
              rescue StandardError => e
                ui.display_error("Failed to set configuration: #{e.message}")
              end
              # --- End Duplicated 'config set' ---

            when 'Back'
              break # Exit config sub-menu
            end
            puts ''
            ui.prompt.keypress('Press any key to return to Config menu...') unless config_choice == 'Back'
            system 'clear' or system 'cls'
          end
          # --- End Sub-Menu for Config ---

        when 'Exit'
          ui.display_info('Exiting Promptly. Goodbye!')
          break # Exit the main loop
        end

        # Don't prompt if exiting
        next if choice == 'Exit'

        puts '' # Add a newline
        ui.prompt.keypress('Press any key to return to the menu...')
        system 'clear' or system 'cls' # Clear screen for next menu display
      end
    end

    # --- GLI Command Definitions (UNCHANGED) ---

    # Defines the 'docs' command.
    # This command displays interactive documentation.
    desc 'View interactive documentation (SFL Concepts)'
    command :docs do |c|
      c.action do |_global_options, _options, _args|
        Promptly::DocsViewer.new.show
      rescue StandardError => e
        ui = Promptly::UI.new
        ui.display_error("Failed to view docs: #{e.message}\n#{e.backtrace.join("\n")}")
        exit_now!(1)
      end
    end

    desc 'List all available prompts'
    command :list do |c|
      c.action do |_global_options, _options, _args|
        manager = Promptly::Manager.new
        ui = Promptly::UI.new

        begin
          prompts = manager.list_all
          ui.display_prompt_table(prompts)
          puts "\\nTotal: #{prompts.size} prompt(s) found" if prompts.any?
        rescue StandardError => e
          ui = Promptly::UI.new # This line is redundant but in original
          ui.display_error("Failed to list prompts: #{e.message}")
          exit_now!(1)
        end
      end
    end

    desc 'View details of a specific prompt'
    arg_name 'name'
    command :view do |c|
      c.action do |_global_options, _options, args|
        if args.empty?
          ui = Promptly::UI.new
          ui.display_error('Please provide a prompt name')
          exit_now!(1)
        end

        prompt_name = args.first

        begin
          manager = Promptly::Manager.new
          ui = Promptly::UI.new

          prompt = manager.find_by_name(prompt_name)

          if prompt
            ui.display_prompt_details(prompt)
          else
            ui.display_error("Prompt '#{prompt_name}' not found")

            # Suggest similar prompts
            all_prompts = manager.list_all
            suggestions = all_prompts.select { |p| p.name.downcase.include?(prompt_name.downcase) }

            if suggestions.any?
              puts '\\nDid you mean one of these?'
              suggestions.each { |p| puts "  - #{p.name}" }
            end

            exit_now!(1)
          end
        rescue Promptly::ParseError => e
          ui = Promptly::UI.new
          ui.display_error(e.message)
          exit_now!(1)
        rescue StandardError => e
          ui = Promptly::UI.new
          ui.display_error("Failed to view prompt: #{e.message}")
          exit_now!(1)
        end
      end
    end

    desc 'Edit a prompt'
    arg_name 'name'
    command :edit do |c|
      c.action do |_global_options, _options, args|
        if args.empty?
          ui = Promptly::UI.new
          ui.display_error('Please provide a prompt name')
          exit_now!(1)
        end

        prompt_name = args.first
        ui = Promptly::UI.new

        begin
          manager = Promptly::Manager.new

          prompt = manager.find_by_name(prompt_name)
          filepath = nil

          if prompt
            filepath = prompt.filepath
            ui.display_info("Editing existing prompt: #{prompt.name}")
          else
            prompts_dir = $config.fetch(:prompts_directory)
            filepath = File.join(prompts_dir, "#{prompt_name}.md")

            if ui.confirm("Prompt '#{prompt_name}' not found. Create new prompt?")
              template_content = create_prompt_template(prompt_name)
              File.write(filepath, template_content)
              ui.display_success("Created new prompt file: #{filepath}")
            else
              exit_now!(0)
            end
          end

          editor = TTY::Editor
          editor_command = $config.fetch(:default_editor, nil) # Fetch with nil default

          opened = editor_command ? editor.open(filepath, command: editor_command) : editor.open(filepath)

          if opened
            begin
              updated_prompt = manager.find_by_name(prompt_name)
              if updated_prompt
                ui.display_success("Successfully updated prompt: #{prompt_name}")
              else
                ui.display_warning('Prompt saved, but there may be parsing issues')
              end
            rescue Promptly::ParseError => e
              ui.display_warning("Prompt saved, but has parsing errors: #{e.message}")
            end
          else
            ui.display_error('Failed to open editor')
            exit_now!(1)
          end
        rescue Promptly::ParseError => e
          ui.display_error("Parse error: #{e.message}")
          exit_now!(1)
        rescue StandardError => e
          ui.display_error("Failed to edit prompt: #{e.message}\\n#{e.backtrace.join("\n")}")
          exit_now!(1)
        end
      end
    end

    desc 'Configuration management'
    command :config do |c|
      c.desc 'Get configuration value'
      c.arg_name 'key'
      c.command :get do |get_cmd|
        get_cmd.action do |_global_options, _options, args|
          if args.empty?
            ui = Promptly::UI.new
            ui.display_error('Please provide a configuration key')
            exit_now!(1)
          end

          key = args.first.to_sym
          ui = Promptly::UI.new

          begin
            value = $config.fetch(key)
            puts "#{key}: #{value}"
          rescue KeyError # TTY::Config raises KeyError
            ui.display_error("Configuration key '#{key}' not found")
            puts '\\nAvailable configuration keys:'
            $config.to_h.keys.each { |k| puts "  - #{k}" }
            exit_now!(1)
          rescue StandardError => e
            ui.display_error("Failed to get configuration: #{e.message}")
            exit_now!(1)
          end
        end
      end

      c.desc 'Set configuration value'
      c.arg_name 'key value'
      c.command :set do |set_cmd|
        set_cmd.action do |_global_options, _options, args|
          if args.size < 2
            ui = Promptly::UI.new
            ui.display_error('Please provide both key and value')
            exit_now!(1)
          end

          key = args[0].to_sym
          value = args[1..-1].join(' ')
          ui = Promptly::UI.new

          begin
            $config.set(key, value: value)
            config_file = File.join(Dir.home, '.config', 'promptly', 'config.yml')
            FileUtils.mkdir_p(File.dirname(config_file))
            $config.write(config_file, format: :yaml, force: true) # Use force: true
            ui.display_success("Set #{key} = #{value}")
          rescue StandardError => e
            ui.display_error("Failed to set configuration: #{e.message}")
            exit_now!(1)
          end
        end
      end

      c.desc 'List all configuration values'
      c.command :list do |list_cmd|
        list_cmd.action do |_global_options, _options, _args|
          ui = Promptly::UI.new

          begin
            config_hash = $config.to_h

            if config_hash.empty?
              ui.display_info('No configuration values set')
            else
              table = TTY::Table.new(
                header: %w[Key Value],
                rows: config_hash.map { |k, v| [k, v] }
              )
              puts table.render(:unicode, padding: [0, 1])
            end
          rescue StandardError => e
            ui.display_error("Failed to list configuration: #{e.message}")
            exit_now!(1)
          end
        end
      end
    end

    private

    def clear_screen
      system('clear') || system('cls')
    end

    # Make this a class method so it can be called from show_interactive_menu
    def self.create_prompt_template(name)
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
