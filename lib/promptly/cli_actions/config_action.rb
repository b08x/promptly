# frozen_string_literal: true

require 'fileutils'
require 'tty-table' # For displaying the config list

module Promptly
  module CliActions
    # Handles configuration management actions: list, get, set.
    class ConfigAction
      # Initializes a new ConfigAction.
      #
      # @param ui [Promptly::UI] The UI service for output.
      # @param _manager [Promptly::Manager] The prompt management service (not directly used by config).
      # @param config [TTY::Config] The application configuration object.
      def initialize(ui, _manager, config = $config)
        @ui = ui
        @config = config
      end

      # Executes a configuration action (list, get, set).
      #
      # @param params [Hash] Expected to contain :sub_action and other relevant params.
      #   For :list -> {}
      #   For :get  -> { key: Symbol }
      #   For :set  -> { key: Symbol, value: String }
      # @return [Hash] A result hash, e.g.,
      #   { success: true, data: { ... } } for list/get
      #   { success: true, message: "Successfully set..." } for set
      #   { success: false, message: String }
      def execute(params = {})
        sub_action = params[:sub_action]&.to_sym

        case sub_action
        when :list
          list_configurations
        when :get
          get_configuration(params[:key])
        when :set
          set_configuration(params[:key], params[:value])
        else
          { success: false, message: "Invalid config sub-action: #{sub_action}. Supported: list, get, set." }
        end
      rescue StandardError => e
        # Consider logging e.backtrace here
        { success: false, message: "Configuration action failed: #{e.message}" }
      end

      private

      def list_configurations
        config_hash = @config.to_h
        if config_hash.empty?
          @ui.display_info('No configuration values set.')
        else
          # Note: TTY::Table output goes directly to STDOUT.
          # The UI class could have a method for this if we want to capture/box it.
          # For now, direct output is consistent with original CLI.
          table = TTY::Table.new(
            header: %w[Key Value],
            rows: config_hash.map { |k, v| [k.to_s, v.to_s] } # Ensure keys/values are strings for table
          )
          puts table.render(:unicode, padding: [0, 1])
        end
        { success: true, data: { configurations: config_hash } }
      end

      def get_configuration(key_str)
        return { success: false, message: "Configuration key not provided." } unless key_str

        key = key_str.to_sym
        value = @config.fetch(key) # TTY::Config raises KeyError if not found
        @ui.display_info("#{key}: #{value}") # Direct display for get
        { success: true, data: { key: key, value: value } }
      rescue KeyError
        message = "Configuration key '#{key}' not found."
        available_keys = @config.to_h.keys.map(&:to_s)
        if available_keys.any?
          message += "\\nAvailable configuration keys:\\n" + available_keys.map { |k_name| "  - #{k_name}" }.join("\\n")
        end
        { success: false, message: message, data: { available_keys: available_keys } }
      end

      def set_configuration(key_str, value)
        return { success: false, message: "Configuration key not provided for set." } unless key_str
        # Value can be nil/empty string, that's a valid set operation.

        key = key_str.to_sym
        @config.set(key, value: value) # TTY::Config specific API

        # Persist the configuration
        # This logic is from the original CLI.
        # Consider moving config file path to a central config or constant.
        config_file_path = File.join(Dir.home, '.config', 'promptly', 'config.yml')
        FileUtils.mkdir_p(File.dirname(config_file_path))
        @config.write(config_file_path, format: :yaml, force: true)

        message = "Set configuration: #{key} = #{value}"
        @ui.display_success(message)
        { success: true, message: message, data: { key: key, value: value } }
      end
    end
  end
end