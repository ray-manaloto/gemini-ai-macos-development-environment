# Specification: Dotfile Management

## Overview

This specification defines dotfile templates managed by Chezmoi.

## Template Files

### 1. Shell Configuration (`dot_zshrc.tmpl`)

**Location**: `config/chezmoi/dot_zshrc.tmpl`  
**Target**: `~/.zshrc`

**Content Requirements**:

```zsh
# 1. Mise activation (MUST be first)
eval "$(mise activate zsh)"

# 2. Starship prompt
eval "$(starship init zsh)"

# 3. Zoxide initialization
eval "$(zoxide init zsh)"

# 4. Modern CLI aliases
alias ls="eza --icons"
alias ll="eza --icons -la"
alias cat="bat"
alias grep="rg"
alias find="fd"
alias cd="z"

# 5. Git aliases
alias g="git"
alias gs="git status"
alias gd="git diff"
alias gc="git commit"
alias gp="git push"

# 6. History configuration
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
```

**Acceptance Criteria**:
- [ ] Mise activates correctly on shell start
- [ ] Starship prompt displays
- [ ] All aliases functional
- [ ] Zoxide `z` command works

---

### 2. Git Configuration (`dot_gitconfig.tmpl`)

**Location**: `config/chezmoi/dot_gitconfig.tmpl`  
**Target**: `~/.gitconfig`

**Content Requirements**:

```ini
[user]
    name = {{ .name | default "Developer" }}
    email = {{ .email | default "dev@example.com" }}

[core]
    editor = zed --wait
    pager = delta
    autocrlf = input
    excludesfile = ~/.gitignore_global

[init]
    defaultBranch = main

[pull]
    rebase = true

[push]
    autoSetupRemote = true

[merge]
    conflictStyle = diff3

[diff]
    colorMoved = default

[delta]
    navigate = true
    line-numbers = true
    syntax-theme = Dracula

[alias]
    co = checkout
    br = branch
    ci = commit
    st = status
    lg = log --oneline --graph --all
```

**Template Variables**:
- `.name`: User's full name (from chezmoi config)
- `.email`: User's email (from chezmoi config)

**Acceptance Criteria**:
- [ ] Git commands use delta for diffs
- [ ] Default branch is `main`
- [ ] Rebase on pull enabled

---

### 3. Chezmoi Configuration (`.chezmoi.toml.tmpl`)

**Location**: `config/chezmoi/.chezmoi.toml.tmpl`  
**Target**: `~/.config/chezmoi/chezmoi.toml`

**Content Requirements**:

```toml
[data]
    name = "{{ promptString "Your full name" }}"
    email = "{{ promptString "Your email address" }}"
    
[edit]
    command = "zed"
    args = ["--wait"]

[git]
    autoCommit = false
    autoPush = false

[diff]
    pager = "delta"
```

**Acceptance Criteria**:
- [ ] Prompts for name/email on first `chezmoi apply`
- [ ] Uses Zed as editor
- [ ] Uses Delta for diffs

---

### 4. Global Git Ignore (`dot_gitignore_global`)

**Location**: `config/chezmoi/dot_gitignore_global`  
**Target**: `~/.gitignore_global`

**Content Requirements**:

```gitignore
# macOS
.DS_Store
.AppleDouble
.LSOverride
._*

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# Python
__pycache__/
*.py[cod]
.venv/
venv/
.env

# Node
node_modules/
npm-debug.log*
.npm/

# Mise
.mise.local.toml

# Secrets
*.pem
*.key
.env.local
.env.*.local
```

**Acceptance Criteria**:
- [ ] Common files ignored across all repos
- [ ] No secrets accidentally committed

---

## Chezmoi Workflow

### Initial Setup

```bash
# 1. Initialize chezmoi with this repo's templates
chezmoi init --source ~/dev/github/ray-manaloto/gemini-ai-macos-development-environment/config/chezmoi

# 2. Preview changes
chezmoi diff

# 3. Apply templates
chezmoi apply
```

### Updating Dotfiles

```bash
# Edit a managed file
chezmoi edit ~/.zshrc

# Re-apply after editing templates
chezmoi apply

# See what would change
chezmoi diff
```

## Verification Tests

```bash
# tests/test_chezmoi.bats

@test "chezmoi source path is valid" {
  run chezmoi source-path
  [ "$status" -eq 0 ]
  [ -d "$output" ]
}

@test "dot_zshrc template exists" {
  source_path=$(chezmoi source-path)
  [ -f "$source_path/dot_zshrc.tmpl" ] || \
  [ -f "config/chezmoi/dot_zshrc.tmpl" ]
}

@test "dot_gitconfig template exists" {
  source_path=$(chezmoi source-path)
  [ -f "$source_path/dot_gitconfig.tmpl" ] || \
  [ -f "config/chezmoi/dot_gitconfig.tmpl" ]
}

@test "chezmoi templates are valid" {
  run chezmoi execute-template < config/chezmoi/dot_zshrc.tmpl
  [ "$status" -eq 0 ]
}
```
