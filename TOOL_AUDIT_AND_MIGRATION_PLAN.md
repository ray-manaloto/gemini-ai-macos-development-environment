# Tool Audit and Migration Plan

**Generated:** 2026-02-01
**Goal:** Consolidate all tools under mise-first philosophy

---

## Executive Summary

| Category | Count | Status |
|----------|-------|--------|
| Homebrew Formulae | 112 | ⚠️ 26 top-level, many should migrate to mise |
| Homebrew Casks | 11 | ✅ OK (GUI apps) |
| Mise Tools | 45 | ✅ Properly managed |
| uv Tools (~/.local/bin) | 25 | ⚠️ Should migrate to mise pipx: |
| npm Global | 5 | ⚠️ Should migrate to mise npm: |

---

## Current Tool Landscape

### 1. Homebrew Formulae (112 total)

#### CLI Tools That Should Migrate to Mise (26 top-level)

| Tool | Current | Mise Backend | Priority |
|------|---------|--------------|----------|
| bat | Homebrew | aqua:sharkdp/bat | High |
| eza | Homebrew | asdf:mise-plugins/mise-eza | High |
| fzf | Homebrew | aqua:junegunn/fzf | High |
| shellcheck | Homebrew | aqua:koalaman/shellcheck | High |
| jq | Homebrew | aqua:jqlang/jq | High |
| yq | Homebrew | aqua:mikefarah/yq | High |
| delta | Homebrew | aqua:dandavison/delta | High |
| hyperfine | Homebrew | aqua:sharkdp/hyperfine | Medium |
| glow | Homebrew | aqua:charmbracelet/glow | Medium |
| lsd | Homebrew | aqua:lsd-rs/lsd | Medium |
| hadolint | Homebrew | aqua:hadolint/hadolint | Medium |
| direnv | Homebrew | aqua:direnv/direnv | Low (mise replaces) |
| tmux | Homebrew | github:tmux/tmux-builds | Low |
| tree | Homebrew | Keep (no mise backend) | - |

#### Build Dependencies (Keep in Homebrew)

These are libraries/dependencies, not CLI tools:
- openssl, curl, libpng, cairo, freetype, fontconfig
- llvm (for compilation)
- gnupg (for signing)
- docker, docker-compose, buildkit (container tooling)

#### Duplicates (Homebrew + Mise)

| Tool | Active Version | Action |
|------|----------------|--------|
| bat | Homebrew | Remove from Homebrew after mise install |
| fd | mise ✅ | Remove from Homebrew |
| ripgrep | mise ✅ | Remove from Homebrew |
| zoxide | mise ✅ | Remove from Homebrew (if in Homebrew) |
| gh | mise ✅ | Remove from Homebrew |

### 2. Homebrew Casks (11 total) ✅ OK

GUI applications should remain in Homebrew:
- ghostty, iterm2, wezterm (terminals)
- orbstack (containers)
- sublime-text (editor)
- mactex (LaTeX)
- gemini, opencode-desktop (AI tools)

### 3. Mise Tools (45 installed) ✅ Properly Managed

Currently managed by mise:
```
bun, node, pixi, uv, chezmoi, starship, ripgrep, fd, zoxide, 
ast-grep, github-cli, pkl, usage, pitchfork, 1password-cli,
npm:bats, npm:gemini-cli, npm:ralph-cli, pipx:mgrep, ubi:gum
```

### 4. uv Tools in ~/.local/bin (25 tools)

These were installed via `uv tool install` but should be managed by mise:

| Tool | Current | Migrate To |
|------|---------|------------|
| aider-chat | uv tool | pipx:aider-chat |
| crewai | uv tool | pipx:crewai |
| langchain-cli | uv tool | pipx:langchain-cli |
| langgraph-cli | uv tool | pipx:langgraph-cli |
| skypilot | uv tool | pipx:skypilot |
| pre-commit | uv tool | pipx:pre-commit |
| open-interpreter | uv tool | pipx:open-interpreter |
| mcpdoc | uv tool | pipx:mcpdoc |
| notebooklm-mcp-server | uv tool | pipx:notebooklm-mcp-server |

### 5. npm Global (5 packages)

Installed in node's global lib:

| Tool | Current | Migrate To |
|------|---------|------------|
| @anthropic-ai/claude-code | npm -g | npm:@anthropic-ai/claude-code |
| @mermaid-js/mermaid-cli | npm -g | npm:@mermaid-js/mermaid-cli |
| jscpd | npm -g | npm:jscpd |

