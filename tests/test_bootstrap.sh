#!/usr/bin/env bash
# bootstrap.sh must (a) be source-safe: sourcing it defines functions but does
# NOT clone/exec; (b) surface a failing git as a non-zero exit with no partial
# clone left behind. We stub git on PATH so no network is touched.
test_bootstrap_is_source_safe() {
  # Sourcing must not invoke main (guarded by the BASH_SOURCE check). If it ran,
  # it would try to clone and fail here. We assert the function exists instead.
  ( BOOTSTRAP_NO_MAIN=1 source "$ROOT/bootstrap.sh"; declare -F main >/dev/null ) \
    && assert_eq 0 0 'bootstrap defines main() without running it' \
    || assert_eq 1 0 'bootstrap defines main() without running it'
}
test_bootstrap_git_failure_is_clean() {
  local stub home out rc=0
  stub="$(mktemp -d)"; home="$(mktemp -d)"
  printf '#!/usr/bin/env bash\necho "fatal: unable to access" >&2\nexit 128\n' > "$stub/git"
  chmod +x "$stub/git"
  out="$( HOME="$home" PATH="$stub:$PATH" CCS_REF="v0.0.0-test" bash "$ROOT/bootstrap.sh" 2>&1 )" || rc=$?
  rm -rf "$stub"
  assert_ok "[[ $rc -ne 0 ]]" 'bootstrap exits non-zero when git fails'
  assert_contains "$out" 'unable to access' 'bootstrap surfaces the git error'
  assert_ok "[[ ! -d \"$home/.claude-code-starter\" ]]" 'no partial clone dir left behind'
  rm -rf "$home"
}
test_latest_ref_survives_many_tags() {
  # Regression: latest_ref must not abort under set -euo pipefail when git emits a
  # large tag list (piping into head used to SIGPIPE git -> exit 141 -> installer dies).
  local stub out rc=0
  stub="$(mktemp -d)"
  cat > "$stub/git" <<'GITEOF'
#!/usr/bin/env bash
n=5000; while [ "$n" -ge 1 ]; do printf 'deadbeef%d\trefs/tags/v0.%d.0\n' "$n" "$n"; n=$((n-1)); done
GITEOF
  chmod +x "$stub/git"
  out="$( BOOTSTRAP_NO_MAIN=1 PATH="$stub:$PATH" bash -c 'source "'"$ROOT"'/bootstrap.sh"; latest_ref' 2>&1 )" || rc=$?
  rm -rf "$stub"
  assert_ok "[[ $rc -eq 0 ]]" 'latest_ref does not abort on a large tag list'
  assert_contains "$out" 'v0.5000.0' 'latest_ref returns the newest tag'
}
