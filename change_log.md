# DT-IFG Migration Change Log

Last updated: 29 Nov 2025_

This log captures significant planning decisions and architecture changes as we progress through the migration milestones. Update entries chronologically.

## 2025-11-29
- Followed up on the `account-list` Cloud Run smoke by executing `gcloud run jobs execute account-list --project i4g-dev --region us-central1` after clearing the `I4G_ACCOUNT_JOB__DRY_RUN` override. Execution `account-list-dvrq4` finished in ~78s but surfaced `Account list run account-run-cb63651e completed: indicators=0 sources=3` with warnings for every indicator category (bank/crypto/payments) because the LLM extractor could not reach Ollama inside Cloud Run.
- Pulled the job logs via `gcloud logging read ... account-list-dvrq4` and captured the stack traces showing both embedding and chat calls failing (`ConnectionError: Failed to connect to Ollama...`). Until we swap the provider to Vertex/mock for Cloud Run, the worker will keep falling back to text search and emit zero indicators, so this remains the top blocker for Milestone 1 validation.
- Exporter still produced local `/tmp/i4g/reports/account_list/account-run-cb63651e_20251129T005352Z.{pdf,xlsx}` artifacts, but no new objects landed in `gs://i4g-reports-dev/account_list/` for this run (confirmed via `gsutil ls`). Need to wire the warning propagation back through the API/worker responses and add automated alerts when uploads fail or produce empty indicator sets so analysts know the report is incomplete.
- Updated the job to run with `I4G_LLM__PROVIDER=mock` via `gcloud run jobs update ... --set-env-vars` and re-executed it (`account-list-5bd7f`). The run completed in 1m46s with the expected mock output (`account-run-92d1b4af`: 6 indicators / 3 sources), confirming the extractor path is unblocked once Ollama is bypassed in Cloud Run.
- Even with the mock provider, Chroma embeddings still try to call Ollama and emit warnings before falling back to text search; need to either disable embeddings in Cloud Run or route them through a managed backend so logs stop filling with connection errors.
- GCS uploads remain broken for dev runs: `/tmp/i4g/reports/account_list/account-run-92d1b4af_20251129T010107Z.{pdf,xlsx}` exist locally on the job, but `gsutil ls gs://i4g-reports-dev/account_list/*92d1b4af*` returned no matches. Track this alongside the warning-surface work so analysts get actionable signals when uploads fail.
- Set the job’s env vars explicitly (`I4G_ENV=dev`, `I4G_STORAGE__REPORTS_BUCKET=i4g-reports-dev`, `I4G_STORAGE__FIRESTORE__PROJECT=i4g-dev`, `I4G_LLM__PROVIDER=mock`, `I4G_ACCOUNT_LIST__ENABLE_VECTOR=false`). Execution `account-list-5pq2j` now disables vector search without error spam and uploads artifacts straight to `gs://i4g-reports-dev/account_list/account-run-6484995e_20251129T010803Z.{pdf,xlsx}`—confirms bucket wiring + warning surfacing path works once the env is set correctly.
- Wired audit/logging end-to-end: the `/accounts/extract` API now tags audit entries with a requester header (`X-ACCOUNTLIST-REQUESTER` fallback to client IP) and logs run counts/artifacts; the Cloud Run job records runs as `account_job:<env>`. `log_account_list_run` captures request metadata alongside indicator/source counts, and the refreshed unit tests cover the API, worker entrypoint, and audit helper.
- Extended the FastAPI router with `/accounts/runs` (pulling structured payloads from `ReviewStore`) and relaxed `/accounts/extract` so analyst `X-API-KEY` tokens can trigger runs without a separate service key. Updated the Next.js console with a dedicated `/accounts` page that launches manual runs, refreshes audit history via `/api/account-list/{run,runs}`, and surfaces artifact links + warning text directly in the UI.

