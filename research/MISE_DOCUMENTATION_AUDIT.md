# Mise Documentation Audit

Comprehensive audit of mise documentation to identify features we should use, potential issues, and areas needing user consultation.

---

## Key Documentation Pages Reviewed

1. [Home](https://mise.jdx.dev/)
2. [Dev Tools](https://mise.jdx.dev/dev-tools/)
3. [Configuration](https://mise.jdx.dev/configuration.html)
4. [MCP](https://mise.jdx.dev/mcp.html)
5. [Comparison to asdf](https://mise.jdx.dev/dev-tools/comparison-to-asdf.html)

---

## ✅ Features We SHOULD Be Using

### 1. Configuration Hierarchy
**Status**: Partially implemented

We're using a single global config via Pkl → TOML. We should leverage:
- `~/.config/mise/config.toml` for global defaults
- Project-level `mise.toml` for project-specific tools
- `mise.local.toml` for local overrides (git-ignored)

**Recommendation**: Update setup to support this hierarchy.

### 2. Tool Options with postinstall
**Status**: Not implemented

Mise supports running commands after tool installation:
```toml
[tools]
node = { version = "22", postinstall = "corepack enable" }
```

**Action Items**:
- [ ] Add `postinstall = "corepack enable"` to node
- [ ] Consider postinstall hooks for other tools

### 3. OS-Specific Tools
**Status**: Not implemented

Mise can restrict tools to specific operating systems:
```toml
[tools]
ripgrep = { version = "latest", os = ["linux", "macos"] }
```

**Action Items**:
- [ ] Consider using this for macOS-specific tools
- [ ] Useful if we want cross-platform support later

### 4. Shell Aliases
**Status**: Not implemented

Mise can set shell aliases per-directory:
```toml
[shell_alias]
ll = "ls -la"
gs = "git status"
dev = "npm run dev"
```

**Action Items**:
- [ ] Add common aliases for dev workflow
- [ ] Consider git shortcuts

### 5. Minimum Version Enforcement
**Status**: Not implemented

Ensure users have compatible mise version:
```toml
min_version = { hard = '2024.11.1', soft = '2024.9.0' }
```

**Action Items**:
- [ ] Add `min_version` to config to ensure compatibility

### 6. Environment-Specific Configs
**Status**: Not implemented

Mise supports `mise.development.toml`, `mise.production.toml`, etc.:
```bash
MISE_ENV=development mise install
```

**Action Items**:
- [ ] Consider creating `mise.development.toml` for dev-specific tools
- [ ] Useful for different cloud environments

### 7. Idiomatic Version Files
**Status**: Not configured

Mise can read `.nvmrc`, `.python-version`, `.ruby-version`, etc.:
```toml
[settings]
idiomatic_version_file_enable_tools = ['node', 'python']
```

**Action Items**:
- [ ] Enable for node and python for better compatibility
- [ ] Helps with existing projects using these files

### 8. Auto-Install Settings
**Status**: Implicitly enabled (defaults)

Mise has intelligent auto-install:
- `exec_auto_install` - for `mise x`
- `task_auto_install` - for `mise r`
- `not_found_auto_install` - for missing commands

**Recommendation**: Keep defaults, they're sensible.

### 9. Trusted Config Paths
**Status**: Not configured

Auto-trust configs in specific directories:
```toml
[settings]
trusted_config_paths = [
  '~/work/my-trusted-projects',
]
```

**Action Items**:
- [ ] Add common development paths to trusted_config_paths
- [ ] Reduces `mise trust` prompts

### 10. Custom Plugin URLs
**Status**: Not implemented

Override plugin sources for internal/custom plugins:
```toml
[plugins]
node = "https://github.com/my-org/mise-node.git"
```

**Recommendation**: Not needed unless using custom forks.

---

## ⚠️ Features Needing User Consultation

### 1. Secrets Management Approach

**Options**:
- A) 1Password CLI with `op://` URIs
- B) Infisical for team secrets
- C) Mise native secrets (`mise secrets set`)

**Current**: Both 1password-cli and infisical in tool list

**Question**: Which approach do you prefer for API keys?

### 2. Shims vs PATH Activation

**Options**:
- A) `mise activate zsh` (modifies PATH, faster)
- B) `mise activate --shims` (creates shims, more compatible)

