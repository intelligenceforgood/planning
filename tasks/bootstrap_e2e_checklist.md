# Bootstrap End-to-End Checklist

Cross-validation checklist for running the bootstrap cookbooks end-to-end.
Combines both [prepare_bootstrap_bundles.md](core/docs/cookbooks/prepare_bootstrap_bundles.md) and
[bootstrap_environments.md](core/docs/cookbooks/bootstrap_environments.md).

---

## Pre-Flight

- [ ] Conda env `i4g` is active
- [ ] Working directory is `core/`
- [ ] Set run date: `export RUN_DATE=$(date +%Y%m%d)`

## Part 1 — Prepare Bootstrap Bundles

### 1.1 Clean legacy Azure data

- [ ] Source data exists at `data/bundles/legacy_azure/`
- [ ] Run:
  ```bash
  python scripts/etl/clean_legacy_azure.py \
    --input data/bundles/legacy_azure \
    --output data/bundles/legacy_azure_clean/cases.jsonl
  ```
- [ ] Confirm output: `data/bundles/legacy_azure_clean/cases.jsonl` exists and has entries
- [ ] Review stdout for dropped records count — sanity check

### 1.2 ETL incident report responses

- [ ] CSV exported from Google Sheet to `data/exports/incident_responses.csv`
- [ ] Run:
  ```bash
  python scripts/etl/etl_incident_responses.py \
    --csv data/exports/incident_responses.csv \
    --output data/bundles/incident_responses/cases.jsonl
  ```
- [ ] Confirm output: `data/bundles/incident_responses/cases.jsonl` exists
- [ ] Spot-check: `head -2 data/bundles/incident_responses/cases.jsonl | python -m json.tool`

### 1.3 Synthesize golden seed SQL

- [ ] Run:
  ```bash
  python scripts/etl/synthesize_golden_data.py \
    --output data/bundles/golden_seed/seed.sql
  ```
- [ ] Confirm output: `data/bundles/golden_seed/seed.sql` exists
- [ ] Quick check: `grep -c 'INSERT INTO' data/bundles/golden_seed/seed.sql` shows reasonable count

### 1.4 Build consolidated golden bundle

- [ ] Run:
  ```bash
  i4g bootstrap build-golden-bundle \
    --bundles-dir data/bundles \
    --output-dir data/bundles/golden
  ```
- [ ] Confirm outputs exist:
  - [ ] `data/bundles/golden/cases.jsonl`
  - [ ] `data/bundles/golden/seed.sql`
  - [ ] `data/bundles/golden/manifest.json`
- [ ] Check manifest: `python -m json.tool data/bundles/golden/manifest.json`
- [ ] Verify case count: `wc -l data/bundles/golden/cases.jsonl` (expect ~1200)

### 1.5 Upload golden bundle to GCS (optional)

- [ ] Run:
  ```bash
  gsutil -m rsync -r data/bundles/golden gs://i4g-dev-data-bundles/$RUN_DATE/golden/
  ```
- [ ] Verify upload: `gsutil ls gs://i4g-dev-data-bundles/$RUN_DATE/golden/`

## Part 2 — Bootstrap Local Environment

### 2.1 Backup current local state (safety net)

- [ ] Run: `i4g db backup --env local`
- [ ] Confirm archive created in `data/backups/`

### 2.2 Bootstrap local with golden bundle

- [ ] Run:
  ```bash
  i4g bootstrap local reset
  ```
- [ ] Watch for errors. Each step should complete:
  - [ ] Reset artifacts (wipe SQLite, Chroma, reports)
  - [ ] Apply Alembic migrations
  - [ ] Seed campaigns
  - [ ] Fast-ingest golden bundle (cases, entities, indicators)
  - [ ] Apply seed SQL (campaigns, watchlists, graph edges, timeline, geography)
  - [ ] OCR processing (if Tesseract available, else skipped)
  - [ ] Rebuild manual demo
  - [ ] Seed review cases
  - [ ] **Analytics aggregation** (entity_stats, indicator_stats, campaign_stats)
  - [ ] Verify sandbox

### 2.3 Verify local sandbox

- [ ] Run verification:
  ```bash
  i4g bootstrap local verify --smoke-search --smoke-dossiers
  ```
- [ ] Check reports: `ls data/reports/bootstrap_local/`
- [ ] Start dev server: `uvicorn i4g.api.app:app --reload`
- [ ] Spot-check UI pages (if UI is running):
  - [ ] Dashboard — shows cases
  - [ ] Intelligence / Campaigns — 7 campaigns with stats
  - [ ] Intelligence / Indicators — has entries (from incident responses with entities)
  - [ ] Intelligence / Graph — nodes and edges visible
  - [ ] Intelligence / Watchlist — items and alerts
  - [ ] Impact / Geography — multiple countries

### 2.4 Post-bootstrap backfill (optional)

- [ ] Check pending work: `i4g backfill status`
- [ ] Run classification (slow — LLM calls): `i4g backfill run classify`
- [ ] Refresh analytics after classification: `i4g backfill run analytics`

## Part 3 — Bootstrap Dev Environment

> **⚠ HIGH RISK** — This wipes the shared dev database. Ensure no one else is actively using dev.

### 3.1 Backup dev database (critical safety net)

- [ ] Run: `i4g db backup --env dev`
- [ ] Upload to GCS:
  ```bash
  gcloud storage cp <dump_path> gs://i4g-dev-data-bundles/backups/$(date +%Y%m%dT%H%M%SZ)/dump.sql.gz
  ```

### 3.2 Bootstrap dev with golden bundle

- [ ] Impersonate infra SA:
  ```bash
  gcloud config set auth/impersonate_service_account sa-infra@i4g-dev.iam.gserviceaccount.com
  ```
- [ ] Run:
  ```bash
  I4G_ENV=dev i4g bootstrap dev reset \
    --rate-limit-delay 0.5 \
    --timeout 10800 \
    --run-smoke \
    --run-dossier-smoke \
    --run-search-smoke
  ```
- [ ] Monitor Cloud Run job logs in GCP Console for errors

### 3.3 Verify dev (post-ingest)

- [ ] Wait ~10 min for classification_sweeper (or trigger manually): `i4g jobs run classification-sweeper`
- [ ] Wait for analytics_aggregation (or trigger manually): `i4g jobs analytics`
- [ ] Check dev UI at `https://app.dev.intelligenceforgood.org`:
  - [ ] Dashboard shows cases
  - [ ] Campaigns page populated
  - [ ] Search returns results

---

## Rollback Plan

If the dev environment is left in a broken state:

1. **Restore from backup:**

   ```bash
   i4g db restore --env dev --from <backup_path>.sql.gz --confirm yes-restore-dev
   ```

2. **If no backup exists, re-bootstrap:**
   ```bash
   I4G_ENV=dev i4g bootstrap dev reset --rate-limit-delay 0.5 --timeout 10800
   ```

---

## Post-Run

- [ ] Unset impersonation: `gcloud config unset auth/impersonate_service_account`
- [ ] Report any cookbook errors to fix documentation
- [ ] Update `planning/change_log.md` with bootstrap refresh date
