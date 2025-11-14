# Azure → GCP Migration Runbooks (Draft)

_Last updated: 11 Nov 2025_

These runbooks outline the phased process for migrating DT-IFG workloads from Azure to the i4g Google Cloud Platform stack. Each section can be executed independently as data, services, or infrastructure become ready. Update this document as plans firm up during Milestone 3 and 4.

## 0. Quick Plan (High-Level Sketch)
- **Prep**: Confirm downtime expectations, inventory Azure assets, bootstrap GCP targets/service accounts.
- **Dry Run 1 (T-30)**: Move sample data into non-prod GCP, sanity-check counts/checksums.
- **Dry Run 2 (T-21)**: Rehearse full stack (data, identity, jobs) in dev; iterate rollback scripts.
- **Dry Run 3 (T-14)**: Execute end-to-end rehearsal in prod project with Azure still primary.
- **Freeze (T-5)**: Announce change window, lock Terraform state, prep comms + checklists.
- **Cutover (T)**: Stop Azure writers, run migration scripts, flip identity/DNS, smoke test, announce complete.
- **Hypercare (T+0→7)**: Monitor ingest/chat/reporting daily, log findings, close out incidents.

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
5. **Rollback Plan**
   - Keep Azure SQL read-only copy until production cutover verified.
   - If issues arise, halt writes to GCP, fix mapping, re-run ETL.

> Legacy "case" datasets live in Firestore (see IFG Chat UI). Document and plan that export separately once the Azure SQL tables are migrated.

## 3. Unstructured Data Migration (Azure Blob Storage → Cloud Storage)

1. **Inventory Containers**
   - `evidence` container (original uploads)
   - `reports` container (generated documents)
2. **Data Transfer**
   - Use `AzCopy` or `Azure Storage Explorer` to sync blobs to a local staging area or directly to Cloud Storage via `gsutil` (use service principal credentials for Azure and service account for GCP).
   - Recommended: `gsutil -m rsync -r gs://azure-export/evidence gs://i4g-evidence-prod`
3. **Metadata Preservation**
   - Ensure metadata (content-type, checksum, creation time) is preserved; if not, store sidecar JSON with attributes.
   - For signed URL parity, confirm `storageClass`, retention policies, and encryption align with GCP buckets.
4. **Validation**
   - Spot check file counts per case folder.
   - Compare checksums between Azure and GCP copies (e.g., MD5 or CRC32C).
5. **Cleanup & Rollback**
   - Do not delete Azure blobs until GCP copies are verified and backup snapshots exist.
   - Document fallback procedure (e.g., re-point signed URLs to Azure if GCP copy fails).

## 4. Search Index Migration (Azure Cognitive Search → Vertex AI Search)

1. **Export Existing Index**
   - Use Azure Cognitive Search REST API to dump index schema and documents.
   - For large indexes, export in batches and store interim data in Cloud Storage.
2. **Transform for Vertex AI Search**
   - Map fields to Vertex AI Search schema; ensure vector embeddings are included or recomputable.
   - If embeddings are missing, regenerate using the chosen embedding model in GCP.
3. **Import to Vertex AI Search**
   - Use `gcloud discovery-engine data-stores documents import` with Cloud Storage manifest.
   - Monitor import progress via Vertex AI Search console or `gcloud` CLI.
4. **Validation**
   - Run representative queries in both systems; compare top results for parity.
   - Capture metrics (precision@k, recall) where possible; document differences.
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
| evidence/ |  |  |  |  |  |
| reports/ |  |  |  |  |  |

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
