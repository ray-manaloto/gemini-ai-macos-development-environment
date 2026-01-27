---
name: analyze
description: Non-interactive deep code analysis. Outputs as continuous stream without prompts.
license: MIT
compatibility: Works with any codebase
metadata:
  author: gemini-ai-macos-dev
  version: "1.0"
  mode: non-interactive
---

# /analyze - Non-Interactive Code Analysis

**MODE: CONTINUOUS STREAM - NO PROMPTS, NO QUESTIONS, NO PAUSES**

This skill analyzes code structure, dependencies, patterns, and issues. It NEVER asks questions - it parses arguments, applies defaults, and outputs continuously.

## Usage

```
/analyze <target> [--depth=shallow|deep] [--output=terminal|file]
```

## Argument Parsing (MANDATORY FIRST STEP)

**IMMEDIATELY parse arguments. NEVER ask for clarification.**

```
IF no target provided:
  OUTPUT: "ERROR: Missing target

  Usage: /analyze <target> [--depth=shallow|deep] [--output=terminal|file]

  Examples:
    /analyze src/auth.ts
    /analyze src/services/ --depth=deep
    /analyze \"AuthService class\""

  STOP EXECUTION (do not proceed, do not ask)
```

## Default Values (Log, NEVER Ask)

| Option | Default | Log Message |
|--------|---------|-------------|
| --depth | shallow | "ASSUMPTION: Using depth=shallow" |
| --output | terminal | "ASSUMPTION: Output to terminal" |
| ambiguous target | first match | "ASSUMPTION: Analyzing [first-match]" |

---

## Execution Protocol (Continuous Stream)

### Phase 1: Target Resolution

```
1. Parse target from arguments
2. Search for target in codebase
3. If multiple matches: pick first, log "ASSUMPTION: Analyzing [path]"
4. If no matches: "ERROR: Target not found: [target]" and STOP
5. NEVER ask "which one did you mean?"
```

### Phase 2: Parallel Analysis

Launch ALL analysis simultaneously:

```typescript
// Fire in parallel - continuous execution
delegate_task(subagent_type="explore", prompt="Analyze structure of [target]", run_in_background=true)
delegate_task(subagent_type="explore", prompt="Find dependencies of [target]", run_in_background=true)
```

Use direct tools:
- `lsp_symbols` for structure
- `lsp_find_references` for usage
- `lsp_diagnostics` for issues

### Phase 3: Continuous Output

Output ALL results without pausing:

```
=== ANALYSIS: [target] ===

ASSUMPTION: Using depth=shallow
ASSUMPTION: Output to terminal

--- STRUCTURE ---
[classes, functions, exports]

--- DEPENDENCIES ---
[imports, external libs, internal refs]

--- PATTERNS ---
[design patterns detected]

--- ISSUES ---
[warnings, errors, code smells]

--- RECOMMENDATIONS ---
[suggested improvements]

=== ANALYSIS COMPLETE ===
```

---

## FORBIDDEN (Non-Interactive Enforcement)

| Pattern | Forbidden | Required Instead |
|---------|-----------|------------------|
| "What file?" | YES | Parse from args or ERROR |
| "Would you like to..." | YES | Just do it |
| "Should I continue?" | YES | Always continue |
| AskUserQuestion tool | YES | Log ASSUMPTION |
| Question tool | YES | Apply default |
| Waiting for input | YES | Proceed autonomously |
| Modifying files | YES | Read-only analysis |

---

## Read-Only Enforcement

This command MUST NOT:
- Write to any files
- Modify any code
- Create any new files
- Delete anything

This command MAY ONLY:
- Read files
- Search codebase
- Output analysis to terminal/file
