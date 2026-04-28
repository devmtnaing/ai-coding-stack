#!/usr/bin/env bash
# sync-base.sh — pull the latest CLAUDE.base.md from ai-coding-stack into the current project.
#
# Usage:
#   bash bin/sync-base.sh                       # if you have this script vendored in your project
#   curl -fsSL https://raw.githubusercontent.com/${REPO}/main/bin/sync-base.sh | bash
#
# Override the source repo via env var:
#   REPO=myuser/ai-coding-stack BRANCH=main bash bin/sync-base.sh

set -euo pipefail

REPO="${REPO:-devmtnaing/ai-coding-stack}"
BRANCH="${BRANCH:-main}"
SRC_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/CLAUDE.base.md"
DEST="CLAUDE.base.md"

echo "→ fetching $SRC_URL"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

if ! curl -fsSL "$SRC_URL" -o "$tmp"; then
  echo "error: failed to download $SRC_URL" >&2
  exit 1
fi

if [[ ! -s "$tmp" ]]; then
  echo "error: downloaded file is empty" >&2
  exit 1
fi

if [[ -f "$DEST" ]] && cmp -s "$tmp" "$DEST"; then
  echo "✓ $DEST already up to date"
  exit 0
fi

mv "$tmp" "$DEST"
trap - EXIT
echo "✓ updated $DEST"

if [[ -f CLAUDE.md ]] && ! grep -qE '^@CLAUDE\.base\.md\b' CLAUDE.md; then
  echo
  echo "note: your CLAUDE.md does not appear to import CLAUDE.base.md."
  echo "      add this line near the top of CLAUDE.md to load the shared base:"
  echo
  echo "      @CLAUDE.base.md"
fi
