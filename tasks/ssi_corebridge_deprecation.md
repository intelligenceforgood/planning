# SSI CoreBridge Deprecation

**Created:** 2026-02-28
**Status:** In Progress — partial migration done, deployment pending

---

## Context

`CoreBridge` (`ssi/src/ssi/integration/core_bridge.py`) uses HTTP calls to the
core API to push SSI investigation results (cases, evidence, entities, timeline
events, dossier triggers). This fails with **403 Forbidden** in GCP because the
SSI Cloud Run Job service account cannot authenticate through IAP to reach core's
load-balanced API.

The correct pattern is **direct database writes** to the shared Cloud SQL
instance, which both SSI and core already connect to.

## Completed

- [x] `worker/jobs.py` — replaced `CoreBridge.push_investigation()` with
      `ScanStore.create_case_record()` for case/scam_record/review_queue creation.
- [x] `worker/task_reporter.py` — replaced HTTP POST to
      `/tasks/{task_id}/update` with `ScanStore.update_scan()` for status reporting.
- [x] Added `DeprecationWarning` to `CoreBridge.__init__()`.
- [x] All tests pass: core 859, SSI 726.

## Remaining Callers

| Caller                 | File                                   | Context                     | Risk                        |
| ---------------------- | -------------------------------------- | --------------------------- | --------------------------- |
| `_push_to_core`        | `ssi/src/ssi/api/routes.py:190`        | SSI API service (Cloud Run) | **High** — same IAP 403     |
| `_push_result_to_core` | `ssi/src/ssi/worker/batch_jobs.py:241` | Batch Cloud Run Job         | **High** — same IAP 403     |
| `_push_to_core_cli`    | `ssi/src/ssi/cli/investigate.py:312`   | Local CLI                   | **Low** — targets localhost |

## Features Not Yet Covered by Direct DB

These CoreBridge capabilities don't have direct-DB equivalents yet:

1. **Evidence attachment** — `_attach_evidence()` uploads files to
   `POST /cases/{id}/evidence` → `source_documents` table. Needs a new
   `ScanStore.attach_evidence()` method or direct `source_documents` insert.
2. **Entity/indicator creation** — `_create_entities()`,
   `_create_wallet_indicators()`, `_create_osint_entities()` POST to
   `/cases/{id}/entities/batch` and `/cases/{id}/indicators/batch`. Need direct
   inserts into `entities` / `indicators` tables.
3. **Timeline events** — `_create_timeline_events()` POSTs to
   `/cases/{id}/timeline`. Need direct inserts into `review_actions`.
4. **Classification update** — `_store_classification()` PATCHes
   `/cases/{id}`. Already partially handled by `create_case_record()` which sets
   `classification_result` and `risk_score` on the cases row.
5. **Dossier trigger** — `_trigger_dossier()` POSTs to `/dossier/queue`. This
   is a control-plane action (launching another Cloud Run Job), not a DB write.
   May need a Pub/Sub or Cloud Tasks trigger instead.

## Migration Plan

1. **Deploy current fixes** — build + push new SSI job image so
   `_create_case_direct` and DB-backed `TaskStatusReporter` run in cloud.
2. **Migrate `routes.py` and `batch_jobs.py`** — replace their
   `CoreBridge.push_investigation()` calls with `ScanStore.create_case_record()`.
3. **Add evidence/entity/timeline direct-DB methods** to `ScanStore` so the
   migrated callers retain full functionality.
4. **Remove CoreBridge** once all callers are migrated and verified in cloud.

## Priority

**Medium** — The primary job path (`worker/jobs.py`) is already fixed. The
remaining callers (`routes.py`, `batch_jobs.py`) are secondary paths that are
also broken in cloud for the same IAP reason. Fix them when working on SSI API
service or batch job features.
