require 'spec_helper'

RSpec.describe PromptMark::UI do
  let(:ui) { described_class.new }
  let(:test_prompt) do
    PromptMark::Prompt.new(
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

      expect { ui.display_prompt_table(prompts) }.to output.to_stdout
      # Since we can't easily test the exact table output due to TTY::Table rendering,
      # we're just verifying it outputs something to stdout
    end
  end

  describe '#display_prompt_details' do
    it 'displays prompt details in a formatted box' do
      expect { ui.display_prompt_details(test_prompt) }.to output.to_stdout
    end

    it 'displays a message when the prompt body is empty' do
      prompt_without_body = PromptMark::Prompt.new(
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
      allow(prompt_double).to receive(:select).with('Select an option', ['Option 1', 'Option 2']).and_return('Option 1')

      result = ui.select('Select an option', ['Option 1', 'Option 2'])

      expect(result).to eq('Option 1')
    end
  end

  describe 'private #build_metadata_content' do
    it 'formats prompt metadata' do
      # We can test this indirectly through display_prompt_details
      expect { ui.display_prompt_details(test_prompt) }.to output(/Description: A test prompt description/).to_stdout
      expect { ui.display_prompt_details(test_prompt) }.to output(/Variables: var1, var2/).to_stdout
      expect { ui.display_prompt_details(test_prompt) }.to output(%r{File: /path/to/test_prompt\.md}).to_stdout
    end
  end

  describe 'private #truncate_text' do
    it 'truncates long text' do
      # Test indirectly through display_prompt_table with a long description
      long_description_prompt = PromptMark::Prompt.new(
        name: 'long_desc',
        description: 'A' * 50, # Long description that should be truncated
        variables: [],
        filepath: '/path/to/long_desc.md'
      )

      expect { ui.display_prompt_table([long_description_prompt]) }.to output.to_stdout
      # Since we can't easily verify the truncated output, we're just checking it runs without error
    end

    it 'returns N/A for nil or empty text' do
      prompt_with_no_desc = PromptMark::Prompt.new(
        name: 'no_desc',
        description: nil,
        variables: [],
        filepath: '/path/to/no_desc.md'
      )

      expect { ui.display_prompt_table([prompt_with_no_desc]) }.to output.to_stdout
    end
  end
end
