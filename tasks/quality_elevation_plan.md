# Quality Elevation Plan — Round 2 Refactoring Sprint

> **Goal:** Second-pass systematic improvement of the codebase, building on
> the completed [Consolidation Sprint](../archive/consolidation_plan.md) and
> [Debt Remediation Sprint](../archive/debt_remediation_plan.md). Round 1
> resolved 68 debt items across 10 work streams. This round targets the
> next layer: config discipline, performance, security hardening, test
> coverage, and code organization.
>
> **Created:** 2026-02-11
> **Last Updated:** 2026-02-11
> **Status:** IN PROGRESS
> **Predecessor:** `planning/archive/debt_remediation_plan.md` (ALL 10 WS COMPLETE)

---

## How to Use This Document

- Each work stream is a logical unit of related changes.
- Work streams are ordered by priority (WS-1 first, WS-10 last).
- Individual items have an E-number (E = "elevation") for traceability.
- Status per item: `[ ]` not started, `[~]` in progress, `[x]` done.
- When starting a session, Copilot reads this file to know current position.
- After completing tasks, update the checkbox, add a date, and note decisions in
  the **Session Log** at the bottom.

---

## Summary

| #     | Work Stream                          | Items  | HIGH   | MED    | LOW    | Est. Days | Status      |
| ----- | ------------------------------------ | ------ | ------ | ------ | ------ | --------- | ----------- |
| WS-1  | Security Hardening II                | 7      | 4      | 2      | 1      | 2–3       | DONE        |
| WS-2  | Config & Settings Discipline         | 10     | 4      | 5      | 1      | 2–3       | NOT STARTED |
| WS-3  | Store & Schema Improvements          | 6      | 2      | 3      | 1      | 2–3       | NOT STARTED |
| WS-4  | API Completeness & Correctness       | 7      | 1      | 4      | 2      | 1–2       | NOT STARTED |
| WS-5  | Core Code Organization               | 7      | 0      | 5      | 2      | 2–3       | NOT STARTED |
| WS-6  | UI Performance & Bundle Optimization | 5      | 3      | 2      | 0      | 2–3       | NOT STARTED |
| WS-7  | UI Code Quality & Deduplication      | 10     | 2      | 7      | 1      | 3–5       | NOT STARTED |
| WS-8  | Test Coverage Expansion              | 6      | 2      | 4      | 0      | 3–5       | NOT STARTED |
| WS-9  | Infrastructure Quality               | 8      | 1      | 4      | 3      | 2–3       | NOT STARTED |
| WS-10 | Documentation & Planning Alignment   | 8      | 0      | 4      | 4      | 1–2       | NOT STARTED |
|       | **Totals**                           | **74** | **19** | **40** | **15** | **20–32** |             |

---

## WS-1: Security Hardening II

> **Priority:** CRITICAL — CORS misconfiguration, API key exposure in client
> bundle, and hardcoded auth tokens present real security risks.
>
> **Estimated effort:** 2–3 days
> **Repos:** `core/`, `ui/`, `infra/`

### Items

| #   | Finding                                                                            | Severity | Status |
| --- | ---------------------------------------------------------------------------------- | -------- | ------ |
| E1  | `allow_origins=["*"]` + `allow_credentials=True` in `app.py` — wide-open CORS      | HIGH     | [x]    |
| E2  | Hardcoded `_API_TOKENS` dict with dev tokens used in production auth               | HIGH     | [x]    |
| E3  | `NEXT_PUBLIC_API_KEY` fallback in 5 server-side files leaks key to client bundle   | HIGH     | [x]    |
| E4  | Binary `tfplan` committed to git (may embed secrets from provider state)           | HIGH     | [x]    |
| E5  | `allUsers` in Cloud Run invoker members (dev + prod)                               | MED      | [x]    |
| E6  | Prod Cloud SQL IAM user suffix inconsistency (may cause auth failures)             | MED      | [x]    |
| E7  | `console.log` in catch-all proxy leaks request URLs to server logs unconditionally | LOW      | [x]    |

### Design Decisions Required

