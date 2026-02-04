# Future Tools Research

Research findings for optional tools that enhance the development environment.

## Summary

| Tool | Purpose | Recommendation | Priority |
|------|---------|----------------|----------|
| **atuin** | Shell history sync | ✅ Add | High |
| **age** | File encryption | ✅ Add | Medium |
| **direnv** | Per-directory env vars | ❌ Skip | Low |

## Atuin - Enhanced Shell History

**Repository**: https://github.com/atuinsh/atuin

### What It Does

Atuin replaces your shell history with a SQLite database that records:
- Command text
- Exit code
- Duration
- Timestamp
- Working directory
- Hostname/session

Features:
- Full-screen fuzzy search (replaces Ctrl+R)
- Filter by directory, exit code, time
- Optional end-to-end encrypted sync across machines
- Statistics and analytics

### Installation

```bash
# Install via mise
mise use -g atuin@latest

# Add to shell config (~/.zshrc)
eval "$(atuin init zsh)"
```

### Privacy Options

1. **Local only** (no sync): `auto_sync = false`
2. **Self-hosted server**: Run your own atuin server
3. **Atuin Cloud**: End-to-end encrypted (zero-knowledge)

### Recommendation

**✅ STRONGLY RECOMMEND** - Aligns with mise-first philosophy, enhances productivity, privacy-first design.

---

## Age - Modern File Encryption

**Repository**: https://github.com/FiloSottile/age

### What It Does

Modern, simple alternative to GPG for file encryption:
- Small text keys (~60 characters)
- X25519 + ChaCha20-Poly1305 cryptography
- Post-quantum support (hybrid ML-KEM-768)
- SSH key support (convenience feature)
- No config files, no keyring

### Installation

```bash
# Install via mise
mise use -g "aqua:FiloSottile/age"

# Generate key for chezmoi
age-keygen -o ~/.config/chezmoi/age.txt
```

### Use Cases

| Use Case | Tool | Why |
|----------|------|-----|
| Runtime API keys | 1Password CLI | Dynamic, revocable, audited |
| Encrypted dotfiles | age | Version-controlled, shareable |
| Team secret sharing | age (recipients) | Multiple recipients |
| Backup encryption | age | Simple, no dependencies |

### Chezmoi Integration

```toml
# ~/.config/chezmoi/chezmoi.toml
encryption = "age"
[age]
    identity = "~/.config/chezmoi/age.txt"
    recipient = "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"
```

Then encrypt sensitive dotfiles:
```bash
chezmoi add --encrypt ~/.env
chezmoi add --encrypt ~/.aws/credentials
```

### Recommendation

**✅ RECOMMEND** - Complements 1Password (file encryption vs runtime secrets), perfect chezmoi integration.

---

## Direnv - Per-Directory Environment

**Repository**: https://direnv.net/

### What It Does

Automatically loads/unloads environment variables when entering directories:
- Shell hook for auto-activation
- `.envrc` files with shell scripting
- Rich stdlib (40+ helper functions)
- Security model (`direnv allow`)

### Comparison with Mise [env]

| Feature | direnv | mise [env] |
|---------|--------|------------|
| Auto-activation | ✅ | ✅ |
| PATH management | ✅ `PATH_add` | ✅ `_.path` |
| Dotenv loading | ✅ `dotenv` | ✅ `_.file` |
| Shell sourcing | ✅ `source_env` | ✅ `_.source` |
| Templating | ❌ | ✅ |
| Caching | ❌ | ✅ |
| Redaction | ❌ | ✅ |
| Language layouts | ✅ `layout python` | ⚠️ Limited |

### Official Stance

From mise documentation:
> "The official stance is you should not use direnv with mise."

Reasons:
- Both tools hook into shell environment
- Can conflict when managing same tools
- PATH ordering issues

### Recommendation

**❌ SKIP** - mise [env] covers 90% of use cases with additional features (templating, caching, redaction). Adding direnv introduces complexity and potential conflicts.

**Exception**: Add direnv only if you need:
- Nix integration (`use nix`, `use flake`)
- Language layouts (`layout python`, `layout go`)
- Existing `.envrc` files from other projects

---

## Implementation Plan

### Phase 1: Add Recommended Tools

Add to `config/mise.toml`:

```toml
[tools]
# Enhanced shell history
atuin = "latest"

# Modern file encryption (for chezmoi)
"aqua:FiloSottile/age" = "latest"
```

### Phase 2: Shell Integration

Update `config/chezmoi/dot_zshrc.tmpl`:

```bash
# Atuin - Enhanced shell history
if command -v atuin &> /dev/null; then
  eval "$(atuin init zsh)"
fi
```

### Phase 3: Chezmoi Encryption (Optional)

```bash
# Generate age key
age-keygen -o ~/.config/chezmoi/age.txt

# Configure chezmoi
cat >> ~/.config/chezmoi/chezmoi.toml <<EOF
encryption = "age"
[age]
    identity = "~/.config/chezmoi/age.txt"
    recipient = "<your-public-key>"
EOF

# Store key in 1Password
op item create --category=password --title="Chezmoi Age Key" \
  private_key="$(cat ~/.config/chezmoi/age.txt)"
```

### Phase 4: Validation

Add to `tests/test_tools.bats`:

```bash
@test "atuin is installed via mise" {
  run mise which atuin
  [ "$status" -eq 0 ]
}

@test "age is installed via mise" {
  run mise which age
  [ "$status" -eq 0 ]
}
```

---

## Not Recommended

### Tools Evaluated But Not Added

| Tool | Reason |
|------|--------|
| **direnv** | mise [env] is sufficient, potential conflicts |
| **nvm** | Use mise instead |
| **pyenv** | Use mise instead |
| **asdf** | mise is a faster, Rust-based replacement |
| **rbenv** | Use mise instead |

---

## See Also

- [SECRETS.md](SECRETS.md) - Secrets management guide
- [MIGRATION.md](MIGRATION.md) - Migrating from other tools
- [mise documentation](https://mise.jdx.dev/) - Official mise docs
