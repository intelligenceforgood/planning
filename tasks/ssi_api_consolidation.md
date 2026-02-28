# SSI API Consolidation: Merge ssi-api into fastapi-gateway

> **Created**: February 25, 2026
> **Status**: Complete — All phases done. Validated on `i4g-dev` 2026-02-28.
> **Replaces**: `planning/tasks/ssi_roadmap.md` (Phases 3C, 3D, 4D, and parts of 4A–4C)
> **Risk level**: High — the current system works end-to-end; this consolidation touches all three repos

---

## Progress Dashboard

| Phase | Description             | Status      | Tasks Done |
| ----- | ----------------------- | ----------- | ---------- |
| A     | Documentation           | Done        | 4 / 4      |
| B     | Database & Store        | Done        | 5 / 5      |
| C     | Endpoint Migration      | Done        | 7 / 7      |
| D     | UI Simplification       | Done        | 6 / 6      |
| E     | WebSocket Decision      | Done        | 2 / 2      |
| F     | Infra Decommission      | Done        | 5 / 5      |
| G     | SSI Job Integration     | Done        | 4 / 4      |
| H     | Validation & Smoke Test | Done        | 4 / 4      |

---

## Motivation

Phase 3A of the SSI roadmap added a thin trigger-and-track layer to core's `fastapi-gateway` (`POST /investigations/ssi` + `GET /investigations/ssi/{task_id}`). The UI proxy layer was updated with dual-backend routing: investigation **trigger + status** go through core in cloud, everything else (history, wallets, evidence, playbooks, WebSockets) still hits the standalone `ssi-api` service directly.

This created an awkward split: two Cloud Run Services, two IAP bindings, duplicated auth (OIDC SSI→core is broken — see roadmap 3.3 investigation notes), and a UI that must know about both backends with response-shape normalization.

Merging `ssi-api` into `fastapi-gateway` eliminates:

- **Auth complexity** — one IAP-protected gateway; SSI Job authenticates via service account, not cross-service OIDC
- **Dual-backend UI routing** — all UI API routes go to core; remove `SSI_API_URL` conditional logic
- **Infra duplication** — one fewer Cloud Run Service, Docker image, IAP binding, Terraform config
- **Data copying** — SSI tables live in core's database; no more CoreBridge HTTP calls to replicate data
- **The OIDC audience mismatch bug** — gone entirely (SSI Job talks to core directly, not through IAP)

### What stays separate

- **`ssi/` repository** — keeps its `pyproject.toml`, investigation logic (orchestrator, browser, OSINT, LLM, playbooks, wallet extraction), CLI (`ssi investigate ...`), and Cloud Run Job image
- **`ssi-job.Dockerfile`** — unchanged; browser deps (zendriver, Playwright, Chromium) stay in the Job image only
- **SSI standalone mode** — `ssi` CLI and `ssi/src/ssi/api/app.py` remain functional for local development and testing; they just stop being the production deployment path

---

## Current Architecture (before)

```
┌──────────────┐
│  Next.js UI  │
└──┬───────┬───┘
   │       │
   │       │  SSI_API_URL set (local)     SSI_API_URL absent (cloud)
   │       │  ─────────────────────────   ──────────────────────────
   │       │  POST /investigate ──────▶   POST /investigations/ssi ──▶ core
   │       │  GET  /investigate/{id} ─▶   GET  /tasks/{id} ─────────▶ core
   │       │  GET  /investigations ───▶   GET  /investigations ─────▶ ssi-api ← always
   │       │  GET  /wallets ──────────▶   GET  /wallets ────────────▶ ssi-api ← always
   │       │  GET  /report/{id}/pdf ──▶   GET  /report/{id}/pdf ────▶ ssi-api ← always
   │       │
   ▼       ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────────┐
│ fastapi-     │    │ ssi-api      │    │ ssi-investigate   │
│ gateway      │    │ (Cloud Run   │    │ (Cloud Run Job)   │
│ (Cloud Run   │    │  Service)    │    │                   │
│  Service)    │    │ port 8100    │    │ Browser + LLM +   │
│              │◀───│──────────────│◀───│ OSINT + evidence  │
│ 15 routers   │    │ 5 routers    │    │                   │
│ IAP-protected│    │ IAP-protected│    │ Pushes results    │
│              │    │              │    │ via CoreBridge    │
└──────────────┘    └──────────────┘    └──────────────────┘
       │                   │                     │
       ▼                   ▼                     ▼
   Cloud SQL          Cloud SQL              GCS evidence
   (core tables)      (SSI tables)           bucket
```

**Problems:**

