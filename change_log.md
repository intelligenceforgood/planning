# Planning Change Log (active items only)

Last updated: 08 Feb 2026

This log keeps only decisions that affect future development. Older history lives in `archive/change_log_2025-12-14.md`.

## 2026-02-08
- **UI Mockup Sprint Closed**: All 9 console pages (Dashboard, Search, Cases, Taxonomy, Analytics, Reports/Dossiers, Accounts, Campaigns, Discovery) verified as fully connected to live backend endpoints. Zero `MOCK_` constants remain in production UI source. Deleted `planning/ui_mockup_assessment.md` — sprint complete.
- **Mock Fallback Removal (Full UI Cleanup)**: Removed all runtime mock fallback paths from `ui/apps/web/src/`.
  - **`i4g-client.ts`**: Deleted `getMockClient()`, `withMockFallback()`, and all `NEXT_PUBLIC_USE_MOCK_DATA` / `NEXT_PUBLIC_ENABLE_MOCK_FALLBACK` branching. `resolveClient()` now throws if no API URL is configured.
  - **`platform-client.ts`**: Removed `createMockClient` import, the `{ ...mock, ...restClient }` spread pattern, and the mock catch-fallback in `searchIntelligence`.
  - **`account-list-service.ts`**: Deleted `MOCK_RUNS` and `MOCK_RESULT` constants. `getAccountListRuns()` and `triggerAccountListRun()` now throw instead of silently returning fake data.
  - **SDK (`@i4g/sdk`)**: `createMockClient()` retained but marked test-only via JSDoc. No production code imports it.
  - **Env files**: Removed `NEXT_PUBLIC_USE_MOCK_DATA` from `.env.example` and `.env.local`.
  - **Planning**: Updated `ui_mockup_assessment.md` with completed removal status.
- **Search History Integration** (`ui/`): Removed static mock fallbacks (`MOCK_HISTORY`, `MOCK_SAVED_SEARCHES`) from `reviews-service.ts`. `getSearchHistory()` and `listSavedSearches()` now return empty arrays when the backend is unreachable instead of fake data. Backend `GET /reviews/search/history` verified working with real audit entries from `ReviewStore.get_recent_actions(action="search")`. Updated `ui_mockup_assessment.md` to mark task as completed.
- **Firestore Removal (Full Workspace Cleanup)**:
  - **Assessment**: Confirmed zero Firestore client code exists anywhere in the codebase. The `google-cloud-firestore` pip dependency was completely unused. `StorageSettings.structured_backend` Literal was already `['sqlite', 'cloudsql']`.
  - **Source** (`core/src/i4g/`): Removed orphaned `firestore_project` from `_apply_environment_overrides`, removed `_ingestion_bool("enable_firestore", ...)` block, updated CLI help text in `bootstrap/dev.py`, `bootstrap/local.py`, and `settings/manifest.py`.
  - **Settings** (`core/config/`): Removed `firestore_project` and `enable_firestore` from `settings.local.toml`, `settings.default.toml`, `settings.dev_network_smoke.toml`, `settings.network_smoke.toml`.
  - **Dependencies**: Removed `google-cloud-firestore` from `pyproject.toml` and regenerated `requirements.txt` via `pip-compile`.
  - **Manifests**: Regenerated `settings_manifest.{json,yaml}` in both `core/docs/config/` and `docs/config/` via `i4g settings export-manifest --docs-repo ../docs`.
  - **Tests**: Updated `test_ingestion_retry_store.py` and `test_ingest_job_retry_helpers.py` (`backend="firestore"` → `"cloudsql"`).
  - **Docs** (`core/docs/`, `docs/`): Cleaned ~100+ references across architecture, compliance, TDD, dev guide, glossary, smoke tests, cookbooks, config README, IAM, drawio cookbook, runbooks, and fraud taxonomy docs. Replaced Firestore with Cloud SQL / PostgreSQL references.
  - **Arch-viz**: Updated `system_topology.py`, `security_model.py`, `data_pipeline.py` to use `SQL` icon instead of `Firestore`.
  - **Copilot instructions**: Updated all 7 repo-level `.github/copilot-instructions.md` files.
  - **Migration scripts**: Marked `fix_and_run.sh` and `run_migration.sh` as deprecated with `exit 1`.
  - **Intentionally untouched**: `dtp/` (legacy archive), `infra/environments/app/prod/main.tf` (Terraform state — separate deprecation task).

