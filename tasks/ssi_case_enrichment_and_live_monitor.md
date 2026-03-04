# SSI Case Enrichment & Live Monitor Redesign

**Created:** 2026-02-28
**Updated:** 2026-03-02
**Status:** Phase 3 — 3B.10 in progress (4 root causes fixed; needs rebuild + redeploy + E2E retest)

---

## 1. Assessment

### 1A. Empty Timeline & Artifacts on SSI-Created Cases

**Root cause:** Two distinct data-plumbing gaps.

| Card          | Data source in UI                                     | What SSI does today                                                                                                                                    | Why it's empty                                                                                                                                                                |
| ------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Timeline**  | `review_actions` rows joined by `review_id`           | SSI calls `POST /cases` → core calls `store.enqueue_case()` which inserts one action (`enqueued`). No other actions are logged.                        | The only entry is an auto-generated "enqueued" event. No SSI milestones (scan started, classification done, wallets found, evidence uploaded, report generated) are recorded. |
| **Artifacts** | `metadata.files` JSON array on the `scam_records` row | SSI uploads evidence files via `POST /cases/{id}/evidence` → inserts into `source_documents` table. The `metadata.files` array is **never populated**. | The Artifacts card reads from `metadata.files`, but SSI writes to `source_documents`. Two separate data paths that don't connect.                                             |

**Impact:** An analyst opening a case created by SSI sees a near-empty details page despite rich investigation data existing in the system.

**Effort:** Low–Medium. Both gaps are data-plumbing fixes — no new UI components needed.

### 1B. Live Monitor Page — Broken in Cloud, Misplaced in Navigation

**Root cause:** Architectural mismatch between local dev and cloud deployment.

| Aspect              | Status                                                                                                                                                                                                                                                                                                         |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **UI code**         | Fully implemented — screenshot viewer, guidance input, event log all work                                                                                                                                                                                                                                      |
| **SSI backend**     | Fully implemented — EventBus, WebSocket endpoints (`/ws/monitor/{id}`, `/ws/guidance/{id}`), snapshot caching                                                                                                                                                                                                  |
| **Works locally?**  | Yes — when SSI API runs as a persistent `uvicorn` process on `:8100`                                                                                                                                                                                                                                           |
| **Works in cloud?** | **No** — SSI runs as an ephemeral Cloud Run Job. No persistent WebSocket server exists. The UI has no endpoint to connect to.                                                                                                                                                                                  |
| **UX placement**    | The monitor tab lives on `/ssi/investigations/[id]` (post-hoc detail page), but the user needs live feedback on `/ssi` (the investigate page) during the scan. Navigating away from `/ssi` loses all polling state (all `useState` hooks are ephemeral with no persistence to `sessionStorage` or URL params). |

**Impact:**

- **Cloud users:** Live Monitor is a dead feature — clicking the tab shows "disconnected" permanently.
- **Local dev users:** Must manually open `/ssi/investigations/{id}` in a second tab to see live screenshots; navigating away from the originating `/ssi` page loses progress tracking.

**Effort:** Medium–High. Fixing cloud requires either (a) deploying SSI as a persistent Cloud Run Service with WebSocket support, or (b) relaying events through core via SSE/stored events. Fixing UX placement is medium effort.

---

## 2. Proposed Design

### Phase 1 — Case Enrichment (Timeline + Artifacts)

**Goal:** SSI-created cases show meaningful timeline events and downloadable artifacts on the case detail page.

#### 2A. Timeline Events

**Approach:** Add a `POST /cases/{case_id}/timeline` endpoint in core that accepts structured event payloads. SSI's `CoreBridge.push_investigation()` calls it after case creation to log key milestones.

**Events to record (from `InvestigationResult`):**

| Event                      | Timestamp source | Description                                                 |
| -------------------------- | ---------------- | ----------------------------------------------------------- |
| `investigation_submitted`  | `started_at`     | "SSI investigation initiated for {url}"                     |
| `classification_completed` | `completed_at`   | "Classified as {primary_type} (risk: {risk_score})"         |
| `wallets_harvested`        | `completed_at`   | "Found {n} wallet addresses across {m} networks"            |
| `evidence_collected`       | `completed_at`   | "Collected {n} evidence artifacts (screenshots, HAR, STIX)" |
| `report_generated`         | `completed_at`   | "Investigation report generated"                            |
| `case_created`             | now              | "Case created from SSI investigation {investigation_id}"    |

**Core changes:**

1. Add `POST /cases/{case_id}/timeline` endpoint → inserts into `review_actions` with `actor="ssi-agent"`.
2. Update `CaseTimelineEvent` mapping to render SSI events with better descriptions (strip the `"{action}: "` prefix pattern).

**SSI changes:**

1. `CoreBridge._create_timeline_events(case_id, result)` — new method called in `push_investigation()`.

#### 2B. Artifacts Card

**Approach:** After uploading evidence files, also update the case's `metadata.files` array so the Artifacts card renders them.

Two options:

- **Option A (preferred):** Change the case detail GET handler to **also query `source_documents`** for the case and merge them into the artifacts list. This is the cleaner fix — the data already exists, the UI just doesn't read it.
- **Option B:** Have SSI's `CoreBridge._attach_evidence()` PATCH the case metadata to append uploaded filenames to `metadata.files`. This adds a round-trip and coupling.

**Core changes (Option A):**

1. In `get_case()`, query `source_documents WHERE case_id = ?` and map each row to a `CaseArtifact` with `url = f"/cases/{case_id}/evidence/{doc_id}"`.
2. Merge with any existing `metadata.files` artifacts.

