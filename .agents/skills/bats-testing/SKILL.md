---
name: bats-testing
description: "BATS (Bash Automated Testing System) test patterns for this project's 948-test suite. Use when writing new BATS tests, debugging test failures, adding test coverage, or running the test suite. Triggers on: writing tests, test failures, bats, test_*.bats files, @test blocks, test assertions, test fixtures, or test coverage discussions."
---

# BATS Testing

This project uses BATS for all testing. 948 tests across 16 test files.

## Test Locations

| File | Tests | Purpose |
|------|-------|---------|
| `tests/test_mise.bats` | Core | Mise install, backends, tasks |
| `tests/test_tools.bats` | Core | CLI tool availability |
| `tests/test_chezmoi.bats` | Core | Dotfile templates |
| `tests/test_starship.bats` | Core | Prompt config |
| `tests/test_integration.bats` | Core | E2E structure |
| `tests/test_ide_configs.bats` | Core | VS Code, Zed |
| `tests/test_menubar_core.bats` | Menu | Core parity (68) |
| `DevEnvManager-SwiftBar/tests/` | Menu | SwiftBar (272) |
| `DevEnvManager/Tests/` | Menu | Swift validation (91) |
| `DevEnvManager-Iced/tests/` | Menu | Iced Rust (48) |
| `DevEnvManager-Tauri/src-tauri/tests/` | Menu | Tauri Rust (42) |

## Running Tests

```bash
eval "$(mise activate bash --shims)"   # Required for mise tools in PATH
bats tests/                            # All core tests
bats tests/test_mise.bats              # Specific file
bats tests/test_mise.bats --filter "bun"  # Filter by name
```

## Test Structure Pattern

```bash
#!/usr/bin/env bats

# Setup runs before each test
setup() {
  if ! command -v mise &> /dev/null; then
    skip "mise not installed"
  fi
}

@test "descriptive test name" {
  run command_to_test
  [ "$status" -eq 0 ]
  [[ "$output" =~ expected_pattern ]]
}
```

## Assertion Patterns

```bash
# Exit status
[ "$status" -eq 0 ]                    # Success
[ "$status" -ne 0 ]                    # Failure expected

# Output matching
[[ "$output" =~ "substring" ]]         # Contains
[[ "$output" == "exact" ]]             # Exact match
[[ ! "$output" =~ "error" ]]           # Does not contain

# File checks
[ -f "$filepath" ]                     # File exists
[ -d "$dirpath" ]                      # Dir exists
[ -x "$filepath" ]                     # Is executable
[ -s "$filepath" ]                     # Not empty

# String checks
[ -n "$var" ]                          # Not empty string
[ -z "$var" ]                          # Empty string
```

## Conventions

- File naming: `test_<module>.bats`
- Test naming: Descriptive, starts with subject (`"mise has bun installed"`)
- Use `setup()` for prerequisites and skip conditions
- Use `skip "reason"` for optional/conditional tests
- Test one thing per `@test` block
- Use `run` to capture output and status

## Writing New Tests

1. Add to existing test file if module exists, else create `tests/test_<module>.bats`
2. Include shebang: `#!/usr/bin/env bats`
3. Add `setup()` with skip conditions for CI
4. Write `@test` blocks following existing naming conventions
5. Run `bats tests/test_<file>.bats` to verify
6. Run full suite `bats tests/` before committing

## Debugging Failed Tests

```bash
bats tests/test_mise.bats --trace      # Show commands executed
bats tests/test_mise.bats -t           # Timing info
```
