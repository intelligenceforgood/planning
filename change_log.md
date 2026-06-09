# Planning Change Log (active items only)

Last updated: 09 Jun 2026

## 2026-06-09 - Antigravity 2.0 Model Routing & Token Economy Enhancements

Implemented standardized model routing rules and token budgeting guidelines across documentation, skills, and rules to optimize development costs and token efficiency in Antigravity 2.0.

- **Model Routing Rules:** Routed planning-tier skills strictly to Opus 4.6 (avoiding Gemini Pro for architecture), code review tasks to Sonnet 4.6, and implementation/execution-tier tasks to specific Gemini 3.5 Flash (H/M/L) and Gemini 3.1 Pro (H/L) variants.
- **Token Economy Guidelines:** Added guidelines for targeted search-and-replace edits, editor tab hygiene, subagent token budgets, and Gemini context strategies to `context-budget.md`.
- **Repos affected:** `antigravity/`, `planning/`.

## 2026-06-09 - Antigravity Workflow Migration and Scraper Test Fix

Migrated the GCA-style workflows into Antigravity-native configurations and resolved a critical mock-patch issue in the Google scraper tests.

- **Antigravity Workflows:** Added YAML frontmatter headers to standard files under `knowledge/standards/` to support repository-specific routing. Restructured the Antigravity workflows and skills under `.agent/` and `.agents/` directories.
- **Scraper Tests:** Fixed `tests/unit/osint/google/test_scrapers.py` by correcting quote formatting for the JSONP Maps response string and switching from `@pytest.mark.asyncio` to `@pytest.mark.anyio`. Swapped global `httpx.AsyncClient.get` mocking with a clean local `AsyncClient` mock.
- **Failed Experiment Cleanup:** Removed the temporary `bin/ag_headroom.sh` script and reverted all `gemini_api_base` proxy settings/routing changes in `core` and `ssi`.
- **Repos affected:** `antigravity/`, `ssi/`, `planning/`.

## 2026-05-09 - Impact Pages Modernization Phase 4: Architecture & Data Fetching Refactor

Implemented Phase 4 (Architecture & Data Fetching Refactor) for the Impact Pages Modernization.

- **Server-Side Fetching:** Transitioned `GeographyView` and `TaxonomyExplorer` to fetch initial data on the server side via their respective `page.tsx` components using the `getI4GClient` SDK methods.
- **Navigation Consolidation:** Removed the redundant `/impact/taxonomy` link from the Impact section in `navigation.tsx` and renamed the `/impact/taxonomy-explorer` label to "Taxonomy" to clean up the navigation menu.
- **Tests:** Updated `sprint4-views.test.tsx` to pass the required initial props (`initialSummaries` and `initialSankeyData`) to the React components. Verified all unit tests pass successfully.
- **Repos affected:** `ui/`, `planning/`.

## 2026-05-09 - Impact Pages Modernization Phase 3: Geography View

Implemented Phase 3 (Geography View Enhancement) for the Impact Pages Modernization.

- **Visual Map Integration:** Replaced the text list in `ui/apps/web/src/app/(console)/impact/geography/geography-view.tsx` with an interactive SVG world map using `react-simple-maps` and `i18n-iso-countries`. Color-coded countries based on case volume.
- **Richer Drill-Down Context:** Enhanced the detail view to include `victimCount` aggregate metrics alongside total cases and loss, plus recent cases.
- **Linting:** Fixed TypeScript and ESLint warnings for unused imports and explicit `any`.
- **Repos affected:** `ui/`, `planning/`.

## 2026-05-08 - Intelligence Pages Modernization Phase 3: Entity & Campaign Management

Implemented Phase 3 (Entity and Campaign Management) for the Intelligence Pages Modernization.

- **Bulk Entity Operations:** Added checkbox selection and a bulk action bar to `entity-explorer.tsx` to handle "Flag Selected" and "Add to Watchlist" actions via the `/api/intelligence/entities/bulk` endpoint.
- **Entity Status Toggling:** Replaced the static status badge in `entity-detail-panel.tsx` with an inline dropdown to manually update entity status using the `/api/intelligence/entities/status` endpoint.
- **Campaign Management Modal:** Implemented a new Client Component `manage-campaign-modal.tsx` and integrated it into the Campaign detail page (`campaigns/[id]/page.tsx`) to edit campaign status and name via `/api/intelligence/campaigns/{campaign_id}/manage`.
- **Validation:** Verified syntactic correctness using `eslint`.
- **Repos affected:** `ui/`, `planning/`.

## 2026-05-08 - Dashboard Revamp Phase 1: Frontend Enhancements

Implemented Phase 1 (Frontend Enhancements) for the Intelligence Dashboard Modernization.

- **Dashboard Charts:** Refactored Loss Trend Visualization in `ui/apps/web/src/app/(console)/intelligence/page.tsx` to render a `Recharts` area chart.
- **Chart Sharing:** Added `ShareDashboardButton` to the dashboard header that uses the `POST /charts/share` endpoint to generate an embed link.
- **Backend Fix:** Corrected the `user` dependency injection typing in `core/src/i4g/api/intelligence.py`'s `create_chart_share_token` endpoint.
- **Tests:** Ran existing unit tests and linting to ensure no regressions.
- **Repos affected:** `core/`, `ui/`, `planning/`.

## 2026-05-08 - Dashboard Revamp Phase 1: Backend Metrics

Implemented Phase 1 (Backend & Data Contract) for the Analyst Console Dashboard Revamp.

- **Backend Metrics:** Added `_get_engagement_completion`, `_get_loss_linkages`, and `_get_campaign_risk_scores` metrics to `GET /dashboard/overview` endpoint in `core/src/i4g/api/dashboard.py`.
- **Alerts:** Modified `_get_alerts` to return recent high priority cases and active campaign alerts.
- **Tests:** Created `core/tests/unit/api/test_dashboard.py` to verify the dashboard overview endpoint successfully returns the new metrics.
- **Repos affected:** `core/`.

## 2026-05-02 - PhishDestroy Sprint 4.4: SLO dashboards

Staged Sprint 4.4 (SLO dashboards) for the PhishDestroy integration. Note: due to billing issues, GCP deployments are skipped, and items are marked as implemented but not tested `[-]`.

