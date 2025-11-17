# Azure → GCP Migration Runbooks (Draft)

_Last updated: 16 Nov 2025_

These runbooks outline the phased process for migrating DT-IFG workloads from Azure to the i4g Google Cloud Platform stack. Each section can be executed independently as data, services, or infrastructure become ready. Update this document as plans firm up during Milestone 3 and 4.

## 0. Quick Plan (High-Level Sketch)
- **Prep**: Confirm downtime expectations, inventory Azure assets, bootstrap GCP targets/service accounts.
- **Dry Run 1 (T-30)**: Move sample data into non-prod GCP, sanity-check counts/checksums.
- **Dry Run 2 (T-21)**: Rehearse full stack (data, identity, jobs) in dev; iterate rollback scripts.
- **Dry Run 3 (T-14)**: Execute end-to-end rehearsal in prod project with Azure still primary.
- **Freeze (T-5)**: Announce change window, lock Terraform state, prep comms + checklists.
- **Cutover (T)**: Stop Azure writers, run migration scripts, flip identity/DNS, smoke test, announce complete.
- **Hypercare (T+0→7)**: Monitor ingest/chat/reporting daily, log findings, close out incidents.
- **Automation**: Dev Cloud Run job `weekly-azure-refresh` runs Mondays at 11:00 UTC; prod scheduler stays disabled until we warm the prod cadence.

> The remainder of this document keeps the detailed notes in case we need them; default to the bullets above when planning your day.

## 1. Preparation Checklist (Run Once)

- [ ] Confirm stakeholder buy-in for migration downtime windows and data validation expectations.
- [x] Inventory Azure resources in scope:
   - Azure SQL Database (legacy intake pipeline tables: `intake_form_data`, `intake_form_data_last_processed`, `groupsio_message_data`)
  - Azure Blob Storage containers (evidence, generated reports)
  - Azure Cognitive Search indexes
  - Azure Functions (ingestion jobs)
  - Azure AD B2C / identity providers
- [ ] Ensure target GCP resources are provisioned via Terraform:
  - Firestore database, Cloud Storage buckets (`i4g-evidence-{env}`, `i4g-reports-{env}`)
  - Vertex AI Search data store (`retrieval-prod`)
  - Cloud Run services/jobs, Secret Manager entries
- [ ] Set up migration service accounts and credentials:
  - Azure AD app registration for data export scripts
  - `sa-migration@{project}` service account in GCP with access to Firestore, Storage, Vertex AI Search imports
- [ ] Define success criteria and rollback procedures:
  - Row counts, checksum comparisons, random sampling for data accuracy
  - Document how to revert DNS/API endpoints if cutover fails

## 2. Structured Data Migration (Azure SQL → Firestore/Cloud SQL)

> **Weekly cadence:** Run the incremental export/import every Friday while the MVP iterates so data in GCP stays within seven days of Azure. Capture each run’s report under `data/intake_migration_report_*.json` and log highlights here.

_Incremental sync log_

- 2025-11-15: Ran full table refresh into `i4g-dev`; all counts matched prior baseline (81/1/26,220) with unchanged checksums (report `data/intake_migration_report_20251115.json`).

**Automation helper**

- Preferred: `python scripts/migration/run_weekly_refresh.py --firestore-project i4g-dev` runs the SQL export, blob sync, and search re-import in one pass (use `--skip-*` flags for partial runs). Summary file lands at `data/weekly_refresh_<date>.json`.

1. **Export from Azure SQL**
   - Use `sqlpackage` (with Azure AD auth) to export the three legacy tables to BACPAC or CSV/Parquet.
   - Capture schema mapping between Azure SQL tables and their downstream consumers (forms pipeline, Groups.io cache).
      - **Post-export:** remove temporary SQL firewall rule with `az sql server firewall-rule delete --name allow-export-YYYYMMDD --server intelforgood --resource-group intelforgood` to close access from your IP.
2. **Transform Schema**
   - Implement a Python ETL script (preferably in `proto/scripts/migration/azure_sql_to_firestore.py`).
   - Map `intake_form_data` and `intake_form_data_last_processed` into the new intake staging collections; migrate `groupsio_message_data` into the successor messaging cache.
   - Preserve primary keys/foreign keys in document IDs or reference fields.
3. **Load into GCP**
   - Run ETL script with `I4G_ENV=prod` configuration, impersonating `sa-migration`.
   - Batch writes using Firestore transactions/bulk writer to preserve consistency.
