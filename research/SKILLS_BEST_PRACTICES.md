# Skills Best Practices

Research-backed best practices for AI agent skills in this project. Based on Vercel Engineering's AGENTS.md research, Anthropic's skill-creator patterns, and oh-my-opencode's architecture.

## Key Finding: AGENTS.md Beats Skills

Vercel Engineering tested four approaches across 7 SWE tasks:

| Approach | Pass Rate |
|----------|-----------|
| AGENTS.md with compressed docs index | **100%** |
| Skills with explicit instructions | **79%** |
| Skills with default behavior | **53%** |
| No documentation at all | **53%** |

**Critical insight**: Skills with default behavior performed identically to no documentation. They weren't triggered in 56% of cases. Passive context (AGENTS.md) beats active retrieval (Skills) for horizontal knowledge.

Source: [Vercel Blog - Best Practices for Building AGENTS.md](https://vercel.com/blog/best-practices-for-building-agents-md)

## When to Use What

| Knowledge Type | Use | Why |
|---------------|-----|-----|
| **Horizontal** (always relevant) | AGENTS.md | Always in context, 100% hit rate |
| **Vertical** (action-specific) | Skills | Loaded on-demand, saves context window |
| **Reference** (look-up) | Skills with references/ | Progressive disclosure, loaded only when needed |

### AGENTS.md (Horizontal Knowledge)

Best for:
- Project identity, structure, conventions
- Tool hierarchy (Mise > Bun > Pixi > Uv)
- Critical rules (never sudo, never npm -g)
- Navigation tables (file → purpose)
- Command reference (mise run X)
- Anti-patterns (what NOT to do)
- Compressed docs index (pointing to retrievable files)

### Skills (Vertical Knowledge)

Best for:
- Step-by-step workflows (OpenSpec change lifecycle)
- Domain-specific procedures (BATS test patterns)
- Tool-specific expertise (Rust Iced/Tauri development)
- Non-interactive commands (/analyze, /investigate, /tdd)
- External tool integrations (Playwright, MCP builder)

## Skill Architecture in This Project

### Directory Structure

```
.agents/skills/    ← Universal source (managed by bunx skills CLI)
  ├── symlink → .claude/skills/     (Claude Code reads from here)
  └── symlink → .opencode/skills/   (OpenCode reads from here)
```

### How Oh-My-OpenCode Loads Skills

Oh-my-opencode discovers skills from 6 locations (in order):
1. **builtin** — playwright, dev-browser, frontend-ui-ux, git-master
2. **config** — oh-my-opencode.json `disabled_skills` can exclude
3. **user** — `~/.claude/skills/` (global, user-level)
4. **global** — `~/.config/opencode/skills/`
5. **project** — `.claude/skills/` (project-level)
6. **project** — `.opencode/skills/` (project-level)

When `delegate_task(load_skills=["name"])` runs, the skill's SKILL.md content is injected into the subagent's system prompt.

### Skill Loading is Lazy

Skills use a three-level progressive disclosure:
1. **Metadata** (name + description) — Always in context (~100 words)
2. **SKILL.md body** — Loaded only when skill triggers
3. **Bundled resources** (references/, scripts/, assets/) — Loaded only when agent reads them

This means a skill's `description` field is the primary triggering mechanism. A poorly written description = skill never triggers.

## Skill File Format

```markdown
---
name: skill-name
description: "What it does AND when to use it. Include trigger words."
---

# Skill Title

Instructions for using the skill...
```

### Description Best Practices

The description is the ONLY thing the agent sees before deciding whether to load the skill. Make it count:

**Good:**
```yaml
description: "BATS test patterns for this project's 948-test suite. Use when writing new BATS tests, debugging test failures, adding test coverage, or running the test suite. Triggers on: writing tests, test failures, bats, test_*.bats files."
```

**Bad:**
```yaml
description: "Testing skill"
```

### Body Best Practices

- Keep under 500 lines
- Use tables for quick reference
- Include code examples, not explanations
- Split large content into `references/` files
- Use imperative voice ("Run X", not "You should run X")
- Don't duplicate what's already in AGENTS.md

## Managing Skills

### Install from Trusted Sources

```bash
bunx skills add <org/repo> --skill <name> --agent claude-code opencode -y
```

Trusted sources:
- `anthropics/skills` — Official Anthropic (17 skills)
- `obra/superpowers` — Jesse Vincent (14 skills, high quality)
- `vercel-labs/agent-skills` — Vercel Engineering (4 skills)

### Create Custom Skills

```bash
bunx skills init <name>   # Creates template SKILL.md
# Edit .agents/skills/<name>/SKILL.md
# Symlink to .claude/skills/ and .opencode/skills/
```

### List Installed

```bash
bunx skills list            # Project skills
bunx skills list --global   # Global skills (should be empty)
```

### Update

```bash
bunx skills check    # Check for updates
bunx skills update   # Update all
```

## Current Skill Inventory

### Custom Project Skills (5)

| Skill | Domain | Triggers |
|-------|--------|----------|
| mise-expert | Mise config, tasks, backends | mise.toml, tool install, mise settings |
| bats-testing | BATS test patterns, assertions | test writing, test failures, .bats files |
| shell-scripting | Bash scripts, SwiftBar plugin | .sh files, setup.sh, shell functions |
| rust-dev | Iced + Tauri Rust backends | .rs files, Cargo.toml, cargo commands |
| menu-bar-dev | All 4 menu bar implementations | NSStatusItem, tray, DevEnvManager |

### Installed from Trusted Sources (7)

| Source | Skill | Purpose |
|--------|-------|---------|
| anthropics/skills | skill-creator | Create/update skills |
| anthropics/skills | mcp-builder | Build MCP servers |
| anthropics/skills | webapp-testing | Playwright web testing |
| obra/superpowers | systematic-debugging | Bug investigation workflow |
| obra/superpowers | test-driven-development | Red-green-refactor TDD |
| obra/superpowers | verification-before-completion | Evidence before assertions |
| vercel-labs/agent-skills | web-design-guidelines | UI/UX review |

### Workflow Skills (14, pre-existing)

| Skill | Purpose |
|-------|---------|
| openspec-* (10) | OpenSpec change workflow |
| analyze | Non-interactive code analysis |
| investigate | Non-interactive issue investigation |
| tdd | Non-interactive TDD workflow |
| refactor | Non-interactive code refactoring |

## Anti-Patterns

| Pattern | Why It's Bad | Do Instead |
|---------|-------------|------------|
| Global skills (`~/.claude/skills/`) | Leak across projects | Project-level only |
| Skills for horizontal knowledge | Only 53% trigger rate | Use AGENTS.md |
| Vague description field | Skill never triggers | Include trigger words |
| Duplicating AGENTS.md content | Wastes context window | Reference AGENTS.md |
| Skills over 500 lines | Context bloat | Split into references/ |
| `npx skills` | Bypasses mise | `bunx skills` |