- Two Cloud Run Services with IAP
- UI must choose backend at runtime
- CoreBridge copies data from SSI DB → core DB via HTTP
- OIDC auth SSI→core is broken (audience format mismatch)
- SSI has its own separate DB tables

---

## Target Architecture (after)

```
┌──────────────┐
│  Next.js UI  │
└──────┬───────┘
       │  All requests
       ▼
┌──────────────────┐         ┌──────────────────┐
│ fastapi-gateway  │────────▶│ ssi-investigate   │
│ (Cloud Run       │ trigger │ (Cloud Run Job)   │
│  Service)        │         │                   │
│                  │◀────────│ Browser + LLM +   │
│ ~20 routers      │  report │ OSINT + evidence  │
│ (core + SSI)     │  status │                   │
│ IAP-protected    │         │ Writes directly   │
│                  │         │ to core DB + GCS  │
└──────────────────┘         └──────────────────┘
       │                              │
       ▼                              ▼
   Cloud SQL                      GCS evidence
   (all tables)                   bucket
```

**Wins:**

- One gateway, one auth layer
- UI always talks to core — no conditional routing
- SSI Job writes investigation results directly to core's DB (or via simple internal API calls on localhost)
- No more CoreBridge HTTP auth dance
- SSI tables are Alembic-managed alongside core tables

---

## Inventory: What Moves

### SSI Endpoints → Core Routers

| SSI Endpoint                                         | Core Destination                                         | Priority |
| ---------------------------------------------------- | -------------------------------------------------------- | -------- |
| `POST /investigate`                                  | Already exists: `POST /investigations/ssi`               | Done     |
| `GET /investigate/{id}`                              | Already exists: `GET /investigations/ssi/{task_id}`      | Done     |
| `GET /investigations`                                | New: `GET /investigations/ssi/history`                   | Phase C  |
| `GET /investigations/active`                         | New: `GET /investigations/ssi/active`                    | Phase C  |
| `GET /investigations/{scan_id}`                      | New: `GET /investigations/ssi/{scan_id}`                 | Phase C  |
| `GET /wallets`                                       | New: `GET /wallets` or `GET /investigations/ssi/wallets` | Phase C  |
| `GET /.../wallets.xlsx`                              | New: `GET /investigations/ssi/{scan_id}/wallets.xlsx`    | Phase C  |
| `GET /.../wallets.csv`                               | New: `GET /investigations/ssi/{scan_id}/wallets.csv`     | Phase C  |
| `GET /.../evidence-bundle`                           | New: `GET /investigations/ssi/{scan_id}/evidence-bundle` | Phase C  |
| `GET /.../lea-package`                               | New: `GET /investigations/ssi/{scan_id}/lea-package`     | Phase C  |
| `GET /report/{id}/pdf`                               | New: `GET /investigations/ssi/{scan_id}/report.pdf`      | Phase C  |
| `GET/POST/PUT/DELETE /playbooks`                     | New: `GET/POST/PUT/DELETE /playbooks/ssi`                | Phase C  |
| `POST /playbooks/test-match`                         | New: `POST /playbooks/ssi/test-match`                    | Phase C  |
| `WS /ws/monitor/{id}`                                | Deferred — evaluate in Phase E                           | Phase E  |
| `WS /ws/guidance/{id}`                               | Deferred — evaluate in Phase E                           | Phase E  |
| `GET /`, `POST /submit`, `GET /status/{id}` (web UI) | Not migrated — SSI-only dev convenience                  | N/A      |

### SSI Data Layer → Core

| SSI Component                          | Core Destination                                       |
| -------------------------------------- | ------------------------------------------------------ |
| `ScanStore` (scan_store.py, 753 lines) | New `SsiStore` in `core/src/i4g/services/ssi_store.py` |
| `site_scans` table                     | Alembic migration in core                              |
| `harvested_wallets` table              | Alembic migration in core                              |
| `agent_sessions` table                 | Alembic migration in core                              |
| `pii_exposures` table                  | Alembic migration in core                              |

### SSI Integration Layer → Simplified

| SSI Component                    | After Consolidation                                                           |
| -------------------------------- | ----------------------------------------------------------------------------- |
| `CoreBridge` (584 lines)         | Simplified: Job writes to core DB via internal store calls or single-host API |
| `TaskStatusReporter` (106 lines) | Unchanged — still posts to `POST /tasks/{task_id}/update`                     |
| OIDC auth dance                  | Eliminated — Job uses SA auth to core's internal task update endpoint         |

### Infrastructure → Reduced

