# Other Tools Audit for macOS Dev Environment

This document provides a brief audit of supplementary tools (pixi, uv, bun, chezmoi, starship) for use in a mise-managed macOS development environment.

---

## 1. Pixi

**Overview**: A fast, cross-platform, multi-language package manager built on the conda ecosystem, written in Rust.

### Key Features for macOS Dev Environment

- **Multi-language support**: Python, C++, R, Rust, and more via conda packages
- **Lockfile-based reproducibility**: Automatic `pixi.lock` generation ensures consistent environments
- **Task runner**: Define cross-platform tasks directly in `pixi.toml`
- **Multi-environment support**: Isolated features/environments in one manifest
- **PyPI integration**: Uses uv internally for PyPI packages (`pixi add --pypi <package>`)
- **Global tool installation**: Replace homebrew for isolated CLI tools

### Mise Integration

- **Current status**: Pixi is in mise tools registry; hooks can run `eval "$(pixi shell-hook)"`
- **Backend plugin**: Feature request exists for `pixi global` backend; custom backend infrastructure exists but not fully implemented
- **Recommended approach**: Use pixi alongside mise, with mise managing language versions and pixi managing project dependencies

### Best Practices

```toml
# pixi.toml example
[project]
name = "my-project"
channels = ["conda-forge"]
platforms = ["osx-arm64", "osx-64", "linux-64"]

[tasks]
test = "pytest"
lint = "ruff check ."

[dependencies]
python = ">=3.11"

[pypi-dependencies]
requests = "*"
```

- Set default channels in `$HOME/.pixi/config.toml`
- Use `pixi.lock` for reproducibility (commit to git)
- Define tasks for common workflows (test, lint, format)
- Use `pixi add --dev` for development-only dependencies

---

## 2. uv

**Overview**: An extremely fast Python package and project manager written in Rust by Astral (creators of Ruff).

### Key Features for macOS Dev Environment

- **10-100x faster** than pip/pip-tools
- **All-in-one replacement**: pip, pip-tools, pipx, poetry, pyenv, virtualenv
- **Universal lockfile**: `uv.lock` for reproducible builds
- **Python version management**: Install/manage Python versions directly
- **Single-file scripts**: PEP 723 inline dependency metadata support
- **Tool management**: `uvx` for running CLI tools without explicit installation

### Mise Integration

- **`pipx.uvx = true`**: Mise uses uvx instead of pipx when uv is on PATH
- **`python.uv_venv_auto = true`**: Auto-create/source venvs when `uv.lock` is present
- **`uv_create_args`**: Pass arguments to uv venv creation (e.g., `['--seed']` for pip)

```toml
# mise.toml
[tools]
python = "3.12"
uv = "latest"

[settings]
pipx.uvx = true

[env]
_.python.venv = { path = ".venv", create = true, uv = true }
```

### Best Practices

```toml
# pyproject.toml with uv
[project]
name = "my-project"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = ["requests>=2.28"]

[project.optional-dependencies]
dev = ["pytest", "ruff"]

[tool.uv]
dev-dependencies = ["pytest>=7.0", "ruff>=0.1"]
```

- Use `uv run` to guarantee correct environment
- Prefer version ranges (`>=0.68,<1.0`) over strict pins
- Use `uv add --dev` for development dependencies
- Commit `uv.lock` to version control
- Migrate from requirements.txt: `uv add -r requirements.txt`

---

## 3. Bun

**Overview**: An all-in-one JavaScript runtime, bundler, test runner, and package manager. Acquired by Anthropic in November 2025.

### Key Features for macOS Dev Environment

- **4x faster than Node.js** in benchmarks (powered by JavaScriptCore)
- **Native TypeScript/JSX**: Zero configuration transpilation
- **Built-in bundler**: Replace webpack/esbuild for many use cases
- **Hot reload**: `--hot` flag replaces nodemon
- **Built-in test runner**: Jest-compatible with fake timers
- **Bun.SQL**: Native database clients (MySQL, PostgreSQL, SQLite)
- **10-30% lower memory usage** in frameworks like Next.js

### Mise Integration

- **`npm.bun = true`**: Mise uses bun instead of npm when bun is on PATH
- **Direct installation**: `mise use bun@latest`

```toml
# mise.toml
[tools]
bun = "latest"

[settings]
npm.bun = true
```

### Best Practices

```toml
# bunfig.toml
[test]
coverage = true
coverageThreshold = { line = 0.8 }

[install]
# Use private registry if needed
# registry = "https://npm.company.com"

[run]
# Preload scripts for global setup
# preload = ["./setup.ts"]
```

- Keep `bunfig.toml` minimal; add options as needed
- Use `.env` files for secrets, not bunfig.toml
- Place `bunfig.toml` in project root alongside `package.json`
- Use `bun run --hot` for development servers
- Leverage native TypeScript support; skip separate transpilation step

---

## 4. Chezmoi

**Overview**: A dotfiles manager for managing personal configuration files across multiple machines securely.

### Key Features for macOS Dev Environment

- **Templates**: Go-based templates adapt dotfiles to different machines
- **Password manager integration**: 1Password, Bitwarden, LastPass, AWS Secrets Manager
- **Full file encryption**: age, gpg, git-crypt, or transcrypt support
- **Script execution**: Run setup scripts within dotfiles
- **Autocommit/autopush**: Automatic git commits when dotfiles change

