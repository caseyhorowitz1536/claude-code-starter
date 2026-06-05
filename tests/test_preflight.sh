#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$ROOT/lib/common.sh"
source "$ROOT/lib/preflight.sh"

# Stub `uname` to report Linux so these run deterministically on any OS.
test_preflight_dryrun_nonmac_returns_0() {
  local stub rc=0
  stub="$(mktemp -d)"
  printf '#!/usr/bin/env bash\necho Linux\n' > "$stub/uname"; chmod +x "$stub/uname"
  ( PATH="$stub:$PATH" DRY_RUN=1 do_preflight ) >/dev/null 2>&1 || rc=$?
  rm -rf "$stub"
  assert_eq "$rc" 0 'preflight: non-macOS dry-run returns 0 (Linux CI can smoke-test)'
}
test_preflight_real_nonmac_fails() {
  local stub rc=0
  stub="$(mktemp -d)"
  printf '#!/usr/bin/env bash\necho Linux\n' > "$stub/uname"; chmod +x "$stub/uname"
  ( PATH="$stub:$PATH" DRY_RUN=0 do_preflight ) >/dev/null 2>&1 || rc=$?
  rm -rf "$stub"
  assert_ok "[[ $rc -ne 0 ]]" 'preflight: non-macOS real install still fails'
}
