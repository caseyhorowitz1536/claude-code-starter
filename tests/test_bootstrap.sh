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
test_bootstrap_pipe_safe_under_set_u() {
  # Simulates `curl ... | bash`: the script is read from STDIN, so BASH_SOURCE is
  # empty. Must NOT abort with `set -u` 'unbound variable'. BOOTSTRAP_NO_MAIN keeps
  # the install from running during the test.
  local out rc=0
  out="$( BOOTSTRAP_NO_MAIN=1 bash < "$ROOT/bootstrap.sh" 2>&1 )" || rc=$?
  assert_eq "$rc" 0 'bootstrap read from stdin (pipe) exits 0 under set -u'
  case "$out" in
    *"unbound variable"*) assert_eq 1 0 'no unbound-variable error on the pipe path' ;;
    *) assert_eq 0 0 'no unbound-variable error on the pipe path' ;;
  esac
}
test_bootstrap_pipe_runs_main() {
  # Regression: the old BASH_SOURCE==$0 guard skipped main entirely under curl|bash.
  # With a failing stubbed git, main must still RUN (and then fail), not be skipped.
  local stub home out rc=0
  stub="$(mktemp -d)"; home="$(mktemp -d)"
  printf '#!/usr/bin/env bash\necho "stub-git" >&2\nexit 128\n' > "$stub/git"; chmod +x "$stub/git"
  out="$( HOME="$home" PATH="$stub:$PATH" CCS_REF="v0.0.0-test" bash < "$ROOT/bootstrap.sh" 2>&1 )" || rc=$?
  rm -rf "$stub" "$home"
  assert_ok "[[ $rc -ne 0 ]]" 'pipe path with failing git exits non-zero (main ran)'
  case "$out" in
    *"Cloning"*|*"stub-git"*) assert_eq 0 0 'main executed on the pipe path' ;;
    *) assert_eq 1 0 'main executed on the pipe path' ;;
  esac
}
test_bootstrap_stops_cleanly_without_clt() {
  # Fresh Mac: Darwin + no Command Line Tools -> trigger the installer and exit 1
  # with re-run instructions BEFORE touching git (whose /usr/bin shim would fail).
  local stub home out rc=0
  stub="$(mktemp -d)"; home="$(mktemp -d)"
  printf '#!/usr/bin/env bash\necho Darwin\n' > "$stub/uname"
  printf '#!/usr/bin/env bash\n[ "$1" = "-p" ] && exit 2; exit 0\n' > "$stub/xcode-select"
  printf '#!/usr/bin/env bash\necho GIT-CALLED >&2; exit 1\n' > "$stub/git"
  chmod +x "$stub"/*
  out="$( HOME="$home" PATH="$stub:$PATH" bash "$ROOT/bootstrap.sh" 2>&1 )" || rc=$?
  assert_ok "[[ $rc -ne 0 ]]" 'bootstrap exits non-zero when CLT are missing'
  assert_contains "$out" 'run the SAME install command again' 'bootstrap tells the user to re-run after CLT'
  local called=0; [[ "$out" == *GIT-CALLED* ]] && called=1
  assert_eq "$called" 0 'bootstrap never calls the git shim without CLT'
  rm -rf "$stub" "$home"
}
test_bootstrap_moves_non_git_dest_aside() {
  local stub home rc=0
  stub="$(mktemp -d)"; home="$(mktemp -d)"
  mkdir -p "$home/.claude-code-starter"; touch "$home/.claude-code-starter/junk"
  printf '#!/usr/bin/env bash\nexit 128\n' > "$stub/git"; chmod +x "$stub/git"
  HOME="$home" PATH="$stub:$PATH" CCS_REF="v0.0.0-test" bash "$ROOT/bootstrap.sh" >/dev/null 2>&1 || rc=$?
  assert_ok "[[ -f \"$home/.claude-code-starter.bak.1/junk\" ]]" 'non-git leftover dir is moved aside, not nested into'
  rm -rf "$stub" "$home"
}
