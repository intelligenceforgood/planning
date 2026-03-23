# ML Platform — Phase 1: Data Platform Maturity

> **Status:** In Progress
> **Start:** 2026-03-22
> **PRD ref:** [prd_ml_infrastructure.md §12 Phase 1](../prd_ml_infrastructure.md)
> **TDD ref:** [ml_infrastructure_tdd.md](../../ml/docs/design/ml_infrastructure_tdd.md)
> **Phase 0 log:** [change_log.md 2026-03-22](../change_log.md)

---

## Goal

Stand up production-ready serving with real model inference, close the feedback loop, and mature the data
platform. Exit criteria from PRD:

- Feedback loop operational (analyst corrections flow to BigQuery)
- Multiple training frameworks demonstrated (PyTorch + XGBoost)
- Production serving active on `serving-prod`
- ≥ 200 real analyst labels (stretch — depends on analyst activity)

## Phase 0 Deferred Items (must be resolved first)

Phase 0 shipped a skeleton with these known gaps:

1. **Predict is stubbed** — `ml/src/ml/serving/predict.py` returns `INTENT.UNKNOWN` / `CHANNEL.UNKNOWN`
2. **Vertex AI only proxies `/predict`** — `/feedback` endpoint is unreachable; need Cloud Run service
3. **Evaluate pipeline step is stubbed** — returns dummy metrics, doesn't run real inference
4. **Monitoring modules are empty** — `accuracy.py`, `drift.py`, `cost.py`, `triggers.py`

---

## Sprint 1 — Cloud Run Serving + Real Inference

### 1.1 — Cloud Run Service for ML Serving

Deploy the serving container as a Cloud Run service (not just behind Vertex AI Endpoint) so all routes
(`/predict/classify`, `/feedback`, `/health`) are directly accessible over HTTP.

- [x] **1.1.1** Add Cloud Run service module to `infra/modules/run/` (or reuse existing) for the serving container
- [x] **1.1.2** Add Cloud Run service to `infra/stacks/ml/main.tf` — container from Artifact Registry, env vars (`MODEL_ARTIFACT_URI`, `GOOGLE_CLOUD_PROJECT`, BigQuery settings), auth via IAM
- [x] **1.1.3** Add Cloud Scheduler trigger for health check (optional — or rely on Cloud Run health probe)
- [x] **1.1.4** Update `infra/environments/ml/` tfvars if needed
- [x] **1.1.5** Deploy: `terraform apply` in `environments/ml/`
- [x] **1.1.6** Smoke test: `curl <service-url>/health` returns model info

**Repos:** `infra/`
**Risk:** Service account needs `aiplatform.user` + `bigquery.dataEditor` + `storage.objectViewer` roles.

### 1.2 — Real Model Loading & Inference

Replace the stub `classify_text()` with real model loading and inference.

- [x] **1.2.1** Implement `load_model()` in `predict.py` — detect model type (PyTorch vs XGBoost) from artifact contents, load weights + tokenizer / booster into `_MODEL_STATE`
- [x] **1.2.2** Implement PyTorch inference path in `classify_text()` — tokenize → forward pass → softmax → extract per-axis predictions with confidence
- [x] **1.2.3** Implement XGBoost inference path in `classify_text()` — extract tabular features → predict → map output indices to label codes
- [x] **1.2.4** Handle label schema loading — model artifact must include `label_map.json` mapping indices to taxonomy codes
- [x] **1.2.5** Add fallback: if model load fails at startup, log error and serve `503` on prediction routes (not crash)
- [x] **1.2.6** Unit tests: model loading (mock GCS), PyTorch inference (mock model), XGBoost inference (mock booster)
- [x] **1.2.7** Build and push updated serving container: `make build-serve-dev`

**Repos:** `ml/`
**Risk:** PyTorch + Transformers add ~2GB to container image. Evaluate cold start time.

### 1.3 — Evaluate Pipeline Step (Un-stub)

Replace the stubbed `evaluate_model` KFP component with real evaluation logic.

- [x] **1.3.1** `evaluate_model` component: download model artifact from GCS, load model, run inference on golden test set, compute per-axis P/R/F1 using existing `evaluation.py`
- [x] **1.3.2** Output metrics as KFP artifacts for Vertex AI Experiments tracking
- [x] **1.3.3** Eval gate check: compare candidate metrics against champion (uses `promotion.py` logic)
- [x] **1.3.4** Recompile pipeline: `python -m kfp.compiler ...` → update `pipeline.yaml`
- [x] **1.3.5** Test: submit pipeline with a known dataset, verify eval step runs real inference

**Repos:** `ml/`
**Depends on:** 1.2 (real inference must work for eval to produce real metrics)

### 1.4 — Core → ML Platform E2E Integration

Wire up the full Core → ML Platform prediction flow, deferred from Phase 0.

