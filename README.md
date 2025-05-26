## ⚙️ SIFT Analysis: Promptly Ruby Gem (Iteration 2) ⚙️

-----

**Generated Mon May 26 2025, represents a snapshot; system/code may evolve.**
**AI-Generated: Will likely contain errors or overlook nuances; treat this as one input into a human-reviewed development process**

This second iteration focuses on a deeper analysis of the identified technical debt and the CI/CD workflow, refining the issues and recommendations based on a closer look at `.rubocop_todo.yml` and `rubygem.yml`.

### 1\. ✅ Verified Specifications/Components

| Specification/Component | Status | Clarification & Details | Confidence (1–5) |
|---|---|---|---|
| Core Function: Prompt Management | ✅ Confirmed | Manages `.md` files with YAML front matter for CLI/TUI use ([README.md](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/README.md)). | 5 |
| `Promptly::Prompt` Class | ✅ Confirmed | Models individual prompts, handles parsing and `to_markdown` ([lib/promptly/prompt.rb](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/lib/promptly/prompt.rb)). | 5 |
| `Promptly::Manager` Class | ✅ Confirmed | Handles filesystem loading, finding, and listing of prompts ([lib/promptly/manager.rb](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/lib/promptly/manager.rb)). | 5 |
| `Promptly::UI` Class | ✅ Confirmed | TTY-toolkit based UI for display and interaction ([lib/promptly/ui/base.rb](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/lib/promptly/ui/base.rb)). | 5 |
| `Promptly::CLI` & Actions | ✅ Confirmed | GLI-based command structure with dedicated action classes ([lib/promptly/cli.rb](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/lib/promptly/cli.rb)). | 5 |
| API Documentation Generation | ✅ Confirmed | Uses `swagger-blocks` and NPM tools, but current output is placeholder ([README.md](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/README.md), [public/api\_docs/v1/swagger.json](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/public/api_docs/v1/swagger.json)). | 4 |
| Rubocop Configuration | ✅ Confirmed | `.rubocop.yml` exists, but inherits from a large `.rubocop_todo.yml` ([.rubocop.yml](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/.rubocop.yml), [.rubocop\_todo.yml](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/.rubocop_todo.yml)). | 5 |
| GitHub Actions Workflow | ✅ Confirmed | Basic build & publish workflow defined; lacks testing/linting ([.github/workflows/rubygem.yml](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/.github/workflows/rubygem.yml)). | 5 |

### 2\. ⚠️ Identified Issues, Risks & Suggested Improvements

