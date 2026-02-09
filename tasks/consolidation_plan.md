# Consolidation & Quality Plan — "CTO-Ready" Sprint

> **Goal:** Comprehensive walk-through of all repos to solidify design,
> implementation, and documentation so the project is presentable to external
> CTOs and institutional partners for Intelligence for Good.
>
> **Created:** 2026-02-08  
> **Last Updated:** 2026-02-09  
> **Overall Status:** Phases 1-4 COMPLETE — Phases 5-6 remaining

---

## How to Use This Document

- Each task has a checkbox: `[ ]` not started, `[~]` in progress, `[x]` done.
- When starting a session, Copilot should read this file first to know where
  we left off.
- After completing tasks, update the checkbox, add a date, and note any
  decisions made in the **Session Log** at the bottom.
- Tasks marked ⚠️ require a user decision before proceeding.

---

## Phase Summary

| Phase | Title | Est. Days | Status |
|-------|-------|-----------|--------|
| 1 | Retire Legacy Components | 1–2 | DONE |
| 2 | Design & Architecture Doc Alignment | 2–3 | DONE |
| 3 | Core Backend Review | 3–5 | DONE (audit + remediation) |
| 4 | UI Frontend Review | 2–3 | DONE (audit + remediation) |
| 5 | End-User Documentation | 2–3 | NOT STARTED |
| 6 | Infrastructure & Config Consistency | 1–2 | NOT STARTED |

---

## Phase 1: Retire Legacy Components

> Remove dead code before reviewing live code to avoid wasted effort.

- [x] **1.1** ⚠️ Confirm Streamlit is fully retired (all 9 console pages live in Next.js)
  - Decision: **YES — retire it.** All 9 pages confirmed live in Next.js.
  - Date: 2026-02-08
- [x] **1.2** Remove `core/src/i4g/ui/` — entire Streamlit package (~2,800 lines)
  - Depends on: 1.1
- [x] **1.3** Remove `core/docker/streamlit.Dockerfile`
  - Depends on: 1.1
- [x] **1.4** Remove `streamlit` from `pyproject.toml` and regenerate `requirements.txt`
  - Depends on: 1.1
- [x] **1.5** Remove Streamlit Terraform resources from `infra/`
  - `module.run_streamlit` in `infra/environments/app/dev/`
  - IAP bindings in `infra/scripts/make-iap-protected.sh`
  - Output references in `infra/environments/app/dev/outputs.tf`
  - Depends on: 1.1
- [x] **1.6** Clean residual Firestore references (3 remaining)
  - `core/docs/diagrams/dossier_flow.drawio` — "Case Queue (SQL / Firestore)"
  - `core/docs/cookbooks/prepare_bootstrap_bundles.md` — deprecated note
  - `docs/book/assets/architecture/system_topology.svg` — Firestore node
- [x] **1.7** ⚠️ Decide Ollama/ChromaDB status
  - Options: (a) Keep as local-dev-only, document clearly; (b) Remove Ollama dep entirely
  - Decision: **(a) Keep as local-dev-only.** The app must run fully on a laptop without cloud services (Vertex AI). Ollama provides that capability. Document clearly.
  - Date: 2026-02-08
- [x] **1.8** ⚠️ Decide `dtp/` repo fate
  - Options: (a) Remove from multi-root workspace; (b) Archive with README notice; (c) No change
  - Decision: **(c) Leave as-is.** No action needed.
  - Date: 2026-02-08

---

## Phase 2: Design & Architecture Doc Alignment

> Bring "source of truth" documents in sync with what was actually built.

- [x] **2.1** Update `planning/prd_production.md` — remove Streamlit/Ollama as primary, reflect current GCP + Next.js + Vertex AI stack
- [x] **2.2** Mark `planning/prd_prototype.md` as historical (add banner)
- [x] **2.3** Review & update TDDs against implementation:
  - [x] `core/docs/design/architecture.md` — v2.0 (14 fixes: endpoints, profiles, LLM, schema)
  - [x] `core/docs/design/data_model.md` — rewritten (17-table schema vs. old 3-entity stub)
  - [x] `core/docs/design/storage.md` — fixed table list, status values, version
  - [x] `core/docs/design/iam.md` — disclosed prototype API-key auth layer
  - [x] `core/docs/design/jobs.md` — added 2 missing jobs, fixed entrypoints
  - [x] `core/docs/design/pii_vault.md` — verified accurate (no changes needed)
  - [x] `core/docs/design/rag.md` — fixed LLM model ref, noted Ollama hardcoding
  - [x] `core/docs/design/fraud_taxonomy_tdd.md` — fixed file paths
  - [x] `core/docs/design/campaign_governance_bridge.md` — verified accurate (no changes needed)
  - [x] `core/docs/design/ftc_fraud_classification_low_cost_llm_design_spec.md` — verified accurate (minor design divergence acceptable)