- **Terraform:** Created `infra/modules/monitoring/dashboards.tf` containing a `google_monitoring_dashboard` resource for `phishdestroy_slo`.
- **Panels Added:**
  - Per-service daily-quota utilisation (`provider_quota_usage`)
  - p50 ingest-to-enqueue latency panel (`ingest_latency`)
  - Parse-failure rate per team (`parse_failure_rate`)
  - Blocklist-aggregator source health (`blocklist_source_health`)
- **Repos affected:** `infra/`, `planning/`.

## 2026-05-02 - PhishDestroy Sprint 4.3: Prod deployment (infra/ + core/)

Staged Sprint 4.3 (Prod deployment) for the PhishDestroy integration. Note: due to billing issues, GCP deployments are skipped, and items are marked as implemented but not tested `[-]`.

- **Terraform:** Configured `infra/environments/app/prod/terraform.tfvars` for production jobs:
  - Enabled `merklemap_tail` Cloud Run job.
  - Added `blocklist_aggregator` Cloud Scheduler.
  - Added `phishdestroy_archive` and `phishdestroy_actors` ingest jobs.
- **Secrets:** Added Secret Manager resource configs for `WHOXY_API_KEY` and `GHUNT_COOKIE_BLOB` in `infra/stacks/app/main.tf` under `ssi_secrets`.
- **Validation:** Executed `terraform fmt` and verified formatting with `terraform fmt -check` clean in `infra/stacks/app` and `infra/environments/app/prod`.
- **Repos affected:** `infra/`, `planning/`.


## 2026-05-01 - PhishDestroy Sprint 3.7: Verification

Completed Sprint 3.7 (Verification) for the PhishDestroy integration.

- **Audit Coverage:** Fixed `get_actor` endpoint in `phishdestroy_actors.py` to ensure every individual PII read (threat actor real name, leak record cleartext passwords, chat session transcripts) produces a distinct audit log entry with the appropriate `resource_type` and `resource_id`.
- **Tests:** Updated `test_phishdestroy_actors.py` to assert the correct audit log `resource_type` for threat actors.
- **Verification:** Completed the end-to-end analyst walkthrough in dev to verify the new audit logs.
- **Repos affected:** `core/`, `planning/`.


## 2026-05-01 — PhishDestroy Sprint 3.5: Actor API + RBAC + audit

Implemented Sprint 3.5 (Actor API + RBAC + audit) for the PhishDestroy integration.

- **Actors API:** Added `GET /actors` and `GET /actors/{id}` endpoints in `phishdestroy_actors.py`.
- **Filtering:** Added role, campaign, activity window, and threat-level filtering to `list_actors` in `ThreatActorStore`.
- **RBAC & PII Gating:** Enforced `role=senior_analyst` requirement for viewing PII fields (`real_name`, `password_cleartext`, `transcript`).
- **Auditing:** Wired up `audit_log.log_action` on every PII-bearing read requiring a `reason` query param or `x-reason` header.
- **Tests:** Wrote unit tests for RBAC denial paths.
- **Repos affected:** `core/`.




## 2026-05-01 — PhishDestroy Sprint 3 Phase 3: Actor Ingestion

Implemented Sprint 3 Phase 3 (Actor Ingestion & Graph Hydration) for the PhishDestroy integration.

- **Actors Ingestion:** Added `ingest_actors` routine to parse `data.json` and `registrants.json` into threat actors, identities, leak records, and registrant pivots.
- **Jobs:** Added `i4g-jobs-ingest-phishdestroy-actors` job and integrated it into the CLI.
- **Edges:** Implemented edge building for `shared_domain_registrant`.
- **Repos affected:** `core/`, `planning/`.

## 2026-04-30 — PhishDestroy Sprint 3 Phase 2: SSI Enrichment Modules

Implemented Sprint 3 Phase 2 (SSI Enrichment Modules) for the PhishDestroy integration.

- **OSINT Modules:** Added `whoxy_reverse.py`, `ghunt.py`, and `webarchive.py` to `ssi/osint/`.
- **Tests:** Added unit tests with recorded fixtures.
- **Repos affected:** `ssi/`.

## 2026-04-30 — PhishDestroy Sprint 3 Phase 1: Schema & Stores

Implemented Sprint 3 Phase 1 (Schema & Stores) for the PhishDestroy integration.

- **Schema:** Added `leak_records` and `registrant_pivots` ORM models and generated the corresponding Alembic migration.
- **Stores & Factories:** Created `LeakRecordStore` and `RegistrantPivotStore`, wired them into `factories.py`.
- **Tests:** Added comprehensive unit tests for both stores.
- **Repos affected:** `core/`.

## 2026-04-30 — Gemini CLI Workflow: Planner/Executor mitigations

Added new mitigations for Planner/Executor interface mismatches and hallucinated file modifications to workflow patterns.

- **Workflow Memories:** Updated `memories/repo/workflow-patterns.md` with rules for Executor adherence to structural contracts and diff verification for requested file modifications.
- **Repos affected:** `gemini/`, `planning/`.

## 2026-04-29 — PhishDestroy Sprint 2 Phase F: Campaign UI & Verification

Completed Sprint 2 by implementing the Campaign page UI cards (Damage Ledger, Infrastructure Profile, Actors placeholder), feature-flagging dossier template changes, running the full archive backfill in dev to verify the <1% parse failure rate, and verifying audit logs.

- **UI Implementation**: Added Damage ledger, Infrastructure profile, and Actors placeholder to the Campaign detail page (`campaigns/[id]/page.tsx`).
- **Dossier Template**: Wrapped Sprint 2 additions in a feature-flag check in `lea_dossier.md.j2`.
- **Verification & Backfill**: Executed full archive backfill with 0% parse failures on synthetic and TWP datasets. Verified audit-log entries are generated for ingested PII-bearing rows (`chat_sessions`).
- **Repos affected:** `core/`, `ui/`, `planning/`.

## 2026-04-29 — Gemini CLI Workflow: Wrap-up and Merge Routine

Added a new "Sprint Wrap-Up and Merge" routine to the Gemini configuration. This chains the sprint-wrapup and merge prompts to streamline the end-of-sprint workflow.

- **Prompts & Snippets:** Created `@prompts/wrapup-and-merge.md` and registered the `gca-wrapup-merge` snippet.
- **Workflow Memories:** Bootstrapped `memories/repo/` with `lessons-learned.md` and `workflow-patterns.md`, documenting mitigation strategies for destructive updates to trackers by AI executors.
- **Repos affected:** `gemini/`.

## 2026-04-29 — PhishDestroy Sprint 0.5: Unblocking & Resumption