- **E1:** ✅ Added `settings.api.cors_origins: list[str]` field (default `["*"]`
  for local, override via `I4G_API__CORS_ORIGINS` env var in cloud). CORS driven by config.
- **E2:** ✅ Chose option (c): replaced hardcoded token dict with IAP JWT verification
  for cloud envs. Fallback: `settings.api.key` for service-to-service calls. Local
  keeps `disable_auth=true`. This is a temporary measure until full RBAC sprint.
- **E5:** ✅ Verified: `allUsers` is NOT required. The IAP service agent
  (`gcp-sa-iap.iam.gserviceaccount.com`) is already in `default_runtime_invokers`.
  Removed `allUsers` from both dev and prod. Google Workspace groups
  (`gcp-i4g-analyst@`, `i4g-friend@`) already bound as IAP access members.

### Acceptance Criteria

- [x] CORS origins configurable via `settings.api.cors_origins`.
- [x] No hardcoded API tokens in source code.
- [x] `NEXT_PUBLIC_API_KEY` removed from all server-side files.
- [x] `tfplan` removed from git and `.gitignore` updated.
- [x] Cloud SQL IAM user format consistent across environments.

---

## WS-2: Config & Settings Discipline

> **Priority:** HIGH — ~60+ raw `os.getenv()` calls bypass the settings
> model, creating an untestable shadow config layer. Duplicated logging
> setup in every worker job adds maintenance burden.
>
> **Estimated effort:** 2–3 days
> **Repos:** `core/`

### Items

| #   | Finding                                                                                                  | Severity | Status |
| --- | -------------------------------------------------------------------------------------------------------- | -------- | ------ |
| E8  | `ingest.py` — 6+ `os.getenv` calls for `I4G_INGEST__*` fields that exist on Settings                     | HIGH     | [ ]    |
| E9  | `report.py` — 3 `os.getenv` calls for `I4G_REPORT__*` bypassing Settings                                 | HIGH     | [ ]    |
| E10 | `ingest_retry.py` — `I4G_INGEST_RETRY__*` fields not modeled in Settings at all                          | HIGH     | [ ]    |
| E11 | `classification_sweeper.py` — non-`I4G_` prefixed env vars (`JOB_MAX_RUNTIME_SECONDS`, `JOB_BATCH_SIZE`) | HIGH     | [ ]    |
| E12 | `factories.py` — 4 `os.getenv` calls for Vertex params that exist on `VectorSettings`                    | MED      | [ ]    |
| E13 | `discovery.py` — duplicate Vertex `os.getenv` calls same as factories.py                                 | MED      | [ ]    |
| E14 | `task_status.py` — `I4G_TASK_ID` and `I4G_TASK_STATUS_URL` read raw                                      | MED      | [ ]    |
| E15 | 8× duplicated `_configure_logging()` across all worker jobs                                              | MED      | [ ]    |
| E16 | `_env_flag()` in `ingest.py` duplicates `coerce_bool` from `i4g.utils.coerce`                            | MED      | [ ]    |
| E17 | Hardcoded Cloud Run URL in 6 places across 3 CLI files                                                   | LOW      | [ ]    |

### Design Decisions Required

- **E10:** Create `IngestRetrySettings` section or add fields to existing
  `IngestionSettings`.
- **E11:** Rename to `I4G_` prefix and add to Settings, or create a
  `SweepSettings` section.
- **E15:** Extract shared `configure_job_logging()` to `i4g.worker.logging` or
  `i4g.observability`.

### Acceptance Criteria

- [ ] Zero `os.getenv()` calls in worker job files — all config via Settings.
- [ ] All env vars use `I4G_` prefix and are modeled in the Settings Pydantic hierarchy.
- [ ] Single `configure_job_logging()` function shared across all 8 jobs.
- [ ] `settings_manifest.yaml` regenerated with any new fields.
- [ ] `pytest tests/unit` passes.

---

## WS-3: Store & Schema Improvements

> **Priority:** HIGH — the PII token store still uses raw sqlite3 (the last
> holdout), missing indexes degrade query performance, and the session factory
> anti-pattern creates unnecessary connections.
>
> **Estimated effort:** 2–3 days
> **Repos:** `core/`

