#!/usr/bin/env bash
# Fails if any [[wikilink]] in vault/*.md points to a note that doesn't exist,
# or if a required MOC is missing. Run from repo root or anywhere.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VAULT="${ROOT}/vault"
fail=0

# Set of existing note basenames (without .md)
existing="$(cd "$VAULT" && for f in *.md; do printf '%s\n' "${f%.md}"; done)"

# Required MOCs
for req in "Start Here" "Zero-to-Hero Index" "LLM Index"; do
  if ! grep -qxF "$req" <<<"$existing" && [[ ! -f "${VAULT}/00 — ${req}.md" ]] && [[ ! -f "${VAULT}/${req}.md" ]]; then
    echo "MISSING required MOC: ${req}"; fail=1
  fi
done

# Every [[link]] (strip alias after |, strip #heading) must resolve to a file
while IFS= read -r link; do
  base="${link%%|*}"; base="${base%%#*}"
  [[ -z "$base" ]] && continue
  if [[ ! -f "${VAULT}/${base}.md" ]] && ! grep -qxF "$base" <<<"$existing"; then
    echo "DANGLING link: [[${link}]]"; fail=1
  fi
done < <(grep -rhoE '\[\[[^]]+\]\]' "$VAULT"/*.md | sed -E 's/^\[\[//; s/\]\]$//')

if [[ "$fail" -ne 0 ]]; then echo "Vault link check FAILED"; exit 1; fi
echo "Vault link check passed"
