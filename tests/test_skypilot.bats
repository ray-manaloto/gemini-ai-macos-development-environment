#!/usr/bin/env bats
# test_skypilot.bats - SkyPilot and AWS cloud agent tests
# Run with: bats tests/test_skypilot.bats

# =============================================================================
# Setup
# =============================================================================

setup() {
  if ! command -v mise &> /dev/null; then
    skip "mise not installed"
  fi
}

# =============================================================================
# SkyPilot Installation Tests
# =============================================================================

@test "skypilot is configured in mise" {
  run mise ls
  [ "$status" -eq 0 ]
  # SkyPilot is installed via pipx
  [[ "$output" =~ "skypilot" ]] || [[ "$output" =~ "pipx" ]]
}

@test "sky command is available" {
  # Skip if SkyPilot not installed yet
  if ! command -v sky &> /dev/null; then
    skip "SkyPilot not installed - run 'mise install' first"
  fi
  
  run sky --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "SkyPilot" ]] || [[ "$output" =~ "sky" ]]
}

@test "sky check runs without critical errors" {
  if ! command -v sky &> /dev/null; then
    skip "SkyPilot not installed"
  fi
  
  # sky check may return non-zero if no cloud configured
  # We just verify it runs and produces output
  run sky check
  [[ "$output" =~ "Checking" ]] || [[ "$output" =~ "AWS" ]] || [[ "$output" =~ "enabled" ]] || [[ "$output" =~ "disabled" ]]
}

# =============================================================================
# Agent Configuration Tests
# =============================================================================

@test "agent.yaml template exists" {
  [ -f "templates/agent.yaml" ]
}

@test "agent.yaml is valid YAML" {
  if ! command -v yq &> /dev/null; then
    skip "yq not installed"
  fi
  
  run yq '.' templates/agent.yaml
  [ "$status" -eq 0 ]
}

@test "agent.yaml has required fields" {
  [ -f "templates/agent.yaml" ]
  
  # Check for essential SkyPilot fields
  run grep -E "^name:|resources:|setup:|run:" templates/agent.yaml
  [ "$status" -eq 0 ]
}

@test "agent.yaml uses AWS cloud" {
  [ -f "templates/agent.yaml" ]
  
  run grep -E "cloud:\s*aws" templates/agent.yaml
  [ "$status" -eq 0 ]
}

@test "agent.yaml uses spot instances" {
  [ -f "templates/agent.yaml" ]
  
  run grep -E "use_spot:\s*true" templates/agent.yaml
  [ "$status" -eq 0 ]
}

# =============================================================================
# Mise Task Tests
# =============================================================================

@test "agent:up task is defined" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "agent:up" ]]
}

@test "agent:down task is defined" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "agent:down" ]]
}

@test "agent:status task is defined" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "agent:status" ]]
}

@test "agent:stop task is defined" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "agent:stop" ]]
}

@test "agent:start task is defined" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "agent:start" ]]
}

@test "agent:restart task is defined" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "agent:restart" ]]
}

@test "agent:ssh task is defined" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "agent:ssh" ]]
}

@test "agent:logs task is defined" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "agent:logs" ]]
}

@test "agent:exec task is defined" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "agent:exec" ]]
}

# =============================================================================
# AWS Configuration Tests (Optional - Skip if no credentials)
# =============================================================================

@test "AWS CLI is available" {
  if ! command -v aws &> /dev/null; then
    skip "AWS CLI not installed"
  fi
  
  run aws --version
  [ "$status" -eq 0 ]
  [[ "$output" =~ "aws-cli" ]]
}

@test "AWS credentials are configured" {
  # Skip if AWS CLI not installed
  if ! command -v aws &> /dev/null; then
    skip "AWS CLI not installed"
  fi
  
  # Skip if no credentials file
  if [ ! -f "$HOME/.aws/credentials" ] && [ -z "$AWS_ACCESS_KEY_ID" ]; then
    skip "No AWS credentials configured"
  fi
  
  # Try to get caller identity (validates credentials)
  run aws sts get-caller-identity 2>&1
  
  # Either success or explicit error about credentials
  # (not "command not found" or similar)
  [[ "$status" -eq 0 ]] || [[ "$output" =~ "InvalidClientTokenId" ]] || [[ "$output" =~ "ExpiredToken" ]] || [[ "$output" =~ "credentials" ]]
}

