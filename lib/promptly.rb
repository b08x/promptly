# frozen_string_literal: true

require 'promptly/version'

require 'fileutils'
require 'yaml'
require 'front_matter_parser'
require 'tty-prompt'
require 'tty-box'
require 'tty-markdown'
require 'tty-table'
require 'tty-editor'
require 'tty-pager'
require 'tty-screen'

require_relative 'promptly/cli'
require_relative 'promptly/prompt'
require_relative 'promptly/prompt_loader'
require_relative 'promptly/ui/base'
require_relative 'promptly/ui/docs'

module Promptly
  class Error < StandardError; end
  class PromptNotFoundError < Error; end
  class ParseError < Error; end
end