## 2025-11-28
- Revalidated HybridRetriever coverage after latest data refresh by running the financial-entity probe (bank/crypto/payments, 30-day window, top_k=50). Each category surfaced 50 documents with representative case IDs (`ucisms-120-0`, `ucisms-123-0`, etc.), and datasets still report as `unknown` because the mock bundle omits explicit tags—tracking this until new metadata lands.
- Rehydrated the sandbox (`scripts/bootstrap_local_sandbox.py --reset`) and re-ran the Milestone 1 data coverage probe. Discovered `FinancialEntityRetriever` was discarding vector-only hits (no structured `record` payload), so coverage still read zero despite populated stores.
- Updated the retriever to merge metadata/text from vector entries, added regression tests (`tests/unit/services/test_account_list_retriever.py`), and reran the probe. All three indicator categories now return 50 source docs within the 30-day window (datasets resolve to `unknown` because the mock smoke bundle lacks explicit source tags), so we can proceed to the dev job smoke.
- Ran the local `i4g-account-job` smoke (dry run + full execution) with the mock LLM provider. The real run generated `i4g/data/reports/account_list/account-run-deecf0f8_20251129T000158Z.{pdf,xlsx}`, logged 122 source docs (1 payments indicator, bank/crypto warned empty), and confirms exporter + artifact plumbing work end-to-end on the laptop build.
- Executed `gcloud run jobs execute account-list --project i4g-dev --region us-central1` (dry run + full). Execution `account-list-4z8mj` completed with 6 indicators / 3 sources and published artifacts to `gs://i4g-reports-dev/account_list/account-run-6c4f7933_20251129T000756Z.{pdf,xlsx}`; captured logs via `gcloud logging read` for the smoke record.
- Hardened the account list exporter so Drive/GCS upload failures append warnings back through the API/worker responses (and tests now assert the behavior). Exporter `export()` returns `(artifacts, warnings)` and the service merges those warnings so analysts know when outputs fell back to local paths.

## 2025-11-27
- Added a dedicated `data/bundles/account_list_smoke.jsonl` fixture with bank/crypto/payment indicators, reingested the bundle (total structured cases now 5,580), and updated the account-job Docker build to process every `bundles/*.jsonl` file so smoke datasets ride along with the container image.
- Normalized naive timestamps inside the account list retriever and introduced a mock LLM provider path (regex-based extractor + env override) so Cloud Run can generate indicators without Ollama/Vertex dependencies; also exposed the provider override via `I4G_LLM__PROVIDER`.
- Rebuilt/pushed `us-central1-docker.pkg.dev/i4g-dev/applications/account-job:dev` with the refreshed data, executed the `account-list` job in `i4g-dev`, and captured populated artifacts: `gs://i4g-reports-dev/account_list/account-run-f724963f_20251127T174416Z.xlsx` + `.pdf` (run logged 6 indicators / 3 source docs via the mock extractor).

## 2025-11-25
- Ran the first structured-source validation pass for Milestone 1 using `FinancialEntityRetriever` across the bank/crypto/payment indicator queries (Nov 12–26 window as well as unrestricted). Every query returned zero source documents, indicating the local structured/vector stores are empty or stale. Next steps: rerun `scripts/bootstrap_local_sandbox.py --reset` (or ingest fresh cases) before the Cloud Run smoke so the retriever has data to mine.
- Attempted to execute the `account-list` Cloud Run job in `i4g-dev` (`gcloud run jobs execute account-list --project i4g-dev --region us-central1 ...`). The command failed because the job does not yet exist in the project (`Cannot find job [account-list]`). Need to add the job via Terraform (or stand up manually) before we can complete the dev smoke test; recorded the gcloud failure output for reference.
- Kicked off Milestone 1 (Account List Extraction parity). Added `planning/milestone1_account_list.md` outlining the service architecture, API/worker plan, and deliverables for porting `account_list_extract` + client workflows into proto. Next actions focus on scaffolding the new service module and validating data sources.
- Created `src/i4g/services/account_list/` with request/response models, indicator query catalog, retriever adapter, and LLM-backed service orchestration. This establishes the core dependency graph for Milestone 1 implementation.
- Added `/accounts/extract` FastAPI router with settings-driven API key enforcement, plus unit tests to cover success, limit validation, and auth failures. Introduced `account_list` settings section for header name, API key, and `top_k` guardrails.
- Built artifact exporter plumbing: account list requests can now ask for CSV/JSON outputs via `output_formats`, generated by `AccountListExporter` and surfaced in responses/tests. This sets the stage for the worker + storage jobs.
- Extended exporter to produce XLSX + PDF artifacts, upload to Cloud Storage when `storage.reports_bucket` is set, and added pytest coverage for every format alongside new dependencies (`openpyxl`, `reportlab`).
- Added Google Drive upload support driven by `ACCOUNT_LIST__DRIVE_FOLDER_ID`, using service-account ADC (no JSON keys). Exporter now prefers Drive links when configured while falling back to GCS/local paths, with unit tests covering the behavior.

