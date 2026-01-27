---
name: refactor
description: Non-interactive intelligent refactoring. No Intent Gate, no questions, continuous execution.
license: MIT
compatibility: Works with any codebase
metadata:
  author: gemini-ai-macos-dev
  version: "1.0"
  mode: non-interactive
---

# /refactor - Non-Interactive Refactoring

**MODE: CONTINUOUS STREAM - NO PROMPTS, NO QUESTIONS, NO PAUSES**

This skill performs intelligent refactoring without the interactive "Intent Gate" of the builtin. It parses arguments, applies defaults, and executes continuously.

## Usage

```
/refactor <target> [--scope=file|module|project] [--strategy=safe|aggressive] [--on-failure=abort|rollback]
```

## Argument Parsing (MANDATORY FIRST STEP)

**IMMEDIATELY parse arguments. NEVER ask for clarification.**

```
IF no target provided:
  OUTPUT: "ERROR: Missing refactoring target

  Usage: /refactor <target> [--scope=file] [--strategy=safe]

  Examples:
    /refactor src/auth.ts
    /refactor AuthService --scope=module
    /refactor "rename getUserById to findUserById"

  STOP EXECUTION (do not proceed, do not ask)
```

## Default Values (Log, NEVER Ask)

| Option | Default | Log Message |
|--------|---------|-------------|
| --scope | file | "ASSUMPTION: Scope=file" |
| --strategy | safe | "ASSUMPTION: Strategy=safe" |
| --on-failure | abort | "ASSUMPTION: On failure=abort" |
| ambiguous target | first match | "ASSUMPTION: Refactoring [first-match]" |

---

## Execution Protocol (Continuous Stream)

**NOTE: This removes the interactive "Intent Gate" from the builtin.**

### Phase 1: Target Resolution

```
1. Parse target from arguments
2. Resolve to file(s) or symbol(s)
3. If ambiguous: pick first match, log assumption
4. If not found: ERROR and STOP
5. NEVER ask "What did you mean by [target]?"
```

### Phase 2: Codebase Analysis (Parallel)

```typescript
delegate_task(subagent_type="explore", prompt="Find all usages of [target]", run_in_background=true)
delegate_task(subagent_type="explore", prompt="Find tests for [target]", run_in_background=true)
```

Use LSP tools:
- `lsp_find_references` for usage mapping
- `lsp_goto_definition` for understanding
- `lsp_diagnostics` for baseline errors

### Phase 3: Safety Assessment

```
=== REFACTOR: [target] ===

ASSUMPTION: Scope=file
ASSUMPTION: Strategy=safe

--- PRE-REFACTOR STATE ---
Files affected: [count]
Test coverage: [percentage or "unknown"]
Baseline errors: [count]

--- REFACTORING PLAN ---
1. [Step 1]
2. [Step 2]
3. [Step 3]

Proceeding with refactoring...
```

### Phase 4: Execute Refactoring

For each step:
```
--- STEP 1: [description] ---
[Execute using lsp_rename or ast_grep_replace]
[Run tests]
[Report result]
```

### Phase 5: Verification

```
--- VERIFICATION ---
Tests: [PASS/FAIL]
Lint: [PASS/FAIL]
Type check: [PASS/FAIL]

--- RESULT ---
[SUCCESS or ABORTED with reason]

=== REFACTOR COMPLETE ===
```

---

## Failure Handling (Non-Interactive)

**NEVER ask "Tests failed, should I continue?"**

| Situation | Action |
|-----------|--------|
| Tests fail | Log failure, ABORT (or rollback if --on-failure=rollback) |
| Type errors | Log errors, ABORT |
| Lint failures | Log warnings, CONTINUE (safe) or ABORT (aggressive) |
| File not found | ERROR and STOP |

---

## FORBIDDEN (Non-Interactive Enforcement)

| Pattern | Forbidden | Required Instead |
|---------|-----------|------------------|
| Intent Gate | YES | Direct execution |
| "What's your intent?" | YES | Infer from args |
| "Options I see..." | YES | Pick default, log |
| "Should I proceed?" | YES | Always proceed |
| AskUserQuestion | YES | Log ASSUMPTION |
| "What I'm unsure about" | YES | Make assumption |

---

## Tool Usage

| Tool | Purpose |
|------|---------|
| lsp_rename | Symbol renames across codebase |
| ast_grep_replace | Pattern-based transformations |
| lsp_find_references | Impact analysis |
| lsp_diagnostics | Verify no new errors |
