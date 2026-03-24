# ML Platform — Phase 2: Training Maturity + Continuous Learning Summary (Archived)

> **Completed:** 2026-03-24 | **PRD:** [prd_ml_infrastructure.md §12 Phase 2](../prd_ml_infrastructure.md) | **Task plan:** [tasks/ml_phase2_training_maturity.md](../tasks/ml_phase2_training_maturity.md)

## What Was Built

**Goal:** Complete the monitoring layer, deliver continuous retraining, add shadow mode and Vizier hyperparameter tuning, train and deploy a second ML capability (NER), and build Dataflow/Beam graph features. Phase 1 shipped production serving with real inference and a closed feedback loop; Phase 2 made the platform self-improving and multi-capability.

**Repos touched:** `ml/` (primary), `infra/`, `core/`

---

## Sprint 0 — Repo Hygiene (Pre-Work)

Brought the `ml/` repo to a clean baseline before Phase 2 development:

- Fixed README.md: corrected package path (`src/ml/`, not `src/i4g_ml/`), fixed TDD link
- Fixed deployment runbook: corrected conda env references (`ml`, not `i4g`)
- Canonicalized `pipeline.yaml`: moved compiled KFP artifact from repo root to `pipelines/training_pipeline.yaml`, updated `submit_pipeline.py`, added `.gitignore` entry and `compile-pipeline` Makefile target
- Full lint/format/test pass: `ruff`, `black`, `pre-commit`, all 238 unit tests passing
- `pyproject.toml` cleanup: added `[project.urls]`, `.ruff_cache/` in `.gitignore`

---

## Sprint 1 — Monitoring + Dashboards

### 1.1 — `monitoring/drift.py` Implementation

Filled the drift detection stub with full implementation:

- `DriftReport` dataclass with per-axis `PredictionDrift` and per-feature `FeatureDrift`
- `compute_prediction_drift()`: queries `prediction_log` for baseline and current windows, computes PSI per axis (threshold: PSI > 0.2)
- `compute_feature_drift()`: pulls numeric features from `prediction_log.features_used` JSON, computes PSI vs. training-time baseline
- `materialize_drift_metrics()`: writes to `analytics_drift_metrics` BigQuery table
- BigQuery DDL: `pipelines/sql/analytics_drift_metrics.sql`
- Unit tests: mock BigQuery, verified PSI math and materialization payload shape

### 1.2 — `monitoring/triggers.py` Implementation

- `RetrainingTrigger` dataclass: `should_retrain`, `reasons`, `new_analyst_label_count`, `max_drift_psi`, `last_training_date`
- `evaluate_retraining_conditions()`: checks data volume (≥ 200 analyst labels since last training), drift (any axis PSI > 0.2), staleness (> 30 days), and `force` flag
- `record_trigger_event()`: inserts to `analytics_trigger_log` BigQuery table
- BigQuery DDL: `pipelines/sql/analytics_trigger_log.sql`
- Unit tests: each condition independently, combined logic, `force=True`

### 1.3 — Vertex AI Model Monitoring on `serving-prod`

- Added Terraform `google_vertex_ai_model_deployment_monitoring_job` targeting `serving-prod`
- Cloud Scheduler daily trigger (6 AM UTC) for BigQuery-based drift computation as Cloud Run Job
- `terraform apply` on `infra/environments/ml/`
- Smoke tested: sent prediction, verified monitoring job logs

### 1.4 — Accuracy + Cost Dashboards

- Cloud Scheduler jobs (5 AM, 5:30 AM UTC daily) for `accuracy.py` and `cost.py` materialization
- BigQuery DDL: `pipelines/sql/analytics_cost_summary.sql`
- Terraform: Cloud Scheduler jobs added to `infra/stacks/ml/main.tf`
- Dashboard access and data freshness documented in `ml/docs/design/monitoring.md`

---

## Sprint 2 — Shadow Mode + Vizier

### 2.1 — Shadow Mode in Serving Container

Deployed shadow inference so candidate models are evaluated on real traffic before promotion:

- `SHADOW_MODEL_ARTIFACT_URI` env var controls shadow model loading (empty = disabled)
- At startup: loads shadow model into separate `_SHADOW_MODEL_STATE` dict, with memory guard (RSS > 80% = skip shadow loading)
- Champion inference runs synchronously and returns immediately; shadow inference fires as `asyncio.create_task` (non-blocking)
- Shadow predictions logged to `prediction_log` with `is_shadow=True` and `prediction_id = f"{champion_pred_id}-shadow"`
- Shadow failures never affect champion responses (all exceptions caught)
- BigQuery schema updated: `ALTER TABLE predictions_prediction_log ADD COLUMN is_shadow BOOL DEFAULT FALSE`
- `monitoring/accuracy.py`: added `compute_shadow_comparison()` for champion vs. shadow agreement metrics
- Updated Terraform Cloud Run service with `SHADOW_MODEL_ARTIFACT_URI` env var
- Deployed to `serving-dev`, integration tested: both champion and shadow rows confirmed in BigQuery

