# ML Platform — Phase 0 Summary (Archived)

> **Completed:** 2026-03-21 | **PRD:** [prd_ml_infrastructure.md](../prd_ml_infrastructure.md) | **TDD:** [ml/docs/design/ml_infrastructure_tdd.md](../../ml/docs/design/ml_infrastructure_tdd.md)

## What Was Built

**Goal:** Stand up ML platform end-to-end with a stub classification model. Prove pipeline completeness; model quality deferred to Phase 1.

**Repos touched:** `ml/` (new), `infra/`, `core/`

### Infrastructure (i4g-ml GCP project)

- `sa-ml-platform` service account with cross-project IAM (Cloud SQL read from i4g-dev, aiplatform.user grants for core SAs)
- GCS bucket `i4g-ml-data`, Artifact Registry `containers`, BigQuery dataset `i4g_ml`
- BigQuery tables: `raw_cases`, `raw_entities`, `raw_analyst_labels`, `features_case_features`, `predictions_prediction_log`, `predictions_outcome_log`, `training_dataset_registry`, `analytics_model_performance`
- Vertex AI Endpoints: `serving-dev`, `serving-prod`
- Terraform: `infra/stacks/ml/`, `infra/environments/ml/`, cross-project IAM in `infra/stacks/app/`

### ML Repo (`ml/`)

- **Data:** ETL incremental sync (Cloud SQL → BigQuery `raw.*`), feature view `v_case_features`, dataset versioning with stratified splits
- **Training:** KFP v2 pipeline (prepare → train → evaluate → register → deploy), PyTorch (Gemma 2B LoRA) and XGBoost containers
- **Serving:** FastAPI container (`/predict/classify`, `/feedback`, `/health`), deployed to Vertex AI Endpoint
- **Registry:** Model promotion workflow (experimental → candidate → champion) with eval gate (F1 threshold, no per-axis regression > 5%)
- **Monitoring:** Prediction/outcome logging to BigQuery, drift detection stubs
- **ETL Cloud Run Job:** `etl-ingest`, daily at 2 AM UTC

### Core Integration (`core/`)

- `analyst_labels` Alembic migration (FK → cases, indexed on `case_id, axis`)
- `[ml]` settings section: `inference_backend`, `platform_base_url`, `platform_auth_method`, `fallback_to_llm`
- `MLPlatformClient` with `classify()` and `send_feedback()` — async httpx, wired via `build_inference_client()` factory

## Known Deferrals to Phase 1

- `/feedback` endpoint: works in container but Vertex AI predict route only proxies `/predict`. Needs Cloud Run service to front the container.
- Full E2E integration test via `MLPlatformClient` → Vertex AI (unit tests pass; integration deferred)
- Stub model returns UNKNOWN — real model quality is a Phase 1 goal

## Manual Steps (not yet run)

- `terraform apply` on `infra/environments/app/dev/` (ML SA as Cloud SQL IAM user)
- `i4g db migrate dev` (Alembic migration grants SELECT to ML SA)
- `make build-all-dev && make deploy-etl-dev` in `ml/`
- Bootstrap training dataset from LLM classifications, run baseline benchmark
- Submit KFP pipeline to Vertex AI
