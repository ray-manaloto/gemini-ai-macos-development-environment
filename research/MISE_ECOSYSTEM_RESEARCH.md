# Mise Ecosystem Research

Research on mise-based development environment setups, alternatives, and community resources.

---

## Notable Mise-Based Dotfiles Repositories

### 1. jasonraimondi/dotfiles
**URL**: https://github.com/jasonraimondi/dotfiles

A comprehensive macOS development environment setup featuring:
- Modular dotfiles with GNU Stow
- Mise integration for programming language versions
- Homebrew with categorized Brewfiles (Requirefile, Brewfile, Caskfile, Fontfile, Macfile)
- `.tool-versions` for consistent environments

### 2. webpro/dotfiles
**URL**: https://github.com/webpro/dotfiles

Cross-platform dotfiles (macOS, Ubuntu, Arch Linux):
- Makefile-based installation
- Homebrew + Caskroom + Node.js
- Latest Bash + GNU Utils
- Tested weekly on real machines via GitHub Actions (Ventura, Sonoma, Sequoia)

### 3. driesvints/dotfiles
**URL**: https://github.com/driesvints/dotfiles

Popular macOS dotfiles starter:
- One-command setup
- Comprehensive documentation
- Good starting point for beginners

### 4. joshukraine/dotfiles
**URL**: https://github.com/joshukraine/dotfiles

Modern dotfiles with AI integration:
- Claude Code integration for AI-assisted development
- Neovim, Zsh/Fish, Ghostty + Tmux
- AI assistance is optional

### 5. CodelyTV/dotfiles
**URL**: https://github.com/CodelyTV/dotfiles

Speed-focused macOS setup:
- Fine-tuned settings for performance
- Well-documented customizations

---

## Mise vs asdf Comparison

### Performance

| Aspect | asdf (bash) | asdf (go 0.16+) | mise |
|--------|-------------|-----------------|------|
| Shim overhead | ~120ms | Faster | ~0ms (no shims) |
| Startup time | Slow | Moderate | Fast |
| Written in | Bash | Go | Rust |

> "asdf's shims have terrible performance, adding ~120ms to every runtime call. mise activate does not use shims and instead updates PATH."

### Key Differences

1. **No Shims**: mise updates PATH directly, eliminating shim overhead
2. **Built-in Language Support**: Native support for major languages (no plugins needed)
3. **Additional Features**:
   - Environment variable management (replaces direnv)
   - Task runner (replaces make)
   - Secrets management
4. **Plugin Compatibility**: Can use asdf plugins when needed

### References
- [Mise vs asdf Comparison (Better Stack)](https://betterstack.com/community/guides/scaling-nodejs/mise-vs-asdf/)
- [Official Comparison to asdf](https://mise.jdx.dev/dev-tools/comparison-to-asdf.html)
- [Why I Switched from asdf to mise (Medium)](https://medium.com/@nidhivya18_77320/why-i-switched-from-asdf-to-mise-and-you-should-too-8962bf6a6308)

---

## Other Version Managers

### Alternative Tools

| Tool | Description | Windows Support |
|------|-------------|-----------------|
| **proto** | Pluggable version manager, unified toolchain | ✅ |
| **vfox** | Cross-platform, extensible | ✅ |
| **asdf** | Original polyglot manager | ❌ |
| **mise** | Modern asdf alternative | Limited |

### References
- [Awesome Version Managers](https://github.com/bernardoduarte/awesome-version-managers)
- [asdf Alternatives (AlternativeTo)](https://alternativeto.net/software/asdf-1/)
- [asdf Alternatives (LibHunt)](https://www.libhunt.com/r/asdf)

---

## Community Discussions

### Erlang Forums Thread
**URL**: https://erlangforums.com/t/asdf-vs-mise-your-thoughts/5201

Discussion comparing asdf vs mise from Erlang developer perspective.

### DEV Community
**URL**: https://dev.to/binbingoloo/2025-macos-development-environment-setup-guide-4jj0

2025 macOS Development Environment Setup Guide covering mise and other tools.

---

## Mise Documentation Resources

### Official Documentation
- [Mise Homepage](https://mise.jdx.dev/)
- [Getting Started](https://mise.jdx.dev/getting-started.html)
- [Dev Tools](https://mise.jdx.dev/dev-tools/)
- [MCP Integration](https://mise.jdx.dev/mcp.html)

### Third-Party Guides
- [Getting Started with Mise (Better Stack)](https://betterstack.com/community/guides/scaling-nodejs/mise-explained/)
- [mise-en-place for Managing Development Tooling (Field Notes)](https://www.stuartellis.name/articles/mise-en-place/)
- [Mise Setup (Coumets Dev)](https://coumets.dev/mise/setup/)
- [Installing Swift with Mise](https://www.swifttoolkit.dev/posts/mise-swift)

---

## Installation Methods

### macOS

```bash
# Via curl (recommended)
curl https://mise.run | sh

# Via Homebrew
brew install mise

# Via MacPorts
sudo port install mise
```

### Post-Installation

```bash
# Add to ~/.zshrc
eval "$(mise activate zsh)"

# Verify installation
mise doctor
```

---

## GitHub Topics to Watch

- https://github.com/topics/dotfiles-macos
- https://github.com/topics/mise
- https://github.com/topics/version-manager
- https://github.com/topics/dev-environment

---

## Key Takeaways

1. **mise is the clear successor to asdf** for most use cases
2. **Performance is significantly better** due to PATH manipulation vs shims
3. **Additional features** (env vars, tasks) reduce tool sprawl
4. **Plugin compatibility** means easy migration from asdf
5. **Active community** with many dotfiles repos adopting mise

---

*Research conducted: January 2026*
