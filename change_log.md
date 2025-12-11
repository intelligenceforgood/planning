# DT-IFG Migration Change Log

Last updated: 10 Dec 2025_

This log captures significant planning decisions and architecture changes as we progress through the migration milestones. Update entries chronologically.

## 2025-12-10
- Finalized vault artifact handling: sharded GCS layout by artifact kind + SHA-256, immutable metadata with hash/size,
	scheduled hash verification job, and explicit lifecycle/hold guidance captured in `proto/docs/pii_vault.md`.
- Added `scripts/infra/verify_vault_secret_access.py` to impersonate app SAs and confirm vault Secret Manager bindings via
	Workload Identity; marked the cross-project verifier checklist item complete.
- Documented Cloud Run app integration: map `tokenization-pepper` and optional `pii-tokenization-key` secrets from the
	vault project into runtime env vars; stop keeping secret material in app projects. Captured in `proto/docs/pii_vault.md`
	and `infra/environments/pii-vault/README.md`.
- Added regression/smoke guidance: fail fast on missing/denied secrets and require a Cloud Run dev smoke (pepper read +
	tokenization/detokenization round trip) before promotion.
- Wired Terraform to match the dev binding: `environments/pii-vault/dev/terraform.tfvars` now grants
	`sa-app@i4g-dev.iam.gserviceaccount.com` Secret Manager + KMS access so applies mirror the gcloud change.
- Archived the completed `pii_vault_spike_checklist.md` into `planning/archive/` now that the spike deliverables are
	reflected in docs and the roadmap.

## 2025-12-09
- Rebuilt the PII vault design with globally deterministic tokens (`AAA-XXXXXXXX`), expanded prefix catalog (identity,
	gov IDs incl. student/employer, financial, crypto, network/device, health/biometric, vehicle, location, docs, `UNK`),
	and sharded artifact storage by type + content hash for indefinite retention.
- Captured the design in `proto/docs/pii_vault.md` (linked from `docs/architecture.md`); removed the stray doc from the
	end-user `docs` repo to keep developer vs end-user docs separated.
- Updated roadmap Milestone 5 and PII vault checklist to reflect cross-environment determinism, broadened detectors,
	prefix registry, and hashed artifact sharding tasks.

## 2025-12-05
- Wired dossier Drive uploads: `DossierUploader` now pushes manifest/markdown/PDF/HTML/signatures to the configured
  Shared Drive, records remote hashes in the signature manifest, and warns on checksum mismatches. Queue processor and
  generation tests cover the upload path plus PDF/HTML export presence.
- Added `scripts/verify_dossier_hashes.py` smoke helper to scan signature manifests under
	`data/reports/dossiers/` (or a provided path) and fail on missing/mismatched artifacts so local/dev runs can quickly
	validate dossier bundles.
- Recorded why `/reports/dossiers` verification kept failing: the admin principals only had `roles/owner`, which
	lacks `serviceAccounts.getAccessToken`, so `gcloud auth print-identity-token --impersonate-service-account=sa-report@i4g-dev.iam.gserviceaccount.com`
	returned `IAM_PERMISSION_DENIED` before we could reach the IAP endpoint. Added Terraform bindings in both
	`infra/environments/{dev,prod}/main.tf` granting `roles/iam.serviceAccountTokenCreator` on `sa-report` to every entry in
	`i4g_admin_members`, unblocking local/CI smoke tests that need to mint identity tokens for the dossier API.
- Extended the FastAPI IAP bindings (`infra/environments/{dev,prod}/main.tf`) with the `sa-report` principal directly so
	service-account identity tokens can clear IAP without stuffing the SA into the human analyst group. Cloud Run dossier
	verification now works headlessly once Terraform applies.
- Refreshed the dossier golden regression harness to include deterministic PDF/HTML exports and updated SHA-256 anchors
	after wiring the exporter into the generator. The golden test now asserts markdown/manifest/signature hashes and the
	presence of rendered exports.
- Added `templates/reports/dossiers/dossier_schema.json` to document required/optional dossier sections (plan, analysis,
	context, tools, assets, template render, exports, signatures) so UI/docs can align with the manifest contract.

## 2025-12-04
 - Split the analyst guidance into console-specific runbooks: `docs/runbooks/analyst_runbook.md` now serves as an index that
	links to `docs/runbooks/console/search.md` (hybrid search filters, schema refresh, saved-search migration) and
	`docs/runbooks/console/reports.md` (Evidence Dossiers workflow, inline signature verification, LEA handoff steps).