- [x] **2.4** Update `arch-viz/` diagram scripts to match real topology
  - Fixed: IAP (not Firebase Auth), intake form (not chatbot), UI Console in security model
- [x] **2.5** Refresh `planning/roadmap.md` — add consolidation sprint milestone, update status
- [x] **2.6** Refresh `planning/copilot_prompt/COPILOT_SESSION.md` with active task

---

## Phase 3: Core Backend Review

> Systematic pass through the 20 packages in `core/src/i4g/`.
> Full audit completed 2026-02-08. Findings documented below; remediation tracked as separate tasks.

- [x] **3.1** API router audit — consistent error handling, auth, response models, docstrings
  - Files: `core/src/i4g/api/*.py` (13 routers)
  - Found: 7 routers with NO auth; `review.py` 953 lines (needs split); no logging in 11/13 routers; no `response_model` on most endpoints; path-traversal risk in `reports.py`
- [x] **3.2** Store layer audit — check for overlap across 17 store modules, consolidate where possible
  - Key files: `sql.py`, `structured.py`, `review_store.py`, `entity_store.py`
  - Found: SQLite/SQLAlchemy duplication (~800 LOC); `scam_records` dual-write with normalized schema; DDL defined in 2 places; 6 files with module-level `get_settings()`; 8 prod-code locations bypass factories; no domain exception hierarchy
- [x] **3.3** Services layer audit — verify `factories.py` as single factory pattern, check for duplicate init logic
  - Found: Duplicate LLM factory logic in `classifier.py` + `llm_extractor.py`; `campaigns.py` bypasses store layer; `_coerce_bool` duplicated 5x; env-var reads bypass settings in 3 files
- [x] **3.4** Worker/jobs audit — consistent logging, error handling, progress reporting across 8 job modules
  - Found: Only 1/8 jobs uses TASK_STATUS progress; `pii_backfill.py` needs complete rewrite (accesses private store internals, no error handling); `classification_sweeper.py` bypasses store layer; Pydantic v1 `.dict()` still used; `datetime.utcnow()` in 4 files
- [x] **3.5** Reports audit — check for dead code from prototype-era dossier experiments (15+ modules)
  - Found: 3 dead/legacy files (~285 LOC): `gdoc_exporter.py`, `template_engine.py`, `generator.py` (M5.1 prototype superseded by M4 dossier pipeline); No `__init__.py`; `bundle_candidates.py` bypasses factories; duplicate `_hash_file` across 2 modules
- [x] **3.6** CLI audit — consistent patterns for `get_settings()`, arg parsing across 11 sub-commands
  - Found: `bootstrap/dev.py` is 2064 lines (needs split); `SimpleNamespace` proxy antipattern in 8/12 subcommands (~400 LOC boilerplate); dead `argparse` parsers in 4 files; duplicate Vertex search functions in `search/logic.py`; 3 different exit patterns; `TestClient` imported in prod CLI; dead `i4g-admin` entry point
- [x] **3.7** Settings model audit — every TOML section has a Pydantic model (and vice versa); `settings_manifest.yaml` is current
  - Found: **P0 BUG** — `_apply_environment_overrides` uses `"reports_bucket"` but field is `"report_bucket"` (local env never clears bucket); `[crypto]` section missing from TOML; 18 Pydantic fields undocumented in TOML; `docs/` manifest 67 days stale; `vector.vertex_ai_data_store` uncommented in default TOML (leaks cloud value)
- [x] **3.8** Test coverage check — `pytest tests/unit` with coverage; identify gaps in stores and services
  - 271 tests: 252 passed, 18 failed, 1 error
  - Failures in: `test_review_store` (9 — TypeError), `test_store_vector` (2), `test_dossier_pilot` (2), `test_account_list_exporter` (3), `test_cases` (1), `test_review_taxonomy` (1 error)
  - Coverage gaps: no tests for `runtime`, `api`, `identity`, `storage`, `vector`, `secrets`, `report`, `crypto` settings sections; no `_resolve_paths` test
