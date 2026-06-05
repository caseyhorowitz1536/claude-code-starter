#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$ROOT/lib/common.sh"
source "$ROOT/lib/config.sh"

test_config_writes_when_absent() {
  local home; home="$(mktemp -d)"
  ( HOME="$home" REPO_DIR="$ROOT" DRY_RUN=0 do_config ) >/dev/null 2>&1
  assert_ok "[[ -f \"$home/.claude/settings.json\" ]]" 'do_config creates settings.json when absent'
  # must be valid JSON we can grep for a known key
  assert_contains "$(cat "$home/.claude/settings.json")" 'permissions' 'settings.json has permissions'
  rm -rf "$home"
}
test_config_never_clobbers() {
  local home; home="$(mktemp -d)"
  mkdir -p "$home/.claude"
  printf '{"mine":true}' > "$home/.claude/settings.json"
  ( HOME="$home" REPO_DIR="$ROOT" DRY_RUN=0 do_config ) >/dev/null 2>&1
  assert_contains "$(cat "$home/.claude/settings.json")" 'mine' 'do_config leaves an existing settings.json untouched'
  rm -rf "$home"
}
