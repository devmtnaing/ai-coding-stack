#!/usr/bin/env bash
# sync-upstream.sh — refresh everything this repo vendors from external sources.
#
# Combines:
#   1. `npx skills update` — refreshes skills tracked in skills-lock.json
#   2. `bin/upstream-pull.sh` — refreshes non-skill files tracked in upstream.json
#
# Run before pushing if you want downstream projects to pick up upstream changes.
#
# Usage:
#   bin/sync-upstream.sh           # update skills + upstream files
#   bin/sync-upstream.sh --check   # report drift only, no writes (CI-friendly for upstream files)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

CHECK_ONLY=false
[[ "${1:-}" == "--check" ]] && CHECK_ONLY=true

echo "═══ skills (skills-lock.json) ═══"
if $CHECK_ONLY; then
  echo "(skip — npx skills has no --check mode; run without --check to refresh)"
else
  npx --yes skills update
fi

echo
echo "═══ upstream files (upstream.json) ═══"
if $CHECK_ONLY; then
  bin/upstream-pull.sh --check
else
  bin/upstream-pull.sh
fi
