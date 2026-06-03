#!/usr/bin/env bash
# Plain-bash test runner (no bats dependency). Each test_* function asserts with
# assert_eq / assert_contains / assert_ok. Exits non-zero if any assertion fails.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILS=0

assert_eq()       { if [[ "$1" != "$2" ]]; then printf 'FAIL %s: expected [%s] got [%s]\n' "$3" "$2" "$1"; FAILS=$((FAILS+1)); else printf 'ok   %s\n' "$3"; fi; }
assert_contains() { if [[ "$1" != *"$2"* ]]; then printf 'FAIL %s: [%s] missing [%s]\n' "$3" "$1" "$2"; FAILS=$((FAILS+1)); else printf 'ok   %s\n' "$3"; fi; }
assert_ok()       { if ! eval "$1"; then printf 'FAIL %s: cmd failed [%s]\n' "$2" "$1"; FAILS=$((FAILS+1)); else printf 'ok   %s\n' "$2"; fi; }

# Test files register themselves by defining test_* functions, then we run them.
# shellcheck source=/dev/null
for f in "$ROOT"/tests/test_*.sh; do [[ -e "$f" ]] && source "$f"; done
for t in $(declare -F | awk '{print $3}' | grep '^test_'); do "$t"; done

if [[ "$FAILS" -gt 0 ]]; then printf '\n%d assertion(s) failed\n' "$FAILS"; exit 1; fi
printf '\nAll tests passed\n'