Resumed work on the PhishDestroy integration, addressing pending blockers and preparing for local-only development due to zero-budget constraints.

- **Design Execution:** Drafted wireframes for the UI cards (Damage Ledger, Infra Profile) and the `/actors` view in `ui/docs/design/phishdestroy_ui_wireframes.md`.
- **ML Schema Definition:** Defined the BigQuery schema for `i4g_ml.actor_features` in `ml/docs/schema/actor_features.md`.
- **Budget Constraints:** Configured the plan to develop all features but add configuration flags to disable API calls and use free tiers or local mock data where possible.
- **Keys and Approvals:** Rotated Merklemap and Whoxy API keys and obtained Counsel sign-off on PII storage.
- **Repos affected:** `ui/`, `ml/`, `planning/`.


## 2026-04-25 — PhishDestroy Sprint 1 Wrap-up: E1 cleanups + Phase D-local smoke + Phase F docs

Closes Sprint 1 (Phases A–E2). All remaining GCP-gated items (Phase D2: `terraform apply`,
secret population, 30-min Cloud Run smoke) are deferred to Sprint 2 once billing is restored.

- **E1 drift cleanups (`core/`):** renamed `_trigger_ssi_scan` → `enqueue_passive_scan_for_domain`
  (public helper; caller no longer passes `settings=`); added `DomainDiscoveryStore.get()`
  public accessor; rewrote router `_get_row_or_404` to use the public accessor instead of
  reaching into `store._session_factory()`. Removed unused `get_settings` import from the
  router. Tests updated to match new helper name.
- **Local smoke script (`core/scripts/smoke_merklemap_tail_local.py`):** validates
  `PHISHDESTROY__MERKLEMAP_TAIL__API_KEY` and prints (does NOT execute) the `docker run`
  command for a no-GCP rehearsal of the `ingest-job:dev` image.
- **Dev doc (`core/docs/design/phishdestroy-integration.md`):** architecture overview, data
  model, stores/factories, settings table, provider-gating + provenance contract links,
  worker lifecycle, API surface, local smoke pointer, open items.
- **End-user doc (`docs/book/analyst-guide/discoveries.md`):** analyst walkthrough of the
  /discoveries page — columns, Enqueue/Dismiss actions, typical workflow.
- **SUMMARY.md:** added Discoveries entry under Intelligence Tools.
- **Manifest:** `planning/handoffs/2026-04-25-phishdestroy-sprint-1-wrapup.manifest.md`.
- **Repos affected:** `core/`, `docs/`, `planning/`.

## 2026-04-25 — PhishDestroy Sprint 1 Phase D1: merklemap-tail Terraform (no apply)

Phase D1 lands all Terraform code for the dev `merklemap-tail` Cloud Run job — Secret Manager
resource, `run_jobs` map entry (dev `enabled=true`, prod mirrored with `enabled=false` per
parity rule), and `sa-ingest` invoker grant on `ssi-svc`. **No `terraform plan` / `apply` and
no live smoke** — those are Phase D2 (deferred until GCP billing on `i4g-dev` is restored).

- **Infra (`infra/stacks/app/main.tf`):** new `google_secret_manager_secret.merklemap_api_key`
  resource (auto replication, `service=phishdestroy` label); `module "run_ssi_service"` invoker
  list extended with `sa-ingest` so the merklemap-tail core image can POST `/trigger/investigate`.
- **Infra (`infra/environments/app/dev/terraform.tfvars`):** `merklemap_tail` job — reuses
  `ingest-job:dev` image, runs `i4g jobs merklemap-tail --max-runtime-seconds=1800` (30-min
  bounded), CloudSQL via `sa-ingest@i4g-dev.iam`, secret env `PHISHDESTROY__MERKLEMAP_TAIL__API_KEY`
  + `I4G_CRYPTO__PII_KEY`. SSI URL is a `https://ssi-svc-PLACEHOLDER-uc.a.run.app` placeholder
  — Phase D2 must replace with the live URL before `terraform apply`.
- **Infra (`infra/environments/app/prod/terraform.tfvars`):** parity mirror, `enabled=false`,
  `i4g-prod` project / image / secrets. Stays inert until Sprint 4 SLO sign-off.
- **Verification:** `terraform fmt -check -recursive` clean; `terraform validate` clean in both
  dev and prod (offline `init -backend=false`). Diff scoped to the three intended files.
- **Workflow:** This manifest was a corrective re-issue of the original Phase D bundle that
  conflated local Terraform code with `plan`/`apply`/live smoke — when GCP billing was paused,
  the bundle became unblockable. Lessons recorded as Planner rules **7** (predecessor gates check
  commit existence, not push state) and **8** (split manifests at the local/external boundary)
  in `copilot/.github/shared/handoff-manifest.instructions.md`.
- **Manifest:** `planning/handoffs/2026-04-25-phishdestroy-sprint-1-phaseD1.manifest.md`.
- **Repos affected:** `infra/`, `planning/`, `copilot/` (workflow rules update).

**Deferred to Phase D2 (when GCP billing restored):**

```bash
cd infra/environments/app/dev && make plan       # confirm only intended deltas
cd infra/environments/app/dev && make apply      # apply secret + job
gcloud secrets versions add merklemap-api-key \
  --data-file=- --project=i4g-dev                # paste rotated key on stdin
# Replace I4G_SSI__SERVICE_URL placeholder with live ssi-svc URL:
gcloud run services describe ssi-svc \
  --region=us-central1 --project=i4g-dev --format='value(status.url)'
# Confirm ingest-job:dev image rebuilt AFTER Phase C commit 40a69eb:
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/i4g-dev/applications/ingest-job \
  --include-tags --filter='tags:dev'
gcloud run jobs execute merklemap-tail --wait \
  --region=us-central1 --project=i4g-dev          # 30-min smoke
```

## 2026-04-24 — PhishDestroy Sprint 1 Phase C: merklemap-tail worker (core/)

Phase C lands the `merklemap-tail` streaming worker in `core/`. SSE client + bounded
async pipeline → `domain_discoveries` upserts → brand-regex filter match → enqueue passive
SSI scan via `ssi_scan` row. Worker runs to completion under `--max-runtime-seconds`
or `--max-events`; honors SIGTERM for Cloud Run job graceful shutdown.

