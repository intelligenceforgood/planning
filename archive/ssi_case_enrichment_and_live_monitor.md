# SSI Case Enrichment & Live Monitor — Archive

**Completed:** 2026-03-03 | **Status:** All phases done ✅

---

## What Was Built

Five phases fixing two root problems: (1) SSI-created cases had empty timelines and artifacts in the analyst console, and (2) the live monitor was broken in cloud deployments.

### Phase 1 — Case Enrichment ✅

**Problem:** Timeline and Artifacts cards empty on SSI cases.
**Design:** Direct DB writes via `ScanStore._insert_timeline_events()` and `_insert_evidence_documents()` — skipped the CoreBridge HTTP path entirely. Artifacts card fixed by querying `source_documents` in `get_case()` instead of relying on `metadata.files`.

### Phase 2 — Investigate Page State Persistence ✅

**Problem:** Navigating away from `/ssi` during an investigation lost all polling state.
**Design:** `sessionStorage` + URL search param (`?investigationId=`) for resumption on page remount. No backend changes needed.

### Phase 3.0 — Job→Service Migration + Rename ✅

**Problem:** SSI ran as an ephemeral Cloud Run Job — no persistent WebSocket/SSE endpoints possible.
**Design:** Deployed SSI as `ssi-svc` (Cloud Run Service, CPU always allocated). `POST /trigger/investigate` replaces the job dispatch. Service-to-service auth via Google OIDC tokens — no custom middleware. Cloud Run Job (`ssi-investigate`) removed entirely. Renamed `fastapi-gateway` → `core-svc` across all repos simultaneously.

### Phase 3A — Live View on Investigate Page ✅

Embedded `useInvestigationMonitor` hook + screenshot/event panel directly on `/ssi` page alongside progress steps. Investigation detail page (`/ssi/investigations/[id]`) kept as event replay viewer.

### Phase 3B — Cloud Live Monitoring via SSE ✅

**Architecture:** SSI → `POST /events/ssi/{scan_id}` (HTTP batches) → core stores in `ssi_events` table + publishes to Redis pub/sub → `GET /events/ssi/{scan_id}/stream` fans out to browser via SSE. DB polling fallback when Redis unavailable.

**Key decisions:**

- **Screenshots:** Inline base64 in `ssi_events.data_json` (~50–150 KB JPEG). Avoids GCS signed URL complexity; same format as existing WebSocket path.
- **Redis pub/sub:** Needed for 20–30 concurrent investigations (tutorial sessions). DB polling at 2 s × 30 viewers would overload PostgreSQL.

**Critical bugs fixed during E2E:**

1. `.env.local` was baking `NEXT_PUBLIC_SSI_WS_URL=ws://localhost:8100` into the Docker image (no `.dockerignore`). Fix: added `.dockerignore`; made transport selection runtime-aware (HTTPS → always SSE).
2. Next.js `fetch()` buffers SSE responses before resolving — breaking the stream-proxy approach. Fix: rewrote the Next.js proxy route as a **polling forwarder** (`GET /events/ssi/{scanId}?after={ts}` every 2.5 s, re-emit as SSE).
3. Cloud Run `timeout_seconds` defaulted to 300. Fix: set 3600 on `core-svc` and `i4g-console`.

### Phase 3C — Guidance Relay in Cloud Mode ✅

**Problem:** Analysts could observe cloud investigations but not guide them (no shared WebSocket).
**Design:** Core as intermediary — `ssi_guidance_commands` table stores commands; SSI's `GuidancePollRelay` (background `asyncio.Task`) polls `GET /events/ssi/{scan_id}/guidance/pending` every 2 s and feeds commands into `EventBus.provide_guidance()`. UI sends via `sendGuidance()` HTTP POST through Next.js proxy route. Auto-continue after 300 s if no analyst responds.

**Bug fixed (TASK_STATUS race):** Cloud Run instances don't share in-memory `TASK_STATUS`. Fix: `task_id = scan_id` (UUID). `get_task_status()` falls back to `SsiStore.get_scan(task_id)` when the key is missing from memory — works across any instance.

**New env vars:** `SSI_INTEGRATION__GUIDANCE_POLL_ENABLED` (default `false`), `SSI_INTEGRATION__GUIDANCE_POLL_INTERVAL` (default `2.0 s`).

---

## Key Files

| Area            | Files                                                                                             |
| --------------- | ------------------------------------------------------------------------------------------------- |
| Core endpoints  | `api/ssi_events.py`, `api/investigations.py`, `api/app.py`                                        |
| Core store      | `store/ssi_events_store.py`, `store/sql.py`                                                       |
| Core migration  | `migrations/versions/20260303_02_add_ssi_guidance_commands.py`                                    |
| SSI monitoring  | `monitoring/guidance_poll_handler.py`, `monitoring/http_event_sink.py`, `monitoring/event_bus.py` |
| SSI routes      | `api/investigation_routes.py`                                                                     |
| UI hook         | `lib/use-investigation-monitor.ts`                                                                |
| UI proxy routes | `app/api/events/ssi/[scanId]/stream/route.ts`, `.../guidance/route.ts`                            |
| UI page         | `app/(console)/ssi/page.tsx`                                                                      |
