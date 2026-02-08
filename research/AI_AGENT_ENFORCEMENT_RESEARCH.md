# AI Agent Enforcement & Automation Research

> Deep research on lefthook and similar tools for AI/LLM agent enforcement, skill discovery, token tracking, documentation auto-updates, and self-learning mechanisms.

**Date**: 2026-02-07
**Status**: Complete

---

## Executive Summary

This research explores how to build a comprehensive enforcement and automation layer for AI/LLM agents that:

1. **Enforces skill discovery** before agents start work
2. **Tracks token usage** across multiple providers (Anthropic, OpenAI, Gemini)
3. **Auto-updates documentation** (AGENTS.md, etc.) based on agent activity
4. **Enables self-learning** through failure tracking and learnings persistence
5. **Works with OpenCode/oh-my-opencode** multi-provider architecture

---

## Table of Contents

1. [Git Hook Tools Comparison](#1-git-hook-tools-comparison)
2. [Current Project Infrastructure](#2-current-project-infrastructure)
3. [AI Agent Orchestration Patterns](#3-ai-agent-orchestration-patterns)
4. [Token Usage Tracking](#4-token-usage-tracking)
5. [Self-Learning Patterns](#5-self-learning-patterns)
6. [Documentation Auto-Update](#6-documentation-auto-update)
7. [Multi-Provider Considerations](#7-multi-provider-considerations)
   - [OpenCode/oh-my-opencode Extension Points](#74-opencodeoh-my-opencode-extension-points)
   - [Playwright Agent Automation Stack](#75-playwright-agent-automation-stack)
   - [Vercel Labs Skills & Tools](#76-vercel-labs-skills--tools)
8. [Implementation Proposal](#8-implementation-proposal)

---

## 1. Git Hook Tools Comparison

### 1.1 Lefthook (Recommended)

**Repository**: [evilmartians/lefthook](https://github.com/evilmartians/lefthook)
**Stars**: 7.5k | **Language**: Go | **Latest**: v2.1.0 (Feb 2026)

#### Key Features

| Feature | Description |
|---------|-------------|
| **Parallel Execution** | Run commands concurrently for speed |
| **Remote Hooks** | Fetch configs from remote repos |
| **Multiple Formats** | YAML, TOML, JSON, JSONC |
| **Local Overrides** | `lefthook-local.yml` for personal config |
| **CI/CD Integration** | Skip hooks in CI, env-aware |
| **Fast Startup** | Single Go binary, no runtime deps |

#### Configuration Example

```yaml
# lefthook.yml
min_version: 1.6.0

pre-commit:
  parallel: true
  commands:
    lint-shell:
      glob: "*.sh"
      run: shellcheck {staged_files}
    
    check-secrets:
      run: config/scripts/check-secrets.sh {staged_files}
    
    validate-toml:
      glob: "*.toml"
      run: python3 -c "import tomllib; [tomllib.load(open(f,'rb')) for f in '{staged_files}'.split()]"

  # AI Agent Enforcement (custom)
  scripts:
    "agent-skill-check":
      runner: bash
      
pre-push:
  commands:
    tests:
      run: bats tests/
      
# Remote hooks for shared team config
remotes:
  - git_url: https://github.com/company/shared-hooks
    ref: main
    configs:
      - lefthook-ai-agents.yml
```

#### Remote Config Details

```yaml
remotes:
  - git_url: https://github.com/company/lefthook-configs
    ref: v1.0.0
    configs:
      - lefthook-backend.yml
      - lefthook-frontend.yml
    refetch_frequency: 24h
```

**Priority**: local `lefthook.yml` overrides remote configs, with optional `lefthook-local.yml` for developer overrides.

#### Why Lefthook Over Alternatives

| Tool | Pros | Cons |
|------|------|------|
| **Lefthook** | Fast (Go), parallel, remote configs, TOML support | Smaller ecosystem |
| **Husky** | Popular, npm ecosystem | Node.js required, slower |
| **pre-commit** | Huge plugin ecosystem | Python required, slower startup |
| **Overcommit** | Ruby ecosystem | Ruby required, less active |

**Recommendation**: Lefthook for this project because:
- Already using TOML (mise.toml)
- Fast startup matters for developer experience
- Remote hooks enable shared AI agent configs
- No runtime dependencies (single binary)

### 1.2 Installation

```bash
# Via mise (recommended for this project)
mise use -g lefthook

# Initialize in project
lefthook install
```

---

## 2. Current Project Infrastructure

### 2.1 Existing Hooks

| File | Purpose | Checks |
|------|---------|--------|
| `.git/hooks/pre-commit` | Active hook | 6 blocking checks |
| `config/scripts/pre-commit-hook.sh` | Source (221 lines) | Secrets, TOML, shellcheck, TS, Rust, anti-patterns |
| `.mise.toml` | Mise tasks | `hooks:install`, `hooks:test`, `skills:validate*` |

#### Current Pre-Commit Checks (All BLOCKING)

1. **Secrets detection** - passwords, API keys, tokens
2. **TOML syntax** - validate with Python tomllib
3. **Shellcheck** - lint shell scripts
4. **TypeScript** - type errors via `bunx tsc`
5. **Rust** - `cargo check` for .rs files
6. **Anti-patterns** - sudo, npm -g, pip install, @ts-ignore, as any

### 2.2 Skills Architecture

```
.agents/skills/           ← Canonical source (29 skills)
  ├── mise-expert/
  │   └── SKILL.md
  ├── bats-testing/
  │   └── SKILL.md
  ├── shell-scripting/
  │   └── SKILL.md
  └── ...
  
.claude/skills/          ← Symlinks to .agents/skills/
.Claude/skills/          ← Symlinks to .agents/skills/
.opencode/skills/        ← Symlinks to .agents/skills/
.cursor/skills/          ← Symlinks to .agents/skills/
.gemini/skills/          ← Symlinks to .agents/skills/
.windsurf/skills/        ← Symlinks to .agents/skills/
.augment/skills/         ← Symlinks to .agents/skills/
.agent/skills/           ← Symlinks to .agents/skills/
.kiro/skills/            ← Symlinks to .agents/skills/
```

#### Skill Discovery (Current)

Skills are loaded via `delegate_task(load_skills=["name"])` which injects SKILL.md content into subagent prompts. Currently **no enforcement** that agents check skills before acting.

#### Skill Validation & Tests

- `config/scripts/validate-skills.sh` (467 lines) validates canonical source, SKILL.md frontmatter, symlink health, duplicates, and inventory.
- `tests/test_skills.bats` (54 tests) validates symlink parity and SKILL.md format.
- `tests/test_noninteractive_skills.bats` (25 tests) enforces non-interactive skill patterns (no questions, assumption logging, read-only).

#### Skill File Format (SKILL.md)

```yaml
---
name: skill-name
description: "30+ char trigger description"
metadata:
  mode: "non-interactive"
---
```

### 2.3 Telemetry Infrastructure

| File | Purpose |
|------|---------|
| `config/scripts/telemetry.sh` | Bash helper for event emission |
| `~/.config/dev-env/telemetry/events.jsonl` | Local event storage |
| Event schema | id, timestamp, source, category, name, status, duration_ms, payload |

**Gap**: No token usage tracking currently.

### 2.4 OpenCode/oh-my-opencode Touchpoints

- `.opencode/oh-my-opencode.json` maps agent categories and providers.
- `.claude/settings.json` uses hook-style checks for readiness and context injection.

---

## 3. AI Agent Orchestration Patterns

### 3.1 Hook Types Across Frameworks

| Framework | Pre-Execution | Post-Execution | Blocking | Multi-Provider |
|-----------|---------------|----------------|----------|----------------|
| **LangChain** | `on_llm_start` | `on_llm_end` | Yes | Via callbacks |
| **CrewAI** | `@before_llm_call` | `@after_llm_call` | Yes (return False) | Yes |
| **Claude Code** | `PreToolUse` | `PostToolUse` | Exit code 2 | N/A |
| **oh-my-opencode** | Hook system | Hook system | Yes | Yes (native) |

### 3.2 CrewAI Hook Pattern (Best for Reference)

```python
from crewai.hooks import before_llm_call, after_llm_call

@before_llm_call
def enforce_skill_discovery(context: LLMCallHookContext) -> bool | None:
    """Require skill check before any LLM work."""
    skills_loaded = context.agent.get_metadata("skills_loaded", False)
    
    if not skills_loaded:
        # Inject skill discovery prompt
        context.messages.insert(0, {
            "role": "system",
            "content": "BEFORE PROCEEDING: Check available skills in .agents/skills/"
        })
        context.agent.set_metadata("skills_loaded", True)
    
    return None  # Continue execution

@after_llm_call
def track_token_usage(context: LLMCallHookContext) -> None:
    """Track tokens per provider."""
    usage = context.response.usage
    emit_telemetry("llm.tokens", "completed", {
        "provider": context.llm.provider,
        "model": context.llm.model,
        "input_tokens": usage.input_tokens,
        "output_tokens": usage.output_tokens,
        "cost_usd": calculate_cost(usage)
    })
    return None
```

### 3.3 oh-my-opencode Hook System

oh-my-opencode provides hooks compatible with Claude Code:

```json
// .opencode/oh-my-opencode.json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|Write|Edit",
        "hooks": [{
          "type": "command",
          "command": "scripts/check-skill-loaded.sh"
        }]
      }
    ],
    "PostToolUse": [
      {
        "hooks": [{
          "type": "command",
          "command": "scripts/track-usage.sh"
        }]
      }
    ],
    "Stop": [
      {
        "hooks": [{
          "type": "command",
          "command": "scripts/update-learnings.sh"
        }]
      }
    ]
  }
}
```

---

## 4. Token Usage Tracking

### 4.1 Multi-Provider Token Tracking

Top tools for LLM monitoring (2026):

| Tool | Self-Hosted | Multi-Provider | Cost Tracking | Open Source |
|------|-------------|----------------|---------------|-------------|
| **LangWatch** | Yes | Yes | Yes | Yes |
| **Langfuse** | Yes | Yes | Yes | Yes |
| **Braintrust** | No | Yes | Yes | No |
| **Helicone** | No | Yes | Yes | No |
| **Portkey** | No | Yes | Yes | No |

### 4.2 OpenTelemetry Pattern (Recommended)

```typescript
// Universal token tracking via OpenTelemetry
import { trace, metrics } from '@opentelemetry/api';

const tokenCounter = metrics.getMeter('ai-agent').createCounter('llm.tokens', {
  description: 'LLM token usage',
  unit: 'tokens'
});

function trackLLMCall(provider: string, model: string, usage: TokenUsage) {
  tokenCounter.add(usage.input_tokens, {
    provider,
    model,
    direction: 'input'
  });
  
  tokenCounter.add(usage.output_tokens, {
    provider,
    model,
    direction: 'output'
  });
  
  // Also emit to local telemetry
  emitTelemetry('llm.tokens', 'completed', {
    provider,
    model,
    input_tokens: usage.input_tokens,
    output_tokens: usage.output_tokens,
    cost_usd: PRICING[provider][model] * (usage.input_tokens + usage.output_tokens)
  });
}
```

### 4.3 LiteLLM Pattern (Multi-Provider Abstraction)

```python
# LiteLLM already normalizes token usage across providers
import litellm
from litellm import completion

litellm.success_callback = ["langfuse"]  # Auto-track to Langfuse

# Works with any provider
response = completion(
    model="anthropic/claude-sonnet-4",  # or "openai/gpt-4" or "gemini/gemini-pro"
    messages=[{"role": "user", "content": "Hello"}]
)

# Access normalized usage
print(response.usage.prompt_tokens)
print(response.usage.completion_tokens)
print(response.usage.total_tokens)
```

---

## 5. Self-Learning Patterns

### 5.1 Reflexion Pattern

From the seminal paper [Reflexion: Language Agents with Verbal Reinforcement Learning](https://arxiv.org/abs/2303.11366):

```
┌─────────────────────────────────────────────────────────────┐
│                     REFLEXION LOOP                          │
├─────────────────────────────────────────────────────────────┤
│  1. Actor generates response                                │
│  2. Evaluator assesses response (success/failure)           │
│  3. Self-Reflection generates verbal feedback               │
│  4. Memory stores reflection for future use                 │
│  5. Next iteration incorporates past reflections            │
└─────────────────────────────────────────────────────────────┘
```

#### Implementation Pattern

```python
class ReflexionAgent:
    def __init__(self):
        self.memory = []  # Episodic memory of reflections
        
    def run(self, task: str, max_iterations: int = 3) -> str:
        for i in range(max_iterations):
            # 1. Generate with past reflections
            context = self._build_context(task)
            response = self.generate(context)
            
            # 2. Evaluate
            success, feedback = self.evaluate(response, task)
            
            if success:
                return response
            
            # 3. Self-reflect on failure
            reflection = self.reflect(task, response, feedback)
            
            # 4. Store in memory
            self.memory.append({
                "iteration": i,
                "task": task,
                "response": response,
                "feedback": feedback,
                "reflection": reflection
            })
        
        return response  # Best effort
    
    def reflect(self, task: str, response: str, feedback: str) -> str:
        prompt = f"""
        Task: {task}
        My Response: {response}
        Feedback: {feedback}
        
        Reflect on why this failed and what to do differently:
        """
        return self.generate(prompt)
```

### 5.2 Learnings Persistence

```yaml
# ~/.config/dev-env/learnings/learnings.yaml
schema_version: 1
learnings:
  - id: learn_001
    date: 2026-02-07
    category: tool_use
    trigger: "Used grep instead of rg"
    learning: "Always prefer rg (ripgrep) over grep for speed"
    confidence: 0.95
    
  - id: learn_002
    date: 2026-02-07
    category: skill_discovery
    trigger: "Didn't load bats-testing skill before writing tests"
    learning: "Check .agents/skills/ before any testing task"
    confidence: 0.9
    
  - id: learn_003
    date: 2026-02-07
    category: pattern_matching
    trigger: "Created new pattern instead of following existing"
    learning: "Search codebase for existing patterns before creating new ones"
    confidence: 0.85
```

### 5.3 Self-Healing Triggers

| Failure Pattern | Detection | Self-Heal Action |
|-----------------|-----------|------------------|
| Same error 2+ times | Error message hash match | Load relevant skill, change approach |
| Tool blocked by hook | PreToolUse returns False | Read hook feedback, adjust |
| Test failure loop | 3+ consecutive failures | Consult Oracle agent |
| Token budget exceeded | Usage > threshold | Switch to cheaper model |
| Missing context | Repeated "I don't have access" | Fire explore agents |

---

## 6. Documentation Auto-Update

### 6.1 AGENTS.md Auto-Update Patterns

```bash
#!/bin/bash
# scripts/update-agents-md.sh
# Called by Stop hook after significant sessions

# Extract learnings from session
LEARNINGS=$(jq -r '.learnings[]' ~/.config/dev-env/learnings/session-learnings.json)

# Update AGENTS.md sections
if [[ -n "$LEARNINGS" ]]; then
    # Append to learnings section
    echo "### Recent Learnings" >> AGENTS.md
    echo "$LEARNINGS" | while read -r learning; do
        echo "- $learning" >> AGENTS.md
    done
fi

# Update skill inventory
SKILL_COUNT=$(find .agents/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
sed -i '' "s/Skills (.*)/Skills ($SKILL_COUNT total)/" AGENTS.md
```

### 6.2 Automated Documentation Generation

```typescript
// Post-task hook for documentation updates
async function updateDocumentation(session: Session) {
  const changes = session.getFileChanges();
  const newPatterns = session.extractPatterns();
  
  // Update relevant docs
  for (const pattern of newPatterns) {
    if (pattern.type === 'new_skill') {
      await updateSkillInventory(pattern);
    }
    if (pattern.type === 'new_task') {
      await updateTaskList(pattern);
    }
    if (pattern.type === 'learning') {
      await appendLearning(pattern);
    }
  }
  
  // Regenerate AGENTS.md if significant changes
  if (changes.hasSignificantChanges()) {
    await regenerateAgentsMd();
  }
}
```

---

## 7. Multi-Provider Considerations

### 7.1 OpenCode/oh-my-opencode Multi-Provider Architecture

oh-my-opencode supports multiple providers natively:

| Agent | Default Model | Use Case |
|-------|---------------|----------|
| Sisyphus (main) | Claude Opus 4.5 | Orchestration |
| Hephaestus | GPT 5.2 Codex | Deep autonomous work |
| Oracle | GPT 5.2 | Architecture, debugging |
| Frontend | Gemini 3 Pro | UI/UX work |
| Librarian | Claude Sonnet 4.5 | Docs, code search |
| Explore | Claude Haiku 4.5 | Fast codebase grep |

### 7.2 Provider-Agnostic Tracking Schema

```typescript
interface AgentUsageEvent {
  // Core fields
  event_id: string;
  timestamp: string;
  session_id: string;
  
  // Provider info
  provider: 'anthropic' | 'openai' | 'google' | 'other';
  model: string;
  
  // Usage metrics
  input_tokens: number;
  output_tokens: number;
  cost_usd: number;
  latency_ms: number;
  
  // Agent context
  agent_name: string;
  task_description: string;
  skills_loaded: string[];
  tools_used: string[];
  
  // Outcome
  success: boolean;
  error?: string;
}
```

### 7.3 Cost Calculation

```typescript
const PRICING = {
  anthropic: {
    'claude-opus-4.5': { input: 0.015, output: 0.075 },
    'claude-sonnet-4.5': { input: 0.003, output: 0.015 },
    'claude-haiku-4.5': { input: 0.0005, output: 0.0025 }
  },
  openai: {
    'gpt-5.2': { input: 0.01, output: 0.03 },
    'gpt-5.2-codex': { input: 0.012, output: 0.036 }
  },
  google: {
    'gemini-3-pro': { input: 0.00125, output: 0.005 }
  }
};

function calculateCost(provider: string, model: string, usage: TokenUsage): number {
  const rates = PRICING[provider]?.[model];
  if (!rates) return 0;
  return (usage.input_tokens * rates.input + usage.output_tokens * rates.output) / 1000;
}
```

### 7.4 OpenCode/oh-my-opencode Extension Points

OpenCode uses a multi-provider config with `providerID/modelID`. oh-my-opencode adds a hook system (40+ hooks), background task management, category-based model routing, and per-agent tool restrictions. Key enforcement hooks include:

- `todo-continuation-enforcer`
- `comment-checker`
- `write-existing-file-guard`
- `context-window-monitor` and `preemptive-compaction`

Skill discovery in oh-my-opencode merges project, user, config, and builtin skills (priority: project > user > config > builtin). No direct token counting is implemented; it relies on context size heuristics.

### 7.5 Playwright Agent Automation Stack

- **CLI**: `@playwright/cli` (token-efficient, built for coding agents)
- **MCP**: `@playwright/mcp` (official server for Claude/VS Code/Cursor/opencode)

Use CLI for concise command workflows. Use MCP when you need persistent state and deep page introspection.

### 7.6 Vercel Labs Skills & Tools

Relevant assets for agent enforcement and automation:

- `vercel-labs/agent-skills` (skills like `react-best-practices`, `web-design-guidelines`)
- `vercel-labs/skills` (skills CLI)
- `agent-browser` (fast browser automation)
- `opensrc` (fetch dependency sources)
- `specli` (OpenAPI → CLI)
- `dev3000` (debugging timeline for AI)

---

## 8. Implementation Proposal

### 8.1 Phase 1: Lefthook Integration

```yaml
# lefthook.yml (new file)
min_version: 1.6.0

pre-commit:
  parallel: true
  commands:
    existing-checks:
      run: config/scripts/pre-commit-hook.sh

# Agent-specific hooks (new)
ai-agent-start:
  scripts:
    "enforce-skill-check":
      runner: bash
      
ai-agent-stop:
  scripts:
    "persist-learnings":
      runner: bash
    "update-docs":
      runner: bash
```

### 8.2 Phase 2: Skill Discovery Enforcement

```bash
#!/bin/bash
# config/scripts/enforce-skill-check.sh
# Called before any agent work starts

SKILLS_DIR="${PROJECT_ROOT}/.agents/skills"
TASK_TYPE="$1"

# Find matching skills for task type
RELEVANT_SKILLS=$(find "$SKILLS_DIR" -name "SKILL.md" -exec grep -l "$TASK_TYPE" {} \;)

if [[ -n "$RELEVANT_SKILLS" ]]; then
    echo "🔍 Found relevant skills for $TASK_TYPE:"
    echo "$RELEVANT_SKILLS" | while read -r skill; do
        SKILL_NAME=$(dirname "$skill" | xargs basename)
        echo "  - $SKILL_NAME"
    done
    echo ""
    echo "💡 Consider loading: load_skills=[$(echo "$RELEVANT_SKILLS" | xargs -I{} basename $(dirname {}) | paste -sd, -)]"
fi
```

### 8.3 Phase 3: Token Tracking

```bash
#!/bin/bash
# config/scripts/track-agent-usage.sh
# Called after each LLM call

USAGE_FILE="${HOME}/.config/dev-env/telemetry/agent-usage.jsonl"

# Append usage event
cat >> "$USAGE_FILE" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "provider": "$PROVIDER",
  "model": "$MODEL",
  "input_tokens": $INPUT_TOKENS,
  "output_tokens": $OUTPUT_TOKENS,
  "cost_usd": $COST,
  "agent": "$AGENT_NAME",
  "task": "$TASK_DESCRIPTION",
  "skills_loaded": $SKILLS_JSON
}
EOF
```

### 8.4 Phase 4: Self-Learning Loop

```bash
#!/bin/bash
# config/scripts/persist-learnings.sh
# Called at session end

LEARNINGS_FILE="${HOME}/.config/dev-env/learnings/learnings.yaml"
SESSION_LEARNINGS="$1"

if [[ -n "$SESSION_LEARNINGS" ]]; then
    # Parse and append learnings
    echo "$SESSION_LEARNINGS" | yq -y '. as $learning | 
      {
        id: "learn_\(now | strftime("%Y%m%d%H%M%S"))",
        date: (now | strftime("%Y-%m-%d")),
        category: .category,
        trigger: .trigger,
        learning: .learning,
        confidence: .confidence
      }' >> "$LEARNINGS_FILE"
    
    echo "📚 Persisted $(echo "$SESSION_LEARNINGS" | jq length) learnings"
fi
```

### 8.5 Phase 5: oh-my-opencode Integration

```json
// .opencode/oh-my-opencode.json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [{
          "type": "command",
          "command": "config/scripts/load-learnings.sh"
        }]
      }
    ],
    "PreToolUse": [
      {
        "matcher": ".*",
        "hooks": [{
          "type": "command",
          "command": "config/scripts/check-skill-loaded.sh"
        }]
      }
    ],
    "PostToolUse": [
      {
        "hooks": [{
          "type": "command",
          "command": "config/scripts/track-agent-usage.sh"
        }]
      }
    ],
    "Stop": [
      {
        "hooks": [{
          "type": "command",
          "command": "config/scripts/persist-learnings.sh"
        }, {
          "type": "command",
          "command": "config/scripts/update-agents-md.sh"
        }]
      }
    ]
  },
  "disabled_hooks": []
}
```

---

## 9. Summary

### Key Recommendations

1. **Adopt Lefthook** for git hooks management - faster, supports TOML, remote configs
2. **Implement skill enforcement** via PreToolUse hooks
3. **Track tokens** via OpenTelemetry + local JSONL for offline analysis
4. **Persist learnings** in YAML format for human readability
5. **Auto-update AGENTS.md** at session end with skill inventory and learnings
6. **Use oh-my-opencode hooks** for multi-provider orchestration

### Files to Create

| File | Purpose |
|------|---------|
| `lefthook.yml` | Git hooks configuration |
| `config/scripts/enforce-skill-check.sh` | Skill discovery enforcement |
| `config/scripts/track-agent-usage.sh` | Token tracking |
| `config/scripts/persist-learnings.sh` | Self-learning persistence |
| `config/scripts/load-learnings.sh` | Load learnings at session start |
| `config/scripts/update-agents-md.sh` | Auto-update documentation |
| `.opencode/oh-my-opencode.json` | oh-my-opencode hook config |

### Expected Outcomes

- **Skill discovery**: Agents always check skills before starting work
- **Token visibility**: Full usage tracking across Anthropic, OpenAI, Gemini
- **Self-improvement**: Learnings persist and inform future sessions
- **Living documentation**: AGENTS.md stays current automatically
- **Provider agnostic**: Same patterns work across all LLM providers

---

## References

- [Lefthook Documentation](https://lefthook.dev/)
- [evilmartians/lefthook](https://github.com/evilmartians/lefthook)
- [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)
- [Reflexion Paper](https://arxiv.org/abs/2303.11366)
- [CrewAI Execution Hooks](https://docs.crewai.com/en/learn/execution-hooks)
- [LangWatch](https://langwatch.ai/)
- [Langfuse](https://langfuse.com/)
- [LiteLLM](https://docs.litellm.ai/)