## 2025-11-24
- Finalized Workspace-group IAM for human access: Terraform now binds `group:gcp-i4g-admin@intelligenceforgood.org` to `roles/owner` (new `i4g_admin_members` variable) and routes all Cloud Run/IAP access through `group:gcp-i4g-analyst@intelligenceforgood.org` via `i4g_analyst_members`.
- Updated `infra/environments/{dev,prod}` tfvars/README files plus `proto/docs/iam.md` to document the groups, ensuring onboarding/offboarding happens via Workspace instead of editing Terraform.

## 2025-11-25
- Added a temporary org-policy override in `infra/environments/dev/main.tf` to set `constraints/iam.allowedPolicyMemberDomains` `enforced = false`, unblocking `scripts/make-unauthed.sh` until the Cloud Run services sit behind a Load Balancer + IAP. **Reminder:** remove this override once the public domain + LB path is live and we no longer need emergency public toggles.

## 2025-11-21
- Shipped the Quick Auth helper SPA (`ui/apps/iam-helper`) with a production-ready Dockerfile and documented build/deploy guidance in `proto/docs/iam.md`; the helper is the only unauthenticated Cloud Run surface and exists solely to mint GIS ID tokens client-side.
- Added Terraform inputs for the upcoming `iam-helper` Cloud Run service so dev/prod can deploy the helper with `allUsers` invoke while still running under the shared `sa-app` runtime.
- Updated IAM documentation to include concrete Cloud Run URLs, explicit ID-token troubleshooting steps, and the Artifact Registry/Cloud Run deployment playbook for the helper.
- **Pivot:** Retired the helper SPA / GIS flow after repeated failures; removed all helper code, Terraform inputs, and docs references across proto/ui/infra. Identity now relies on IAP in front of every Cloud Run surface, with Terraform (next) managing the IAP policy for analyst Google Groups.

## 2025-11-20
- Consolidated the FastAPI, Streamlit, and Next.js console Cloud Run services onto the shared `sa-app` runtime service account so operators only manage one principal for UI workloads; Terraform now removes `sa-fastapi`, drops the console-specific account, and carries forward the required IAM roles on the shared identity.
- Tightened Cloud Run IAM by making Terraform manage the full `roles/run.invoker` binding, defaulting access to
	the shared runtime account plus `i4g_analyst_members` so services stay private while analysts can still reach them.
- Replaced the confusing `project_owner_members` variable with `i4g_analyst_members` and stopped auto-granting
	project Owner via Terraform; analysts now gain access either individually or through Google Groups listed in the
	new variable.

## 2025-11-18
- Resolved the Cloud Run intake job regression caused by missing job records when using API mode: updated the worker to treat 404 status updates as warnings, rebuilt `intake-job:dev`, and verified the end-to-end run in `i4g-dev` with API-hosted state.
- Documented the split between local and GCP smoke tests in `docs/smoke_test.md`, adding the new Cloud Run procedure (including baked-in environment variables) so future executions only need the intake/job identifiers.
- Captured the Cloud Run job configuration in code by updating `process-intakes` environment variables (`I4G_INTAKE__API_BASE`, `I4G_STORAGE__SQLITE_PATH`, vector toggle) and noted the verification commands to keep dev/prod parity checks straightforward.
- Logged the successful dev smoke run (FastAPI submission → Cloud Run job → case attachment) so the migration team can reference the baseline when revalidating infrastructure changes.