### Items

| #   | Finding                                                                              | Severity | Status |
| --- | ------------------------------------------------------------------------------------ | -------- | ------ |
| E18 | `pii_token_store.py` still uses raw `sqlite3` — last store not on SQLAlchemy         | HIGH     | [ ]    |
| E19 | `review_queue` table missing indexes on `status`, `priority`, `case_id`, `queued_at` | MED      | [ ]    |
| E20 | `review_actions` table missing indexes on `review_id`, `created_at`                  | MED      | [ ]    |
| E21 | Dashboard/analytics endpoints use double-call session factory anti-pattern           | MED      | [ ]    |
| E22 | Bare `except:` clause in `review_store.py` catches SystemExit/KeyboardInterrupt      | HIGH     | [ ]    |
| E23 | `async def get_case()` in `cases.py` runs synchronous SQLAlchemy — blocks event loop | LOW      | [ ]    |

### Design Decisions Required

- **E18:** Migrate `PiiTokenStore` to SQLAlchemy following the same pattern as
  the unified store consolidation from Round 1 (WS-3). The PII vault uses a
  separate database, so it needs its own `session_factory`.
- **E19/E20:** Add indexes via Alembic migration. Verify no performance
  regression on insert-heavy paths.
- **E21:** Replace direct `session_factory()()` calls with FastAPI `Depends`
  pattern matching `review_deps.py`.

### Acceptance Criteria

- [ ] `pii_token_store.py` uses SQLAlchemy; zero `import sqlite3` in production
      store code.
- [ ] Alembic migration adds indexes on high-traffic query columns.
- [ ] Dashboard/analytics use dependency-injected sessions.
- [ ] No bare `except:` clauses in production code.
- [ ] `pytest tests/unit` passes.

---

## WS-4: API Completeness & Correctness

> **Priority:** HIGH — `bulk_update_tags` endpoint calls an unimplemented
> method (runtime crash). Several endpoints still lack response models or
> contain hardcoded mock data.
>
> **Estimated effort:** 1–2 days
> **Repos:** `core/`

### Items

| #   | Finding                                                                                  | Severity | Status |
| --- | ---------------------------------------------------------------------------------------- | -------- | ------ |
| E24 | `bulk_update_tags` API endpoint calls unimplemented `ReviewStore` method — runtime crash | HIGH     | [ ]    |
| E25 | 11 API endpoints still missing `response_model` (86% → target 95%+)                      | MED      | [ ]    |
| E26 | `CASES_RESPONSE` — 80 lines of hardcoded mock data inline in `cases.py`                  | MED      | [ ]    |
| E27 | Hardcoded `reminders` list in `dashboard.py`                                             | MED      | [ ]    |
| E28 | Analytics endpoints return hardcoded placeholders (`"100%"`, all-zeros geography)        | MED      | [ ]    |
| E29 | `time.sleep(5)` dead placeholder in simulated report generation endpoint                 | LOW      | [ ]    |
| E30 | 3 xfail tests (`bulk_update_tags` × 2, `list_dossier_candidates` × 1) to implement       | LOW      | [ ]    |

### Design Decisions Required

- **E24/E30:** Implement `bulk_update_tags` and `list_dossier_candidates` on
  `ReviewStore`. These are already called from the API.
- **E26–E28:** Options: (a) Remove mock fallbacks entirely (return 404 when data
  missing); (b) Move to fixture files loaded only in local/dev mode.

### Acceptance Criteria

- [ ] `bulk_update_tags` and `list_dossier_candidates` implemented and tested.
- [ ] 3 xfail tests converted to passing tests.
- [ ] ≥95% of API endpoints have `response_model`.
- [ ] No inline mock data in API modules.
- [ ] Dead placeholder code removed.

---

## WS-5: Core Code Organization

> **Priority:** MEDIUM — large files, missing `__init__.py`, and legacy type
> annotations add friction but don't impact runtime behavior.
>
> **Estimated effort:** 2–3 days
> **Repos:** `core/`

### Items

