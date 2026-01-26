# Gaps Analysis: macOS Dev Environment Setup

This document identifies gaps in the current setup and recommends additional research or implementation.

---

## ✅ What We Have (Complete)

| Component | Status | Notes |
|-----------|--------|-------|
| **Mise** | ✅ Configured | Global tool manager in `setup.sh` |
| **Pixi** | ✅ Configured | In `main.pkl`, `pixi.toml` created |
| **Uv** | ✅ Configured | Set as pip backend |
| **Bun** | ✅ Configured | Set as node backend |
| **Pkl** | ✅ Configured | Config language with `main.pkl` |
| **OrbStack** | ✅ Listed | In tool list, needs manual install |
| **SkyPilot** | ✅ Configured | Template in `templates/agent.yaml` |
| **Textual Dashboard** | ✅ Created | `dashboard.py` script |
| **SwiftBar** | ✅ Script ready | `dev-status.1m.sh` |
| **GitHub Actions** | ✅ Configured | `validate.yml` workflow |
| **Research Tools** | ✅ Documented | ast-grep, mgrep, NotebookLM CLIs |

---

## ⚠️ Gaps Identified

### 1. Dotfile Management (Chezmoi) - NOT IMPLEMENTED

**Current State**: Mentioned in Gemini chat but not implemented

**Gap**: No chezmoi configuration, templates, or dotfile structure

**Recommendation**:
```
research/repos/chezmoi/          # ✅ Downloaded
config/chezmoi/                  # ❌ Missing - needs template files
~/.local/share/chezmoi/          # ❌ Not initialized
```

**Action Items**:
- [ ] Create `config/chezmoi/` directory with dotfile templates
- [ ] Add chezmoi initialization to `setup.sh`
- [ ] Create template for `.zshrc` with mise/starship activation
- [ ] Create template for `.gitconfig`

---

### 2. Shell Prompt (Starship) - NOT IMPLEMENTED

**Current State**: Not mentioned in current config

**Gap**: No Starship installation or configuration

**Recommendation**:
```pkl
// Add to config/main.pkl tools section
["brew:starship"] = "latest"
```

**Action Items**:
- [ ] Add Starship to tool list
- [ ] Create `config/starship.toml` preset
- [ ] Add shell initialization to chezmoi templates

---

### 3. DevPod Integration - NOT IMPLEMENTED

**Current State**: OrbStack listed but no DevPod

**Gap**: No devcontainer workflow for reproducible environments

**Recommendation**:
```
.devcontainer/
├── devcontainer.json
└── Dockerfile
```

**Action Items**:
- [ ] Add DevPod to tool list
- [ ] Create `.devcontainer/devcontainer.json`
- [ ] Configure OrbStack as DevPod provider

---

### 4. Secrets Manager Integration - INCOMPLETE

**Current State**: Infisical listed in tools but not configured

**Gap**: No actual secrets integration, no 1Password alternative

**Recommendation**:
```bash
# Option A: Infisical
infisical init
infisical run -- ./setup.sh

# Option B: 1Password CLI
op run --env-file=".env.1p" -- ./setup.sh
```

**Action Items**:
- [ ] Create secrets template (`.env.example`)
- [ ] Document 1Password CLI as alternative
- [ ] Add secrets loading to `setup.sh`

---

### 5. macOS System Preferences - NOT IMPLEMENTED

**Current State**: User-space only, no system settings

**Gap**: Many developers want consistent macOS settings

**Recommendation**: Create optional `scripts/macos-defaults.sh`:
```bash
# Example settings
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.dock autohide -bool true
```

**Action Items**:
- [ ] Create optional `macos-defaults.sh` script
- [ ] Document that this requires admin privileges
- [ ] Make it opt-in, not part of main setup

---

### 6. Validation Script - NEEDS ENHANCEMENT

**Current State**: Basic `validate.sh` exists

**Gap**: Doesn't test all components

**Current Tests**:
- Python isolation check
- Secrets availability
- Container runtime

**Missing Tests**:
- [ ] Mise installation verification
- [ ] Pkl compilation test
- [ ] Bun functionality test
- [ ] Network connectivity (for SkyPilot)
- [ ] Git configuration verification
- [ ] SSH key presence

---

### 7. Rollback/Uninstall Script - MISSING

**Current State**: No uninstall mechanism

**Gap**: Users can't cleanly remove the environment

**Recommendation**: Create `uninstall.sh`:
```bash
#!/bin/bash
# Remove symlink
rm -f ~/.config/dev-env

# Remove mise config (optional)
rm -f ~/.config/mise/config.toml

# Note: This does NOT remove mise itself or installed tools
```

---

### 8. IDE Configuration - INCOMPLETE

**Current State**: Zed listed but no config

**Gap**: No editor settings or extensions

**Recommendation**:
```
config/
├── zed/
│   └── settings.json
└── vscode/
    └── settings.json
```

**Action Items**:
- [ ] Create Zed settings template
- [ ] Create VS Code settings as alternative
- [ ] Add to chezmoi dotfiles

---

### 9. Network/Proxy Configuration - MISSING

**Current State**: Assumes direct internet access

**Gap**: Corporate environments may need proxy settings

**Recommendation**: Add optional proxy configuration:
```pkl
// In config/main.pkl env section (if needed)
env = new {
  ["HTTP_PROXY"] = ""
  ["HTTPS_PROXY"] = ""
  ["NO_PROXY"] = "localhost,127.0.0.1"
}
```

---

### 10. Testing Framework - MISSING

**Current State**: No automated tests

**Gap**: Can't verify setup works before deployment

**Recommendation**: Add test framework:
```
tests/
├── test_mise.bats        # Bats shell tests
├── test_pixi.bats
└── test_integration.py   # Python integration tests
```

---

## 📊 Priority Matrix

| Gap | Impact | Effort | Priority |
|-----|--------|--------|----------|
| Chezmoi dotfiles | High | Medium | **P1** |
| Starship prompt | Medium | Low | **P1** |
| Validation enhancement | High | Low | **P1** |
| Secrets integration | High | Medium | **P2** |
| DevPod/devcontainer | Medium | Medium | **P2** |
| Uninstall script | Low | Low | **P2** |
| IDE configuration | Medium | Low | **P3** |
| macOS defaults | Low | Low | **P3** |
| Testing framework | Medium | High | **P3** |
| Proxy configuration | Low | Low | **P4** |

---

## 🎯 Recommended Next Steps

### Phase 1: Core Completeness (P1)
1. Add Starship to tool list and create config
2. Implement chezmoi dotfile management
3. Enhance validation script

### Phase 2: Enterprise Ready (P2)
4. Complete secrets manager integration
5. Add DevPod/devcontainer support
6. Create uninstall script

### Phase 3: Polish (P3)
7. Add IDE configurations
8. Create optional macOS defaults script
9. Add testing framework

---

## 📚 Additional Research Needed

### Tools to Investigate
- [ ] **direnv** - Per-directory environment variables (alternative to mise env)
- [ ] **age** - Modern encryption for secrets (chezmoi integration)
- [ ] **atuin** - Shell history sync across machines
- [ ] **zoxide** - Smarter cd command
- [ ] **fzf** - Fuzzy finder for terminal
- [ ] **ripgrep** - Fast grep alternative (complements ast-grep)
- [ ] **bat** - Better cat with syntax highlighting
- [ ] **eza** - Modern ls replacement
- [ ] **delta** - Better git diff viewer

### Documentation Gaps
- [ ] Troubleshooting guide for common issues
- [ ] Migration guide from existing setups (nvm, pyenv, etc.)
- [ ] Team onboarding documentation

---

*Generated: January 2026*