## 2025-11-16
- TODO: Confirm whether the `serverless-egress-nat` replacement (now `endpoint_types=["ENDPOINT_TYPE_SERVERLESS"]`) needs to include VM traffic; adjust before prod apply if any instances still rely on the default-network NAT.
- TODO: Run `terraform apply` for the dev VPC connector/NAT changes and replicate in prod (including the new Discovery editor binding) once the change window opens.
- Logged the first weekly incremental Azure SQL → Firestore sync (`data/intake_migration_report_20251115.json`) in the runbook, confirming counts and checksums remain stable while stakeholders exercise the MVP.
- Added detailed weekly procedures for Azure Blob and Cognitive Search refreshes so the unstructured data and Vertex AI Search indexes stay aligned with the MVP feedback loop.
- Introduced `scripts/migration/run_weekly_refresh.py` to execute the SQL, blob, and search cadences end-to-end (with summary artifacts under `data/weekly_refresh_<date>.json`) and documented how to use it or slice the flow per data type.
- Containerized the orchestrator (`docker/weekly-refresh-job.Dockerfile`), wired a dev-only Cloud Run job + scheduler via Terraform (with Secret Manager placeholders), and noted that prod remains disabled until we deliberately warm that cadence.
- Added `scripts/infra/add_azure_secrets.py` so operators can rotate Azure connection strings/admin keys in Secret Manager without relying on ad-hoc `gcloud` commands.

## 2025-11-15
- Closed out Milestone 2: Security/IAM blueprint finalized with Terraform WIF pipeline validated in CI, prod scaffolding documented, and a summary committed to the milestone outline so downstream teams adopt the two-project model with confidence.
- Captured MVP-ready migration notes: Vertex AI Search imports now include per-corpus `source` tags, the import helper gained a `--dry-run` mode for safe verification, and the runbook reflects the new validation flow for Discovery loads.
- Expanded the MVP roadmap with a weekly incremental migration cadence, GitBook stakeholder guide deliverable, and a refreshed two-week focus list so Phase 2 execution stays on track while documentation spins up.
- Retired `planning/azure_migration_notes_20251113.md` after folding its content into `planning/migration_runbook.md`, keeping a single canonical source for Azure-to-GCP migration steps across planning docs.

## 2025-11-06
- Added open-first guiding principle to migration plan.
- Published technology evaluation matrix covering identity, retrieval/search, and LLM hosting options.
- Drafted future-state architecture describing GCP-only, open-aligned topology.
- Created implementation roadmap sketching workstreams and sequencing.

## 2025-11-07
- Clarified future-state architecture vector-store placement and added managed vs local deployment profiles.
- Standardised configuration approach on Pydantic BaseSettings with environment-specific overrides.
- Refactored runtime settings into nested sections (`settings.api`, `settings.storage`, `settings.vector`, etc.) to enable per-component swaps between local resources and GCP services.
- Codified engineering defaults: prefer comprehensive type hints, Google-style docstrings, and focused inline comments to aid long-term maintainability.
- Added `planning/persistent_prompt.md` as the canonical session-rehydration checklist (scan planning docs, refresh change log, honor coding conventions).
- Added `src/i4g/services/factories.py` with helper builders for structured, review, and vector stores so services can instantiate backends directly from configuration.
- Migrated ingestion, retrieval, report generation, worker tasks, and CLI admin utilities to the new factory helpers so configuration-driven backend swaps propagate consistently.
- Began Milestone 2 prep: extracted action list from `migration_plan.md` and outlined upcoming architecture deliverables.
- Expanded `planning/future_architecture.md` with Mermaid topology diagram, detailed data-flow narratives, and capability replacement matrix to anchor Milestone 2 discussions.
- Documented preferred Mermaid preview tooling (`bierner.markdown-mermaid`) in `persistent_prompt.md` so contributors know how to view diagrams locally.
- Captured single-owner context in `persistent_prompt.md` (work assumed by Jerry, with Copilot support) to keep action items grounded.
- Elaborated the Security & IAM section (service accounts, secrets, monitoring) in `future_architecture.md` and marked the corresponding Milestone 2 workstream as drafted.
- Added automatic local-environment overrides (`mock` auth, SQLite/Chroma stores, Ollama, Secret Manager disabled) so the sandbox can run on a laptop without cloud credentials and documented the profile in planning notes.
- Introduced `scripts/bootstrap_local_sandbox.py` to recreate demo data with a single command, keeping the laptop environment reproducible.

