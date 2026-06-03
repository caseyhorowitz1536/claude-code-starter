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
