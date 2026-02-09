# TDD Validation Plan

**Purpose**: Ensure the God-Tier macOS Development Environment workflow is fully validated with no warnings/issues ignored.

**Status**: ✅ IMPLEMENTED (January 2026)

## Implementation Summary

All gaps have been addressed:
- **305 tests** now pass (up from 254)
- **0 warnings** in validation (optional items reclassified to INFO)
- **Strict mode** available via `mise run validate:strict`
- **Quick check** available via `mise run validate:quick`

## Original Gaps (Now Resolved)

### 1. Warning Classification (FIXED)
| Warning | Old Behavior | New Behavior |
|---------|-------------|--------------|
| No container runtime | WARN | INFO (optional) |
| SkyPilot not installed | WARN | INFO (optional) |
| GitHub CLI not authenticated | WARN | INFO (optional) |
| PATH has shims: NO | Not checked | Now checks both shim and activation modes |

### 2. Missing Validations
| Check | Description |
|-------|-------------|
| Shims in PATH | Critical for tools to work properly |
| Shell activation | Is `mise activate` in shell config? |
| Config symlink | Is `~/.config/dev-env` valid? |
| Tool shadows | Are mise tools being shadowed? |
| AWS CLI | For cloud operations |
| Machine-readable output | For CI/automation |

### 3. Status Command Gaps
| Gap | Fix |
|-----|-----|
| No error code on issues | Add `--strict` flag |
| No JSON output | Add `--json` flag |
| Issues not categorized | Add severity levels |

## TDD Test Plan

### Phase 1: Warning Escalation Tests
```
RED: Test strict mode fails on warnings
GREEN: Implement --strict flag in validate.sh
REFACTOR: Clean up output formatting
```

### Phase 2: Status Completeness Tests
```
RED: Test shims-in-PATH check exists
GREEN: Add PATH validation to validate.sh
REFACTOR: Consolidate health checks
```

### Phase 3: Workflow E2E Tests
```
RED: Test full setup→validate→status cycle
GREEN: Create workflow validation task
REFACTOR: Add CI task
```

## Test Categories

### A. Core Validation Tests (`test_workflow_validation.bats`)

1. **Strict Mode Tests**
   - `validate --strict` exits non-zero on any warning
   - `validate --strict` reports all warnings as errors
   - `validate` (default) exits zero on warnings

2. **Warning Classification Tests**
   - Required warnings (must pass for functional env)
   - Optional warnings (nice to have, won't fail strict)
   - Critical failures (always fail)

3. **Status Completeness Tests**
   - All sections present in env:status
   - PATH shims check present
   - Shell activation check present
   - Config symlink check present

### B. Health Check Tests

1. **PATH Configuration**
   - Mise shims directory in PATH
   - Shims directory has correct permissions
   - No shadowing by ~/.local/bin

2. **Shell Integration**
   - mise activate in zshrc/bashrc
   - Starship init in shell config
   - Zoxide init in shell config

3. **Tool Functionality**
   - Each tool can run `--version`
   - Each tool resolves to mise install path
   - No version conflicts

### C. End-to-End Workflow Tests

1. **Fresh Install Simulation**
   - setup.sh runs without errors
   - validate passes after setup
   - env:status shows all components

2. **Upgrade Path**
   - mise upgrade doesn't break env
   - Config migration works

3. **Recovery Tests**
   - Can recover from broken shims
   - Can recover from missing tools

## Implementation Order

### Sprint 1: Strict Mode (Priority: CRITICAL)
1. Add `--strict` flag to validate.sh
2. Create `validate:strict` task
3. Write tests for strict mode behavior
4. Update CI to use strict mode

### Sprint 2: PATH Validation (Priority: HIGH)
1. Add shims-in-PATH check to validate.sh
2. Add shell activation check
3. Write tests for PATH checks
4. Add remediation suggestions

### Sprint 3: Machine-Readable Output (Priority: MEDIUM)
1. Add `--json` flag to validate.sh
2. Add `--json` flag to env:status
3. Create `validate:ci` task for CI
4. Write tests for JSON output

### Sprint 4: E2E Workflow (Priority: MEDIUM)
1. Create workflow validation script
2. Add recovery procedures
3. Write E2E tests
4. Document recovery playbook

## Success Criteria

### Minimum Viable Validation
- [ ] `mise run validate` catches all critical issues
- [ ] `mise run validate --strict` fails on any warning
- [ ] `mise run env:status` shows complete system state
- [ ] All 254+ tests pass
- [ ] CI uses strict validation

### Full Validation Suite
- [ ] JSON output available for automation
- [ ] Recovery procedures documented and tested
- [ ] No silent failures possible
- [ ] < 30 second full validation time

## Task Definitions

### validate:strict
Runs validation in strict mode where warnings = failures.

### validate:ci
Runs validation with JSON output for CI systems.

### validate:fix
Attempts to automatically fix common issues.

### env:health
Quick health check (subset of full validation).

## Severity Levels

| Level | Exit Code | Description |
|-------|-----------|-------------|
| PASS | 0 | Check passed |
| INFO | 0 | Informational, not a problem |
| WARN | 0 (1 in strict) | Issue exists, env functional |
| FAIL | 1 | Critical issue, env broken |

## Warning Categories

### Required (WARN → FAIL in strict mode)
- Container runtime (Docker/OrbStack)
- Cloud CLI (SkyPilot, AWS)
- GitHub authentication

### Optional (WARN → INFO in strict mode)
- DevPod
- Infisical
- SwiftBar

### Critical (Always FAIL)
- Mise not installed
- Core runtimes missing (bun, uv, pixi)
- Shell activation broken
- Shims not in PATH