---

## Step-by-Step Migration Plan

### Phase 1: Add Missing Tools to Mise Config (Day 1)

```bash
# 1. Add CLI tools to config/mise.toml [tools] section
mise use -g bat fzf shellcheck eza jq yq delta

# 2. Add AI/ML Python tools
mise use -g "pipx:aider-chat" "pipx:crewai" "pipx:langchain-cli"
mise use -g "pipx:langgraph-cli" "pipx:skypilot" "pipx:pre-commit"

# 3. Add npm tools
mise use -g "npm:@anthropic-ai/claude-code"
mise use -g "npm:@mermaid-js/mermaid-cli"
mise use -g "npm:jscpd"
```

### Phase 2: Verify Mise Tools Work (Day 1-2)

```bash
# Verify each tool works
mise doctor
mise run validate

# Check for shadows
mise run validate:tools
```

### Phase 3: Remove Homebrew Duplicates (Day 2)

```bash
# Remove CLI tools now managed by mise
brew uninstall bat eza fzf shellcheck jq yq delta hyperfine glow lsd hadolint

# Keep: docker, docker-compose, buildkit, gnupg, llvm
# Keep: All casks (GUI apps)
```

### Phase 4: Clean Up uv Tools (Day 2)

```bash
# Remove tools now managed by mise
uv tool uninstall aider-chat crewai langchain-cli langgraph-cli
uv tool uninstall skypilot pre-commit open-interpreter

# Verify mise versions work
mise which aider crewai langchain
```

### Phase 5: Clean Up npm Global (Day 2)

```bash
# Remove npm globals now managed by mise
npm uninstall -g @anthropic-ai/claude-code @mermaid-js/mermaid-cli jscpd

# Verify mise versions work
mise which claude-code mmdc jscpd
```

### Phase 6: Update config/mise.toml (Day 3)

Add all tools to the source of truth:

```toml
[tools]
# Core Runtimes
bun = "latest"
node = "latest"
pixi = "latest"
uv = "latest"

# Modern CLI Utilities (migrated from Homebrew)
bat = "latest"
eza = "latest"
fzf = "latest"
shellcheck = "latest"
jq = "latest"
yq = "latest"
delta = "latest"
hyperfine = "latest"
glow = "latest"
lsd = "latest"
hadolint = "latest"

# AI/ML Tools (migrated from uv)
"pipx:aider-chat" = "latest"
"pipx:crewai" = "latest"
"pipx:langchain-cli" = "latest"
"pipx:langgraph-cli" = "latest"
"pipx:skypilot" = "latest"
"pipx:pre-commit" = "latest"

# npm Tools (migrated from npm global)
"npm:@anthropic-ai/claude-code" = "latest"
"npm:@mermaid-js/mermaid-cli" = "latest"
"npm:jscpd" = "latest"
```

---

## DevContainer Enhancement Plan

### Current State
- Basic devcontainer.json exists
- Uses mise DevContainer feature
- Missing: Custom Dockerfile for more control

### Enhanced DevContainer Structure

```
.devcontainer/
├── devcontainer.json      # Enhanced configuration
├── Dockerfile             # Custom image with all tools
├── scripts/
│   ├── post-create.sh     # Setup script
│   └── post-attach.sh     # Verification script
└── .env.example           # Environment template
```

### Benefits of Enhanced DevContainer

1. **Complete Isolation**: All tools installed in container
2. **Reproducibility**: Same environment for all developers
3. **Fast Startup**: Pre-built image with tools cached
4. **CI/CD Ready**: Same container for GitHub Actions

---

## Rollback Plan

If migration causes issues:

```bash
# Re-install Homebrew tools
brew install bat eza fzf shellcheck jq yq delta

# Re-install uv tools
uv tool install aider-chat crewai langchain-cli

# Re-install npm globals
npm install -g @anthropic-ai/claude-code
```

---

## Success Criteria

- [ ] All CLI tools managed by mise (`mise which <tool>` shows mise path)
- [ ] No shadows detected (`mise run validate:tools` passes)
- [ ] Homebrew contains only: libraries, GUI apps, docker tools
- [ ] ~/.local/bin contains only: mise, opencode, fabric, mde-* scripts
- [ ] DevContainer builds and runs with all tools
- [ ] All 254+ BATS tests pass