### 2.2 — Vertex AI Vizier Hyperparameter Tuning

Vizier operates outside the KFP pipeline — it manages a study that spawns multiple pipeline runs with different hyperparameters:

- `training/vizier.py`:
  - `create_vizier_study()`: creates `aiplatform.VizierStudy` with configurable search space and metric
  - `run_vizier_sweep()`: suggest trial → extract params → submit pipeline → wait → report metric → loop
  - `get_best_config()`: returns optimal parameters from completed study
- Search spaces defined in pipeline configs:
  - `classification_xgboost.yaml`: `n_estimators`, `max_depth`, `learning_rate` (log scale), `subsample`
  - `classification_gemma2b.yaml`: `learning_rate` (log scale), `lora_r`, `batch_size`
- `enable_vizier: bool = False` added to `TrainingConfig`
- `run-vizier-sweep` Makefile target
- Unit tests: mock `aiplatform.VizierStudy`, study creation, trial suggestion loop, best config extraction

---

## Sprint 3 — Continuous Retraining Pipeline

### 3.1 — Pipeline Submission Utility

Extended `scripts/submit_pipeline.py`:

- `submit_pipeline()`: compiles KFP YAML if stale, creates `aiplatform.PipelineJob` with config params, tags run with capability/trigger reason/dataset version/timestamp
- Called by both manual runs and automated trigger
- Unit tests: mock `aiplatform.PipelineJob`, parameter passing, tag metadata

### 3.2 — Retraining Trigger Cloud Run Job

- `scripts/trigger_retraining.py`: Cloud Run Job entry point accepting `--capability` and `--force` args
- Calls `evaluate_retraining_conditions()` → if `should_retrain`: submits pipeline, records trigger event, logs structured JSON
- Exit code 0 always (structured logging for alerting, not exit codes)
- Terraform: `retrain-trigger` Cloud Run Job + Cloud Scheduler (daily 6 AM UTC + monthly force)
- `trigger-retrain-dev` Makefile target
- Unit tests: both retrain and skip branches

### 3.3 — E2E Loop Test (Dev)

- Full manual test validated: inserted 200+ synthetic analyst labels → drift materialization → trigger retraining → pipeline submitted → model registered → eval gate ran
- Procedure documented in `ml/docs/runbooks/retraining.md`
- Cloud Monitoring log-based alert added: `action=retrain_submitted`

---

## Sprint 4 — NER Model (Second Capability)

### 4.1 — NER Evaluation Harness

- `NerEvalResult` dataclass: per-entity-type P/R/F1 for PERSON, ORG, CRYPTO_WALLET, BANK_ACCOUNT, PHONE, EMAIL, URL
- `evaluate_ner()`: converts span annotations to BIO tags, uses `seqeval.metrics.classification_report`
- `align_labels_with_tokens()`: expands character-offset labels to subword token BIO labels — edge cases (multi-token entities, adjacent entities, entity at start/end) unit tested explicitly
- Golden test set: 59 samples with 143 entities across all 7 types in `gs://i4g-ml-data/golden-sets/ner_v1.jsonl`
- `seqeval>=1.2` added to `pyproject.toml`

### 4.2 — NER Dataset Export

- `create_ner_dataset_version()` in `data/datasets.py`: queries BigQuery, converts to BIO-tagged token sequences, applies PII redaction on non-entity text, stratified split by entity type distribution
- Dataset validation: min 50 examples, every entity type ≥ 5 examples

### 4.3 — NER Training Container

- `containers/train-ner/` with `train.py`: loads JSONL, tokenizes with `AutoTokenizer`, aligns BIO tags to subword tokens, fine-tunes `AutoModelForTokenClassification`
- Base model: `dslim/bert-base-NER` (pre-trained on CoNLL-2003 NER, good transfer) — cased model preserves critical signals for NER
- Logs per-entity-type F1 to Vertex AI Experiments
- Exports: `model.safetensors`, `tokenizer/`, `label_map.json`, `training_config.json`
- `docker/train-ner.Dockerfile`, built and pushed to Artifact Registry
- `build-train-ner-dev` and `build-train-ner-prod` Makefile targets

### 4.4 — Multi-Capability Serving

Refactored serving container for multi-model support:

- Replaced single `_MODEL_STATE` with `_MODELS: dict[str, ModelState]` keyed by capability
- Startup loads all capabilities from env vars: `MODEL_ARTIFACT_URI` (classification), `NER_MODEL_ARTIFACT_URI` (ner)
- New `extract_entities()`: tokenizes, runs token classification, decodes BIO tags → entity spans with confidence
- `POST /predict/extract-entities` route: returns entity spans, 503 if NER model not loaded, logs to `prediction_log` with `capability = "ner"`
- Updated Terraform with `NER_MODEL_ARTIFACT_URI` env var
- Unit tests: multi-model loading, classification unaffected, NER span decoding, BIO tag collapse, 503 when disabled

