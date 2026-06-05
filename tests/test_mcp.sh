#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$ROOT/lib/common.sh"
source "$ROOT/lib/mcp.sh"

test_mcp_dryrun_prints_intended_commands() {
  local home out; home="$(mktemp -d)"
  out="$( HOME="$home" DRY_RUN=1 do_mcp 2>&1 )"
  assert_contains "$out" 'server-filesystem' 'dry-run names the filesystem MCP server'
  assert_contains "$out" 'mcp add' 'dry-run shows the claude mcp add command'
  assert_contains "$out" '.claude-code-vault' 'dry-run uses the space-free symlink path'
  rm -rf "$home"
}
test_mcp_real_skips_without_npx() {
  # No npx on a stubbed PATH -> graceful skip (return 0) + manual instructions, not a hard fail.
  local home stub out rc; home="$(mktemp -d)"; stub="$(mktemp -d)"
  # provide a 'claude' so the npx check is what triggers, but NO npx/node
  printf '#!/usr/bin/env bash\nexit 0\n' > "$stub/claude"; chmod +x "$stub/claude"
  mkdir -p "$home/Documents/Claude Code Starter"
  out="$( HOME="$home" PATH="$stub" DRY_RUN=0 do_mcp 2>&1 )"; rc=$?
  assert_eq "$rc" 0 'do_mcp returns 0 (graceful) when npx is missing'
  assert_contains "$out" 'Node' 'do_mcp explains Node is needed'
  rm -rf "$home" "$stub"
}
