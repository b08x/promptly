# Promptly

## Purpose

`Promptly` is a command-line software tool, written in Ruby, intended for the management of text segments, referred to as "prompts." These prompts are stored as individual Markdown (`.md`) files which utilize YAML front matter for metadata. The software provides functions to list, display, and edit these prompt files.

## Functional Description

The software operates through a command-line interface (CLI) invoked by the executable `promptly`. If no command-line arguments are provided, it presents an interactive menu.

### Core Components

1. **`Promptly::Prompt`**: A Ruby class that models a single prompt. It reads and stores data from a Markdown file's YAML front matter (e.g., `name`, `description`, `variables`) and its Markdown body content.
2. **`Promptly::Manager` (formerly `PromptLoader`)**: A Ruby class responsible for file system operations related to prompts. This includes locating `.md` prompt files within a specified directory, loading their content into `Promptly::Prompt` objects, and providing lists of available prompts.
3. **`Promptly::UI`**: A Ruby class that handles interactions with the terminal display. It uses various `tty-toolkit` components (`tty-table`, `tty-box`, `tty-markdown`, `tty-prompt`) to render information and receive user input. This includes specific UI modules for displaying help documents (`Promptly::DocsViewer`), pre-styled boxes (`Promptly::UI::Box`), and a side-by-side scrollable text viewer (`Promptly::UI::ScrollableBox`).
4. **`Promptly::CLI`**: A Ruby class utilizing the `gli` gem to define and manage command-line commands. It also contains the logic for the interactive menu presented when no arguments are supplied.
5. **`Promptly::CliActions`**: A module containing action classes for core CLI operations:
   - **`ListAction`**: Handles the logic for listing all available prompts.
   - **`ViewAction`**: Handles the logic for viewing a specific prompt.
   - **`EditAction`**: Handles the logic for editing an existing prompt or creating a new one.
   - **`ConfigAction`**: Handles configuration management actions: list, get, set.

### Available Operations

* **Listing Prompts (`list`)**: Displays a table of available prompt files found in the configured prompts directory, handled by `Promptly::CliActions::ListAction`.
* **Viewing a Prompt (`view <name>`)**: Shows the metadata and body content of a specified prompt, handled by `Promptly::CliActions::ViewAction`.
* **Editing a Prompt (`edit <name>`)**: Opens the specified prompt file in the system's default or configured text editor. If the file does not exist, it offers to create it based on a template, handled by `Promptly::CliActions::EditAction`.
* **Configuration Management (`config`)**: Allows viewing and modifying configuration parameters such as the prompts directory and default editor, stored in `~/.config/promptly/config.yml`, handled by `Promptly::CliActions::ConfigAction`.
* **Documentation Viewer (`docs`)**: Presents an interactive TUI for Browse documentation content (e.g., SFL concepts) stored in Markdown files within a `docs/` directory. This interface allows navigation and scrolling of content.
* **Prompt Comparison (`compare <prompt1> <prompt2>`)**: Displays the content of two specified prompts side-by-side in a scrollable TUI.

### File Format for Prompts

Prompt files are expected to be Markdown (`.md`) files. They should contain a YAML front matter block for metadata, followed by the main body content in Markdown.

Example Structure:

```markdown
---
name: (string, optional)
description: (string, optional)
variables: (list of strings, optional)
---

(Markdown content of the prompt)
```

If `name` is not provided in the front matter, the filename (excluding `.md`) is used as the prompt's name. The `variables` field is intended for future use with an interpolation system.

## Installation and Execution

(This section would typically detail how to install the gem and run the executable. Based on the provided files, it's run from a cloned repository via `bundle install` and then `exe/promptly` or `bundle exec bin/promptly`. A global `$config` object is initialized by the executable to manage settings.)

## Future Development Considerations

The software structure allows for future inclusion of features such as variable interpolation in prompt bodies and further organization mechanisms for prompts. The technical overview in the original README suggests refactoring the interactive menu logic and global configuration handling for improved modularity.
