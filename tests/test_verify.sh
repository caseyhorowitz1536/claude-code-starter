#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$ROOT/lib/common.sh"
source "$ROOT/lib/verify.sh"

test_verify_reports_missing_as_fail() {
  # Empty HOME + empty PATH stub: nothing is installed -> non-zero + ✗ markers.
  # `&& rc=0 || rc=$?` captures the exit without tripping `set -e` (setup.sh,
  # sourced by another test, leaves errexit on in the runner shell).
  local home stub out rc; home="$(mktemp -d)"; stub="$(mktemp -d)"
  out="$( HOME="$home" PATH="$stub" do_verify 2>&1 )" && rc=0 || rc=$?
  assert_ok "[[ $rc -ne 0 ]]" 'do_verify exits non-zero when critical checks fail'
  assert_contains "$out" 'claude' 'verify reports the claude check'
  rm -rf "$home" "$stub"
}
test_verify_passes_with_stubs() {
  # Stub claude (version + mcp get + plugin list) and npx; create vault + settings.
  local home stub out rc; home="$(mktemp -d)"; stub="$(mktemp -d)"
  cat > "$stub/claude" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  --version) echo "claude 9.9.9";;
  mcp) [ "$2" = "get" ] && exit 0;;
  plugin) echo "superpowers"; exit 0;;
esac
exit 0
EOF
  chmod +x "$stub/claude"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$stub/npx"; chmod +x "$stub/npx"
  mkdir -p "$home/.claude" "$home/Documents/Claude Code Starter"
  printf '{}' > "$home/.claude/settings.json"
  ln -s "$home/Documents/Claude Code Starter" "$home/.claude-code-vault"
  # Prepend the stub so it shadows any real claude/npx, but keep the system PATH
  # so the stubs' `#!/usr/bin/env bash` shebang (and head/etc.) still resolve.
  out="$( HOME="$home" PATH="$stub:$PATH" do_verify 2>&1 )" && rc=0 || rc=$?
  assert_eq "$rc" 0 'do_verify exits 0 when everything is present'
  rm -rf "$home" "$stub"
}