4. **Validation**
   - Compare record counts and key checksums (e.g., `hashlib.sha256` over concatenated fields).
   - Sample random cases to verify nested structures and PII tokenization references.
   - Log validation results in `planning/migration_runbook.md` (append tables or checklists).
   - _2025-11-13 dry run recap_: Export required an Azure SQL firewall rule for the workstation IP (`az sql server firewall-rule create --name allow-export-YYYYMMDD ...`). `DefaultAzureCredential` paths failed for pyodbc; created scoped SQL login `migration_user` with `db_datareader`. Final command used `python scripts/migration/azure_sql_to_firestore.py --connection-string "Driver={ODBC Driver 18 for SQL Server};Server=tcp:intelforgood.database.windows.net,1433;Database=intelforgood;..." --firestore-project i4g-dev --report data/intake_migration_report_20251113.json`.
5. **Rollback Plan**
   - Keep Azure SQL read-only copy until production cutover verified.
   - If issues arise, halt writes to GCP, fix mapping, re-run ETL.

> Legacy "case" datasets live in Firestore (see IFG Chat UI). Document and plan that export separately once the Azure SQL tables are migrated.

## 3. Unstructured Data Migration (Azure Blob Storage → Cloud Storage)

> **Weekly cadence:** Mirror newly arrived blobs alongside the SQL refresh. Store incremental reports as `data/blob_migration_incremental_*.json` and note anomalies or large deltas in this section.

**Weekly procedure (dev project shown)**

The combined orchestrator now skips the live copy when the dry-run sees no new or python scripts/infra/add_azure_secrets.py --project i4g-devupdated blobs, so Cloud Run executions stay quick after an all-clear diff.

1. Ensure `AZURE_STORAGE_CONNECTION_STRING` is exported for the `attachmentsdata` account and that `gcloud auth application-default login` (or workload identity) is active for GCS writes.
2. Run a dry-run diff to capture the expected delta (add or remove `--container` flags to match the real Azure containers):
    ```bash
    python scripts/migration/azure_blob_to_gcs.py \
       --connection-string "$AZURE_STORAGE_CONNECTION_STRING" \
       --container intake-form-attachments=gs://i4g-evidence-dev/forms \
       --container groupsio-attachments=gs://i4g-evidence-dev/groupsio \
       --dry-run \
       --report data/blob_migration_incremental_${RUN_DATE}_dryrun.json
    ```
3. If the dry-run looks good, execute the copy (without `--dry-run`) and write the main report:
    ```bash
    python scripts/migration/azure_blob_to_gcs.py \
       --connection-string "$AZURE_STORAGE_CONNECTION_STRING" \
       --container intake-form-attachments=gs://i4g-evidence-dev/forms \
       --container groupsio-attachments=gs://i4g-evidence-dev/groupsio \
       --report data/blob_migration_incremental_${RUN_DATE}.json
    ```
4. Append a bullet under “Unstructured sync log” with blob counts, skipped objects, and notable failures. Upload both JSON reports to `gs://i4g-migration-artifacts-dev/blob-incremental/${RUN_DATE}/` for audit.
5. Orchestrated option: run `python scripts/migration/run_weekly_refresh.py --skip-search --skip-sql` to execute just the blob cadence (still respect the reporting/upload steps above).

_Unstructured sync log_

1. **Inventory Containers (T-35)**
   - Azure CLI: `az storage container list --account-name <account> --auth-mode login --output table`
   - Capture size per container: `az storage container show --name <container> --account-name <account>`
   - Expected containers: `intake-form-attachments` (forms), `evidence` (raw uploads), `reports` (generated PDFs).
   - Record container → GCS target mapping in this runbook.
2. **Pre-flight Checks (T-33)**
   - Ensure Cloud Storage buckets exist (`i4g-evidence-{env}`, `i4g-reports-{env}`) via Terraform.
   - Confirm service account used for migration has `roles/storage.admin` on target buckets.
    - Acquire Azure Storage connection string or SAS token with read permissions. Example CLI:
       ```bash
       az storage account show-connection-string \
          --name attachmentsdata \
          --resource-group intelforgood \
          --query connectionString -o tsv
       ```
