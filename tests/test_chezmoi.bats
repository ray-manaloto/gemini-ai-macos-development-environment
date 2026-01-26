#!/usr/bin/env bats
# test_chezmoi.bats - Chezmoi configuration tests
# Run with: bats tests/test_chezmoi.bats

# Skip if chezmoi not installed
setup() {
  if ! command -v chezmoi &> /dev/null; then
    skip "chezmoi not installed"
  fi
}

@test "chezmoi templates exist" {
  [ -f "config/chezmoi/dot_zshrc.tmpl" ]
}

@test "chezmoi gitconfig template exists" {
  [ -f "config/chezmoi/dot_gitconfig.tmpl" ]
}

@test "chezmoi ignore file exists" {
  [ -f "config/chezmoi/.chezmoiignore" ]
}

@test "zshrc template contains mise activation" {
  run grep -q "mise activate" config/chezmoi/dot_zshrc.tmpl
  [ "$status" -eq 0 ]
}

@test "zshrc template contains starship init" {
  run grep -q "starship init" config/chezmoi/dot_zshrc.tmpl
  [ "$status" -eq 0 ]
}

@test "zshrc template contains zoxide init" {
  run grep -q "zoxide init" config/chezmoi/dot_zshrc.tmpl
  [ "$status" -eq 0 ]
}

@test "gitconfig template has user section placeholder" {
  run grep -q "name\|email" config/chezmoi/dot_gitconfig.tmpl
  [ "$status" -eq 0 ]
}

@test "chezmoi can validate templates" {
  if ! command -v chezmoi &> /dev/null; then
    skip "chezmoi not installed"
  fi
  # Dry-run to check template validity
  run chezmoi execute-template < config/chezmoi/dot_zshrc.tmpl
  [ "$status" -eq 0 ]
}
