# AI/LLM Agent Best Practices

Research findings from Vercel's agent evaluation series, applied to our development environment.

**Last Updated:** February 2026  
**Sources:** Vercel Engineering Blog (January-February 2026)

---

## Key Finding: AGENTS.md Outperforms Skills

| Configuration | Pass Rate | Notes |
|---------------|-----------|-------|
| Baseline (no docs) | 53% | Agent relies on pre-training |
| Skills (default) | 53% | Skills not invoked reliably |
| Skills (explicit instructions) | 79% | Better but fragile |
| **AGENTS.md with docs index** | **100%** | Always present, no decision point |

**Why AGENTS.md wins:** Content is always in context. Skills require agents to decide "should I look this up?" - and they fail to invoke 56% of the time.

---

## Critical Instruction Pattern

Add this to your AGENTS.md:

```markdown
> **IMPORTANT:** Prefer retrieval-led reasoning over pre-training-led reasoning 
> for [Framework] tasks. These tools evolve rapidly—consult project files and 
> documentation rather than relying on potentially outdated training data.
```

**Why it works:** Explicitly tells agents to use current documentation instead of potentially outdated training data.

---

## Content Negotiation for Agents

### HTTP Header Approach

Agents can request markdown versions using the `Accept` header:

```bash
curl https://example.com/docs/page -H "accept: text/markdown"
```

### URL Suffix Approach

Append `.md` to get markdown version:

```
https://example.com/docs/page.md
```

### Performance Impact

- HTML/CSS/JS: ~500KB
- Markdown: ~2KB
- **99.6% size reduction**

### For GitHub Projects

GitHub already serves raw markdown:
```
https://raw.githubusercontent.com/owner/repo/main/AGENTS.md
```

---

## Compressed Documentation Index

Instead of full docs, use a compressed index that points to retrievable files:

```markdown
[Tool Documentation Index]|root: ./.docs
|IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning
|mise:{installation.md,configuration.md,tasks.md,backends.md}
|bun:{runtime.md,package-manager.md,bundler.md}
|pixi:{getting-started.md,configuration.md,environments.md}
|uv:{installation.md,pip-interface.md,venv.md}
```

**Benefits:**
- 80% compression (40KB → 8KB)
- Agent reads specific files on demand
- Version-matched documentation
- Minimal context overhead

---

## Skills vs AGENTS.md

### Use AGENTS.md For:
- Project-specific context and conventions
- Codebase navigation ("where to look")
- Anti-patterns and rules
- Quick reference tables
- Static documentation

### Use Skills For:
- Repeatable workflows across projects
- Domain expertise (React patterns, SQL best practices)
- Multi-step processes with decision logic
- Shareable knowledge across teams
- Workflows with executable scripts

### Recommendation

Use **both together**:
- AGENTS.md: "Here's how THIS project works"
- Skills: "Here's HOW to do specific tasks"

---

## Filesystem + Bash Architecture

### Core Principle

Replace custom tooling with two primitives:
1. **Filesystem access** (read files, explore directories)
2. **Bash commands** (ls, grep, find, cat)

**Result:** Sales agent cost dropped from ~$1.00 to ~$0.25 per call with improved quality.

### Exploration-First Approach

```bash
# Start with directory structure
ls -la

# Find configuration files
find . -name "*.toml" -not -path "./.git/*"

# Search for patterns
grep -r "experimental" config/

# Read specific files on demand
cat config/mise.toml | head -50
```

### Directory Structure That Helps Agents

```bash
project/
├── AGENTS.md              # Agent entry point
├── config/
│   ├── mise.toml          # Tool configuration
│   └── scripts/           # Utility scripts
├── research/              # Documentation
│   └── *.md               # Searchable with grep
├── tests/                 # Validation
│   └── *.bats             # BATS test files
└── openspec/              # Specifications
    └── specs/             # Gherkin scenarios
```

### Treat Data Like Code

Agents are trained on billions of code navigation examples. Structure your project so they can:
- `grep` for specific values
- `find` files by pattern
- `cat` relevant sections
- Build context incrementally

---

## Security Considerations

### Sandboxed Execution

- Run agents in isolated compute
- Scope filesystem to task-relevant data only
- Read-heavy operations (ls, cat, grep, find)
- Write access only to specific directories

### Permission Model

| Operation | Allowed | Notes |
|-----------|---------|-------|
| `ls`, `cat`, `grep`, `find` | ✅ Yes | Read operations |
| `mise run <task>` | ✅ Yes | Defined tasks only |
| `rm`, `mv` | ⚠️ Careful | Restrict to temp directories |
| `sudo` | ❌ Never | User-space only |
| Network access | ⚠️ Careful | Sandbox from production |

---

## Application to Our Project

### What We Already Do Well

✅ **AGENTS.md** with navigation map and rules  
✅ **Markdown documentation** accessible via GitHub raw URLs  
✅ **Structured directories** (config/, research/, tests/)  
✅ **Anti-patterns documented** (Critical Rules section)  
✅ **Mise tasks** as agent interface  

### Improvements Applied

1. **Added retrieval-led reasoning instruction** to AGENTS.md
2. **Added exploration commands** for agent discovery
3. **llms.txt** provides documentation index
4. **Research tasks** for ecosystem monitoring

### Future Enhancements

- [ ] Create compressed documentation index for mise/bun/pixi/uv
- [ ] Add version tracking to AGENTS.md
- [ ] Create agent workspace preparation task
- [ ] Build eval suite for tool-specific tasks

---

## References

| Article | URL | Key Insight |
|---------|-----|-------------|
| Agent-Friendly Pages | https://vercel.com/blog/making-agent-friendly-pages-with-content-negotiation | Content negotiation, 99.6% size reduction |
| AGENTS.md vs Skills | https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals | 100% pass rate with docs index |
| Agent Skills FAQ | https://vercel.com/blog/agent-skills-explained-an-faq | Skills for workflows, AGENTS.md for context |
| Filesystem + Bash | https://vercel.com/blog/how-to-build-agents-with-filesystems-and-bash | Primitives beat custom tools |

---

*Research conducted: February 2026*