# =============================================================================
# Documentation Tests
# =============================================================================

@test "SKYPILOT.md documentation exists" {
  [ -f "SKYPILOT.md" ]
}

@test "SKYPILOT.md has required sections" {
  [ -f "SKYPILOT.md" ]
  
  # Check for essential documentation sections
  run grep -E "## (Prerequisites|Quick Start|Configuration|Troubleshooting)" SKYPILOT.md
  [ "$status" -eq 0 ]
}

@test "agent tasks support CLUSTER environment variable" {
  # Check that agent tasks use CLUSTER variable
  grep -q 'CLUSTER=' config/mise.toml
  grep -q 'CLUSTER:-' config/mise.toml
}

@test "env:start starts cloud agents by default" {
  grep -q 'Starting Cloud Agents' config/mise.toml
  grep -q 'sky start' config/mise.toml
}

@test "env tasks support SKIP_CLOUD option" {
  grep -q 'SKIP_CLOUD' config/mise.toml
}

@test "agent:check task exists for credential validation" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "agent:check" ]]
}

@test "agent:up depends on agent:check" {
  grep -A3 '\[tasks."agent:up"\]' config/mise.toml | grep -q 'depends.*agent:check'
}

@test "env:start validates AWS credentials before cloud operations" {
  grep -q 'sky check aws' config/mise.toml
}

@test "mise.toml does not hardcode AWS_PROFILE" {
  ! grep -q 'AWS_PROFILE.*=.*"dev-account"' config/mise.toml
}

# =============================================================================
# Enhanced Status Output Tests
# =============================================================================

@test "agent:status uses verbose output (sky status -v)" {
  grep -A60 '\[tasks."agent:status"\]' config/mise.toml | grep -q 'sky status -v'
}

@test "agent:status shows cost report" {
  grep -A50 '\[tasks."agent:status"\]' config/mise.toml | grep -q 'sky cost-report'
}

@test "agent:status supports CLUSTER parameter for specific cluster" {
  grep -A50 '\[tasks."agent:status"\]' config/mise.toml | grep -q 'CLUSTER='
}

@test "agent:status shows IP address for specific cluster" {
  grep -A50 '\[tasks."agent:status"\]' config/mise.toml | grep -q 'sky status --ip'
}

@test "agent:status shows endpoints for specific cluster" {
  grep -A50 '\[tasks."agent:status"\]' config/mise.toml | grep -q 'sky status --endpoints'
}

@test "env:status uses verbose SkyPilot output" {
  grep -A15 '=== Cloud' config/mise.toml | grep -q 'sky status -v'
}

@test "env:status shows cost summary" {
  grep -A15 '=== Cloud' config/mise.toml | grep -q 'cost-report'
}

# =============================================================================
# AWS Status Task Tests
# =============================================================================

@test "aws:status task is defined" {
  run mise tasks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "aws:status" ]]
}

@test "aws:status lists EC2 instances" {
  grep -A80 '\[tasks."aws:status"\]' config/mise.toml | grep -q 'ec2 describe-instances'
}

@test "aws:status lists RDS databases" {
  grep -A80 '\[tasks."aws:status"\]' config/mise.toml | grep -q 'rds describe-db-instances'
}

@test "aws:status lists load balancers" {
  grep -A80 '\[tasks."aws:status"\]' config/mise.toml | grep -q 'elbv2 describe-load-balancers'
}

@test "aws:status lists S3 buckets" {
  grep -A80 '\[tasks."aws:status"\]' config/mise.toml | grep -q 's3api list-buckets'
}

@test "aws:status shows SkyPilot clusters" {
  grep -A80 '\[tasks."aws:status"\]' config/mise.toml | grep -q 'sky status'
}

@test "agent:status references aws:status for full AWS view" {
  grep -A80 '\[tasks."agent:status"\]' config/mise.toml | grep -q 'aws:status'
}

@test "env:status references aws:status" {
  grep -A60 '=== Cloud' config/mise.toml | grep -q 'aws:status'
}