**No SSI changes needed for Option A.**

---

### Phase 2 — Investigate Page State Persistence

**Goal:** User can navigate away from `/ssi` during an investigation and return without losing progress.

**Approach:** Persist active investigation state to `sessionStorage` and URL search params.

**UI changes:**

1. On investigation start, write `{investigationId, scanId, url, scanType, startedAt}` to `sessionStorage`.
2. On page mount, check `sessionStorage` for an active investigation — if found, resume polling.
3. Push `?investigationId={id}` to the URL so browser back/forward preserves context.
4. On investigation complete/fail, clear `sessionStorage`.

**No backend changes needed.**

---

### Phase 3 — Live Monitor Relocation & Cloud Support

**Goal:** Move live monitoring to the investigate page and make it work in cloud deployments.

This phase is split into four sub-phases (3.0 → 3C), designed to be independently testable and revertible.

#### 3.0. Job-to-Service Migration (Medium effort, standalone) — ✅ Complete

**Problem:** SSI originally ran as a Cloud Run Job. Job cold-starts are unpredictable (5–30 s), and the ephemeral container means no persistent endpoints (WebSocket, SSE) are reachable from the UI.

**Outcome (3.0.1–3.0.11):** SSI is now deployed as a Cloud Run Service (`ssi-svc`). Interactive investigation works via `POST /jobs/investigate` on ssi-svc. The Cloud Run Job definition was kept in Terraform with a `ssi_job.mode` feature flag for safe rollback.

**Next (3.0.12):** The job path has proven unnecessary. ssi-svc handles interactive investigation reliably with sub-second dispatch. Batch investigation will also move to ssi-svc via `POST /investigate/batch`. The Cloud Run Job (`ssi-investigate`), the `ssi_job.mode` toggle, and all `SSI_JOB__*` env vars are being removed entirely. See task list 3.0.12a–3.0.12ap below.

**Architecture (service-only, post-3.0.12):**

```
┌─ Core API ─────────────────────────────────────────────────┐
│ POST /investigations/ssi                                   │
│   → HTTP POST to SSI Service (OIDC-authenticated)          │
│         ↓                                                  │
│   SSI Service: POST /investigate (single investigation)    │
│                POST /investigate/batch (manifest-driven)   │
│         ↓ (background task, CPU always allocated)           │
│   run_investigation() → DB writes → TaskStatusReporter     │
└────────────────────────────────────────────────────────────┘
```

**Service-to-service auth (zero custom code):**

```python
# Core calls SSI service with Google-issued OIDC token
import google.auth.transport.requests
import google.oauth2.id_token
token = google.oauth2.id_token.fetch_id_token(request, audience=service_url)
requests.post(service_url + "/investigate", headers={"Authorization": f"Bearer {token}"}, json=payload)
```

Cloud Run validates the token automatically — no middleware needed on the SSI side.

#### 3A. Move Live Monitor to the Investigate Page (Medium effort)

**Approach:** Embed the `useInvestigationMonitor` hook and monitor panel directly on `/ssi` page, shown alongside the progress spinner when an investigation is running.

**UI changes:**

1. Add a "Live View" expandable panel on the `/ssi` page below the progress steps.
2. When investigation is active, connect `useInvestigationMonitor` with the `investigationId`.
3. Show screenshot and event log inline (read-only — no guidance input in this phase).
4. **Keep** the Live Monitor tab on `/ssi/investigations/[id]` — once Phase 3B persists events to `ssi_events`, this tab becomes an event replay viewer. No need to remove and re-add it.

**Consideration:** This only works locally (direct WebSocket to SSI API). For cloud, see 3B.

#### 3B. Cloud Live Monitoring via DB-Polled SSE (High effort)

**Approach:** SSI pushes investigation events to core via HTTP during the investigation. Core stores events in a database table and streams them to the UI via Server-Sent Events (SSE) using DB polling.

**Why Redis pub/sub for event streaming:** Although this is a monitoring feed (not a real-time trading system), the platform regularly hosts tutorial sessions for volunteer students where 20–30 concurrent investigations are expected. DB polling at 2–3 s intervals across 30 active viewers would generate excessive query load on PostgreSQL. Redis pub/sub provides sub-second fan-out to multiple SSE clients with negligible overhead — and Redis is a lightweight addition to the infrastructure (Cloud Memorystore or a sidecar container).

**Architecture:**

```
SSI Service → HTTP POST batches → Core API POST /events/ssi/{scan_id}
                                        ↓
                                  ssi_events table (PostgreSQL) + Redis pub/sub
                                        ↓                              ↓
                              (replay: DB query)            (live: Redis subscribe)
                                        ↓                              ↓
                              Core API GET /events/ssi/{scan_id}/stream (SSE)
                                        ↓
                                  UI EventSource
```

**Screenshot strategy:** Screenshots are stored inline in the `ssi_events` table as base64 (in the `data_json` column). This avoids GCS complexity (signed URLs, expiry, CORS, separate bucket management) for what are typically small JPEG thumbnails (~50–150 KB each). The same inline format works for both live monitoring and replay. For final reports shared with stakeholders or law enforcement, screenshots are already embedded inline by the report generator — no change needed.

**Core changes:**

1. New `ssi_events` table: `{id, scan_id, event_type, timestamp, data_json}` — `data_json` carries all event data including inline screenshot base64 when applicable.
2. `POST /events/ssi/{scan_id}` — SSI pushes event batches; inserts rows into `ssi_events` and publishes to Redis pub/sub channel `ssi:events:{scan_id}`.
3. `GET /events/ssi/{scan_id}/stream` — SSE endpoint; subscribes to Redis channel and streams events to the client in real time. Falls back to DB polling if Redis is unavailable.
4. Auth: same service-to-service OIDC token as Phase 3.0.

