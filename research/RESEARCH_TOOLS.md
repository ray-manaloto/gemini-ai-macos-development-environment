# Research Tools for macOS Dev Environment Validation

This document summarizes the tools and resources gathered for validating and researching the God-Tier macOS Development Environment setup.

## 📁 Downloaded Repositories

All repositories are cloned to `research/repos/`:

| Repository | Description | Use Case |
|------------|-------------|----------|
| **jdx/mise** | Polyglot tool version manager | Core tool manager in our setup |
| **prefix-dev/pixi** | Fast package manager built on conda-forge | Python/system binary isolation |
| **astral-sh/uv** | Extremely fast Python package manager | Backend for pip operations |
| **oven-sh/bun** | Fast JS/TS runtime | Replaces Node.js/npm |
| **apple/pkl** | Configuration language | Type-safe TOML generation |
| **skypilot-org/skypilot** | ML and AI workload orchestrator | AWS spot instance management |
| **Textualize/textual** | Python TUI framework | Dashboard building |
| **twpayne/chezmoi** | Dotfile manager | Cross-machine synchronization |
| **ast-grep/ast-grep** | AST-based code search/lint/rewrite | Code analysis and refactoring |
| **mixedbread-ai/mgrep** | Semantic code search | AI-powered code discovery |
| **tmc/nlm** | NotebookLM CLI (Go) | Research automation |
| **jacob-bd/notebooklm-cli** | NotebookLM CLI (Python) | Research automation |
| **ericbuess/claude-code-docs** | Claude Code docs mirror | Documentation access |

---

## 🔍 Code Analysis Tools

### ast-grep
- **Install**: `npm install -g @ast-grep/cli` or `brew install ast-grep`
- **Purpose**: Structural code search, lint, and rewriting using AST
- **Features**:
  - Pattern matching that looks like ordinary code
  - jQuery-like API for AST traversal
  - YAML configuration for custom rules
  - MCP server available for AI integration
- **Use**: `sg --pattern '$FUNC($ARGS)' --lang python`

### mgrep (Semantic Search)
- **Install**: `npm install -g @mixedbread/mgrep`
- **Purpose**: AI-powered semantic code search
- **Features**:
  - Natural language queries
  - Background indexing with `mgrep watch`
  - Web search integration with `--web` flag
  - Uses ~2x fewer tokens than grep-based workflows
- **Use**: `mgrep "find authentication logic"`

---

## 📚 NotebookLM CLI Tools

### nlm (Go CLI by tmc)
```bash
# Install
go install github.com/tmc/nlm/cmd/nlm@latest

# Authenticate
nlm auth

# Core commands
nlm list                    # List notebooks
nlm create "Title"          # Create notebook
nlm add <id> <url>          # Add source
nlm sources <id>            # List sources
nlm audio-create <id>       # Create audio overview
```

### notebooklm-cli (Python CLI by jacob-bd)
```bash
# Install
pip install notebooklm-cli
# or
uv tool install notebooklm-cli

# Authenticate
nlm login

# Core commands
nlm notebook list
nlm notebook create "Title"
nlm source add <id> --url "https://..."
nlm audio create <id> --confirm
nlm research start "query" --notebook-id <id>
```

**Key Differences**:
- Go CLI (`nlm`): Simpler, batch mode, audio focus
- Python CLI: Full API coverage, aliases, research integration, AI-teachable (`nlm --ai`)

---

## 📖 Claude Code Docs Mirror

```bash
# Install
curl -fsSL https://raw.githubusercontent.com/ericbuess/claude-code-docs/main/install.sh | bash

# Usage (as slash command in Claude Code)
/docs hooks         # Read hooks documentation
/docs mcp           # Read MCP documentation
/docs changelog     # Read Claude Code release notes
/docs what's new    # Show recent doc changes
```

---

## 🎓 NotebookLM Notebook Created

**Notebook**: "macOS Dev Environment Research"
**Location**: https://notebooklm.google.com
**Sources Added**: 22 sources including:

### GitHub Repositories
- mise, pixi, uv, bun, pkl
- skypilot, textual, chezmoi
- ast-grep, mgrep
- nlm, notebooklm-cli
- claude-code-docs

### Documentation Sites
- mise.jdx.dev
- pixi.sh
- docs.astral.sh/uv
- bun.sh/docs
- pkl-lang.org
- ast-grep.github.io

### YouTube Videos
- UV Python tutorial (Corey Schafer)
- Additional relevant tutorials

---

## 🔬 Research Workflow

### 1. Code Validation with ast-grep
```bash
# Find all function calls matching a pattern
sg --pattern 'mise.$METHOD($$$)' --lang bash

# Lint for anti-patterns
sg scan --rule rules/mise-best-practices.yml
```

### 2. Semantic Search with mgrep
```bash
# Index the project
cd gemini-ai-macos-development-environment
mgrep watch

# Search semantically
mgrep "how is pixi configured"
mgrep "where are environment variables set"
```

### 3. Research Aggregation with NotebookLM CLI
```bash
# Add new sources as you discover them
nlm source add <notebook-id> --url "https://new-resource.com"

# Query across all sources
nlm notebook query <id> "What are the best practices for mise configuration?"

# Generate audio overview for passive learning
nlm audio create <id> --confirm
```

### 4. Claude Code Documentation
```bash
# Check if your hooks are correctly configured
/docs hooks

# Understand MCP integration
/docs mcp
```

---

## 📊 Tool Comparison

| Feature | ast-grep | mgrep |
|---------|----------|-------|
| Search Type | Structural (AST) | Semantic (AI) |
| Speed | Very fast | Fast (indexed) |
| Pattern Syntax | Code-like | Natural language |
| Refactoring | Yes (rewrite) | No |
| AI Integration | MCP server | Native |
| Best For | Code transforms | Intent discovery |

---

## 🚀 Quick Start

```bash
# 1. Install code analysis tools
npm install -g @ast-grep/cli @mixedbread/mgrep

# 2. Install NotebookLM CLI
pip install notebooklm-cli --break-system-packages

# 3. Install Claude Code docs
curl -fsSL https://raw.githubusercontent.com/ericbuess/claude-code-docs/main/install.sh | bash

# 4. Index your project for semantic search
cd ~/dev/gemini-ai-macos-development-environment
mgrep watch

# 5. Run validation
sg scan  # AST-based linting
mgrep "check environment setup"  # Semantic search
```

---

## 📚 Additional Resources

- [Mise Documentation](https://mise.jdx.dev/)
- [Pixi Documentation](https://pixi.sh/)
- [UV Documentation](https://docs.astral.sh/uv/)
- [ast-grep Playground](https://ast-grep.github.io/playground.html)
- [NotebookLM](https://notebooklm.google.com/)

---

*Generated for macOS Dev Environment Research Project*
