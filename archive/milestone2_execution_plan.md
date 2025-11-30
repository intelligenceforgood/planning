# Milestone 2 Execution Plan – Dual Extraction Pipeline

Use this working doc to track Milestone 2 end-to-end. Update status and notes as tasks move forward so context survives across sessions.

| Task | Owner | Status | Notes / Next Steps |
| --- | --- | --- | --- |
| Finalize dual-extraction schema (ERD + SQL migrations) | Jerry | ✅ Complete | SqlWriter metadata + Alembic migrations merged; SQLite + dev schemas created during dual-write rollout. |
| Define Vertex document contract updates | Jerry | ✅ Complete | `prepare_ingest_payload` now emits dataset/categories/indicator_ids, worker + Vertex CLI accept default dataset, docs updated with contract + `--dataset` flag. |
| Update ingestion worker to fan-out writes (Firestore + Vertex + SQL) | Jerry | ✅ Complete | Pipeline now dual-writes SQL + Firestore + Vertex, run tracker increments each counter, and `_maybe_enqueue_retry` captures payload/context for the ingestion retry queue + worker. |
| Local fan-out smoke | Jerry | ✅ Complete | Vector-enabled `i4g-ingest-job` run (50 cases) wrote SQL + embeddings, `scripts/verify_ingestion_run.py` asserts tracker rows, and a forced Firestore failure (run `26ff94bf-4128-45f6-834f-d4e04658841d`) seeded the retry queue. Drained the queue via the Firestore emulator + `python -m i4g.worker.jobs.ingest_retry`, then confirmed `No ingestion retry entries ready` and captured the flow in the smoke guide. |
| Dev environment backfill | Jerry | ✅ Complete | Ingestion run `01993af5-09ab-4ecf-b0c8-cd86702b8edd` processed all 200 cases in `retrieval_poc_dev`, dual-wrote SQL + Firestore, hit Vertex quota (155 live writes), and drained 45 queued retries via `python -m i4g.worker.jobs.ingest_retry`. Logged results in `planning/change_log.md`. |
| Documentation + runbook updates | Jerry | ✅ Complete | Roadmap, architecture, and smoke-test runbooks now cover the dev backfill results, Vertex quota behavior, and retry-drain procedure; remaining config docs will pick up changes as future settings land. |

_Last updated: 30 Nov 2025_
