require 'spec_helper'

RSpec.describe Promptly::Prompt do
  describe '#initialize' do
    it 'creates a prompt with the given attributes' do
      prompt = described_class.new(
        name: 'test_prompt',
        description: 'A test prompt',
        variables: %w[var1 var2],
        body: 'This is a test prompt body',
        filepath: '/path/to/prompt.md'
      )

      expect(prompt.name).to eq('test_prompt')
      expect(prompt.description).to eq('A test prompt')
      expect(prompt.variables).to eq(%w[var1 var2])
      expect(prompt.body).to eq('This is a test prompt body')
      expect(prompt.filepath).to eq('/path/to/prompt.md')
    end

    it 'handles nil variables by defaulting to an empty array' do
      prompt = described_class.new(
        name: 'test_prompt',
        variables: nil,
        body: 'Test body'
      )

      expect(prompt.variables).to eq([])
    end
  end

  describe '.from_parsed_data' do
    let(:parsed_data) do
      double(
        front_matter: {
          'name' => 'parsed_prompt',
          'description' => 'A parsed prompt',
          'variables' => %w[var1 var2]
        },
        content: 'Parsed prompt content'
      )
    end

    it 'creates a prompt from parsed front matter data' do
      prompt = described_class.from_parsed_data(parsed_data, '/path/to/prompt.md')

      expect(prompt.name).to eq('parsed_prompt')
      expect(prompt.description).to eq('A parsed prompt')
      expect(prompt.variables).to eq(%w[var1 var2])
      expect(prompt.body).to eq('Parsed prompt content')
      expect(prompt.filepath).to eq('/path/to/prompt.md')
    end

    it 'uses the filename as name when name is not present in front matter' do
      parsed_without_name = double(
        front_matter: {
          'description' => 'A parsed prompt',
          'variables' => %w[var1 var2]
        },
        content: 'Parsed prompt content'
      )

      prompt = described_class.from_parsed_data(parsed_without_name, '/path/to/example_prompt.md')

      expect(prompt.name).to eq('example_prompt')
      expect(prompt.description).to eq('A parsed prompt')
      expect(prompt.variables).to eq(%w[var1 var2])
    end

    it 'handles missing front matter data' do
      allow(parsed_data).to receive(:front_matter).and_return(nil)

      prompt = described_class.from_parsed_data(parsed_data, '/path/to/example_prompt.md')

      expect(prompt.name).to eq('example_prompt')
      expect(prompt.variables).to eq([])
    end
  end

  describe '#to_markdown' do
    it 'converts prompt to markdown format with front matter' do
      prompt = described_class.new(
        name: 'test_prompt',
        description: 'A test prompt',
        variables: %w[var1 var2],
        body: 'This is a test prompt body'
      )

      markdown = prompt.to_markdown

      expect(markdown).to include('---')
      expect(markdown).to include('name: test_prompt')
      expect(markdown).to include('description: A test prompt')
      expect(markdown).to include('variables:')
      expect(markdown).to include('- var1')
      expect(markdown).to include('- var2')
      expect(markdown).to include('This is a test prompt body')
    end

    it 'handles empty front matter correctly' do
      prompt = described_class.new(
        name: 'test_prompt',
        body: 'Just the body'
      )

      markdown = prompt.to_markdown

      expect(markdown).to start_with("---\n")
      expect(markdown).to include('name: test_prompt')
      expect(markdown).to include('Just the body')
    end
  end

  describe '#has_variables?' do
    it 'returns true when variables are present' do
      prompt = described_class.new(
        name: 'test_prompt',
        variables: %w[var1 var2]
      )

      expect(prompt.has_variables?).to be true
    end

    it 'returns false when variables are empty' do
      prompt = described_class.new(
        name: 'test_prompt',
        variables: []
      )

      expect(prompt.has_variables?).to be false
    end
  end

  describe '#variable_count' do
    it 'returns the number of variables' do
      prompt = described_class.new(
        name: 'test_prompt',
        variables: %w[var1 var2 var3]
      )

      expect(prompt.variable_count).to eq(3)
    end

    it 'returns 0 when no variables are present' do
      prompt = described_class.new(
        name: 'test_prompt',
        variables: []
      )

      expect(prompt.variable_count).to eq(0)
    end
  end
end