- Generated sanitized console screenshots via Pillow and committed the placeholders under
	`docs/assets/console/{dossiers-list,dossiers-verify}.png` so documentation can showcase the Reports tab without
	exposing real case data.
- Updated the Milestone 4 plan to note the new runbooks/screenshots under the Documentation & Enablement checklist,
	keeping the execution tracker aligned with the docs split.
- Expanded `tests/unit/reports/test_dossier_signatures.py` with base-path resolution + missing-hash regression cases so
	the manifest verification helpers now have deterministic pytest coverage.
- Added dossier queue smoke procedures to `docs/smoke_test.md`: local runs use `i4g-admin pilot-dossiers` followed by
	`i4g-dossier-job`, while the dev flow documents `gcloud run jobs execute dossier-queue` plus FastAPI verification so
	Cloud Run parity checks stay reproducible.

## 2025-12-06
- Completed portal parity for dossier downloads/verification: Next.js console now renders local/remote artifacts with
 - Completed portal parity for dossier downloads/verification: Next.js console now renders local/remote artifacts with
inline signature results, backed by an API download proxy (`/api/dossiers/download`) and SDK download typings. Added
Vitest coverage for download rendering.
- Updated milestone doc (Milestone 4) current-state to reflect portal parity; remaining gap is LEA distribution UX and
	optional client-side verification.
- Landed LEA handoff UX in the portal: dossier cards now surface a copyable LEA link banner plus in-browser hash
- Landed LEA handoff UX in the portal: dossier cards now surface a copyable LEA link banner plus in-browser hash
verification (Web Crypto) so analysts can prove downloads without backend calls. Added a client-side verification
Vite test and refreshed `docs/runbooks/console/reports.md` to cover the new flow and handoff steps.
 - Added `scripts/run_lea_pilot.py` to automate a local pilot dossier creation and verification harness via FastAPI TestClient.
 - Added `scripts/enqueue_sample_dossier.py` to populate the production-like SQLite queue so CI/Action runs can verify the real API.
 - Added GitHub Action `.github/workflows/nightly-smoke-dossiers.yml` to run the smoke test each night and fail on mismatches.
 - Added monitoring runbook (`docs/runbooks/console/dossier_monitoring.md`) with sample Prometheus / Grafana rules for mismatch/missing alerts.

## 2025-12-03

- Documented the Milestone 4 dossier runtime contract by adding a dedicated env-var table to
	`docs/dev_guide.md` (Drive parent ID, dossier loss/recency thresholds, hash algorithm, and Drive
	service-account scopes) so FastAPI, worker jobs, and Cloud Run deployments share the same
	configuration checklist.
- Introduced the `/reports/dossiers` FastAPI router (`src/i4g/api/reports.py`) backed by
	`DossierQueueStore.list_plans()`, exposing manifest/signature metadata plus inline payloads when
	requested. Added regression coverage in `tests/unit/api/test_reports.py` to assert manifest +
	signature rendering and to guard the warning path when a manifest file is missing.
- Surfaced the new reports API inside the Streamlit analyst dashboard: the **Evidence dossiers** panel
	(status filters, inline manifest toggle, download button, signature warnings) keeps LEA pilots
	unblocked until the Next.js portal consumes the endpoint. Session state + API helpers now live in
	`src/i4g/ui/{state,api}.py`, and the UI walks analysts through manifest/path validation.
- Extended `docs/dev_guide.md` with the Streamlit dossier viewer workflow and a manual regression
	checklist (pilot bundle generation → panel refresh → manifest/signature hash verification) so
	Milestone 4 smoke tests stay reproducible prior to LEA portal enablement.
- Added inline signature verification to the Streamlit dossier panel: each plan now exposes a
	**Verify signatures** action that hashes every artifact from `{plan_id}.signatures.json`, surfaces
	missing/mismatch counts inline, and renders artifact-level details for LEA reviewers. The dev
	guide now walks through the button-driven workflow plus the optional CLI hash cross-check.
- Landed the `dossier_candidate_metrics` SQLite view plus mirroring Firestore
	`bundle_metrics` payload so BundleBuilder + CLI runs can pull deterministic loss/geo bands and
	cross-border flags. `BundleCandidateProvider` now prefers the view (with StructuredStore
	fallback) and Firestore fan-out writes the metrics on every case document; unit tests cover the
	store helper, candidate provider, bundle metrics helper, and Firestore writer integration.