| #   | Finding                                                                         | Severity | Status |
| --- | ------------------------------------------------------------------------------- | -------- | ------ |
| E31 | `settings/config.py` at 1,374 lines — 16+ settings classes in one file          | MED      | [ ]    |
| E32 | `review_search.py` — ~300 lines of coercion helpers extractable to utils        | MED      | [ ]    |
| E33 | Missing `__init__.py` in `reports/`, `worker/`, `llm/prompts/`                  | MED      | [ ]    |
| E34 | 109 files use legacy `Dict`/`List`/`Optional` from `typing` instead of builtins | MED      | [ ]    |
| E35 | 29 `# type: ignore` comments — review and reduce where possible                 | MED      | [ ]    |
| E36 | `_coerce_bool` re-export adapter still in `intake_job_runner.py`                | LOW      | [ ]    |
| E37 | Circular import risk: `task_status.py` deferred import from `api.app`           | LOW      | [ ]    |

### Design Decisions Required

- **E31:** Split into `settings/sections/` submodules (e.g., `storage.py`,
  `llm.py`, `vector.py`, `identity.py`) with `config.py` as thin orchestrator.
- **E34:** Bulk modernization pass — replace `Dict` → `dict`, `List` → `list`,
  `Optional[X]` → `X | None`, `Tuple` → `tuple`. Safe since 122 files already
  have `from __future__ import annotations`.

### Acceptance Criteria

- [ ] `settings/config.py` ≤500 lines; sections in submodules.
- [ ] Coercion helpers extracted from `review_search.py`.
- [ ] All packages have explicit `__init__.py`.
- [ ] ≥80% of files use builtin generics.
- [ ] `pytest tests/unit` passes.

---

## WS-6: UI Performance & Bundle Optimization

> **Priority:** HIGH — Recharts (~460 KB) statically imported, zero dynamic
> imports, zero `React.memo` usage. These directly impact page load time
> and interaction responsiveness.
>
> **Estimated effort:** 2–3 days
> **Repos:** `ui/`

### Items

| #   | Finding                                                                               | Severity | Status |
| --- | ------------------------------------------------------------------------------------- | -------- | ------ |
| E38 | Recharts statically imported (~460 KB gzipped) — use `next/dynamic` with `ssr: false` | HIGH     | [ ]    |
| E39 | Zero `React.memo` on list-item components (`SearchResultCard`, etc.)                  | HIGH     | [ ]    |
| E40 | Zero `next/dynamic` or `React.lazy` for heavy client components                       | HIGH     | [ ]    |
| E41 | `DiscoveryPanel` is 733 lines — decompose into sub-components                         | MED      | [ ]    |
| E42 | `use-search-state.ts` is 578 lines — split entity-filter and saved-search hooks       | MED      | [ ]    |

### Design Decisions Required

- **E38:** Wrap `AnalyticsCharts` in `dynamic(() => import(...), { ssr: false })`.
- **E40:** Identify top candidates for dynamic import: `DiscoveryPanel`,
  `AccountListConsole`, `CaseIntakeForm`, `SearchHistoryList`.
- **E39:** Memoize all components rendered inside `.map()` in lists.

### Acceptance Criteria

- [ ] Recharts loaded lazily (not in initial bundle).
- [ ] ≥5 list-item components wrapped in `React.memo`.
- [ ] ≥4 heavy page components loaded via `next/dynamic`.
- [ ] `DiscoveryPanel` ≤400 lines after decomposition.
- [ ] `pnpm build` succeeds with no new warnings.

---

## WS-7: UI Code Quality & Deduplication

> **Priority:** HIGH — SDK carries ~580 lines of mock data in production
> bundle, utility functions duplicated 4-5x across route handlers and
> components, and section heading pattern repeated 44 times.
>
> **Estimated effort:** 3–5 days
> **Repos:** `ui/`

### Items