3. **Dry Run (T-30)**
   - Run new helper script in dry-run mode to enumerate objects and confirm access:
     ```bash
     python scripts/migration/azure_blob_to_gcs.py \
       --connection-string "$AZURE_STORAGE_CONNECTION_STRING" \
       --container evidence=gs://i4g-evidence-dev/handoff \
       --container reports=gs://i4g-reports-dev \
       --dry-run \
       --report data/blob_migration_dryrun.json
     ```
   - Review report for object counts, skipped items, and permission errors.
4. **Data Transfer (T-28)**
   - Execute full copy (remove `--dry-run`). Add `--overwrite` only if checksums differ and re-sync is needed.
   - Script preserves `content-type`, `cache-control`, and custom metadata when available.
   - For very large containers, run per-container to manage runtime; use `--temp-dir` pointing to a disk with sufficient space.
   - _2025-11-14_: Copied `intake-form-attachments` → `gs://i4g-evidence-dev/forms` and `groupsio-attachments` → `gs://i4g-evidence-dev/groupsio`; follow-up run captured `data/blob_migration_20251114.json` for reporting after the initial copy.
5. **Validation (T-27)**
   - Update Storage Validation Log with Azure counts, GCS counts, checksum spot checks.
   - Spot-check per-case folders and timestamps. Verify signed URL generation against new GCS objects.
   - Optional: `gsutil ls -L gs://i4g-evidence-dev/...` and compare MD5 with Azure `content_md5` reported in migration script.
   - _2025-11-14_: Confirmed Azure ↔ GCS blob counts match for both migrated folders; JSON report saved at `data/blob_migration_20251114.json` documents 0 copies and all objects skipped as existing.
6. **Cleanup & Rollback (T-27)**
   - Retain Azure blobs until GCS validation complete + snapshot captured.
   - Rollback plan: re-enable Azure SAS URLs and pause GCS consumers if issues found.
   - Archive migration reports (`data/blob_migration_*.json`) in docs for audit.

## 4. Search Index Migration (Azure Cognitive Search → Vertex AI Search)

> **Weekly cadence:** Export Azure Cognitive Search indexes, transform them for Vertex AI Search, and re-import into `retrieval-poc` so stakeholder feedback stays aligned with fresh data. Store artifacts under `data/search_exports/${RUN_DATE}/` and upload the Vertex-ready JSONL to `gs://i4g-migration-artifacts-dev/search/${RUN_DATE}/` for traceability.

**Weekly procedure (dev project shown)**

1. Set `AZURE_SEARCH_ENDPOINT` and `AZURE_SEARCH_ADMIN_KEY` in the shell (or pass via CLI flags). Choose an output directory tagged with the run date, e.g., `RUN_DATE=$(date +%Y%m%d)`.
2. Export schemas and documents:
    ```bash
    python scripts/migration/azure_search_export.py \
       --endpoint "$AZURE_SEARCH_ENDPOINT" \
       --admin-key "$AZURE_SEARCH_ADMIN_KEY" \
       --output-dir data/search_exports/${RUN_DATE}
    ```
3. Transform for Vertex AI Search:
    ```bash
    python scripts/migration/azure_search_to_vertex.py \
       --input-dir data/search_exports/${RUN_DATE} \
       --output-dir data/search_exports/${RUN_DATE}/vertex
    ```
4. Import into Discovery Engine (global data store `retrieval-poc` shown):
    ```bash
    python scripts/migration/import_vertex_documents.py \
       --project i4g-dev \
   --location global \
   --data-store-id retrieval-poc \
   --uris gs://i4g-migration-artifacts-dev/search/${RUN_DATE}/vertex/groupsio-search_vertex.jsonl \
      gs://i4g-migration-artifacts-dev/search/${RUN_DATE}/vertex/intake-form-search_vertex.jsonl \
   --error-prefix gs://i4g-migration-artifacts-dev/search/${RUN_DATE}/errors
    ```
5. Record the long-running operation ID and success/failure counts below. If failures occur, capture sample documents and adjust the transformer before re-running.
6. Orchestrated option: run `python scripts/migration/run_weekly_refresh.py --skip-sql --skip-blob` to handle the index export/transform/import + uploads in a single pass (see summary JSON for the operation ID).

_Search sync log_

