# Proposal: God-Tier macOS Development Environment

## Problem Statement

Modern macOS development suffers from **fragmented tool management**:

1. **Version Conflicts**: Multiple projects need different Python/Node versions, leading to `pyenv`, `nvm`, `asdf` sprawl
2. **System Pollution**: Homebrew installs globally, creating dependency conflicts and breaking system Python
3. **Non-Reproducible Environments**: New machines require hours of manual setup; teammates have "works on my machine" issues
4. **Tool Sprawl**: Developers juggle npm, pip, conda, cargo, go install - each with its own cache, config, and quirks
5. **No AI Integration**: Development environments don't expose context to AI assistants (Claude, Gemini, GitHub Copilot)

## Proposed Solution

A **mise-first development environment** that:

1. **Single Orchestrator**: Mise manages ALL tools (runtimes, CLIs, packages) through a unified interface
2. **User-Space Only**: Everything installs to `~/.local` - zero `sudo`, zero system modifications
3. **Strict Hierarchy**: `Mise > Bun > Pixi > Uv` ensures predictable package resolution
4. **Reproducible**: One `setup.sh` script creates identical environments on any macOS machine
5. **AI-Native**: MCP integration exposes environment context to Claude/Gemini for intelligent assistance

## Target Users

| Persona | Pain Point | How We Solve It |
|---------|------------|-----------------|
| **Solo Developer** | Hours wasted setting up new machines | `./setup.sh` gives complete env in 10 minutes |
| **Team Lead** | "Works on my machine" across team | Shared `mise.toml` ensures consistency |
| **AI-First Developer** | Claude doesn't know my environment | MCP integration exposes tools, versions, tasks |
| **Polyglot Developer** | Managing Python + Node + Rust versions | Mise handles all runtimes uniformly |

## Success Criteria

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Setup Time** | < 15 minutes | Time from clone to working environment |
| **Reproducibility** | 100% | Same tools/versions across machines |
| **System Modifications** | Zero | No files outside `~/.local` and `~/.config` |
| **Test Coverage** | 100% critical paths | All BATS tests pass |
| **AI Context** | Full environment visibility | Claude can query tools, versions, tasks via MCP |

## Non-Goals

- **Not a Docker replacement**: This is for native macOS development, not containerized workflows
- **Not cross-platform**: macOS-only (Linux would require different patterns)
- **Not managing GUI apps**: Only Homebrew casks for essential tools (OrbStack, Zed)
- **Not IDE configuration**: Users bring their own editor preferences

## Key Decisions

### Why Mise over asdf/rtx?

| Factor | Mise | asdf |
|--------|------|------|
| Speed | Rust-based, 10x faster | Shell-based, slow |
| Native Backends | Bun, Uv built-in | Requires plugins |
| Tasks | Built-in task runner | None |
| MCP | Native integration | None |

### Why Bun over Node?

- **3x faster** package installation
- **Native TypeScript** without transpilation
- **Drop-in replacement** for npm scripts
- Mise's `node_backend = "bun"` makes it transparent

### Why Uv over pip?

- **10x faster** package resolution
- **Deterministic lockfiles** by default
- **Cross-platform hashes** for reproducibility
- Mise's `pip_backend = "uv"` makes it transparent

### Why Pixi for binaries?

- **Conda-forge ecosystem**: FFmpeg, CUDA, scientific packages
- **Binary isolation**: No system library conflicts
- **Reproducible**: Lockfile-based installations

## Timeline

| Phase | Status | Deliverables |
|-------|--------|--------------|
| **P1: Core** | Complete | setup.sh, mise config, validation tests |
| **P2: Enterprise** | Backlog | DevContainer, secrets docs, uninstall |
| **P3: Polish** | Backlog | IDE configs, macOS defaults, migration guides |
| **P4: Nice-to-Have** | Backlog | Proxy config, team onboarding |

## References

- [Mise Documentation](https://mise.jdx.dev/)
- [Bun Documentation](https://bun.sh/)
- [Uv Documentation](https://docs.astral.sh/uv/)
- [Pixi Documentation](https://pixi.sh/)
- [research/CHATGPT_DEEP_RESEARCH.md](../../research/CHATGPT_DEEP_RESEARCH.md) - Original ChatGPT research