## 2026-02-06
- **Account List Fixes (Dev Environment)**:
  - **Config**: Renamed `REPORTS_BUCKET` to `REPORT_BUCKET` (singular) across codebase and Terraform to enforce naming conventions.
  - **GCS Access**: Fixed 403 Forbidden errors by adding `roles/storage.objectAdmin` to Cloud Run SA. Implemented robust artifact link generation (Signed URL -> Authenticated Browser Link fallback) to handle missing credentials gracefully.
  - **Reliability**: Configured explicit `gemini-2.0-flash` model for Vertex AI in `dev`. Removed silent mock fallbacks in `AccountEntityExtractor` to ensure hard failures on LLM errors.

- **Discovery Integration & Mock Removal**:
  - **Decision**: Eliminated all static mock fallbacks for Discovery.
    - Frontend (`/api/discovery/search`) now returns a `503` if `I4G_API_URL` is missing, instead of fake data.
    - Backend (`_local_discovery_search`) now raises explicit exceptions if `HybridSearchService` fails (e.g., missing artifacts), instead of returning a static mock.
  - **Goal**: Ensure developers see real integration errors in critical path rather than masking them with "Mock hits".

- **Analytics & Reporting Redesign**:
  - **Status**: Completed.
  - **Backend**: Verified `GET /analytics/overview` returns schema-compliant real data.
  - **Frontend**: Full redesign of `ui/apps/web/src/app/(console)/analytics`. 
    - Aligned visual style with Case Workspace (Shell, Typography). 
    - Replaced custom icons with standard `@i4g/ui-kit` Badges.
    - Added `force-dynamic` rendering and loading skeletons.
  - **Integration**: Removed static mocks; page now relies on live API data (falling back only on explicit env config).

- **Bootstrap Consolidation**:
  - **Completed**: Unified bootstrap seeding logic, eliminating the standalone properties of `seed_cases.py`.
  - **Enhancements**:
    - Integrated seeding into `i4g bootstrap` for both `local` and `dev` environments.
    - Updated `ingest-job` and `fastapi` Docker images to include mock fixtures for consistent artifact serving.
    - Added `seed_reviews` support to `dev.py` and `admin/seed.py`.
  - **Cleanup**: Deleted legacy `core/scripts/seed_cases.py`.
  - **Verification**: Confirmed parity between local and dev seeding processes.

## 2026-02-05
- **Standardization: Review Queue Statuses**:
  - **Decision**: Standardized status lifecycle across Backend, UI, and Docs to eliminate legacy/conflicting terms (active/blocked vs in_review/awaiting_input).
  - **Status Set**: 
    - `new` (Triage)
    - `in_review` (Active investigation)
    - `awaiting_input` (Blocked external)
    - `accepted` (True Positive / Fraud)
    - `rejected` (False Positive / Safe)
    - `closed` (Admin/Duplicate)
  - **Impact**: Database schema migration (`review_queue.status` default=`new`), API filters update (`dashboard.py` excludes all 3 terminal states), and UI badge colors/filters updated.

## 2026-02-03
- **Case Workspace Implementation**:
  - **Backend**: Implemented `GET /cases/{id}` endpoint in `core.api.cases` serving structured mock data (Phase 1).
  - **Frontend**: Created `cases/[id]` detailed view with timeline, artifacts, and graph components.
  - **Integration**: Connected Case List "Open Case" button to the new view; full end-to-end data flow verified.

## 2026-02-02
- **Dashboard Backend & Build Stability**:
  - **Backend (Analytics)**: Implemented real analytics queries in `core` (Detection Rate, SLA, Trend lines) leveraging `i4g.store.sql`, replacing static mock responses.
  - **Frontend (Build)**: Resolved a critical build failure in `ui/apps/web` where a stale `.next` cache was serving legacy "Trafficking" taxonomy data, causing Zod schema validation errors.
- **Performance & UX (Cold Starts)**:
  - **Infrastructure**: Updated `infra/environments/app/dev/main.tf` to set `min_instances = 1` for `fastapi-gateway` and `i4g-console`. This prevents scale-to-zero latency (~15s) for the initial request.
  - **UX**: Added `ui/apps/web/src/app/(console)/search/loading.tsx` to provide an immediate skeleton UI response while data fetches, fixing the "unresponsive click" perception during page transitions.