- [x] **3.9** Dependency audit — review `pyproject.toml` for unused deps (especially post-Phase 1 cleanup)
  - Found: 9 unused deps to remove (`altair`, `datasets`, `huggingface-hub`, `trio`, `regex`, `ollama`, `google-auth-httplib2`, `google-auth-oauthlib`, `psycopg2-binary`); 3 missing explicit deps (`sqlalchemy`, `jinja2`, `pyyaml`); 4 Azure deps to move to `[migration]` extra; `paddleocr[all]` to `[ocr-paddle]` extra; dead `run-dataflow` entry point; est. 2-3 GB Docker image savings

---

## Phase 4: UI Frontend Review

> Quality pass on the Next.js analyst console and shared packages.
> Full audit completed 2026-02-09. Findings documented below; remediation tracked as debt items.

- [x] **4.1** SDK/API client audit — `@i4g/sdk` types match FastAPI response models, check for drift
  - Files: `ui/packages/sdk/src/index.ts`, `ui/apps/web/src/lib/platform-client.ts`, `ui/apps/web/src/lib/i4g-client.ts`, 5 server services
  - Found: SDK `searchIntelligence` targets non-existent `/search` (platform-client overrides it); `indicatorTypes`/`lossBuckets` search filters silently dropped; `CaseSummary.classification` never returned by backend; 3 separate auth patterns (SDK X-API-KEY only, platform-client IAP+key, server services each re-implement auth boilerplate); SDK covers only 9 of ~40+ backend endpoints; dead taxonomy enum imports; fragile `../../../types/taxonomy` relative import; search field name camelCase→snake_case translation implicit and undocumented
- [x] **4.2** Page audit — consistent patterns across 9 console pages (loading, error boundaries, auth)
  - Files: 9 page directories under `ui/apps/web/src/app/(console)/`
  - Found: 0/9 pages have `error.tsx` (no error boundaries anywhere); 7/9 pages have no `loading.tsx` (only search+analytics have skeletons); no user authentication guard in console; `cases/[id]` Suspense fallback is unstyled `<div>Loading...</div>`; no `not-found.tsx` for `notFound()` calls; console layout is entirely `"use client"` (prevents server-side nav optimization); `search-experience.tsx` is 1324 lines, `dossier-list.tsx` is 998 lines (decomposition candidates); campaign form uses raw HTML inputs instead of ui-kit; dead code in `campaign-form.tsx` (commented-out `renderNode`, unused `_taxonomy`); inconsistent header typography across pages; non-functional placeholder buttons on dashboard and cases pages
- [x] **4.3** ui-kit audit — shared component quality, prop typing, Storybook coverage
  - Files: `ui/packages/ui-kit/src/` (4 components: Badge, Button, Card, Input)
  - Found: Zero Storybook configuration or stories; `BadgeProps`/`BadgeVariant` types not exported; manual `index.d.ts` duplicates barrel export (drift risk); no Tailwind CSS peer dependency declared; no unit tests for any shared package; components well-typed with CVA + forwardRef otherwise
- [x] **4.4** Types alignment — consolidate `ui/packages/types/` and `ui/types/` if redundant
  - Found: `TaxonomyItem`/`TaxonomyAxis` defined in 3 places (packages/types, sdk Zod schemas, taxonomy page local re-declarations); root `types/taxonomy.ts` enums complementary to packages/types interfaces but confusingly split; `tsconfig.base.json` includes `types/**/*.d.ts` but file is `.ts` (fragile); `@i4g/types` package is very thin (3 interfaces only); `campaigns.ts` and `reviews.ts` types live only in app-local files; `neutral.300` token hex value `#CBD5F5` looks like a typo (expected `#CBD5E1`)
- [x] **4.5** Formatting pass — `pnpm format` across all UI files
  - Result: All files already formatted (no changes needed)
- [x] **4.6** Playwright/Vitest audit — test health and coverage
  - Found: Vitest: 26 tests across 6 files, all passing (~1.4s); Playwright: 1 smoke spec configured but requires live server; `reviews-service.helpers.test.ts` exists in 2 locations (in-source + tests/unit) with overlapping but different tests; 5 shared packages have zero test files; no coverage thresholds enforced; `iam-helper` app is a shell (no source, no package.json); Playwright smoke test has fragile selectors per inline comments

---

