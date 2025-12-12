#!/usr/bin/env bash
set -euo pipefail

# Snapshot for planning/copilot_prompt
OUT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
OUT_FILE="$OUT_DIR/COPILOT_SESSION.md"
mkdir -p "$OUT_DIR"

# 1. Preserve existing notes if file exists
ACTIVE_TASK=""
NEXT_STEP=""

if [[ -f "$OUT_FILE" ]]; then
  # Extract content after "Active task:" until end of line
  ACTIVE_TASK=$(grep "^Active task:" "$OUT_FILE" | sed 's/^Active task: //')
  # Extract content after "Next step:" until end of line
  NEXT_STEP=$(grep "^Next step:" "$OUT_FILE" | sed 's/^Next step: //')
fi

# 2. Start writing new file
echo "Session timestamp: $(date -u '+%Y-%m-%d %H:%M UTC')" >"$OUT_FILE"

# 3. Gather repo context
# Use relative paths that are robust to where the script is run
REPO_DIRS=(
  "$OUT_DIR/../../core"
  "$OUT_DIR/../../planning"
  "$OUT_DIR/../../docs"
  "$OUT_DIR/../../infra"
  "$OUT_DIR/../../ui"
  "$OUT_DIR/../../mobile"
)

for repo_dir in "${REPO_DIRS[@]}"; do
  if [[ -d "$repo_dir" ]] && git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    repo_name=$(basename "$repo_dir")
    echo "Repo: $repo_name" >>"$OUT_FILE"
    echo "User: $(git -C "$repo_dir" config --get user.name || whoami)" >>"$OUT_FILE"
    echo "Branch: $(git -C "$repo_dir" rev-parse --abbrev-ref HEAD || echo N/A)" >>"$OUT_FILE"
    echo "Last commit: $(git -C "$repo_dir" rev-parse --short HEAD || echo N/A)" >>"$OUT_FILE"

    # Limit changed files output to avoid huge lines
    changed=$(git -C "$repo_dir" status --porcelain | awk '{print $2}' | head -n 10 | paste -sd, - || echo '')
    count=$(git -C "$repo_dir" status --porcelain | wc -l | tr -d ' ')
    if [[ "$count" -gt 10 ]]; then
      changed="${changed}, ... ($((count - 10)) more)"
    fi

    echo "Files changed: ${changed}" >>"$OUT_FILE"
    echo "" >>"$OUT_FILE"
  else
    # Handle case where directory exists but isn't a git repo
    if [[ -d "$repo_dir" ]]; then
        echo "Repo: $(basename "$repo_dir") (not a git repo)" >>"$OUT_FILE"
    fi
  fi
done

# 4. Restore notes or add placeholders
echo "Active task: ${ACTIVE_TASK}" >>"$OUT_FILE"
echo "Next step: ${NEXT_STEP}" >>"$OUT_FILE"
echo "Relevant todos: planning/pii_vault_spike_checklist.md" >>"$OUT_FILE"
echo "Note: Edit this file with a short Active task & Next step summary before closing VS Code." >>"$OUT_FILE"

echo "Wrote $OUT_FILE"
