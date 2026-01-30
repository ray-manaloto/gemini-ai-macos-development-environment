# validation Specification

## Purpose

The validation specification defines the behavior of the environment health check script (`config/scripts/validate.sh`) and the `mise run validate` task. This ensures users and AI agents can verify their environment is correctly configured.

## Requirements

### Requirement: Validation Invocation

The system MUST provide multiple ways to run validation.

#### Scenario: Run via mise task

**Given** mise is installed and configured
**When** the user runs `mise run validate`
**Then** the validation script executes
**And** results are displayed to stdout

#### Scenario: Run directly

**Given** the repository is cloned
**When** the user runs `./config/scripts/validate.sh`
**Then** the validation script executes
**And** results are displayed to stdout

---

### Requirement: Mise Validation

The system MUST validate the mise orchestrator.

#### Scenario: Mise installed

**Given** mise is installed
**When** validation runs
**Then** it reports PASS for "Mise installed"
**And** displays the mise version

#### Scenario: Mise not installed

**Given** mise is not installed
**When** validation runs
**Then** it reports FAIL for "Mise not installed"
**And** the script exits with code 1

#### Scenario: Mise doctor check

**Given** mise is installed
**When** validation runs `mise doctor`
**Then** it reports PASS if no critical issues
**And** reports WARN if issues exist with guidance to run `mise doctor`

#### Scenario: Mise experimental features

**Given** mise is installed
**When** validation checks `settings.experimental`
**Then** it reports PASS if experimental = true
**And** reports WARN if experimental features are disabled

#### Scenario: Mise node backend

**Given** mise is installed
**When** validation checks `settings.node_backend`
**Then** it reports PASS if node_backend = "bun"
**And** reports WARN if set to a different value

#### Scenario: Mise pip backend

**Given** mise is installed
**When** validation checks `settings.pip_backend`
**Then** it reports PASS if pip_backend = "uv"
**And** reports WARN if set to a different value

---

### Requirement: Core Runtime Validation

The system MUST validate core runtimes are installed.

#### Scenario: Bun installed

**Given** bun is installed via mise
**When** validation runs
**Then** it reports PASS for "Bun installed"
**And** displays the bun version

#### Scenario: Bun not installed

**Given** bun is not installed
**When** validation runs
**Then** it reports WARN for "Bun not installed"

#### Scenario: Uv installed

**Given** uv is installed via mise
**When** validation runs
**Then** it reports PASS for "Uv installed"
**And** displays the uv version

#### Scenario: Pixi installed

**Given** pixi is installed via mise
**When** validation runs
**Then** it reports PASS for "Pixi installed"
**And** displays the pixi version

---

### Requirement: Python Isolation Validation

The system MUST validate Python is not using system installation.

#### Scenario: Python isolated

**Given** Python is managed by mise/pixi/uv
**When** validation checks `which python`
**Then** it reports PASS for "Python isolated"
**And** the path does NOT contain `/usr/bin/`

#### Scenario: System Python in use

**Given** Python resolves to `/usr/bin/python`
**When** validation runs
**Then** it reports FAIL for "Using system Python"
**And** provides guidance that Python should be managed by mise/pixi/uv

#### Scenario: Python not in PATH

**Given** Python is not in PATH
**When** validation runs
**Then** it reports INFO "Python not in PATH (will be installed per-project)"

---

### Requirement: Shell Tools Validation

The system MUST validate shell tools are configured.

#### Scenario: Starship installed

**Given** starship is installed via mise
**When** validation runs
**Then** it reports PASS for "Starship installed"
**And** displays the starship version

#### Scenario: Starship config exists

**Given** starship is installed
**And** `~/.config/starship.toml` exists
**When** validation runs
**Then** it reports PASS for "Starship config exists"

#### Scenario: Starship config missing

**Given** starship is installed
**And** `~/.config/starship.toml` does not exist
**When** validation runs
**Then** it reports WARN for "Starship config not found"

#### Scenario: Zoxide installed

**Given** zoxide is installed via mise
**When** validation runs
**Then** it reports PASS for "Zoxide installed"
**And** displays the zoxide version

---

### Requirement: Search Tools Validation

The system MUST validate search tools are installed.

#### Scenario: Ripgrep installed

**Given** ripgrep is installed via mise
**When** validation runs
**Then** it reports PASS for "Ripgrep installed"
**And** displays the ripgrep version

#### Scenario: fd installed

**Given** fd is installed via mise
**When** validation runs
**Then** it reports PASS for "fd installed"
**And** displays the fd version

#### Scenario: ast-grep installed

**Given** ast-grep (sg) is installed via mise
**When** validation runs
**Then** it reports PASS for "ast-grep installed"
**And** displays the ast-grep version

---

### Requirement: Dotfile Management Validation

The system MUST validate chezmoi is configured.

#### Scenario: Chezmoi installed