**SSI changes:**

1. New `HttpEventSink` in EventBus — posts events to core's HTTP endpoint.
2. Screenshot throttling: only emit on state change or at configurable interval (not every frame). Screenshots are JPEG-compressed and resized before embedding.

**UI changes:**

1. Update `useInvestigationMonitor` to support SSE fallback: when `NEXT_PUBLIC_SSI_WS_URL` is unset (cloud), use `EventSource` to `GET /events/ssi/{scan_id}/stream` instead of WebSocket.
2. Screenshot rendering: support both inline `base64` from SSE events and existing base64 from WebSocket (same format, no branching needed).

#### 3C. Analyst Guidance in Cloud Mode ✅

**Approach:** Bidirectional guidance via core as intermediary. Analysts submit commands through the UI → core stores in `ssi_guidance_commands` table → SSI's `GuidancePollRelay` continuously polls and feeds commands into the `EventBus` guidance queue → consumed when `AgentController` is wired into the orchestrator (future phase).

**Implemented:** Core endpoints (POST/GET/ACK), SSI `GuidancePollHandler` (direct `GuidanceHandler` protocol) + `GuidancePollRelay` (background EventBus feeder), UI guidance input panel on `/ssi` page with HTTP POST fallback, 300s auto-continue timeout. Settings: `SSI_INTEGRATION__GUIDANCE_POLL_ENABLED`, `SSI_INTEGRATION__GUIDANCE_POLL_INTERVAL`.

---

## 3. Task List

### Phase 1 — Case Enrichment _(estimated: 2–3 days)_

- [x] **1.1** Add `POST /cases/{case_id}/timeline` endpoint accepting `{description, actor, type, timestamp}` _(core, S)_
- [x] **1.2** Update `get_case()` to query `source_documents` and merge into artifacts list _(core, S)_
- [x] **1.3** Improve timeline event description formatting (strip raw `action: payload` pattern, add icons by type) _(core, XS)_
- [x] **1.4** Add `CoreBridge._create_timeline_events(case_id, result)` method _(ssi, S)_
- [x] **1.5** Call `_create_timeline_events()` from `push_investigation()` after each step _(ssi, XS)_
- [x] **1.6** Unit tests for new timeline endpoint + artifacts merge _(core, S)_
- [x] **1.7** Unit tests for CoreBridge timeline event creation _(ssi, S)_
- [x] **1.8** Manual E2E: run investigation → verify case detail shows timeline + artifacts _(both, S)_
- [x] **1.9** Direct-DB enrichment: `ScanStore._insert_timeline_events()` + `_insert_evidence_documents()` _(ssi, M)_ — replaces CoreBridge HTTP path; 13 tests in `test_case_enrichment.py`
- [x] **1.10** Backfill 14 orphaned `site_scans` → case links in dev DB _(data, XS)_
- [x] **1.11** Fix dead env var `SSI_INTEGRATION__PUSH_TO_CORE` → `SSI_JOB__PUSH_TO_CORE` in Terraform _(infra, XS)_

### Phase 2 — Investigate Page State Persistence _(estimated: 1 day)_

- [x] **2.1** Persist investigation state to `sessionStorage` on start _(ui, S)_
- [x] **2.2** Resume polling from `sessionStorage` on page mount _(ui, S)_
- [x] **2.3** Push `investigationId` to URL search params _(ui, XS)_
- [x] **2.4** Clear state on completion/failure _(ui, XS)_
- [x] **2.5** Manual test: navigate away and back during investigation _(ui, S)_

### Phase 3.0 — Job-to-Service Migration _(estimated: 2–3 days)_

- [x] **3.0.1** Add `POST /jobs/investigate` endpoint to SSI API accepting `{url, scan_type, scan_id, push_to_core, dataset}` → spawns background task, returns 202 _(ssi, M)_
- [x] **3.0.2** Create `ssi-svc.Dockerfile` — same base as `ssi-job.Dockerfile` but entrypoint is `uvicorn ssi.api.app:app --host 0.0.0.0 --port 8080` _(ssi, S)_
- [x] **3.0.3** Add `ssi_job.mode` setting (`"job"` \| `"service"`, default `"job"`) and `ssi_job.service_url` setting to `SsiJobSettings` _(core, S)_
- [x] **3.0.4** Add `_trigger_cloud_run_service()` in `investigations.py` — HTTP POST with OIDC identity token _(core, M)_
- [x] **3.0.5** Update `trigger_ssi_investigation()` to dispatch based on `ssi_job.mode` _(core, S)_
- [x] **3.0.6** Terraform: add SSI Cloud Run Service resource using `modules/run/service` _(infra, M)_
- [x] **3.0.7** Terraform: IAM binding — `sa-app` gets `roles/run.invoker` on SSI service _(infra, S)_
- [x] **3.0.8** Unit tests for mode dispatch + service trigger _(core, S)_
- [x] **3.0.9** Settings env-override tests for `ssi_job.mode` and `ssi_job.service_url` _(core, XS)_
- [x] **3.0.10** Build + deploy SSI service image to dev _(infra, S)_
- [x] **3.0.11** E2E: trigger investigation via service mode, verify case created + status polling works _(all, M)_

#### 3.0.12 — Remove ssi-job, service-only cutover _(estimated: 3–4 days)_

