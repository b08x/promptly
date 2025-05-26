require 'spec_helper'

RSpec.describe Promptly::UI do
  let(:ui) { described_class.new }
  let(:test_prompt) do
    Promptly::Prompt.new(
      name: 'test_prompt',
      description: 'A test prompt description',
      variables: %w[var1 var2],
      body: 'This is a test prompt body',
      filepath: '/path/to/test_prompt.md'
    )
  end

  describe '#display_prompt_table' do
    it 'displays info message when no prompts are found' do
      expect(ui).to receive(:display_info).with('No prompts found.')

      ui.display_prompt_table([])
    end

    it 'displays a table with prompt information' do
      prompts = [test_prompt]
      
      # Mock TTY::Table to avoid ioctl errors
      table_double = instance_double(TTY::Table)
      rendered_table = "Rendered table content"
      
      # Create the expected rows array that matches what the method will generate
      expected_rows = [
        [
          test_prompt.name,
          ui.send(:truncate_text, test_prompt.description, 40),
          test_prompt.variable_count,
          File.basename(test_prompt.filepath)
        ]
      ]
      
      expect(TTY::Table).to receive(:new).with(
        header: %w[Name Description Variables File],
        rows: expected_rows
      ).and_return(table_double)
      
      expect(table_double).to receive(:render).with(:unicode, padding: [0, 1]).and_return(rendered_table)
      expect { ui.display_prompt_table(prompts) }.to output(/#{Regexp.escape(rendered_table)}/).to_stdout
    end
  end

  describe '#display_prompt_details' do
    before do
      # Mock TTY::Box.frame to avoid terminal-related issues in tests
      allow(TTY::Box).to receive(:frame) do |**options, &block|
        "Mocked box with content: #{block.call}"
      end
      allow(ui.instance_variable_get(:@markdown)).to receive(:parse).and_return("Parsed markdown")
    end

    it 'displays prompt details in a formatted box' do
      expect { ui.display_prompt_details(test_prompt) }.to output.to_stdout
    end

    it 'displays a message when the prompt body is empty' do
      prompt_without_body = Promptly::Prompt.new(
        name: 'empty_prompt',
        description: 'Empty prompt',
        variables: [],
        body: ''
      )

      expect { ui.display_prompt_details(prompt_without_body) }.to output(/\(No content\)/).to_stdout
    end
  end

  describe '#display_success' do
    it 'displays a success message' do
      expect { ui.display_success('Operation successful') }.to output.to_stdout
    end
  end

  describe '#display_error' do
    it 'displays an error message' do
      expect { ui.display_error('An error occurred') }.to output.to_stdout
    end
  end

  describe '#display_info' do
    it 'displays an info message' do
      expect { ui.display_info('Information message') }.to output.to_stdout
    end
  end

  describe '#display_warning' do
    it 'displays a warning message' do
      expect { ui.display_warning('Warning message') }.to output.to_stdout
    end
  end

  describe '#confirm' do
    it 'asks for user confirmation' do
      prompt_double = instance_double(TTY::Prompt)
      allow(TTY::Prompt).to receive(:new).and_return(prompt_double)
      allow(prompt_double).to receive(:yes?).with('Confirm?').and_return(true)

      result = ui.confirm('Confirm?')

      expect(result).to be true
    end
  end

  describe '#select' do
    it 'prompts the user to select from options' do
      prompt_double = instance_double(TTY::Prompt)
      allow(TTY::Prompt).to receive(:new).and_return(prompt_double)
      allow(prompt_double).to receive(:select).with('Select an option', ['Option 1', 'Option 2'], {}).and_return('Option 1')

      result = ui.select('Select an option', ['Option 1', 'Option 2'])

      expect(result).to eq('Option 1')
    end
  end

  describe 'private #build_metadata_content' do
    it 'formats prompt metadata correctly' do
      # Test the method directly instead of through display_prompt_details
      metadata_content = ui.send(:build_metadata_content, test_prompt)
      
      expect(metadata_content).to include("Description: A test prompt description")
      expect(metadata_content).to include("Variables: var1, var2")
      expect(metadata_content).to include("File: /path/to/test_prompt.md")
    end
    
    it 'handles prompts without variables' do
      prompt_without_vars = Promptly::Prompt.new(
        name: 'no_vars',
        description: 'No variables',
        variables: [],
        body: 'Body'
      )
      
      metadata_content = ui.send(:build_metadata_content, prompt_without_vars)
      expect(metadata_content).to include("Variables: None")
    end
    
    it 'handles prompts without filepath' do
      prompt_without_filepath = Promptly::Prompt.new(
        name: 'no_file',
        description: 'No filepath',
        variables: [],
        body: 'Body'
      )
      
      metadata_content = ui.send(:build_metadata_content, prompt_without_filepath)
      expect(metadata_content).to include("File: Unknown")
    end
  end

  describe 'private #truncate_text' do
    it 'truncates long text' do
      long_text = 'A' * 50
      result = ui.send(:truncate_text, long_text, 40)
      expect(result).to eq("#{'A' * 40}...")
    end

    it 'returns original text if not longer than max_length' do
      text = 'Short text'
      result = ui.send(:truncate_text, text, 40)
      expect(result).to eq(text)
    end

    it 'returns N/A for nil text' do
      result = ui.send(:truncate_text, nil, 40)
      expect(result).to eq('N/A')
    end

    it 'returns N/A for empty text' do
      result = ui.send(:truncate_text, '', 40)
      expect(result).to eq('N/A')
    end
  end
end
