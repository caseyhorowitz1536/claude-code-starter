#!/usr/bin/env bash
# setup.sh must be source-safe: define parse_args + globals without running main.
# shellcheck source=/dev/null
REPO_DIR="$ROOT" source "$ROOT/setup.sh"

test_defaults() {
  parse_args
  assert_eq "$DRY_RUN" 0 'DRY_RUN defaults 0'
  assert_eq "$SKIP_OBSIDIAN" 0 'SKIP_OBSIDIAN defaults 0'
}
test_flags() {
  parse_args --dry-run --skip-obsidian --skip-plugins --skip-vault --yes
  assert_eq "$DRY_RUN" 1 '--dry-run sets DRY_RUN'
  assert_eq "$SKIP_OBSIDIAN" 1 '--skip-obsidian'
  assert_eq "$SKIP_PLUGINS" 1 '--skip-plugins'
  assert_eq "$SKIP_VAULT" 1 '--skip-vault'
  assert_eq "$ASSUME_YES" 1 '--yes'
}
test_unknown_flag_fails() {
  if ( parse_args --bogus ) >/dev/null 2>&1; then assert_eq 1 0 'unknown flag should fail'; else assert_eq 0 0 'unknown flag fails'; fi
}
test_new_skip_flags() {
  parse_args --skip-config --skip-mcp
  assert_eq "$SKIP_CONFIG" 1 '--skip-config'
  assert_eq "$SKIP_MCP" 1 '--skip-mcp'
}
test_verify_flag() {
  parse_args --verify
  assert_eq "$VERIFY_ONLY" 1 '--verify sets VERIFY_ONLY'
}
test_skip_flag_matrix() {
  local combos=("" "--skip-obsidian" "--skip-plugins" "--skip-vault" "--skip-config" "--skip-mcp" \
    "--skip-obsidian --skip-plugins --skip-vault --skip-config --skip-mcp")
  local c
  for c in "${combos[@]}"; do
    parse_args $c
    case "$c" in *obsidian*) assert_eq "$SKIP_OBSIDIAN" 1 "obsidian gated [$c]";; *) assert_eq "$SKIP_OBSIDIAN" 0 "obsidian on [$c]";; esac
    case "$c" in *config*)   assert_eq "$SKIP_CONFIG"  1 "config gated [$c]";;   *) assert_eq "$SKIP_CONFIG"  0 "config on [$c]";; esac
    case "$c" in *mcp*)      assert_eq "$SKIP_MCP"     1 "mcp gated [$c]";;      *) assert_eq "$SKIP_MCP"     0 "mcp on [$c]";; esac
  done
}
test_help_short_circuits() {
  # Regression: `setup.sh --help` must print usage and NOT run the installer.
  local out
  out="$(bash "$ROOT/setup.sh" --help 2>&1)" || true
  assert_contains "$out" 'Usage: setup.sh' '--help prints usage'
  case "$out" in
    *"=== Preflight ==="*) assert_eq 1 0 '--help must NOT run the installer' ;;
    *) assert_eq 0 0 '--help does not run the installer' ;;
  esac
}