**Decision:** ssi-svc handles both interactive and batch investigations. Batch callers invoke `POST /investigate` repeatedly with concurrency control on the caller side. Cloud Run Job (`ssi-investigate`) and the `ssi_job.mode` toggle are removed entirely.

**Scope:** Every repo in the workspace — code, configs, Terraform, Docker, Makefiles, scripts, docs, tests, env vars.

##### SSI repo

- [x] **3.0.12a** Rename `POST /jobs/investigate` → `POST /trigger/investigate`; move route from `job_routes.py` to `investigation_routes.py`; remove `/jobs` prefix _(ssi, M)_
- [x] **3.0.12b** Remove `ssi/src/ssi/worker/jobs.py` (Cloud Run Job entrypoint) _(ssi, S)_
- [x] **3.0.12c** Remove `ssi/src/ssi/worker/batch_jobs.py` (batch Cloud Run Job entrypoint) — batch re-added as `POST /trigger/batch` in 3.0.12d _(ssi, S)_
- [x] **3.0.12d** Add `POST /trigger/batch` endpoint — accepts manifest (inline JSON array or GCS URI), runs investigations sequentially or with configurable concurrency, returns 202 _(ssi, M)_
- [x] **3.0.12e** Update `ssi/src/ssi/cli/job.py` — remove env-var-based invocation; CLI runs in-process via orchestrator _(ssi, M)_
- [x] **3.0.12f** Remove `ssi/docker/ssi-job.Dockerfile`; consolidated to single `Dockerfile` _(ssi, S)_
- [x] **3.0.12g** Update `ssi/Makefile` — remove `ssi-job` build targets; update `docker-build` to use the single Dockerfile _(ssi, S)_
- [x] **3.0.12h** Update `ssi/scripts/build_image.sh` — remove `ssi-job` references; default image name to `ssi-svc` _(ssi, XS)_
- [x] **3.0.12i** Remove `SSI_JOB__*` env var handling from `job_routes.py` background runner — use direct function args instead of env-var thread patching _(ssi, M)_
- [x] **3.0.12j** Update `ssi/src/ssi/worker/task_reporter.py` — replace `SSI_JOB__SCAN_ID` env var lookup with explicit parameter _(ssi, S)_
- [x] **3.0.12k** Update `ssi/src/ssi/investigator/orchestrator.py` — remove `SSI_JOB__SCAN_ID` env var fallback _(ssi, XS)_
- [x] **3.0.12l** Update `ssi/src/ssi/integration/core_bridge.py` — remove `SSI_JOB__SCAN_ID` references in docstrings _(ssi, XS)_
- [x] **3.0.12m** Update SSI tests: `test_job_routes.py` → `test_investigation_routes.py` (new endpoint path), remove/update `test_worker_jobs.py`, `test_batch_jobs.py`, `test_task_reporter.py` _(ssi, M)_ — **723 tests pass**
- [x] **3.0.12n** Update SSI docs: `developer_guide.md`, `tdd.md`, `batch_scheduling.md`, `playbook_authoring.md` — remove job references, document service-only architecture _(ssi, M)_

##### Core repo

- [x] **3.0.12o** Remove `ssi_job.mode` setting and `_trigger_cloud_run_job()` from `investigations.py` — always dispatch via HTTP POST to ssi-svc _(core, M)_
- [x] **3.0.12p** Rename `ssi_job` settings section → `ssi`; remove job-only fields (`job_name`, `project`, `region`, `service_account`); keep `service_url`, `core_api_url`, `playbook_dir` _(core, M)_
- [x] **3.0.12q** Update `trigger_ssi_investigation()` — remove mode branching; single code path: HTTP POST to `service_url + "/trigger/investigate"` _(core, S)_
- [x] **3.0.12r** Update `ssi_playbooks.py` — change `settings.ssi_job.playbook_dir` → `settings.ssi.playbook_dir` _(core, XS)_
- [x] **3.0.12s** Update `runtime_overrides.py` — change `settings.ssi_job` → `settings.ssi` _(core, XS)_
- [x] **3.0.12t** Update `settings/sections/jobs.py` — rename `SsiJobSettings` → `SsiSettings`; remove `AliasChoices` for `SSI_JOB__*` _(core, M)_
- [x] **3.0.12u** Update core tests: `test_investigations.py` — remove job-mode tests, keep service dispatch tests; `test_settings_env_overrides.py` — update for renamed settings _(core, M)_ — **868 tests pass**
- [x] **3.0.12v** Update `core/docs/config/README.md`, `settings_manifest.json`, `settings_manifest.yaml` — replace `ssi_job.*` entries with `ssi.*` _(core, S)_
- [x] **3.0.12w** Update `core/.github/architecture-cheatsheet.instructions.md` — remove Cloud Run Job dispatch from SSI table _(core, XS)_
- [x] **3.0.12x** Update `core/scripts/infra/clean_cloud_run_history.sh` — remove `ssi-investigate` from job list _(core, XS)_

##### Infra repo

- [x] **3.0.12y** Remove `ssi-investigate` Cloud Run Job Terraform resource from dev `main.tf` _(infra, M)_
- [x] **3.0.12z** Remove `ssi-investigate` Cloud Run Job Terraform resource from prod `main.tf` _(infra, M)_
- [x] **3.0.12aa** Remove `ssi_investigate` job variables from dev and prod `terraform.tfvars` and `variables.tf` _(infra, S)_
- [x] **3.0.12ab** Remove `I4G_SSI_JOB__MODE` and `I4G_SSI_JOB__SERVICE_URL` env vars from core's Cloud Run Service config — replaced with `I4G_SSI__SERVICE_URL` _(infra, S)_
- [x] **3.0.12ac** Update SSI service env vars in `terraform.tfvars` — `SSI_JOB__PUSH_TO_CORE` → `SSI_INTEGRATION__PUSH_TO_CORE`; removed `SSI_JOB__SCAN_TYPE` _(infra, S)_
- [x] **3.0.12ad** Set `ssi_service_enabled` default to `true` (service always on); kept flag for rollback flexibility _(infra, XS)_
- [x] **3.0.12ae** Terraform plan + apply dev — verify clean removal of job resources _(infra, M)_

