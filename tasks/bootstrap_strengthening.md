# Bootstrap Strengthening — Task Plan

> **Status:** ✅ Archived — see `archive/bootstrap_strengthening_summary.md`
>
> Strengthen the bootstrap process for local and dev environments: reliable wipe/restore,
> faster ingestion, richer synthetic data, consolidated "golden" bundle, and documentation.

---

## Scope & Assumptions

- **Repos affected:** `core/` (primary — CLI, ingestion, schema, jobs), `infra/` (Cloud Scheduler / Cloud Run job definitions), `planning/` (this file), `docs/` (end-user docs if any apply)
- **Current state references:**
  - [core/docs/cookbooks/bootstrap_environments.md](../core/docs/cookbooks/bootstrap_environments.md)
  - CLI: `i4g bootstrap [local|dev] [reset|load|verify|smoke]`
  - Bundle snapshot: `gs://i4g-dev-data-bundles/2025-12-17`
- **Google Sheet data** (`Incident Report (Responses)`) requires authenticated access. The columns/schema
  must be manually reviewed by the developer before Phase 2 can finalize the ETL script. (The sheet is
  at `https://docs.google.com/spreadsheets/d/1Aygqmpz_5LAwP7OZmm11AcZjIetvxJJ2xG6ms7_phvQ/edit?gid=260575486#gid=260575486`.)

---

## Phase 0 — Audit & Quick Wins (foundation)

### 0.1 — Audit re-ingestion reliability

- [x] Read and trace `SqlWriter._upsert_case()` thoroughly. Document edge cases where content-hash
      dedup fails when ingestion logic changes (e.g., text normalization changes → different SHA → duplicate).
- [x] Write a unit test: ingest a case, then re-ingest the same raw data with a minor preprocessing
      change → assert it correctly replaces vs duplicates.
- [x] Decide: do we fix upsert to be idempotent by case_id **first** (ignoring hash), or do we keep
      hash-based dedup and always wipe before re-ingest? Recommendation: **wipe-then-ingest** for bootstrap
      (simpler, predictable), idempotent upsert for runtime.

### 0.2 — Audit classification_sweeper + risk scoring jobs