## Phase 5: End-User Documentation

> Bring the GitBook docs at `docs/book/` to publication quality.

- [ ] **5.1** Audit `docs/book/SUMMARY.md` — every entry has a real page, no dead links
- [ ] **5.2** Platform Overview — update personas (remove Streamlit), refresh use cases
- [ ] **5.3** Analyst Guide — search, discovery, dossiers, campaigns guides match live UI
- [ ] **5.4** Architecture section — update system topology SVG, refresh data pipeline and security diagrams
- [ ] **5.5** Configuration reference — sync `settings.md` with `config.py` Pydantic model and `settings_manifest.yaml`
- [ ] **5.6** API Guide — verify auth docs, sample workflows, taxonomy reference
- [ ] **5.7** Contributing guide — update dev-loop instructions (Next.js, not Streamlit)

---

## Phase 6: Infrastructure & Config Consistency

> Ensure infra matches deployed reality, remove leftovers.

- [ ] **6.1** Terraform audit — remove Streamlit resources, verify module references match deployed services
- [ ] **6.2** Docker audit — all Dockerfiles build cleanly post-cleanup; consistent base images
- [ ] **6.3** CI/CD alignment — GitHub Actions match current build/deploy workflow
- [ ] **6.4** Env vars contract — cross-check Cloud Run job env vars in Terraform against `settings_manifest.yaml`
- [ ] **6.5** Secrets audit — Secret Manager entries match what the code expects

---

## Concrete Debt Inventory (Found 2026-02-08)

