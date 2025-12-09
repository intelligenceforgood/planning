# Copilot Rehydration Workflow

This document describes a simple, low-friction workflow to persist the key session context for GitHub Copilot Chat so you can rehydrate your session after a restart.

1) Keep one active file for rehydration
 - `planning/copilot_prompt/COPILOT_SESSION.md` — short snapshot used to rehydrate Copilot after a restart.

2) Save the session summary before you close VS Code
 - Run the helper that gathers context and writes a short snapshot (preferred via Make):

```bash
make save-session
```

If you are running from the repository root, use:

```bash
make -C planning/copilot_prompt save-session
```

3) Edit `planning/copilot_prompt/COPILOT_SESSION.md` and update the `Active task` and `Next step` lines.
 - Keep them short and actionable (one or two lines). Example: `Next step: Add smoke script infra/scripts/verify_vault_access.sh and run local smoke test`.

4) Rehydrate after restart
 - Run the session rehydrate helper to show the short snapshot (preferred via Make):

```bash
make rehydrate
```

From the repository root:

```bash
make -C planning/copilot_prompt rehydrate
```

5) Optional automation — commit the snapshot (if you want it as part of the repo history) or stash changes and commit before starting a large change.

Notes:
 - This approach intentionally uses a repo-checked file so Copilot can read it on rehydrate and also to ensure the context persists across machine restarts or VS Code crashes.
 - Use `git stash` to save temporary edits and re-apply after rehydrating if you have unfinished changes you do not want to commit.
````markdown
# Copilot Rehydration Workflow

This document describes a simple, low-friction workflow to persist the key session context for GitHub Copilot Chat so you can rehydrate your session after a restart.

1) Keep one active file for rehydration
 - `planning/copilot_prompt/COPILOT_SESSION.md` — short snapshot used to rehydrate Copilot after a restart.

2) Save the session summary before you close VS Code
 - Run the helper that gathers context and writes a short snapshot:

```bash
session_snapshot.sh
```

3) Edit `planning/copilot_prompt/COPILOT_SESSION.md` and update the `Active task` and `Next step` lines.
 - Keep them short and actionable (one or two lines). Example: `Next step: Add smoke script infra/scripts/verify_vault_access.sh and run local smoke test`.

4) Rehydrate after restart
 - Run the session rehydrate helper to show the short snapshot:

```bash
session_rehydrate.sh
```

5) Optional automation — commit the snapshot (if you want it as part of the repo history) or stash changes and commit before starting a large change.

Notes:
 - This approach intentionally uses a repo-checked file so Copilot can read it on rehydrate and also to ensure the context persists across machine restarts or VS Code crashes.
 - Use `git stash` to save temporary edits and re-apply after rehydrating if you have unfinished changes you do not want to commit.

````
