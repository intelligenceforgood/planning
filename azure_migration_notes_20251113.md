# Azure SQL → Firestore Migration Notes (13 Nov 2025)

These notes capture the access hurdles, dead-ends, and final working steps from the first structured-data migration dry run.

## 1. Access & Networking
- Azure SQL blocked outbound IP (`98.234.181.54`). Created temporary firewall rule:
  ```bash
  az sql server firewall-rule create \
    --name allow-export-YYYYMMDD \
    --server intelforgood \
    --resource-group intelforgood \
    --start-ip-address 98.234.181.54 \
    --end-ip-address 98.234.181.54
  ```
- Documented cleanup command and added to runbook:
  ```bash
  az sql server firewall-rule delete --name allow-export-YYYYMMDD --server intelforgood --resource-group intelforgood
  ```

## 2. Authentication Attempts (and Failures)
- **DefaultAzureCredential + access token**: multiple pyodbc connection errors (`Invalid value for Authentication`, `Cannot use Access Token with Authentication/User/Password`).
- **sqlcmd (AAD)**: macOS build lacked `--authentication-method`, forcing password flow; ActiveDirectoryInteractive failed with tenant mismatch; fallback was new sqlcmd v2 or Azure Portal (not adopted).
- **Final decision**: use SQL login (`migration_user`) with scoped `db_datareader` role. Created via VS Code SQL extension (AAD connection → master DB → create login, then new connection to `intelforgood` DB → create user + add to role).

## 3. Tooling Pitfalls
- Homebrew install of `msodbcsql18`/`mssql-tools18` appeared to hang; confirmed completion via `brew list`. PATH had to prefer `/opt/homebrew/bin`.
- VS Code SQL extension authentication: must sign into **Default Directory** tenant (`40d408e0-0cf0-4eeb-9c34-e9114b0814a3`). Signing out of Azure cloud account prevented cross-tenant confusion.
- `USE database` doesn’t work in Azure SQL portal; created second connection scoped to `intelforgood` database instead.

## 4. Migration Script Build & Adjustments
- Script path: `proto/scripts/migration/azure_sql_to_firestore.py`.
- Dependencies added to `pyproject.toml`: `azure-identity`, `google-cloud-firestore`, `pyodbc`.
- CLI options: connection string, optional `--use-aad`, Firestore project, table selection, batch size, report output.
- Early dry run flagged PK mismatches:
  - `dbo.intake_form_data_last_processed` only has `last_row`; script updated to let Firestore auto-ID.
  - `dbo.groupsio_message_data` PK is `id`, timestamp column is `timestamp` (not `received_at`).
- Final command used:
  ```bash
  python scripts/migration/azure_sql_to_firestore.py \
    --connection-string "Driver={ODBC Driver 18 for SQL Server};Server=tcp:intelforgood.database.windows.net,1433;Database=intelforgood;Encrypt=yes;TrustServerCertificate=no;UID=migration_user;PWD=${SQL_MIGRATION_PASSWORD}" \
    --firestore-project i4g-dev \
    --report data/intake_migration_report_20251113.json
  ```

## 5. Firestore Project Gaps (Infra Fixes)
- API not enabled: added `google_project_service.firestore` to `infra/environments/{dev,prod}/main.tf`.
- Default DB missing: Terraform now creates `google_firestore_database.default` with `FIRESTORE_NATIVE`.
- Requires `terraform -chdir=environments/dev apply` (and similar for prod) to provision the database prior to running the migration script.

## 6. Validation Outcomes (Report `data/intake_migration_report_20251113.json`)
- `dbo.intake_form_data`: 81 rows → 81 docs, checksum `874079e6…`.
- `dbo.intake_form_data_last_processed`: 1 row → 1 doc, checksum `6a3bbca0…`.
- `dbo.groupsio_message_data`: 26,220 rows → 26,220 docs, checksum `34604070…`.
- Validation table in `planning/migration_runbook.md` updated with zero deltas and ✅ checksums.

## 7. Clean-Up & Future Reminders
- Rotate or disable `migration_user` credentials when migration concludes.
- Remove temporary SQL firewall rule after each run (already scripted in runbook).
- Next dry runs can reuse the script + SQL login without revisiting AAD auth complexities.
- Schedule follow-up to inventory Firestore collections backing legacy “cases/case_events”.
- Consider scripting Terraform import for existing Artifact Registry repos if state errors recur (`terraform import google_artifact_registry_repository.applications ...`).