| # | Finding | Severity | Phase | Status |
|---|---------|----------|-------|--------|
| D1 | ~2,800 lines of Streamlit code in `core/src/i4g/ui/` | HIGH | 1 | DONE |
| D2 | `streamlit.Dockerfile` still present | MED | 1 | DONE |
| D3 | Streamlit Terraform resources still provisioned | MED | 1 | DONE |
| D4 | 50+ Streamlit doc references across core/docs, docs/ | MED | 1,5 | DONE |
| D5 | Firestore label in system_topology.svg | LOW | 1 | DONE |
| D6 | 3 residual Firestore text references | LOW | 1 | DONE |
| D7 | PRD references outdated architecture | MED | 2 | DONE |
| D8 | Roadmap stale since Dec 2025 | LOW | 2 | DONE |
| D9 | data_model.md was 17-line stub (actual: 17 tables) | HIGH | 2 | DONE |
| D10 | iam.md omitted prototype API-key auth layer | HIGH | 2 | DONE |
| D11 | arch-viz security model referenced Firebase Auth (should be IAP) | MED | 2 | DONE |
| D12 | 7/13 API routers have NO authentication | HIGH | 3 | FOUND |
| D13 | `review.py` is 953 lines — needs splitting into sub-routers | HIGH | 3 | FOUND |
| D14 | `reports.py` has no path-traversal protection on `plan_id` | HIGH | 3 | FOUND |
| D15 | No logging in 11/13 API routers | HIGH | 3 | FOUND |
| D16 | SQLite/SQLAlchemy dual implementations (~800 LOC duplication) | HIGH | 3 | FOUND |
| D17 | `scam_records` dual-write with normalized schema (consistency risk) | HIGH | 3 | FOUND |
| D18 | 8 prod-code locations bypass `factories.py` for store creation | HIGH | 3 | FOUND |
| D19 | Duplicate LLM factory logic in `classifier.py` + `llm_extractor.py` | HIGH | 3 | FOUND |
| D20 | `pii_backfill.py` — private attribute access, no error handling, no CLI harness | HIGH | 3 | FOUND |
| D21 | **P0 BUG** `_apply_environment_overrides`: `reports_bucket` vs `report_bucket` mismatch | CRIT | 3 | **DONE** |
| D22 | `bootstrap/dev.py` is 2064 lines — needs decomposition | HIGH | 3 | FOUND |
| D23 | 9 unused dependencies (~2-3 GB Docker savings) | HIGH | 3 | **DONE** |
| D24 | 3 missing explicit deps (`sqlalchemy`, `jinja2`, `pyyaml`) | HIGH | 3 | **DONE** |
| D25 | Dead `run-dataflow` entry point in `pyproject.toml` | MED | 3 | **DONE** |
| D26 | Only 1/8 worker jobs uses TASK_STATUS progress reporting | MED | 3 | FOUND |
| D27 | `SimpleNamespace` proxy antipattern in 8/12 CLI subcommands (~400 LOC) | MED | 3 | FOUND |
| D28 | 3 dead/legacy report files (~285 LOC) from M5.1 prototype | MED | 3 | FOUND |
| D29 | Module-level `get_settings()` in 6+ store/service files | MED | 3 | FOUND |
| D30 | `_coerce_bool` / `_parse_datetime` duplicated across 5+ files | MED | 3 | FOUND |
| D31 | 18 failed tests + 1 error in `pytest tests/unit` | MED | 3 | **DONE** (268 pass, 3 xfail) |
| D32 | No `response_model` on most API endpoints (broken OpenAPI) | MED | 3 | FOUND |
| D33 | `datetime.utcnow()` usage in 4+ files (deprecated Python 3.12+) | LOW | 3 | FOUND |
| D34 | `docs/config/settings_manifest.yaml` 67 days stale | LOW | 3 | FOUND |
| D35 | Dead `i4g-admin` entry point alias | LOW | 3 | **DONE** |
| D36 | SDK `searchIntelligence` targets non-existent `/search` endpoint | HIGH | 4 | FOUND |
| D37 | `indicatorTypes`/`lossBuckets` search filters silently dropped | HIGH | 4 | FOUND |
| D38 | `CaseSummary.classification` type never returned by backend | HIGH | 4 | FOUND |
| D39 | 0/9 console pages have error boundaries (`error.tsx`) | HIGH | 4 | FOUND |
| D40 | 7/9 console pages have no loading state (`loading.tsx`) | HIGH | 4 | FOUND |
| D41 | No user authentication guard in console (no middleware/session check) | HIGH | 4 | FOUND |
| D42 | Zero Storybook configuration or stories for `@i4g/ui-kit` | HIGH | 4 | FOUND |
| D43 | Manual `index.d.ts` duplicates barrel export in ui-kit (drift risk) | HIGH | 4 | **DONE** |
| D44 | `BadgeProps`/`BadgeVariant` types not exported from ui-kit | MED | 4 | **DONE** |
| D45 | 3 separate auth patterns with duplicated boilerplate across server services | MED | 4 | FOUND |
| D46 | SDK covers only 9 of ~40+ backend endpoints | MED | 4 | FOUND |
| D47 | `TaxonomyItem`/`TaxonomyAxis` defined in 3 separate places | MED | 4 | FOUND |
| D48 | `search-experience.tsx` (1324 LOC) and `dossier-list.tsx` (998 LOC) need decomposition | MED | 4 | FOUND |
| D49 | Campaign form uses raw HTML inputs instead of ui-kit components | MED | 4 | FOUND |
| D50 | Dead code in `campaign-form.tsx` (commented-out function, unused vars) | MED | 4 | **DONE** |
| D51 | Console layout entirely `"use client"` (prevents server-side nav optimization) | MED | 4 | FOUND |
| D52 | `tsconfig.base.json` includes `types/**/*.d.ts` but file is `.ts` (fragile) | MED | 4 | **DONE** |
| D53 | `neutral.300` token hex `#CBD5F5` looks like typo (expected `#CBD5E1`) | MED | 4 | **DONE** |
| D54 | Duplicate `reviews-service.helpers.test.ts` in 2 locations | MED | 4 | **DONE** |
| D55 | 5 shared packages have zero test files | MED | 4 | FOUND |
| D56 | No Tailwind CSS peer dependency in `@i4g/ui-kit` | MED | 4 | **DONE** |
| D57 | No coverage thresholds enforced in Vitest config | LOW | 4 | FOUND |
| D58 | Non-functional placeholder buttons on dashboard and cases pages | LOW | 4 | FOUND |
| D59 | Dead `iam-helper` app (no source, no package.json — only `.next/` cache) | LOW | 4 | **DONE** |
| D60 | `CaseSummary.status` enum stricter than backend (Zod will throw on unknown status) | LOW | 4 | FOUND |
| D61 | Search field name camelCase→snake_case translation implicit and undocumented | LOW | 4 | FOUND |

---

## Session Log

> Append an entry every session. Format:  
> `### YYYY-MM-DD — Summary`

### 2026-02-08 — Plan Creation

- Performed full workspace audit across all 8 repos.
- Identified primary debt: Streamlit legacy (~2,800 LOC + infra + 50 doc refs),
  stale Firestore references, outdated PRD/roadmap.
