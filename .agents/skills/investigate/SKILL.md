---
name: investigate
description: "Non-interactive issue investigation command. Outputs as continuous stream without prompts or questions. Capabilities: root cause analysis, error tracing, bug hunting, evidence gathering, git history analysis. Actions: investigate, trace, debug, hunt, find root cause. Keywords: investigate, root cause, error, bug, trace, debug, issue, problem, evidence, git history, non-interactive, continuous stream. Use when: investigating bugs, tracing errors, finding root causes, debugging issues, analyzing problems. CRITICAL: This is a NON-INTERACTIVE command - never ask questions, always use defaults and log assumptions."
license: MIT
compatibility: Works with any codebase
metadata:
  author: gemini-ai-macos-dev
  version: "1.0"
  mode: non-interactive
---

# /investigate - Non-Interactive Issue Investigation

**MODE: CONTINUOUS STREAM - NO PROMPTS, NO QUESTIONS, NO PAUSES**

This skill investigates issues, errors, and problems in the codebase. It NEVER asks questions - it parses arguments, applies defaults, and outputs continuously.

## Usage

```
/investigate <issue|error|pattern> [--scope=file|module|project] [--max-depth=N]
```

## Argument Parsing (MANDATORY FIRST STEP)

**IMMEDIATELY parse arguments. NEVER ask for clarification.**

```
IF no issue provided:
  OUTPUT: "ERROR: Missing issue to investigate

  Usage: /investigate <issue> [--scope=module] [--max-depth=3]

  Examples:
    /investigate "login fails"
    /investigate TypeError --scope=project
    /investigate "memory leak" --max-depth=5"

  STOP EXECUTION (do not proceed, do not ask)
```

## Default Values (Log, NEVER Ask)

| Option | Default | Log Message |
|--------|---------|-------------|
| --scope | module | "ASSUMPTION: Scope=module" |
| --max-depth | 3 | "ASSUMPTION: Max depth=3" |
| vague issue | interpret literally | "ASSUMPTION: Searching for '[issue]'" |

---

## Execution Protocol (Continuous Stream)

### Phase 1: Issue Parsing

```
1. Extract issue description from arguments
2. Determine if it's an error message, pattern, or description
3. NEVER ask "can you be more specific?"
4. ASSUMPTION: Interpret the issue as provided
```

### Phase 2: Evidence Gathering (Parallel)

```typescript
// Fire all searches simultaneously
delegate_task(subagent_type="explore", prompt="Search for [issue] in codebase", run_in_background=true)
delegate_task(subagent_type="explore", prompt="Find related error handling", run_in_background=true)
delegate_task(subagent_type="explore", prompt="Check git history for [issue]", run_in_background=true)
```

Use direct tools:
- `grep` for pattern search
- `git log -S` for history search
- `lsp_diagnostics` for related errors

### Phase 3: Continuous Output

```
=== INVESTIGATION: [issue] ===

ASSUMPTION: Scope=module
ASSUMPTION: Max depth=3

--- HYPOTHESIS ---
[Root cause theory based on evidence]

--- EVIDENCE ---
Location 1: [file:line]
  [relevant code snippet]
  [why this is related]

Location 2: [file:line]
  [relevant code snippet]
  [why this is related]

--- TIMELINE ---
[Git history showing when issue may have been introduced]

--- ROOT CAUSE ---
[Most likely cause based on evidence]

--- RECOMMENDATIONS ---
1. [Specific fix suggestion]
2. [Alternative approach]
3. [Prevention measure]

=== INVESTIGATION COMPLETE ===
```

---

## FORBIDDEN (Non-Interactive Enforcement)

| Pattern | Forbidden | Required Instead |
|---------|-----------|------------------|
| "Can you describe the issue?" | YES | Use provided description |
| "Would you like more details?" | YES | Output all findings |
| AskUserQuestion tool | YES | Log ASSUMPTION |
| Implementing fixes | YES | Only recommend |
| Modifying files | YES | Read-only investigation |

---

## Read-Only Enforcement

This command MUST NOT:
- Write to any files
- Implement fixes
- Modify code to "test theories"
- Create test files

This command MAY ONLY:
- Read files
- Search codebase
- Query git history
- Output investigation report