1. **Export Existing Index**
    - Install the Azure CLI Search extension (once per workstation):
       ```bash
       az extension add --name search
       ```
    - Authenticate and select the correct subscription:
       ```bash
       az login
       az account list --output table  # note the subscription name or ID
       az account set --subscription "<subscription-name-or-id>"
       ```
    - Discover the Cognitive Search service and resource group:
       ```bash
       az search service list --output table
       az search service show --name <service-name> --resource-group <resource-group>
       ```
       Note the `properties.endpoint` value (e.g. `https://ifg-ai-search.search.windows.net`).
    - List indexes and grab admin/query keys:
       ```bash
       az search index list --service-name <service-name> --resource-group <resource-group> --output table
       az search admin-key show --service-name <service-name> --resource-group <resource-group>
       az search query-key list --service-name <service-name> --resource-group <resource-group>
       ```
   - Run the helper script to snapshot schemas and documents locally:
     ```bash
     python scripts/migration/azure_search_export.py \
       --endpoint "$AZURE_SEARCH_ENDPOINT" \
          --admin-key "$AZURE_SEARCH_ADMIN_KEY"
     ```
    - Store exported artifacts (`data/search_exports/<index>_schema.json`, `data/search_exports/<index>_documents.jsonl`) and upload to GCS for collaboration (current dropzone: `gs://i4g-migration-artifacts-dev/search/20251114/`).
    - Convert Azure JSONL into Vertex AI Search format:
       ```bash
       python scripts/migration/azure_search_to_vertex.py \
          --input-dir data/search_exports \
          --output-dir data/search_exports/vertex
       ```
    - Prepared Vertex JSONL staged at `gs://i4g-migration-artifacts-dev/search/20251114/vertex/` for Discovery Engine import.
2. **Transform for Vertex AI Search**
   - Map fields from Azure documents to Vertex AI Search schema; ensure vector embeddings or semantic fields are recomputable via GCP models.
   - Transformer updates (2025-11-15): populate `structData.index_type`/`source` with the Azure index name, encode long-form text as `Document.content.rawBytes` (base64) to satisfy GA API requirements, and hash Azure IDs exceeding 128 characters while storing the original ID in `structData.source_id`.
   - Record per-index field mapping and filter requirements directly in this runbook; `planning/search_migration_notes.md` has been merged here.
3. **Import to Vertex AI Search**
   - Use `gcloud discovery-engine data-stores documents import` or the Python helper (`scripts/migration/import_vertex_documents.py`) pointing at the Vertex-ready JSONL files.
   - Helper supports `--dry-run` to print the `ImportDocumentsRequest` without starting an operation and `--error-prefix` to direct rejection logs to GCS.
   - Monitor import progress via Vertex AI Search console or `gcloud` CLI; record LRO name in change log.
4. **Validation**
   - Run representative queries in both systems; compare top results for parity.
   - Capture metrics (precision@k, recall) where possible; document differences.
   - Latest import (2025-11-15): `success_count=1159`, `failure_count=0` after excluding attachment-only intake rows; Discovery Engine document IDs prefixed with `hash_` verify hashed ID logic works.
5. **Cutover Plan**
   - Update `VectorClient` configuration to point to Vertex AI Search.
   - Keep Azure index accessible for fallback during initial production use.

## 5. Identity & Access Cutover (Azure AD B2C → Google Identity)

1. **User Migration**
   - Export Azure AD B2C user directory (CSV or JSON) with emails, roles, MFA settings.
   - Import into Google Cloud Identity Platform using Admin SDK or custom scripts.
2. **App Registration**
   - Update Streamlit/FastAPI OIDC client IDs/secrets to point to Google Identity.
   - Verify redirect URIs and authorized domains.
3. **Testing**
   - Conduct end-to-end login tests for each role (victim, analyst, admin, LEO).
   - Confirm token claims align with role-based access control in FastAPI.
4. **Cutover**
   - Disable Azure AD B2C sign-ins after GCP login is confirmed stable.
   - Communicate login changes to users; provide support channel for MFA resets.
5. **Rollback**
   - Keep Azure AD B2C tenant active (but read-only) until confident in new flow.
   - Re-enable Azure login only if major incidents occur; document rollback steps.

## 6. Automation & Ingestion Jobs (Azure Functions → Cloud Run Jobs)

1. **Code Porting**
   - Review Azure Function implementations (GroupsIO, forms ingestion, etc.).
   - Containerize logic into Cloud Run Jobs with appropriate entrypoints.
2. **Scheduling**
   - Replace Azure Scheduler/Timers with Cloud Scheduler + Pub/Sub triggers.
   - Ensure service accounts have necessary IAM (Secret Manager, Firestore, Storage).
