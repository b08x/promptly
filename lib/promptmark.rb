# frozen_string_literal: true

require 'promptmark/version'

require 'fileutils'
require 'yaml'
require 'front_matter_parser'
require 'tty-prompt'
require 'tty-box'
require 'tty-markdown'
require 'tty-table'
require 'tty-editor'

require_relative 'promptmark/prompt'
require_relative 'promptmark/prompt_loader'
require_relative 'promptmark/ui'

module PromptMark
  class Error < StandardError; end
  class PromptNotFoundError < Error; end
  class ParseError < Error; end
end