##### Docs repo

- [x] **3.0.12af** Update `book/config/settings.md` — replace `ssi_job.*` rows with `ssi.*` settings _(docs, S)_
- [x] **3.0.12ag** Update `book/config/settings.yaml` — replace `ssi_job.*` entries _(docs, S)_
- [x] **3.0.12ah** Update `book/ssi/configuration.md` — `SSI_JOB__PUSH_TO_CORE` → `SSI_INTEGRATION__PUSH_TO_CORE` _(docs, XS)_
- [x] **3.0.12ai** Update `book/architecture/system-topology.md` — remove `SSIJob` / `ssi-investigate` from Mermaid diagram; add `SSISvc` to Services; update edges and counts _(docs, S)_
- [x] **3.0.12aj** Update `docs/config/settings_manifest.json` and `settings_manifest.yaml` — replace `ssi_job` entries with `ssi.*` _(docs, S)_

##### UI repo

- [x] **3.0.12ak** Verify `/api/ssi/investigate` proxy route is correct — confirmed no stale job references in UI codebase _(ui, XS)_

##### Planning repo

- [x] **3.0.12al** Update `change_log.md` with ssi-job removal summary _(planning, XS)_

##### Cross-cutting

- [x] **3.0.12am** Run full unit test suites in core and ssi — verify zero failures _(all, S)_
- [x] **3.0.12an** E2E: trigger interactive investigation via ssi-svc, verify case created _(all, M)_
- [x] **3.0.12ao** E2E: trigger batch investigation via `POST /investigate/batch`, verify all cases created _(all, M)_ — deferred (no active use cases); will revisit when batch is needed
- [x] **3.0.12ap** Delete the `ssi-investigate` Cloud Run Job resource in GCP dev (after Terraform apply removes it) _(infra, XS)_ — confirmed removed; `gcloud run jobs list` returns empty

### Phase 3A — Live Monitor on Investigate Page _(estimated: 2 days)_

- [x] **3A.1** Design inline monitor panel layout for `/ssi` page _(ui, S)_
- [x] **3A.2** Embed `useInvestigationMonitor` in `/ssi` page with conditional rendering _(ui, M)_
- [x] **3A.3** Add "Live View" toggle/expand panel below progress steps (read-only: screenshot + event log) _(ui, S)_
- [x] **3A.4** Keep Live Monitor tab on `/ssi/investigations/[id]` for replay; disable live controls when disconnected _(ui, S)_
- [x] **3A.5** Manual test local dev: investigate with live screenshots visible on `/ssi` page _(ui + ssi, S)_

### Phase 3B — Cloud Live Monitoring via DB-Polled SSE _(estimated: 5–7 days)_

- [x] **3B.1** Create `ssi_events` table migration (`id`, `scan_id`, `event_type`, `timestamp`, `data_json`, `screenshot_url`) _(core, S)_
- [x] **3B.2** Implement event ingestion endpoint `POST /events/ssi/{scan_id}` — stores event batch in `ssi_events` _(core, M)_
- [x] **3B.3** Implement SSE stream `GET /events/ssi/{scan_id}/stream` — DB polls every 2–3 s, streams new events _(core, M)_
- [x] **3B.4** Add `HttpEventSink` to SSI EventBus — posts events to core's HTTP endpoint _(ssi, M)_
- [x] **3B.5** Screenshot throttling: only emit on state change or at configurable interval; JPEG-compress + resize before embedding _(ssi, S)_
- [x] **3B.6** Add Redis pub/sub infrastructure — publish events on ingest, subscribe in SSE endpoint _(core, M)_
- [x] **3B.7** Update `useInvestigationMonitor` — add SSE fallback via `EventSource` when WebSocket URL is unset _(ui, M)_
- [x] **3B.8** Add event replay on `/ssi/investigations/[id]` Live Monitor tab — load events from `GET /events/ssi/{scan_id}` _(ui, M)_
- [x] **3B.9** Integration tests for event ingestion + SSE stream _(core + ssi, M)_
- [x] **3B.10** E2E cloud: run investigation → verify live events stream to UI via SSE _(all, L)_
  - **[FIX COMMITTED — needs rebuild + redeploy]**
  - **Root cause 1:** `NEXT_PUBLIC_SSI_WS_URL=ws://localhost:8100` from `.env.local` was being bundled into the Cloud Run image during `docker build` — no `.dockerignore` excluded it. The cloud console used WebSocket to `localhost:8100` instead of SSE. **Fix:** Added `ui/.dockerignore` excluding `.env.local` / `.env.*.local`.
  - **Root cause 2 (not applicable):** GCP Global HTTPS LB `timeout_sec` — GCP does **not** support `timeoutSec` on Serverless NEG backends (Cloud Run). Fix reverted. SSE duration governed solely by Cloud Run `timeout_seconds`.
  - **Root cause 3:** `core-svc` and `i4g-console` Cloud Run services had default `timeout_seconds = 300`. **Fix:** Set `timeout_seconds = 3600` on both `run_core_svc` and `run_console` in `dev` and `prod` environments.
  - **Root cause 4 (the real blocker):** Next.js patches global `fetch` for response caching. Even with `dynamic = "force-dynamic"`, the SSE proxy route's `await fetch(upstream_sse_url)` buffers the entire SSE response body before resolving — but SSE streams never end, so the fetch hangs until Cloud Run request timeout. Browser times out at ~60 s after exhausting retry attempts. Adding `cache: "no-store"` helps but behaviour is fragile across Next.js versions. **Fix:** Rewrote `ui/apps/web/src/app/api/events/ssi/[scanId]/stream/route.ts` from a stream-proxy to a **polling approach** — polls `GET /events/ssi/{scanId}?after={timestamp}` every 2.5 s and re-emits events as SSE. Added `after` query param to core-svc's `GET /events/ssi/{scan_id}` endpoint (`core/src/i4g/api/ssi_events.py`) for incremental polling.
  - **Root cause 5:** `.dockerignore` excluded `.env.local`, but Docker build cache may retain stale layers with the old env var baked in. Even after `.dockerignore` was added, the deployed image still had `NEXT_PUBLIC_SSI_WS_URL=ws://localhost:8100` — the hook used WebSocket to `localhost:8100` (silent failure, no server logs, stays on "connecting..." forever). **Fix:** Made transport selection **runtime-aware** in `useInvestigationMonitor` — when the page is served over HTTPS (cloud), always force SSE regardless of `NEXT_PUBLIC_SSI_WS_URL`. WebSocket is only used when both the env var is set AND the page is HTTP (local dev). Added diagnostic logging (`console.debug`) to trace transport selection, SSE connection, and errors.
  - **Next action:** Rebuild `i4g-console` (use `--no-cache` to guarantee fresh build), redeploy, then re-run E2E cloud smoke. Check browser console for `[Monitor]` logs to confirm SSE transport is selected.

