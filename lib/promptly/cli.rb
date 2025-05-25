# frozen_string_literal: true

# The Promptly module serves as a namespace for all the classes and modules
# that make up the Promptly application.
module Promptly
  # The CLI class is the main entry point for the command-line interface.
  # It uses the GLI gem to define commands, options, and arguments.
  class CLI
    extend GLI::App

    program_desc 'Markdown Prompt Viewer/Editor CLI'
    version Promptly: VERSION

    # Defines the 'list' command.
    # This command lists all available prompts found in the configured prompts directory.
    desc 'List all available prompts'
    command :list do |c|
      # The action block for the 'list' command.
      # It initializes a PromptLoader and UI, fetches all prompts,
      # and displays them in a table.
      #
      # @param _global_options [GLI::GlobalOptions] global options (not used)
      # @param _options [GLI::Options] command-specific options (not used)
      # @param _args [Array<String>] command arguments (not used)
      # @raise [StandardError] if any error occurs during the listing process.
      c.action do |_global_options, _options, _args|
        loader = Promptly::PromptLoader.new
        ui = Promptly::UI.new

        prompts = loader.list_all
        ui.display_prompt_table(prompts)
        puts "\nTotal: #{prompts.size} prompt(s) found" if prompts.any?
      rescue StandardError => e
        ui = Promptly::UI.new
        ui.display_error("Failed to list prompts: #{e.message}")
        exit_now!(1)
      end
    end

    # Defines the 'show' command.
    # This command displays the details of a specific prompt.
    desc 'Show details of a specific prompt'
    arg_name 'name'
    command :show do |c|
      # The action block for the 'show' command.
      # It requires a prompt name as an argument. It then loads and displays
      # the details of the specified prompt. If the prompt is not found,
      # it suggests similar prompts.
      #
      # @param _global_options [GLI::GlobalOptions] global options (not used)
      # @param _options [GLI::Options] command-specific options (not used)
      # @param args [Array<String>] command arguments, expecting the prompt name
      # @raise [Promptly::ParseError] if the prompt file has parsing errors.
      # @raise [StandardError] if any other error occurs during the process.
      c.action do |_global_options, _options, args|
        if args.empty?
          ui = Promptly::UI.new
          ui.display_error('Please provide a prompt name')
          exit_now!(1)
        end

        prompt_name = args.first

        begin
          loader = Promptly::PromptLoader.new
          ui = Promptly::UI.new

          prompt = loader.find_by_name(prompt_name)

          if prompt
            ui.display_prompt_details(prompt)
          else
            ui.display_error("Prompt '#{prompt_name}' not found")

            # Suggest similar prompts
            all_prompts = loader.list_all
            suggestions = all_prompts.select { |p| p.name.downcase.include?(prompt_name.downcase) }

            if suggestions.any?
              puts "\nDid you mean one of these?"
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
          ui.display_error("Failed to show prompt: #{e.message}")
          exit_now!(1)
        end
      end
    end

    # Defines the 'edit' command.
    # This command allows editing an existing prompt or creating a new one.
    desc 'Edit a prompt'
    arg_name 'name'
    command :edit do |c|
      # The action block for the 'edit' command.
      # It requires a prompt name as an argument. If the prompt exists, it opens
      # it in the configured editor. If not, it offers to create a new prompt
      # file with a basic template. After editing, it attempts to validate the prompt.
      #
      # @param _global_options [GLI::GlobalOptions] global options (not used)
      # @param _options [GLI::Options] command-specific options (not used)
      # @param args [Array<String>] command arguments, expecting the prompt name
      # @raise [Promptly::ParseError] if the prompt file has parsing errors after editing.
      # @raise [StandardError] if any other error occurs during the process.
      c.action do |_global_options, _options, args|
        if args.empty?
          ui = Promptly::UI.new
          ui.display_error('Please provide a prompt name')
          exit_now!(1)
        end

        prompt_name = args.first
        ui = Promptly::UI.new

        begin
          loader = Promptly::PromptLoader.new

          # Find existing prompt or create new one
          prompt = loader.find_by_name(prompt_name)
          filepath = nil

          if prompt
            filepath = prompt.filepath
            ui.display_info("Editing existing prompt: #{prompt.name}")
          else
            # Create new prompt file
            prompts_dir = $config.fetch(:prompts_directory)
            filepath = File.join(prompts_dir, "#{prompt_name}.md")

            if ui.confirm("Prompt '#{prompt_name}' not found. Create new prompt?")
              # Create basic template
              template_content = create_prompt_template(prompt_name)
              File.write(filepath, template_content)
              ui.display_success("Created new prompt file: #{filepath}")
            else
              exit_now!(0)
            end
          end

          # Open editor
          editor = TTY::Editor
          editor_command = $config.fetch(:default_editor)

          if editor.open(filepath, command: editor_command)
            # Validate the edited file
            begin
              updated_prompt = loader.find_by_name(prompt_name)
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
          ui.display_error("Failed to edit prompt: #{e.message}\n#{e.backtrace}")
          exit_now!(1)
        end
      end
    end

    # Defines the 'config' command and its subcommands.
    # This command group allows users to manage application configuration.
    desc 'Configuration management'
    command :config do |c|
      # Defines the 'config get' subcommand.
      # Retrieves and displays the value of a specific configuration key.
      c.desc 'Get configuration value'
      c.arg_name 'key'
      c.command :get do |get_cmd|
        # The action block for the 'config get' subcommand.
        # Requires a configuration key as an argument.
        #
        # @param _global_options [GLI::GlobalOptions] global options (not used)
        # @param _options [GLI::Options] command-specific options (not used)
        # @param args [Array<String>] command arguments, expecting the configuration key
        # @raise [TTY::Config::ReadError] if the configuration key is not found.
        # @raise [StandardError] if any other error occurs.
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
          rescue TTY::Config::ReadError
            ui.display_error("Configuration key '#{key}' not found")

            # Show available keys
            puts "\nAvailable configuration keys:"
            $config.to_h.keys.each { |k| puts "  - #{k}" }

            exit_now!(1)
          rescue StandardError => e
            ui.display_error("Failed to get configuration: #{e.message}")
            exit_now!(1)
          end
        end
      end

      # Defines the 'config set' subcommand.
      # Sets the value for a specific configuration key and writes it to the config file.
      c.desc 'Set configuration value'
      c.arg_name 'key value'
      c.command :set do |set_cmd|
        # The action block for the 'config set' subcommand.
        # Requires a configuration key and its value as arguments.
        #
        # @param _global_options [GLI::GlobalOptions] global options (not used)
        # @param _options [GLI::Options] command-specific options (not used)
        # @param args [Array<String>] command arguments, expecting the key and value
        # @raise [StandardError] if any error occurs during setting or writing the configuration.
        set_cmd.action do |_global_options, _options, args|
          if args.size < 2
            ui = Promptly::UI.new
            ui.display_error('Please provide both key and value')
            exit_now!(1)
          end

          key = args[0].to_sym
          value = args[1..-1].join(' ') # Join in case value has spaces
          ui = Promptly::UI.new

          begin
            $config.set(key, value: value)

            # Write to config file
            config_file = File.join(Dir.home, '.config', 'promptly', 'config.yml')
            FileUtils.mkdir_p(File.dirname(config_file))
            $config.write(config_file, format: :yaml)

            ui.display_success("Set #{key} = #{value}")
          rescue StandardError => e
            ui.display_error("Failed to set configuration: #{e.message}")
            exit_now!(1)
          end
        end
      end

      # Defines the 'config list' subcommand.
      # Lists all current configuration key-value pairs.
      c.desc 'List all configuration values'
      c.command :list do |list_cmd|
        # The action block for the 'config list' subcommand.
        # Displays all configurations in a table.
        #
        # @param _global_options [GLI::GlobalOptions] global options (not used)
        # @param _options [GLI::Options] command-specific options (not used)
        # @param _args [Array<String>] command arguments (not used)
        # @raise [StandardError] if any error occurs while reading or displaying configurations.
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

    # Creates a basic template string for a new prompt file.
    #
    # @param name [String] The name of the prompt.
    # @return [String] A string containing the template for a new prompt,
    #   including frontmatter for name, description, and variables.
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
