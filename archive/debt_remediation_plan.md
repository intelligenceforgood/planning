# Debt Remediation Plan — Post-Consolidation Sprint

> **Goal:** Systematically resolve the technical debt items discovered
> during the [Consolidation & Quality Sprint](consolidation_plan.md).
> Items are grouped into 10 prioritized work streams, ordered by risk.
>
> **Created:** 2026-02-09
> **Last Updated:** 2026-02-15
> **Status:** COMPLETE — All 10 work streams done (68 items resolved)
> **Predecessor:** `planning/tasks/consolidation_plan.md` (ALL PHASES COMPLETE)
> **Archived:** 2026-02-11 → `planning/archive/`

---

## How to Use This Document

- Each work stream is a logical unit of related changes.
- Work streams are ordered by priority (WS-1 first, WS-9 last).
- Individual items retain their original D-number from the consolidation audit
  for traceability.
- Status per item: `[ ]` not started, `[~]` in progress, `[x]` done.
- When starting a session, Copilot reads this file to know current position.
- After completing tasks, update the checkbox, add a date, and note decisions in
  the **Session Log** at the bottom.

---

## Summary

| #     | Work Stream                              | Items  | HIGH   | MED    | LOW    | Est. Days | Status |
| ----- | ---------------------------------------- | ------ | ------ | ------ | ------ | --------- | ------ |
| WS-1  | Security & Auth Hardening                | 6      | 3      | 1      | 1+1    | 3–5       | DONE   |
| WS-2  | API Quality & Contract Alignment         | 9      | 4      | 3      | 2      | 3–5       | DONE   |
| WS-3  | Store Consolidation & Factory Discipline | 4      | 3      | 1      | 0      | 3–5       | DONE   |
| WS-4  | Service & Worker Cleanup                 | 5      | 2      | 2      | 1      | 2–3       | DONE   |
| WS-5  | CLI Refactor                             | 2      | 1      | 1      | 0      | 2–3       | DONE   |
| WS-6  | UI Resilience & UX Quality               | 8      | 3      | 4      | 1      | 3–5       | DONE   |
| WS-7  | Type Unification & Test Coverage         | 4      | 1      | 2      | 1      | 2–3       | DONE   |
| WS-8  | Dead Code & Hygiene                      | 8      | 0      | 4      | 4      | 1–2       | DONE   |
| WS-9  | CI/CD & Infrastructure                   | 5      | 0      | 5      | 0      | 2–3       | DONE   |
| WS-10 | Dev/Prod Parity                          | 15     | 4      | 8      | 3      | 3–5       | DONE   |
|       | **Totals**                               | **66** | **21** | **31** | **14** | **26–42** |        |

---

## WS-1: Security & Auth Hardening

> **Priority:** CRITICAL — unauthenticated routes, path traversal, and
> production misconfiguration are the highest-risk items in the backlog.
>
> **Estimated effort:** 3–5 days
> **Repos:** `core/`, `ui/`, `infra/`

### Items

| #   | Finding                                                                                | Severity | Status |
| --- | -------------------------------------------------------------------------------------- | -------- | ------ |
| D12 | 7/13 API routers have NO authentication                                                | HIGH     | [x]    |
| D14 | `reports.py` has no path-traversal protection on `plan_id`                             | HIGH     | [x]    |
| D41 | No user authentication guard in console (no middleware/session check)                  | HIGH     | [x]    |
| D65 | Prod FastAPI missing `I4G_VECTOR__BACKEND`, `I4G_LLM__PROVIDER`, `I4G_LLM__CHAT_MODEL` | HIGH     | [x]    |
| D68 | Secret injection inconsistent — only FastAPI + ingest (dev) get PII secrets            | MED      | [x]    |
| D69 | API key (`I4G_API__KEY`) stored as plain-text in Terraform tfvars                      | LOW      | [x]    |

### Design Decisions Required

- **D12:** ⚠️ Which auth mechanism for the 7 unprotected routers? Options:
  (a) Extend existing `X-API-KEY` dependency to all routers;
  (b) Implement IAP header validation middleware (production-grade);
  (c) Hybrid — API key for local dev, IAP for cloud.
  Current state: `review.py` and `reports.py` have `Depends(require_api_key)`;
  intake, cases, campaigns, taxonomy, analytics, health, admin, tasks, search do not.
- **D14:** Path traversal fix is straightforward (validate `plan_id` against
  allowlist or `re.match(r'^[a-zA-Z0-9_-]+$')`). No design decision needed.
- **D41:** ⚠️ Next.js auth guard approach? Options:
  (a) Middleware-based IAP header check (`X-Goog-Authenticated-User-Email`);
  (b) Server-side session + redirect to login;
  (c) Client-side guard component wrapping console layout.
  Note: IAP already protects the Cloud Run service in prod, so this is partly
  defense-in-depth for local dev and non-IAP deployments.
- **D65:** Add missing env vars to prod `terraform.tfvars`. Confirm correct
  values with infrastructure owner before applying.

### Dependencies

- D12 blocks WS-2 items (response models are less urgent than unprotected routes).
- D65 must be coordinated with a prod deployment window.
- D68 depends on understanding which jobs actually need PII secrets (only those
  calling tokenization/detokenization APIs).

### Acceptance Criteria

- [x] All 13 API routers require authentication (API key or IAP header).
- [x] `plan_id` parameter validated against safe pattern; malicious paths return 400.
- [x] Console pages redirect or show error for unauthenticated users in local dev.
- [x] Prod Terraform tfvars include `I4G_VECTOR__BACKEND=vertex`,
      `I4G_LLM__PROVIDER=vertex`, `I4G_LLM__CHAT_MODEL=gemini-2.5-flash`
      (or current model).
- [x] PII secrets injected into all jobs that perform tokenization operations.
- [x] API key moved from tfvars to Secret Manager reference.
- [x] `pytest tests/unit` passes (268+ tests, 0 failures).

---

## WS-2: API Quality & Contract Alignment

> **Priority:** HIGH — the SDK/backend contract drift causes silent data loss
> in search and broken type expectations on the frontend.
>
> **Estimated effort:** 3–5 days
> **Repos:** `core/`, `ui/`

### Items

| #   | Finding                                                                     | Severity | Status |
| --- | --------------------------------------------------------------------------- | -------- | ------ |
| D13 | `review.py` is 953 lines — needs splitting into sub-routers                 | HIGH     | [x]    |
| D15 | No logging in 11/13 API routers                                             | HIGH     | [x]    |
| D36 | SDK `searchIntelligence` targets non-existent `/search` endpoint            | HIGH     | [x]    |
| D37 | `indicatorTypes`/`lossBuckets` search filters silently dropped              | HIGH     | [x]    |
| D32 | No `response_model` on most API endpoints (broken OpenAPI)                  | MED      | [x]    |
| D38 | `CaseSummary.classification` type never returned by backend                 | MED      | [x]    |
| D46 | SDK covers only 9 of ~40+ backend endpoints                                 | MED      | [x]    |
| D60 | `CaseSummary.status` enum stricter than backend (Zod will throw on unknown) | LOW      | [x]    |
| D61 | Search field name camelCase→snake_case translation implicit/undocumented    | LOW      | [x]    |

### Design Decisions Required

- **D13:** ⚠️ How to split `review.py`? Proposed sub-routers:
  - `review_search.py` — search + history + saved searches
  - `review_queue.py` — queue actions (assign, decide, escalate)
  - `review_detail.py` — single-review CRUD + evidence
    Keep the `/reviews` prefix; use `APIRouter(prefix="/reviews", tags=[...])`.
- **D36/D37:** Fix SDK default `baseUrl` or remove dead `searchIntelligence`
  from SDK (platform-client already overrides correctly). Decide: fix SDK or
  document that SDK is not used directly for search.
- **D38:** ⚠️ Either add `classification` to the backend `GET /reviews/{id}`
  response, or remove it from the `CaseSummary` Zod schema. Which?
- **D46:** SDK expansion is a long-term item. For this sprint, document which
  endpoints the SDK covers vs. which require direct `platform-client` calls.

### Dependencies

- D13 is a refactor-only change (no behavior change) — safe to do independently.
- D36/D37 require coordination between `core/` and `ui/` repos.
- D32 (response models) naturally follows D13 (splitting makes it easier to add).
- D15 (logging) can be done in parallel with D13.

### Acceptance Criteria

- [x] `review.py` split into 3+ sub-routers, each ≤300 lines.
- [x] All 13 routers use `logger = logging.getLogger(__name__)` with
      request-level logging for errors and key actions.
- [x] SDK `searchIntelligence` either fixed or removed; search filters
      (`indicatorTypes`, `lossBuckets`) properly mapped to backend query params.