- Built the first dossier visual assets: loss timeline charts, GeoJSON feature collections, and
	world-map previews live under `src/i4g/reports/dossier_visuals.py` and are wired into
	`DossierGenerator`. Each generated manifest now references on-disk PNG/JSON assets, and pytest
	coverage exercises the renderers plus queue processor integration.
- Defined the dossier signature contract: `report.hash_algorithm` drives SHA-256 manifests,
	`dossier_signatures.py` hashes every artifact (manifest + visuals), and a companion
	`*.signatures.json` file ships alongside the dossier bundle. The generator exposes the signature
	file through `payload.signature_manifest`, and new tests cover the helper + queue processor flow.
- Kicked off Milestone 4 (Agentic LEA Evidence Dossiers) via `planning/milestone4_agentic_evidence_dossiers.md`, outlining
	the agent orchestration flow (BundleBuilder, LangChain tool suite, modular templates) plus the delivery plan for Weeks 7-8.
- Defined bundling criteria (loss thresholds, geo/cross-border flags, entity clusters) and the queue-driven dossier builder so
	Cloud Run jobs can deterministically select prosecutable case sets before invoking the agent pipeline.
- Captured dependencies for geo data licensing, signature strategy, and LEA portal auth while seeding next actions (chart
	renderer prototype, signature metadata contract, pilot dossier run) ahead of the implementation start.
- Updated the plan to route dossier artifacts through the Google Workspace Shared Drive (Drive parent ID controls, future
	subfolders/ACLs) instead of the `i4g-reports-*` bucket so LEA access mirrors Workspace governance.
- Added a curated pilot dataset (`data/manual_demo/dossier_pilot_cases.json`) plus `i4g-admin pilot-dossiers` so we can seed/queue three historical cases on demand; the helper writes structured + queue records, dry-runs plan generation, and ships with pytest coverage (`tests/unit/reports/test_dossier_pilot.py`).

## 2025-12-02
- Finished the Next.js hybrid-search UX polish: the console now forwards saved-search descriptors through `/api/search`,
  clears them the moment analysts tweak filters/entities, and includes Vitest coverage for the rerun flow to match the
  backend + Streamlit parity requirement.
- Expanded the Next.js `/search` Playwright smoke to exercise taxonomy + dataset toggles, the entity-filter builder,
  and the saved-search flow (prompt acceptance). `conda run -n i4g pnpm --filter web test:smoke` now runs clean so the
  milestone testing checklist item is satisfied end-to-end.
- Promoted the saved-search migration defaults into `[search.saved_search]` (settings + env overrides) so every CLI flag
	and helper script consumes the same source of truth. Added regression tests for the new settings and refreshed the
	exported manifests under `docs/config/`.
 - Documented the end-to-end analyst workflow (export → tag/annotate → import) in `docs/runbooks/analyst_runbook.md`, including
	the new `--schema-version` flag on `i4g-admin export-saved-searches` and the `scripts/tag_saved_searches.py` helper.
- Expanded the hybrid-search backend test suite with overlap/time-window/tie-breaker assertions in
	`tests/unit/services/test_hybrid_search_service.py`, closing the “pytest coverage” checklist item from the milestone.
- Authored `docs/hybrid_search_deployment_checklist.md`, covering required env vars, `TASK_STATUS` expectations, smoke
	tests, and observability counters for dev → prod promotions.
- Normalized all saved-search params through the `HybridSearchRequest` schema (API `/reviews/search/saved` now injects
	schema_version, structured filters, and ISO `time_range` values). Streamlit search now posts to `/reviews/search/query`
	and replays any saved search that contains structured filters, ensuring UI and Next.js share the same payload contract.
- `/reviews/search/query` now accepts optional saved-search descriptors (id/name/owner/tags) and persists them in
	review action logs so `/reviews/search/history` surfaces the saved-search title instead of “Untitled search.” The
	Next.js console passes this metadata through the SDK client, enriches saved-search rerun links, and updates history
	parsing/tests to render the saved-search badge + label when analysts rerun presets.

## 2025-12-01
- Extended the ingestion settings surface with first-class knobs for `dataset_path`, `batch_limit`, `dry_run`, and
	`reset_vector`, refreshed the config manifests in both proto/docs repos, and added regression coverage in
	`tests/unit/settings/test_settings_env_overrides.py` so TOML-driven runs stay fully tested. Introduced
	`config/settings.network_smoke.toml` (local) and `config/settings.dev_network_smoke.toml` (dev) so ingestion jobs can
	target the manual network-entity bundle without exporting transient env vars.