- **Client (`core/src/i4g/clients/merklemap.py`):** async SSE consumer (`httpx.AsyncClient`),
  exponential reconnect backoff capped at 30s, JSON-line parsing with malformed-line skip,
  per-event `source_provenance(source="merklemap.tail", record_id=f"merklemap:{event_id}")`.
- **Worker (`core/src/i4g/worker/jobs/merklemap_tail.py`):** orchestrates client + stores;
  upserts every event to `domain_discoveries`; matches against
  `phishdestroy.merklemap_tail.brand_regexes` (8 brands by default — Trust Wallet, Coinbase,
  Ledger, MetaMask, Binance, Phantom, Uniswap, OpenSea); on match enqueues `ssi_scan` row
  with `kind="passive"`. Emits per-minute metrics: domains/sec, match rate, scans enqueued.
  Bounded memory (single-event scope, no buffering).
- **CLI (`core/src/i4g/cli/jobs/__init__.py`):** `i4g jobs merklemap-tail` — flags
  `--max-runtime-seconds`, `--max-events`, `--brand-regex` (repeatable override), `--dry-run`
  (no enqueue, log only). Reuses settings via `get_settings().phishdestroy.merklemap_tail`.
- **Settings (`core/src/i4g/settings/sections/jobs.py`):** new `MerklemapTailSettings`
  block — `enabled`, `api_key` (Secret Manager), `sse_url`, `brand_regexes`, `request_timeout`.
  Env vars `PHISHDESTROY__MERKLEMAP_TAIL__*` (provider-gated; default disabled).
- **Tests:** 230 LOC of unit tests for the worker (filter match, enqueue contract, SIGTERM
  handling, max-runtime/max-events caps) + 129 LOC for the client (reconnect backoff cap,
  malformed-line skip, provenance shape) + 42 LOC for settings. All use `httpx.MockTransport`;
  zero live network in CI.
- **Settings drift (`core/docs/config/settings_manifest.yaml` + `docs/config/settings_manifest.yaml`):**
  53-line `phishdestroy.merklemap_tail.*` block added to both copies (drift-check requires both).
- **Manifest:** `planning/handoffs/2026-04-24-phishdestroy-sprint-1-phaseC.manifest.md`.
- **Repos affected:** `core/`, `docs/`, `planning/`.

## 2026-04-24 — PhishDestroy Sprint 1 Phase B: destroylist ingestion (core/)

Phase B lands the `i4g jobs ingest-destroylist` CLI command and the underlying
ingestion module. Pulls from the pinned DestroyScammers `data.json` commit
(`c40cbbf5…`, 2025-11-30); idempotent on `(source, commit_sha, record_id)`.

- **Ingestion (`core/src/i4g/ingestion/phishdestroy/destroylist.py`):** fetches `data.json`
  at the pinned SHA from `raw.githubusercontent.com`; per-record provenance built by
  `build_source_provenance(source="phishdestroy.destroylist", commit_sha=PINNED, record_id=...)`;
  emits `BlocklistHit` upserts. Idempotent — second run on same SHA inserts 0 rows.
- **Worker job (`core/src/i4g/worker/jobs/phishdestroy_destroylist.py`):** Cloud-Run-friendly
  entry point; honors `--dry-run`, returns ingest counts in structured logs.
- **CLI (`core/src/i4g/cli/jobs/__init__.py`):** `i4g jobs ingest-destroylist` (dash-separated;
  sub-app refactor deferred). Reads provenance pin + endpoint from settings.
- **Settings (`core/src/i4g/settings/sections/jobs.py`):** new `PhishDestroyDestroyListSettings`
  block — `enabled`, `commit_sha` (pinned), `data_url`. Env vars `PHISHDESTROY__DESTROYLIST__*`.
- **Tests:** 156 LOC for ingestion (idempotency, malformed records, partial network failure),
  47 LOC for shared `build_source_provenance` helper, 51 LOC for settings; fixtures committed
  under `tests/unit/ingestion/phishdestroy/fixtures/destroylist_sample.json`.
- **Smoke:** `I4G_ENV=local i4g jobs ingest-destroylist` produced 23,561 rows on first run; 0
  inserted on second run (idempotency confirmed).
- **Settings drift (`core/docs/config/settings_manifest.yaml`):** 27-line
  `phishdestroy.destroylist.*` block added.
- **Provenance contract clarification (`copilot/.github/shared/phishdestroy-provenance.instructions.md`):**
  one-line edit confirming `record_id` is sourced from `data.json` rows, not registrants.
- **Manifest:** `planning/handoffs/2026-04-24-phishdestroy-sprint-1-phaseB.manifest.md`.
- **Repos affected:** `core/`, `copilot/`, `planning/`.

## 2026-04-24 — PhishDestroy Sprint 1 Phase A: SSI OSINT modules + provider gate

Phase A of Sprint 1 (§1.3 in `tasks/phishdestroy_integration_tasks.md`) landed in `ssi/`. Three OSINT modules + a shared provider-gating primitive + 44 unit tests, all opt-in (every provider `enabled = false` by default). No `core/`, `infra/`, `ui/`, or `docs/` changes — Phases B–E ship as their own manifests.

- **New SSI modules** (`ssi/src/ssi/osint/`):
  - `blocklist_aggregator.py` — 8-source feed scanner (MetaMask, ScamSniffer, OpenPhish, SEAL, Enkrypt, destroylist, Polkadot, CryptoFirewall); 6h file cache keyed by `sha256(url + ingest_date_bucket)`; per-source circuit breaker (3 consecutive failures → skip rest of run); emits one record per `(indicator, source)` with full `source_provenance` (SHA-1 commit_sha pin).
  - `ctlog_lookup.py` — crt.sh JSON subdomain enumeration; exponential backoff on 429 (`2^n` capped at 30s, max 5 retries); each entry carries `source_provenance(source="ctlog.crtsh", record_id=f"crtsh:{entry_id}")`.
  - `merklemap_client.py` — async SSE tail via `httpx.AsyncClient`; reconnect with exponential backoff capped at 30s; gates on `ProviderGate("merklemap")` and yields `SkippedResult(reason="quota_gated")` when disabled (default).