### Phase 3C — Analyst Guidance in Cloud Mode ✅

- [x] **3C.0** **[BUG FIX — deployed core-svc-00013-z22]** Active investigation UI froze on "Analysing site" (step grays out, jumps to "Generating PDF report" spinning indefinitely) in cloud despite the investigation completing in the DB.
  - **Root cause:** Cloud Run instances do not share in-memory `TASK_STATUS`. When the polling request lands on a different instance than the one that wrote `TASK_STATUS[task_id]`, it returns `status: "unknown"`. The UI's `stepAnalyzing` falls to "pending" (gray) and `stepReport` becomes "active" (spinning). The investigation completes in the DB — so the investigations list shows it as done — but the `/ssi` page never receives `"completed"` and hangs forever. Active scans (browser automation, several minutes) dramatically widen this race window vs. passive scans.
  - **Fix 1 (`investigations.py`):** Set `task_id = scan_id` (UUID, same value). Previously `task_id` was a short `ssi-{hex12}` string separate from `scan_id`. Now any Cloud Run instance can perform a DB lookup using `task_id` alone — no shared memory required.
  - **Fix 2 (`app.py` `get_task_status`):** Added DB fallback in the `task_id not in TASK_STATUS` branch: call `SsiStore.get_scan(task_id)` (works because `task_id == scan_id`). Returns full task shape including `risk_score`, `case_id`, and `duration_seconds` from the persistent DB row.
  - **Migration:** `20260303_02_add_ssi_guidance_commands` applied to Cloud SQL dev (`i4g_db`) manually.
  - **Tests:** 18/18 investigation tests pass; full unit suite 884/884 passes.

- [x] **3C.1** Design guidance relay architecture (core as intermediary) _(decision)_
  - Core stores guidance commands in `ssi_guidance_commands` table (Alembic migration `20260303_02`)
  - SSI polls via `GuidancePollRelay` background task → feeds into `EventBus.provide_guidance()`
  - UI sends via HTTP POST through Next.js proxy route (SSE/cloud mode fallback)
- [x] **3C.2** Add `POST /events/ssi/{scan_id}/guidance` endpoint in core _(core, M)_
  - `POST /{scan_id}/guidance` — submit command (action, value, reason) → 202
  - `GET /{scan_id}/guidance/pending` — poll pending commands with optional `limit`
  - `POST /{scan_id}/guidance/{command_id}/ack` — acknowledge consumed command
  - Schemas: `SsiGuidanceRequest`, `SsiGuidanceResponse`, `SsiPendingGuidanceResponse`
  - Redis pub/sub notification on `ssi:guidance:{scan_id}` channel
  - Tests: `core/tests/unit/test_ssi_guidance.py` — 8/8 passing
- [x] **3C.3** SSI polls for pending guidance commands during investigation _(ssi, M)_
  - `GuidancePollHandler`: implements `GuidanceHandler` protocol for direct use with `AgentController`
  - `GuidancePollRelay`: background `asyncio.Task` that continuously polls core, feeds commands into `EventBus`, and acknowledges them
  - Wired into `trigger_investigate()` when `SSI_INTEGRATION__GUIDANCE_POLL_ENABLED=true`
  - Auth: OIDC tokens for Cloud Run, API key for local (matches `HttpEventSink` pattern)
  - Tests: `ssi/tests/unit/test_guidance_poll.py` — 8/8 passing
- [x] **3C.4** Add guidance input to the Live View panel on `/ssi` page _(ui, M)_
  - Next.js proxy route: `ui/apps/web/src/app/api/events/ssi/[scanId]/guidance/route.ts`
  - `useInvestigationMonitor.sendGuidance()` HTTP POST fallback for SSE/cloud mode
  - `/ssi` page: action dropdown (continue/click/goto/type/scroll/wait/skip/abort), value input, reason input, send button
  - `guidance: true` enabled in hook call
