---
name: tdd
description: Non-interactive TDD workflow. Red-green-refactor cycle without prompts.
license: MIT
compatibility: Auto-detects test framework
metadata:
  author: gemini-ai-macos-dev
  version: "1.0"
  mode: non-interactive
---

# /tdd - Non-Interactive Test-Driven Development

**MODE: CONTINUOUS STREAM - NO PROMPTS, NO QUESTIONS, NO PAUSES**

This skill executes the TDD red-green-refactor cycle without asking questions. It auto-detects the test framework and proceeds autonomously.

## Usage

```
/tdd <target> [--mode=create|fix|extend] [--max-iterations=N]
```

## Argument Parsing (MANDATORY FIRST STEP)

**IMMEDIATELY parse arguments. NEVER ask for clarification.**

```
IF no target provided:
  OUTPUT: "ERROR: Missing TDD target

  Usage: /tdd <target> [--mode=create] [--max-iterations=3]

  Examples:
    /tdd validateConfig
    /tdd src/auth.ts --mode=extend
    /tdd "user registration" --max-iterations=5"

  STOP EXECUTION (do not proceed, do not ask)
```

## Default Values (Log, NEVER Ask)

| Option | Default | Log Message |
|--------|---------|-------------|
| --mode | create | "ASSUMPTION: Mode=create" |
| --max-iterations | 3 | "ASSUMPTION: Max iterations=3" |
| test framework | auto-detect | "DETECTED: Using [framework]" |

---

## Framework Auto-Detection (NEVER Ask)

```
Check in order:
1. package.json scripts.test → extract framework
2. jest.config.* → Jest
3. vitest.config.* → Vitest
4. bun test in package.json → Bun
5. pytest.ini or pyproject.toml [tool.pytest] → Pytest
6. go.mod exists → Go test

If none found:
  "ASSUMPTION: Using bats (shell project detected)"
  OR "ERROR: No test framework detected, cannot proceed"
```

---

## Execution Protocol (Continuous Stream)

### Phase 1: Setup

```
=== TDD: [target] ===

ASSUMPTION: Mode=create
ASSUMPTION: Max iterations=3
DETECTED: Using [framework]

--- TEST FILE ---
Creating: [test-file-path]
```

### Phase 2: RED (Write Failing Test)

```
--- ITERATION 1: RED ---
Writing failing test for: [target]

[Test code]

Running: [test command]
Expected: FAIL
Result: FAIL (as expected)
```

### Phase 3: GREEN (Implement Minimum)

```
--- ITERATION 1: GREEN ---
Implementing minimum code to pass...

[Implementation code]

Running: [test command]
Expected: PASS
Result: [PASS/FAIL]
```

### Phase 4: REFACTOR (If Green)

```
--- ITERATION 1: REFACTOR ---
Cleaning up implementation...

[Refactored code]

Running: [test command]
Result: PASS (still green)
```

### Phase 5: Repeat or Complete

```
IF tests pass AND iteration < max_iterations:
  Continue to next iteration
ELSE IF tests pass:
  === TDD COMPLETE: SUCCESS ===
ELSE IF iteration >= max_iterations:
  === TDD COMPLETE: MAX ITERATIONS REACHED ===
  Tests still failing, manual intervention needed
```

---

## FORBIDDEN (Non-Interactive Enforcement)

| Pattern | Forbidden | Required Instead |
|---------|-----------|------------------|
| "What test framework?" | YES | Auto-detect |
| "What should the test check?" | YES | Infer from target |
| "Is this implementation correct?" | YES | Run tests to verify |
| "Should I continue iterating?" | YES | Check max-iterations |
| AskUserQuestion | YES | Use defaults |

---

## Test Framework Commands

| Framework | Test Command |
|-----------|--------------|
| Jest | `npm test` or `jest [file]` |
| Vitest | `npm test` or `vitest [file]` |
| Bun | `bun test [file]` |
| BATS | `bats [file]` |
| Pytest | `pytest [file]` |
| Go | `go test ./...` |