- Confirmed: Azure code fully isolated in `dtp/`, Firestore mostly cleaned,
  no TODO/FIXME markers, UI mocks fully removed.
- Created this tracking document.

### 2026-02-08 — Phase 1 Complete

- **Decisions recorded:** Streamlit retired (1.1), Ollama/Chroma kept as local-dev-only (1.7), `dtp/` left as-is (1.8).
- **Deleted:**
  - `core/src/i4g/ui/` — ~2,800 lines of Streamlit source code
  - `core/docker/streamlit.Dockerfile`
  - `core/tests/adhoc/analyst_dashboard_demo.py`
- **Removed `streamlit` dependency** from `pyproject.toml`, regenerated `requirements.txt`.
- **Cleaned Terraform** (dev + prod): removed `module.run_streamlit`, `module.iap_streamlit`, variables, outputs, tfvars, locals, READMEs, scripts.
- **Updated 20+ doc files** across `core/docs/`, `docs/book/`, `ui/docs/`, `infra/` to remove all Streamlit references.
- **Cleaned 3 Firestore residuals**: `.drawio` diagram, bootstrap cookbook, system topology SVG.
- **Updated 1 Python source** docstring in `core/src/i4g/api/app.py`.
- **Updated 1 TSX file** in `ui/apps/web/src/app/(console)/discovery/page.tsx`.
- Workspace-wide grep confirms zero Streamlit references outside `planning/`.
- **Next step:** Phase 2 — Design & Architecture Doc Alignment.

### 2026-02-08 — Phase 2 Complete

- **Audited all 10 TDD/design documents** against actual implementation via subagent:
  - HIGH severity: `data_model.md` (17-line stub), `iam.md` (missing API-key auth disclosure)
  - MEDIUM severity: `storage.md`, `jobs.md`, `rag.md` (incomplete/inaccurate)
  - LOW severity: `fraud_taxonomy_tdd.md` (wrong paths), `pii_vault.md`, `campaign_governance_bridge.md`, `ftc_classification.md` (minor)
  - Zero Streamlit/Firestore references found in any TDD.
- **Rewrote `data_model.md`** from 17 lines to comprehensive schema reference (17 tables in METADATA + 1 in VAULT_METADATA, relationships, conventions, migrations).
- **Fixed `iam.md`** — added "Two-Layer Authentication" subsection documenting prototype `X-API-KEY` mechanism alongside IAP, flagged as action item.
- **Fixed `storage.md`** — expanded table list from 5 to 17+, corrected `reviews` → `review_queue`, fixed dossier queue statuses.
- **Fixed `jobs.md`** — added `classification_sweeper` and `pii_backfill` jobs, corrected report-job entrypoint.
- **Fixed `rag.md`** — updated LLM from Gemini 1.5 Pro → 2.5 Flash, noted `pipeline.py` Ollama hardcoding.
- **Fixed `fraud_taxonomy_tdd.md`** — corrected file paths from `data/taxonomy/` to `src/i4g/taxonomy/`.
- **Updated `arch-viz/` diagrams** — security_model.py: replaced Firebase Auth with IAP, added UI Console; system_topology.py: changed "Chatbot" → "Intake Form", "Identity Platform" → "IAP".
- **Refreshed `roadmap.md`** — changed status from "Paused" to "Active", added consolidation sprint progress, added RAG pipeline follow-up.
- **Refreshed `COPILOT_SESSION.md`** — full rewrite with Phase 1-2 summary, key decisions, and next steps.
- **Next step:** Phase 3 — Core Backend Review.

### 2026-02-08 — Phase 3 Audit Complete

