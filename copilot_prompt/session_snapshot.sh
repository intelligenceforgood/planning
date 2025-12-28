#!/usr/bin/env bash
set -euo pipefail

# Snapshot for planning/copilot_prompt
OUT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
OUT_FILE="$OUT_DIR/COPILOT_SESSION.md"
mkdir -p "$OUT_DIR"

# 1. Preserve existing notes if file exists
CONTENT=""
if [[ -f "$OUT_FILE" ]]; then
  # Preserve everything starting from the first Markdown header (## ...)
  # This handles the new format (Context, Active Task, Next Steps, Notes)
  CONTENT=$(awk '/^## / {p=1} p' "$OUT_FILE")
fi

# If no content found (e.g. old format or empty), provide default structure
if [[ -z "$CONTENT" ]]; then
    CONTENT="## Context
- Session started.

## Active Task
- [ ] Awaiting instructions.

## Next Steps
- [ ] TBD.

## Notes
"
fi

# 2. Start writing new file
echo "# Copilot Session Notes" >"$OUT_FILE"
echo "" >>"$OUT_FILE"
echo "Session timestamp: $(date -u '+%Y-%m-%d %H:%M UTC')" >>"$OUT_FILE"

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
    
    branch=$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD || echo N/A)
    user=$(git -C "$repo_dir" config --get user.name || whoami)
    
    echo "Repo: $repo_name | Branch: $branch | User: $user" >>"$OUT_FILE"

    # Limit changed files output to avoid huge lines
    changed=$(git -C "$repo_dir" status --porcelain | awk '{print $2}' | head -n 5 | paste -sd, - || echo '')
    count=$(git -C "$repo_dir" status --porcelain | wc -l | tr -d ' ')
    if [[ "$count" -gt 5 ]]; then
      changed="${changed}, ... ($((count - 5)) more)"
    fi
    
    if [[ -n "$changed" ]]; then
        echo "  Changed: ${changed}" >>"$OUT_FILE"
    fi
  fi
done

echo "" >>"$OUT_FILE"

# 4. Append preserved content
echo "$CONTENT" >>"$OUT_FILE"

echo "Wrote $OUT_FILE"
