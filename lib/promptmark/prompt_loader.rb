# frozen_string_literal: true

module PromptMark
  # Handles loading and finding prompts from the filesystem
  class PromptLoader
    def initialize(config = $config)
      @config = config
    end

    # List all available prompts
    def list_all
      prompts = []
      prompt_files = Dir.glob(File.join(prompts_directory, '*.md'))

      prompt_files.each do |filepath|
        prompt = load_prompt_from_file(filepath)
        prompts << prompt if prompt
      rescue StandardError => e
        # Log error but continue with other files
        warn "Warning: Could not load #{filepath}: #{e.message}"
      end

      prompts.sort_by(&:name)
    end

    # Find a prompt by name
    def find_by_name(name)
      filepath = find_filepath(name)
      return nil unless filepath && File.exist?(filepath)

      load_prompt_from_file(filepath)
    rescue StandardError => e
      raise ParseError, "Failed to parse prompt '#{name}': #{e.message}"
    end

    # Find the filepath for a given prompt name
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

    def prompts_directory
      dir = @config.fetch(:prompts_directory)
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      dir
    end

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