- Re-ran the ingestion worker against `i4g-dev` using the new config-only workflow:
	`I4G_ENV=dev I4G_SETTINGS_FILE=config/settings.dev_network_smoke.toml conda run -n i4g python -m i4g.worker.jobs.ingest`.
	Run `f43506cc-c41c-4edf-9c4a-5860010ee2e5` ingested `network-test-001`, persisted the record via SQL + Firestore, and
	pushed the document to Vertex AI Search (vector embeddings skipped because the Vertex vector backend is still
	unimplemented locally). This validates that the dev dataset now contains explicit browser-agent/IP/ASN entities.
- Spot-checked `/reviews/search/schema` under the same config (FastAPI `TestClient` + `X-API-KEY=dev-analyst-token`) and
	confirmed the endpoint returns the expanded indicator list (`browser_agent`, `ip_address`, `asn`, etc.), so the
	analyst UI can surface the new structured filters immediately after the dev ingestion run.
 - Drafted `docs/runbooks/analyst_runbook.md` so analysts can refresh the schema, run structured hybrid queries, and migrate saved
	searches via `i4g-admin` export/import workflows without waiting on ad-hoc Slack instructions.

## 2025-11-30
- Added a reusable observability helper (`src/i4g/observability.py`) that emits structured JSON logs plus StatsD/OTLP
	metrics based on the runtime settings, then wired `HybridSearchService` to record query counters, timings, cache hits,
	and structured summaries for every search request. Extended `ObservabilitySettings` with StatsD + service-name knobs,
	refreshed the config manifests/docs, and added pytest coverage for the new env overrides and observability hooks.
- Verified the ingestion pipeline emits browser agent/IP/ASN entities by enriching `prepare_ingest_payload` with
	structured network fields and adding dual-write regression tests so SQL/Firestore surfaces stay filter-ready for UI
	work. The milestone tracker now marks the ingestion verification task complete.
- Executed the ingestion backfill against `i4g-dev` using `python -m i4g.worker.jobs.ingest` with the Firestore + Vertex
	fan-out toggles enabled (`I4G_ENV=dev`, `I4G_STORAGE__FIRESTORE_PROJECT=i4g-dev`,
	`I4G_VERTEX_SEARCH_PROJECT=i4g-dev`, `I4G_VERTEX_SEARCH_LOCATION=global`, `I4G_VERTEX_SEARCH_DATA_STORE=retrieval-poc`). Run
	`01993af5-09ab-4ecf-b0c8-cd86702b8edd` processed all 200 cases in `retrieval_poc_dev`, dual-wrote SQL + Firestore, and
	recorded entity counts (820) in the ingestion tracker. Vertex AI Search only accepted 155 documents during the live run
	because the 200-case burst tripped the “Document batch requests per minute” quota (429 ResourceExhausted) after the
	initial batches landed.
- Replayed the backlog with `python -m i4g.worker.jobs.ingest_retry` (batch size 10) until the worker reported “No
	ingestion retry entries ready; exiting.” A total of 45 vertex payloads were reprocessed successfully with zero
	failures/drops once quota recovered, confirming the retry queue captured every rejected batch and the worker can drain
	dev-scale spikes. `scripts/verify_ingestion_run.py --run-id 01993af5-... --verbose` still shows `vertex_writes=155` and
	`retry_count=45` because the run tracker currently records retries but does not increment the vertex counter on replay;
	follow-on work will either update the tracker or adjust the verification script so it can validate “retries consumed”
	runs.
- Archived the Milestone 2 planning packet (`planning/milestone2_*.md`) now that the Dual Extraction deliverables are
	complete. The files live under `planning/archive/` for historical reference; all active tracking moves to the change
	log and roadmap.
- Replaced the ad-hoc environment-variable sprawl for ingestion jobs with TOML-backed configuration overrides. Pydantic
	settings now read `config/settings.default.toml` (tracked) plus developer-local `config/settings.local.toml` and an
	optional `I4G_SETTINGS_FILE` pointing to any single TOML. Docs/dev_guide + docs/config include examples so running the
	ingest worker, retry worker, or verification script in `i4g-dev` no longer requires a dozen env exports per command.
- Closed out Milestone 2 with the documentation refresh: roadmap + architecture docs now capture the dev backfill,
	retry drain workflow, and Vertex quota mitigations. Shifted the immediate roadmap focus toward Milestone 3 hybrid
	search design and the analyst UI structured-filter requirements.
