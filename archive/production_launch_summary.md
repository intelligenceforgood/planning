# Production Launch Summary

**Completed:** 2026-03-10
**Scope:** Spin up `i4g-prod` and `i4g-pii-vault-prod` GCP environments end-to-end.

---

## What Was Deployed

- **GCP Projects:** `i4g-prod` (app) + `i4g-pii-vault-prod` (PII vault)
- **Cloud SQL:** `i4g-prod-db` (main) + `i4g-vault-prod-db` (vault), both with IAM-based auth
- **Cloud Run Services:** `core-svc`, `i4g-console` — both behind IAP + global HTTPS LB
- **Cloud Run Jobs:** 7 jobs deployed (`ingest-bootstrap`, `process-intakes`, `generate-reports`, `classification-sweeper`, `account-list`, `dossier-queue`, `retention-purge`); schedulers created in PAUSED state
- **Load Balancer:** Global LB with Google-managed SSL on `api.intelligenceforgood.org` + `app.intelligenceforgood.org`
- **IAP:** Single OAuth client protects both API and console backends; Google Workspace org-level access
- **Monitoring:** 3 log-based alert policies (PII access, ingestion failures, dossier issues) with email notification channel
- **Storage:** `i4g-evidence-prod`, `i4g-reports-prod`, `i4g-prod-ssi-evidence` — retention policies active
- **Networking:** Static egress IP via Cloud NAT + VPC connector, dev/prod parity confirmed
- **CI/CD:** GitHub Actions workflow with Workload Identity Federation (WIF) for Terraform; deployment gates deferred

## Deferred Items

- Cloud Scheduler triggers remain **paused** — enable when ready for automated job execution
- Manual job execution tests deferred (ingestion, report generation, audit logs)
- CI/CD deployment approval gates and full pipeline testing
- Documentation of `i4g db` CLI commands in `core/docs/cookbooks/cloud_sql_primer.md`

---

## Key Decisions & Architecture Corrections

### 1. Console-to-API routing must go through the LB, not direct Cloud Run URL

**Problem:** `i4g-console` server-side API calls used the direct Cloud Run URL for `core-svc`, but `core-svc` ingress is set to `internal-and-cloud-load-balancing`. Direct calls were rejected.

**Fix:** Set `I4G_API_URL` to `https://api.intelligenceforgood.org` (the LB domain) in both dev and prod `console_env_vars`. The console uses `getIapHeaders()` for IAP-authenticated server-to-server calls through the LB. This was applied to both `environments/app/dev/main.tf` and `environments/app/prod/main.tf`.

**Lesson:** Any server-side component (console SSR, jobs) calling `core-svc` must route through the LB when ingress is restricted. Direct Cloud Run URLs only work with `all` ingress or from within the same project's VPC.

### 2. Service account needs IAP access to call API through the LB

**Problem:** Even after routing `I4G_API_URL` through the LB, the console's service account (`sa-app`) still got 403s from IAP because it wasn't in the IAP access list.

**Fix:** Added `app_service_account_member` to `core_svc_iap_access_members` in prod `main.tf`, matching the existing dev pattern.

**Lesson:** When IAP protects a backend, every identity that calls it — including service accounts — must be granted `roles/iap.httpsResourceAccessor` on that specific backend service.

### 3. Console LB backend should only deploy when `ui_custom_domain` is set

**Problem:** The LB module tried to create a console backend even when `ui_custom_domain` was empty, causing Terraform errors.

**Fix:** Introduced `deploy_console_lb = deploy_console && ui_custom_domain != ""` local, used it for the console LB backend and IAP binding `count` conditions. The console Cloud Run service can exist without an LB backend (useful for staging).

### 4. Monitoring module variables were duplicated in `main.tf` and `variables.tf`

**Problem:** The monitoring module had `variable` blocks in both `main.tf` and `variables.tf`, causing Terraform errors.

**Fix:** Removed the duplicate declarations from `main.tf`, keeping them only in `variables.tf` (standard Terraform convention).

