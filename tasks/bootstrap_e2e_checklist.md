# Bootstrap End-to-End Checklist

Cross-validation checklist for running the bootstrap cookbooks end-to-end.
Combines both [prepare_bootstrap_bundles.md](core/docs/cookbooks/prepare_bootstrap_bundles.md) and
[bootstrap_environments.md](core/docs/cookbooks/bootstrap_environments.md).

Items marked **🔲 DEFERRED** are newly implemented items from the bootstrap strengthening plan
that should also be validated during this run.

---

## Pre-Flight

- [ ] Conda env `i4g` is active
- [ ] Working directory is `core/`
- [ ] `gcloud auth login` and `gcloud auth application-default login` complete
- [ ] `gcloud config set project i4g-dev`
- [ ] `config/settings.local.toml` has Cloud SQL connection info (`[db_admin]` section)
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
- [ ] Verify case count is reasonable (expect hundreds, not thousands)

### 1.5 Upload golden bundle to GCS **🔲 DEFERRED**

- [ ] Run:
  ```bash
  gsutil -m rsync -r data/bundles/golden gs://i4g-dev-data-bundles/$RUN_DATE/golden/
  ```
- [ ] Verify upload: `gsutil ls gs://i4g-dev-data-bundles/$RUN_DATE/golden/`
- [ ] Confirm: `cases.jsonl`, `seed.sql`, `manifest.json` all present on GCS

## Part 2 — Bootstrap Local Environment

### 2.1 Backup current local state (safety net)

- [ ] Run:
  ```bash
  i4g db backup --env local
  ```
- [ ] Confirm archive created in `data/backups/`
- [ ] Note the archive path for rollback: `_________________`

### 2.2 Bootstrap local with golden bundle

- [ ] Run:
  ```bash
  I4G_BOOTSTRAP__USE_GOLDEN_BUNDLE=true I4G_ENV=local i4g bootstrap local reset
  ```
- [ ] Watch for errors in output — each step should complete cleanly:
  - [ ] Reset artifacts (wipe SQLite, Chroma, reports)
  - [ ] Apply Alembic migrations
  - [ ] Seed campaigns
  - [ ] Ingest JSONL bundles (skip-classification = on)
  - [ ] Apply seed SQL (campaigns, watchlists, graph edges, timeline, geography)
  - [ ] OCR processing (if Tesseract available, else skipped)
  - [ ] Rebuild manual demo
  - [ ] Seed review cases
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
  - [ ] Intelligence / Campaigns — populated
  - [ ] Intelligence / Graph — nodes and edges visible
  - [ ] Intelligence / Timeline — events across 6+ months
  - [ ] Intelligence / Watchlist — items and alerts
  - [ ] Impact / Geography — multiple countries

### 2.4 Test local restore flow **🔲 DEFERRED — Alembic revision validation**

- [ ] Run:
  ```bash
  i4g db restore --env local --from data/backups/<your_backup_file>.tar.gz
  ```
- [ ] Confirm: Alembic revision check printed (OK or mismatch warning)
- [ ] If mismatch: run `alembic upgrade head` then re-verify

## Part 3 — Bootstrap Dev Environment

> **⚠ HIGH RISK** — This wipes the shared dev database. Ensure no one else is actively using dev.

### 3.1 Backup dev database (critical safety net)

- [ ] Run:
  ```bash
  i4g db backup --env dev
  ```
- [ ] Note the dump file path: `_________________`
- [ ] Upload to GCS:
  ```bash
  gcloud storage cp <dump_path> gs://i4g-dev-data-bundles/backups/$(date +%Y%m%dT%H%M%SZ)/dump.sql.gz
  ```
- [ ] Confirm upload: `gsutil ls gs://i4g-dev-data-bundles/backups/`

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
- [ ] Wait for ingestion to complete (may take 30-60 min)

### 3.3 Verify dev (post-ingest)

- [ ] Wait ~10 min for classification_sweeper to run (or trigger manually):
  ```bash
  i4g jobs run classification-sweeper
  ```
- [ ] Wait for analytics_aggregation to run (or trigger manually):
  ```bash
  i4g jobs run analytics
  ```
- [ ] Check dev UI at `https://app.dev.intelligenceforgood.org`:
  - [ ] Dashboard shows cases
  - [ ] Campaigns page populated
  - [ ] Search returns results

### 3.4 Test dev restore flow **🔲 DEFERRED — Alembic revision validation**

- [ ] Run:
  ```bash
  i4g db restore --env dev \
    --from <backup_path>.sql.gz \
    --confirm yes-restore-dev
  ```
- [ ] Confirm: Alembic revision validation printed after restore
- [ ] If mismatch: `i4g db migrate dev`

## Part 4 — Deferred Items Validation

### 4.1 Backup job Docker image **🔲 DEFERRED**

- [ ] Build the image:
  ```bash
  make build-backup-dev
  ```
- [ ] Deploy the job:
  ```bash
  make deploy-backup-dev
  ```
- [ ] Test manually (optional — will run weekly via scheduler):
  ```bash
  gcloud run jobs execute backup-db --region us-central1 --project i4g-dev --wait
  ```
- [ ] Verify backup appeared:
  ```bash
  gsutil ls gs://i4g-dev-data-bundles/backups/
  ```

### 4.2 Terraform — backup scheduler **🔲 DEFERRED**

- [ ] After merging infra changes, apply Terraform:
  ```bash
  cd infra/environments/app/dev && make plan
  ```
- [ ] Review plan: should show new `backup-db` Cloud Run job + Cloud Scheduler
- [ ] Apply: `make apply`
- [ ] Verify scheduler: `gcloud scheduler jobs list --project i4g-dev --location us-central1`

### 4.3 Dev e2e smoke (full cycle) **🔲 DEFERRED**

- [ ] This is covered by Part 3 above — if Part 3 completes without errors, this item is satisfied

---

## Rollback Plan

If the dev environment is left in a broken state:

1. **Restore from backup:**

   ```bash
   i4g db restore --env dev \
     --from <backup_path>.sql.gz \
     --confirm yes-restore-dev
   ```

2. **If no backup exists, re-bootstrap from legacy bundles:**

   ```bash
   I4G_ENV=dev i4g bootstrap dev reset \
     --rate-limit-delay 0.5 \
     --timeout 10800
   ```

3. **If Cloud SQL is truly unrecoverable:**
   ```bash
   # Terraform will recreate the instance
   cd infra/environments/app/dev && make plan && make apply
   # Then re-run migrations and bootstrap
   i4g db migrate dev
   ```

---

## Post-Run

- [ ] Unset impersonation: `gcloud config unset auth/impersonate_service_account`
- [ ] Report any cookbook errors to fix documentation
- [ ] Update `planning/change_log.md` with bootstrap refresh date