## 2025-11-08
- Hardened the sandbox bootstrapper by prepending `src/` to `PYTHONPATH`, allowing subprocess helpers to run without installing the package in editable mode.
- Refreshed developer docs (`docs/dev_guide.md`, `tests/adhoc/README.md`) with the unified bootstrap flow, flag breakdown, and runtime guidance so onboarding stays accurate after the script change.
- Extended `future_architecture.md` Security & IAM section with Workload Identity Federation coverage, automation service account, artifact signing, access transparency, and a role-to-capability matrix to steer Milestone 2 security design.
- Updated `m2_task_outline.md` to capture the expanded IAM deliverables and mark the 2025-11-08 progress.
- Documented the Terraform-without-SaaS workflow in `infra/README.md`, selecting GCS-backed state, WIF-authenticated GitHub Actions, and a module roadmap that mirrors the IAM matrix.
- Added post-onboarding checklist for migrating projects under the official Google Cloud Organization/billing account once available.

## 2025-11-09
- Implemented `modules/iam/workload_identity_github` and wired dev environment to grant GitHub Actions `roles/iam.workloadIdentityUser` on `sa-infra`, enabling Terraform plans without service account keys.
- Added `.github/workflows/terraform-dev.yml` so PRs run Terraform fmt/plan via WIF and merges auto-apply to keep `i4g-dev` state in sync; documented repository variable requirements in `infra/README.md`.
- Captured Cloud Run refresh workflow for reusing container tags (`gcloud run services update ...`) and ran smoke tests: FastAPI queue seed/read succeeded with `I4G_STORAGE__SQLITE_PATH=/tmp/i4g_store.db`, Streamlit defaulted to the deployed API URL, and the analyst dashboard verified queue actions end-to-end after redeploy.

## 2025-11-10
- Reaffirmed single-owner delivery model: Jerry (with Copilot assistance) makes all technology and implementation decisions; stakeholder feedback is welcome but not gatekeeping. Documented this in `persistent_prompt.md` and status communications.
- Standardised environment naming on two GCP projects (`i4g-dev`, `i4g-prod`), retiring the generic “sandbox” framing except for local/offline security tests.
- Tightened risk tracking to focus on technology/architecture uncertainties (e.g., retrieval backend choice) rather than stakeholder availability.
- Updated `implementation_roadmap.md` to a 12-week execution plan reflecting the accelerated Milestone 2 progress to date.
- Enabled Gemini Cloud Assist (`cloudaicompanion.googleapis.com`) via Terraform so the dev project can use Gemini-assisted workflows without manual console toggles.

## 2025-11-11
- Locked in Milestone 2 architecture decisions: Google Identity Platform for auth, Vertex AI Search for retrieval, Vertex AI Gemini 1.5 Pro for inference, defer BigQuery until post-M3, and Terraform as IaC baseline.
- Expanded `future_architecture.md` §3.8 with a managed-vs-local capability matrix including swap mechanisms (`I4G_ENV`, backend selectors) to keep component choices portable.
- Updated `m2_task_outline.md` to mark the outstanding decisions register and managed/local appendix deliverables as complete, clearing the remaining Milestone 2 documentation backlog.
- Reaffirmed the two-environment plan (dev + prod), removed the temporary staging Terraform scaffolding, and refreshed docs to match the simplified promotion strategy.
- Scaffolded `infra/environments/prod` Terraform configuration with locked-down Cloud Run defaults (no public invokers, prod env vars, Vertex AI Search `retrieval-prod`) to prepare for Milestone 3 deployments.
- Captured the dev → prod promotion workflow (image tagging, Terraform apply cadence, post-deploy checks) in `infra/README.md` so deployments stay consistent.
- Drafted `planning/migration_runbook.md` with Azure → GCP data, identity, and job cutover procedures plus dry-run timeline, cutover/rollback playbooks, and validation templates (all owned by Jerry) to seed Milestone 4 execution.
- Implemented Terraform `storage/buckets` module with dev/prod wiring so Cloud Storage evidence/report buckets (with lifecycle rules and retention for prod) are provisioned alongside existing Cloud Run and IAM resources.
- Added Terraform `run/job` and `scheduler/job` modules, wiring ingestion/report Cloud Run jobs and their Cloud Scheduler triggers (with token impersonation bindings) into both dev and prod environments.
- Built Cloud Run job images for ingestion/report workflows (`docker/ingest-job.Dockerfile`, `docker/report-job.Dockerfile`) with new Python entrypoints (`i4g.worker.jobs.ingest`, `i4g.worker.jobs.report`) and documented the Artifact Registry build/push steps in the developer guide.
- Hardened the ingestion pipeline to run when embeddings are unavailable by making the vector store optional, letting the dev job succeed on Cloud Run without an Ollama backend.
