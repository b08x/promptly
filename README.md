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
    * **`ListAction`**: Handles the logic for listing all available prompts.
    * **`ViewAction`**: Handles the logic for viewing a specific prompt.
    * **`EditAction`**: Handles the logic for editing an existing prompt or creating a new one.
    * **`ConfigAction`**: Handles configuration management actions: list, get, set.

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

## API Documentation

`Promptly` now includes capabilities for generating and managing API documentation using Swagger and OpenAPI standards. This ensures that the API is well-documented and accessible.

### Generation Process

* **Swagger Definitions**: API endpoints and data models are defined using `swagger-blocks` within the Ruby codebase (see `lib/swagger_definitions.rb`).
* **Swagger 2.0 JSON**: A Rake task (`rake swagger:generate`) processes these definitions to produce a `swagger.json` file located at `public/api_docs/v1/swagger.json`.
* **OpenAPI 3.0 Conversion**: The same Rake task then utilizes `swagger2openapi` (an npm tool) to convert the Swagger 2.0 JSON into OpenAPI 3.0 format, available as `openapi.yml` and `openapi.json` in the same directory (`public/api_docs/v1/`).
* **NPM Tooling**: Node.js and npm are used to manage tools like `swagger2openapi` and `@redocly/cli` (for linting OpenAPI specifications). The necessary `package.json` and `package-lock.json` files are included in the project. Rake tasks, as defined in the `Rakefile`, will attempt to install npm dependencies if `node_modules` is not present and npm is installed.

### Accessing Documentation

The generated API documentation can be found in the `public/api_docs/v1/` directory. These files can be used with various tools that support Swagger or OpenAPI for viewing and interacting with the API documentation (e.g., Swagger UI, ReDoc).

### Linting

The project includes a script in `package.json` for linting the OpenAPI specification using Redocly CLI:

```bash
npm run lint-openapi
```

This can be run after generating the documentation to ensure its quality and correctness.

## Installation and Execution

To run `Promptly` from a cloned repository:

1. **Ruby Dependencies**: Install Ruby dependencies using Bundler:

    ```bash
    bundle install
    ```

2. **Node.js Dependencies (for documentation features)**: For API documentation generation and linting, Node.js and npm are required. Install Node.js dependencies by running the following command in the project root:

    ```bash
    npm install
    ```

    The Rake tasks related to documentation (e.g., `rake swagger:generate`) will also attempt to install these dependencies automatically if the `node_modules` directory is missing and npm is available on your system.
3. **Running the CLI**: Execute the tool via:

    ```bash
    exe/promptly
    ```

    or

    ```bash
    bundle exec bin/promptly
    ```

A global `$config` object is initialized by the executable to manage settings.

## Future Development Considerations

The software structure allows for future inclusion of features such as variable interpolation in prompt bodies and further organization mechanisms for prompts. The technical overview in the original README suggests refactoring the interactive menu logic and global configuration handling for improved modularity.