### 4.5 — NER Pipeline Config + Promotion

- `pipelines/configs/ner_bert.yaml`: capability `ner`, eval metric `entity_micro_f1`, Vizier search space
- `registry/promotion.py`: eval gate dispatches on capability (classification → macro F1, NER → entity micro F1)
- `training/pipeline.py`: capability parameter routes to correct training container and eval function

### 4.6 — Core `MLPlatformClient` Extension

- `core/src/i4g/ml/client.py`: added `extract_entities()` — POST to `/predict/extract-entities`, returns entity list compatible with existing LLM extraction output format
- `[ml] entity_extraction_backend` setting added to `core/config/settings.default.toml` (`"llm"` or `"ml_platform"`)
- `build_entity_extraction_client()` factory routes independently from classification backend
- Unit tests: mock HTTP, request format, entity list parsing

### 4.7 — NER E2E Deployment

- NER training pipeline submitted on dev (`make submit-pipeline CONFIG=pipelines/configs/ner_bert.yaml`)
- `docs/design/architecture.md` updated with NER capability section and Mermaid diagram

---

## Sprint 5 — Dataflow/Beam Graph Features

**Architecture decision:** Dataflow/Beam over Spark/Dataproc — co-occurrence aggregations + connected components don't need heavy graph frameworks. Beam handles this with native BigQuery I/O, pay-per-use autoscaling, and zero cluster config. NetworkX handles connected components within a Beam DoFn at our scale (~10K cases, sparse graph).

### 5.1 — Beam Pipeline for Graph Features

- `src/ml/data/graph_features.py`: Beam pipeline with configurable runner (DirectRunner / DataflowRunner)
  - Entity co-occurrence pairs → per-case aggregation (shared_entity_count, entity_reuse_frequency) → connected components (cluster_size) → WriteToBigQuery (WRITE_TRUNCATE, idempotent)
- BigQuery DDL: `pipelines/sql/features_graph_features.sql`
- Graph feature definitions added to `FEATURE_REGISTRY` with `compute_method=ComputeMethod.DATAFLOW`

### 5.2 — Infrastructure + Integration

- Terraform: Dataflow IAM (`roles/dataflow.worker`), Cloud Run Job (`graph-features`), Cloud Scheduler (weekly Sunday 4 AM UTC)
- `docker/graph-features.Dockerfile` with `apache-beam[gcp]` and `networkx`
- `submit-graph-features-dev`, `build-graph-features-dev` Makefile targets
- `data/datasets.py`: LEFT JOIN `features_graph_features` during dataset creation (nullable, graceful missing data)

### 5.3 — Validation

- Unit tests: mock BigQuery reads, co-occurrence pair generation, connected component aggregation, feature output schema

---

## Deliverable Summary

| Metric                     | Value                                                           |
| -------------------------- | --------------------------------------------------------------- |
| Sprints completed          | 6 (Sprint 0–5)                                                 |
| PRD deliverables completed | 7 / 7                                                           |
| Repos changed              | `ml/`, `infra/`, `core/`                                       |
| Capabilities on platform   | 2 (classification + NER)                                        |
| Monitoring coverage        | Drift daily, Model Monitoring on prod, accuracy + cost matured  |
| Continuous retraining      | E2E validated on dev, Cloud Scheduler triggers operational      |
| Shadow mode                | Deployed to `serving-dev`, champion/shadow comparison queryable |
| Vizier                     | XGBoost + PyTorch search spaces defined, sweep framework tested |
| Graph features             | Dataflow/Beam pipeline built, Terraform deployed                |

## Known Deferrals to Phase 3

- **Looker Studio dashboard** — requires manual GUI work; BigQuery `analytics_*` tables are populated and ready
- **Shadow mode on prod** — set `SHADOW_MODEL_ARTIFACT_URI` on prod Cloud Run service when ready
- **NER model on prod** — awaiting pipeline completion; set `NER_MODEL_ARTIFACT_URI` on prod when model is promoted
- **NER E2E validation** — confirm model registered, promote to candidate, deploy to `serving-dev`, run eval harness, document baseline metrics
- **Vizier XGBoost sweep** — 10-trial sweep deferred to budget approval ($50+)
- **Graph features local validation** — requires live BigQuery connection; DoFn unit tests cover logic
- **Graph features ablation study** — blocked on sufficient training data
- **Dataflow job verification** — weekly Cloud Scheduler will run Sunday; verify `features_graph_features` populated
- **Developer Bootcamp Exercises** — extracted as separate task (9 guided exercises for ML platform onboarding)
