# setup Specification

## Purpose

The setup specification defines the behavior of the bootstrap script (`setup.sh`) that installs and configures the God-Tier macOS Development Environment. This spec ensures AI agents and users can reliably set up the environment from a fresh clone.

## Requirements

### Requirement: Prerequisites Validation

The system MUST validate prerequisites before proceeding with installation.

#### Scenario: macOS version check

**Given** a macOS system
**When** the user runs `./setup.sh`
**Then** the script checks the macOS version
**And** fails with a helpful message if version is below 13.0 (Ventura)

#### Scenario: Xcode CLI tools check

**Given** Xcode Command Line Tools are not installed
**When** the user runs `./setup.sh`
**Then** the script detects the missing tools
**And** provides the command to install them: `xcode-select --install`

#### Scenario: Disk space check

**Given** a macOS system with less than 10GB free disk space
**When** the user runs `./setup.sh`
**Then** the script warns about low disk space
**And** continues with installation (warning only)

---

### Requirement: Mise Installation

The system MUST install mise as the central orchestrator.

#### Scenario: Fresh mise installation

**Given** mise is not installed on the system
**When** the user runs `./setup.sh`
**Then** mise is downloaded from `https://mise.run`
**And** mise is installed to `~/.local/bin/mise`
**And** `mise --version` returns a valid version string

#### Scenario: Existing mise installation

**Given** mise is already installed on the system
**When** the user runs `./setup.sh`
**Then** the existing mise installation is preserved
**And** the script logs "Mise already installed"

#### Scenario: Shell activation configuration

**Given** mise is installed
**When** the setup completes
**Then** `eval "$(mise activate zsh)"` is added to `~/.zshrc`
**And** the activation line is only added once (idempotent)

---

### Requirement: Stable Path Establishment

The system MUST create a stable symlink for configuration access.

#### Scenario: Create stable configuration path

**Given** the repository is cloned to any location
**When** the user runs `./setup.sh`
**Then** a symlink is created at `~/.config/dev-env`
**And** the symlink points to the repository directory

#### Scenario: Existing symlink with same target

**Given** `~/.config/dev-env` already points to the repository
**When** the user runs `./setup.sh`
**Then** the symlink is preserved unchanged
**And** the script logs "Stable path already configured"

#### Scenario: Existing symlink with different target

**Given** `~/.config/dev-env` points to a different location
**When** the user runs `./setup.sh`
**Then** the symlink is updated to point to the repository
**And** the script logs the change

---

### Requirement: Core Tool Installation

The system MUST install all core tools via mise.

#### Scenario: Install Bun (JavaScript runtime)

**Given** mise is installed and activated
**When** the setup reaches step 4
**Then** bun is installed via `mise use -g bun`
**And** `bun --version` returns a valid version string

#### Scenario: Install Uv (Python backend)

**Given** mise is installed and activated
**When** the setup reaches step 5
**Then** uv is installed via `mise use -g uv`
**And** `uv --version` returns a valid version string

#### Scenario: Install Pixi (conda-forge packages)

**Given** mise is installed and activated
**When** the setup reaches step 3
**Then** pixi is installed via `mise use -g pixi`
**And** `pixi --version` returns a valid version string

#### Scenario: Install Starship (shell prompt)

**Given** mise is installed and activated
**When** the setup reaches step 6
**Then** starship is installed via `mise use -g starship`
**And** starship.toml is copied to `~/.config/starship.toml`

#### Scenario: Install Chezmoi (dotfile manager)

**Given** mise is installed and activated
**When** the setup reaches step 7
**Then** chezmoi is installed via `mise use -g chezmoi`
**And** `chezmoi --version` returns a valid version string

---

### Requirement: Configuration Deployment

The system MUST deploy mise configuration to the standard location.

#### Scenario: Copy mise configuration

**Given** `config/mise.toml` exists in the repository
**When** the setup reaches step 8
**Then** the file is copied to `~/.config/mise/config.toml`
**And** `~/.config/mise/` directory is created if missing

#### Scenario: Missing mise configuration

**Given** `config/mise.toml` does not exist in the repository
**When** the setup reaches step 8
**Then** the script warns "mise.toml not found - using default config"
**And** installation continues without failing

---

### Requirement: Full Tool Stack Installation

The system MUST install all configured tools.

#### Scenario: Install all tools from configuration

**Given** mise configuration is deployed
**When** the setup runs `mise install`
**Then** all tools defined in the configuration are installed
**And** the script logs success for each tool

#### Scenario: Install CLI utilities

**Given** mise is installed and activated
**When** the setup reaches step 11
**Then** the following tools are installed: zoxide, fd, ripgrep, bat, eza, fzf, jq, yq, delta
**And** each tool is accessible via its command name

---

### Requirement: Idempotency

The setup script MUST be safe to run multiple times.

#### Scenario: Running setup twice

**Given** setup.sh has already been run successfully
**When** the user runs `./setup.sh` again
**Then** no errors occur
**And** existing configurations are preserved
**And** tools are not reinstalled if already present

#### Scenario: Partial installation recovery

**Given** a previous setup.sh run failed mid-execution
**When** the user runs `./setup.sh` again
**Then** the script resumes from where it left off
**And** already-installed components are skipped
**And** the installation completes successfully

---

### Requirement: Post-Installation Steps

The system MUST provide clear post-installation instructions.

#### Scenario: Display post-installation steps

**Given** the setup completes successfully
**When** the final step runs
**Then** the script displays:
  - "Restart your terminal (or run: source ~/.zshrc)"
  - "Run: chezmoi apply (to apply dotfile templates)"
  - "Run: mise doctor (to verify installation)"
  - "Run: ./config/scripts/validate.sh (health check)"

#### Scenario: Display installed versions

**Given** the setup completes successfully
**When** the final step runs
**Then** the script displays version information for:
  - mise
  - bun
  - uv
  - pixi
  - starship
  - chezmoi

---

### Requirement: Error Handling

The system MUST handle errors gracefully.

#### Scenario: Network failure during mise download

**Given** the network is unavailable
**When** the user runs `./setup.sh`
**And** mise is not already installed
**Then** the script fails with a clear error message
**And** suggests checking network connectivity

#### Scenario: Tool installation failure

**Given** a tool fails to install
**When** the setup encounters the error
**Then** the script exits immediately (set -e)
**And** displays which step failed
**And** the user can fix and re-run

#### Scenario: Insufficient permissions

**Given** the user lacks write permission to `~/.local`
**When** the user runs `./setup.sh`
**Then** the script fails with a permissions error
**And** does NOT suggest using sudo (user-space only)

---

## AI Agent Usage

### For AI Agents Setting Up This Environment:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/ray-manaloto/gemini-ai-macos-development-environment.git
   cd gemini-ai-macos-development-environment
   ```

2. **Run setup**:
   ```bash
   ./setup.sh
   ```

3. **Restart terminal** (or `source ~/.zshrc`)

4. **Verify installation**:
   ```bash
   mise doctor
   mise run validate
   bats tests/
   ```

### Troubleshooting for AI Agents:

| Issue | Solution |
|-------|----------|
| "command not found: mise" | Run `source ~/.zshrc` or restart terminal |
| "curl: command not found" | Install Xcode CLI: `xcode-select --install` |
| "mise install failed" | Check disk space: `df -h /` |
| Tool version mismatch | Run `mise trust` then `mise install` |