**Current**: Using `eval "$(mise activate zsh)"` (PATH modification)

**Question**: Are there any tools that don't work with PATH activation?

### 3. Global vs Project Tools

**Question**: Should all tools be global, or should some be project-specific?

**Current**: Everything is global via `~/.config/mise/config.toml`

### 4. Job Parallelism

**Default**: `jobs = 4`

**Question**: Increase for faster installs? (depends on CPU/network)

### 5. Experimental Features

**Status**: `experimental = true` in our config

**Warning**: MCP requires `MISE_EXPERIMENTAL=1`

**Question**: Are you okay with experimental features enabled?

---

## 🐛 Potential Issues/Bugs Found

### 1. Documentation 404 Error

**Issue**: `/configuration/` returns 404, correct path is `/configuration.html`

**Impact**: Low - just documentation navigation

### 2. MCP Feature is Experimental

**Warning from docs**:
> "The MCP feature is experimental and requires enabling experimental features with MISE_EXPERIMENTAL=1."

**Impact**: MCP may change or break in future versions

**Mitigation**: We handle this with env var in MCP config

### 3. Plugin Cache Duration Not Implemented

**From docs**:
> "plugin_autoupdate_last_check_duration = '1 week' # set to 0 to disable updates
> (note: this isn't currently implemented but there are plans to add it)"

**Impact**: Plugins may not auto-update as expected

### 4. Cargo Backend Naming

**Observation**: Gemini chat used `cargo:` prefix (e.g., `cargo:starship`)
**Reality**: Mise docs show this works, but some tools may use different naming

**Action**: Verify all cargo-prefixed tools install correctly

---

## 📋 Configuration Improvements

### Update config/main.pkl with These Settings

```pkl
// Add to settings section
settings = new {
  experimental = true
  node_backend = "bun"
  pip_backend = "uv"

  // NEW: Add these
  jobs = 4                           // Parallel installs
  verbose = false                    // Clean output
  not_found_auto_install = true      // Auto-install missing tools

  // Enable idiomatic version files for compatibility
  idiomatic_version_file_enable_tools = new Listing {
    "node"
    "python"
  }

  // Trust common development paths
  trusted_config_paths = new Listing {
    "~/dev"
    "~/work"
    "~/projects"
  }
}
```

### Add postinstall Hooks

```pkl
// Update tools with postinstall
["node"] = new {
  version = "latest"
  postinstall = "corepack enable"
}
```

### Add Shell Aliases

```pkl
// Add shell_alias section
shell_alias = new {
  ["ll"] = "ls -la"
  ["gs"] = "git status"
  ["gp"] = "git pull"
  ["gc"] = "git commit"
  ["dev"] = "mise run dashboard"
}
```

### Add Min Version

```pkl
// At top of output
min_version = new {
  hard = "2024.11.0"
  soft = "2024.9.0"
}
```

---

## 📚 Documentation Resources

- [Mise JSON Schema](https://mise.jdx.dev/schema/mise.json) - For editor autocompletion
- [Mise Task Schema](https://mise.jdx.dev/schema/mise-task.json) - For task files
- [Settings Reference](https://mise.jdx.dev/configuration/settings.html)
- [Tasks Reference](https://mise.jdx.dev/tasks/)
- [Environments Reference](https://mise.jdx.dev/environments/)

---

## 🎯 Priority Actions

### High Priority
1. [ ] Add `min_version` to ensure compatibility
2. [ ] Enable idiomatic version files for node/python
3. [ ] Add `postinstall` for node to enable corepack
4. [ ] Verify all cargo-prefixed tools install correctly

### Medium Priority
5. [ ] Add shell aliases for common commands
6. [ ] Configure trusted_config_paths for common dev directories
7. [ ] Test MCP integration thoroughly

### Low Priority
8. [ ] Consider OS-specific tool restrictions
9. [ ] Add environment-specific configs if needed
10. [ ] Document any plugin URL overrides needed

---

*Audit completed: January 2026*
*Mise version at time of audit: Latest (2026)*