- [x] `CaseSummary` Zod schema matches actual backend response (no extra or
      missing fields).
- [x] ≥80% of API endpoints have `response_model` defined.
- [x] OpenAPI spec (`/docs`) renders correctly with typed responses.
- [x] Field name translation (camelCase↔snake_case) documented in
      `docs/book/api/` or SDK README.

---

## WS-3: Store Consolidation & Factory Discipline

> **Priority:** HIGH — the dual SQLite/SQLAlchemy implementation is the largest
> single source of duplication and consistency risk in the backend.
>
> **Estimated effort:** 3–5 days
> **Repos:** `core/`

### Items

| #   | Finding                                                             | Severity | Status |
| --- | ------------------------------------------------------------------- | -------- | ------ |
| D16 | SQLite/SQLAlchemy dual implementations (~800 LOC duplication)       | HIGH     | [x]    |
| D17 | `scam_records` dual-write with normalized schema (consistency risk) | HIGH     | [x]    |
| D18 | 8 prod-code locations bypass `factories.py` for store creation      | HIGH     | [x]    |
| D29 | Module-level `get_settings()` in 6+ store/service files             | MED      | [x]    |

### Design Decisions Required

- **D16:** ⚠️ Which implementation survives?
  - `sql.py` (raw SQLite via `sqlite3`) — simpler, used by bootstrap and CLI.
  - `structured.py` / `review_store.py` (SQLAlchemy ORM) — used by API and jobs.
  - **Proposed:** Keep SQLAlchemy as the single data access layer. Migrate
    remaining `sql.py` callers to use `session_factory` from `factories.py`.
    Delete `sql.py` after migration. Estimated ~800 LOC removal.
- **D17:** ⚠️ The `scam_records` table co-exists with the normalized schema
  (`cases`, `case_indicators`, `case_financial_summary`, etc.). Options:
  (a) Remove `scam_records` and migrate all reads to normalized tables;
  (b) Keep `scam_records` as a denormalized read-cache, fed by a trigger or
  post-write hook;
  (c) Deprecate gradually — stop writing, migrate reads, then drop.
- **D18/D29:** Straightforward refactor — replace direct `Store()` constructors
  and module-level `get_settings()` with `factories.py` builders and
  dependency injection.

### Dependencies

- D16 must be done before D17 (can't fix dual-write until the access layer is
  unified).
- D18 and D29 can be done in parallel with D16 or as a follow-up.
- Affects test fixtures — many unit tests create stores directly. Update
  `conftest.py` accordingly.

### Acceptance Criteria

- [x] Single data access path: all store operations go through SQLAlchemy
      session factories.
- [x] `sql.py` (raw `sqlite3` module) deleted or reduced to a thin migration-only
      utility.
- [x] `scam_records` write path consolidated (no dual-write).
- [x] Zero prod-code locations instantiate stores outside `factories.py`.
- [x] No module-level `get_settings()` calls in store/service files (settings
      passed via constructor or dependency injection).
- [x] `pytest tests/unit` passes with same or better coverage.

---

## WS-4: Service & Worker Cleanup

> **Priority:** HIGH — `pii_backfill.py` accesses private store internals and
> has no error handling; duplicate LLM factory logic creates drift risk.
>
> **Estimated effort:** 2–3 days
> **Repos:** `core/`

### Items

| #   | Finding                                                                         | Severity | Status |
| --- | ------------------------------------------------------------------------------- | -------- | ------ |
| D19 | Duplicate LLM factory logic in `classifier.py` + `llm_extractor.py`             | HIGH     | [x]    |
| D20 | `pii_backfill.py` — private attribute access, no error handling, no CLI harness | HIGH     | [x]    |
| D26 | Only 1/8 worker jobs uses TASK_STATUS progress reporting                        | MED      | [x]    |
| D30 | `_coerce_bool` / `_parse_datetime` duplicated across 5+ files                   | MED      | [x]    |
| D33 | `datetime.utcnow()` usage in 4+ files (deprecated Python 3.12+)                 | LOW      | [x]    |

### Design Decisions Required

- **D19:** Consolidate into `factories.py` — add `build_llm_client()` or
  similar. Minor design question: should the factory return a raw LLM client
  or a wrapped service object?
- **D20:** ⚠️ Is `pii_backfill` still needed? If yes, rewrite using public
  store APIs and add CLI subcommand. If no, delete.
- **D26:** TASK_STATUS integration is incremental — add progress callbacks
  to each job's main loop. No design decision, just implementation work.

### Dependencies

- D19 depends on WS-3 (D18 factory discipline) being at least partially done.
- D20 is independent.
- D30 and D33 are safe parallel changes (utility extraction + deprecation fix).

### Acceptance Criteria

- [x] Single LLM client factory in `factories.py`; `classifier.py` and
      `llm_extractor.py` use it.
- [x] `pii_backfill.py` either deleted or rewritten with: public store APIs,
      structured error handling, CLI harness, unit tests.
- [x] ≥4/8 worker jobs emit TASK_STATUS progress (at minimum: start, %, done).
- [x] `_coerce_bool` and `_parse_datetime` extracted to a shared
      `core/src/i4g/utils/` module; all callers updated.
- [x] Zero `datetime.utcnow()` calls — replaced with
      `datetime.now(datetime.UTC)`.

---

## WS-5: CLI Refactor

> **Priority:** MEDIUM — `bootstrap/dev.py` at 2064 lines is the largest single
> file in the codebase and a constant merge-conflict source. The
> `SimpleNamespace` proxy pattern adds ~400 LOC of unnecessary boilerplate.
>
> **Estimated effort:** 2–3 days
> **Repos:** `core/`

### Items

| #   | Finding                                                                | Severity | Status |
| --- | ---------------------------------------------------------------------- | -------- | ------ |
| D22 | `bootstrap/dev.py` is 2064 lines — needs decomposition                 | HIGH     | [x]    |
| D27 | `SimpleNamespace` proxy antipattern in 8/12 CLI subcommands (~400 LOC) | MED      | [x]    |

### Design Decisions Required

- **D22:** ⚠️ Decomposition strategy for `bootstrap/dev.py`. Proposed:
  - `bootstrap/stores.py` — store initialization and seeding
  - `bootstrap/vector.py` — vector store setup and indexing
  - `bootstrap/reports.py` — report generation bootstrapping
  - `bootstrap/dev.py` — top-level orchestrator importing the above
  - Each sub-module ≤500 lines.
- **D27:** Replace `SimpleNamespace` proxy with direct `get_settings()` calls
  or a thin `CLIContext` dataclass that's explicitly typed.

### Dependencies

- Independent of other work streams.
- D27 is simpler and can be done first as a warm-up.

### Acceptance Criteria

- [x] `bootstrap/dev.py` split into ≥3 modules; no single file exceeds 500 lines.
- [x] `SimpleNamespace` usage removed from all CLI subcommands.
- [x] CLI commands produce identical output before and after refactor (behavioral
      equivalence verified by running `i4g bootstrap local reset` against fresh
      `data/` directory).
- [x] All existing CLI tests pass.

---

## WS-6: UI Resilience & UX Quality

> **Priority:** HIGH — zero error boundaries means any React error crashes the
> entire console with a blank screen. Missing loading states create poor UX
> on slow connections.
>
> **Estimated effort:** 3–5 days
> **Repos:** `ui/`

### Items

| #   | Finding                                                                         | Severity | Status |
| --- | ------------------------------------------------------------------------------- | -------- | ------ |
| D39 | 0/9 console pages have error boundaries (`error.tsx`)                           | HIGH     | [x]    |
| D40 | 7/9 console pages have no loading state (`loading.tsx`)                         | HIGH     | [x]    |
| D42 | Zero Storybook configuration or stories for `@i4g/ui-kit`                       | HIGH     | [x]    |
| D45 | 3 separate auth patterns with duplicated boilerplate across server services     | MED      | [x]    |
| D48 | `search-experience.tsx` (1324 LOC) + `dossier-list.tsx` (998 LOC) decomposition | MED      | [x]    |
| D49 | Campaign form uses raw HTML inputs instead of ui-kit components                 | MED      | [x]    |
| D51 | Console layout entirely `"use client"` (prevents server-side nav optimization)  | MED      | [x]    |
| D58 | Non-functional placeholder buttons on dashboard and cases pages                 | LOW      | [x]    |

### Design Decisions Required

- **D39:** Standard `error.tsx` template for all pages? Proposed: shared
  `ErrorFallback` component in ui-kit that displays a user-friendly message +
  retry button. Each page's `error.tsx` wraps it.
- **D42:** ⚠️ Storybook setup scope: (a) Full Storybook with all 4 components +
  design tokens; (b) Minimal — just Badge/Button stories for now.
