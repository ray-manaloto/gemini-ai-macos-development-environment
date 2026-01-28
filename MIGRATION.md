# Migration Guide: From nvm/pyenv/asdf to Mise

Transitioning from legacy version managers to Mise's unified approach.

---

## Why Migrate?

| Legacy Tool | Issue | Mise Advantage |
|-------------|-------|----------------|
| **nvm** | Slow shell startup, Node-only | 10x faster, polyglot |
| **pyenv** | Slow, shim-based, Python-only | Native builds, polyglot |
| **asdf** | Plugin ecosystem fragile | Rust core, native backends |
| **rbenv** | Ruby-only, slow | Polyglot, fast |
| **Multiple tools** | Configuration scattered | Single config file |

**Mise provides:**
- 10x faster shell startup
- Single `.mise.toml` configuration
- Native backends (not plugins)
- Bun/uv integration for faster package management

---

## Migration from nvm

### Step 1: Export Current Node Version

```bash
# Check current Node version
node --version
# v20.10.0

# Note any global packages
npm list -g --depth=0
```

### Step 2: Install Mise and Node

```bash
# Install mise (if not already)
curl https://mise.run | sh

# Install same Node version via mise
mise use -g node@20.10
```

### Step 3: Migrate Global Packages

```bash
# Reinstall global npm packages via mise
mise use -g "npm:typescript"
mise use -g "npm:eslint"
mise use -g "npm:prettier"
# Add other packages as needed
```

### Step 4: Remove nvm

```bash
# Remove nvm from shell config
# Edit ~/.zshrc and remove:
#   export NVM_DIR="..."
#   [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Delete nvm directory
rm -rf ~/.nvm

# Verify mise Node is active
which node  # Should show ~/.local/share/mise/...
```

### Step 5: Update Project Configs

```bash
# Convert .nvmrc to mise.toml
# Before (.nvmrc):
# 20.10.0

# After (mise.toml):
cat > mise.toml << 'EOF'
[tools]
node = "20.10"
EOF
```

---

## Migration from pyenv

### Step 1: Export Current Python Version

```bash
# Check current Python version
python --version
# Python 3.11.6

# Export pip packages
pip freeze > requirements.txt
```

### Step 2: Install Mise and Python

```bash
# Install Python via mise (uses prebuilt binaries by default)
mise use -g python@3.11

# Or use pyenv-style builds
mise settings set python.compile true
mise use -g python@3.11
```

### Step 3: Migrate Pip Packages

```bash
# Use uv for faster installation
uv pip install -r requirements.txt

# Or for CLI tools, use mise
mise use -g "pipx:black"
mise use -g "pipx:ruff"
mise use -g "pipx:mypy"
```

### Step 4: Remove pyenv

```bash
# Remove pyenv from shell config
# Edit ~/.zshrc and remove:
#   export PYENV_ROOT="..."
#   eval "$(pyenv init -)"

# Delete pyenv directory
rm -rf ~/.pyenv

# Verify mise Python is active
which python  # Should show ~/.local/share/mise/...
```

### Step 5: Update Project Configs

```bash
# Convert .python-version to mise.toml
# Before (.python-version):
# 3.11.6

# After (mise.toml):
cat > mise.toml << 'EOF'
[tools]
python = "3.11"

[settings.python]
uv_venv_auto = true
EOF
```

---

## Migration from asdf

### Step 1: Export Current Tool Versions

```bash
# List all installed tools
asdf list

# Check .tool-versions
cat .tool-versions
```

### Step 2: Install Mise (Compatible)

Mise reads `.tool-versions` files directly:

```bash
# Install mise
curl https://mise.run | sh

# Mise automatically respects .tool-versions
mise install
```

### Step 3: Migrate to mise.toml (Optional)

```bash
# Convert .tool-versions to mise.toml
# Before (.tool-versions):
# nodejs 20.10.0
# python 3.11.6
# ruby 3.2.2

# After (mise.toml):
cat > mise.toml << 'EOF'
[tools]
node = "20.10"
python = "3.11"
ruby = "3.2"
EOF

# Remove old file
rm .tool-versions
```

### Step 4: Remove asdf

```bash
# Remove asdf from shell config
# Edit ~/.zshrc and remove:
#   . "$HOME/.asdf/asdf.sh"

# Delete asdf directory
rm -rf ~/.asdf

# Verify mise is active
mise doctor
```

---

## Key Differences

