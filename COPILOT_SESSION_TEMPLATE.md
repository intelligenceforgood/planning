# Copilot session snapshot template

This file is a template for saving a short, consistent snapshot of the current working context so Copilot or an incoming developer can rehydrate quickly after a restart.

Fill this out before you close VS Code or end a long Copilot chat session. Keep it short (4-8 lines) and update the "Next step" area.

Session timestamp: <!-- YYYY-MM-DD HH:MM UTC -->
User: <!-- Name / email -->
Branch: <!-- git branch -->
Last commit: <!-- git commit hash -->
Files changed: <!-- comma-separated list (short) -->
Active task: <!-- 1-2 line summary of the current task -->
Next step: <!-- exact next command or file to edit -->
Relevant todos: <!-- path to a checklist or tasks (e.g., planning/pii_vault_spike_checklist.md) -->

Small reminders (optional):
- Tests to run: <!-- pytest files or commands -->
- External APIs: <!-- any service updates / secrets expected -->

---
Example:
Session timestamp: 2025-12-09 13:00 UTC
User: jerry.soung
Branch: main
Last commit: e7825b2
Files changed: infra/environments/pii-vault/dev/main.tf, infra/README.md
Active task: Add smoke script to test cross-project secret access
Next step: Add `infra/scripts/verify_vault_access.sh` and test with dev service account.
Relevant todos: planning/pii_vault_spike_checklist.md
---
