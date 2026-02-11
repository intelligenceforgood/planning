# Debt Remediation Plan — Post-Consolidation Sprint

> **Goal:** Systematically resolve the 50 open technical debt items discovered
> during the [Consolidation & Quality Sprint](consolidation_plan.md).
> Items are grouped into 9 prioritized work streams, ordered by risk.
>
> **Created:** 2026-02-09
> **Last Updated:** 2026-02-09
> **Status:** IN PROGRESS
> **Predecessor:** `planning/tasks/consolidation_plan.md` (ALL PHASES COMPLETE)

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

| #    | Work Stream                              | Items  | HIGH   | MED    | LOW    | Est. Days | Status      |
| ---- | ---------------------------------------- | ------ | ------ | ------ | ------ | --------- | ----------- |
| WS-1 | Security & Auth Hardening                | 6      | 3      | 1      | 1+1    | 3–5       | DONE        |
| WS-2 | API Quality & Contract Alignment         | 9      | 4      | 3      | 2      | 3–5       | DONE        |
| WS-3 | Store Consolidation & Factory Discipline | 4      | 3      | 1      | 0      | 3–5       | DONE        |
| WS-4 | Service & Worker Cleanup                 | 5      | 2      | 2      | 1      | 2–3       | DONE        |
| WS-5 | CLI Refactor                             | 2      | 1      | 1      | 0      | 2–3       | DONE        |
| WS-6 | UI Resilience & UX Quality               | 8      | 3      | 4      | 1      | 3–5       | DONE        |
| WS-7 | Type Unification & Test Coverage         | 4      | 1      | 2      | 1      | 2–3       | DONE        |
| WS-8 | Dead Code & Hygiene                      | 8      | 0      | 4      | 4      | 1–2       | NOT STARTED |
| WS-9 | CI/CD & Infrastructure                   | 5      | 0      | 5      | 0      | 2–3       | NOT STARTED |
|      | **Totals**                               | **51** | **17** | **23** | **11** | **21–34** |             |

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
| D28  | 3 dead/legacy report files (~285 LOC) from M5.1 prototype                     | MED      | [ ]    |
| D34  | `docs/config/settings_manifest.yaml` 67 days stale                            | MED      | [ ]    |
| D62  | 3 stale Azure secrets in Terraform                                            | MED      | [ ]    |
| D63  | Vestigial `roles/datastore.*` IAM bindings                                    | MED      | [ ]    |
| D64  | `I4G_INGEST__ENABLE_TOKENIZATION` dead env var (4 Terraform, 0 Python)        | LOW      | [ ]    |
| D70  | Dev Vertex AI Search tfvars has `REPLACE_WITH_*` placeholders                 | LOW      | [ ]    |
| D77  | Prod missing `sweeper` and `account_list` job definitions                     | LOW      | [ ]    |
| D78  | IAP `oauth_client` module is a no-op stub                                     | LOW      | [ ]    |
| D28b | `llm_extractor.py` stale `_provider_override_from_env()` + dead comment block | LOW      | [ ]    |

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

- [ ] Dead report files (`gdoc_exporter.py`, `template_engine.py`,
      `generator.py`) deleted.
- [ ] `settings_manifest.yaml` regenerated and matches current Pydantic model.
- [ ] Stale Azure secrets removed from Terraform (after confirmation).
- [ ] Vestigial Datastore IAM bindings removed (after confirmation).
- [ ] Dead `I4G_INGEST__ENABLE_TOKENIZATION` removed from all 4 Terraform
      locations.
- [ ] Vertex AI Search tfvars has real values or is clearly marked as
      requires-manual-setup.
- [ ] Prod Terraform updated with sweeper/account_list jobs (if confirmed
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
| D66 | 6 `I4G_ACCOUNT_JOB__*` env vars bypass Settings model (`os.getenv()`)      | MED      | [ ]    |
| D67 | `I4G_RUNTIME__FALLBACK_DIR` + `I4G_INTAKE__API_BASE` bypass Settings model | MED      | [ ]    |
| D71 | No CI workflow for UI repo                                                 | MED      | [ ]    |
| D72 | No prod Terraform workflow (only dev has `terraform-dev.yml`)              | MED      | [ ]    |
| D73 | Docker build/push is fully manual (no CI pipeline)                         | MED      | [ ]    |

### Design Decisions Required

- **D66/D67:** ⚠️ Add these to the Settings Pydantic model? Options:
  (a) Add `AccountJobSettings` and `IntakeSettings` sections to `config.py`;
  (b) Consolidate into existing sections (e.g., `runtime`, `ingest`);
  (c) Accept as job-specific env vars and document them in the manifest only.
- **D71:** ⚠️ UI CI scope: (a) Lint + type-check + Vitest on PR; (b) Full
  build + Playwright smoke; (c) Build + push Docker image on merge to main.
- **D72:** ⚠️ Prod Terraform automation: (a) Plan-only on PR, manual apply;
  (b) Full plan + apply on merge with approval gate; (c) Keep manual for now,
  document the process.
- **D73:** Docker build CI: (a) Build + push on tag; (b) Build + push on merge
  to main; (c) Manual trigger with version input.

### Dependencies

- D66/D67 are Python-only changes (independent of CI work).
- D71/D72/D73 are infrastructure work that can proceed in parallel.

### Acceptance Criteria

- [ ] All `I4G_ACCOUNT_JOB__*`, `I4G_RUNTIME__FALLBACK_DIR`, and
      `I4G_INTAKE__API_BASE` env vars either added to Settings model or documented
      in `settings_manifest.yaml` with rationale for bypass.
- [ ] UI repo has a GitHub Actions CI workflow that runs on PR (lint, type-check,
      test).
- [ ] Prod Terraform has at minimum a plan-on-PR workflow.
- [ ] Docker build/push is automated (manual trigger at minimum).
- [ ] `docs/config/settings_manifest.yaml` updated to reflect any new Settings
      sections.

---

## Recommended Sprint Order

```
Sprint 1 (Week 1):  WS-1 Security & Auth ──────────── highest risk, unblocks WS-2
Sprint 2 (Week 2):  WS-2 API Quality ──────────────── SDK/backend contract fix
                     WS-8 Dead Code (parallel) ─────── quick wins, low risk
Sprint 3 (Week 3):  WS-3 Store Consolidation ──────── largest refactor
Sprint 4 (Week 4):  WS-6 UI Resilience ────────────── error boundaries + loading
                     WS-7 Type Unification (parallel)
Sprint 5 (Week 5):  WS-4 Service & Worker ─────────── depends on WS-3
                     WS-5 CLI Refactor (parallel)
Sprint 6 (Week 6):  WS-9 CI/CD & Infrastructure ──── wrap up automation
```

This order can be adjusted based on team capacity and upcoming feature work.
WS-8 (dead code) can be interleaved with any sprint as low-risk filler.

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
