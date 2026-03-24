# ML Platform — Phase 1: Data Platform Maturity Summary (Archived)

> **Completed:** 2026-03-23 | **PRD:** [prd_ml_infrastructure.md §12 Phase 1](../prd_ml_infrastructure.md) | **Task plan:** [tasks/ml_phase1_data_platform_maturity.md](../tasks/ml_phase1_data_platform_maturity.md)

## What Was Built

**Goal:** Stand up production-ready serving with real model inference, close the feedback loop, and mature the data platform. Phase 0 shipped a skeleton with stub predictions; Phase 1 replaced every stub with real implementation.

**Repos touched:** `ml/` (primary), `infra/`, `core/`

---

## Sprint 1 — Cloud Run Serving + Real Inference

### 1.1 — Cloud Run Service for ML Serving

Deployed the serving container as a Cloud Run service so all routes (`/predict/classify`, `/feedback`, `/health`) are directly accessible over HTTP — unblocking the feedback endpoint that was unreachable via Vertex AI Endpoint alone.

- Cloud Run service module added to `infra/modules/run/` (or extended)
- ML stack `infra/stacks/ml/main.tf` updated: container from Artifact Registry, env vars, IAM
- `terraform apply` executed; health check smoke test passed

### 1.2 — Real Model Loading & Inference

Replaced stub `classify_text()` in `ml/src/ml/serving/predict.py` with real inference:

- `load_model()` detects PyTorch vs XGBoost from artifact contents; loads weights + tokenizer / booster into `_MODEL_STATE`
- PyTorch path: tokenize → forward pass → softmax → per-axis predictions with confidence
- XGBoost path: tabular feature extraction → predict → map output indices to taxonomy codes
- `label_map.json` loaded from model artifact for label decoding
- 503 fallback if model fails to load at startup
- Unit tests: model loading (mock GCS), PyTorch inference, XGBoost inference
- Updated serving container built and pushed

### 1.3 — Evaluate Pipeline Step (Un-stubbed)

`evaluate_model` KFP component replaced with real evaluation:

- Downloads model artifact from GCS, loads model, runs inference on golden test set
- Computes per-axis P/R/F1 via existing `evaluation.py`
- Outputs KFP artifacts for Vertex AI Experiments tracking
- Eval gate compares candidate vs champion via `promotion.py`
- Pipeline recompiled; `pipeline.yaml` updated

### 1.4 — Core → ML Platform E2E Integration

- `core/config/settings.dev.toml` updated with Cloud Run service URL as `platform_base_url`
- Integration tests: `classify()` and `send_feedback()` via real Cloud Run service
- `build_inference_client()` factory verified to switch correctly between LLM and ML backends
- Deployment runbook documented

---

## Sprint 2 — Feedback Loop + PII + Dataset Refresh

### 2.1 — Feedback / Outcome Logging E2E

- E2E verified: `POST /feedback` → `predictions_outcome_log` BigQuery row appears
- `outcome_log` JOIN with `prediction_log` confirmed for analyst-override-rate metrics
- Retry/dead-letter added for failed BigQuery writes in `serving/logging.py`
- Cloud Monitoring alert configured: outcome logging failure rate > 5%

### 2.2 — PII Redaction in Dataset Export

- `redact_pii()` wired into `create_dataset_version()` before JSONL write
- `redacted: bool` field added to dataset registry metadata
- Unit test: exported JSONL validated — no raw PII (emails, phones, SSNs)
- `ml/docs/design/architecture.md` updated with PII handling documentation

### 2.3 — Automated Dataset Refresh with Outcomes

- `create_dataset_version()` JOINs `raw_analyst_labels` as ground-truth (analyst labels preferred over LLM bootstrap)
- `label_source` field (`analyst` | `llm_bootstrap`) tracked per JSONL record
- `data-refresh-pipeline`: ETL refresh → feature re-materialization → dataset re-export (v(N+1))
- Validation gate: min_samples and class_balance checks on each new version
- Cloud Scheduler trigger: weekly refresh (Sunday 4 AM UTC), added to `infra/stacks/ml/`

### 2.4 — XGBoost Pipeline Integration

- `pipelines/configs/classification_xgboost.yaml` added
- `train_model` KFP component verified with XGBoost container URI
- End-to-end pipeline test run: train → eval → register
- PyTorch vs XGBoost comparison documented, framework selection criteria in `ml/docs/design/architecture.md`

---

## Sprint 3 — Monitoring + Production Serving

### 3.1 — Accuracy Monitoring (`monitoring/accuracy.py`)

- `compute_accuracy_metrics()`: BigQuery JOIN of `prediction_log` + `outcome_log`, per-model per-axis accuracy, override rate, F1
- `materialize_performance()`: writes results to `analytics_model_performance` table
- Cloud Scheduler: daily at 5 AM UTC
- Cloud Monitoring alerts: override rate > 20% (warning), > 30% (critical)
- Unit tests with mock BigQuery results

### 3.2 — Cost Monitoring (`monitoring/cost.py`)

- `compute_cost_summary()`: queries GCP billing export (Vertex AI, Cloud Run, BigQuery, Storage), aggregates per-prediction cost
- `compare_to_llm_cost()`: per-prediction cost comparison vs LLM API (default $0.03/call baseline)
- Unit tests with mock billing data

### 3.3 — Data Quality Dashboard Queries

- Scheduled BigQuery queries: label distribution per axis (daily), ETL freshness, feature null rates
- Queries documented in `ml/docs/design/monitoring.md`
- Looker Studio dashboard spec created

### 3.4 — Production Serving Deployment

- Best-available model trained on latest dataset and promoted to champion
- `serving-prod` Vertex AI Endpoint and Cloud Run service deployed (separate from dev)
- Core prod settings updated to point to prod ML endpoint
- E2E smoke test on prod: prediction + logging verified
- Cloud Monitoring alerts on prod endpoint latency and error rate

---

## Deliverable Summary

| Metric                     | Value                                    |
| -------------------------- | ---------------------------------------- |
| Sprints completed          | 3                                        |
| Tasks completed            | 65 / 65                                  |
| New unit tests added       | `test_accuracy.py`, `test_cost.py` + others |
| Total test suite           | 137 passing, 0 failures                  |
| Repos changed              | `ml/`, `infra/`, `core/`                 |
| Production endpoint        | `serving-prod` deployed and smoke-tested |

## Known Deferrals to Phase 2

- Vertex AI Vizier hyperparameter tuning
- Shadow mode (candidate on prod, logged but not returned)
- Continuous retraining pipeline (triggered by data volume / drift)
- Vertex AI Model Monitoring on prod endpoint
- NER model (entity extraction)
- `monitoring/drift.py` and `monitoring/triggers.py` implementations
- Spark-based features (Dataproc Serverless)
