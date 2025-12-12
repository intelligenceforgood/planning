# Rename Plan: proto → core

Use this checklist to migrate the platform repo from `proto` to `core` and update all dependents.

## Decisions
- Preserve history by renaming repo (preferred). If new repo with clean history is chosen, tasks remain the same but expect to rewire CI secrets and lose blame.
- Image/name convention: retag/publish as `core` (e.g., `core-fastapi`, `core-worker`).

## Prep
- [x] Rename local folder `proto/` → `core/`; update remote origin URL to new repo.
- [x] Update default branch protections, required checks, badges to new repo name.
- [x] Announce rename in change log(s).

## Core repo updates (former proto)
- [x] Update README and any in-repo paths/links that spell `proto`.
- [x] Update examples mentioning `I4G_PROJECT_ROOT` path or `proto/` folder.
- [x] Adjust docker image tags, Makefile targets, scripts that reference `proto` or `fastapi-gateway` image names (if they include repo prefix).

## Cross-repo updates
- **planning**
  - [x] Update roadmap/change_log and any instructions referencing `proto` paths.
  - [x] Update copilot prompt files that mention `proto` as the main repo.
- **docs**
  - [x] Search/replace `proto/` links in markdown (architecture, API, config refs) → `core/`.
  - [x] Refresh docs/book references so GitBook/Honkit sources no longer point at `proto/`.
  - [x] Update any code links pointing to `proto` GitHub paths (search found none remaining).
- **infra**
  - [x] Update Terraform locals/vars that reference `proto` image/repo names.
  - [x] Update Cloud Run image names/paths if tagged with `proto`.
  - [x] Update CI/CD pipelines or Actions that `git clone` `proto` (search found no remaining references).
- **ui**
  - [x] Update docs and scripts that point to `proto` for API references.
  - [x] Update any environment examples that assume `proto` path on disk.
- **mobile**
  - [x] Update docs/scripts that reference `proto`.

## CI/CD and Automation
- [x] Update GitHub Actions (checkout paths, cache keys, badges) to new repo name (search found no remaining `proto`).
- [x] Update release pipelines and artifact names (docker tags, archives) if they embed `proto` (no remaining `proto` tags found).
- [x] Update PR templates/issue templates mentioning `proto` (no templates present with `proto`).

## Runtime/Config
- [x] Update default config samples (env vars, paths) that include `proto`.
- [x] Update docs pointing to `proto` data directories.
- [x] Flip `API_KIND` and related env examples from `proto` to `core` across shared docs/configs.

## Verification
- [x] Run link check across docs after replacements (markdown-link-check on docs/book/SUMMARY.md).
- [x] Rebuild/publish images under new names and update Cloud Run services.
- [x] Smoke test core services after retag/deploy.
