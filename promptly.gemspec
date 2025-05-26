# Ensure we require the local version and not one we might have installed already
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'promptly/version'

Gem::Specification.new do |spec|
  spec.required_ruby_version = '>= 3.1'
  spec.name                  = 'promptly'
  spec.version               = Promptly::VERSION
  spec.authors               = ['Robert Pannick']
  spec.email                 = ['rwpannick@gmail.com']

  spec.summary               = 'A simple Prompt Management CLI.'
  spec.description           = 'An interactive TUI (using FZF / Curses) ' \
                               'for view, creating or editing markdown prompts a terminal.'
  spec.homepage              = 'https://github.com/b08x/promptly'
  spec.license               = 'MIT'

  spec.files                 = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features|assets)/})
    end
  end

  spec.bindir        = 'exe'
  spec.require_paths = ['lib']

  spec.executables << 'promptly'

  spec.add_dependency 'colorize'
  spec.add_dependency 'curses'
  spec.add_dependency('gli', '~> 2.22.2')
  spec.add_dependency 'json'
  spec.add_dependency('reline')
  spec.add_dependency 'tty-screen'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