- [x] **1.4.1** Update `core/config/settings.dev.toml` with Cloud Run service URL as `platform_base_url`
- [x] **1.4.2** Integration test: `MLPlatformClient.classify()` → Cloud Run service → real prediction
- [x] **1.4.3** Integration test: `MLPlatformClient.send_feedback()` → Cloud Run service → BigQuery `outcome_log`
- [x] **1.4.4** Verify `build_inference_client()` factory switches correctly between LLM and ML platform
- [x] **1.4.5** Document: deployment runbook for switching Core to ML platform inference

**Repos:** `core/`, `ml/`
**Depends on:** 1.1 (Cloud Run service deployed), 1.2 (real inference)

---

## Sprint 2 — Feedback Loop + PII + Dataset Refresh

### 2.1 — Feedback / Outcome Logging E2E

Verify and harden the full feedback data flow: Analyst → Core → ML Platform → BigQuery.

- [ ] **2.1.1** E2E test: `POST /feedback` with prediction_id → verify row appears in `predictions_outcome_log` BigQuery table
- [ ] **2.1.2** Verify `outcome_log` join with `prediction_log` produces correct analyst-override-rate metrics
- [ ] **2.1.3** Add retry/dead-letter for failed BigQuery writes in `serving/logging.py` (currently fire-and-forget)
- [ ] **2.1.4** Add Cloud Monitoring alert: outcome logging failure rate > 5%

**Repos:** `ml/`
**Depends on:** 1.1 (Cloud Run service exposing `/feedback`)

### 2.2 — PII Redaction in Dataset Export

Wire `pii.py` (already implemented) into the dataset creation pipeline so training data is redacted.

- [ ] **2.2.1** Call `redact_pii()` on case narrative text during `create_dataset_version()` before writing JSONL
- [ ] **2.2.2** Add `redacted: bool` field to dataset registry metadata
- [ ] **2.2.3** Unit test: dataset export produces redacted text (emails, phones, SSNs replaced)
- [ ] **2.2.4** Validate: exported JSONL contains no raw PII patterns (regex scan)
- [ ] **2.2.5** Update `ml/docs/design/architecture.md` to document PII handling in data flow

**Repos:** `ml/`

### 2.3 — Automated Dataset Refresh with Outcomes

Build pipeline to re-export training datasets incorporating new analyst corrections.

- [ ] **2.3.1** Extend `create_dataset_version()` to JOIN `raw_analyst_labels` as ground truth labels (prefer analyst labels over bootstrap LLM labels when both exist)
- [ ] **2.3.2** Add label source priority: `analyst` > `llm_bootstrap` — track `label_source` in JSONL records
- [ ] **2.3.3** Add `data-refresh-pipeline` KFP pipeline or Cloud Scheduler → Cloud Run Job: ETL refresh → feature re-materialization → dataset re-export (new version)
- [ ] **2.3.4** Dataset version auto-increment: query registry for latest version, create v(N+1)
- [ ] **2.3.5** Validation gate: new dataset must pass min_samples and class_balance checks
- [ ] **2.3.6** Unit test: dataset with mixed label sources correctly prioritizes analyst labels
- [ ] **2.3.7** Cloud Scheduler trigger: weekly dataset refresh (e.g., Sunday 4 AM UTC)

**Repos:** `ml/`, `infra/` (scheduler)
**Depends on:** 2.1 (outcomes must be flowing to BigQuery)

### 2.4 — XGBoost Pipeline Integration

The XGBoost training container exists but isn't fully integrated into the pipeline.

- [ ] **2.4.1** Add XGBoost training config YAML: `pipelines/configs/classification_xgboost.yaml`
- [ ] **2.4.2** Verify `train_model` pipeline component works with XGBoost container URI
- [ ] **2.4.3** Test: submit training pipeline with XGBoost config, verify end-to-end (train → eval → register)
- [ ] **2.4.4** Compare XGBoost vs PyTorch results on same dataset (notebook or script)
- [ ] **2.4.5** Document framework selection criteria in `ml/docs/design/architecture.md`

**Repos:** `ml/`
**Depends on:** 1.3 (evaluate step must be un-stubbed)

---

## Sprint 3 — Monitoring + Production Serving

### 3.1 — Accuracy Monitoring

Implement `ml/src/ml/monitoring/accuracy.py` — the most critical monitoring capability.

- [ ] **3.1.1** Implement `compute_accuracy_metrics()` — BigQuery query joining `prediction_log` + `outcome_log`, outputs per-model per-axis accuracy, override rate, F1
- [ ] **3.1.2** Implement `materialize_performance()` — writes results to `analytics_model_performance` table
- [ ] **3.1.3** Add Cloud Scheduler trigger: daily accuracy computation (5 AM UTC)
- [ ] **3.1.4** Cloud Monitoring alert: override rate > 20% (warning), > 30% (critical)
- [ ] **3.1.5** Unit test: accuracy computation with mock BigQuery results