| #   | Finding                                                                          | Severity | Status |
| --- | -------------------------------------------------------------------------------- | -------- | ------ |
| E43 | SDK `index.ts` (1,378 LOC) — ~580 lines of mock data should be in test fixtures  | HIGH     | [ ]    |
| E44 | `resolveApiBase()`/`resolveApiKey()` copy-pasted in 5 API route files            | HIGH     | [ ]    |
| E45 | `formatDate()` duplicated 4× with signature variations                           | MED      | [ ]    |
| E46 | `getTaxonomyDescription()` duplicated in `cases/page.tsx` and `search-types.ts`  | MED      | [ ]    |
| E47 | Classification badge rendering blocks duplicated between cases and search        | MED      | [ ]    |
| E48 | Section heading pattern (`text-xs font-semibold uppercase...`) repeated 44×      | MED      | [ ]    |
| E49 | `@i4g/config` package completely unused — remove or integrate                    | MED      | [ ]    |
| E50 | `@i4g/types` only exports taxonomy; app-local types not shared                   | MED      | [ ]    |
| E51 | `z.any()` used in 3 Zod schemas + 5× in `account-list-service` — defeats typing  | MED      | [ ]    |
| E52 | Native `<input>`/`<textarea>` used instead of ui-kit in accounts and case intake | LOW      | [ ]    |

### Design Decisions Required

- **E43:** Extract mock data to `packages/sdk/src/__fixtures__/` or a
  `@i4g/test-fixtures` package. Only import in test files.
- **E44:** All API route handlers import from `lib/server/api-client.ts`.
- **E48:** Create a `<SectionLabel>` component in `@i4g/ui-kit`, or an
  `@apply` Tailwind utility in the global styles.
- **E49:** Either use `@i4g/config` for ESLint/tsconfig or remove the package.
- **E50:** Expand `@i4g/types` to be canonical or merge into SDK entirely.

### Acceptance Criteria

- [ ] SDK `index.ts` ≤800 lines; mock data in separate fixture module.
- [ ] `resolveApiBase`/`resolveApiKey` defined in exactly 1 location.
- [ ] `formatDate` consolidated into `lib/format.ts`.
- [ ] Classification badges extracted to `<ClassificationBadges>` component.
- [ ] Section heading pattern uses shared component or utility.
- [ ] Zero `z.any()` in Zod schemas (replaced with `z.record(z.unknown())`).
- [ ] `pnpm format` clean, Vitest passing.

---

## WS-8: Test Coverage Expansion

> **Priority:** MEDIUM — 182 source files vs 97 test files in core. Zero
> tests for UI API route handlers or server services. Major modules
> (classification, embedding, extraction, ingestion, OCR) have no coverage.
>
> **Estimated effort:** 3–5 days
> **Repos:** `core/`, `ui/`

### Items

| #   | Finding                                                                                         | Severity | Status |
| --- | ----------------------------------------------------------------------------------------------- | -------- | ------ |
| E53 | Core: 0 tests for `classification/`, `embedding/`, `extraction/`, `ingestion/`, `ocr/`          | HIGH     | [ ]    |
| E54 | Core: 0 tests for `store/dossier_queue_store`, `storage/evidence`, `services/intake_job_runner` | MED      | [ ]    |
| E55 | Core: `cli/bootstrap/` (14 files) has 0 unit tests                                              | MED      | [ ]    |
| E56 | UI: 0 tests for 11 API route handlers (including catch-all proxy)                               | HIGH     | [ ]    |
| E57 | UI: 0 tests for `platform-client.ts` (461 LOC of normalization logic)                           | MED      | [ ]    |
| E58 | UI: 0 tests for 5 server services (campaigns, account-list, taxonomy, discovery, auth)          | MED      | [ ]    |

### Design Decisions Required

- **E53:** Prioritize smoke tests that verify the modules import cleanly and
  exercise the main code paths with mock dependencies. Don't aim for 100%
  coverage — focus on integration paths and error handling.
- **E56:** Use `next/test` or direct `fetch` against the route handlers with
  mock backend. Focus on the catch-all proxy security (path validation).

### Acceptance Criteria

- [ ] ≥1 unit test per untested core module (classification, embedding,
      extraction, ingestion, OCR).
- [ ] `dossier_queue_store`, `evidence`, `intake_job_runner` have ≥3 tests each.
- [ ] ≥3 UI API route handler tests covering auth, proxy, and error cases.
- [ ] `platform-client.ts` has ≥5 tests covering normalization functions.
- [ ] All tests passing (core + UI).