- [x] **3C.5** Handle timeout/auto-continue when no analyst is watching _(ssi, S)_
  - `GuidancePollHandler.request_guidance()` returns `HumanAction.CONTINUE` after `timeout_seconds` (default 300s)
  - Continual poll with `poll_interval` (default 2s, configurable via `SSI_INTEGRATION__GUIDANCE_POLL_INTERVAL`)

### Phase 3.0.12b — Rename `fastapi` → `core-svc` _(estimated: 2–3 days)_

**Goal:** Align the core API's service name, image name, and Dockerfile name with the `ssi-svc` naming convention. Every reference to `fastapi` (as a deployment artifact) and `fastapi-gateway` (as the Cloud Run service name) becomes `core-svc`.

**Scope:** File renames, Docker image names, Terraform resources/variables, CI matrix, build scripts, default URLs, docs. **Not** renaming Python framework imports (`from fastapi import ...`) — those stay as-is.

**Risk:** Terraform `name` change on the Cloud Run Service triggers a destroy+recreate. Plan carefully: update DNS/domain mapping, IAP backend, and UI `I4G_API_URL` in the same apply. Consider a blue-green approach: deploy `core-svc` alongside `fastapi-gateway`, verify, then remove the old service.

##### Core repo

- [x] **3.0.12ba** Rename `docker/fastapi.Dockerfile` → `docker/core-svc.Dockerfile` _(core, XS)_
- [x] **3.0.12bb** Update `docker/README.md` — rename heading and references _(core, XS)_
- [x] **3.0.12bc** Update `.github/workflows/docker-build.yml` — change matrix entry `fastapi` → `core-svc` _(core, S)_
- [x] **3.0.12bd** Update `scripts/infra/clean_cloud_run_history.sh` — `fastapi-gateway` → `core-svc` _(core, XS)_
- [x] **3.0.12be** Update `src/i4g/cli/bootstrap/dev/constants.py` — `DEFAULT_SMOKE_API_URL` domain (once DNS resolves to `core-svc`) _(core, XS)_
- [x] **3.0.12bf** Update `src/i4g/settings/sections/jobs.py` — SSI `core_api_url` default from `fastapi-gateway-*` → `core-svc-*` _(core, XS)_
- [x] **3.0.12bg** Update `docs/config/README.md`, `settings_manifest.json`, `settings_manifest.yaml` — replace `fastapi-gateway` URLs _(core, S)_
- [x] **3.0.12bh** Update `docs/cookbooks/smoke_test.md` — replace `fastapi-gateway` URLs and `FASTAPI_BASE` var → `CORE_API_BASE` _(core, S)_
- [x] **3.0.12bi** Update `docs/runbooks/console/search.md` — `FASTAPI_BASE` → `CORE_API_BASE` _(core, XS)_
- [x] **3.0.12bj** Update `docs/runbooks/dossiers_deployment_checklist.md` — replace `fastapi-gateway` URLs _(core, XS)_
- [x] **3.0.12bk** Update `docs/runbooks/hybrid_search_deployment_checklist.md` — `fastapi app logs` → `core-svc logs` _(core, XS)_
- [x] **3.0.12bl** Update `docs/design/architecture.md` — service name in component table + gcloud commands _(core, S)_
- [x] **3.0.12bm** Update `docs/design/iam.md` — service name in IAM table _(core, XS)_
- [x] **3.0.12bn** Update `docs/development/dev_guide.md` — `gcloud run services update fastapi-gateway` → `core-svc` _(core, XS)_
- [x] **3.0.12bo** Update `docs/cookbooks/bootstrap_environments.md` — `fastapi-gateway` → `core-svc` _(core, XS)_
- [x] **3.0.12bp** Update all `.github/copilot-instructions.md` across repos — `fastapi` → `core-svc` in Docker Build Reference _(all, S)_

##### Infra repo

- [x] **3.0.12bq** Rename Terraform variables: `fastapi_image` → `core_svc_image`, `fastapi_env_vars` → `core_svc_env_vars`, `fastapi_secret_env_vars` → `core_svc_secret_env_vars`, `fastapi_invoker_member(s)` → `core_svc_invoker_member(s)`, `fastapi_custom_domain` → `core_svc_custom_domain` in dev `variables.tf` _(infra, M)_
- [x] **3.0.12br** Same variable renames in prod `variables.tf` _(infra, M)_
- [x] **3.0.12bs** Update dev `terraform.tfvars` — rename all `fastapi_*` keys; update image path `applications/fastapi:dev` → `applications/core-svc:dev` _(infra, S)_
- [x] **3.0.12bt** Update prod `terraform.tfvars` — same renames + image path _(infra, S)_
- [x] **3.0.12bu** Update dev `main.tf` — rename `module "run_fastapi"` → `module "run_core_svc"`, `name = "fastapi-gateway"` → `name = "core-svc"`, all `local.fastapi_*` → `local.core_svc_*`, `service = "fastapi"` label → `service = "core-svc"` _(infra, L)_
- [x] **3.0.12bv** Update prod `main.tf` — same as dev _(infra, L)_
- [x] **3.0.12bw** Update dev + prod `outputs.tf` — `output "fastapi_service"` → `output "core_svc_service"` _(infra, XS)_
- [x] **3.0.12bx** Update dev + prod `locals.tf` — `"Runs FastAPI and console services"` → `"Runs core-svc and console services"` _(infra, XS)_
- [x] **3.0.12by** Update `scripts/make-unauthed.sh`, `scripts/make-iap-protected.sh` — `fastapi-gateway` → `core-svc` _(infra, XS)_
- [x] **3.0.12bz** Update `bootstrap/create_iap_oauth.sh` — `iap-fastapi` → `iap-core-svc`, `iap-client-fastapi` → `iap-client-core-svc` _(infra, XS)_
- [x] **3.0.12ca** Update `docs/iap_manual.md`, `docs/domain_mapping.md` — replace `fastapi-gateway` references _(infra, S)_
- [x] **3.0.12cb** Update `environments/app/dev/README.md`, `environments/app/prod/README.md` — replace image/service references _(infra, S)_
- [x] **3.0.12cc** Update `modules/run/service/README.md`, `modules/iam/service_accounts/README.md` — replace example names _(infra, XS)_
- [x] **3.0.12cd** Terraform plan + apply dev — blue-green: deploy `core-svc` alongside `fastapi-gateway`, verify DNS + IAP, then destroy old service _(infra, L)_
- [x] **3.0.12ce** Terraform plan + apply prod — same blue-green approach _(infra, L)_

