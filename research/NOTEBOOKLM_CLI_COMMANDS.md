# NotebookLM CLI Commands for Adding Sources

This document provides commands to add sources to the NotebookLM notebook "macOS Dev Environment Research".

---

## Prerequisites

```bash
# Install the CLI
pip install notebooklm-cli

# Authenticate (opens browser)
nlm login
```

---

## Notebook ID

The notebook created earlier has this approximate URL:
```
https://notebooklm.google.com/notebook/65d2e821-a46a-426c-8087-467329cfd790
```

You can create an alias for easier reference:
```bash
nlm alias set macos-dev 65d2e821-a46a-426c-8087-467329cfd790
```

---

## Commands to Add Sources

### GitHub Repositories (Already Added Manually)

These were added through the browser UI:
- jdx/mise
- prefix-dev/pixi
- astral-sh/uv
- oven-sh/bun
- apple/pkl
- skypilot-org/skypilot
- Textualize/textual
- twpayne/chezmoi
- ast-grep/ast-grep
- mixedbread-ai/mgrep
- tmc/nlm
- jacob-bd/notebooklm-cli
- ericbuess/claude-code-docs

### Add New Sources via CLI

Run these commands to add additional sources:

```bash
# Set the notebook alias first
nlm alias set macos-dev <notebook-id>

# Add awesome-claude-code repository
nlm source add macos-dev --url "https://github.com/hesreallyhim/awesome-claude-code"

# Add claude_setting_manager repository
nlm source add macos-dev --url "https://github.com/shyinlim/claude_setting_manager"

# Add mise MCP documentation
nlm source add macos-dev --url "https://mise.jdx.dev/mcp.html"

# Add 1Password CLI documentation
nlm source add macos-dev --url "https://developer.1password.com/docs/cli/"

# Add DevPod documentation
nlm source add macos-dev --url "https://devpod.sh/docs/getting-started/overview"

# Add Starship documentation
nlm source add macos-dev --url "https://starship.rs/guide/"

# Add Zoxide documentation
nlm source add macos-dev --url "https://github.com/ajeetdsouza/zoxide"

# Add GitHub CLI documentation
nlm source add macos-dev --url "https://cli.github.com/manual/"

# Add Chezmoi quick start
nlm source add macos-dev --url "https://www.chezmoi.io/quick-start/"

# Add OrbStack documentation
nlm source add macos-dev --url "https://docs.orbstack.dev/"

# Add ripgrep documentation
nlm source add macos-dev --url "https://github.com/BurntSushi/ripgrep"

# Add fd documentation
nlm source add macos-dev --url "https://github.com/sharkdp/fd"

# Add Google Gemini CLI
nlm source add macos-dev --url "https://github.com/google/gemini-cli"
```

---

## Research Commands

After adding sources, you can use the research feature:

```bash
# Start a research session
nlm research start "Best practices for mise configuration" --notebook-id macos-dev

# Query the notebook
nlm notebook query macos-dev "What tools should be included in a mise-based dev environment?"

# Generate audio overview
nlm audio create macos-dev --confirm
```

---

## Deep Research Feature

To use NotebookLM's Deep Research:

```bash
# Enable research mode
nlm research start "Compare tool management approaches: mise vs asdf vs nvm/pyenv" \
  --notebook-id macos-dev \
  --depth deep

# Research specific topics
nlm research start "Security best practices for mise secrets management" \
  --notebook-id macos-dev

nlm research start "MCP integration patterns for AI coding assistants" \
  --notebook-id macos-dev
```

---

## Batch Source Addition Script

Save this as `add-notebooklm-sources.sh`:

```bash
#!/bin/bash
# Add sources to NotebookLM notebook

NOTEBOOK_ID="${1:-macos-dev}"

SOURCES=(
    "https://github.com/hesreallyhim/awesome-claude-code"
    "https://github.com/shyinlim/claude_setting_manager"
    "https://mise.jdx.dev/mcp.html"
    "https://developer.1password.com/docs/cli/"
    "https://devpod.sh/docs/getting-started/overview"
    "https://starship.rs/guide/"
    "https://github.com/ajeetdsouza/zoxide"
    "https://cli.github.com/manual/"
    "https://www.chezmoi.io/quick-start/"
    "https://docs.orbstack.dev/"
    "https://github.com/BurntSushi/ripgrep"
    "https://github.com/sharkdp/fd"
    "https://github.com/google/gemini-cli"
)

echo "Adding ${#SOURCES[@]} sources to notebook: $NOTEBOOK_ID"

for url in "${SOURCES[@]}"; do
    echo "Adding: $url"
    nlm source add "$NOTEBOOK_ID" --url "$url"
    sleep 2  # Rate limiting
done

echo "Done! Run 'nlm source list $NOTEBOOK_ID' to verify."
```

---

## List All Sources

```bash
nlm source list macos-dev
```

---

## Export Notebook

```bash
# Export as markdown
nlm notebook export macos-dev --format markdown --output research-notes.md

# Export as JSON
nlm notebook export macos-dev --format json --output research-data.json
```

---

*Generated: January 2026*
