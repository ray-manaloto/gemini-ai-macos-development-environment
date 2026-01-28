# Tool Management Specification

## ADDED Requirements

### Requirement: Mise Installation

The system MUST install mise as the primary tool version manager.

#### Scenario: Fresh installation on macOS

**Given** a clean macOS system with Xcode CLI tools installed
**When** the user runs `./setup.sh`
**Then** mise is installed to `~/.local/bin/mise`
**And** `mise --version` returns a valid version string

#### Scenario: Mise activation in shell

**Given** mise is installed
**When** the user opens a new terminal
**Then** `eval "$(mise activate zsh)"` is executed from `.zshrc`
**And** mise shims are added to PATH

---

### Requirement: Bun as Node Backend

The system MUST use Bun as the backend for all Node.js operations.

#### Scenario: npm commands redirect to bun

**Given** mise is configured with `node_backend = "bun"`
**When** the user runs `npm install`
**Then** the command is executed as `bun install`
**And** packages are installed using Bun's package manager

#### Scenario: Node scripts run with Bun

**Given** mise is configured with `node_backend = "bun"`
**When** the user runs `node script.js`
**Then** the script is executed using Bun runtime

---

### Requirement: Uv as Pip Backend

The system MUST use uv as the backend for all pip operations.

#### Scenario: pip commands redirect to uv

**Given** mise is configured with `pip_backend = "uv"`
**When** the user runs `pip install requests`
**Then** the command is executed as `uv pip install requests`
**And** packages are installed 10x faster than standard pip

#### Scenario: Virtual environment creation

**Given** uv is installed
**When** the user runs `python -m venv .venv`
**Then** uv creates the virtual environment
**And** the `.venv` directory is created with proper structure

---

### Requirement: Pixi for Binary Dependencies

The system MUST use Pixi for conda-forge binary packages.

#### Scenario: Install binary package

**Given** pixi is installed
**When** the user runs `pixi add ffmpeg`
**Then** FFmpeg is installed from conda-forge
**And** the binary is isolated from system libraries

#### Scenario: Project-level dependencies

**Given** a `pixi.toml` file exists in the project
**When** the user runs `pixi install`
**Then** all dependencies are installed to `.pixi/` directory
**And** a lockfile `pixi.lock` is generated

---

### Requirement: Modern CLI Utilities

The system MUST install modern replacements for common CLI tools.

#### Scenario: ripgrep replaces grep

**Given** ripgrep is installed via mise
**When** the user runs `rg "pattern"`
**Then** ripgrep searches files recursively
**And** results are displayed with syntax highlighting

#### Scenario: fd replaces find

**Given** fd is installed via mise
**When** the user runs `fd "*.py"`
**Then** fd finds files matching the pattern
**And** respects `.gitignore` by default

#### Scenario: zoxide replaces cd

**Given** zoxide is installed and initialized
**When** the user runs `z project-name`
**Then** zoxide navigates to the most frecent matching directory

---

### Requirement: Starship Prompt

The system MUST configure Starship as the shell prompt.

#### Scenario: Prompt shows git status

**Given** starship is installed and configured
**When** the user is in a git repository
**Then** the prompt displays the current branch
**And** shows uncommitted changes indicator

#### Scenario: Prompt shows tool versions

**Given** starship is configured with language modules
**When** the user is in a Python project
**Then** the prompt displays the Python version
**And** shows the active virtualenv if present

---

### Requirement: Chezmoi Dotfile Management

The system MUST use Chezmoi for dotfile management.

#### Scenario: Apply dotfile templates

**Given** chezmoi is installed with templates configured
**When** the user runs `chezmoi apply`
**Then** `.zshrc` is generated from template
**And** `.gitconfig` is generated from template
**And** user-specific values are interpolated

#### Scenario: Preview changes before applying

**Given** chezmoi templates have been modified
**When** the user runs `chezmoi diff`
**Then** changes are displayed in diff format
**And** no files are modified until `chezmoi apply` is run
