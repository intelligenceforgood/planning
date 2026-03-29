# Bootstrap Strengthening Summary

**Completed:** 2026-03-29
**Source Plan:** `tasks/bootstrap_strengthening.md`

---

## What Was Built

Strengthened the bootstrap process for local and dev environments: reliable wipe/restore, faster ingestion, richer synthetic data, consolidated "golden" bundle, and comprehensive documentation.

### Database Utilities (Phase 1)

- **`i4g db wipe`** — Wipe platform database. Local: deletes SQLite + Chroma + artifacts. Dev: TRUNCATE all user-data tables (42 tables in FK-safe dependency order) with `--confirm "yes-wipe-dev"` safety. `--dry-run` preview mode.
- **`i4g db backup`** — Local: tar.gz of SQLite + Chroma → `data/backups/`. Dev: `pg_dump` via cloud-sql-proxy → gzip.
- **`i4g db restore`** — Local: wipe → extract archive. Dev: wipe → `psql` restore. Includes Alembic revision validation post-restore (warns on mismatch, suggests `alembic upgrade head`).
- **`backup-db` Cloud Run job** — Scheduled weekly (`0 2 * * 0`). Dedicated Docker image with `postgresql-client` + `cloud-sql-proxy`. Runs `pg_dump` with IAM auth, gzips, uploads to `gs://i4g-{env}-data-bundles/backups/{timestamp}/dump.sql.gz`. Terraform + Makefile targets for both dev (active) and prod (paused).

### Golden Data Bundle (Phase 2)

- **ETL scripts** — `clean_legacy_azure.py` (min 50-char text, SHA-256 dedup), `etl_incident_responses.py` (Google Sheet CSV → JSONL with entity extraction), `synthesize_golden_data.py` (SQL INSERTs for campaigns, graph edges, watchlists, review queue, intake records across 15 countries).
- **`i4g bootstrap build-golden-bundle`** — Consolidates all cleaned sources into `data/bundles/golden/{cases.jsonl, seed.sql, manifest.json}`.
- **Seed SQL** — Direct DB inserts for: 7 campaigns, 40 campaign-case links, 15 infrastructure edges, watchlist items + alerts, review queue entries — all `ON CONFLICT DO NOTHING` for safety.

### Faster Ingestion (Phase 3)

- **Two-phase approach** — Fast ingest writes cases with `classification_status = 'pending'` (no LLM calls). Classification sweeper picks them up asynchronously (every 5 min). Analytics aggregation runs every 4 hours.
- **`--skip-classification` flag** — Threaded through CLI, local orchestrator, and dev orchestrator (Cloud Run job specs). Default: on for local, configurable for dev.

### CLI & Integration (Phase 4)

- All new commands registered via `db_app` and `bootstrap_app` Typer sub-apps.
- Local bootstrap flow updated: reset → migrate → seed campaigns → ingest JSONL → apply seed SQL → OCR → rebuild demo → seed reviews → verify.
- `I4G_BOOTSTRAP__USE_GOLDEN_BUNDLE` env var toggle for golden vs legacy bundles.

### Documentation (Phase 5)

- **`prepare_bootstrap_bundles.md`** — Complete rewrite covering golden bundle build process, ETL scripts, GCS upload, adding new data sources, and legacy bundle reference.
- **`bootstrap_environments.md`** — Complete rewrite covering golden bundle, two-phase ingestion, database management (wipe/backup/restore), local + dev bootstrap recipes, partial rebuilds, verification, and job reference.

## Deferred Items (addressed)

| Item                                   | Resolution                                                                                                 |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Cloud Scheduler backup job             | Implemented: `backup-job.Dockerfile`, Terraform (dev active, prod paused at `0 2 * * 0`), Makefile targets |
| Alembic revision validation in restore | Implemented: both local (SQLite read) and dev (psycopg2 query) validate post-restore                       |
| Dev e2e smoke                          | Requires manual run — covered in `tasks/bootstrap_e2e_checklist.md`                                        |
| GCS upload of golden bundle            | Manual step — included in e2e checklist                                                                    |

## Files Changed

### `core/`

- `src/i4g/cli/db/__init__.py` — wipe, backup, restore commands; Alembic revision validation
- `src/i4g/cli/jobs/__init__.py` — `backup-db` job command
- `src/i4g/cli/bootstrap/` — golden bundle support, skip-classification, seed SQL application
- `src/i4g/worker/jobs/backup_db.py` — Cloud Run backup job worker
- `docker/backup-job.Dockerfile` — backup job container
- `scripts/etl/` — ETL scripts (clean_legacy_azure, etl_incident_responses, synthesize_golden_data)
- `scripts/build_golden_bundle.py` — bundle consolidation
- `docs/cookbooks/prepare_bootstrap_bundles.md` — full rewrite
- `docs/cookbooks/bootstrap_environments.md` — full rewrite
- `tests/unit/test_db_wipe.py` — wipe command unit tests
- `tests/unit/test_sql_writer.py` — re-ingestion dedup tests
- `Makefile` — backup job build/deploy targets

### `infra/`

- `environments/app/dev/terraform.tfvars` — `backup_db` Cloud Run job + scheduler
- `environments/app/prod/terraform.tfvars` — `backup_db` Cloud Run job + scheduler (paused)

### `planning/`

- `tasks/bootstrap_e2e_checklist.md` — end-to-end validation checklist with deferred items
