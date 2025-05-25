require 'spec_helper'

RSpec.describe PromptMark::PromptLoader do
  let(:config) { { prompts_directory: '/tmp/promptmark_test_prompts' } }
  let(:loader) { described_class.new(config) }
  let(:prompt_content) do
    <<~PROMPT
      ---
      name: test_prompt
      description: A test prompt
      variables:
        - var1
        - var2
      ---
      This is a test prompt body
    PROMPT
  end

  before do
    FileUtils.mkdir_p(config[:prompts_directory])
  end

  after do
    FileUtils.rm_rf(config[:prompts_directory])
  end

  describe '#list_all' do
    it 'returns all prompts sorted by name' do
      # Create test prompt files
      File.write(File.join(config[:prompts_directory], 'b_prompt.md'), prompt_content.gsub('test_prompt', 'b_prompt'))
      File.write(File.join(config[:prompts_directory], 'a_prompt.md'), prompt_content.gsub('test_prompt', 'a_prompt'))
      File.write(File.join(config[:prompts_directory], 'c_prompt.md'), prompt_content.gsub('test_prompt', 'c_prompt'))

      prompts = loader.list_all

      expect(prompts.size).to eq(3)
      expect(prompts.map(&:name)).to eq(%w[a_prompt b_prompt c_prompt])
    end

    it 'returns an empty array when no prompts are found' do
      prompts = loader.list_all

      expect(prompts).to be_empty
    end

    it 'skips invalid prompt files but logs a warning' do
      File.write(File.join(config[:prompts_directory], 'valid.md'), prompt_content)
      File.write(File.join(config[:prompts_directory], 'invalid.md'), 'Invalid content')

      expect { loader.list_all }.to output(/Warning/).to_stderr

      prompts = loader.list_all
      expect(prompts.size).to eq(1)
      expect(prompts.first.name).to eq('valid')
    end
  end

  describe '#find_by_name' do
    before do
      File.write(File.join(config[:prompts_directory], 'test_prompt.md'), prompt_content)
    end

    it 'returns the prompt when found by exact name' do
      prompt = loader.find_by_name('test_prompt')

      expect(prompt).not_to be_nil
      expect(prompt.name).to eq('test_prompt')
      expect(prompt.description).to eq('A test prompt')
    end

    it 'returns the prompt when found by case-insensitive name' do
      prompt = loader.find_by_name('TEST_PROMPT')

      expect(prompt).not_to be_nil
      expect(prompt.name).to eq('test_prompt')
    end

    it 'returns nil when prompt is not found' do
      prompt = loader.find_by_name('nonexistent_prompt')

      expect(prompt).to be_nil
    end

    it 'raises ParseError when prompt file has invalid front matter' do
      File.write(File.join(config[:prompts_directory], 'invalid.md'), "---\ninvalid: yaml:\n---\nContent")

      expect { loader.find_by_name('invalid') }.to raise_error(PromptMark::ParseError)
    end
  end

  describe '#find_filepath' do
    before do
      File.write(File.join(config[:prompts_directory], 'test_prompt.md'), prompt_content)
    end

    it 'returns the filepath when prompt is found by exact name' do
      filepath = loader.find_filepath('test_prompt')

      expect(filepath).to eq(File.join(config[:prompts_directory], 'test_prompt.md'))
    end

    it 'returns the filepath when prompt is found by case-insensitive name' do
      filepath = loader.find_filepath('TEST_PROMPT')

      expect(filepath).to eq(File.join(config[:prompts_directory], 'test_prompt.md'))
    end

    it 'returns nil when prompt is not found' do
      filepath = loader.find_filepath('nonexistent_prompt')

      expect(filepath).to be_nil
    end
  end

  describe 'private #prompts_directory' do
    it 'creates the prompts directory if it does not exist' do
      FileUtils.rm_rf(config[:prompts_directory])

      # This should trigger the creation of the directory
      loader.list_all

      expect(Dir.exist?(config[:prompts_directory])).to be true
    end
  end

  describe 'private #load_prompt_from_file' do
    before do
      File.write(File.join(config[:prompts_directory], 'test_prompt.md'), prompt_content)
    end

    it 'loads a prompt from a valid file' do
      # Since this is a private method, we'll test it indirectly through find_by_name
      prompt = loader.find_by_name('test_prompt')

      expect(prompt).not_to be_nil
      expect(prompt.name).to eq('test_prompt')
      expect(prompt.variables).to eq(%w[var1 var2])
    end

    it 'raises ParseError when file cannot be read' do
      filepath = File.join(config[:prompts_directory], 'unreadable.md')
      File.write(filepath, prompt_content)
      File.chmod(0o000, filepath) # Make file unreadable

      expect { loader.find_by_name('unreadable') }.to raise_error(PromptMark::ParseError)
    ensure
      File.chmod(0o644, filepath) if File.exist?(filepath) # Make file readable again for cleanup
    end
  end
end