| Resource                                  | Action                                                             |
| ----------------------------------------- | ------------------------------------------------------------------ |
| `ssi-api` Cloud Run Service               | Delete                                                             |
| `ssi-api.Dockerfile`                      | Delete                                                             |
| `ssi-api` Artifact Registry image         | Delete                                                             |
| `ssi-api` IAP binding                     | Delete                                                             |
| `SSI_API_URL` env var (console)           | Scoped to local dev only (2 trigger+poll routes); not set in cloud |
| `ssi_api_enabled` Terraform variable      | Delete                                                             |
| `sa-ssi` in `fastapi_iap_access_members`  | Remove (no longer needs IAP access)                                |
| `sa-ssi` `run.invoker` on fastapi-gateway | Remove (Job doesn't call gateway through LB)                       |

---

## Implementation Plan

### Phase A — Documentation & Architecture (1–2 days)

> Update docs first so the target state is clear before any code changes.

- [x] **A.1** — Update system topology — revised `docs/book/architecture/system-topology.md` Mermaid diagram: bumped router count 13→19, added `ssi-investigate` Cloud Run Job node with data flow edges, updated Artifact Registry count to 8, updated "What's in the platform" descriptions.

- [x] **A.2** — Updated API docs — added SSI endpoint reference table to `docs/book/api/README.md` (13 endpoints: investigations, wallets, evidence, playbooks, task polling). Updated SSI README, getting-started, configuration, and live-monitoring pages to reflect consolidated architecture (no standalone `ssi-api` in production).

- [x] **A.3** — Updated SSI user docs — revised `docs/book/ssi/README.md` (deployment note), `getting-started.md` (architecture note), `configuration.md` (shared DB docs, `SSI_STORAGE__DB_URL`), `live-monitoring.md` (WebSocket availability note — local dev only, SSE recommended for future prod).

- [x] **A.4** — Regenerated `settings_manifest.json` and `.yaml` via `i4g settings export-manifest --docs-repo ../docs`. `ssi_job` section (6 fields: `core_api_url`, `job_name`, `playbook_dir`, `project`, `region`, `service_account`) now present in both `core/docs/config/` and `docs/config/` manifests. No `SSI_API_URL` references (was never in core's settings model).

**Exit criteria**: All architecture diagrams and docs reflect the target single-gateway topology.

---

### Phase B — Database Schema Merge (2–3 days)

> Bring SSI's four tables into core's Alembic-managed schema.

- [x] **B.1** — Alembic migration — create migration adding `site_scans`, `harvested_wallets`, `agent_sessions`, `pii_exposures` tables to core's database. Use the exact column definitions from SSI's `ScanStore` (see `ssi/src/ssi/store/scan_store.py` `_ensure_tables()` method). Add foreign key from `site_scans.case_id` → `cases.case_id`.
  - _Done_: Migration `20260221_01_add_ssi_scan_tables.py` already existed with correct schema, FKs, and indexes. Table definitions in `core/src/i4g/store/sql.py` already present.

- [x] **B.2** — `SsiStore` data access layer — create `core/src/i4g/store/ssi_store.py` implementing the same CRUD interface as SSI's `ScanStore`:
  - `create_scan()`, `update_scan()`, `complete_scan()`, `get_scan()`, `list_scans()`
  - `add_wallet()`, `add_wallets_bulk()`, `get_wallets()`, `search_wallets()`
  - `log_agent_action()`, `get_agent_actions()`
  - `add_pii_exposure()`, `add_pii_exposures_bulk()`, `get_pii_exposures()`
  - _Note_: `persist_investigation()` intentionally omitted — it depends on SSI-specific models and stays in `ssi.store.ScanStore`.

- [x] **B.3** — `SsiStore` factory — added `build_ssi_store()` to `core/src/i4g/services/factories.py` following the existing factory pattern. Supports both SQLite (local) and Cloud SQL backends.

- [x] **B.4** — Unit tests — 41 tests in `tests/unit/store/test_ssi_store.py` covering all CRUD methods across all 4 tables. 98% coverage (148/148 stmts, 3 misses).

- [x] **B.5** — Settings — verified `SsiJobSettings` already exists in `core/src/i4g/settings/sections/jobs.py`. No new settings needed; `SsiStore` uses existing `storage.structured_backend` engine.

**Exit criteria**: `SsiStore` passes all unit tests; migration applies cleanly; `pytest tests/unit` green.

---

### Phase C — Endpoint Migration (3–4 days)

> Move SSI's read endpoints into core as new routers. The trigger endpoint already exists.

- [x] **C.1** — Investigation history router — `core/src/i4g/api/ssi_investigations.py` (3 endpoints: history, active stub, detail). 100% coverage.

- [x] **C.2** — Wallet router — `core/src/i4g/api/ssi_wallets.py` (3 endpoints: search, CSV, XLSX). XLSX uses optional `openpyxl` dep. 98% coverage.

- [x] **C.3** — Evidence/report endpoints — `core/src/i4g/api/ssi_evidence.py` (3 endpoints: evidence-bundle, lea-package, report.pdf). GCS signed URL redirect for cloud, local file serving for dev. 84% coverage.

- [x] **C.4** — Playbook router — `core/src/i4g/api/ssi_playbooks.py` (6 endpoints: list, detail, create, update, delete, test-match). File-based storage via `settings.ssi_job.playbook_dir` (env: `SSI_PLAYBOOK_DIR`). Self-contained models (no SSI imports). Added `playbook_dir` field to `SsiJobSettings` with path resolution in `runtime_overrides.py`. 27 tests in `tests/unit/api/test_ssi_playbooks.py`. 97% coverage.

- [x] **C.5** — Register routers — added to `core/src/i4g/api/app.py`. Playbook router added (own prefix `/playbooks/ssi` — no ordering issue). Wallet/evidence routers registered before investigations router so static paths resolve before `{scan_id}` catch-all. Note: the old `GET /investigations/ssi/{task_id}` convenience alias is now shadowed; use `GET /tasks/{task_id}` instead.

- [x] **C.6** — Unit tests — 35 tests in `tests/unit/api/test_ssi_endpoints.py` + 27 tests in `tests/unit/api/test_ssi_playbooks.py`. 92%+ combined coverage (target ≥90%). Updated existing `test_investigations.py` to reflect shadowed route.

- [x] **C.7** — Integration validation — 842 passed, 1 skipped, 0 failures. No regressions. Playbook router (C.4) fully implemented with 27 tests.

**Exit criteria**: All SSI read endpoints served by core; `pytest tests/unit` green; endpoint parity verified.

---

### Phase D — UI Simplification (1–2 days)

> Remove the dual-backend proxy layer. All routes go to core.

- [x] **D.1** — Simplify API routes — updated all 6 files in `ui/apps/web/src/app/api/ssi/`:
  - `investigate/route.ts` — retains `SSI_API_URL` conditional for **local dev only** (proxies `POST /investigate` to SSI service so in-process task status works); cloud path calls core's `POST /investigations/ssi` via `apiFetch()`. Removed `backend` field from response.
  - `investigate/[id]/route.ts` — retains `SSI_API_URL` conditional for **local dev only** (polls `GET /investigate/{id}` on SSI service); cloud path polls core's `GET /tasks/{task_id}` via `apiFetch()`. Removed `backend` field.
  - `investigations/route.ts` — core-only; calls `GET /investigations/ssi/history` via `apiFetch()` with `queryParams`
  - `investigations/[id]/route.ts` — core-only; calls `GET /investigations/ssi/{scan_id}` via `apiFetch()`
  - `wallets/route.ts` — core-only; calls `GET /investigations/ssi/wallets` via `apiFetch()` with `queryParams`
  - `report/[id]/route.ts` — **core-only**; proxies `GET /investigations/ssi/{scan_id}/report.pdf` using raw `fetch` (binary streaming). `SSI_API_URL` fallback removed — with shared DB, core serves the PDF directly. Handles 307 redirects (GCS signed URL pass-through) and 200 (local disk PDF stream). Sets `Content-Type: application/pdf` and `Content-Disposition` headers.
  - _Rationale_: Core's `_trigger_local_investigation()` spawns a subprocess that cannot update the in-memory `TASK_STATUS` dict, so polling via core in local dev returns `"queued"` forever. The SSI service handles investigation in-process and can serve status correctly. In cloud, the Cloud Run Job + `TaskStatusReporter` properly updates core's task status via HTTP callback.

- [x] **D.2** — Update SSI types — updated `ui/apps/web/src/types/ssi.ts`: removed `backend` field from `InvestigateResponse` and `StatusResponse`; changed `InvestigationDetailResponse` top-level keys to camelCase (`piiExposures`, `agentActions`) to match core's `CamelModel` output. Nested dict keys remain snake_case (from DB).

- [x] **D.3** — Update console pages:
  - `page.tsx` — removed `investigationBackend` state and all its references; removed SSI-backend-only warning block
  - `investigations/page.tsx` — server component now uses `apiFetch("/investigations/ssi/history")` instead of direct `SSI_API_URL` fetch
  - `investigations/[id]/page.tsx` — updated `data.pii_exposures` → `data.piiExposures` to match CamelModel output

- [x] **D.4** — Scope `SSI_API_URL` to local dev only:
  - Re-added to `ui/apps/web/.env.local` and `.env.example` with clear local-dev-only comments
  - Only used by 2 routes: `investigate/route.ts` (trigger) and `investigate/[id]/route.ts` (poll)
  - In cloud (no `SSI_API_URL` set), both routes fall through to core — no ssi-api service needed
  - No Terraform references (already clean; `SSI_API_URL` is not set in Cloud Run env vars)

- [x] **D.5** — Ran `pnpm format` (all unchanged — clean) and `tsc --noEmit` (zero errors).

- [x] **D.6** — Fixed `page.tsx` step logic — added `"queued"` to `stepAnalyzing` active states and `stepReport` pending states. Core returns `"queued"` as initial status when triggering locally; without this fix, the UI skipped the analysis step and hung on the report step forever.

**Exit criteria**: UI builds clean; 4 data routes are core-only; 2 trigger+poll routes use `SSI_API_URL` in local dev (core-only in cloud). `tsc --noEmit` passes. ✅

> **Pre-merge note (2026-02-26):** During iterative development, D.1–D.6 changes were accidentally stashed (`git stash`). Pre-merge review recovered the complete stash content and reconciled it with incremental working-tree fixes. All 10 files verified consistent. `pnpm format` clean, `tsc --noEmit` zero errors.

---

### Phase E — WebSocket Decision (1 day)

> WebSocket live monitoring is a power-user feature for watching the agent work in real time.

- [x] **E.1** — Evaluate options:
  - **Option A**: Add WebSocket support to core gateway (FastAPI supports it natively). Requires ensuring Cloud Run's HTTP/2 + streaming works for WS.
    - _Pros_: Native FastAPI support; full-duplex; real-time agent monitoring in prod.
    - _Cons_: Cloud Run WS requires HTTP/2 and has a 1-hour timeout max. IAP does not support WebSocket connections — would need an unauthenticated path or a separate ingress. Next.js proxy adds complexity (server-side WS relay). Significant engineering for a power-user feature.
  - **Option B**: Keep WebSocket as CLI/local-dev-only via SSI's standalone app. No prod WS support. **(Selected)**
    - _Pros_: Zero effort. Standalone SSI app already works for dev/demo. Task status polling (`GET /tasks/{task_id}`) provides adequate production UX for progress tracking. No IAP/Cloud Run WS complexity.
    - _Cons_: No real-time agent log streaming in prod console. Power users must use CLI for live monitoring.
  - **Option C**: Implement server-sent events (SSE) instead of WebSocket — simpler with Cloud Run's request model.
    - _Pros_: Unidirectional (server→client) fits the monitoring use case. Works with HTTP/1.1. Cloud Run supports long-lived streaming responses. Simpler than WS through IAP.
    - _Cons_: Still requires IAP pass-through testing, Next.js SSE relay, and new core endpoint. Moderate effort for a power-user feature.

  **Decision: Option B** — WebSocket/SSE live monitoring is deferred from the consolidation scope. The existing task polling mechanism provides sufficient UX for production investigation tracking. Real-time agent log streaming remains available via `ssi` CLI in local/dev mode. If prod live monitoring becomes a priority, Option C (SSE) is the recommended future path due to better Cloud Run and IAP compatibility.

- [x] **E.2** — Decision documented above. No implementation needed for Option B.

**Exit criteria**: ~~Decision documented. If implementing, WS/SSE endpoints work on Cloud Run.~~ Decision documented — Option B selected (defer to CLI/local-dev).

---

### Phase F — Infrastructure Decommission (staged rollout)

> Remove the standalone `ssi-api` Cloud Run Service and related infra.
> **Strategy**: Staged rollout with instant rollback at each stage. The `ssi-api` service stays running as a hot standby until Stage 5 (full decommission) is validated.

#### Stage 0 — Pre-flight validation (local) ✅

- [x] All unit tests pass: core 842 passed, SSI 717 passed, UI `tsc --noEmit` zero errors.
- [x] Verified all 6 UI SSI proxy routes are correctly wired for cloud mode (no `SSI_API_URL`).
- [x] Confirmed stashed UI changes were already in HEAD commit `f419c9e`; stash dropped.

#### Stage 1 — Deploy updated gateway image (additive, zero-risk)

> New SSI routers come online on the gateway. No traffic hits them yet because the console still routes through `ssi-api` via `SSI_API_URL`.

- [x] **F.S1.1** — Build and push core image: `cd core && scripts/build_image.sh fastapi dev`
- [x] **F.S1.2** — Deploy to Cloud Run (gcloud or CD pipeline)
- [x] **F.S1.3** — Verify new endpoints respond (`/investigations/ssi/history`, `/investigations/ssi/wallets`)
- _Rollback_: Redeploy previous core image tag (~3 min)

#### Stage 2 — Deploy updated console image (partial switchover)

> Console starts using core for 4 data routes (history, detail, wallets, report). Trigger+poll still goes through `ssi-api`.

- [x] **F.S2.1** — Build and push console image: `cd ui && scripts/build_image.sh i4g-console dev`
- [x] **F.S2.2** — Deploy to Cloud Run
- [x] **F.S2.3** — Verify data routes work: history, detail, wallets, PDF report download
- _Rollback_: Redeploy previous console image tag (~3 min)

#### Stage 3 — Shift all SSI traffic to core (env var override)

> Set `SSI_API_URL = ""` in `console_env_vars` via tfvars. The `ssi-api` service stays running (0 idle instances = zero cost) as a hot standby.

- [x] **F.S3.1** — `SSI_API_URL` was never set in cloud env vars (confirmed clean). `ssi-api` Cloud Run Service deleted via Terraform.
- [x] **F.S3.2** — `terraform plan` confirmed only `ssi-api` resource removal.
- [x] **F.S3.3** — `terraform apply` completed. `ssi-api` service decommissioned.
- [x] **F.S3.4** — Cloud smoke test passed: trigger → poll → history → detail → wallets → evidence → report.
- _Rollback_: Remove `SSI_API_URL = ""` line, `terraform apply` (~2 min)

#### Stage 4 — Bake period (1–2 days)

> Let co-workers use it organically. `ssi-api` remains running as safety net.

- [x] **F.S4.1** — Team notified of SSI routing switch on dev.
- [x] **F.S4.2** — Bake period complete; no regressions reported.

#### Stage 5 — Full decommission

> Only after Stage 4 is validated. Changes prepared on feature branches:
>
> - `infra`: branch `feat/phase-f-ssi-api-decommission` (commit `579ca8a`)
> - `ssi`: branch `feat/phase-f-ssi-api-decommission` (commit `8b170aa`)

- [x] **F.1** — Terraform changes prepared (branch `feat/phase-f-ssi-api-decommission`):
  - Remove `module "run_ssi_api"` block
  - Remove `SSI_API_URL` from console env vars
  - Remove `sa-ssi` from `fastapi_iap_access_members` and invoker lists
  - Remove `ssi_api_*` variables and tfvars blocks
  - Keep `sa-ssi` for Cloud Run Job roles

- [x] **F.2** — Delete `ssi/docker/ssi-api.Dockerfile` (on branch).

- [x] **F.3** — Clean up Artifact Registry — `ssi-api` image tags deleted.

- [x] **F.4** — Updated SSI's `scripts/build_image.sh` — removed `ssi-api` references.

- [x] **F.5** — Core's `scripts/build_image.sh` has no SSI references — no changes needed.

**Exit criteria**: `terraform plan` shows only the removal of `ssi-api` resources; no other changes. All smoke tests pass.

---

### Phase G — Shared Database Integration (1–2 days)

> SSI writes directly to core's database — no CoreBridge, no HTTP dance.

- [x] **G.1** — Shared database approach selected:
  - Added `db_url` field to SSI's `StorageSettings` (`SSI_STORAGE__DB_URL` env var).
  - When set, `build_engine()` uses the URL instead of SSI's local `sqlite_path`.
  - Default in `settings.default.toml`: `sqlite:///../core/data/i4g_store.db` — SSI writes directly to core's DB in local dev.
  - In cloud: SSI Job uses `SSI_STORAGE__CLOUDSQL_*` fields (same Cloud SQL instance as core).
  - _No CoreBridge needed for data persistence_ — SSI's `ScanStore` writes to the same tables core reads.

- [x] **G.2** — Removed `download_report_pdf` endpoint from `ssi/src/ssi/api/investigation_routes.py` (workaround added in prior session). Core's `ssi_evidence.py` router now serves report PDFs for all environments.

- [x] **G.3** — One-time data migration: `ssi/scripts/migrate_to_core_db.py` copied 248 scans, 57 wallets, 40 agent sessions, 20 PII exposures from `ssi/data/ssi_store.db` → `core/data/i4g_store.db`. Schemas are column-for-column identical (verified via `PRAGMA table_info`).

- [x] **G.4** — Updated SSI config:
  - `ssi/config/settings.default.toml` — added `db_url` default pointing at core's DB.
  - `ssi/config/settings.local.toml.example` — added commented storage section.
  - SSI's `_resolve_paths()` validator normalizes relative `sqlite:///` paths in `db_url`.

**Exit criteria**: SSI writes to core's DB; core endpoints return real data; `download_report_pdf` workaround removed. ✅

---

### Phase H — Validation & Smoke Test (1–2 days)

> End-to-end validation of the consolidated architecture on `i4g-dev`.

- [x] **H.1** — Deploy to `i4g-dev` — verified 2026-02-28:
  - Terraform applied: 0 added, 2 changed (scaling drift), 0 destroyed. No `ssi-api` resources.
  - Gateway image: `fastapi:dev` built, pushed, deployed → `fastapi-gateway-00168-kdv`
  - SSI Job image: `ssi-job:dev` built, pushed
  - Console image: `i4g-console:dev` built, pushed, deployed → `i4g-console-00113-7j4`

- [x] **H.2** — Smoke test checklist — all passed 2026-02-28:
  - [x] Analyst triggers investigation from console → Cloud Run Job launches (HTTP 202, `ssi-investigate-ngpmb`)
  - [x] Task status polls show progress → Job completes (`running` → `completed`, 39.52s, risk_score=16.0)
  - [x] Investigation appears in history list (HTTP 200, latest scan matches triggered investigation)
  - [x] Investigation detail shows wallets, PII, agent actions (HTTP 200, correct camelCase keys)
  - [x] Evidence bundle downloads (HTTP 307 → GCS signed URL redirect)
  - [x] LEA package — HTTP 404 (expected: scan had no LEA package generated)
  - [x] PDF report downloads (HTTP 307 → GCS signed URL redirect)
  - [x] Wallet search works (HTTP 200, 4 wallets from prior investigations)
  - [x] Case back-reference — `case_id: null` (expected: passive scan of benign site, no case creation triggered)
  - [x] Evidence is attached to case — N/A (no case created for benign test site)
  - [x] CLI `ssi investigate url` still works in local dev mode — verified 2026-02-28

- [x] **H.3** — Run full test suites — verified 2026-02-28:
  - Core: `pytest tests/unit` → **850 passed**, 1 skipped
  - SSI: `pytest tests/unit` → **717 passed**
  - UI: `pnpm type-check` → 0 errors
  - Bootstrap local reset → 7,086 cases, 7,532 docs, all SSI tables present, verify.json/verify.md generated

- [x] **H.4** — Update `planning/change_log.md` with consolidation summary — 2026-02-28.

**Exit criteria**: All smoke tests pass; test suites green; no regressions. ✅

---

### Post-Merge Items (identified during pre-merge review)

- [x] **PM.1** — Orchestrator `investigation_id` skip-create test — `ssi/tests/unit/test_orchestrator.py` (3 tests):
  - `create_scan()` called when `investigation_id` is None (standalone path)
  - `create_scan()` NOT called when `investigation_id` provided (Cloud Run Job path)
  - `build_scan_store()` NOT called when `persist_scans` is False
  - SSI tests: 720 passed (717 + 3 new), 0 failures.

- [x] **PM.2** — Prod Terraform plan — `terraform plan` on `infra/environments/app/prod/`: 0 added, 1 changed (scaling drift), 0 destroyed. No `ssi-api` resources present. Clean for future apply.

**Exit criteria**: All post-merge items resolved; no regressions.

---

## Risk Mitigation

| Risk                                  | Mitigation                                                                                                                                        |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| Breaking the working cloud deployment | Phase F (infra decommission) is **last**. Until then, `ssi-api` continues running. UI can fall back to SSI-direct if `SSI_API_URL` is re-enabled. |
| Database migration issues             | Phase B adds new tables only — no modification of existing core tables. Rollback = drop the 4 new tables.                                         |
| SSI Job integration breaks            | CoreBridge changes (Phase G) are the last code change. Option B (keep HTTP calls) is lowest risk.                                                 |
| Local dev workflow breaks             | SSI's standalone FastAPI app (`ssi/src/ssi/api/app.py`) remains functional. `ssi investigate url` CLI unchanged.                                  |
| WebSocket monitoring lost             | Phase E evaluates explicitly. If deferred, document and keep SSI standalone for dev monitoring.                                                   |

---

## Sequencing & Dependencies

```
Phase A (docs)         ──▶ can start immediately, no code deps
Phase B (DB + store)   ──▶ after A; core-only changes
Phase C (endpoints)    ──▶ after B (needs SsiStore)
Phase D (UI)           ──▶ after C (needs core endpoints live)
Phase E (WebSocket)    ──▶ after C; independent decision
Phase F (infra)        ──▶ after D + H smoke test passes
Phase G (SSI Job)      ──▶ after B; can parallel with C/D
Phase H (validation)   ──▶ after C + D + G; before F
```

**Critical path**: A → B → C → D → H → F

**Parallel work**: G can run alongside C and D once B is done.

---

## Resource Estimates

| Phase                         | Duration       | Effort         |
| ----------------------------- | -------------- | -------------- |
| Phase A — Documentation       | 1–2 days       | 1 engineer     |
| Phase B — Database & store    | 2–3 days       | 1 engineer     |
| Phase C — Endpoint migration  | 3–4 days       | 1 engineer     |
| Phase D — UI simplification   | 1–2 days       | 1 engineer     |
| Phase E — WebSocket decision  | 0.5–1 day      | 1 engineer     |
| Phase F — Infra decommission  | 0.5–1 day      | 1 engineer     |
| Phase G — SSI Job integration | 1–2 days       | 1 engineer     |
| Phase H — Validation          | 1–2 days       | 1 engineer     |
| **Total**                     | **10–16 days** | **1 engineer** |

---

## Items Deferred from ssi_roadmap.md

The following items from the original SSI roadmap are **not part of this consolidation** and should be tracked separately if still desired:

| Original Item                  | Status              | Notes                                      |
| ------------------------------ | ------------------- | ------------------------------------------ |
| 2.5 — Prod deployment          | Not started         | Do after consolidation is proven on dev    |
| 3.6 — Taxonomy mapping         | Not started         | Can be done post-consolidation             |
| 3.7 — Shared types             | Partially addressed | SSI tables in core DB reduces the need     |
| 3.8 — Victim intake flow       | Not started         | Post-consolidation feature                 |
| 3.9 — Dossier enrichment       | Not started         | Post-consolidation feature                 |
| 4.1 — CAPTCHA solver           | Not started         | Independent of consolidation               |
| 4.2 — Proxy infrastructure     | Not started         | Independent of consolidation               |
| 4.3 — Per-tenant rate limiting | Not started         | Easier post-consolidation (single gateway) |
| 4.4 — Retention policy         | Not started         | Easier post-consolidation (single DB)      |
| 4.6 — Legal review             | Not started         | Independent                                |
| 4.7 — LEA pilot                | Not started         | Independent                                |
| All Phase 5                    | Not started         | Future capabilities                        |

---

## Key Files Reference

### Core (gateway)

- `core/src/i4g/api/app.py` — router registration (15 existing + new SSI routers)
- `core/src/i4g/api/investigations.py` — existing trigger + status (stays)
- `core/src/i4g/api/auth.py` — auth gate (`_verify_iap_jwt`, `require_token`)
- `core/src/i4g/settings/sections/jobs.py` — `SsiJobSettings`
- `core/src/i4g/services/factories.py` — store factories

### SSI (investigation engine)

- `ssi/src/ssi/api/app.py` — SSI FastAPI app (5 routers — stays for local dev)
- `ssi/src/ssi/api/routes.py` — investigate + health endpoints
- `ssi/src/ssi/api/investigation_routes.py` — history, wallets, evidence endpoints (migrate)
- `ssi/src/ssi/api/playbook_routes.py` — playbook CRUD (migrate)
- `ssi/src/ssi/api/ws_routes.py` — WebSocket monitoring (Phase E decision)
- `ssi/src/ssi/store/scan_store.py` — 753 lines, 4 tables (port to core)
- `ssi/src/ssi/integration/core_bridge.py` — 584 lines (simplify in Phase G)
- `ssi/src/ssi/worker/task_reporter.py` — 106 lines (update auth in Phase G)
- `ssi/docker/ssi-api.Dockerfile` — delete in Phase F
- `ssi/docker/ssi-job.Dockerfile` — keep

### UI (analyst console)

- `ui/apps/web/src/app/api/ssi/investigate/route.ts` — dual-backend POST (local dev → SSI; cloud → core)
- `ui/apps/web/src/app/api/ssi/investigate/[id]/route.ts` — dual-backend poll (local dev → SSI; cloud → core)
- `ui/apps/web/src/app/api/ssi/investigations/route.ts` — SSI-direct (redirect to core)
- `ui/apps/web/src/app/api/ssi/investigations/[id]/route.ts` — SSI-direct (redirect to core)
- `ui/apps/web/src/app/api/ssi/wallets/route.ts` — SSI-direct (redirect to core)
- `ui/apps/web/src/app/api/ssi/report/[id]/route.ts` — SSI-direct (redirect to core)
- `ui/apps/web/src/types/ssi.ts` — remove `backend` field, SSI-direct shapes

### Infrastructure

- `infra/environments/app/dev/main.tf` — `module "run_ssi_api"` (delete), IAM bindings, env vars
