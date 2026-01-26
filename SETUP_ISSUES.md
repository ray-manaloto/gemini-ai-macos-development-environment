# Setup Issues - Fix Required

## Error Summary

When running `./setup.sh`, the following error occurs:

```
▶ Installing core generator tools (Pkl, Pixi, Gum)...
mise ERROR Failed to install tools: prefix-dev/pixi@latest, charmbracelet/gum@latest
prefix-dev/pixi@latest: Failed to run ~/.local/share/mise/plugins/prefix-dev-pixi/bin/list-all: No such file or directory (os error 2)
charmbracelet/gum@latest: Failed to run ~/.local/share/mise/plugins/charmbracelet-gum/bin/list-all: No such file or directory (os error 2)
```

## Root Cause

The `setup.sh` script uses incorrect tool names for mise. The tools `prefix-dev/pixi` and `charmbracelet/gum` are **asdf plugin names**, not mise backend names.

**Problematic line in setup.sh (line 74):**
```bash
mise use -g pkl prefix-dev/pixi charmbracelet/gum
```

## Solution

Mise has different backends and tool naming conventions:

| Wrong (asdf plugin style) | Correct (mise backend) |
|---------------------------|------------------------|
| `prefix-dev/pixi` | `pixi` (native mise support) |
| `charmbracelet/gum` | `go:github.com/charmbracelet/gum` or `ubi:charmbracelet/gum` |

### Fix Required

Update `setup.sh` to use correct mise tool names:

```bash
# OLD (broken):
mise use -g pkl prefix-dev/pixi charmbracelet/gum

# NEW (correct):
mise use -g pkl pixi ubi:charmbracelet/gum
```

Or use aqua/ubi backends for tools not natively supported:
```bash
mise use -g pkl pixi
mise use -g ubi:charmbracelet/gum
```

## Mise Tool Naming Reference

| Tool | Correct Mise Name |
|------|-------------------|
| Pixi | `pixi` (built-in) |
| Gum | `ubi:charmbracelet/gum` or `aqua:charmbracelet/gum` |
| Pkl | `pkl` (built-in) |
| Bun | `bun` (built-in) |
| Starship | `starship` (built-in) |
| Node | `node` (built-in) |

## Steps to Fix

1. Edit `setup.sh`
2. Change line 74 from:
   ```bash
   mise use -g pkl prefix-dev/pixi charmbracelet/gum
   ```
   To:
   ```bash
   mise use -g pkl pixi ubi:charmbracelet/gum
   ```
3. Re-run `./setup.sh`

## Verification

After fix, run:
```bash
mise doctor
mise ls
```

Should show pkl, pixi, and gum installed without errors.

---

**Priority**: HIGH - Blocks entire setup
**Assignee**: Claude Code
**Status**: ✅ RESOLVED - Fix applied to setup.sh line 74 on 2026-01-26