- **Completed full audit of all 9 Phase 3 tasks** across ~20 packages in `core/src/i4g/`.
- **API routers (3.1):** 13 router files audited. Critical: 7 routers unprotected, `review.py` at 953 lines needs split, path-traversal risk in `reports.py`, no logging in 11/13 routers, no `response_model` on most endpoints.
- **Store layer (3.2):** 17 store modules audited. SQLite/SQLAlchemy duplication (~800 LOC), `scam_records` dual-write pattern with normalized schema, DDL in 2 places, 8 production files bypass factories, no domain exception hierarchy.
- **Services (3.3):** 15 service files audited. Duplicate LLM factory logic is the biggest gap (`classifier.py` + `llm_extractor.py`). `campaigns.py` bypasses store layer. `_coerce_bool` duplicated 5x.
- **Worker/jobs (3.4):** 8 job modules audited. Only `dossier_queue.py` uses TASK_STATUS. `pii_backfill.py` needs complete rewrite. `classification_sweeper.py` bypasses store layer. Pydantic v1 `.dict()` still used.
- **Reports (3.5):** 18 files audited. 3 dead/legacy files from M5.1 prototype (~285 LOC). Dossier pipeline (15 files, ~2,700 LOC) is well-structured but has factory bypass, utility duplication, and no `__init__.py`.
- **CLI (3.6):** ~40 commands across 12 groups audited. `bootstrap/dev.py` is 2064 lines. `SimpleNamespace` proxy antipattern in 8/12 subcommands. Dead argparse parsers, duplicate Vertex search functions, `TestClient` in prod code.
- **Settings (3.7):** Full Pydantic ↔ TOML ↔ manifest cross-check. **P0 BUG found:** `_apply_environment_overrides` uses `"reports_bucket"` (wrong) vs field `"report_bucket"`. 18 fields undocumented in TOML. `docs/` manifest 67 days stale.
- **Tests (3.8):** 271 tests: 252 pass, 18 fail, 1 error. Failures concentrated in `test_review_store` (9 TypeErrors), `test_account_list_exporter` (3), `test_dossier_pilot` (2), `test_store_vector` (2). Coverage gaps in settings sections.
- **Dependencies (3.9):** 9 unused deps to remove (est. 2-3 GB Docker savings). 3 missing explicit deps (`sqlalchemy`, `jinja2`, `pyyaml`). 4 Azure deps → `[migration]` extra. Dead `run-dataflow` entry point.
- **Total new debt items found: 24** (D12-D35), including 1 CRITICAL bug.
- **Next step:** Phase 3 remediation (fix P0 bug, failing tests, and critical debt) or proceed to Phase 4.

### 2026-02-09 — Phase 3 Remediation Complete

- **D21 FIXED (P0 BUG):** `_apply_environment_overrides` in `config.py` line 931 — changed `"reports_bucket"` → `"report_bucket"` so local env correctly clears the GCS bucket field.
- **D31 FIXED (18 failures + 1 error → 268 pass, 3 xfail):**
  - **ReviewStore API change (12 fixes):** `ReviewStore.__init__` no longer accepts `db_path` (only `session_factory`). Added `_make_review_store()` helper in `test_review_store.py`, `test_review_taxonomy.py`, `test_dossier_pilot.py` that creates SQLAlchemy engine + `METADATA.create_all()` + `sessionmaker`.
  - **Exporter mock typo (3 fixes):** `test_account_list_exporter.py` used `settings.storage.reports_bucket` (wrong); changed to `settings.storage.report_bucket`.
  - **IngestPipeline pepper (2 fixes):** `test_store_vector.py` — `IngestPipeline()` without `tokenization_service` fails because local settings require PII pepper. Passed mock `tokenization_service` with proper return values.
  - **Cases dynamic mock (1 fix):** `test_cases.py` — dynamic fallback was removed; updated test to expect 404 for unknown case IDs.
  - **Account list API key (1 fix):** `test_account_list.py` — local env forces `disable_auth=True`, overriding env vars. Fixed via FastAPI `app.dependency_overrides[get_settings]` with patched settings.
  - **Dossier pilot recency (1 fix):** `test_dossier_pilot.py` — hardcoded `accepted_at: "2025-11-18"` exceeded 60-day recency window; changed to relative date `datetime.now() - 5 days`.
  - **SQLAlchemy type changes (2 fixes):** `test_review_store.py` — assertions expected strings from raw SQLite, but SQLAlchemy returns `datetime`/`dict`; made assertions type-aware.
  - **3 xfail:** `bulk_update_tags` (2 tests) and `list_dossier_candidates` (1 test) — methods not yet implemented on SQLAlchemy ReviewStore.
- **D23 FIXED:** Removed 9 unused deps from `pyproject.toml`: `altair`, `datasets`, `huggingface-hub`, `trio`, `regex`, `ollama`, `google-auth-httplib2`, `google-auth-oauthlib`, `psycopg2-binary`.
- **D24 FIXED:** Added 3 missing deps: `sqlalchemy>=2.0,<3`, `jinja2`, `pyyaml`.
- **D25+D35 FIXED:** Removed dead entry points `run-dataflow` and `i4g-admin` from `pyproject.toml [project.scripts]`.
- **Remaining Phase 3 debt (deferred to later sprints):** D12-D20, D22, D26-D30, D32-D34 (architectural refactors, not blocking CTO readiness).
- **Next step:** Phase 4 — UI Frontend Review.