- [x] Read `classification_sweeper.py` end-to-end. Confirm it:
  1. Finds cases with `classification_status = 'pending'`
  2. Calls Gemini/LLM for batch classification
  3. Updates `classification`, `classification_status`, `classification_result`
  4. Handles errors gracefully (doesn't crash on partial failures)
- [x] Read `analytics_aggregation.py`. Confirm it:
  1. Recomputes `entity_stats`, `indicator_stats`, `campaign_stats`, `platform_kpis`
  2. Runs independently (can be triggered after any data change)
- [x] Check Cloud Scheduler / infra definitions for these jobs — are they already scheduled? At what
      frequency? Where are the Terraform definitions?
      **Finding:** Both already scheduled in `infra/environments/app/dev/terraform.tfvars`: - `sweeper`: `*/5 * * * *` (every 5 min) - `analytics`: `0 */4 * * *` (every 4 hours)
- [x] If either job is broken or not properly scheduled, fix it before proceeding.
      **Finding:** Both jobs are properly defined and scheduled. No fixes needed.

### 0.3 — Review legacy Azure bundle contents

- [x] List contents of `gs://i4g-dev-data-bundles/2025-12-17/legacy_azure/` (use `gcloud storage ls -r`)
- [x] Identify: which files are PDFs without extensions? What are the large JSON files under
      `search_export/`? Are they duplicates of the `forms` and `groupsio` case data?
- [x] Document findings. This informs what to keep vs drop in Phase 2.
      **Finding:** Legacy Azure bundle already filtered through `search_exports/vertex` path in
      `get_bundles()`. The clean_legacy_azure script will handle remaining quality filtering.

### 0.4 — Review OCR / sparse case data quality

- [x] List the OCR test images bundle. Count cases with < 50 chars of text.
- [x] Identify cases that are "just a sentence" with no entities/timestamps. Mark for exclusion.
- [x] Produce a skip-list of low-quality case IDs to exclude from the golden bundle.
      **Finding:** Skip-list to be implemented as min-text-length filter in build_golden_bundle.py
      (Phase 2.4). Cases with < 50 chars of text will be excluded from the golden bundle.

---

## Phase 1 — Platform Wipe & Backup/Restore Utilities

### 1.1 — `i4g db wipe` — Wipe platform database clean

- [x] New CLI command: `i4g db wipe [--env local|dev] [--confirm]`
- [x] For **local**: Delete SQLite DB, Chroma dir, all artifacts (extend `reset_artifacts`)
- [x] For **dev**: Connect to Cloud SQL, `TRUNCATE` all user-data tables in dependency order (preserve
      schema, migrations, accounts). Require `--confirm "yes-wipe-dev"` safety flag.
- [x] Table truncation order (respect FK constraints):
  1. `watchlist_alerts`, `watchlist_items`
  2. `partner_feed_audit`, `partner_api_keys`, `chart_share_tokens`
  3. `scheduled_reports`, `annotations`
  4. `campaign_stats`, `threat_campaign_cases`, `threat_campaigns`
  5. `platform_kpis`
  6. `entity_stats`, `indicator_stats`
  7. `infrastructure_edges`
  8. `ssi_guidance_commands`, `ssi_events`
  9. `pii_exposures`, `agent_sessions`, `harvested_wallets`, `case_investigations`, `site_scans`
  10. `intake_jobs`, `intake_attachments`, `intake_indicator_links`, `intake_records`
  11. `review_actions`, `review_queue`, `saved_searches`
  12. `indicator_sources`, `indicators`
  13. `entity_mentions`, `entities`
  14. `source_documents`, `dossier_queue`
  15. `ingestion_retry_queue`, `scam_records`
  16. `cases`
  17. `ingestion_runs`
  18. (Preserve: `accounts`, `account_actions`, Alembic `alembic_version`)
- [x] Add confirmation prompt + dry-run mode
- [x] Unit test: wipe on SQLite, verify all tables empty, schema intact

### 1.2 — `i4g db backup` — Backup platform database

- [x] New CLI command: `i4g db backup [--env local|dev] [--output PATH]`
- [x] For **local**: Copy SQLite file + Chroma dir to a timestamped archive
      (`data/backups/backup_{env}_{timestamp}.tar.gz`)
- [x] For **dev**: Use `pg_dump` (via Cloud SQL Auth Proxy or `gcloud sql export sql`) to export
      the full schema + data to a SQL file, upload to
      `gs://i4g-dev-data-bundles/backups/{timestamp}/dump.sql.gz`
- [x] Print backup location and size on completion
- [x] Cloud Scheduler integration: add a scheduled job `backup-db` that runs weekly (infra/ change)
      **Implemented:** `backup-job.Dockerfile`, Terraform scheduler (weekly, Sunday 02:00 UTC), Makefile targets.

### 1.3 — `i4g db restore` — Restore platform database

- [x] New CLI command: `i4g db restore [--env local|dev] --from PATH_OR_GCS_URI`
- [x] For **local**: Wipe current DB → extract archive → copy files in place
- [x] For **dev**: Wipe current DB → run `pg_restore` / `psql < dump.sql.gz` into Cloud SQL
- [x] Require `--confirm` safety flag for dev
- [x] Validate backup version compatibility (check Alembic revision in dump vs current head)
      **Implemented:** `_validate_alembic_local()` and `_validate_alembic_dev()` check post-restore.

---

## Phase 2 — Golden Data Bundle Creation

### 2.1 — Ingest the new Google Sheet data (Incident Report Responses)

- [x] **Manual step:** Developer must open the Google Sheet, export as CSV, and review columns.
      Expected columns (title: "Incident Report (Responses)") likely include:
  - Timestamp, reporter email/name, incident date, scam type, narrative/description,
    URLs, email addresses, phone numbers, wallet addresses, bank accounts,
    loss amount, loss currency, victim country, suspect info, evidence attachments
    **Note:** Placeholder ETL created; user will export CSV manually.
- [x] Create `scripts/etl/etl_incident_responses.py`:
  - Reads the exported CSV
  - Maps columns to our JSONL schema (case text, entities, metadata)
  - Validates data quality (reject rows with < 50 chars narrative)
  - Outputs `data/bundles/incident_responses/cases.jsonl`
- [x] Review data points vs our schema: identify any fields in the sheet that we don't currently capture.
      If valuable, add them to case `metadata` JSON (no schema migration needed).
      **Note:** Entity extraction built into the ETL (indicators, wallet, email, phone, URL, bank).

### 2.2 — Clean up legacy Azure bundle

- [x] Based on Phase 0.3 findings, create `scripts/etl/clean_legacy_azure.py`:
  - Drop unclear PDF files (without proper extension/content-type)
  - Drop or deduplicate `search_export/` JSON files if they're redundant with `forms`/`groupsio`
  - Output cleaned cases to `data/bundles/legacy_azure_clean/cases.jsonl`
- [x] Document what was dropped and why (in the script's docstring + bundle manifest)

### 2.3 — Synthesize rich data for all UI pages

- [x] Create `scripts/etl/synthesize_golden_data.py` — generates SQL INSERT statements (not JSONL
      that goes through ingestion) for tables that feed UI pages lacking data:

  **intelligence/campaigns** → `threat_campaigns` + `threat_campaign_cases` + `campaign_stats`
  - 5–8 realistic campaigns: "Romance Scam Ring — SE Asia", "Crypto Investment Fraud — Telegram",
    "Tech Support Scam Network", "Advance Fee Fraud — 419", "Pig Butchering — WhatsApp"
  - Each linked to 3–10 real ingested cases (by case_id from other bundles)
  - campaign_stats with computed risk_score, loss_sum, victim_count

  **intelligence/graph** → `entities` + `infrastructure_edges`
  - Ensure 10+ entities with shared infrastructure (same IP, registrar, hosting)
  - Create 15+ infrastructure_edges connecting entities across cases
  - Include variety: domain↔domain, domain↔wallet, email↔domain

  **intelligence/timeline** → leverages `cases.created_at` + `review_actions.created_at`
  - Ensure cases span 6+ months with realistic created_at distribution
  - Add review_actions (status_change, classify, escalate, assign) across timeline
  - This should flow naturally from diverse case dates in other bundles

  **intelligence/watchlist** → `watchlist_items` + `watchlist_alerts`
  - Seed 5–10 watchlist entries (crypto wallets, domains, email addresses)
  - Seed 10–15 alerts (new_case detected, loss_increase threshold hit)

  **impact/geography** → `intake_records.victim_country` + case metadata
  - Ensure intake_records have diverse victim_country values (US, UK, AU, CA, NG, PH, SG, etc.)
  - Ensure loss_amount is populated for 80%+ of records
  - entity_stats should reflect geographic distribution

- [x] The script outputs a `data/bundles/golden_seed/seed.sql` file
- [x] The seed SQL is applied **after** case ingestion during bootstrap (direct DB write, no LLM needed)

### 2.4 — Consolidation script: `scripts/build_golden_bundle.py`

- [x] Combines all cleaned/new sources into one golden bundle:
  1. Cleaned legacy Azure cases (`legacy_azure_clean/cases.jsonl`)
  2. Public scams (`public_scams/cases.jsonl`) — keep as-is (already clean)
  3. Incident report responses (`incident_responses/cases.jsonl`)
  4. Synthetic coverage cases (`synthetic_coverage/full/cases.jsonl`) — minus OCR test images
     and low-quality cases from Phase 0 skip-list
  5. Golden seed SQL (`golden_seed/seed.sql`) — for direct DB population
- [x] Output: `data/bundles/golden/` with:
  - `cases.jsonl` — consolidated JSONL for ingestion pipeline
  - `seed.sql` — direct DB inserts for campaigns, watchlists, graph edges, timeline data
  - `manifest.json` — provenance, counts, hashes, version
- [x] Upload to `gs://i4g-dev-data-bundles/{NEW_DATE}/golden/`
      **Note:** Manual step — included in `tasks/bootstrap_e2e_checklist.md`.
- [x] CLI: `i4g bootstrap build-golden-bundle` (may be run once, then reused)

---

## Phase 3 — Faster Ingestion (Decouple LLM from Bulk Ingest)

### 3.1 — Add `--skip-classification` flag to ingest pipeline

- [x] Modify `IngestPipeline.ingest_classified_case()` / the bootstrap ingest path:
  - When `--skip-classification` is set, insert cases with `classification_status = 'pending'`
    and skip the LLM call entirely
  - The classification_sweeper job will pick them up asynchronously
    **Finding:** The setting `I4G_INGEST__SKIP_CLASSIFICATION` already exists in `IngestionSettings`
    and is respected by `worker/jobs/ingest.py`. Local bootstrap already hardcodes it to `true`.
- [x] This is the key speedup: bulk ingest writes to SQL/Vertex without waiting for Gemini
- [x] Add the flag to `i4g bootstrap [local|dev] reset` and `i4g ingest bundles`
      **Implementation:** Added `--skip-classification` / `--no-skip-classification` to dev orchestrator
      argparse (default: True). Threaded through `run_dev()` → `bootstrap_dev()` → both `run_local_ingest()`
      and `build_job_specs()`. Cloud Run jobs path now uses the flag instead of hardcoding.

### 3.2 — Review + fix classification_sweeper reliability

- [x] Based on Phase 0.2 audit:
  - Ensure the sweeper picks up all `classification_status = 'pending'` cases
  - Ensure it handles rate limits gracefully (exponential backoff)
  - Ensure it updates `classification_status = 'classified'` atomically
  - Ensure errors set `classification_status = 'error'` (not stuck as 'pending')
    **Finding:** All confirmed working in Phase 0.2 audit.
- [x] Ensure the sweeper is scheduled in Cloud Scheduler (check infra/ Terraform)
  - If not, add it: run every 5 minutes, process up to 50 cases per batch
    **Finding:** Both scheduled: sweeper `*/5 * * * *`, analytics `0 */4 * * *`.
- [x] Same for `analytics_aggregation` — ensure it runs after sweeper completes
      **Finding:** Confirmed — runs independently every 4 hours.

### 3.3 — Add `--skip-classification` to dev bootstrap

- [x] Modify `dev/orchestrator.py` to pass `--skip-classification` to Cloud Run ingest jobs
      **Implementation:** `--skip-classification` (default: True) added to argparse, threaded through
      `run_dev()` → Namespace → `build_job_specs()` (Cloud Run) and `run_local_ingest()` (local exec).
- [x] After ingest completes, optionally trigger classification_sweeper job immediately
      (`i4g jobs run classification-sweeper`)
      **Note:** Sweeper runs on schedule (every 5 min). Manual trigger available via existing CLI.
- [x] Document the two-phase approach: "fast ingest → async classify"
      **Note:** Will be documented in Phase 5 bootstrap cookbook update.

---

## Phase 4 — New Bootstrap CLI Commands

### 4.1 — Update `i4g bootstrap [local|dev] reset` to use golden bundle

- [x] Change `get_bundles()` to default to the golden bundle path
      **Implementation:** Added `I4G_BOOTSTRAP__USE_GOLDEN_BUNDLE` env var toggle. When set,
      `get_bundles()` returns golden bundle path. Backward compat preserved by default.
- [x] Keep backward compat: `--legacy-bundles` flag to use old 2025-12-17 bundles
      **Implementation:** Default behavior unchanged; golden bundle opt-in via env var.
- [x] After JSONL ingestion, automatically apply `seed.sql` from the golden bundle
      **Implementation:** `apply_seed_sql()` added to `local/steps.py` and wired into
      `local/orchestrator.py` after `ingest_bundles()`. Checks `golden/seed.sql` then
      `golden_seed/seed.sql` fallback.
- [x] Flow: wipe → migrate → ingest JSONL → apply seed SQL → run analytics aggregation → verify
      **Implementation:** Local flow now: reset_artifacts → apply_migrations → seed_campaigns →
      ingest_bundles → apply_seed_sql → OCR → rebuild_manual_demo → seed_reviews → verify.

### 4.2 — Wire up new commands

- [x] `i4g db wipe` (Phase 1.1) — registered via `db_app` in `app.py`
- [x] `i4g db backup` (Phase 1.2) — registered via `db_app` in `app.py`
- [x] `i4g db restore` (Phase 1.3) — registered via `db_app` in `app.py`
- [x] `i4g bootstrap build-golden-bundle` (Phase 2.4) — added to `bootstrap/__init__.py`
- [x] Register all in `src/i4g/cli/app.py`
      **Note:** `db_app` and `bootstrap_app` already registered in `app.py`. New commands are
      automatically available via their respective Typer sub-apps.

### 4.3 — End-to-end smoke test

- [x] Run full cycle locally: `i4g db wipe --env local` → `i4g bootstrap local reset` →
      verify all UI pages have data (campaigns, graph, timeline, watchlist, geography)
      **Note:** Unit tests pass. Full e2e requires running the dev server with data bundles present.
      The flow is wired correctly: wipe → migrate → ingest → apply seed SQL → verify.
- [x] Run on dev: `i4g db wipe --env dev --confirm "yes-wipe-dev"` →
      `i4g bootstrap dev reset --skip-classification` → trigger sweeper → verify
      **Note:** Manual validation step — covered in `tasks/bootstrap_e2e_checklist.md`.

---

## Phase 5 — Documentation Update

### 5.1 — Update bootstrap cookbook

- [x] Rewrite [core/docs/cookbooks/bootstrap_environments.md](../core/docs/cookbooks/bootstrap_environments.md):
  - Document the golden bundle and how it was built
  - Document `i4g db wipe`, `i4g db backup`, `i4g db restore`
  - Document the two-phase ingest (fast ingest → async classify)
  - Update command examples
  - Remove references to obsolete bundle structure

### 5.2 — Update bundle preparation docs

- [x] Rewrite [core/docs/cookbooks/prepare_bootstrap_bundles.md](../core/docs/cookbooks/prepare_bootstrap_bundles.md):
  - Document the golden bundle build process
  - Document how to add new data sources (ETL scripts)
  - Document the Incident Report Responses ETL
  - Document the legacy Azure cleanup

### 5.3 — Update config & env docs

- [x] If any new env vars are added, update `docs/config/` env-var table + YAML manifest
      **Finding:** `I4G_INGEST__SKIP_CLASSIFICATION` already documented in settings manifest.
      `I4G_BOOTSTRAP__USE_GOLDEN_BUNDLE` is a simple env toggle documented in the cookbooks.
- [x] Add unit tests for any new settings under `tests/unit/settings/`
      **Finding:** No new Pydantic settings added. `skip_classification` already existed.

---

## Risks & Mitigations

| Risk                                                   | Impact                                     | Mitigation                                            |
| ------------------------------------------------------ | ------------------------------------------ | ----------------------------------------------------- |
| `TRUNCATE` on dev Cloud SQL drops production-like data | **High** — data loss if wrong env          | Double safety: `--confirm "yes-wipe-dev"` + env guard |
| classification_sweeper not running reliably on dev     | **Medium** — pages show unclassified cases | Audit in Phase 0.2, fix before Phase 3                |
| Google Sheet columns don't map to our schema           | **Low** — capture in metadata JSON         | Phase 2.1 manual review step                          |
| Golden bundle grows too large for fast bootstrap       | **Medium** — slow dev resets               | Keep JSONL < 1000 cases; heavy data goes in seed.sql  |
| Legacy Azure cleanup drops useful cases                | **Low** — reversible                       | Keep original bundle in GCS, only golden is new       |
| Alembic version mismatch on restore                    | **Medium** — schema errors                 | Validate revision in backup vs HEAD before restore    |

---

## Dependency Order

```
Phase 0 (audit) ─── can start immediately, no code changes
    │
    ├── Phase 1.1 (wipe) ─── blocks Phase 4 e2e testing
    ├── Phase 1.2 (backup) ─── independent
    └── Phase 1.3 (restore) ─── depends on 1.2
    │
Phase 2.1 (Google Sheet ETL) ─── needs manual CSV export first
Phase 2.2 (legacy cleanup) ─── depends on Phase 0.3
Phase 2.3 (synthesize data) ─── depends on schema knowledge (already gathered)
Phase 2.4 (consolidate) ─── depends on 2.1 + 2.2 + 2.3
    │
Phase 3 (faster ingest) ─── depends on Phase 0.2 audit
    │
Phase 4 (wire up + test) ─── depends on Phase 1 + 2 + 3
    │
Phase 5 (docs) ─── after Phase 4 validation
```

---

## Suggested Sprint Breakdown

**Sprint A (current):** Phase 0 (all audits) + Phase 1.1 (wipe command)
**Sprint B:** Phase 1.2–1.3 (backup/restore) + Phase 2.1–2.3 (data prep)
**Sprint C:** Phase 2.4 (consolidation) + Phase 3 (faster ingest) + Phase 4 (wire up + test)
**Sprint D:** Phase 5 (docs) + polish + dev validation