- Kicked off Milestone 3 with the hybrid search design spike (`planning/milestone3_hybrid_search.md`). Captured the
	proposed `HybridSearchService`, deduplication/scoring policy, `/reviews/search/schema` contract, Streamlit/Next.js
	filter requirements, and the sprint-by-sprint delivery plan so engineering tasks can spin up immediately.
- Added a proper testing stack for the Next.js console: Vitest + Testing Library now cover the search experience helpers
	and entity-filter payloads, Playwright powers a `/search` smoke test that boots the dev server, and the package README
	documents `pnpm --filter web test` plus `test:smoke` so hybrid-search work can gate on automated checks.
- Mirrored proto’s automation discipline in the UI repo by adding `scripts/git-hooks/pre-commit` (Prettier check,
	`pnpm --filter web lint`, `pnpm --filter web test`) and documenting the symlink command in `ui/README.md` so every
	commit runs format + unit suites automatically.
- Added `I4G_UI_PRECOMMIT_QUICK=1` support to the hook for lint-only iterations, clarified in `ui/README.md` +
	`docs/dev_guide.md` that quick mode must be temporary, and documented when the Playwright smoke (`pnpm --filter web
	test:smoke`) is required (hybrid-search changes, routing/server-action updates, pre-release checks).

## 2025-11-29
- Forced a Firestore fan-out failure by running `python -m i4g.worker.jobs.ingest` with `I4G_ENV=dev`,
	`I4G_STORAGE__FIRESTORE_PROJECT=i4g-dev`, and `FIRESTORE_EMULATOR_HOST=127.0.0.1:8787` pointed at a closed port.
	Run `26ff94bf-4128-45f6-834f-d4e04658841d` ingested three cases (SQL writes succeeded) and enqueued retries for
	`romance_bitcoin-012`, `impostor_refund-012`, and `tech_support-038`, exercising the retry payload context.
- Installed `openjdk@21` so the `gcloud beta emulators firestore start` command can run locally, launched the
	emulator, and executed `python -m i4g.worker.jobs.ingest_retry` (dry run + live). The live pass replayed all three
	Firestore entries against the emulator, and a follow-up run reported `No ingestion retry entries ready; exiting`.
	Verified the run metadata via `scripts/verify_ingestion_run.py --dataset retry_demo --max-retry-count 3 --verbose` to
	confirm the retry counter increments while the status stays `succeeded`.
- Refreshed `docs/smoke_test.md` §2c with the working Firestore failure recipe (`I4G_STORAGE__FIRESTORE_PROJECT`,
	emulator instructions, and verification flags) so the retry smoke stays reproducible.
- Added an `i4g-ingest-retry-job` Cloud Run entrypoint plus docs/tests to drain `ingestion_retry_queue`. The worker
	replays Firestore + Vertex fan-out using the stored classification payload, enforces `settings.ingestion.max_retries`,
	and exposes a dry-run mode so queued work can be inspected without mutating state. `_maybe_enqueue_retry` now records
	the serialized `SqlWriterResult` + backend errors alongside each payload to power the replays.
- Fixed a regression where running `python -m i4g.worker.jobs.ingest` raised `NameError: _maybe_enqueue_retry` because the
	retry helpers were declared after the `if __name__ == "__main__"` guard. Moving `_clone_payload`, `_serialise_sql_result`,
	and `_maybe_enqueue_retry` above `main()` unblocks the CLI path and keeps the test imports unchanged. Re-ran the retry
	helper/job tests plus the ingress retry store tests to confirm coverage (12 passing).
- Completed the local vector-enabled smoke: `i4g.worker.jobs.ingest` ingested 50 records from `data/retrieval_poc/cases.jsonl`
	with embeddings reset, dual-wrote SQL successfully, and recorded run `22f54e5f-70e2-46d4-ae75-c08c2e61b0e6` in
	`/Users/jerry/Work/project/i4g/data/i4g_store.db` with case/sql counts (vector enabled). Followed up with
	`python -m i4g.worker.jobs.ingest_retry`, which exited cleanly because the queue was empty—validating the new worker path.
