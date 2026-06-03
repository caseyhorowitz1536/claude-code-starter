#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$ROOT/lib/common.sh"

test_have_true()  { assert_ok 'have bash' 'have finds bash'; }
test_have_false() { if have definitely_not_a_real_cmd_xyz; then assert_eq 1 0 'have rejects missing'; else assert_eq 0 0 'have rejects missing'; fi; }

test_run_dryrun_echoes() {
  DRY_RUN=1
  local out; out="$(run mkdir /tmp/should_not_exist_xyz 2>&1)"
  assert_contains "$out" '[dry-run] mkdir /tmp/should_not_exist_xyz' 'run echoes in dry-run'
  assert_ok '[[ ! -e /tmp/should_not_exist_xyz ]]' 'run did not execute in dry-run'
  # shellcheck disable=SC2034  # DRY_RUN is exported and read by sourced lib functions
  DRY_RUN=0
}

test_backup_renames() {
  local d; d="$(mktemp -d)"; echo hi > "$d/f"
  # shellcheck disable=SC2034  # DRY_RUN is read by sourced lib functions
  DRY_RUN=0
  backup "$d/f"
  assert_ok "[[ -e '$d/f.bak.1' && ! -e '$d/f' ]]" 'backup moves to .bak.1'
  rm -rf "$d"
}

test_backup_noop_when_absent() {
  local d; d="$(mktemp -d)"
  assert_ok "backup '$d/missing'" 'backup is a no-op when target absent'
  rm -rf "$d"
}
