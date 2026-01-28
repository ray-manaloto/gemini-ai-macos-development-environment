# Setup Issues - Tracking Document

This document tracks issues identified during environment setup and their resolution status.

---

## ✅ RESOLVED Issues

### Issue #1: Incorrect Tool Names in setup.sh (RESOLVED)

**Resolved**: 2026-01-26

**Problem**: Line 74 used asdf-style names (`prefix-dev/pixi`, `charmbracelet/gum`) instead of mise backend names.

**Error Message**:
```
mise ERROR Failed to install tools: prefix-dev/pixi@latest, charmbracelet/gum@latest
```

**Solution Applied**: Changed to mise backend names:
```bash
# Before (broken):
mise use -g pkl prefix-dev/pixi charmbracelet/gum

# After (fixed):
mise use -g pkl pixi ubi:charmbracelet/gum
```

---

### Issue #2: Missing macos-defaults.sh Script (RESOLVED)

**Resolved**: 2026-01-26

**Problem**: `main.pkl` referenced `config/scripts/macos-defaults.sh` for the `setup-mac` task, but the file didn't exist.

**Solution Applied**: Created `config/scripts/macos-defaults.sh` with developer-friendly macOS defaults:
- Finder: Show hidden files, path bar, status bar
- Dock: Autohide, speed optimizations
- Keyboard: Fast key repeat, disable smart quotes
- Screenshots: Save to ~/Screenshots as PNG
- Safari: Enable Developer menu

---

### Issue #3: Missing gum and bats Tools (RESOLVED)

**Resolved**: 2026-01-26

**Problem**: 
- `gum` required for `mise run help` task
- `bats` required for test suite (`bats tests/`)

**Solution Applied**: Added to mise global config:
```bash
mise use -g ubi:charmbracelet/gum npm:bats
```

---

## Mise Tool Naming Reference

| Tool | Correct Mise Name |
|------|-------------------|
| Pixi | `pixi` (built-in) |
| Gum | `ubi:charmbracelet/gum` |
| Pkl | `pkl` (built-in) |
| Bun | `bun` (built-in) |
| Bats | `npm:bats` |
| Starship | `starship` (built-in) |
| Node | `node` (built-in) |

---

## Verification Commands

```bash
# Check mise health
mise doctor

# List installed tools
mise ls

# Run validation script
./config/scripts/validate.sh

# Run test suite
bats tests/

# Test help command
mise run help
```

---

*Last updated: 2026-01-26*
