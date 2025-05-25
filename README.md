# Promptly

**`Promptly`** is a command-line tool designed to help you manage, view, and edit a collection of text prompts, especially those crafted in Markdown with YAML front matter. Whether you're wrangling prompts for AI, generating standardized responses, or just organizing text snippets, `Promptly` provides both a scriptable CLI and an interactive terminal interface.

It leverages the power of the TTY toolkit to offer a smooth, in-terminal experience, and `gli` for a robust command-line structure.

## Features

* **Interactive Menu:** Run `promptly` without arguments for a user-friendly, TTY-driven menu to navigate your prompts.
* **YAML Front Matter:** Define metadata like `name`, `description`, and `variables` right inside your prompt files.
* **Markdown Body:** Write your main prompt content using Markdown for clarity and structure.
* **List & Show:** Quickly list all available prompts in a table or view the detailed content and metadata of a specific prompt.
* **Edit & Create:** Open prompts in your default (or configured) editor. If a prompt doesn't exist, `promptly` will ask to create it for you.
* **Configuration:** Manage settings like your preferred editor and prompts directory.

## Technical Overview

`Promptly` is built around a few key components:

1. **`Promptly::Prompt`:** A Plain Old Ruby Object (PORO) representing a single prompt. It handles parsing the YAML front matter and Markdown content. Think of it as the model in our little MVC (Model-View-CLI) setup – simple, clean, and holds the data.
2. **`Promptly::PromptLoader`:** Responsible for finding and loading `.md` prompt files from the designated directory. It’s got a bit of filesystem smarts, even doing case-insensitive searches if an exact match fails – a nice touch for those "did I name it `MyPrompt` or `myprompt`?" moments.
3. **`Promptly::UI`:** This class is where the TTY magic happens. It uses `tty-table`, `tty-box`, `tty-markdown`, and `tty-prompt` to render tables, boxes, markdown, and handle user input. It keeps the CLI from looking like something straight out of the 90s.
4. **`Promptly::CLI`:** The main entry point, built using `gli`. It defines the commands (`list`, `show`, `edit`, `config`) and handles command-line arguments. Interestingly, it also houses the logic for the interactive menu. This dual-role approach is a classic sign of evolution – an interactive feature bolted onto a CLI framework. It works, but it's like having two competing CSS frameworks; you might find yourself defining the same styles (or logic) in two different places. Refactoring this into more focused, reusable service objects could be a future enhancement.

A small, but significant, detail is the use of a global `$config` variable. While it provides easy access to configuration throughout the application, it's a bit like using global CSS selectors – convenient, but it can make dependencies harder to track and testing a bit more complex. Encapsulating configuration access might be a worthwhile evolution.

## Installation

*(Waiting for user input - will add this section once I know the intended installation method.)*

## Usage

### Interactive Mode

Simply run `promptly` in your terminal:

```bash
promptly
```

This will launch an interactive menu allowing you to:

* **List:** See all your prompts.
* **Show:** Select a prompt to view its details.
* **Edit:** Choose a prompt to edit or create a new one.
* **Configure:** Manage settings.
* **Exit:** Leave `Promptly`.

### Command-Line Interface

You can also use `Promptly` directly from the command line:

* **List Prompts:**

    ```bash
    promptly list
    ```

* **Show a Prompt:**

    ```bash
    promptly show <prompt_name>
    ```

* **Edit/Create a Prompt:**

    ```bash
    promptly edit <prompt_name>
    ```

* **Manage Configuration:**

    ```bash
    promptly config list
    promptly config get <key>
    promptly config set <key> <value>
    ```

## Prompt Format

`Promptly` expects prompts to be Markdown files (`.md`) with YAML front matter.

```markdown
---
name: my_awesome_prompt
description: A brief description of this prompt.
variables:
  - user_input
  - context
---

# My Awesome Prompt

This is the main body of the prompt. You can use Markdown here.

You can reference variables like $${user_input} or $${context} (though variable interpolation isn't implemented in this code version, the structure supports it).
```

* **`name`**: (Optional) The name of the prompt. If omitted, the filename (without `.md`) will be used.
* **`description`**: (Optional) A short description.
* **`variables`**: (Optional) A list of variables your prompt uses.

## Configuration

*(Waiting for user input - will refine this based on how `$config` is initialized.)*

`Promptly` stores its configuration in `~/.config/promptly/config.yml`. You can manage it using the `promptly config` commands.

Key settings include:

* `prompts_directory`: The folder where your `.md` prompt files are stored.
* `default_editor`: Your preferred command-line editor (e.g., `vim`, `nano`, `code`).

## Development & Testing

The project includes Minitest and RSpec tests.

*(Details on running tests would go here, typically involving `bundle install` and `bundle exec rake` or `bundle exec rspec`)*