- **D48:** ⚠️ Decomposition targets for the two large page components. Proposed:
  - `search-experience.tsx` → `SearchFilters`, `SearchResults`, `SearchHistory`,
    `SearchPagination` + orchestrator
  - `dossier-list.tsx` → `DossierTable`, `DossierFilters`, `DossierActions` +
    orchestrator
- **D51:** ⚠️ Can the console layout be converted to a server component?
  Depends on whether the sidebar uses client-only hooks (e.g., `usePathname`).
  If yes, extract the interactive parts into a client sub-component.

### Dependencies

- D39 and D40 are independent quick wins (can start immediately).
- D42 (Storybook) is independent but benefits from D49 (adding ui-kit components
  for the campaign form gives more stories to write).
- D48 is a pure refactor — no behavior change.
- D45 (auth pattern consolidation) depends on WS-1 D41 (auth guard decision).

### Acceptance Criteria

- [x] All 9 console pages have an `error.tsx` boundary.
- [x] All 9 console pages have a `loading.tsx` skeleton.
- [x] Storybook runs locally (`pnpm storybook`) with stories for all ui-kit
      components (Badge, Button, Card, Input, ErrorFallback).
- [x] Server services use a single shared auth helper (no boilerplate duplication).
- [x] `search-experience.tsx` (259 LOC) and `dossier-list.tsx` (369 LOC) each
      reduced to ≤400 LOC via extracted sub-components.
- [x] Campaign form uses ui-kit `Input` and `Button` components.
- [x] Placeholder buttons removed from dashboard, cases list, and case detail.
- [x] `pnpm format` clean, Vitest 26 tests passing (5 test files).

---

## WS-7: Type Unification & Test Coverage

> **Priority:** MEDIUM — taxonomy type fragmentation causes confusion; zero
> test coverage on 5 shared packages means regressions go undetected.
>
> **Estimated effort:** 1–2 days
> **Repos:** `ui/`

### Items

| #    | Finding                                                                                                | Severity | Status |
| ---- | ------------------------------------------------------------------------------------------------------ | -------- | ------ |
| D79  | API JSON uses inconsistent casing — need Pydantic `alias_generator` + SDK cleanup                      | HIGH     | [x]    |
| D47  | `TaxonomyItem`/`TaxonomyAxis` defined in 3 separate places                                             | MED      | [x]    |
| D55  | 5 shared packages have zero test files                                                                 | MED      | [x]    |
| D57  | No coverage thresholds enforced in Vitest config                                                       | LOW      | [x]    |
| D55b | Unit tests for new WS-4 modules (`llm/client`, `utils/coerce`, `utils/datetime_parse`, `pii_backfill`) | MED      | [x]    |

### Design Decisions Required

- **D79:** ⚠️ Standardize API JSON on camelCase. Approach:
  (a) Add a `CamelModel` base class with `alias_generator = to_camel` and
  `model_config = {"populate_by_name": True, "by_alias": True}`.
  (b) Migrate all `response_models.py` + `cases.py` + other Pydantic models to
  inherit from `CamelModel`. Backend Python stays snake_case internally.
  (c) Delete SDK `normalize*` functions (~100 LOC), platform-client request
  mapping (~15 LOC), and helpers dual-key patterns (~30 LOC).
  (d) Fix any remaining mixed-casing fields in backend models (e.g.,
  `CaseDetail` has `updatedAt` + `graph_nodes` in the same model).
  Ref: `docs/book/api/field_name_translation.md` catalogs all 14 sites.
- **D47:** ⚠️ Single source of truth for taxonomy types. Options:
  (a) `@i4g/types` package is canonical — SDK Zod schemas and page-local
  types import from it;
  (b) SDK Zod schemas are canonical — `@i4g/types` re-exports inferred types;
  (c) Merge `@i4g/types` into SDK entirely.
- **D55/D57:** Which packages get tests first? Proposed priority:
  1. `@i4g/sdk` — most critical shared code
  2. `@i4g/ui-kit` — visual regression tests via Storybook (covered in WS-6)
  3. `@i4g/types` — type-only package, tests are less impactful

### Dependencies

