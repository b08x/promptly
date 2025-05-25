# frozen_string_literal: true

# The Promptly module provides tools for managing and using text prompts,
# particularly those with YAML front matter and Markdown content.
module Promptly
  # Handles loading and finding {Promptly::Prompt} objects from the filesystem.
  # It interacts with a configuration to determine the directory where prompts are stored.
  class PromptLoader
    # Initializes a new PromptLoader.
    #
    # @param config [Hash] A configuration hash. It is expected to have a
    #   `:prompts_directory` key pointing to the path where prompt files are stored.
    #   Defaults to a global `$config` variable if not provided.
    def initialize(config = $config)
      @config = config
    end

    # Lists all available prompts found in the configured prompts directory.
    # Prompts are loaded from `.md` files. If a file cannot be loaded, a warning
    # is issued, and the process continues with other files.
    #
    # @return [Array<Promptly::Prompt>] An array of loaded {Promptly::Prompt} objects, sorted by name.
    def list_all
      prompts = []
      prompt_files = Dir.glob(File.join(prompts_directory, '*.md'))

      prompt_files.each do |filepath|
        begin
          prompt = load_prompt_from_file(filepath)
          prompts << prompt if prompt
        rescue StandardError => e
          # Log error but continue with other files
          $stderr.puts "Warning: Could not load #{filepath}: #{e.message}"
        end
      end

      prompts.sort_by(&:name)
    end

    # Finds a single prompt by its name.
    # The search first looks for an exact filename match (e.g., `name.md`) and then
    # performs a case-insensitive search if the exact match is not found.
    #
    # @param name [String] The name of the prompt to find (without the .md extension).
    # @return [Promptly::Prompt, nil] The loaded {Promptly::Prompt} object if found, otherwise `nil`.
    # @raise [Promptly::ParseError] if the prompt file is found but cannot be parsed.
    def find_by_name(name)
      filepath = find_filepath(name)
      return nil unless filepath && File.exist?(filepath)

      load_prompt_from_file(filepath)
    rescue StandardError => e
      raise ParseError, "Failed to parse prompt '#{name}': #{e.message}"
    end

    # Finds the filepath for a given prompt name.
    # It first attempts an exact match (e.g., `name.md`). If not found, it performs
    # a case-insensitive search for `*.md` files where the basename matches the given name.
    #
    # @param name [String] The name of the prompt (without the .md extension).
    # @return [String, nil] The full path to the prompt file if found, otherwise `nil`.
    def find_filepath(name)
      # Try exact match first
      exact_path = File.join(prompts_directory, "#{name}.md")
      return exact_path if File.exist?(exact_path)

      # Try case-insensitive search
      Dir.glob(File.join(prompts_directory, '*.md')).find do |filepath|
        File.basename(filepath, '.md').downcase == name.downcase
      end
    end

    private

    # Retrieves the configured prompts directory path.
    # If the directory does not exist, it attempts to create it.
    #
    # @return [String] The path to the prompts directory.
    def prompts_directory
      dir = @config.fetch(:prompts_directory)
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      dir
    end

    # Loads a {Promptly::Prompt} from a given file path.
    #
    # @param filepath [String] The full path to the prompt file.
    # @return [Promptly::Prompt] The loaded prompt object.
    # @raise [Promptly::ParseError] if the file has invalid YAML front matter or
    #   if there's an error reading the file.
    def load_prompt_from_file(filepath)
      File.read(filepath)
      parsed = FrontMatterParser::Parser.parse_file(filepath)
      Prompt.from_parsed_data(parsed, filepath)
    rescue FrontMatterParser::SyntaxError => e
      raise ParseError, "Invalid YAML front matter in #{filepath}: #{e.message}"
    rescue StandardError => e
      raise ParseError, "Failed to read #{filepath}: #{e.message}"
    end
  end
end