---

## WS-9: Infrastructure Quality

> **Priority:** MEDIUM — module layout inconsistencies, Cloud Run v1 API
> deprecation, dead variables, and missing variable validation.
>
> **Estimated effort:** 2–3 days
> **Repos:** `infra/`

### Items

| #   | Finding                                                                          | Severity | Status |
| --- | -------------------------------------------------------------------------------- | -------- | ------ |
| E59 | Cloud Run service module uses deprecated v1 API (`google_cloud_run_service`)     | HIGH     | [ ]    |
| E60 | `lb/iap_https` module — single file, no `variables.tf`/`outputs.tf`              | MED      | [ ]    |
| E61 | `iam/pii_vault_access` — variables inline in `main.tf`                           | MED      | [ ]    |
| E62 | `iap_manage_clients` + `iap_secret_replication_locations` dead variables in dev  | MED      | [ ]    |
| E63 | `FORCE_REDEPLOY = "7"` hardcoded in dev `run_console` env vars                   | MED      | [ ]    |
| E64 | `vertex_search` module — `google-beta` provider not version-pinned               | LOW      | [ ]    |
| E65 | No `validation` blocks on `database_version`, `config.tier`, `ingress` variables | LOW      | [ ]    |
| E66 | Org policy constraint format inconsistency (prefixed vs unprefixed) between envs | LOW      | [ ]    |

### Design Decisions Required

- **E59:** Migrate `modules/run/service/main.tf` from `google_cloud_run_service`
  to `google_cloud_run_v2_service`. This is a breaking change that requires
  `terraform state mv` for existing resources. Plan carefully.
- **E63:** Convert `FORCE_REDEPLOY` to a variable or remove entirely.

### Acceptance Criteria

- [ ] Cloud Run service module uses v2 API.
- [ ] All modules follow `main.tf` / `variables.tf` / `outputs.tf` convention.
- [ ] Dead variables removed from dev.
- [ ] `terraform validate` passes for both dev and prod.

---

## WS-10: Documentation & Planning Alignment

> **Priority:** LOW — editorial artifacts, stale roadmap, and diagram
> inaccuracies don't impact runtime but reduce professionalism.
>
> **Estimated effort:** 1–2 days
> **Repos:** `docs/`, `planning/`, `arch-viz/`

### Items

| #   | Finding                                                                        | Severity | Status |
| --- | ------------------------------------------------------------------------------ | -------- | ------ |
| E67 | Roadmap stale — "Phases 5-6 remaining" despite all phases complete             | MED      | [ ]    |
| E68 | `change_log.md` broken link to `data_reset_bootstrap_plan.md`                  | MED      | [ ]    |
| E69 | arch-viz shows PubSub as task queue — actual architecture uses Cloud Scheduler | MED      | [ ]    |
| E70 | arch-viz shows Azure SQL sync flow — may be retired                            | MED      | [ ]    |
| E71 | Placeholder text "(Replace the placeholder...)" in 3 architecture pages        | LOW      | [ ]    |
| E72 | Duplicate `book.json` (outer `docs/` vs inner `docs/book/`)                    | LOW      | [ ]    |
| E73 | `authentication.md` references `require_role("admin")` — verify exists         | LOW      | [ ]    |
| E74 | `arch-viz/src/shared/` is an empty directory                                   | LOW      | [ ]    |

### Design Decisions Required

- **E69/E70:** ⚠️ Confirm whether PubSub and Azure SQL are still part of the
  architecture or fully retired before updating diagrams.

### Acceptance Criteria

- [ ] Roadmap reflects all completed work through WS-10.
- [ ] All internal links in `planning/` resolve.
- [ ] arch-viz diagrams match actual deployed architecture.
- [ ] No editorial placeholder text in published docs.

---

## Recommended Sprint Order

