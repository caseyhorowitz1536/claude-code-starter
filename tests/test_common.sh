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

test_need_cmd_ok() {
  # a command that exists returns 0 and prints nothing fatal
  assert_ok "need_cmd ls" 'need_cmd passes for an existing command'
}
test_need_cmd_missing() {
  # a bogus command must make need_cmd exit non-zero (run in a subshell so it
  # doesn't kill the test runner) and mention the command name. `|| rc=$?` keeps
  # the failing substitution in a tested context so a leaked `set -e` (sourced
  # from setup.sh by other test files) can't abort the runner.
  local out rc=0
  out="$( ( need_cmd definitely_not_a_real_cmd_xyz ) 2>&1 )" || rc=$?
  assert_ok "[[ $rc -ne 0 ]]" 'need_cmd exits non-zero for a missing command'
  assert_contains "$out" 'definitely_not_a_real_cmd_xyz' 'need_cmd names the missing command'
}
test_ensure_propagates_failure() {
  # `|| rc=$?` keeps the failing command in a tested context so a leaked `set -e`
  # (sourced from setup.sh by other test files) can't abort the runner.
  local rc=0; ( ensure false ) >/dev/null 2>&1 || rc=$?
  assert_ok "[[ $rc -ne 0 ]]" 'ensure exits non-zero when the command fails'
}
test_ensure_passes_through() {
  assert_ok "ensure true" 'ensure returns 0 when the command succeeds'
}
