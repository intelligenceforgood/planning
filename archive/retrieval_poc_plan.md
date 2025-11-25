# Retrieval Proof-of-Concept Plan

## Objectives
- Compare two backends (Vertex AI Search vs AlloyDB + pgvector) on relevance, latency, and operational fit.
- Produce metrics and qualitative findings to support the Milestone 2 decision.
- Document setup steps so we can reproduce or extend the PoC later.

## Evaluation Criteria
- **Relevance/Quality**: Top-k match rate against the tagged evaluation set (precision@5, MRR).
- **Latency**: Median and P95 response times for vector-only and hybrid queries.
- **Cost**: Estimated monthly spend under projected load.
- **Ops Complexity**: Setup/maintenance effort, Terraform integration, CI/CD implications.
- **Fallback Story**: Ease of switching to open/self-hosted alternative if credits expire.

## Dataset & Queries
- Source: Synthetic, de-identified corpus generated via `python scripts/prepare_retrieval_dataset.py` (outputs to `data/retrieval_poc/`, 200 records across six scam archetypes).
- Queries: Ground-truth-aligned prompts emitted alongside the dataset in `data/retrieval_poc/ground_truth.yaml`.
- Ground truth: Maintained YAML file mapping queries → relevant case IDs, regenerates with the dataset manifest.

## Environments
- **i4g-dev** project for managed trials (Vertex AI Search, Firestore snapshots, Cloud Run clients).
- **Local/Containerised** environment for AlloyDB + pgvector (using Cloud SQL Auth Proxy or local docker-compose) to mirror managed AlloyDB where possible.

## Work Breakdown
1. **Dataset Preparation**
   - Generate/update synthetic corpus and manifest (`scripts/prepare_retrieval_dataset.py`).
   - Normalise to JSONL schema (`case_id`, `summary`, `text`, `entities`, `tags`, `timestamp`, `structured_fields`).
   - Regenerate aligned ground-truth YAML for the evaluation harness.
2. **Vertex AI Search PoC**
   - Enable Vertex AI Search API in `i4g-dev` (Terraform or console).
   - Ingest dataset via Document AI / Search indexing pipeline.
   - Stand up test client (Python script) to issue vector + hybrid queries.
   - Capture latency metrics and compute relevance scores against ground truth.
3. **AlloyDB + pgvector PoC**
   - Provision AlloyDB cluster or simulate with Cloud SQL Postgres + pgvector (using Terraform module when ready).
   - Create schema/table for embeddings; backfill dataset with precomputed vector embeddings (use `text-embedding-004` or local model).
   - Implement search endpoint (Python CLI) that performs ANN search and optional structured filters.
   - Record latency metrics and relevance scores.
4. **Evaluation Harness**
   - Build a reusable script (`tests/adhoc/evaluate_retrieval.py`) that runs each query against both backends, logs precision@k, MRR, and latency.
   - Export results to CSV/Markdown for inclusion in planning docs.
5. **Analysis & Decision Record**
   - Summarise findings in `future_architecture.md` retrieval section.
   - Update Outstanding Decisions register with final choice, owner (Jerry), decision date, and rationale.

## Timeline (Target)
- Dataset prep + ground truth: 2 days.
- Vertex AI Search trial: 2–3 days (including indexing).
- AlloyDB + pgvector trial: 3–4 days (setup + tuning).
- Evaluation harness + analysis: 2 days.
- Total: ~2 weeks of focused effort within Milestone 2.

## Dependencies
- Access to anonymised case data and transcripts.
- Google Cloud credits for Vertex AI Search trial.
- Terraform modules for enabling required APIs/services (Vertex AI Search, AlloyDB) or manual console enablement until modules exist.

## Next Steps
1. Sanity-check generated corpus coverage (`data/retrieval_poc/cases.jsonl`) and adjust templates if gaps appear.
2. Enable Vertex AI Search API in `i4g-dev` (terraform module or new `google_project_service`).
3. Draft ingestion script(s) for both backends leveraging the new dataset + ground truth artifacts.
4. Begin embedding generation/export flow so AlloyDB + pgvector ingest can start immediately after provisioning.