3. **Validation**
   - Run jobs in dev environment; compare outputs with Azure Function logs.
   - Ensure idempotency to avoid duplicate records during parallel runs.
4. **Cutover**
   - Disable Azure Functions (stop triggers) once Cloud Run Jobs produce expected results.
   - Monitor Cloud Logging for failures during initial days.

### 6.1 Weekly Refresh Cloud Run Job (dev only)

- Container image: build and push `docker/weekly-refresh-job.Dockerfile` to `us-central1-docker.pkg.dev/i4g-dev/applications/weekly-refresh-job:dev`.
   ```bash
   docker build -f docker/weekly-refresh-job.Dockerfile -t us-central1-docker.pkg.dev/i4g-dev/applications/weekly-refresh-job:dev .
   docker push us-central1-docker.pkg.dev/i4g-dev/applications/weekly-refresh-job:dev
   ```
- Terraform wiring lives in `infra/environments/dev/terraform.tfvars` (`run_jobs.weekly_refresh`). `terraform apply` provisions:
   - Cloud Run job `weekly-azure-refresh` (timeout 60 minutes, 1 CPU/2 GiB) executing `run_weekly_refresh.py`.
   - Cloud Scheduler trigger `weekly-azure-refresh-schedule` that runs Mondays at 11:00 UTC (token creator binding handled automatically).
- Secrets: Terraform creates Secret Manager placeholders `azure-sql-connection-string`, `azure-storage-connection-string`, and `azure-search-admin-key`. Populate each before the first scheduled run with the helper script:
   ```bash
   python scripts/infra/add_azure_secrets.py --project i4g-dev
   ```
   Use `--use-env` if you have exported `AZURE_SQL_CONNECTION_STRING`, `AZURE_STORAGE_CONNECTION_STRING`, and `AZURE_SEARCH_ADMIN_KEY` locally.
- Non-secret config (`AZURE_SEARCH_ENDPOINT`) is injected via Terraform; adjust the tfvars file if Azure renames the service.
- Prod has a matching but disabled definition (`enabled = false`) so the scheduler stays off until we intentionally warm the production cadence.
- The job logs the JSON summary emitted by `data/weekly_refresh_<date>.json`; check Cloud Logging for per-step results after each run.

## 7. Communication & Go-Live Checklist

- [ ] Announce migration timeline to stakeholders (volunteers, partner agencies).
- [ ] Provide runbooks to support team for incident handling.
- [ ] Update public status page (if any) with maintenance windows.
- [ ] After cutover, hold a retrospective to capture lessons learned.

## 8. Dry Runs & Final Cutover Timeline

| Phase | Target Window | Key Activities | Owner |
|---|---|---|---|
| Dry Run 1 – Data Only | T-30 days | Execute structured/unstructured data migrations into non-production GCP project; validate row/file counts; document gaps. | Jerry |
| Dry Run 2 – Full Stack | T-21 days | Rehearse identity cutover + ingestion job redeployment in dev; test rollback scripts; capture timing benchmarks. | Jerry |
| Dry Run 3 – Production Rehearsal | T-14 days | Run end-to-end workflow in prod project with Azure systems still primary; exercise monitoring dashboards and incident response drill. | Jerry |
| Freeze | T-5 days | Communicate code/config freeze; ensure Terraform state locked; confirm incident contacts on-call. | Jerry |
| Cutover Day | T | Disable Azure writers, execute migration scripts, flip DNS/API endpoints, monitor success metrics, communicate completion. | Jerry |
| Hypercare | T+7 days | Daily check-ins on ingestion/chat/reporting; log incidents; plan backlog fixes. | Jerry |

> Adjust timing to fit final schedule; maintain the table in this document as the source of truth for upcoming rehearsals.

### Cutover Day Playbook
1. Announce downtime window on communication channels (email, status page, Slack) 60 minutes before cutover.
2. Verify final Azure snapshots/backups: SQL export timestamp, blob storage snapshot IDs, Cognitive Search export manifest.
3. Pause or disable Azure ingestion jobs to prevent new data writes during migration window.
4. Run structured and unstructured migration scripts with `I4G_ENV=prod`, capturing logs to Cloud Logging + local JSON artifact.
5. Execute Vertex AI Search import job and wait for success indicator in Discovery Engine console/API.
6. Assign Google Identity as primary IdP in application settings and revoke Azure AD B2C client access.
7. Update DNS/API endpoints (e.g., Cloud Run domain mapping, Streamlit custom domain) to point to GCP services.
8. Run post-cutover smoke tests: FastAPI health, Streamlit login for each role, ingestion job dry-run, report generation.
9. Broadcast completion notice with summary of validation results and invite users back onto the system.

