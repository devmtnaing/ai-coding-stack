#!/usr/bin/env bash
# upstream-pull.sh — refresh vendored, non-skill files from their upstream repos.
#
# Reads upstream.json at the repo root. For each entry, downloads the file from
# raw.githubusercontent.com, replaces the local copy if changed, and updates the
# stored sha256 in the manifest.
#
# Usage:
#   bin/upstream-pull.sh           # pull and update files + manifest
#   bin/upstream-pull.sh --check   # report drift, exit 1 if anything is out of date (CI-friendly)
#
# Skills are managed separately by `npx skills update` (see skills-lock.json).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$REPO_ROOT/upstream.json"

if [[ ! -f "$MANIFEST" ]]; then
  echo "error: $MANIFEST not found" >&2
  exit 1
fi

CHECK_ONLY=false
if [[ "${1:-}" == "--check" ]]; then
  CHECK_ONLY=true
fi

read_entries() {
  python3 - "$MANIFEST" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    m = json.load(f)
for dest, e in m.get("files", {}).items():
    fields = [dest, e["source"], e.get("path", ""), e.get("ref", "main"), e.get("sha256", "")]
    print("\t".join(fields))
PY
}

update_manifest_sha() {
  local dest="$1"
  local new_sha="$2"
  python3 - "$MANIFEST" "$dest" "$new_sha" <<'PY'
import json, sys
path, dest, new_sha = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    m = json.load(f)
m["files"][dest]["sha256"] = new_sha
with open(path, "w") as f:
    json.dump(m, f, indent=2)
    f.write("\n")
PY
}

changed=0
errors=0

while IFS=$'\t' read -r dest source path ref _old_sha; do
  [[ -z "$dest" ]] && continue
  url="https://raw.githubusercontent.com/${source}/${ref}/${path}"
  tmp="$(mktemp)"

  if ! curl -fsSL "$url" -o "$tmp"; then
    echo "✗ $dest: failed to fetch $url" >&2
    errors=$((errors + 1))
    rm -f "$tmp"
    continue
  fi

  new_sha="$(shasum -a 256 "$tmp" | awk '{print $1}')"
  target="$REPO_ROOT/$dest"

  if [[ -f "$target" ]] && cmp -s "$tmp" "$target"; then
    echo "✓ $dest unchanged"
    rm -f "$tmp"
    continue
  fi

  if $CHECK_ONLY; then
    echo "△ $dest out of date (upstream sha: ${new_sha:0:12})"
    rm -f "$tmp"
    changed=$((changed + 1))
    continue
  fi

  mkdir -p "$(dirname "$target")"
  mv "$tmp" "$target"
  update_manifest_sha "$dest" "$new_sha"
  echo "↻ $dest updated (sha: ${new_sha:0:12})"
  changed=$((changed + 1))
done < <(read_entries)

echo
if $CHECK_ONLY; then
  if (( changed > 0 )); then
    echo "$changed file(s) out of date. Run bin/upstream-pull.sh to refresh."
    exit 1
  fi
  echo "all upstream files in sync."
else
  echo "done. $changed file(s) updated, $errors error(s)."
  (( errors > 0 )) && exit 1
fi