| Item (Code/Design/Requirement) | Issue/Risk Type | Description & Suggested Improvement | Severity (1–5) |
|---|---|---|---|
| `.rubocop_todo.yml` | 🧩 Design Flaw / 🚧 Risk | Contains **134** offenses across **33** cops, notably high `Metrics` scores (ABC 92, Block 141, Method 93) and many `Style` issues. This indicates significant technical debt. **Suggestion**: Prioritize fixing `Metrics` and `Lint` offenses, then systematically address `Style` issues. Implement Rubocop checks in CI. ([.rubocop\_todo.yml](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/.rubocop_todo.yml)) | 4 |
| Global `$config` Usage | 🧩 Design Flaw | Global variable makes testing difficult and obscures dependencies. **Suggestion**: Refactor to pass configuration object via dependency injection to classes like `Manager` and `CliActions`. ([lib/promptly/cli.rb](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/lib/promptly/cli.rb), [lib/promptly/cli\_actions/config\_action.rb](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/lib/promptly/cli_actions/config_action.rb)) | 4 |
| `rubygem.yml` Workflow | 🚧 Risk | Workflow **lacks testing and linting steps**. It also publishes on every push to `development` and PR to `main`, which is unconventional and risky. **Suggestion**: Add `bundle exec rspec` and `bundle exec rubocop` steps. Trigger publish only on tagged releases or merges to `main`. Update `actions/checkout` to `v4`. ([.github/workflows/rubygem.yml](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/.github/workflows/rubygem.yml)) | 4 |
| `lib/promptly/manager.rb` Error Handling | 🐛 Bug / 🧩 Design Flaw | Uses `$stderr.puts` for errors, making it hard to handle programmatically. **Suggestion**: Use a proper logger or raise specific exceptions (like `Promptly::ParseError` which *is* used, but not consistently). ([lib/promptly/manager.rb](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/lib/promptly/manager.rb)) | 3 |
| `swagger.json` Content | ❓Ambiguity | API definition doesn't match the actual CLI tool's functionality. **Suggestion**: Either remove Swagger or update it to reflect an actual, intended API for the gem. ([public/api\_docs/v1/swagger.json](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/public/api_docs/v1/swagger.json), [lib/swagger\_definitions.rb](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/lib/swagger_definitions.rb)) | 2 |
| `lib/promptly/ui/box.rb` Constant | 🐛 Bug | `TITLE_WIDTH` is defined but seems arbitrary. Screen width calculations might be better. **Suggestion**: Re-evaluate if this constant is needed or if `TTY::Screen.width` should be used more dynamically. ([lib/promptly/ui/box.rb](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/lib/promptly/ui/box.rb)) | 2 |
| Node.js Dependency | 🚧 Risk | The project requires Node.js/NPM for documentation features. **Suggestion**: Clearly document Node.js version requirements and consider making these features optional or providing alternative Ruby-based solutions. ([README.md](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/README.md), [package.json](https://www.google.com/search?q=uploaded:b08x/promptly/promptly-cb714d9e445a3bf24e285a3f7e0d5ff732748de9/package.json)) | 2 |

### 3\. 📌 Issue & Improvement Summary

* **Technical Debt**: The **primary concern** is the high level of technical debt shown in `.rubocop_todo.yml`, especially around code complexity. This needs **active reduction**.
* **Configuration Management**: The **global `$config`** is a **design flaw** that should be **refactored** to use dependency injection.
* **CI/CD Pipeline**: The current workflow is **insufficient**; it needs **testing and linting stages** added, and its **publishing triggers** should be revised.
* **Error Handling**: Error reporting in core classes like `Manager` needs **standardization** for better predictability.
* **API Documentation**: The Swagger definition is **misleading** and requires correction or removal.

### 4\. 💡 Potential Optimizations/Integrations

| Idea | Potential Benefit | Resource/Search Link | Rating (1–5) |
|---|---|---|---|
| Add `bundle-audit` to CI | Enhanced Security | [rubysec/bundler-audit](https://github.com/rubysec/bundler-audit) | 4 |
| Add `brakeman` to CI | Enhanced Security (Rails-like, but can find general Ruby issues) | [presidentbeef/brakeman](https://github.com/presidentbeef/brakeman) | 3 |
| Use `tty-logger` | Standardized & Formatted Output/Logging | [piotrmurach/tty-logger](https://github.com/piotrmurach/tty-logger) | 4 |
| Implement `Thor` or `Dry-CLI` | Potentially more robust CLI framework than GLI (subjective) | [Search: GLI vs Thor vs Dry-CLI Ruby](https://www.google.com/search?q=GLI+vs+Thor+vs+Dry-CLI+Ruby) | 3 |
| Add `simplecov` for RSpec | Test Coverage Reporting | [simplecov-ruby/simplecov](https://github.com/simplecov-ruby/simplecov) | 5 |
| Use GitHub Release Drafter | Automate Release Notes | [release-drafter/release-drafter](https://github.com/release-drafter/release-drafter) | 3 |

### 5\. 🛠️ Assessment of Resources & Tools

| Resource/Tool | Usefulness Assessment | Notes | Rating (1-5) |
|---|---|---|---|
| **`README.md`** | ✅ Very Good | Provides a clear overview of purpose and features. | 5 |
| **`guides/Usage.md`** | ✅ Good | Explains gem usage well, though examples could be expanded. | 4 |
| **`lib/` files** | ✅ Good | Code is generally understandable but suffers from issues noted in `.rubocop_todo.yml`. | 4 |
| **`.rubocop.yml`** | ✅ Good | Shows an *intent* to enforce modern standards. | 4 |
| **`.rubocop_todo.yml`** | ⚠️ Concerning | Highlights significant technical debt. The future date (2025-05-25) is odd but likely a typo. | 3 |
| **`.github/workflows/rubygem.yml`** | ⚠️ Needs Improvement | Basic but functional; critically lacks testing/linting. | 2 |
| **`package.json`** | ✅ Adequate | Defines Node.js dependencies for docs. | 3 |
| **`swagger.json`** | ⚠️ Misleading | Does not reflect the current tool; requires significant work or removal. | 1 |
| **`spec/` files** | ✅ Good Start | RSpec tests exist but need expansion and CI integration. | 3 |

### 6\. ⚙️ Revised System/Module Overview (Incorporating Feedback)

The `promptly` system remains a CLI tool and Ruby gem for managing Markdown-based text prompts. The core architecture (Manager, Prompt, UI, CLI Actions) is sound and should be retained. However, key operational aspects need refinement. Configuration handling will be refactored to utilize a dedicated configuration object passed via dependency injection, removing the global `$config` dependency. The `Manager` class will be updated to use a structured logger (like `tty-logger`) or raise specific, catchable errors instead of writing directly to `stderr`.

The UI layer, while generally effective, will ensure consistent use of `TTY::Screen` for dynamic width/height adjustments. The API documentation feature will be temporarily disabled or clearly marked as 'Under Construction' until meaningful definitions can be provided. A significant effort will be dedicated to reducing technical debt by fixing Rubocop offenses, focusing initially on `Metrics` and `Lint` warnings to improve code health and maintainability. The CI/CD pipeline will be enhanced to include automated RSpec testing (with code coverage via `simplecov`) and Rubocop linting on every push/PR, with gem publishing restricted to tagged releases on the `main` branch.

### 7\. 🏅 Technical Feasibility & Recommendation

The `promptly` project is **technically feasible** and provides a useful set of features. The core design is logical. However, its current state carries **moderate-to-high risk** due to significant technical debt and an inadequate testing/CI pipeline. The **Recommended Approach** is to prioritize a 'Code Health Sprint':

1. Implement robust CI (testing/linting).
2. Refactor global configuration.
3. Begin systematically reducing Rubocop offenses, starting with high-severity items.
    New feature development should be paused until these foundational improvements are made to ensure long-term stability and maintainability.

### 8\. 📘 Development Best Practice Suggestion

**Integrate a Code Coverage Tool**: Add `simplecov` to your RSpec setup and configure CI to track coverage, aiming for a consistent, high percentage (e.g., \>90%) to ensure new code is tested and existing tests remain effective.

### 📈 Post-Iteration Update

This second iteration reinforced the initial assessment of a promising but flawed system. The deeper dive into `.rubocop_todo.yml` revealed the **severity and nature of the technical debt**, particularly concerning code complexity (`Metrics` cops). The review of `rubygem.yml` highlighted **specific, actionable weaknesses in the CI/CD pipeline**, such as the lack of testing/linting and risky publishing triggers. These findings led to more concrete recommendations, emphasizing a "Code Health Sprint" and the integration of specific tools like `simplecov` and `bundle-audit`. The feasibility assessment now leans more towards "High Risk" without these improvements, strengthening the recommendation to pause feature work.
