# env:status Specification

## Overview

The `mise run env:status` command provides a comprehensive, non-interactive status overview of the development environment in a single continuous stream.

## Requirements

### R1: Non-Interactive Execution
- **R1.1**: Command MUST complete without user input
- **R1.2**: Command MUST complete within 15 seconds
- **R1.3**: First output MUST appear within 2 seconds
- **R1.4**: Command MUST exit with code 0 (success)
- **R1.5**: Network calls MUST have timeouts (3-5 seconds) to prevent blocking

### R2: Output Sections (8 required)

The command MUST output ALL of the following sections in order:

| # | Section | Required Content |
|---|---------|------------------|
| 1 | `=== Environment Status ===` | Platform (OS, arch), Environment (Host/Container) |
| 2 | `=== Mise Status ===` | Version, Config path |
| 3 | `=== Backend Settings ===` | npm.bun, npm.package_manager, python.uv_venv_auto |
| 4 | `=== Installed Tools ===` | List of mise-managed tools |
| 5 | `=== Daemons (Pitchfork) ===` | Running services or "No daemons running" |
| 6 | `=== Health Check ===` | PATH shims status, Bun/Uv/Node versions |
| 7 | `=== Cloud (SkyPilot) ===` | Clusters (verbose), Cost report |
| 8 | `=== AWS Services ===` | EC2, RDS, Load Balancers, S3 (or credentials message) |

### R3: Cloud/AWS Requirements

#### R3.1: SkyPilot
- MUST use verbose flag (`sky status -v`)
- MUST show cost report (`sky cost-report`)
- MUST handle missing SkyPilot gracefully ("SkyPilot not installed")
- MUST timeout after 5 seconds

#### R3.2: AWS Services
- MUST check for AWS CLI availability
- MUST check for AWS credentials
- IF credentials configured:
  - MUST show Account and Region
  - MUST show EC2 Instances (Running)
  - MUST show RDS Databases
  - MUST show Load Balancers
  - MUST show S3 Buckets
- IF credentials NOT configured:
  - MUST show "AWS credentials not configured. Run: aws configure"
- All AWS calls MUST timeout after 5 seconds

### R4: Footer
- MUST reference `mise run agent:status` for detailed SkyPilot info
- MUST reference `mise run aws:status` for standalone AWS view

## Acceptance Tests

Each requirement maps to a test:

```gherkin
Feature: env:status command

  Scenario: Non-interactive execution
    Given mise is installed
    When I run "mise run env:status"
    Then it should complete within 15 seconds
    And it should exit with code 0
    And first output should appear within 2 seconds

  Scenario: All sections present
    Given mise is installed
    When I run "mise run env:status"
    Then output should contain "=== Environment Status ==="
    And output should contain "=== Mise Status ==="
    And output should contain "=== Backend Settings ==="
    And output should contain "=== Installed Tools ==="
    And output should contain "=== Daemons (Pitchfork) ==="
    And output should contain "=== Health Check ==="
    And output should contain "=== Cloud (SkyPilot) ==="
    And output should contain "=== AWS Services ==="

  Scenario: Backend Settings content
    Given mise is installed
    When I run "mise run env:status"
    Then output should contain "npm.bun:"
    And output should contain "npm.package_manager:"
    And output should contain "python.uv_venv_auto:"

  Scenario: Footer references
    Given mise is installed
    When I run "mise run env:status"
    Then output should contain "mise run agent:status"
    And output should contain "mise run aws:status"
```

## Test Mapping

| Requirement | Test Name | File |
|-------------|-----------|------|
| R1.1-R1.4 | Non-interactive tests | test_env_status.bats |
| R2 (all sections) | Section presence tests | test_env_status.bats |
| R3.1 | SkyPilot config tests | test_skypilot.bats |
| R3.2 | AWS config tests | test_skypilot.bats |
| R4 | Footer tests | test_env_status.bats |
