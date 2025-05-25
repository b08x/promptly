# frozen_string_literal: true

APP_ROOT = File.expand_path('..', __dir__)

require 'promptly/version'

require 'fileutils'
require 'yaml'
require 'front_matter_parser'

require_relative 'promptly/cli'
require_relative 'promptly/prompt'
require_relative 'promptly/manager'
require_relative 'promptly/ui/base'
require_relative 'promptly/ui/docs'
require_relative 'promptly/ui/box'
require_relative 'promptly/ui/scrollable_box'

module Promptly
  class Error < StandardError; end
  class PromptNotFoundError < Error; end
  class ParseError < Error; end
end