## 2026-01-05
- **Performance Optimization (Classification Sweeper)**:
  - **Job Architecture**: Implemented asynchronous `classification-sweeper` Cloud Run Job to decouple ingestion from LLM latency.
  - **Stability Fixes**:
    - Updated `FraudClassifier` to handle empty JSON responses from LLM (treating them as valid "Unspecified" results rather than failures).
    - Fixed batch sizing logic to align fetch/classify/ensure-campaign steps.
    - Added Markdown code-block stripping to JSON parser for better LLM output resilience.
  - **Result**: Reduced classification error rate from ~35% (synchronous) to <0.2% (asynchronous/batched).

## 2026-01-04
- **Fraud Taxonomy (Phase 5)**:
  - **Database Schema**: Added `campaigns` table and updated `cases` table to store structured `FraudClassificationResult` (JSON) and link to campaigns.
  - **Campaign Logic**: Implemented `CampaignService` to map classification results (intents, actions, etc.) to campaigns based on taxonomy criteria.
  - **Integration**: Completed backend integration for persisting classification results and linking them to campaigns.

## 2026-01-02
- **Dev Environment Stabilization**:
  - **IAM**: Granted `roles/serviceusage.serviceUsageConsumer` to `sa-report` to fix 403 errors during report generation.
  - **Configuration Cleanup**: Removed all legacy `STORAGE__CLOUDSQL` variables from code and documentation. Standardized on `APP__CLOUDSQL` and `PII__CLOUDSQL`.
  - **Job Specs**: Fixed `seed_reviews` job in `dev.py` to explicitly use `sa-report` (was defaulting to `sa-ingest`).
  - **Local Verification**: Updated `settings.local.toml` to use the developer's active account (`jerry@...`) for Cloud SQL verification, aligning with local ADC credentials.

## 2025-12-31
- **Search & Infrastructure Fixes**: Resolved multiple "500 Internal Server Error" issues in `fastapi-gateway`.
  - **Backend (Vertex AI)**: Updated `VertexVectorStore` to robustly handle `struct_data` from Vertex AI Search. Implemented `MessageToDict` with a fallback for `MapComposite` objects (which lack `DESCRIPTOR`) to prevent `AttributeError` and JSON serialization crashes.
  - **Backend (ReviewStore)**: Added missing `ensure_placeholder_review` method to `SqlAlchemyReviewStore` to fix crashes in the search audit logging flow.
  - **Infrastructure**: Verified that `TOKENIZATION` environment variables were correctly renamed to `PII` in Terraform (`infra/environments/app/dev/main.tf`), resolving Cloud SQL connection failures.

## 2025-12-28
- **PII Vault Implementation**:
  - **Schema Isolation**: Separated PII Vault schema from main application schema. Created `VAULT_METADATA` in `sql.py` and a dedicated Alembic environment (`migrations_vault/`, `alembic_vault.ini`) to manage the `pii_tokens` table independently.
  - **Infrastructure**: Provisioned Cloud SQL instance `i4g-vault-dev-db` and KMS key ring `pii-vault-keyring` via Terraform.
  - **Migration**: Generated and applied initial schema migration for PII Vault. Verified isolation (only `pii_tokens` table exists in the vault DB).

- **OCR & Ingestion**:
  - Added PDF support to OCR pipeline via `pypdfium2`.
  - Added error handling for corrupt files in `tesseract.py` to prevent job crashes.
  - Added `--ingest-dry-run` flag to `i4g bootstrap dev` to allow testing extraction logic without DB writes.

## 2025-12-26
- **Search & Save Fixes**: Resolved "401 Unauthorized" and "500 Internal Server Error" issues in Search and Saved Search flows.
  - **Backend**: Updated `VertexVectorStore` to robustly handle `struct_data` vs `json_data` from Vertex AI Search. Renamed `save_search` to `upsert_saved_search` in `ReviewStore` to match API calls and fix FK constraints.
  - **Frontend**: Patched Next.js API routes (`reviews/saved`, `intakes`) to inject IAP OIDC tokens (`Authorization: Bearer ...`) alongside App API keys (`X-API-KEY`).
  - **SDK**: Updated `@i4g/sdk` to send API keys in `X-API-KEY` header instead of `Authorization` to avoid conflict with IAP tokens.
  - **Deployment**: Rebuilt and redeployed both `fastapi-gateway` and `i4g-console` to `dev`.

