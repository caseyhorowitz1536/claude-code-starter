#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$ROOT/lib/common.sh"
source "$ROOT/lib/vault.sh"

test_vault_dest_is_unified_name() {
  assert_contains "$VAULT_DEST" 'Claude Code Starter' 'VAULT_DEST points at the unified vault'
}
test_vault_installs_then_skips() {
  local home; home="$(mktemp -d)"
  # ASSUME_YES so the "open in Obsidian?" confirm never blocks; no Obsidian present anyway.
  ( HOME="$home" REPO_DIR="$ROOT" DRY_RUN=0 ASSUME_YES=1 do_vault ) >/dev/null 2>&1
  assert_ok "[[ -f \"$home/Documents/Claude Code Starter/Start Here.md\" ]]" 'vault copied with top MOC'
  assert_ok "[[ -d \"$home/Documents/Claude Code Starter/Karpathy LLM Wiki\" ]]" 'Karpathy subfolder present'
  # second run must not error and must not duplicate
  ( HOME="$home" REPO_DIR="$ROOT" DRY_RUN=0 ASSUME_YES=1 do_vault ) >/dev/null 2>&1
  assert_eq "$?" 0 'second do_vault run is a clean no-op'
  rm -rf "$home"
}