### Mise Integration

- **Manage mise configs**: Store `.mise.toml`, `.tool-versions` as part of dotfiles
- **Template mise configs**: Use chezmoi templates to customize per-machine

```toml
# .chezmoi.toml.tmpl
[data]
    is_work = {{ promptBoolOnce . "is_work" "Is this a work machine" }}

{{ if .is_work }}
[merge]
    command = "code"
    args = ["--wait", "--diff"]
{{ end }}
```

### Best Practices

- Use `promptOnce` for machine-specific values
- Store secrets in password manager, not dotfiles repo
- Use `.chezmoidata.toml` for shared template variables
- Create templates for files that differ across machines:

```bash
# Add as template
chezmoi add --template ~/.mise.toml

# Manage sensitive files
chezmoi add --encrypt ~/.ssh/id_rsa
```

- Keep dotfiles repo public; use encryption for sensitive data
- Use `chezmoi diff` before `chezmoi apply` to preview changes

---

## 5. Starship

**Overview**: A minimal, blazing-fast, infinitely customizable prompt for any shell, written in Rust.

### Key Features for macOS Dev Environment

- **Cross-shell**: Works with Bash, Zsh, Fish, PowerShell, Nushell
- **Intelligent modules**: Shows relevant info (git branch, Python version, etc.)
- **mise module**: Displays mise health status from `mise doctor`
- **Performance**: Faster than alternatives like Spaceship
- **Presets**: Quick configuration with built-in themes

### Mise Integration

- **Mise module**: Shows mise health status (disabled by default)
- **Version display**: Automatically shows tool versions managed by mise

```toml
# ~/.config/starship.toml
[mise]
disabled = false
format = '[$symbol$status]($style) '

# Mise updates PATH every prompt; Starship reflects current versions
[python]
format = '[${symbol}${pyenv_prefix}(${version} )]($style)'

[nodejs]
format = '[$symbol($version )]($style)'
```

### Best Practices

```toml
# ~/.config/starship.toml - Performance-optimized config
scan_timeout = 10
follow_symlinks = false

[directory]
truncation_length = 3
truncate_to_repo = true

[git_status]
disabled = false

[mise]
disabled = false

# Disable unused modules for performance
[aws]
disabled = true

[gcloud]
disabled = true
```

- Set `scan_timeout` to avoid delays on networked filesystems
- Disable unused modules for faster prompt rendering
- Use `truncate_to_repo = true` for cleaner directory display
- Enable mise module for at-a-glance environment health

---

## Integration Summary for Mise-Managed Environment

| Tool | Mise Integration | Recommended Setup |
|------|------------------|-------------------|
| **pixi** | Registry entry, hooks support | Use alongside mise; pixi for project deps, mise for global versions |
| **uv** | `pipx.uvx`, `python.uv_venv_auto` | Enable uvx backend; auto-create venvs with uv.lock |
| **bun** | `npm.bun` setting | Enable as npm replacement for faster package installs |
| **chezmoi** | Manage mise config files | Store/template mise configs across machines |
| **starship** | Mise module in prompt | Enable mise module; configure version modules |

### Recommended mise.toml Configuration

```toml
[tools]
python = "3.12"
node = "22"
bun = "latest"
uv = "latest"

[settings]
pipx.uvx = true
npm.bun = true

[env]
_.python.venv = { path = ".venv", create = true, uv = true }

[hooks]
enter = 'eval "$(starship init zsh)"'
```

---

## Sources

### Pixi
- [Pixi Official Documentation](https://pixi.sh/latest/)
- [GitHub - prefix-dev/pixi](https://github.com/prefix-dev/pixi)
- [Pixi Project Configuration](https://prefix-dev.github.io/pixi/v0.34.0/reference/project_configuration/)

### uv
- [uv Official Documentation](https://docs.astral.sh/uv/)
- [GitHub - astral-sh/uv](https://github.com/astral-sh/uv)
- [uv Features](https://docs.astral.sh/uv/getting-started/features/)
- [Working on Projects with uv](https://docs.astral.sh/uv/guides/projects/)

### Bun
- [Bun Official Documentation](https://bun.com)
- [GitHub - oven-sh/bun](https://github.com/oven-sh/bun)
- [bunfig.toml Configuration](https://bun.com/docs/runtime/bunfig)

### Chezmoi
- [Chezmoi Official Documentation](https://www.chezmoi.io/)
- [GitHub - twpayne/chezmoi](https://github.com/twpayne/chezmoi)
- [Chezmoi Templating](https://www.chezmoi.io/user-guide/templating/)
- [Chezmoi Secret Functions](https://www.chezmoi.io/reference/templates/secret-functions/)

### Starship
- [Starship Official Guide](https://starship.rs/guide/)
- [GitHub - starship/starship](https://github.com/starship/starship)
- [Starship Configuration](https://starship.rs/config/)
- [Starship Advanced Configuration](https://starship.rs/advanced-config/)

### Mise Integration
- [Mise Settings](https://mise.jdx.dev/configuration/settings.html)
- [Mise Python Cookbook](https://mise.jdx.dev/mise-cookbook/python.html)
- [Mise Backend Plugin Development](https://mise.jdx.dev/backend-plugin-development.html)