**Repos:** `ml/`, `infra/` (scheduler + alert)

### 3.2 — Cost Monitoring

Implement `ml/src/ml/monitoring/cost.py`.

- [ ] **3.2.1** Implement `compute_cost_summary()` — query GCP billing export for Vertex AI + Cloud Run + BigQuery costs, aggregate by capability and component
- [ ] **3.2.2** Implement `compare_to_llm_cost()` — per-prediction cost of ML platform vs LLM API (from Core usage logs)
- [ ] **3.2.3** Add cost summary query to monitoring notebook or dashboard SQL
- [ ] **3.2.4** Unit test with mock billing data

**Repos:** `ml/`

### 3.3 — Data Quality Dashboard Queries

Create the SQL queries and BigQuery scheduled queries for data observability.

- [ ] **3.3.1** Scheduled query: label distribution per axis (daily)
- [ ] **3.3.2** Scheduled query: ETL ingestion freshness (last ingest timestamp per table)
- [ ] **3.3.3** Scheduled query: feature null rates and distribution stats
- [ ] **3.3.4** Add queries to `ml/docs/design/monitoring.md`
- [ ] **3.3.5** Create Looker Studio dashboard spec (or notebook equivalent)

**Repos:** `ml/`

### 3.4 — Production Serving Deployment

Deploy a real trained model to `serving-prod`.

- [ ] **3.4.1** Train best-available model on latest dataset (PyTorch or XGBoost, whichever performs better)
- [ ] **3.4.2** Promote to champion via promotion workflow
- [ ] **3.4.3** Deploy champion to `serving-prod` Vertex AI Endpoint
- [ ] **3.4.4** Deploy Cloud Run service for `serving-prod` (separate from dev)
- [ ] **3.4.5** Update Core prod settings to point to prod ML endpoint
- [ ] **3.4.6** E2E smoke test on prod: prediction + logging verified
- [ ] **3.4.7** Set up monitoring alerts on prod endpoint latency and error rate

**Repos:** `ml/`, `infra/`, `core/`
**Depends on:** 1.2 (real inference), 3.1 (monitoring ready), all Sprint 1–2 work

---

## Out of Scope (Phase 2+)

Per PRD §12 Phase 2:

- Vertex AI Vizier hyperparameter tuning
- Shadow mode (candidate on prod, logged but not returned)
- Continuous retraining pipeline (triggered by data volume / drift)
- Vertex AI Model Monitoring on prod endpoint
- NER model (entity extraction)
- Drift detection implementation (`monitoring/drift.py`)
- Retraining triggers (`monitoring/triggers.py`)
- Spark-based features (Dataproc Serverless) — PRD Phase 1 item, but deprioritized in favor of feedback loop maturity

---

## Risk Register

| Risk                                     | Impact                            | Mitigation                                                                            |
| ---------------------------------------- | --------------------------------- | ------------------------------------------------------------------------------------- |
| Insufficient labeled data for real model | Custom model worse than stub      | Bootstrap from LLM classifications. Track label count. Phase 0 baseline is the floor. |
| Cold start latency on Cloud Run serving  | First request slow (~10s)         | Accept for dev. Set `min-instances=1` on prod if needed (+$30/month).                 |
| PyTorch container image too large (~4GB) | Slow deploys, high AR storage     | Multi-stage Docker build. Consider ONNX export for serving (lighter runtime).         |
| Cross-project IAM complexity             | Auth failures between Core and ML | Test IAM grants end-to-end before switching Core to ML backend.                       |
| BigQuery prediction log volume           | Cost at scale                     | Sampling at high volume (Phase 2+). Free tier covers 10K/month easily.                |

---

## Manual Steps Required

| Step                     | Command / Action                                | When                                         |
| ------------------------ | ----------------------------------------------- | -------------------------------------------- |
| Deploy ML infra          | `cd infra/environments/ml && terraform apply`   | After Terraform changes (1.1, 2.3, 3.1, 3.4) |
| Build + push containers  | `cd ml && make build-serve-dev`                 | After predict.py changes (1.2)               |
| Deploy Cloud Run service | `gcloud run deploy ...` or Terraform            | After 1.1                                    |
| Submit training pipeline | `python scripts/submit_pipeline.py`             | After 1.3, 2.4, 3.4                          |
| Update Core settings     | Edit `settings.dev.toml` / `settings.prod.toml` | After 1.4, 3.4                               |

---

## Completion Tracking

| Sprint                                | Tasks              | Status      |
| ------------------------------------- | ------------------ | ----------- |
| Sprint 1 — Cloud Run + Real Inference | 1.1–1.4 (22 tasks) | Complete    |
| Sprint 2 — Feedback + PII + Data      | 2.1–2.4 (21 tasks) | Not started |
| Sprint 3 — Monitoring + Prod          | 3.1–3.4 (22 tasks) | Not started |
| **Total**                             | **65 tasks**       |             |