- Wired the ingestion job to the dual-write pipeline: IngestPipeline now emits a structured `IngestResult`, feeds the new SqlWriter (case/doc/entity tables), and exposes a run tracker that records progress in `ingestion_runs`. Added ingestion fan-out toggles/default dataset settings plus docs/test coverage so `I4G_INGEST__*` overrides stay source-of-truth.
- Implemented Vertex fan-out inside the ingestion pipeline: added a Vertex writer factory, document builder shared with the standalone Discovery scripts, payload normalization (dataset/categories/indicator IDs/tags), and worker toggles so `i4g-ingest-job` pushes each case to Vertex AI Search. Run tracker now increments vertex_writes, and smoke docs include a verification query.
- Followed up on the `account-list` Cloud Run smoke by executing `gcloud run jobs execute account-list --project i4g-dev --region us-central1` after clearing the `I4G_ACCOUNT_JOB__DRY_RUN` override. Execution `account-list-dvrq4` finished in ~78s but surfaced `Account list run account-run-cb63651e completed: indicators=0 sources=3` with warnings for every indicator category (bank/crypto/payments) because the LLM extractor could not reach Ollama inside Cloud Run.
- Pulled the job logs via `gcloud logging read ... account-list-dvrq4` and captured the stack traces showing both embedding and chat calls failing (`ConnectionError: Failed to connect to Ollama...`). Until we swap the provider to Vertex/mock for Cloud Run, the worker will keep falling back to text search and emit zero indicators, so this remains the top blocker for Milestone 1 validation.
- Exporter still produced local `/tmp/i4g/reports/account_list/account-run-cb63651e_20251129T005352Z.{pdf,xlsx}` artifacts, but no new objects landed in `gs://i4g-reports-dev/account_list/` for this run (confirmed via `gsutil ls`). Need to wire the warning propagation back through the API/worker responses and add automated alerts when uploads fail or produce empty indicator sets so analysts know the report is incomplete.
- Updated the job to run with `I4G_LLM__PROVIDER=mock` via `gcloud run jobs update ... --set-env-vars` and re-executed it (`account-list-5bd7f`). The run completed in 1m46s with the expected mock output (`account-run-92d1b4af`: 6 indicators / 3 sources), confirming the extractor path is unblocked once Ollama is bypassed in Cloud Run.
- Even with the mock provider, Chroma embeddings still try to call Ollama and emit warnings before falling back to text search; need to either disable embeddings in Cloud Run or route them through a managed backend so logs stop filling with connection errors.
- GCS uploads remain broken for dev runs: `/tmp/i4g/reports/account_list/account-run-92d1b4af_20251129T010107Z.{pdf,xlsx}` exist locally on the job, but `gsutil ls gs://i4g-reports-dev/account_list/*92d1b4af*` returned no matches. Track this alongside the warning-surface work so analysts get actionable signals when uploads fail.
- Set the job’s env vars explicitly (`I4G_ENV=dev`, `I4G_STORAGE__REPORTS_BUCKET=i4g-reports-dev`, `I4G_STORAGE__FIRESTORE__PROJECT=i4g-dev`, `I4G_LLM__PROVIDER=mock`, `I4G_ACCOUNT_LIST__ENABLE_VECTOR=false`). Execution `account-list-5pq2j` now disables vector search without error spam and uploads artifacts straight to `gs://i4g-reports-dev/account_list/account-run-6484995e_20251129T010803Z.{pdf,xlsx}`—confirms bucket wiring + warning surfacing path works once the env is set correctly.
- Wired audit/logging end-to-end: the `/accounts/extract` API now tags audit entries with a requester header (`X-ACCOUNTLIST-REQUESTER` fallback to client IP) and logs run counts/artifacts; the Cloud Run job records runs as `account_job:<env>`. `log_account_list_run` captures request metadata alongside indicator/source counts, and the refreshed unit tests cover the API, worker entrypoint, and audit helper.
- Extended the FastAPI router with `/accounts/runs` (pulling structured payloads from `ReviewStore`) and relaxed `/accounts/extract` so analyst `X-API-KEY` tokens can trigger runs without a separate service key. Updated the Next.js console with a dedicated `/accounts` page that launches manual runs, refreshes audit history via `/api/account-list/{run,runs}`, and surfaces artifact links + warning text directly in the UI.
- Completed the docs/settings sync (architecture overview, smoke guide, and config manifest) and retired `planning/account_list_execution_plan.md` plus `planning/milestone1_account_list.md` now that every task is shipped. Milestone 1 is officially closed, a new `planning/milestone2_dual_extraction.md` plan captures the next wave, and planning efforts shift to the dual-extraction pipeline.

## 2025-11-28
- Implemented Firestore fan-out inside the ingestion pipeline: added a Firestore writer with batch commits,
	wired it through the factory helpers, exposed `firestore_written` counters on `IngestResult`, and updated the
	worker job/run tracker so ingestion runs report `firestore_writes` alongside SQL/Vertex totals.
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
