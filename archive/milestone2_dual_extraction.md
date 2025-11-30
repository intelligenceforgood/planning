# Milestone 2 – Dual Extraction Pipeline

**Status:** Planning
<br />
**Date:** 29 Nov 2025

This milestone delivers the dual-write ingestion architecture so every extracted entity lands in Firestore (case context), Vertex AI Search (semantic retrieval), and Cloud SQL/AlloyDB (structured analytics). It builds on the Milestone 1 account list foundation and unlocks hybrid search in Milestone 3.

---

## 1. Goals & Success Criteria

1. **Schema Alignment** – Finalize SQL schemas (entities, indicators, relationships) and the Vertex document contract so both stores share consistent metadata.
2. **Ingestion Upgrades** – Enhance `i4g.worker` jobs to extract entities once and fan out writes to Firestore + Vertex + SQL with retry/backoff semantics.
3. **Backfill & Validation** – Run the new pipeline against the existing sandbox bundles (`data/entities_semantic.json`, `data/bundles/*.jsonl`) and capture validation metrics in the change log.

Success = ingestion artifacts simultaneously populate Vertex + SQL, and the review API can read from either store without code changes.

---

## 2. Work Breakdown (Draft)

| Task | Owner | Notes |
| --- | --- | --- |
| Define SQL schema + migrations | Jerry | Tables for `entities`, `indicators`, `source_documents`, plus indexes for case/date lookups. |
| Vertex document mapping | Jerry | Extend `scripts/ingest_vertex_search.py` to emit the new metadata contract (datasets, categories, indicator IDs). |
| Worker fan-out design | Jerry | Update `i4g.worker.jobs.ingest` + helpers to call Firestore + Vertex + SQL within a transactional envelope (best-effort with retries). |
| Local smoke harness | TBD | Adhoc script to run ingestion over sample bundles and verify counts across all three stores. |
| Dev backfill run | TBD | Execute ingestion in `i4g-dev`, record metrics/artifacts in `planning/change_log.md`. |

---

## 3. Open Questions

1. **SQL Target** – Confirm whether dev uses SQLite/Postgres locally before Cloud SQL/AlloyDB is provisioned.
2. **Vertex Limits** – Validate current quota for document updates to avoid throttling during backfill.
3. **Telemetry** – Decide where to log per-store write results (structured logs vs. ReviewStore actions) for quick triage.

---

## 4. Next Actions

1. Draft the detailed schema (ERD + migration scripts) and circulate for review.
2. Prototype the ingestion fan-out in local mode (SQLite + Vertex mock) to de-risk concurrency.
3. Update `planning/change_log.md` with schema decisions and ingestion test results as they land.