### 5. Alert policy filters need `resource.type` restriction

**Problem:** Cloud Monitoring alert policies with log-based metrics failed validation without a `resource.type` filter.

**Fix:** Added `AND resource.type=one_of("cloud_run_revision","cloud_run_job")` to all three alert policy condition filters.

### 6. Scheduler module needed `paused` support

**Problem:** Cloud Scheduler jobs should be created in a paused state for prod launch (no automated execution until verified manually).

**Fix:** Added `paused` variable to `modules/scheduler/job/` and passed it through from the `run_jobs` variable in both dev and prod.

### 7. Scheduler needs OAuth scopes, not just OIDC

**Problem:** Prod scheduler module call was missing `oauth_scopes` passthrough, causing auth failures when triggering Cloud Run jobs.

**Fix:** Added `oauth_scopes` passthrough in prod `main.tf`, matching the existing dev pattern.

### 8. SSI settings refactored: defaults are now production-ready

**Problem:** `settings.default.toml` had local-dev defaults (Ollama, SQLite, proxy disabled), and `settings.dev.toml` duplicated most of the production values. This made it hard to keep dev and prod in sync.

**Refactor:** `settings.default.toml` now contains production-ready baseline values (Gemini, CloudSQL, GCS, proxy enabled). `settings.dev.toml` is minimal (only CORS origins and core API URL). `settings.local.toml.example` shows how to override back to local-dev stack (Ollama, SQLite, local evidence). Cloud-specific values (GCP project, buckets, API keys) are always injected via Terraform env vars or Secret Manager.

### 9. SSI proxy credentials moved from single-secret host to username/password fields

**Problem:** Proxy authentication was via a single `SSI_PROXY__HOST` secret containing the full URL. This was fragile and non-standard.

**Fix:** Added explicit `username` and `password` fields to `ProxySettings`. The proxy URL is now constructed from components. The password is injected from Secret Manager; the username is a non-sensitive default in config.

---

## Quick Reference: Instance Map

| Environment | GCP Project          | Cloud SQL Instance  | Database   | Proxy Port |
| ----------- | -------------------- | ------------------- | ---------- | ---------- |
| dev app     | `i4g-dev`            | `i4g-dev-db`        | `i4g_db`   | 5432       |
| dev vault   | `i4g-pii-vault-dev`  | `i4g-vault-dev-db`  | `vault_db` | 5433       |
| prod app    | `i4g-prod`           | `i4g-prod-db`       | `i4g_db`   | 5434       |
| prod vault  | `i4g-pii-vault-prod` | `i4g-vault-prod-db` | `vault_db` | 5435       |

## Quick Reference: Service Accounts

| SA          | Dev                              | Prod                              |
| ----------- | -------------------------------- | --------------------------------- |
| `sa-app`    | `sa-app@i4g-dev.iam`             | `sa-app@i4g-prod.iam`             |
| `sa-ingest` | `sa-ingest@i4g-dev.iam`          | `sa-ingest@i4g-prod.iam`          |
| `sa-intake` | `sa-intake@i4g-dev.iam`          | `sa-intake@i4g-prod.iam`          |
| `sa-report` | `sa-report@i4g-dev.iam`          | `sa-report@i4g-prod.iam`          |
| `sa-ssi`    | `sa-ssi@i4g-dev.iam`             | `sa-ssi@i4g-prod.iam`             |
| `sa-vault`  | `sa-vault@i4g-pii-vault-dev.iam` | `sa-vault@i4g-pii-vault-prod.iam` |

## CLI Tooling Added

The `i4g db` CLI subcommand was created for Cloud SQL administration:

- `i4g db migrate <env> [--vault]` — runs Alembic migrations via cloud-sql-proxy
- `i4g db grant-permissions <env> [--vault]` — grants table/sequence/default privileges to SAs + admin users
- `i4g db status <env> [--vault]` — shows current Alembic revision
- All commands support `--dry-run` and automatically manage cloud-sql-proxy lifecycle