## 2025-12-24
- **Infrastructure**: Added Cloud SQL (PostgreSQL 15) provisioning to Terraform (`infra/environments/app/dev/database.tf`) including database and user management.
- **Security & Auth**: Addressed "403 Forbidden" errors in `i4g-console` by fixing OIDC token generation in `auth-helpers.ts`.
  - Identified that `google-auth-library` requires explicit `audience` parameter in `getRequestHeaders` to generate tokens.
  - Updated `ui/apps/web/src/lib/server/auth-helpers.ts` to include the fix.
  - Reverted `i4g-console` ingress to `internal-and-cloud-load-balancing` for security.
- **Documentation**: Added `docs/cookbooks/cloud_sql_primer.md` and updated `docs/cookbooks/bootstrap_environments.md`.

## 2025-12-22 (Session 2)
- **Security & Auth**: Fixed "401 Unauthorized" errors in `i4g-console` by implementing IAP-aware authentication for server-side API calls.
  - Injected `I4G_IAP_CLIENT_ID` into `i4g-console` Cloud Run service via Terraform.
  - Updated `platform-client.ts`, `account-list-service.ts`, and `reviews-service.ts` to generate OIDC tokens using `google-auth-library`.
  - Rebuilt and redeployed `i4g-console` image.
  - Verified `I4G_API_KEY` is correctly set in `terraform.tfvars` to ensure FastAPI authorization.
  - Confirmed `sa-app` service account has `roles/iap.httpsResourceAccessor` on the API backend.

## 2025-12-22
- **Bootstrap Fixes**: Resolved Cloud Run job failures in `dev_bootstrap` by fixing Docker entrypoints (switched `CMD` to `ENTRYPOINT`) and updating ingestion logic to support GCS directory paths (prefixes) for bundles.
- **Report Directory Refactor**: Standardized report output directories to `data/reports/bootstrap_dev` and `data/reports/bootstrap_local` (renamed from `dev_bootstrap`/`local_bootstrap`). Updated all CLI tools and documentation to reflect this change.
- **Documentation**: Updated `docs/cookbooks/bootstrap_environments.md` with correct job names, verification commands, and bundle URI formats.

## 2025-12-19
- Fixed Cloud Run job authentication: `process-intakes` now generates OIDC tokens for service-to-service calls to the API gateway.
- Updated `i4g bootstrap dev verify` to support IAP-protected environments by injecting local identity tokens.
- Refined bootstrap documentation: separated bundle preparation into [core/docs/cookbooks/prepare_bootstrap_bundles.md](../core/docs/cookbooks/prepare_bootstrap_bundles.md) and clarified smoke test expectations.

## 2025-12-11
- Repo rename to `core/` is complete. Flip any remaining `proto` references and use `I4G_API_KIND=core` going forward.

## 2025-12-16
- Data reset/bootstrap plan established for local + dev environments. Canonical bundles live in GCS with manifests; CLI flows will support wipe/import/verify across all storages. See [data_reset_bootstrap_plan.md](data_reset_bootstrap_plan.md).
- Local bootstrap verification now emits a bundle manifest hash and ingestion-run summary to catch stale datasets early.
- Optional dossier signature smoke added to local bootstrap (`--smoke-dossiers`) for end-to-end verification when API is up.
- Archived the data reset/bootstrap sprint plan to [planning/archive/data_reset_bootstrap_plan.md](../planning/archive/data_reset_bootstrap_plan.md) after completing all checklist items.

## 2025-12-10
- PII vault finalized: deterministic `AAA-XXXXXXXX` tokens, sharded GCS layout, and cross-project Secret Manager/KMS bindings
  captured in [core/docs/design/pii_vault.md](../core/docs/design/pii_vault.md). Cloud Run must read pepper/key via env vars.

## 2025-12-06
- LEA dossier flow: portal download + verification parity (API proxy + Web Crypto); nightly smoke covers `/reports/dossiers`.
  Use the signature manifest contract in [core/docs/design/architecture.md](../core/docs/design/architecture.md) for any new report work.

## 2025-12-02
- Hybrid search + structured filters are baseline: Vertex AI Search + SQL dual-write with retry queue. See ingestion settings in
  `config/settings.*.toml` and the retrieval contracts in [core/docs/design/architecture.md](../core/docs/design/architecture.md).