- **New shared primitive** (`ssi/src/ssi/providers/gate.py`) — `ProviderGate` + `SkippedResult` with `SkipReason = Literal["quota_gated", "auth_expired", "rate_limited", "disabled"]`. Hoisted into its own home file so Sprint 1.5+ providers (whoxy, ghunt) can import without redefining.
- **Settings** — new `[phishdestroy]` section + 3 sub-sections in `ssi/config/settings.default.toml`; `PhishDestroySettings` wired into root `Settings`. Reads via `get_settings().phishdestroy.<name>.enabled`. No env-var direct reads in osint/**init**.py.
- **Spike-script update** — `ssi/scripts/spike_merklemap.py` `DEFAULT_URL` corrected to `/live-domains?no_throttle=true` after confirming against `merklemap-cli/src/lib.rs @ 550cb04`.
- **Tests** — 44 unit tests passing (`tests/unit/providers/test_gate.py`, `tests/unit/osint/test_{blocklist_aggregator,ctlog_lookup,merklemap_client}.py`). All use `httpx.MockTransport` — zero live network calls. Covers gate enable/disable, env-var prefix, circuit breaker, 429 backoff cap, SSE reconnect.
- **Repos affected:** `ssi/` only.
- **Env vars / config:** New opt-in flags `SSI_PHISHDESTROY__BLOCKLIST_AGGREGATOR__ENABLED`, `SSI_PHISHDESTROY__CTLOG_LOOKUP__ENABLED`, `SSI_PHISHDESTROY__MERKLEMAP_CLIENT__ENABLED` (all default `false`). No production env-var changes required.
- **Manifest:** `planning/handoffs/2026-04-24-phishdestroy-sprint-1-phaseA.manifest.md`. Supersedes the L-scope five-phase bundle (`2026-04-24-phishdestroy-sprint-1.manifest.md`) which failed fidelity and was retired.
- **Workflow note:** Pre-merge review for the failed bundle prompted a new `copilot/.github/shared/handoff-manifest.instructions.md` "Scope cap: one phase per manifest" section (heuristics: > 8 turns, > 1 repo, > 1 commit checkpoint, > 8 files → split). Phase A re-issued under that cap shipped clean in 6 turns.

## 2026-04-22 — Mobile Sprint 5: Settings, Telemetry, Polish, Dogfood

Sprint 5 work: full Settings screen, Sentry wiring with PII redaction, filter-aware auto-pop (Sprint 4 follow-up), OAuth docs, and developer-guide updates.

- S5.1 Settings screen: Full implementation replacing stub — profile label (`LOCAL · direct · mock`), app version from `expo-constants`, Sentry toggle (Zustand `sentryEnabled`), sign-out (`auth.signOut` + `clearUser` + `router.replace('/sign-in')`), dev-only profile switcher via `SecureStore` + `DevSettings.reload`.
- S5.2 Filter-aware auto-pop: `handleDecisionSuccess` in `case/[id].tsx` reads `currentQueueFilter` from store, computes post-decision status, and calls `router.replace('/(tabs)/queue')` when filter no longer matches. `currentQueueFilter` slice added to `ui.ts`. `queue.tsx` syncs local `filter` to store on change (deviation from files list — necessary consequence).
- S5.3 OAuth client config: Documented GCP console click-path in `developer-guide.md` §5.5. Live sign-in test deferred — requires human at GCP console and physical device.
- S5.4 Sentry wiring: `@sentry/react-native` 8.8.0 installed. `src/lib/sentry.ts` created (`initSentry`, `sentryEnabled`). `redactEvent` extended for full Sentry event shape (user, request, extra, contexts, tags, breadcrumbs). Logger production branch wired with `addBreadcrumb`. Expo plugin added to `app.config.ts`.
- S5.5 Docs / cleanup: `mobile/docs/release-flow.md`, `contributing.md`, `token-flow.md` created. `developer-guide.md` updated with OAuth section, Sprint 5 gotchas (Sentry install, DSN, `beforeSend` type), and Appendix D DoD checklist. Design tokens build confirmed clean. **Post-sprint cleanup:** `planning/proposals/mobile-prototype/{architecture,tdd,developer-guide}.md` moved to `mobile/docs/`; `prd.md` renamed to `planning/prd_mobile_prototype.md`; interim `implementation-plan.md` and `README.md` deleted (git history preserves them).
- Tests: 5 new test files added (sentry, redact.event, settings component, CaseDetailScreen filter logic, queue filter sync) — all pass. `pnpm lint` exits 0. `pnpm typecheck` and `pnpm test` both inherit pre-existing failures from main (16 `theme.color.error/on/priority` missing-token errors; 3 test suites `CaseHeader`/`DecisionSheet`/`CaseDetailScreen` affected by the same) — **not introduced by Sprint 5**; tracked as a Sprint-6 theme-token follow-up.
- Deferred: Live Sentry crash-report validation (needs real DSN + device); live OAuth sign-in against `dev.intelligenceforgood.org` (needs human at GCP console); second-developer acceptance test (needs willing second dev); `mobile-prototype-v0.1` git tag (manual push after human validation).

## 2026-04-22 — Mobile Sprint 4: Approve / Reject decision flow

Sprint 4 write-side work: full Approve / Reject round-trip wired on mobile. S4.1–S4.3 acceptance criteria satisfied.

- New `DecisionSheet` component (`Modal` + segmented control + notes `TextInput`): calls `useDecide(reviewId).mutate(…)`, shows optimistic update, rolls back with inline error banner on failure.
- `ToastHost` added to `_layout.tsx`; auto-dismisses each toast after 3 s via Zustand; uses `pointerEvents="box-none"` so the overlay doesn't swallow touches.
- `CaseHeader` `Decide…` button live-wired via new `onDecide` prop; `(Sprint 4)` label and forced-disabled state removed.
- `case/[id].tsx`: `sheetOpen` state, `handleDecisionSuccess` (fires `pushToast` + closes sheet), navigation stays on detail screen (filter-aware auto-pop deferred to Sprint 5).
- New tests: `DecisionSheet.test.tsx` (5 scenarios), `useDecide.test.tsx` (optimistic + rollback contract), plus new `onDecide` test in `CaseHeader.test.tsx`. All 117 tests green.
- Maestro `happy-path.yaml` extended with decide → submit → toast-success steps (all `optional: true` for CI safety).

## 2026-04-22 — Mobile Prototype Sprint 3 (Case Detail, Evidence, Reports)

Delivered J4 (Case Detail) and J5 (Report Viewer) screens against `i4g-local`. Endpoint gaps from Sprint 1 fully resolved. Split-model flow: Planner manifest → Executor (Sonnet) → Planner verify → inline drift fixes (Planner). Verdict: Pass (after inline fixes).

**Code changes (mobile only):**

- New screens: `app/case/[id].tsx` (multi-section Case Detail), `app/case/[id]/evidence/[eid].tsx` (pinch-to-zoom Evidence Detail), `app/case/[id]/report.tsx` (PDF viewer via `react-native-pdf`)
- New features: `src/features/evidence/` (types, queries, `EvidenceGrid` component), `src/features/reports/` (types, queries)
- New components: `CaseHeader`, `CaseSummarySection`, `CaseClassificationSection`, `CaseTimelineSection`, `AuditLogSection` (collapsible FlatList), `SectionErrorBoundary` (per-section error isolation)
- `src/features/reviews/types.ts` — `CaseDetail` schema replaced with verified shape from `GET /cases/{case_id}`; new `CaseArtifact`, `CaseTimelineEntry` schemas. `ReviewPriority` kept as `.catch('medium')` for defensive parsing of unknown server values.
- `src/features/reviews/queries.ts` — added `useCaseFull(reviewId)` fan-out (review + case + audit in parallel). `useCase` repointed to `ReviewDetail`; `useDecide` optimistic-update key updated in sync.
- `app/(tabs)/queue.tsx` — rows now tappable (`TouchableOpacity` wrapper, `router.push('/case/${id}')`).
- `app/_layout.tsx` — root wrapped in `GestureHandlerRootView` for pinch-to-zoom support.
- `e2e/flows/happy-path.yaml` — extended with Queue → Case Detail → Evidence → back → Report flow.
- New tests: `EvidenceGrid.test.tsx`, `CaseHeader.test.tsx`, `AuditLogSection.test.tsx`, `reports.queries.test.tsx` (MSW contract: signed-URL + bearer-stream + 404 branches).
- `src/design/tokens.ts` — added `color.priority.{critical,high,medium,low}`, `color.error.*`, `color.on.badge` semantic tokens.
- Planner inline fixes: replaced all hardcoded `#RRGGBB` literals in Sprint 3 files with new semantic tokens.

**New dependencies added (mobile/app):**
`expo-image ~3.0.11`, `react-native-pdf ^7.0.4`, `react-native-blob-util ^0.24.7`, `react-native-gesture-handler ~2.28.0`, `react-native-reanimated ~4.1.7`

**Endpoint verification completed:**
`planning/proposals/mobile-prototype/sprint3-endpoint-verification.md` — all three Sprint 1 gaps resolved:

- `GET /cases/{case_id}` → `CaseDetail` (description=summary, tags=classification, timeline included)
- `GET /cases/{case_id}/evidence` → `EvidenceList` with `available` flag for binary-only docs
- `GET /reports/{report_id}/download` → bearer-auth stream (no signed-URL redirect); worker must be running

**Follow-ups for Sprint 4 / cleanup:**

- Replace hardcoded colors in Sprint 2 files (`FilterBar.tsx`, `QueueRow.tsx`) with theme tokens — same pattern already fixed for Sprint 3 files.
- Fix Zustand "update during render" warning in `dashboard.tsx` (tracked from Sprint 2).
- Reviews coverage gate still at 57% for legacy hooks; add coverage when those hooks are touched in Sprint 4.

**No infra, no backend, no env var changes. Mobile repo only.**

---

## 2026-04-22 — Mobile Prototype Sprint 2 (Dashboard + Reviews Queue)

Delivered J2 (Dashboard) and J3 (Reviews Queue) screens against `i4g-local`. Split-model flow: Planner manifest → Executor (Sonnet) → Planner verify. Verdict: Pass with follow-ups.

**Code changes (mobile only):**

- `mobile/app/app/(tabs)/dashboard.tsx` — full Dashboard: whoami header, `MetricCard` grid, recent-activity list, pull-to-refresh, skeleton/empty/error states
- `mobile/app/app/(tabs)/queue.tsx` — Reviews Queue with `FilterBar`, debounced `SearchBox`, progressive `limit` pagination, pull-to-refresh, scroll-to-top, error banner + retry
- `mobile/app/src/features/dashboard/queries.ts` — removed silent try/catch; TanStack Query `isError` now drives UI
- `mobile/app/src/features/reviews/queries.ts` — `useReviewsQueue({ status, limit })` with `URLSearchParams`, query key includes params
- New: `src/features/{dashboard,reviews}/components/` (MetricCard, ActivityRow, QueueRow, FilterBar, SearchBox), `src/lib/useDebouncedValue.ts`, `e2e/flows/happy-path.yaml` (Maestro, file only — not wired to CI)
- New tests: 5 component/hook tests + 2 screen-level contract tests using `jest.spyOn(global, 'fetch')`. 88 tests pass, lint + typecheck clean.

**Backend-discovered constraints honoured:**

- `GET /reviews/queue` only supports `status` + `limit`; priority + search done client-side; pagination is progressive-limit (no offset).

**Follow-ups tracked for Sprint 3 / cleanup:**

- Replace hard-coded colors in `FilterBar.tsx`, `QueueRow.tsx`, `queue.tsx`, `dashboard.tsx` with semantic tokens in `src/design/theme.ts` (or `mobile/shared/design-tokens`).
- Fix Zustand "update during render" warning in `dashboard.tsx` whoami hydration (wrap in `useEffect`).
- Reviews coverage gate at 57% (target 70%) because manifest forbade touching legacy hooks `useCase`/`useAuditLog`/`useDecide`/`useWhoAmI`; add tests for these in Sprint 4 alongside case-detail + decide work.
- Strengthen Maestro assertion to target an actual queue-row test-id instead of the "load more" footer.

**No infra, no backend, no env var changes.**

## 2026-04-15 — Gemini API Key Auth Migration

Switched LLM auth from Vertex AI Application Default Credentials (routed via AI Studio, billing to personal credit card) to Gemini API key auth (routed via `generativelanguage.googleapis.com`, billing to GCP project's non-profit billing account).

**Code changes:**

- `core/src/i4g/settings/sections/ml.py` — added `gemini_api_key` field (aliases: `LLM_GEMINI_API_KEY`, `LLM__GEMINI_API_KEY`)
- `core/src/i4g/services/classifier.py` — `VertexAIClient` prefers API-key auth when key is set
- `core/src/i4g/llm/client.py` — `build_llm_client()` and `_build_vertex_langchain()` pass API key through
- `ssi/src/ssi/settings/config.py` — added `gemini_api_key` field to SSI `LLMSettings`
- `ssi/src/ssi/llm/gemini_provider.py` — `GeminiProvider._init_client()` uses `genai.Client(api_key=...)` when set
- `ssi/src/ssi/llm/factory.py` — passes `api_key` from settings to provider
- `core/tests/unit/llm/test_client.py` — updated mock and error message assertion

**Infrastructure:**

- `infra/stacks/app/main.tf` — enabled `generativelanguage.googleapis.com` API, created `gemini-api-key` Secret Manager secret
- `infra/environments/app/dev/terraform.tfvars` — wired `I4G_LLM__GEMINI_API_KEY` (core-svc, sweeper) and `SSI_LLM__GEMINI_API_KEY` (ssi-svc)
- `infra/environments/app/prod/terraform.tfvars` — same for prod

**Deployment (dev):**

- Built and pushed images: `core-svc:dev`, `ssi-svc:dev`, `ingest-job:dev`
- `terraform apply` successful, all services healthy
- Placeholder secret version created; replace with real API key

**Documentation:**

- `docs/config/README.md` — added `llm.gemini_api_key` to settings table, updated `llm.provider` description
- `ssi/config/settings.default.toml` — added `gemini_api_key` comment
- `copilot/.github/shared/architecture-cheatsheet.instructions.md` — added §4 "LLM Auth (Gemini API)" section with key creation instructions

**Remaining:**

- Create real Gemini API keys for dev and prod projects
- Store keys in Secret Manager (replace placeholder)
- Build and push prod images, run `terraform apply` for prod

**Repos affected:** `core/`, `ssi/`, `infra/`, `docs/`, `copilot/`, `planning/`

## 2026-04-13 — Docs Site Rewrite: Phase 1 Tone & Nav Revision

Revised Phase 1 content based on review feedback.

**Tone (Stripe Docs style):**

- Rewrote `getting-started/why-i4g.md` — removed motivational tagline and emotional framing, replaced narrative "4 things" section with capabilities table
- Rewrote `getting-started/how-it-works.md` — cut "What happens behind the scenes" section, tightened step descriptions, added pipeline stages header
- Rewrote `getting-started/find-your-role.md` — removed "I am a..." framing, streamlined role descriptions
- Rewrote `README.md` welcome page — factual one-liner intro, removed "New here?" section
- Light tone pass on Key Concepts README

**Navigation nesting:**

- Restructured `SUMMARY.md` — child pages now nest under each section's overview/README page so sidebar groups collapse (Getting Started stays flat at 3 pages)

**GitBook hint blocks:**

- `how-it-works.md` — info hint: steps 1–4 automatic, human review at step 5
- `find-your-role.md` — info hint: analysts/engagement participants should read Key Concepts first
- `key-concepts/README.md` — info hint: pages ordered by dependency
- `key-concepts/cases-and-evidence.md` — warning hint on PII protection
- `key-concepts/entity-extraction.md` — info hint on automatic obfuscation reversal

**Repos affected:** `docs/`, `planning/`

## 2026-04-13 — Docs Site Rewrite: Phase 0 + Phase 1 (Structure & Foundation)

Executed Phase 0 (Prep) and Phase 1 (Foundation) of the docs site rewrite plan (`tasks/docs-site-rewrite.md`).

**Phase 0 — Structural prep:**

- Created new directory structure: `getting-started/`, `key-concepts/`, `analyst-guide/`, `engagement-guide/`, `law-enforcement-guide/`, `user-guide/`, `admin-guide/`
- Migrated 8 keep-as-is pages to new locations (taxonomy-explorer, geographic-heatmap, timeline, impact-dashboard, indicator-registry, working-in-engagement, lifecycle, taxonomy-reference)
- Replaced `SUMMARY.md` with the new information architecture (55 pages across 9 sections)
- Created stub pages for Phase 2–4 content so all SUMMARY.md links resolve

**Phase 1 — Foundation content:**

- Rewrote `README.md` welcome page (mission-first, persona-routed table)
- Wrote 3 Getting Started pages: `why-i4g.md`, `how-it-works.md`, `find-your-role.md`
- Wrote 11 Key Concepts pages: README, cases-and-evidence, entities, indicators, entity-extraction, fraud-taxonomy, campaigns, risk-scoring, engagements, dossiers-and-reports, site-investigations
- Created 7 P0 SVG diagrams from Mermaid sources: how-it-works, case-lifecycle, entity-aggregation, entity-indicator-funnel, extraction-pipeline, taxonomy-axes, campaign-clustering

**Repos affected:** `docs/`, `planning/`

**Remaining phases:** Phase 2 (Analyst Journey), Phase 3 (Secondary Journeys), Phase 4 (Security, API, Cleanup).

## 2026-04-10 — Entity Extraction v2: Sprint 6 — Documentation, Migration & Launch

Completed Sprint 6 of the entity extraction v2 overhaul:

- **Architecture documentation** — full design doc at `core/docs/design/entity-extraction-v2.md` with Mermaid pipeline flowchart, module capability matrix, merge algorithm details, and decision log
- **Developer onboarding guide** — `copilot/docs/entity-extraction-dev-guide.md` covering: adding a new module, adding a new entity type, debugging false positives
- **Production migration runbook** — step-by-step at `core/docs/design/entity-extraction-v2-migration.md` with baseline → backfill → validate → deploy sequence
- **Legacy code cleanup** — migrated `cli/extract/tasks.py` from direct `ner_rules`/`semantic_ner` imports to the public `extract_entities()` API; added deprecation warnings to `ner_rules.extract_entities()`, `semantic_ner._merge_results()`, and `semantic_ner._add_confidence_scores()`; updated all tests to suppress deprecation warnings
- **QA bundle expansion** — created `expanded-v1` bundle with 51 labeled cases across 6 categories: non-English (10), obfuscated (10), email threads (5), short texts (10), zero entities (10), complex scams (6)
- **Bug fix** — `bundle.py` referenced `settings.app.project_root` (nonexistent); fixed to `settings.project_root`
- **Handoff documentation** — quality baseline, known limitations, runbook, and future improvements at `core/docs/design/entity-extraction-v2-handoff.md`

Quality gate: 263 extraction + entity_types tests pass. Bundle CLI verified (list, create, test module).

## 2026-04-07 — Engagements Phase 2: UI + Real-Time Dashboard

Implemented the full Engagements UI layer (13 steps from `tasks/engagements_phase2.md`). Manager role added to auth context with proper role hierarchy. SDK extended with Zod schemas, TypeScript types, and 8 client methods for engagement CRUD, case assignment, and summary. Cookie-based engagement scoping (`i4g-engagement-id`) with `X-Engagement-Id` header injection in the catch-all proxy. `EngagementProvider` context resolves selection from URL param → cookie → auto-select-single-active. Engagement selector dropdown in console header. Full management page at `/admin/engagements` with create form, status transitions (draft→active→completed→archived), and bulk case assignment. Dashboard summary card with progress bar. Deep link support via `?engagement=` URL param. Edge case handling: completed-engagement read-only banner, no-engagements onboarding prompt.

Quality gate: `pnpm build` ✓, `pnpm format` ✓, `pnpm lint` ✓, 218/218 tests pass.

**Repos affected:** `ui/`, `planning/`

**ui/ — New files:**

- `apps/web/src/lib/engagement-cookie.ts` — cookie read/write/clear helpers
- `apps/web/src/lib/engagement-context.tsx` — EngagementProvider + useEngagement hook
- `apps/web/src/lib/server/engagements-service.ts` — server-action wrappers for engagement API
- `apps/web/src/components/engagement-selector.tsx` — header dropdown component
- `apps/web/src/components/engagement-summary-card.tsx` — dashboard progress card
- `apps/web/src/components/completed-engagement-banner.tsx` — read-only warning banner
- `apps/web/src/components/no-engagements-prompt.tsx` — onboarding empty state
- `apps/web/src/app/(console)/admin/engagements/page.tsx` — management page (server)
- `apps/web/src/app/(console)/admin/engagements/engagements-table.tsx` — CRUD table (client)

**ui/ — Modified files:**

- `packages/sdk/src/index.ts` — engagement schemas, types, 8 client methods
- `packages/sdk/src/__fixtures__/index.ts` — mock client engagement methods
- `apps/web/src/lib/auth-context.tsx` — manager role + hierarchy update
- `apps/web/src/app/(console)/layout.tsx` — provider chain + selector + banner
- `apps/web/src/app/(console)/navigation.tsx` — Engagements nav item (minRole: manager)
- `apps/web/src/app/(console)/dashboard/page.tsx` — engagement summary card
- `apps/web/src/app/(console)/admin/users/accounts-table.tsx` — manager role config
- `apps/web/src/app/api/[...path]/route.ts` — X-Engagement-Id header injection
- `tsconfig.base.json` — removed stale ignoreDeprecations field
- `apps/web/tests/unit/api-proxy-route.test.ts` — test mock updated for cookies

**Follow-up (Phase 3):**

- Mid-switch unsaved-data warning dialog (needs form-level integration)
- Cross-engagement deep link badge on case detail ("This case belongs to [Other Engagement]")
- `?engagement=` param in shareable search/case links
- Leaderboard + awards (Phase 3 task plan)

## 2026-04-07 — PRD: Engagements (Bounded Work Periods)

New PRD (`planning/prd_engagements.md`) introducing **Engagements** — a first-class concept for grouping cases into bounded work periods (competitions, semesters, exercises). Covers data model (`engagements` table + FK on `cases`), API scoping via `X-Engagement-Id` header, UI engagement selector, per-engagement analytics, and leaderboard. Three-phase delivery: Phase 1 (data + API), Phase 2 (UI + dashboard), Phase 3 (leaderboard + awards). Replaces the informal "batch" concept that was lost during the campaign/batch separation work.

**Repos affected:** `planning/`

## 2026-04-06 — TIFAP Enrichment Sprint: Cross-Navigation + Entity-Cases

New API endpoint `GET /intelligence/entities/{type}/{value}/cases` with paginated case summaries. Case-seeded graph support (`seed_type=case`) in intelligence graph endpoint. Case detail now shows linked threat campaigns and "View Case Graph" button on entity card. Entity detail panel shows linked cases and campaign badges. Breadcrumb navigation added to entity explorer, network graph, and case detail pages. `dialect_group_concat` helper in `sql.py` for PostgreSQL/SQLite portability. Review store join flipped to `cases LEFT JOIN review_queue` so cases without queue entries render correctly. Infra: analytics-refresh job timeout bumped 1800→3600s.

**Repos affected:** `core/`, `ui/`, `infra/`, `planning/`

## 2026-04-05 — TIFAP Enrichment Sprint: Schema Normalization + Entity UI

Schema normalization (migration `20260404_01`): `cases.description` column added, `scam_records.classification_result` and `tags` removed, FK constraints on `review_queue` and `scam_records` to `cases`. Display reads (dashboard, case detail, analytics, dossier bundler) now join `cases` directly instead of `scam_records`. Entity extraction keys aligned between NER rules and worker job. New API: `GET /cases/{id}/related` (entity-overlap ranking). UI: Extracted Entities card on case detail, Related Cases card, graph deep-linking from entity explorer, edge click detail with linked case IDs, help modal on network graph. SSI `sql.py` synced with core schema changes.

**Repos affected:** `core/`, `ssi/`, `ui/`, `copilot/`, `planning/`

## 2026-05-12 - Sec-Gemini SDK Integration into SSI

Implemented the Sec-Gemini SDK integration as a feature-flagged, optional enrichment provider in SSI's Phase 1 pipeline.

- **Provider Implementation:** Created `ssi/providers/sec_gemini/` module encompassing an async SDK wrapper, prompt builder for email/infra analysis, response parser for structured JSON extraction, and data models (`SecGeminiAnalysis`, `EmailSecurityPosture`, `InfraFingerprint`, `VulnerabilityFinding`).
- **Orchestrator Integration:** Wired `_run_sec_gemini_enrichment` into Phase 1 of `ssi.investigator.orchestrator.run_investigation`. It runs securely after eCrimeX and gracefully builds context from existing OSINT to prevent redundant AI lookups.
- **Config & Settings:** Added `SecGeminiSettings` feature-flag block (`[sec_gemini]`) to `settings.default.toml` (disabled by default) and registered it in the core Pydantic configuration. Supported API key injection via Secret Manager.
- **Documentation:** Updated `ssi/docs/tdd.md` to document both the newly added Sec-Gemini enrichment (§6.8) and the previously undocumented Google OSINT integration (§6.7).
- **Testing:** Implemented 31 mocked unit tests for parser, settings, and orchestrator boundaries. Full SSI regression tests passed. Added `sec-gemini` as an optional dependency in `pyproject.toml`.
- **Repos affected:** `ssi/`, `planning/`.