### Rollback Playbook
1. If critical blocking issue detected (P0 outage, data corruption), stop GCP ingestion jobs and disable new logins.
2. Repoint DNS/API endpoints to Azure services (FastAPI/Streamlit) using documented Terraform or `az` CLI commands.
3. Re-enable Azure AD B2C applications and ingestion jobs.
4. Restore Azure SQL/Blob data from pre-cutover snapshots if GCP scripts modified source datasets.
5. Communicate rollback to stakeholders, outlining incident details and next-steps remediation plan.
6. Capture root-cause notes in this runbook and schedule fix/redo window; ensure GCP data is cleaned or archived before next attempt.

### Hypercare Checklist (T+0 → T+7)
- Owner: Jerry (sole operator for monitoring and remediation).
- Daily validation of new victim intake records across FastAPI + Firestore counts.
- Confirm scheduled ingestion jobs complete and log success metrics (duration, record count) in Cloud Logging dashboards.
- Monitor Vertex AI Search latency/errors; rerun sample queries to ensure relevance parity.
- Review Cloud Monitoring alerts for IAM/permission anomalies and Secret Manager access attempts.
- Track user feedback or support tickets; classify severity and link to remediation tasks.
- Record findings in a shared Hypercare log (appendix of this runbook or status updates).

## 9. Tracking Templates

### 9.1 Structured Data Validation Log

| Table/Collection | Azure Count | GCP Count | Delta | Checksum Match | Notes |
|---|---|---|---|---|---|
| intake_form_data | 81 | 81 | 0 | ✅ | Loaded via `azure_sql_to_firestore.py` (Report 2025-11-13) |
| intake_form_data_last_processed | 1 | 1 | 0 | ✅ | Loaded via `azure_sql_to_firestore.py` (Report 2025-11-13) |
| groupsio_message_data | 26220 | 26220 | 0 | ✅ | Loaded via `azure_sql_to_firestore.py` (Report 2025-11-13) |

> Latest dry-run and load executed 13 Nov 2025 using `python scripts/migration/azure_sql_to_firestore.py --connection-string "Driver={ODBC Driver 18 for SQL Server};Server=tcp:intelforgood.database.windows.net,1433;Database=intelforgood;Encrypt=yes;TrustServerCertificate=no;UID=migration_user;PWD=$SQL_MIGRATION_PASSWORD" --firestore-project i4g-dev --report data/intake_migration_report_20251113.json`. Report artifact stored at `data/intake_migration_report_20251113.json`.

### 9.2 Storage Validation Log

| Container/Prefix | Azure Files | GCP Files | Delta | Sampled Checksum Pass | Notes |
|---|---|---|---|---|---|
| intake-form-attachments → gs://i4g-evidence-dev/forms | 433 | 433 | 0 | ✅ | Report 2025-11-14 (`data/blob_migration_20251114.json`); initial copy earlier same day. |
| groupsio-attachments → gs://i4g-evidence-dev/groupsio | 1594 | 1594 | 0 | ✅ | Report 2025-11-14 (`data/blob_migration_20251114.json`); initial copy earlier same day. |

### 9.3 Search Relevance Comparison

| Query | Azure Top Result | Vertex AI Top Result | Match? | Notes |
|---|---|---|---|---|
|  |  |  |  |  |

### 9.4 Identity Migration Checklist

| User Role | Accounts Migrated | MFA Verified | Issues Logged | Resolution |
|---|---|---|---|---|
| Victim |  |  |  |  |
| Analyst |  |  |  |  |
| Admin |  |  |  |  |
| LEO |  |  |  |  |

## 10. Appendix

- **Tools/Commands Reference**
  - `sqlpackage`, `azcopy`, `gsutil`, `gcloud discovery-engine`, custom Python ETL scripts.
- **Service Account Matrix**
  - `sa-migration`: Firestore user, Storage admin (restricted to migration buckets), Vertex AI Search importer.
- **Observation Notes**
  - Record anomalies or data discrepancies here during dry runs.

---

These runbooks are living documents—update steps as scripts are built, credentials generated, and validation results collected.
