#!/usr/bin/env bash
set -euo pipefail

# Snapshot for planning/copilot_prompt
OUT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
OUT_FILE="$OUT_DIR/COPILOT_SESSION.md"
mkdir -p "$OUT_DIR"

echo "Session timestamp: $(date -u '+%Y-%m-%d %H:%M UTC')" >"$OUT_FILE"
REPO_DIRS=("$OUT_DIR/../../proto" "$OUT_DIR/../../infra" "$OUT_DIR/..")
for repo_dir in "${REPO_DIRS[@]}"; do
  if [[ -d "$repo_dir" ]] && git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    repo_name=$(basename "$repo_dir")
    echo "Repo: $repo_name" >>"$OUT_FILE"
    echo "User: $(git -C "$repo_dir" config --get user.name || whoami)" >>"$OUT_FILE"
    echo "Branch: $(git -C "$repo_dir" rev-parse --abbrev-ref HEAD || echo N/A)" >>"$OUT_FILE"
    echo "Last commit: $(git -C "$repo_dir" rev-parse --short HEAD || echo N/A)" >>"$OUT_FILE"
    changed=$(git -C "$repo_dir" status --porcelain | awk '{print $2}' | paste -sd, - || echo '')
    echo "Files changed: ${changed}" >>"$OUT_FILE"
    echo "" >>"$OUT_FILE"
  else
    echo "Repo: $(basename "$repo_dir") (not a git repo)" >>"$OUT_FILE"
  fi
done

echo "Active task: " >>"$OUT_FILE"
echo "Next step: " >>"$OUT_FILE"
echo "Relevant todos: planning/pii_vault_spike_checklist.md" >>"$OUT_FILE"
echo "Note: Edit this file with a short Active task & Next step summary before closing VS Code." >>"$OUT_FILE"
echo "Wrote $OUT_FILE"