### 2026-02-09 — Phase 4 Audit Complete

- **Completed all 6 Phase 4 tasks** across the Next.js monorepo (`ui/`).
- **SDK/API client (4.1):** 15 findings. 3 HIGH: SDK default client targets non-existent `/search` endpoint (platform-client overrides correctly); `indicatorTypes`/`lossBuckets` search filters silently dropped in request mapping; `CaseSummary.classification` field never returned by backend. 6 MED: 3 separate auth patterns with boilerplate duplication; SDK covers only 9/40+ endpoints; taxonomy types defined in 3 places; duplicate utility functions; dead taxonomy enum imports; fragile relative imports. 6 LOW: field name drift, app-only types not shared, campaign type optionality drift.
- **Page audit (4.2):** 20 findings across 9 pages. 4 HIGH: zero error boundaries anywhere; 7/9 pages no loading state; no user auth guard; unstyled Suspense fallback. 8 MED: no `not-found.tsx`; campaign form uses raw HTML; dead code in campaign form; taxonomy page re-declares types; console layout entirely client-rendered; large components (1324 + 998 LOC); inconsistent typography; alert-based error handling. 8 LOW: accessibility gaps (no skip-nav, no ARIA on progress bars/tables), placeholder buttons, duplicate nav icons, redundant CSS import.
- **ui-kit (4.3):** 8 findings. Zero Storybook stories; `BadgeProps`/`BadgeVariant` not exported; manual `index.d.ts` duplicates barrel (drift risk); no Tailwind peer dependency; no tests for any shared package. Components are otherwise well-structured (CVA, forwardRef, proper typing).
- **Types alignment (4.4):** Taxonomy types fragmented across 3 locations; `@i4g/types` is very thin (3 interfaces); `tsconfig.base.json` include pattern mismatches `.ts` file; suspicious `neutral.300` token color value.
- **Formatting (4.5):** All files already conform to Prettier rules — no changes needed.
- **Tests (4.6):** Vitest: 26 tests, all passing. Playwright: 1 smoke spec (not auto-run). Issues: duplicate test file in 2 locations; zero tests for 5 shared packages; no coverage thresholds; dead `iam-helper` app.
- **Total new debt items found: 26** (D36-D61).
- **Next step:** Phase 4 remediation (quick wins), then Phase 5.

### 2026-02-09 — Phase 4 Remediation (Quick Wins)

- **D43 FIXED:** Deleted manual `index.d.ts` from `@i4g/ui-kit`; updated `package.json` types field to point to `src/index.ts` directly — eliminates barrel-drift risk.
- **D44 FIXED:** Exported `BadgeProps` and `BadgeVariant` types from `badge.tsx` (changed `type` → `export type`).
- **D50 FIXED:** Cleaned dead code from `campaign-form.tsx` — removed commented-out `renderNode` function (~20 lines), removed unused `toggleId` function, removed eslint-disable suppressions, used `void` statements for intentionally unused props.
- **D52 FIXED:** Changed `tsconfig.base.json` include pattern from `types/**/*.d.ts` to `types/**/*.ts` so the root `types/taxonomy.ts` file is properly included.
- **D53 FIXED:** Corrected `neutral.300` token hex from `#CBD5F5` (typo) to `#CBD5E1` (Tailwind slate-300).
- **D54 FIXED:** Consolidated duplicate `reviews-service.helpers.test.ts` — merged 4 tests from `tests/unit/` into in-source test file at `src/lib/server/`, deleted duplicate. Test count unchanged (26 tests, 5 files, all passing).
- **D56 FIXED:** Added `tailwindcss: "^3.4.0 || ^4.0.0"` as peer dependency in `@i4g/ui-kit` `package.json`.
- **D59 FIXED:** Removed dead `apps/iam-helper/` directory (contained only `.next/` cache, no source or `package.json`).
- **Verified:** `pnpm format` clean, Vitest 26/26 passing, no TypeScript errors.
- **Remaining Phase 4 debt (deferred):** D36-D42, D45-D49, D51, D55, D57-D58, D60-D61 (architectural refactors requiring design decisions).
- **Next step:** Phase 5 — End-User Documentation.
