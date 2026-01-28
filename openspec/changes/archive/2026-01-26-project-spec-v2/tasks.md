# Tasks: Project Backlog

## Overview

This document defines the implementation backlog for the God-Tier macOS Development Environment, derived from `PROJECT_PLAN.md`.

## Sprint Status

| Sprint | Status | Description |
|--------|--------|-------------|
| P1: Core | **COMPLETE** | Foundation: setup.sh, mise config, validation |
| P2: Enterprise | Backlog | DevContainer, secrets, uninstall |
| P3: Polish | Backlog | IDE configs, macOS defaults, migration |
| P4: Nice-to-Have | Backlog | Proxy, team onboarding |

---

## P1: Core Completeness (COMPLETE)

### US-1: Dotfile Management (Chezmoi) ✅

**Story**: As a developer, I want my shell and git configurations automatically managed, so that I have a consistent environment across machines.

**Deliverables**:
- [x] `.zshrc` template → `config/chezmoi/dot_zshrc.tmpl`
- [x] `.gitconfig` template → `config/chezmoi/dot_gitconfig.tmpl`
- [x] Chezmoi config → `config/chezmoi/.chezmoi.toml.tmpl`
- [x] BATS tests → `tests/test_chezmoi.bats`

---

### US-2: Shell Prompt (Starship) ✅

**Story**: As a developer, I want a context-aware shell prompt, so that I can see git/python/node status at a glance.

**Deliverables**:
- [x] Starship config → `config/starship.toml`
- [x] Shows: git branch, python, node, bun, aws, docker, mise
- [x] BATS tests → `tests/test_starship.bats`

---

### US-3: Environment Validation ✅

**Story**: As a developer, I want to verify my environment is correctly configured, so that I can troubleshoot issues quickly.

**Deliverables**:
- [x] Validation script → `config/scripts/validate.sh`
- [x] BATS tests → `tests/test_*.bats` (5 files, 63 tests)
- [x] Exit codes: 0=pass, non-zero=fail

---

## P2: Enterprise Ready

### US-4: DevContainer Support

**Story**: As a developer, I want to run this environment in DevContainers, so that I can use remote development.

**Acceptance Criteria**:
- [ ] `.devcontainer/devcontainer.json` configuration
- [ ] Works with DevPod
- [ ] Works with OrbStack devcontainers
- [ ] Documentation for remote development

**Estimated Effort**: Medium (1-2 days)

---

### US-5: Secrets Integration Documentation

**Story**: As a developer, I want clear documentation on secrets management, so that I can safely store API keys.

**Acceptance Criteria**:
- [ ] 1Password integration guide
- [ ] Infisical integration guide
- [ ] Mise native secrets guide
- [ ] Examples for common secrets (ANTHROPIC_API_KEY, etc.)

**Estimated Effort**: Small (0.5 days)

---

### US-6: Uninstall Script

**Story**: As a developer, I want a clean uninstall option, so that I can remove everything if needed.

**Acceptance Criteria**:
- [ ] `uninstall.sh` script
- [ ] Removes `~/.local/share/mise`
- [ ] Removes `~/.config/mise` and `~/.config/dev-env`
- [ ] Removes shell activation from `.zshrc`
- [ ] Preserves user data (prompts before deletion)

**Estimated Effort**: Small (0.5 days)

---

## P3: Polish

### US-7: IDE Configurations

**Story**: As a developer, I want pre-configured IDE settings, so that my editor works well with mise.

**Acceptance Criteria**:
- [ ] Zed configuration (`.zed/settings.json`)
- [ ] VS Code configuration (`.vscode/settings.json`)
- [ ] Mise path integration for LSPs
- [ ] Recommended extensions list

**Estimated Effort**: Medium (1 day)

---

### US-8: macOS Defaults Script

**Story**: As a developer, I want sensible macOS defaults, so that my system is optimized for development.

**Acceptance Criteria**:
- [x] `config/scripts/macos-defaults.sh` created
- [ ] Finder: show hidden files, path bar, extensions
- [ ] Dock: auto-hide, minimize to icon
- [ ] Keyboard: fast repeat, disable auto-correct
- [ ] Screenshots: save to ~/Screenshots
- [ ] Interactive confirmation before applying

**Estimated Effort**: Small (already started)

---

### US-9: Migration Guides

**Story**: As a developer migrating from nvm/pyenv, I want clear migration instructions.

**Acceptance Criteria**:
- [ ] `docs/MIGRATE_FROM_NVM.md`
- [ ] `docs/MIGRATE_FROM_PYENV.md`
- [ ] `docs/MIGRATE_FROM_ASDF.md`
- [ ] Common gotchas and troubleshooting

**Estimated Effort**: Medium (1 day)

---

## P4: Nice-to-Have

### US-10: Proxy Configuration

**Story**: As a developer behind a corporate proxy, I want proxy settings to work automatically.

**Acceptance Criteria**:
- [ ] HTTP_PROXY / HTTPS_PROXY support
- [ ] Git proxy configuration
- [ ] npm/bun proxy configuration
- [ ] Documentation for common proxies

**Estimated Effort**: Medium (1 day)

---

### US-11: Team Onboarding Documentation

**Story**: As a team lead, I want onboarding docs for my team, so that everyone uses the same environment.

**Acceptance Criteria**:
- [ ] `docs/TEAM_ONBOARDING.md`
- [ ] Shared `mise.toml` patterns
- [ ] CI/CD integration examples
- [ ] Troubleshooting FAQ

**Estimated Effort**: Medium (1 day)

---

## Task Dependencies

```
P1 (Complete) ──┬──> P2: Enterprise
                │
                └──> P3: Polish ──> P4: Nice-to-Have
```

## Definition of Done

A task is complete when:
1. ✅ Code implemented and committed
2. ✅ Tests written and passing (TDD)
3. ✅ Documentation updated
4. ✅ Works on clean macOS install
5. ✅ Self-reviewed

## Priority Legend

| Priority | Meaning |
|----------|---------|
| P1 | Must have - blocks basic functionality |
| P2 | Should have - enterprise requirements |
| P3 | Nice to have - polish and convenience |
| P4 | Future - deferred but documented |