### Configuration Format

| Tool | Config File | Format |
|------|-------------|--------|
| nvm | `.nvmrc` | Version number only |
| pyenv | `.python-version` | Version number only |
| asdf | `.tool-versions` | `tool version` pairs |
| mise | `mise.toml` | Rich TOML with settings |

### mise.toml Features

```toml
# Multiple tools in one file
[tools]
node = "20"
python = "3.11"
ruby = "3.2"

# Environment variables
[env]
NODE_ENV = "development"

# Settings per tool
[settings.python]
uv_venv_auto = true

# Tasks (replaces npm scripts, Makefiles)
[tasks]
dev = "npm run dev"
test = "pytest"
```

### Package Management

| Legacy | Mise Equivalent |
|--------|-----------------|
| `npm install -g pkg` | `mise use -g "npm:pkg"` |
| `pip install pkg` | `mise use -g "pipx:pkg"` |
| `cargo install pkg` | `mise use -g "cargo:pkg"` |
| `gem install pkg` | `mise use -g "gem:pkg"` |

### Version Specification

```toml
[tools]
node = "20"           # Latest 20.x
node = "20.10"        # Latest 20.10.x
node = "20.10.0"      # Exact version
node = "latest"       # Latest stable
node = "lts"          # Latest LTS
```

---

## Project-Level Migration

### Before (Multiple Files)

```
project/
├── .nvmrc              # node version
├── .python-version     # python version
├── .ruby-version       # ruby version
├── package.json        # npm scripts
├── Makefile            # build commands
└── requirements.txt    # pip packages
```

### After (Single mise.toml)

```
project/
├── mise.toml           # Everything in one place
├── package.json        # npm dependencies only
└── requirements.txt    # pip dependencies only
```

```toml
# mise.toml
[tools]
node = "20"
python = "3.11"
ruby = "3.2"

[env]
NODE_ENV = "development"

[tasks]
dev = "npm run dev"
test = "pytest && npm test"
lint = "ruff check . && eslint src/"
build = "npm run build"
```

---

## CI/CD Migration

### GitHub Actions

```yaml
# Before (separate actions)
- uses: actions/setup-node@v4
  with:
    node-version: '20'
- uses: actions/setup-python@v5
  with:
    python-version: '3.11'

# After (single mise action)
- uses: jdx/mise-action@v2
```

### Docker

```dockerfile
# Before
FROM python:3.11
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
RUN apt-get install -y nodejs

# After
FROM ubuntu:22.04
RUN curl https://mise.run | sh
COPY mise.toml .
RUN mise install
```

---

## Troubleshooting Migration

### "Command not found" after migration

```bash
# Ensure mise is activated
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
source ~/.zshrc

# Verify
which node python
```

### "Wrong version being used"

```bash
# Check what mise sees
mise ls
mise where node

# Trust config file
mise trust mise.toml
```

### "Old tool still in PATH"

```bash
# Check PATH order
echo $PATH

# Remove old tool paths from ~/.zshrc
# Mise shims should come first
```

### "Packages missing after migration"

```bash
# Reinstall global packages
mise use -g "npm:typescript"
mise use -g "pipx:black"

# Verify
which tsc black
```

---

## Coexistence (Gradual Migration)

You can run mise alongside legacy tools temporarily:

```bash
# 1. Install mise
curl https://mise.run | sh

# 2. Add mise activation BEFORE legacy tools in ~/.zshrc
eval "$(mise activate zsh)"
# ... existing nvm/pyenv config below

# 3. Mise takes precedence when mise.toml exists
# 4. Gradually add mise.toml to projects
# 5. Remove legacy tools when ready
```

---

## Checklist

- [ ] Export current tool versions
- [ ] Export global packages list
- [ ] Install mise
- [ ] Install required tool versions via mise
- [ ] Reinstall global packages via mise
- [ ] Update project configs (.nvmrc → mise.toml)
- [ ] Remove legacy tool activation from ~/.zshrc
- [ ] Delete legacy tool directories
- [ ] Verify everything works (`mise doctor`)
- [ ] Update CI/CD pipelines

---

## Related Documentation

- [Mise Documentation](https://mise.jdx.dev/)
- [Mise Configuration](https://mise.jdx.dev/configuration.html)
- [Mise Backends](https://mise.jdx.dev/plugins/backends.html)
- [CLAUDE.md](./CLAUDE.md) - Project patterns