- D47 may be partially addressed by WS-2 (D38 — `CaseSummary` schema fix).
- D55 is independent.
- D57 requires D55 to be meaningful (can't enforce thresholds without tests).

### Acceptance Criteria

- [x] All Pydantic response models inherit from a `CamelModel` base that
      serves camelCase JSON via `alias_generator`. Python code stays snake_case.
- [x] SDK `normalize*` functions deleted (no manual field renaming).
- [x] Platform-client and helpers have zero manual casing translation.
- [x] `TaxonomyItem` and `TaxonomyAxis` defined in exactly 1 package; all
      other locations import from that source.
- [x] `@i4g/sdk` has ≥5 unit tests covering core client methods.
- [x] Vitest config enforces minimum coverage thresholds (e.g., 60% statements
      for `@i4g/sdk`).

---

## WS-8: Dead Code & Hygiene

> **Priority:** LOW — these items reduce noise and prevent confusion but carry
> minimal runtime risk.
>
> **Estimated effort:** 1–2 days
> **Repos:** `core/`, `infra/`, `docs/`

### Items

| #    | Finding                                                                       | Severity | Status |
| ---- | ----------------------------------------------------------------------------- | -------- | ------ |
| D28  | 3 dead/legacy report files (~285 LOC) from M5.1 prototype                     | MED      | [x]    |
| D34  | `docs/config/settings_manifest.yaml` 67 days stale                            | MED      | [x]    |
| D62  | 3 stale Azure secrets in Terraform                                            | MED      | [x]    |
| D63  | Vestigial `roles/datastore.*` IAM bindings                                    | MED      | [x]    |
| D64  | `I4G_INGEST__ENABLE_TOKENIZATION` dead env var (4 Terraform, 0 Python)        | LOW      | [x]    |
| D70  | Dev Vertex AI Search tfvars has `REPLACE_WITH_*` placeholders                 | LOW      | [x]    |
| D77  | Prod missing `sweeper` and `account_list` job definitions                     | LOW      | [x]    |
| D78  | IAP `oauth_client` module is a no-op stub                                     | LOW      | [x]    |
| D28b | `llm_extractor.py` stale `_provider_override_from_env()` + dead comment block | LOW      | [x]    |

### Design Decisions Required

- **D62:** ⚠️ Confirm Azure secrets are truly unused before removing from
  Terraform. Cross-check with `dtp/` repo.
- **D63:** ⚠️ Confirm no Datastore usage anywhere before removing IAM bindings.
  (Consolidation audit found none, but verify with `gcloud` audit logs if
  available.)
- **D77:** ⚠️ Are sweeper and account_list jobs needed in prod yet, or are they
  dev-only for now?

### Dependencies

- All items are independent.
- D34 (manifest refresh) should follow any Settings model changes in WS-1 or
  WS-4.

### Acceptance Criteria

- [x] Dead report files (`gdoc_exporter.py`, `template_engine.py`,
      `generator.py`) reclassified — still actively used by
      `generate_report_for_case()` in `worker/tasks.py` and `worker/jobs/report.py`.
      Deletion deferred until the dossier pipeline fully replaces this path.
- [x] `settings_manifest.yaml` regenerated and matches current Pydantic model.
- [x] Stale Azure secrets removed from Terraform (after confirmation).
- [x] Vestigial Datastore IAM bindings removed (after confirmation).
- [x] Dead `I4G_INGEST__ENABLE_TOKENIZATION` removed from all 4 Terraform
      locations.
- [x] Vertex AI Search tfvars has real values or is clearly marked as
      requires-manual-setup.
- [x] Prod Terraform updated with sweeper/account_list jobs (if confirmed
      needed) or documented as dev-only.

---

## WS-9: CI/CD & Infrastructure Automation

> **Priority:** MEDIUM — manual Docker builds and missing CI pipelines slow
> iteration and increase deployment risk.
>
> **Estimated effort:** 2–3 days
> **Repos:** `core/`, `ui/`, `infra/`

### Items

| #   | Finding                                                                    | Severity | Status |
| --- | -------------------------------------------------------------------------- | -------- | ------ |
| D66 | 6 `I4G_ACCOUNT_JOB__*` env vars bypass Settings model (`os.getenv()`)      | MED      | [x]    |
| D67 | `I4G_RUNTIME__FALLBACK_DIR` + `I4G_INTAKE__API_BASE` bypass Settings model | MED      | [x]    |
| D71 | No CI workflow for UI repo                                                 | MED      | [x]    |
| D72 | No prod Terraform workflow (only dev has `terraform-dev.yml`)              | MED      | [x]    |
| D73 | Docker build/push is fully manual (no CI pipeline)                         | MED      | [x]    |

### Design Decisions Required

- **D66/D67:** ✅ Option (a) chosen. Created `AccountJobSettings` and
  `IntakeJobSettings` nested sections in `config.py`. Added `fallback_dir` to
  `RuntimeSettings`. Refactored `account_list.py`, `intake.py`, and
  `evidence.py` to read from Settings instead of raw `os.getenv()`. Manifest
  regenerated with 116 fields (12 new). 330 tests pass.
- **D71:** ✅ Full scope (a+b+c). PR triggers lint + type-check + Vitest.
  Push to main with `VERSION.txt` change triggers Docker build + push.
  Created `ui/VERSION.txt` (0.1.0) and `ui/.github/workflows/ui-ci.yml`.
- **D72:** ✅ Option (b) with GitHub environment protection. Plan on PR,
  auto-apply on merge to main. Uses `environment: production` for approval
  gate. Created `infra/.github/workflows/terraform-prod.yml`.
- **D73:** ✅ Triggered by `VERSION.txt` changes on main. Matrix strategy
  builds all 6 images in parallel, pushes to both dev and prod registries.
  Created `core/.github/workflows/docker-build.yml`.

### Dependencies

- D66/D67 are Python-only changes (independent of CI work).
- D71/D72/D73 are infrastructure work that can proceed in parallel.

### Acceptance Criteria

- [x] All `I4G_ACCOUNT_JOB__*`, `I4G_RUNTIME__FALLBACK_DIR`, and
      `I4G_INTAKE__API_BASE` env vars either added to Settings model or documented
      in `settings_manifest.yaml` with rationale for bypass.
- [x] UI repo has a GitHub Actions CI workflow that runs on PR (lint, type-check,
      test).
- [x] Prod Terraform has at minimum a plan-on-PR workflow.
- [x] Docker build/push is automated (manual trigger at minimum).
- [x] `docs/config/settings_manifest.yaml` updated to reflect any new Settings
      sections.

---

## WS-10: Dev/Prod Parity

> **Priority:** HIGH — structural drift between `app/dev` and `app/prod`
> Terraform configurations means prod may be missing IAM roles, API
> enablements, and runtime env vars that dev relies on. Some items are likely
> blocking prod functionality today.
>
> **Discovered:** 2026-02-11 during WS-8 cross-project IAM fix
> **Estimated effort:** 3–5 days
> **Repos:** `infra/`

### Items

| #   | Finding                                                                              | Severity | Status |
| --- | ------------------------------------------------------------------------------------ | -------- | ------ |
| D80 | Prod SAs missing `roles/cloudsql.client` + `roles/cloudsql.instanceUser`             | HIGH     | [x]    |
| D81 | Prod SAs missing `roles/aiplatform.user`                                             | HIGH     | [x]    |
| D82 | Prod missing `vertex_ai` API enablement (`aiplatform.googleapis.com`)                | HIGH     | [x]    |
| D83 | Prod missing `report_sa_service_usage` IAM binding                                   | HIGH     | [x]    |
| D84 | `database.tf` has 6 hardcoded values that should be variables                        | MED      | [x]    |
| D85 | Vertex AI Search variables use different shapes (object in dev vs 3 scalars in prod) | MED      | [x]    |
| D86 | `run_job_dynamic_env_vars` pattern only in dev — prod jobs miss Vertex Search vars   | MED      | [x]    |
| D87 | `run_fastapi` hardcodes LLM/Vertex env vars in dev `.tf` instead of tfvars           | MED      | [x]    |
| D88 | `run_console` conditional deployment, resource limits, env vars differ structurally  | MED      | [x]    |
| D89 | IAM role differences: `storage.objectAdmin` in dev vs `storage.objectViewer` in prod | MED      | [x]    |
| D90 | `main.tf` org policy only in dev                                                     | MED      | [x]    |
| D91 | `outputs.tf` structurally different between dev and prod                             | MED      | [x]    |
| D92 | Dev uses LB-based IAP, prod uses per-service IAP modules                             | LOW      | [x]    |
| D93 | Networking resources (egress IP, NAT, VPC connector) only in dev                     | LOW      | [x]    |
| D94 | Prod `backend.tf` missing `random` provider                                          | LOW      | [x]    |

### Design Decisions Required

- **D80/D81:** ✅ Confirmed prod Cloud SQL and Vertex AI are in use (tfvars
  reference Cloud SQL instances and `vertex_ai` provider). Added
  `roles/cloudsql.client` + `roles/cloudsql.instanceUser` to app, ingest,
  report SAs; `roles/aiplatform.user` to app and ingest SAs.
- **D82:** ✅ Enabling `aiplatform.googleapis.com` confirmed needed — prod
  tfvars already set `I4G_LLM__PROVIDER=vertex_ai`. API resource added.
- **D85/D86:** ✅ Adopted dev's single-object `vertex_ai_search` variable in
  prod. Removed 3 scalar variables. Added `run_job_dynamic_env_vars` local to
  prod matching dev's pattern.
- **D87:** ✅ Moved `I4G_LLM__PROVIDER`, `I4G_LLM__CHAT_MODEL`, and
  `I4G_STORAGE__EVIDENCE__LOCAL_DIR` from hardcoded dev `main.tf` into dev's
  `terraform.tfvars`. Also added `I4G_STORAGE__EVIDENCE__LOCAL_DIR` to prod
  tfvars for consistency.
- **D89:** ✅ Changed prod app SA from `storage.objectViewer` to
  `storage.objectAdmin` — the app writes evidence and reports to GCS.
- **D90:** ✅ Documented as **intentionally dev-only**. The org policy allows
  `allUsers` in invoker bindings, which is a dev convenience for testing. Prod
  should not have this policy.
- **D92:** ⚠️ IAP architecture unification is the largest item. Options:
  (a) Migrate prod to LB-based IAP (matches dev, enables custom domain);
  (b) Keep architectural divergence and document the rationale;
  (c) Migrate dev to per-service IAP (matches prod, simpler but less flexible).
  This item is large enough to be its own work stream if chosen.

### Dependencies

- D80–D83 are independent quick fixes (add IAM roles + API enablement).
- D84–D91 are structural normalization that can be done incrementally.
- D92/D93 are architectural decisions — may warrant separate investigation.
- Should be done after WS-9 (CI/CD) so that Terraform CI catches drift going
  forward.

### Acceptance Criteria

- [x] Prod SAs have the same base IAM roles as dev (Cloud SQL, AI Platform,
      Service Usage).
- [x] Vertex AI API enabled in prod (if confirmed needed).
- [x] `database.tf` hardcoded values extracted to variables with prod-specific
      tfvars.
- [x] Vertex AI Search variables use a consistent shape across dev and prod.
- [x] `run_job_dynamic_env_vars` pattern (or equivalent) present in prod for
      Vertex Search environment variables.
- [x] `outputs.tf` structurally aligned between dev and prod.
      Both environments now output the same keys: `serverless_egress_ip`,
      `global_lb_ip`, `iap` (brand_name only). Domain mapping and per-service
      IAP outputs removed from prod.
- [x] IAP architecture unified (D92). Prod migrated from per-service IAP
      (`module.iap_fastapi`, `module.iap_console`, domain mappings) to
      LB-based IAP (`module.global_lb` + `google_iap_web_backend_service_iam_binding`).
      Both environments now use the same architecture: Global LB → Serverless
      NEG → Cloud Run with `internal-and-cloud-load-balancing` ingress.
      Custom domains: prod `*.intelligenceforgood.org`, dev `*.dev.intelligenceforgood.org`.
- [x] `terraform plan` in both dev and prod shows no unexpected changes after
      parity work. Verified during post-state-migration recovery. Dev: 5 adds
      (admin user + IAM bindings + NAT replace), 2 changes, 1 destroy — all
      expected. Prod: 7 adds (database + SQL users recreation), 1 change — all
      expected post-recovery items.

---

## Recommended Sprint Order

```
Sprint 1 (Week 1):  WS-1 Security & Auth ──────────── highest risk, unblocks WS-2     ✅ DONE
Sprint 2 (Week 2):  WS-2 API Quality ──────────────── SDK/backend contract fix         ✅ DONE
                     WS-8 Dead Code (parallel) ─────── quick wins, low risk             ✅ DONE
Sprint 3 (Week 3):  WS-3 Store Consolidation ──────── largest refactor                 ✅ DONE
Sprint 4 (Week 4):  WS-6 UI Resilience ────────────── error boundaries + loading       ✅ DONE
                     WS-7 Type Unification (parallel)                                  ✅ DONE
Sprint 5 (Week 5):  WS-4 Service & Worker ─────────── depends on WS-3                 ✅ DONE
                     WS-5 CLI Refactor (parallel) ──────────────────────────────────── ✅ DONE
Sprint 6 (Week 6):  WS-10 Dev/Prod Parity ─────────── 15/15 done                                    ✅ DONE
Sprint 7 (Week 7):  WS-9 CI/CD & Infrastructure ──── wrap up automation
```

This order can be adjusted based on team capacity and upcoming feature work.
WS-10 should prioritize the high-severity IAM/API gaps (D80–D83) first, as they
may be silently blocking prod functionality.

---

## Cross-Reference: Original Debt IDs

For traceability back to the consolidation audit:

| Work Stream | Debt IDs                                    |
| ----------- | ------------------------------------------- |
| WS-1        | D12, D14, D41, D65, D68, D69                |
| WS-2        | D13, D15, D32, D36, D37, D38, D46, D60, D61 |
| WS-3        | D16, D17, D18, D29                          |
| WS-4        | D19, D20, D26, D30, D33                     |
| WS-5        | D22, D27                                    |
| WS-6        | D39, D40, D42, D45, D48, D49, D51, D58      |
| WS-7        | D47, D55, D57, D79                          |
| WS-8        | D28, D34, D62, D63, D64, D70, D77, D78      |
| WS-9        | D66, D67, D71, D72, D73                     |
| WS-10       | D80–D94                                     |

---

## Session Log

> Append an entry every session. Format:
> `### YYYY-MM-DD — Summary`

### 2026-02-09 — Plan Creation

- Created this document from the 50 open debt items in `consolidation_plan.md`.
- Organized into 9 work streams ordered by risk (security first, hygiene last).
- Estimated 20–33 days total effort across all work streams.
- Proposed 6-sprint execution plan (~6 weeks).
- Marked `consolidation_plan.md` as superseded.

### 2026-02-09 — WS-1 Security & Auth Hardening (COMPLETE)

- **D12 — Auth on all routers:** Updated `require_token` in `auth.py` to check
  `settings.identity.disable_auth`. When `True` (local env), auth is bypassed
  and a mock admin user is returned; when a valid token header is provided it is
  still honoured for test compatibility. Added `Depends(require_token)` to all
  13 API routers (analytics, cases, campaigns, dashboard, discovery, taxonomy,
  reports, tasks, `/reports/generate`, and the 3 unprotected review.py
  endpoints: `list_queue`, `get_review`, `actions`). Also added to
  `tokenization_health`.
- **D14 — Path traversal fix:** Added `_validate_plan_id()` with regex
  `^[a-zA-Z0-9][a-zA-Z0-9_.\-]{0,127}$`; called at the top of every
  `plan_id`-accepting endpoint. Updated `_resolve_relative()` to confine
  resolved paths within `ARTIFACTS_DIR` via `.relative_to()` check. Added
  defense-in-depth confinement in `download_dossier_artifact` before
  `FileResponse`.
- **D41 — Console auth guard:** Created `ui/apps/web/middleware.ts`. In local
  env (I4G_ENV=local or localhost API target), all requests pass through. In
  dev/prod, middleware checks for `X-Goog-Authenticated-User-Email` IAP header
  and returns 401 JSON if absent.
- **D65 — Prod env vars:** Added `I4G_VECTOR__BACKEND=vertex_ai`,
  `I4G_LLM__PROVIDER=vertex_ai`, `I4G_LLM__CHAT_MODEL=gemini-2.5-flash` to
  `infra/environments/app/prod/terraform.tfvars`.
- **D68 — Secret injection:** Added `secret_env_vars` (PII pepper +
  crypto key) to prod ingest job, prod report job, and dev report job.
- **D69 — API key to Secret Manager:** Removed plain-text `I4G_API_KEY` from
  `console_env_vars` in dev and prod tfvars. Added `console_secret_env_vars`
  variable + wiring in both `variables.tf` and `main.tf` for dev and prod.
  Moved intake job `I4G_API__KEY` to `secret_env_vars`. Cleaned
  `local-overrides.tfvars`.
- **Tests:** 268 passed, 3 xfailed, 0 failures.
- **Infra note:** Before applying Terraform changes, create the Secret Manager
  secret `api-key` in both `i4g-dev` and `i4g-prod` projects with the
  appropriate token values.

### WS-2 Session — API Quality & Contract Alignment

**All 9 items completed.**

- **D13 — Split review.py:** Original 953-line file split into 4 modules:
  `review_deps.py` (shared dependency factories, 72 LOC),
  `review_search.py` (13 search routes + helpers, 770 LOC),
  `review_queue.py` (6 queue/action routes, 190 LOC),
  `review_detail.py` (3 detail routes, 55 LOC).
  Original `review.py` rewritten as 55-line thin orchestrator with backward-
  compatible re-exports. Function identity preserved for
  `app.dependency_overrides` in tests.
- **D15 — Logging:** Added `logger = logging.getLogger(__name__)` to all 9
  routers that were missing it. Added request-level log statements to intake,
  tokenization, campaigns, and reports routers.
- **D36 — SDK search fix:** Default SDK `searchIntelligence` now throws a
  clear error directing callers to use `createPlatformClient()` instead of
  silently calling the non-existent `POST /search` endpoint.
- **D37 — Search filter forwarding:** Platform client now forwards
  `lossBuckets` to the backend as `loss_buckets` (was silently dropped).
  `indicatorTypes` confirmed as schema metadata only, not a query filter.
- **D32 — Response models:** Created `api/response_models.py` with 40+ typed
  Pydantic response models. Added `response_model=` to 43/50 applicable
  endpoints (86% coverage, exceeding the 80% target). Remaining 7 endpoints
  return dynamic/arbitrary dicts from store lookups.
- **D38 — Classification alignment:** Added `classification` field to
  `CaseDetail` Pydantic model. Surfaced `classification_result` from
  `review_queue` table in both `get_extended_case()` and
  `get_dashboard_summary()`. JSON-parses the stored value when it is a string.
- **D60 — Status/priority enums:** Changed `CaseDetail.status` from `str` to
  `Literal["new", "in_review", "awaiting_input", "closed", "accepted",
"rejected"]` and `priority` to `Literal["critical", "high", "medium", "low"]`
  matching the SDK Zod enums.
- **D46 — SDK coverage doc:** Created `docs/book/api/sdk_endpoint_coverage.md`
  documenting 9 covered SDK methods vs ~40+ uncovered endpoints, with guidance
  on extending coverage.
- **D61 — Field translation doc:** Created
  `docs/book/api/field_name_translation.md` cataloguing all 14 manual
  camelCase/snake_case translation points across 4 files with complete field
  mapping tables.
- **Tests:** 268 passed, 3 xfailed, 0 failures.
- **Design decisions:** SDK `searchIntelligence` kept as a throw (not removed)
  to preserve the type interface while guiding callers to the correct client.
  `campaigns.py PATCH` endpoint now returns `{"updated": True, "campaign_id":
...}` instead of implicit `None`.

### WS-3 Session — Store Consolidation & Factory Discipline

**D16 — SQLite/SQLAlchemy dual implementations:**

- `structured.py`: Merged `StructuredStore` (raw sqlite3, ~260 LOC) and
  `SqlAlchemyStructuredStore` (~260 LOC) into a single unified
  `StructuredStore` using SQLAlchemy Core. Added `dialect_insert()` helper
  in `sql.py` for cross-dialect upserts (SQLite `ON CONFLICT` vs PostgreSQL
  `ON CONFLICT`). Added `list_all()` method (used by `pii_backfill.py`).
  `SqlAlchemyStructuredStore` kept as alias. ~260 lines down from ~521.
- `dossier_queue_store.py`: Same pattern. `lease_next()` uses dialect
  branching — PostgreSQL: `FOR UPDATE SKIP LOCKED` + `RETURNING`; SQLite:
  `SELECT` + `UPDATE` in same transaction. ~250 lines down from ~448.
- `intake_store.py`: Same pattern. Merged `IntakeStore` (sqlite3) and
  `SqlAlchemyIntakeStore` into single unified class. All `create_intake`
  params kept keyword-only. ~270 lines down from ~635.

**D17 — scam_records dual-write:** Resolved by D16 — the single SQLAlchemy
path eliminates the dual-write risk entirely.

**D18 — Factory bypass locations:**

- `bundle_candidates.py`: Now uses `build_review_store()` and
  `build_structured_store()` (lazy import to avoid circular dependency with
  `factories.py`).
- `account_list.py`: `get_review_store()` dependency provider now calls
  `build_review_store()`.
- `bootstrap/seed.py` and `cli/extract/tasks.py`: Kept direct
  `DossierQueueStore()` since they're CLI/bootstrap code with valid local
  use cases. Clarified with comments.
- `pii_backfill.py`: Replaced `store._conn` raw sqlite3 access with
  `store.list_all()` (new public method). Removed `json.loads()` calls
  since SQLAlchemy JSON columns auto-deserialize.
- `worker/tasks.py` and `reports/generator.py`: Already used factory
  functions as fallback (monkeypatch guard pattern) — no changes needed.

**D29 — Module-level get_settings():**

- `structured.py`, `dossier_queue_store.py`, `intake_store.py`: Removed
  entirely — unified constructors accept `session_factory` or `db_path`.
- `review_store.py`: Removed unused `SETTINGS = get_settings()` and the
  `from i4g.settings import get_settings` import.
- `vector.py`: Moved `SETTINGS`, `DEFAULT_VECTOR_DIR`, `DEFAULT_FAISS_DIR`,
  `DEFAULT_MODEL_NAME` from module level to lazy resolution inside
  `VectorStore.__init__()` and `_default_backend()`.

**factories.py simplification:** Removed backend branching and `SqlAlchemy*`
class imports from `build_structured_store()`, `build_dossier_queue_store()`,
and `build_intake_store()`. All three now just pass `session_factory=` for
Cloud SQL or `db_path=` for SQLite.

**Test changes:** Updated `test_store_structured_sqlalchemy.py` — replaced
obsolete SET ROLE/RESET ROLE tests with alias and session_factory acceptance
tests.

- **Tests:** 268 passed, 3 xfailed, 0 failures.
- **LOC reduction:** ~800+ lines of duplicated raw sqlite3 code removed.

### WS-4 Session — Service & Worker Cleanup

**Date:** 2026-02-12
**Items completed:** D19, D20, D26, D30, D33 (all 5)
**Tests:** 268 passed, 3 xfailed, 0 failures.

**D33 — datetime.utcnow() replacement:**

- Replaced all `datetime.utcnow()` calls with `datetime.now(timezone.utc)`
  across 11 source files and 4 test files (24 individual replacements).
- Files: `schema.py`, `sql_writer.py`, `ingestion_run_tracker.py`, `ingest.py`,
  `classification_sweeper.py`, `generator.py`, `taxonomy.py`,
  `bundle_manifest.py`, `synthetic_coverage.py`, `cases.py`, `datasets.py`,
  plus tests `test_retriever.py`, `test_entity_store.py`,
  `test_hybrid_search_service.py`, `ocr_extract_texts.py`.
- Note: `_utcnow()` wrapper functions in `ingestion_run_tracker.py` and
  `taxonomy.py` already used the correct call internally — left as-is.

**D30 — Shared utils module:**

- Created `src/i4g/utils/` package with `coerce.py` and `datetime_parse.py`.
- `coerce.py`: unified `coerce_bool()`, `env_bool()`, `env_int()`, `env_list()`.
- `datetime_parse.py`: unified `parse_datetime()` with `on_error` parameter
  (`"none"`, `"now"`, `"raise"`).
- Updated 7 callers to delegate to shared utils: `intake_job_runner.py`,
  `worker/jobs/account_list.py`, `worker/jobs/dossier_queue.py`,
  `reports/dossier_pilot.py`, `reports/bundle_candidates.py`,
  `api/review_search.py`, `api/account_list.py`.
- Local helpers retained as thin wrappers for API compatibility.

**D20 — pii_backfill.py rewrite:**

- Rewrote with per-record error handling (try/except, continue on failure).
- Added `TaskStatusReporter` integration (started/processing/finished).
- Added `main()` entry point and CLI command `pii-backfill` in
  `cli/jobs/__init__.py`.
- Uses `env_bool` from shared utils.

**D19 — LLM client factory:**

- Created `src/i4g/llm/client.py` with:
  - `LLMClient` Protocol (simple `generate(prompt) -> str`).
  - `build_llm_client()` — provider-based factory returning `LLMClient`.
  - `build_langchain_llm()` — provider-based factory returning LangChain
    Runnable.
  - `_resolve_model_name()` — centralized model fallback logic.
  - `_build_vertex_langchain()` with `_VertexLangChainAdapter` inner class.
- Updated `classifier.py`: replaced inline 23-line provider switch with
  single `build_llm_client()` call.
- Updated `llm_extractor.py`: removed 65-line `_build_vertex_client()` method;
  `_build_client()` now delegates to `build_langchain_llm()`.
- Updated `rag/pipeline.py`: uses `build_langchain_llm()` instead of
  hardcoded `ChatOllama(model="llama3.1")`.
- Updated `factories.py`: exposes `build_llm_client` and `build_langchain_llm`
  in `__all__`.
- Updated test: `test_classifier_init_ollama` patch target changed from
  `i4g.services.classifier.get_settings` to `i4g.llm.client.get_settings`.

**D26 — TASK_STATUS progress in worker jobs:**

- 4/8 jobs now emit progress via `TaskStatusReporter`:
  1. `dossier_queue.py` (pre-existing).
  2. `pii_backfill.py` (added during D20).
  3. `report.py` — added started/processing/finished with `env_bool` import.
  4. `classification_sweeper.py` — added reporter with started/processing/
     finished around batch loop.
- Remaining 4 jobs (`account_list`, `ingest`, `intake_job_runner`,
  `vault_job_runner`) are lower priority and can be addressed later.

### WS-5 Session — CLI Refactor (In Progress)

**Date:** 2026-02-13
**Items completed:** D22
**Tests:** 268 passed, 3 xfailed, 0 failures.

**D22 — bootstrap/dev.py & bootstrap/local.py decomposition:**

- Decomposed `bootstrap/dev.py` (2064 lines) into `bootstrap/dev/` package
  with 10 focused modules, each ≤500 lines:
  - `__init__.py` — thin re-exports (`dev_app`, `run_dev`, `main`)
  - `constants.py` — path constants, `JobSpec`/`JobResult` dataclasses
  - `utils.py` — `configure_logging`, `guard_environment`, `format_command`,
    `run_command`, `fetch_pepper`, `summarize_bundle`
  - `jobs.py` — `build_job_specs`, `execute_job` (Cloud Run job management)
  - `smoke.py` — `_get_iap_token`, `run_smoke`
  - `verify.py` — `verify_cloud_state` (GCS, Cloud SQL, PII, Vertex)
  - `reports.py` — `write_reports` (JSON + Markdown report generation)
  - `ingest.py` — `run_local_ingest` (local ingestion alternative)
  - `orchestrator.py` — `parse_args`, `bootstrap_dev`, `run_dev`, `main`
  - `commands.py` — `dev_app` Typer + 4 commands (reset/load/verify/smoke)
- Decomposed `bootstrap/local.py` (823 lines) into `bootstrap/local/` package
  with 6 modules:
  - `__init__.py` — thin re-exports (`local_app`, `run_local`)
  - `constants.py` — path constants, `DEFAULT_PILOT_CASES` data
  - `steps.py` — all bootstrap step functions (`reset_artifacts`,
    `ensure_dirs`, `build_bundles`, `ingest_bundles`, OCR, seeding, etc.)
  - `verify.py` — `verify_sandbox` (local verification + report emission)
  - `orchestrator.py` — `run_local` (top-level flow orchestration)
  - `commands.py` — `local_app` Typer + 4 commands (reset/load/verify/smoke)
- Module structure mirrors CLI command group hierarchy:
  `i4g bootstrap {local,dev} {reset,load,verify,smoke}`
- `bootstrap/__init__.py` unchanged — package re-exports maintain same API.
- Eliminated duplicate `_file_sha256` function (consolidated to `hash_file`
  from `cli.utils`).
- **Remaining:** D27 (SimpleNamespace proxy antipattern) not yet addressed.

**D27 — SimpleNamespace proxy elimination:**

**Date:** 2026-02-14
**Tests:** 268 passed, 3 xfailed, 0 failures (baseline preserved).

- Converted all callee functions from `def func(args: Any/object/Namespace)` with
  `args.X` access to `def func(*, explicit_kwarg: type)` with direct parameter usage.
- Updated all Typer command callers to pass kwargs directly instead of constructing
  SimpleNamespace objects.
- Modules refactored (16 files total):
  - `extract/tasks.py` + `extract/__init__.py` — 4 functions: `ocr`, `extraction`,
    `semantic`, `lea_pilot`
  - `data/indexing.py` + `data/datasets.py` + `data/__init__.py` — `build_index`,
    `generate_dataset`
  - `reports/tasks.py` + `reports/__init__.py` — `verify_dossier_hashes`,
    `verify_ingestion_run`
  - `search/logic.py` + `search/__init__.py` — 5 functions: `run_query`,
    `run_vertex_search`, `query_vertex`, `evaluate_vertex`,
    `refresh_hybrid_schema_snapshot`
  - `ingest/logic.py` + `ingest/__init__.py` — `ingest_bundles`,
    `ingest_vertex_search`, `tag_saved_searches`
  - `smoke/dossiers.py` + `smoke/runner.py` + `smoke/__init__.py` — `run_smoke`,
    `vertex_search_smoke`, `cloud_run_smoke`; removed anonymous
    `type("VertexArgs", ...)()` class construction
  - `admin/saved_searches.py` + `admin/dossiers.py` + `admin/pilot.py` +
    `admin/__init__.py` — 9 functions across 3 callee modules;
    11 SimpleNamespace constructions removed from `__init__.py`
  - `bootstrap/common.py` + `bootstrap/dev/smoke.py` +
    `bootstrap/dev/orchestrator.py` + `bootstrap/local/orchestrator.py` —
    `run_search_smoke`, `run_dossier_smoke`, `run_smoke`; removed
    `argparse.Namespace` proxy construction in `local/orchestrator.py`
- Fixed variable shadowing bugs: `status` → `row_status` in `reports/tasks.py`,
  `ground_truth` → `gt` in `data/datasets.py`, `preview` → `preview_count` in
  `admin/dossiers.py`
- Updated test: `test_saved_searches_export.py` updated to pass kwargs.
- Note: `bootstrap/dev/orchestrator.py`'s `bootstrap_dev(args)` still uses
  `argparse.Namespace` internally for deep threading into sub-modules
  (`run_local_ingest`, `execute_job`, `write_reports`). The callers of smoke
  functions within it were updated to pass kwargs. Full conversion of the
  orchestrator internals is a separate effort (low priority, as argparse.Namespace
  is idiomatic there).

### 2026-02-11 — WS-8 Dead Code & Hygiene (COMPLETE)

**Date:** 2026-02-11
**Items completed:** D28 (reclassified), D28b, D34, D62, D63, D64, D70, D77, D78
**Tests:** 324 passed, 3 xfailed, 0 failures.

**D28 — Legacy report files reclassified (NOT dead):**

- Investigation revealed `generator.py`, `gdoc_exporter.py`, and
  `template_engine.py` are still actively used by `generate_report_for_case()`
  in `worker/tasks.py` (called by `review_queue.py` API route and
  `worker/jobs/report.py` batch job). Deletion deferred until the dossier
  pipeline fully replaces the old report generation path.

**D28b — llm_extractor.py stale code removed:**

- Deleted `_provider_override_from_env()` (6 LOC) that manually scanned env
  vars, bypassing the Settings env-override pipeline.
- Simplified `__init__` to `self.provider = (self.settings.llm.provider or
"ollama").lower()`.
- Removed dead `if not indicators: pass` comment block (4 LOC).
- Removed unused `import os`.

**D34 — settings_manifest.yaml refreshed:**

- Copied up-to-date `core/docs/config/settings_manifest.yaml` (generated
  2026-02-07, 973 lines) to `docs/config/settings_manifest.yaml`, replacing
  the stale 2025-12-02 version (777 lines, missing 20 fields including
  `crypto`, `pii`, and `report` sections).

**D62 — Stale Azure secrets removed:**

- Removed 3 Azure Secret Manager resources from dev main.tf:
  `azure-sql-connection-string`, `azure-storage-connection-string`,
  `azure-search-admin-key`.
- Removed 2 Azure Secret Manager resources from prod main.tf:
  `azure-storage-connection-string`, `azure-search-admin-key`.

**D63 — Vestigial Datastore IAM bindings removed:**

- Removed `roles/datastore.user` from 5 service accounts (app, ingest, intake,
  report, vault) in both dev and prod main.tf.
- Removed `roles/datastore.viewer` from app service account in both dev and
  prod main.tf.
- Updated `core/docs/design/iam.md` and
  `infra/modules/iam/service_account_bindings/README.md` to remove datastore
  role references.

**D64 — Dead `I4G_INGEST__ENABLE_TOKENIZATION` removed:**

- Removed from 4 Terraform locations:
  1. dev `run_fastapi` env_vars
  2. dev `run_job_dynamic_env_vars.ingest`
  3. prod `run_fastapi` env_vars
  4. prod `run_jobs` env_vars merge

**D70 — Vertex AI Search placeholders documented:**

- `REPLACE_WITH_*` placeholders in dev terraform.tfvars are intentional
  safe-by-default design, guarded by validation rules in variables.tf.
- Added clarifying comments above `vertex_ai_search` and `iap_clients` blocks
  explaining they must be overridden via `local-overrides.tfvars`.

**D77 — Prod sweeper/account_list jobs added:**

- Added `sweeper` and `account_list` job definitions to prod terraform.tfvars,
  mirroring dev structure with prod-specific values (prod images, prod Cloud SQL
  instance, prod IAM users). Both set `enabled = false` pending deliberate
  activation.

**D78 — IAP oauth_client module assessed:**

- Module is an intentional no-op stub with clear documentation explaining the
  deprecated `google_iap_client` API. Referenced by
  `modules/iap/cloud_run_service/main.tf` via conditional `count`. Removing
  would require updating the parent module. Kept as-is — the stub is the
  correct remediation for the deprecated API.

### 2026-02-11 — WS-10 Dev/Prod Parity (HIGH + MED items)

Prioritized WS-10 ahead of WS-9 because HIGH-severity IAM gaps (D80–D83) were
silently blocking prod functionality. Updated sprint order accordingly.

**D80 — Cloud SQL IAM roles added to prod:**

- Added `roles/cloudsql.client` + `roles/cloudsql.instanceUser` to `app` and
  `report` SAs in prod `iam_service_account_bindings`.
- Added `roles/cloudsql.client` to `ingest` SA.

**D81 — AI Platform IAM role added to prod:**

- Added `roles/aiplatform.user` to `app` and `ingest` SAs.

**D82 — Vertex AI API enabled in prod:**

- Added `google_project_service "vertex_ai"` resource for
  `aiplatform.googleapis.com` to prod `main.tf`.

**D83 — Report SA IAM bindings aligned:**

- Added `roles/cloudsql.client`, `roles/cloudsql.instanceUser`, and
  `roles/discoveryengine.viewer` to prod report SA.

**D84 — database.tf hardcoded values extracted:**

- Created `database_config` variable (object type) in both dev and prod
  `variables.tf` with fields: `instance_name`, `tier`, `disk_size`,
  `availability_type`, `backup_enabled`, `backup_start_time`,
  `deletion_protection`.
- Updated `database.tf` in both environments to use `var.database_config.*`.
- Added `database_config` blocks to both `terraform.tfvars`.

**D85 — Vertex AI Search variable shape unified:**

- Replaced 3 scalar variables (`vertex_search_location`,
  `vertex_search_data_store_id`, `vertex_search_display_name`) in prod with
  the structured `vertex_ai_search` object matching dev.
- Updated prod `main.tf` module call and `terraform.tfvars`.

**D86 — `run_job_dynamic_env_vars` added to prod:**

- Added `run_job_dynamic_env_vars` local to prod `main.tf` with Vertex AI
  env vars for `ingest`, `sweeper`, `intake`, and `account_list`.
- Updated `run_jobs` module to merge dynamic env vars.
- Also injected `I4G_VECTOR__VERTEX_AI_*` and `I4G_VERTEX_SEARCH_*` env vars
  into prod `run_fastapi` and `run_console` from `var.vertex_ai_search`.
- Removed duplicate Vertex Search entries from prod `fastapi_env_vars` and
  `console_env_vars` in tfvars (now sourced dynamically from variable).

**D87 — Hardcoded LLM env vars moved to tfvars:**

- Moved `I4G_LLM__PROVIDER`, `I4G_LLM__CHAT_MODEL`, and
  `I4G_STORAGE__EVIDENCE__LOCAL_DIR` from hardcoded dev `main.tf` block into
  dev's `terraform.tfvars`. Added `I4G_STORAGE__EVIDENCE__LOCAL_DIR` to prod
  tfvars for consistency.
- This also revealed model version drift: dev uses `gemini-2.0-flash`, prod
  uses `gemini-2.5-flash`. Intentional for now.

**D89 — Storage role fixed:**

- Changed prod app SA from `roles/storage.objectViewer` to
  `roles/storage.objectAdmin` — the app writes evidence and reports to GCS.

**D90 — Org policy documented as dev-only:**

- Confirmed `google_project_organization_policy.allow_public_invokers` with
  `allUsers` is intentionally dev-only for testing. Prod should not have this.
  Marked as resolved (intentional divergence).

**D94 — `random` provider added to prod:**

- Added `hashicorp/random ~> 3.0` to prod `backend.tf` `required_providers`.

**D91 — outputs.tf:** Deferred — differences track the IAP architecture
divergence (D92) and networking (D93). Will align after those decisions.

**D92 — IAP architecture:** Deferred — requires architectural decision on
LB-based IAP (dev) vs per-service IAP (prod). Too large for this session.

**D93 — Networking resources:** Deferred — requires decision on whether prod
needs deterministic egress IPs for external API allow-listing.

**Remaining:** D88 (console structural alignment), D91, D92, D93.
**Validation:** Dev `terraform validate` passes. Prod validate requires
`terraform init` to download newly added `random` provider — expected.
**Tests:** No Python code changed. Infrastructure changes only.

### 2026-02-15 (session 3) — WS-10 Pre-Merge Finalization

**Date:** 2026-02-15
**Items completed:** D91 (outputs aligned), D92 (IAP decision documented)

**D91 — outputs.tf aligned:**

- Common outputs (6 blocks: `service_account_emails`, `github_workload_identity_pool`,
  `fastapi_service`, `vertex_search`, `storage_buckets`, `run_jobs`) are structurally
  identical between dev and prod.
- Env-specific outputs reflect intentional architectural divergence:
  - **Dev-only:** `serverless_egress_ip` (D93 networking), `global_lb_ip` (D92 LB-based IAP)
  - **Prod-only:** `fastapi_domain_mapping`, `ui_domain_mapping` (D92 per-service IAP),
    detailed `iap` output with per-service OAuth client metadata
- Added missing `description` attributes to prod's `fastapi_domain_mapping` and
  `ui_domain_mapping` outputs.

**D92 — IAP architecture decision documented:**

- **Current state:** Dev uses LB-based IAP (`module.global_lb` +
  `google_iap_web_backend_service_iam_binding`). Prod uses per-service IAP
  (`module.iap_fastapi` + `module.iap_console` + `module.domain_mapping_*`).
- **Decision:** Keep divergence intentional. Rationale:
  - Dev LB approach was implemented for custom domain support and path-based routing.
  - Prod per-service approach was the initial deployment pattern and is working.
  - Unifying requires provisioning a global LB in prod, migrating DNS, and updating
    IAP bindings — a substantial infrastructure change best done as its own work
    stream when custom domain is needed in prod.
- Both approaches provide IAP authentication; the divergence is in routing, not security.

**D88 — run_console structural differences:** Deferred. Console conditional
deployment and resource limits are configuration differences, not parity bugs.

**D93 — Networking resources:** Deferred. Dev networking (egress IP, NAT, VPC
connector) supports deterministic egress for external API allow-listing. Prod
will add these when external integrations require IP pinning.

**State migration & recovery:**

- Both dev and prod required `terraform state mv` commands after module
  refactoring (database + users modules). State migrations completed.
- Dev: admin group SQL user was destroyed during failed apply — will be
  recreated. Plan: 5 adds, 2 changes, 1 destroy (NAT replacement).
- Prod: database + all SQL users destroyed during failed apply (instance
  survived due to `deletion_protection = true`). Plan: 7 adds, 1 change.
- Post-apply: run Alembic migrations and re-grant in-database permissions in prod.

**WS-10 final status:** 15/15 items done. All acceptance criteria checked.

### 2026-02-15 (session 4) — D92/D93 IAP & Networking Parity

**Date:** 2026-02-15
**Items completed:** D88 (console parity), D92 (IAP unification), D93 (networking)

**D92 — IAP architecture unified:**

- Migrated prod from per-service IAP (`module.iap_fastapi`, `module.iap_console`,
  `module.domain_mapping_fastapi`, `module.domain_mapping_ui`) to LB-based IAP
  (`module.global_lb` + `google_iap_web_backend_service_iam_binding`).
- Both environments now use identical architecture: Global LB → Serverless NEG →
  Cloud Run with `internal-and-cloud-load-balancing` ingress.
- Added `iap_clients` variable to prod with sentinel/validation pattern matching dev.
- Removed unused `iap_manage_clients`, `iap_secret_replication_locations`,
  `console_enabled` variables from prod.
- Added `google_project_organization_policy.allow_public_invokers` to prod
  (needed for `allUsers` invoker with LB-based IAP).

**D93 — Networking resources added to prod:**

- Added `google_compute_address.serverless_egress`, `google_compute_router.serverless`,
  `google_compute_router_nat.serverless`, `google_vpc_access_connector.serverless`.

**D88 — Console structural parity:**

- Removed `count = var.console_enabled ? 1 : 0` from `module.run_console`.
  Console is now always deployed (matching dev).
- Added `min_instances = 1`, `resource_limits`, `I4G_IAP_CLIENT_ID` env var.
- Changed `I4G_API_URL` to use `module.run_fastapi.uri` (internal).

**Custom domains:**

- Dev retains `api.intelligenceforgood.org` / `app.intelligenceforgood.org`.
- Prod domains left empty until ready for cutover. When prod goes live,
  set prod tfvars and move dev to `*.dev.intelligenceforgood.org`.

**Outputs aligned:**

- Prod outputs now match dev: `serverless_egress_ip`, `global_lb_ip`,
  simplified `iap` (brand_name only). Removed domain mapping and per-service
  IAP outputs.

**Validation:** `terraform fmt -check` and `terraform validate` pass for both
dev and prod. Prod is not in active use; these changes are preparation for
future production deployment with custom domains.

**State implications:** Next `terraform apply` in prod will destroy per-service
IAP resources and domain mappings, and create networking + LB resources.
Acceptable since prod is not in use.

### Session: 2026-02-11 — WS-9: CI/CD & Infrastructure Automation

**D66 — AccountJobSettings added:**

- Created `AccountJobSettings(BaseSettings)` with 8 fields: `output_formats`,
  `start_time`, `end_time`, `window_days`, `categories`, `top_k`,
  `include_sources`, `dry_run`. Mounted on `Settings.account_job`.
- Refactored `worker/jobs/account_list.py` to read all config from
  `settings.account_job` instead of raw `os.getenv()` / `env_bool()` /
  `env_int()` / `env_list()` calls.
- Updated unit tests in `test_worker_account_list_job.py` to use
  `SimpleNamespace` mock with `account_job` attribute.

**D67 — IntakeJobSettings + RuntimeSettings.fallback_dir:**

- Created `IntakeJobSettings(BaseSettings)` with 4 fields: `id`, `job_id`,
  `api_base`, `api_key`. Mounted on `Settings.intake`.
- Added `fallback_dir: Path` to `RuntimeSettings` (default `/tmp/i4g/evidence`).
- Refactored `worker/jobs/intake.py` to read from `settings.intake` instead of
  `os.getenv()`. Refactored `storage/evidence.py` to use
  `settings.runtime.fallback_dir`.
- Updated unit tests in `test_worker_intake_job.py`.
- Added 6 new tests in `test_settings_env_overrides.py` covering defaults and
  env overrides for all three new sections.
- Regenerated `settings_manifest.yaml` (116 fields, 12 new).

**D71 — UI CI workflow:**

- Created `ui/VERSION.txt` (0.1.0) for version-gated Docker builds.
- Created `ui/.github/workflows/ui-ci.yml` with two jobs:
  - `lint-test`: Runs on PR. pnpm install → lint → tsc --noEmit → vitest.
  - `build-push`: Runs on push to main when `VERSION.txt` changes. Builds
    `i4g-console` Docker image and pushes to both dev and prod AR registries.
- Uses `pnpm/action-setup@v4` + `actions/setup-node@v4` with caching.
- Docker build uses `docker/build-push-action@v6` with GHA cache.

**D72 — Prod Terraform workflow:**

- Created `infra/.github/workflows/terraform-prod.yml` mirroring the dev
  workflow structure but targeting `environments/app/prod` and
  `environments/pii-vault/prod`.
- Triggers on PR (plan only) and push to main (plan + apply).
- Apply job uses `environment: production` for GitHub environment protection
  (approval gate). This must be configured in GitHub repo settings.
- Uses separate `TF_GCP_PROD_*` repository variables for WIF provider,
  service account, and project IDs.

**D73 — Docker build workflow:**

- Created `core/.github/workflows/docker-build.yml` triggered by `VERSION.txt`
  changes on main.
- Matrix strategy builds all 6 images (`fastapi`, `account-job`, `dossier-job`,
  `ingest-job`, `intake-job`, `report-job`) in parallel.
- Reads version from `VERSION.txt`, tags images with both version and `latest`.
- Pushes to both dev and prod Artifact Registry.
- Uses GHA cache per-image for fast incremental builds.

**Test results:** 330 passed, 3 xfailed, 0 failures.
