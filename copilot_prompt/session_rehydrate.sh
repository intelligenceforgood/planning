#!/usr/bin/env bash
set -euo pipefail

IN_FILE="$(cd "$(dirname "$0")" && pwd -P)/COPILOT_SESSION.md"
if [[ ! -f "$IN_FILE" ]]; then
  echo "No session file found: $IN_FILE" >&2
  exit 1
fi
echo "===== Copilot Session Snapshot ====="
cat "$IN_FILE"
echo "===================================="

echo "Tip: Update the Active task and Next step fields before starting to help rehydrate Copilot."
