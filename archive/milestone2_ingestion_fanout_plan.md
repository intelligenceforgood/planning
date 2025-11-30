# Milestone 2 – Ingestion Fan-Out Plan

_Last updated: 29 Nov 2025_

## 1. Objectives
- Extend the ingestion worker so every classified case persists to three backends: Firestore, Vertex AI Search, and SQL.
- Keep the pipeline idempotent and resumable: a failed backend must not corrupt others, and retries need clean handoffs.
- Provide feature flags/toggles for each backend so devs can isolate issues (e.g., `I4G_INGEST__ENABLE_VERTEX`, `I4G_INGEST__ENABLE_SQL`).
- Add instrumentation + audits so analysts can trace which store failed per case/run.

## 2. Current State
- `IngestPipeline` writes to the structured store (SQLite) and optionally to the vector store (Chroma) via `build_structured_store` and `build_vector_store`.
- Firestore persistence currently happens via `ReviewStore` pathways, not the ingestion worker.
- Vertex doc ingestion is handled by separate scripts (`scripts/ingest_vertex_search.py`).
- There is no central coordinator ensuring all three stores stay in sync per case.

## 3. Target Architecture
```
prepare_ingest_payload(record)
        ↓
IngestFanoutCoordinator
        ├─ StructuredWriter (SQL)
        ├─ FirestoreWriter
        └─ VertexWriter
```
- Each writer implements `persist(payload: IngestPayload) -> FanOutResult` with metadata (writes, warnings, errors).
- Coordinator aggregates results, handles retries, and publishes `FanOutSummary` per case + aggregates per run.

## 4. Execution Flow
1. Worker loads JSONL record → `prepare_ingest_payload` (already produces consistent dict + diagnostics).
2. Coordinator writes to SQL first (transactional). On success, passes the canonical case/indicator IDs to Firestore + Vertex so they share IDs.
3. Firestore writer upserts case/doc/entity/indicator subcollections. Use batch writes (≤500 per batch) and commit sequentially.
4. Vertex writer builds documents from `source_documents` payload, chunking text and embedding metadata (per schema contract). Writes through Vertex API with exponential backoff (5 retries, jitter).
5. Each writer emits `FanOutResult(status, warnings, retryable)` so the coordinator can decide whether to retry immediately, skip, or fail the run.

## 5. Feature Flags & Settings
- `I4G_INGEST__ENABLE_SQL` (default true)
- `I4G_INGEST__ENABLE_FIRESTORE` (default false local)
- `I4G_INGEST__ENABLE_VERTEX` (default false local)
- `I4G_INGEST__MAX_RETRIES` (default 3) – per case per backend
- `I4G_INGEST__FANOUT_TIMEOUT_SECONDS` – upper bound for each backend call
- Settings exposed via `Settings.ingest` dataclass; environment overrides documented in `docs/config/ingest.md` (to create/update).

## 6. Failure Handling
- Coordinator tracks per-case attempt counts. On failure:
  - If SQL fails → stop processing that case (do not attempt Firestore/Vertex). Flag run as failed.
  - If Firestore or Vertex fails but SQL succeeds → log warning, enqueue retry entry in `ingestion_retry_queue` (new table) with payload pointer (case ID + JSON blob). Continue with next case.
- At end of run, coordinator emits summary: counts per backend, number of retries scheduled, fatal errors.
- Add `i4g.ingest.retry` CLI command/job to drain `ingestion_retry_queue` (runs in background or scheduled job).

## 7. Telemetry & Audit Logging
- Extend `ingestion_runs` table (already planned) with per-store counters and `last_error` text.
- Emit structured logs per case: `fanout.case` with fields `case_id`, `sql_status`, `firestore_status`, `vertex_status`, `retry_scheduled`.
- Publish aggregated metrics via Prometheus-style counters (fastapi metrics exporter) once available; for now, ensure Cloud Logging entries exist.

## 8. Implementation Tasks
1. **Settings**: add ingest toggles/limits in `i4g/settings.py` + tests under `tests/unit/settings/test_ingest.py`.
2. **Coordinator module** (`src/i4g/services/ingest/fanout.py`): encapsulate writer orchestration, common retry logic, metrics accrual.
3. **Writers**:
   - `SqlWriter`: consumes new schema tables, exposes helper to create/update cases, docs, entities, indicators, indicator_sources.
   - `FirestoreWriter`: uses existing Firestore client, batch writes, handles document versioning + subcollections per contract.
   - `VertexWriter`: wraps Vertex AI Search import/upsert calls with chunking helper; optionally uses mock backend locally.
4. **Retry queue**: new SQL table or reuse Firestore? Proposed: SQL table `ingestion_retry_queue` with columns `(id, case_id, payload_json, backend, attempt_count, next_attempt_at)`.
5. **Worker update** (`src/i4g/worker/jobs/ingest.py`): instantiate coordinator with writers based on toggles, track per-run summary, persist to `ingestion_runs` when job completes.
6. **CLI/Job**: add `i4g-ingest-retry-job` entrypoint to drain retry queue (can run as Cloud Run job scheduled hourly).
7. **Docs**: update `docs/architecture.md`, `docs/smoke_test.md`, and change log with fan-out behavior.

## 9. Testing Plan
- **Unit tests** for each writer (mocking external clients) verifying success/failure paths and payload transformations.
- **Integration tests** using SQLite + Firestore emulator + Vertex mock to run a full ingest of `data/bundles/account_list_smoke.jsonl`.
- **Load test** (adhoc) to verify Firestore batch behavior with 500+ documents per case.
- **Retry tests** ensuring `ingestion_retry_queue` drains correctly and respects `next_attempt_at`.

## 10. Risks / Open Questions
- Vertex API quotas during backfill: need rate limiting (50 QPS default) and chunk batching to avoid 429s.
- Firestore emulator vs. production differences (indexes, TTL). Document manual steps to create necessary composite indexes.
- SQL transaction boundaries: should we wrap per-case operations in a transaction? (Likely yes to keep case/doc/entity/indicator consistent.)
- Consider streaming logs to TASK_STATUS map so `/tasks/{id}` API surfaces fan-out progress to analysts.
