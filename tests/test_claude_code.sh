#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$ROOT/lib/common.sh"
source "$ROOT/lib/claude-code.sh"

_PATHLINE='export PATH="$HOME/.local/bin:$PATH"'

test_path_zsh_writes_zshrc() {
  local home; home="$(mktemp -d)"
  ( HOME="$home" SHELL=/bin/zsh DRY_RUN=0 _ensure_local_bin_on_path ) >/dev/null 2>&1
  assert_contains "$(cat "$home/.zshrc" 2>/dev/null)" "$_PATHLINE" 'zsh: PATH line added to ~/.zshrc'
  rm -rf "$home"
}

test_path_bash_writes_bash_profile_not_zshrc() {
  local home; home="$(mktemp -d)"
  ( HOME="$home" SHELL=/bin/bash DRY_RUN=0 _ensure_local_bin_on_path ) >/dev/null 2>&1
  assert_contains "$(cat "$home/.bash_profile" 2>/dev/null)" "$_PATHLINE" 'bash: PATH line added to ~/.bash_profile'
  assert_ok "[[ ! -f \"$home/.zshrc\" ]]" 'bash: ~/.zshrc is not created for a bash user'
  rm -rf "$home"
}

test_path_bash_appends_existing_profile() {
  local home; home="$(mktemp -d)"
  printf '# my profile\n' > "$home/.profile"
  ( HOME="$home" SHELL=/bin/bash DRY_RUN=0 _ensure_local_bin_on_path ) >/dev/null 2>&1
  assert_contains "$(cat "$home/.profile")" "$_PATHLINE" 'bash: appends to existing ~/.profile rather than shadowing it'
  assert_ok "[[ ! -f \"$home/.bash_profile\" ]]" 'bash: does not create ~/.bash_profile when ~/.profile exists'
  rm -rf "$home"
}

test_path_is_idempotent() {
  local home; home="$(mktemp -d)"
  ( HOME="$home" SHELL=/bin/zsh DRY_RUN=0 _ensure_local_bin_on_path ) >/dev/null 2>&1
  ( HOME="$home" SHELL=/bin/zsh DRY_RUN=0 _ensure_local_bin_on_path ) >/dev/null 2>&1
  local count; count="$(grep -cxF "$_PATHLINE" "$home/.zshrc")"
  assert_eq "$count" "1" 'PATH line is written exactly once across repeated runs'
  rm -rf "$home"
}