**Given** chezmoi is installed via mise
**When** validation runs
**Then** it reports PASS for "Chezmoi installed"
**And** displays the chezmoi version

---

### Requirement: Secrets Management Validation

The system MUST validate secrets management options.

#### Scenario: 1Password CLI installed

**Given** 1Password CLI (op) is installed
**When** validation runs
**Then** it reports PASS for "1Password CLI installed"
**And** displays the version

#### Scenario: 1Password CLI not installed

**Given** 1Password CLI is not installed
**When** validation runs
**Then** it reports WARN for "1Password CLI not installed"

#### Scenario: Infisical installed

**Given** infisical is installed
**When** validation runs
**Then** it reports PASS for "Infisical installed"

#### Scenario: Infisical not installed

**Given** infisical is not installed
**When** validation runs
**Then** it reports INFO for "Infisical not installed (optional)"

---

### Requirement: Container Runtime Validation

The system MUST validate container runtime availability.

#### Scenario: OrbStack available

**Given** OrbStack is installed
**When** validation runs
**Then** it reports PASS for "OrbStack available"

#### Scenario: OrbStack running

**Given** OrbStack is installed and running
**When** validation runs
**Then** it reports PASS for "OrbStack running"

#### Scenario: OrbStack not running

**Given** OrbStack is installed but not running
**When** validation runs
**Then** it reports WARN for "OrbStack not running"

#### Scenario: Docker available (not OrbStack)

**Given** Docker is installed but not OrbStack
**When** validation runs
**Then** it reports PASS for "Docker available (not OrbStack)"

#### Scenario: No container runtime

**Given** neither OrbStack nor Docker is installed
**When** validation runs
**Then** it reports WARN for "No container runtime found"

#### Scenario: DevPod installed

**Given** DevPod is installed
**When** validation runs
**Then** it reports PASS for "DevPod installed"

---

### Requirement: Cloud Integration Validation

The system MUST validate SkyPilot configuration.

#### Scenario: SkyPilot installed

**Given** SkyPilot (sky) is installed
**When** validation runs
**Then** it reports PASS for "SkyPilot installed"

#### Scenario: SkyPilot configured

**Given** SkyPilot is installed
**And** cloud credentials are configured
**When** validation runs `sky check`
**Then** it reports PASS for "SkyPilot configured with cloud credentials"

#### Scenario: SkyPilot not configured

**Given** SkyPilot is installed
**And** cloud credentials are not configured
**When** validation runs
**Then** it reports WARN for "SkyPilot cloud credentials not configured"

---

### Requirement: AI Tools Validation

The system MUST validate AI development tools.

#### Scenario: GitHub CLI installed

**Given** GitHub CLI (gh) is installed
**When** validation runs
**Then** it reports PASS for "GitHub CLI installed"
**And** displays the version

#### Scenario: GitHub CLI authenticated

**Given** GitHub CLI is installed and authenticated
**When** validation runs `gh auth status`
**Then** it reports PASS for "GitHub CLI authenticated"

#### Scenario: GitHub CLI not authenticated

**Given** GitHub CLI is installed but not authenticated
**When** validation runs
**Then** it reports WARN for "GitHub CLI not authenticated"
**And** suggests running `gh auth login`

---

### Requirement: Summary and Exit Codes

The system MUST provide clear summary and appropriate exit codes.

#### Scenario: All checks pass

**Given** all validation checks pass
**When** validation completes
**Then** it displays "Environment is fully configured and healthy!"
**And** exits with code 0

#### Scenario: Some warnings

**Given** some validation checks show warnings
**And** no checks fail
**When** validation completes
**Then** it displays "Environment is functional but has some warnings"
**And** suggests running `mise install` to fix missing tools
**And** exits with code 0

#### Scenario: Critical failures

**Given** one or more validation checks fail
**When** validation completes
**Then** it displays "Environment has critical issues that need attention"
**And** exits with code 1

#### Scenario: Results summary

**Given** validation completes
**When** the summary is displayed
**Then** it shows the count of: passed, warnings, failed
**And** displays the total number of checks run

---

## Output Format

### Expected Output Structure

```
Running Environment Health Check...
   [timestamp]

--- Mise (Orchestrator) ---
PASS: Mise installed: mise 2024.x.x
PASS: Mise doctor: no critical issues
PASS: Mise experimental features enabled
PASS: Mise node_backend = bun
PASS: Mise pip_backend = uv

--- Core Runtimes ---
PASS: Bun installed: 1.x.x
PASS: Uv installed: uv 0.x.x
PASS: Pixi installed: pixi 0.x.x

[... additional sections ...]

--- Summary ---

Results: X passed, Y warnings, Z failed (out of N checks)

[Status message based on results]
```

### Status Icons

| Status | Icon | Meaning |
|--------|------|---------|
| PASS | `✅` | Check passed |
| WARN | `⚠️` | Non-critical issue |
| FAIL | `❌` | Critical issue |
| INFO | `ℹ️` | Informational |