```
Sprint 1 (Week 1):  WS-1 Security Hardening II ──── highest risk
                     WS-2 Config Discipline (parallel, core-only)
Sprint 2 (Week 2):  WS-3 Store & Schema ──────────── unblocks WS-4
                     WS-4 API Completeness (parallel)
Sprint 3 (Week 3):  WS-6 UI Performance ──────────── high user impact
                     WS-7 UI Code Quality (parallel)
Sprint 4 (Week 4):  WS-5 Core Organization ────────── bulk refactoring
                     WS-8 Test Coverage (parallel)
Sprint 5 (Week 5):  WS-9 Infrastructure ──────────── Cloud Run v2 migration
                     WS-10 Documentation (parallel)
```

---

## Cross-Reference: Finding IDs

| Work Stream | Finding IDs |
| ----------- | ----------- |
| WS-1        | E1–E7       |
| WS-2        | E8–E17      |
| WS-3        | E18–E23     |
| WS-4        | E24–E30     |
| WS-5        | E31–E37     |
| WS-6        | E38–E42     |
| WS-7        | E43–E52     |
| WS-8        | E53–E58     |
| WS-9        | E59–E66     |
| WS-10       | E67–E74     |

---

## Session Log

> Append an entry every session. Format:
> `### YYYY-MM-DD — Summary`

### 2026-02-11 — Plan Creation

- Archived completed Round 1 plans (`consolidation_plan.md` and
  `debt_remediation_plan.md`) to `planning/archive/`.
- Conducted fresh workspace-wide audit across all 8 repos using parallel
  research agents (core Python, UI, infra/docs).
- Round 1 resolved 68 items across 10 work streams. This round targets 74
  new items across 10 work streams at the next quality layer.
- Key themes: config discipline (shadow env vars), security hardening
  (CORS, API keys), performance (bundle size, memoization), test coverage
  expansion, and infrastructure modernization (Cloud Run v2).
- Updated all 8 `copilot-instructions.md` files to point to this plan.
- Fixed broken links in `roadmap.md` after archival.

### 2026-02-12 — WS-1 Security Hardening II (COMPLETE)

- **E1 — CORS:** Added `cors_origins: list[str]` to `APISettings` (default `["*"]`
  for local dev). `app.py` reads from settings. Cloud envs override via
  `I4G_API__CORS_ORIGINS`. Local env stays permissive per user request.
- **E2 — Auth tokens:** Removed hardcoded `_API_TOKENS` dict. Rewrote `auth.py`
  with 4-tier auth: (1) local bypass, (2) IAP JWT verification via
  `X-Goog-IAP-JWT-Assertion`, (3) Bearer token, (4) `settings.api.key` for
  service-to-service. Uses `google.oauth2.id_token` (transitive dep). All
  authenticated Cloud users get admin access as temp measure until RBAC sprint.
- **E3 — API key leak:** Removed `NEXT_PUBLIC_API_KEY` fallback from
  `resolveApiKey()` in `api-client.ts`. Replaced duplicated
  `resolveApiBase()`/`resolveApiKey()` in 4 route files with shared imports
  from `@/lib/server/api-client` (partial E44 credit).
- **E4 — tfplan:** `git rm --cached` the binary; added bare `tfplan` to
  `.gitignore` (existing `*.tfplan` only caught files with extension).
- **E5 — allUsers:** Removed `["allUsers"]` from `invoker_members` in both
  dev and prod `main.tf`. Verified IAP service agent + SAs already in
  `default_runtime_invokers`. Google Workspace groups already bound as IAP
  access members (`gcp-i4g-analyst@`, `i4g-friend@`). This is a temp
  approach — full auth redesign deferred to a future sprint.
- **E6 — Cloud SQL IAM:** Standardized prod fastapi user from
  `sa-app@i4g-prod.iam.gserviceaccount.com` to `sa-app@i4g-prod.iam`
  (truncated `.iam` is the correct format for Cloud SQL IAM auth).
- **E7 — Proxy logging:** Removed `console.log` calls that leaked full
  backend URLs. Downgraded response-error log to `console.warn` with
  sanitized path. Error catches now log `error.message` only (not full stack).
- Updated 4 unit test assertions that relied on the old `_API_TOKENS` mapping
  (`analyst_1` → `local-dev`). Removed unused `is_valid_api_token` import from
  `account_list.py`. All 330 tests pass, 3 xfail unchanged.