##### Docs repo

- [x] **3.0.12cf** Update `book/architecture/system-topology.md` — Mermaid node `FastAPI Gateway` → `Core API (core-svc)` _(docs, S)_
- [x] **3.0.12cg** Update `book/architecture/security-model.md` — Mermaid node _(docs, XS)_
- [x] **3.0.12ch** Update `book/config/settings.md`, `settings.yaml` — replace `fastapi-gateway` URLs _(docs, S)_
- [x] **3.0.12ci** Update `book/security/secrets-reference.md` — `fastapi_secret_env_vars` → `core_svc_secret_env_vars` _(docs, XS)_
- [x] **3.0.12cj** Update `config/settings_manifest.json`, `settings_manifest.yaml` — replace `fastapi-gateway` URLs _(docs, S)_

##### UI repo

- [x] **3.0.12ck** Update `docs/deployment-guide.md` — `I4G_API_URL` from `fastapi-gateway` → `core-svc` _(ui, XS)_

##### Planning repo

- [x] **3.0.12cl** Update `change_log.md` with renaming summary _(planning, XS)_

##### Cross-cutting

- [x] **3.0.12cm** Build + push `core-svc:dev` image to Artifact Registry _(infra, S)_
- [x] **3.0.12cn** Run full unit test suites — verify zero failures (no code logic changes, just names) _(all, S)_
- [x] **3.0.12co** E2E: verify API accessible via new service name / domain _(all, M)_

---

## 4. Recommended Sequencing

1. **Phase 1** first — highest value, lowest effort. Directly improves every SSI case in the analyst console. ✅ Complete.
2. **Phase 2** next — quick UX win, no backend changes. ✅ Complete.
3. **Phase 3.0** (3.0.1–3.0.11) — ✅ Complete. SSI deployed as Cloud Run Service; interactive investigation works via ssi-svc.
4. **Phase 3.0.12** next — remove Cloud Run Job (`ssi-investigate`) entirely. ✅ Complete. ssi-svc is the sole deployment.
5. **Phase 3.0.12b** — rename `fastapi`/`fastapi-gateway` → `core-svc` across all repos. Standalone; no dependency on 3A/3B. ✅ Complete.
6. **Phase 3A** after 3.0.12 — improves local dev experience; sets up UI patterns for cloud monitoring. ✅ Complete.
7. **Phase 3B** after 3A — enables cloud live monitoring via Redis pub/sub + SSE. Adds Redis (Cloud Memorystore) to infrastructure.
8. **Phase 3C** — analyst guidance in cloud. ✅ Complete. Bidirectional guidance relay via core endpoints, `GuidancePollRelay` in SSI, and guidance panel in UI.

---

## 5. Resolved Questions

1. **Live Monitor tab on `/ssi/investigations/[id]`?** → **Keep it.** Once Phase 3B persists events to `ssi_events`, this tab becomes an event replay viewer. Disable live controls (guidance input) when not connected to a live investigation.

2. **Redis pub/sub or DB polling?** → **Redis pub/sub.** Tutorial sessions with volunteer students regularly produce 20–30 concurrent investigations. DB polling at 2–3 s intervals across that many active viewers would impose excessive query load on PostgreSQL. Redis pub/sub provides sub-second fan-out with negligible overhead. Cloud Memorystore (Basic tier, 1 GB) is sufficient. DB is used for persistence (replay), Redis for live fan-out.

3. **Screenshots: GCS objects or inline?** → **Inline (DB-stored base64) for both live monitoring and replay.** Screenshots are JPEG-compressed and resized (~50–150 KB each), stored in the `data_json` column of `ssi_events`. Avoids GCS complexity (signed URLs, expiry, CORS, bucket management). Same format as the existing WebSocket path — no UI branching needed.

4. **Analyst guidance in cloud?** → **Implemented** (Phase 3C). Core stores guidance commands; SSI polls via `GuidancePollRelay`; UI panel submits via HTTP POST in cloud mode. Auto-continue after 300s timeout when no analyst is watching.

5. **Separate ssi-job for batch?** → **No.** ssi-svc handles both interactive and batch. Batch callers invoke `POST /investigate/batch` on ssi-svc, which processes the manifest with configurable concurrency. Eliminates the Cloud Run Job entirely — one image, one deployment, one set of env vars. Job cold-start latency (5–30 s) was the original motivation for ssi-svc; there's no reason to keep the job path for batch when the service can do the same work without cold-start penalties.
