# DT-IFG Migration Change Log

Last updated: 21 Nov 2025_

This log captures significant planning decisions and architecture changes as we progress through the migration milestones. Update entries chronologically.

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
- TODO: Run `terraform apply` for the dev VPC connector/NAT changes and replicate in prod (including the new Discovery Engine editor binding) once the change window opens.
- Logged the first weekly incremental Azure SQL → Firestore sync (`data/intake_migration_report_20251115.json`) in the runbook, confirming counts and checksums remain stable while stakeholders exercise the MVP.
- Added detailed weekly procedures for Azure Blob and Cognitive Search refreshes so the unstructured data and Vertex AI Search indexes stay aligned with the MVP feedback loop.
- Introduced `scripts/migration/run_weekly_refresh.py` to execute the SQL, blob, and search cadences end-to-end (with summary artifacts under `data/weekly_refresh_<date>.json`) and documented how to use it or slice the flow per data type.
- Containerized the orchestrator (`docker/weekly-refresh-job.Dockerfile`), wired a dev-only Cloud Run job + scheduler via Terraform (with Secret Manager placeholders), and noted that prod remains disabled until we deliberately warm that cadence.
- Added `scripts/infra/add_azure_secrets.py` so operators can rotate Azure connection strings/admin keys in Secret Manager without relying on ad-hoc `gcloud` commands.

## 2025-11-15
- Closed out Milestone 2: Security/IAM blueprint finalized with Terraform WIF pipeline validated in CI, prod scaffolding documented, and a summary committed to the milestone outline so downstream teams adopt the two-project model with confidence.
- Captured MVP-ready migration notes: Vertex AI Search imports now include per-corpus `source` tags, the import helper gained a `--dry-run` mode for safe verification, and the runbook reflects the new validation flow for Discovery Engine loads.
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
