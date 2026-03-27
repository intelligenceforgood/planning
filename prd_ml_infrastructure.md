# I4G ML Platform — Product Requirements Document

**Date:** March 2026</br>
**Status:** Draft</br>
**Owner:** Engineering</br>
**Related:** [ML Strategy & Roadmap](ml_strategy.md)

---

## 1. Overview

The I4G ML Platform provides training, serving, evaluation, and monitoring capabilities for machine learning models. It lives in the `ml/` repository, runs in the `i4g-ml` GCP project, and exposes prediction endpoints that any application — starting with I4G — calls for inference.

The platform has four layers:

- **Data** — ETL pipelines, feature engineering, versioned datasets, data quality
- **Training** — Multi-framework model training, experiment tracking, pipeline orchestration, hyperparameter tuning
- **Serving** — Auto-scaling prediction endpoints, prediction logging, outcome logging, batch inference
- **Monitoring** — Drift detection, accuracy tracking, cost attribution, retraining triggers

### Current State

I4G ships production ML features — fraud classification, entity extraction, risk scoring, RAG-powered assessments, and autonomous scam site investigation — powered entirely by third-party foundation models via prompting. There is no training infrastructure, no labeled dataset, no model registry, no evaluation harness, and no custom model serving capability.

We have enough production data to bootstrap. Existing classification results, entity extractions, and risk scores serve as an initial golden set. The end-to-end pipeline can be validated against the current few-shot baseline before any real labeled data arrives.

### Design Principles

1. **Feature-centric architecture.** Features are first-class citizens — engineered, versioned, stored, served, and monitored.
2. **Feedback-loop driven.** Every prediction is logged with features and model version. Outcomes flow back for continuous improvement.
3. **Reproducible by default.** Any training run is recreatable from data version + config + code version.
4. **Few-shot prompting is the perpetual fallback.** Custom models improve on the baseline but never replace it.
5. **GCP-managed over self-hosted.** For a small team, operational overhead is the bottleneck. Use managed services everywhere.

---

## 2. Architecture

```
┌────────────────────────────────────────────────────────────────────────────┐
│                        I4G ML PLATFORM  (i4g-ml)                           │
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ SERVING                                                              │  │
│  │  Vertex AI Endpoints (auto-scaling, scale-to-zero)                   │  │
│  │  ┌────────────────────────────────────────────────────────────────┐  │  │
│  │  │  Classify  │  Extract Entities  │  Score Risk  │  Batch jobs   │  │  │
│  │  └────────────────────────────────────────────────────────────────┘  │  │
│  │  Prediction logging → BigQuery    Feature serving ← BigQuery/cache   │  │
│  │  Outcome logging ← consumer feedback                                 │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                              ↑ model artifacts                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ MODEL REGISTRY — Vertex AI Model Registry                            │  │
│  │  Stages: experimental → candidate → champion                         │  │
│  │  Eval gates on promotion   Lineage tracking   Rollback support       │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                              ↑ trained model                               │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ TRAINING                                                             │  │
│  │  Vertex AI Training     Vertex AI Pipelines     Vertex AI Workbench  │  │
│  │  (custom containers:    (orchestration:          (Jupyter notebooks: │  │
│  │   PyTorch, XGBoost,     data → train → eval     ad-hoc experiments,  │  │
│  │   HF PEFT, TF,          → register → deploy)    evaluation, EDA)     │  │
│  │   Spark ML)                                                          │  │
│  │  Vertex AI Experiments   Vertex AI Vizier        TensorBoard         │  │
│  │  (experiment tracking)   (hyperparameter tuning) (training curves)   │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                              ↑ training data                               │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ DATA                                                                 │  │
│  │  ┌──────────────────┐  ┌─────────────────┐  ┌──────────────────────┐ │  │
│  │  │ BigQuery         │  │ Cloud Storage   │  │ Feature Engineering  │ │  │
│  │  │ - Data warehouse │  │ - Raw ingestion │  │ - BigQuery SQL       │ │  │
│  │  │ - Offline feats  │  │ - Model ckpts   │  │ - Dataproc Spark     │ │  │
│  │  │ - Prediction log │  │ - Datasets      │  │ - Pre-computed       │ │  │
│  │  │ - Outcome log    │  │ - Eval results  │  │   served via cache   │ │  │
│  │  └──────────────────┘  └─────────────────┘  └──────────────────────┘ │  │
│  │                                                                      │  │
│  │  ETL: Cloud Run Jobs (scheduled) — source databases → BigQuery       │  │
│  │  Data quality: validation rules, distribution checks, freshness      │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                            │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │ MONITORING                                                            │ │
│  │  Vertex AI Model Monitoring    BigQuery Analytics    Cloud Monitoring │ │
│  │  (input drift, prediction      (cost, latency,       (alerting,       │ │
│  │   drift, feature skew)         accuracy vs labels)   dashboards)      │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                                                            │
│          ◄── Continuous Learning Loop ──►                                  │
│   predictions logged → outcomes received → data refreshed →                │
│   pipeline triggered → model trained → eval gate → promote if better       │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘

CONSUMERS (e.g., I4G Core, SSI, future products):
  - Call prediction endpoints for inference
  - Send feedback (analyst corrections) for outcome logging

DATA SOURCES (e.g., I4G Cloud SQL):
  - ETL jobs pull data on a schedule
  - No runtime dependency — training data is ingested in batch
```

### Resource Isolation

Training and serving run in the same GCP project (`i4g-ml`) but use fully isolated resources:

| Concern      | Resources                                                  | Lifecycle                                       |
| ------------ | ---------------------------------------------------------- | ----------------------------------------------- |
| **Training** | Vertex AI Training jobs, Pipelines, Experiments, Workbench | Ephemeral — spun up per job/run                 |
| **Serving**  | Vertex AI Endpoints (`serving-dev`, `serving-prod`)        | Long-lived — auto-scaling, always addressable   |
| **Data**     | BigQuery, Cloud Storage                                    | Persistent — shared across training and serving |

Training jobs are ephemeral compute that start, run, and terminate. Serving endpoints are persistent infrastructure with independent scaling. They never compete for the same resources.

---

## 3. GCP Infrastructure

### 3.1 Project

| Property   | Value                                          |
| ---------- | ---------------------------------------------- |
| Project ID | `i4g-ml`                                       |
| Region     | `us-central1`                                  |
| Billing    | Same billing account as `i4g-dev` / `i4g-prod` |

### 3.2 Services

| Service                            | Purpose                                                | Cost profile                                |
| ---------------------------------- | ------------------------------------------------------ | ------------------------------------------- |
| **Vertex AI Training**             | Custom model training (any framework, GPU/CPU)         | Per-job compute hours                       |
| **Vertex AI Pipelines**            | ML pipeline orchestration                              | Per-pipeline-step                           |
| **Vertex AI Endpoints**            | Model serving (auto-scaling, scale-to-zero)            | Per-request + per-node-hour                 |
| **Vertex AI Model Registry**       | Model versioning, stage management, lineage            | Free (part of Vertex AI)                    |
| **Vertex AI Experiments**          | Experiment tracking, metric comparison                 | Free (part of Vertex AI)                    |
| **Vertex AI Workbench**            | Managed Jupyter notebooks                              | Per-instance-hour (stop when idle)          |
| **Vertex AI Model Monitoring**     | Drift detection, feature skew, prediction drift        | Per-prediction monitored                    |
| **BigQuery**                       | Data warehouse, feature store, prediction/outcome logs | Free tier: 1 TB query + 10 GB storage/month |
| **Cloud Storage**                  | Raw data, model artifacts, dataset snapshots           | Per-GB stored                               |
| **Cloud Run Jobs**                 | ETL pipelines, batch processing                        | Per-job execution                           |
| **Cloud Scheduler**                | Trigger periodic ETL, evaluation, retraining           | ~$0.10/job/month                            |
| **Pub/Sub** (Phase 1+)             | Event-driven data flow for real-time feedback          | Per-message                                 |
| **Artifact Registry**              | Docker images for training and serving containers      | Per-GB stored                               |
| **Dataproc Serverless** (Phase 1+) | Spark jobs for large-scale feature engineering         | Per-job                                     |

### 3.3 Orchestration

**Vertex AI Pipelines** (KFP v2) for all ML workflow orchestration. Zero baseline cost — pay only when pipelines run. Native integration with Vertex AI Training, Model Registry, Endpoints, Experiments, BigQuery, and Cloud Storage.

For simple data ETL (source DB → BigQuery sync): **Cloud Scheduler + Cloud Run Jobs**. Simpler than a full pipeline, nearly free, runs on a cron schedule. These ETL jobs can be promoted to Vertex AI Pipeline steps later if needed.

**Why not Airflow (Cloud Composer)?** Managed Airflow baseline is $300–500/month — exceeds the entire ML platform's compute costs at current scale. If pipeline complexity outgrows Vertex AI Pipelines, Prefect Cloud (free tier: 10K task runs/month) is the recommended upgrade path.

### 3.4 Cost Estimate

At 10,000 inferences/month and weekly training:

| Component                                             | Monthly cost |
| ----------------------------------------------------- | ------------ |
| Vertex AI Endpoints (scale-to-zero, ~14 req/hour avg) | $5–20        |
| Vertex AI Training (1 GPU-hour/week)                  | $5–20        |
| Vertex AI Pipelines (4 runs/month, ~5 steps each)     | $1–3         |
| BigQuery (within free tier)                           | $0           |
| Cloud Storage (model artifacts, datasets)             | $1–5         |
| Cloud Run Jobs (ETL, daily)                           | $1–5         |
| Vertex AI Workbench (interactive, stopped when idle)  | $5–30        |
| **Total**                                             | **$18–83**   |

[Google for Nonprofits](https://www.google.com/nonprofits/) provides $10,000/year in GCP credits for eligible 501(c)(3) organizations. Vertex AI, BigQuery, and Cloud Run all have free tier allotments.

---

## 4. Data Platform

### 4.1 Data Sources

| Source              | Data                                                             | Ingestion method          | Frequency    |
| ------------------- | ---------------------------------------------------------------- | ------------------------- | ------------ |
| I4G Cloud SQL       | Cases, classification results, entities, indicators, risk scores | Batch ETL (Cloud Run Job) | Daily        |
| I4G Cloud SQL       | Analyst labels / corrections                                     | Batch ETL (Cloud Run Job) | Daily        |
| SSI database        | Investigation results, site classifications                      | Batch ETL (Cloud Run Job) | Daily        |
| External (Phase 2+) | Threat intelligence feeds, industry datasets                     | API ingestion + ETL       | As available |

### 4.2 Data Warehouse (BigQuery)

```
i4g_ml (BigQuery dataset)
├── raw/                          # Mirror of source data
│   ├── cases
│   ├── classification_results
│   ├── entities
│   ├── indicators
│   ├── analyst_labels
│   └── ssi_investigations
├── features/                     # Engineered features
│   ├── case_features             # Pre-computed feature vectors per case
│   ├── text_features             # NLP-derived features
│   └── graph_features            # Entity co-occurrence, network features
├── training/                     # Versioned training datasets
│   ├── classification_v1_train
│   ├── classification_v1_eval
│   └── classification_v1_test
├── predictions/                  # Prediction and outcome logs
│   ├── prediction_log            # Every prediction: features, model version, result
│   └── outcome_log               # Analyst corrections linked to predictions
└── analytics/                    # Derived tables for dashboards
    ├── model_performance
    ├── cost_summary
    └── drift_metrics
```

### 4.3 ETL Pipelines

**Ingestion ETL** (Cloud Run Job, daily, triggered by Cloud Scheduler):

1. Connect to source Cloud SQL via Cloud SQL Auth Proxy (read-only service account).
2. Extract new/modified records since last run (watermark-based incremental load).
3. Transform: normalize schemas, compute derived columns, handle nulls.
4. Load into BigQuery `raw/` tables (append or merge on primary key).
5. Log ingestion metrics (row counts, latency, errors) to Cloud Monitoring.

The ETL job has no runtime coupling to consumer services — it reads directly from the database on a schedule.

### 4.4 Feature Engineering

Features are first-class objects: defined, versioned, documented, tested.

| Category                 | Features                                                                                     | Compute method     |
| ------------------------ | -------------------------------------------------------------------------------------------- | ------------------ |
| **Text**                 | text_length, word_count, avg_sentence_length, lexical_diversity, language                    | BigQuery SQL       |
| **Entity**               | entity_count, unique_entity_types, has_crypto_wallet, has_bank_account, has_phone, has_email | BigQuery SQL       |
| **Indicator**            | indicator_count, indicator_diversity, max_indicator_confidence                               | BigQuery SQL       |
| **Classification**       | current_classification_confidence, classification_axis_count, top_intent_label               | BigQuery SQL       |
| **Structural**           | document_count, evidence_file_count, case_age_days, has_attachments                          | BigQuery SQL       |
| **Network** (Phase 1+)   | shared_entity_count, cluster_size, entity_reuse_frequency                                    | Spark              |
| **Embedding** (Phase 1+) | text_embedding_384d (domain-tuned or generic)                                                | Vertex AI / custom |

**Feature serving strategy:**

| Phase    | Method                                                     | Latency | Complexity |
| -------- | ---------------------------------------------------------- | ------- | ---------- |
| Phase 0  | Caller sends raw text; serving container computes inline   | ~100ms  | Low        |
| Phase 1  | Pre-computed features in BigQuery; fetched at predict time | ~1s     | Medium     |
| Phase 2+ | Vertex AI Feature Store for online serving                 | <10ms   | Higher     |

At 10K inferences/month (~0.2 QPS average), Phase 0 inline computation is acceptable.

### 4.5 Dataset Management

Datasets are versioned, immutable snapshots for training and evaluation.

**Versioning scheme:** `{capability}_{version}_{split}` (e.g., `classification_v3_train`).

**Dataset creation workflow:**

1. Pipeline queries `raw/` + `features/` tables with point-in-time filters.
2. Validates: min_samples, class balance, null rates.
3. Applies stratified sampling for train/eval/test splits (default 70/15/15).
4. Writes JSONL files to Cloud Storage: `gs://i4g-ml-data/datasets/{capability}/v{N}/{split}.jsonl`.
5. Registers metadata in BigQuery `training/dataset_registry` (version, split sizes, label distribution, config).
6. Datasets are immutable once registered. New data → new version.

### 4.6 Data Quality

| Check                                   | Runs when           | Action                         |
| --------------------------------------- | ------------------- | ------------------------------ |
| Record count below minimum (< 50)       | Dataset creation    | Block export                   |
| Class imbalance ratio > 10:1            | Dataset creation    | Warning + suggest oversampling |
| Feature null rate > 5%                  | Feature engineering | Alert                          |
| Distribution drift vs. previous version | Dataset creation    | Warning                        |
| Ingestion staleness > 48 hours          | Monitoring (daily)  | Alert                          |
| Duplicate records                       | Dataset creation    | De-duplicate                   |

### 4.7 PII Handling

Training data export includes a PII redaction step that replaces victim identifiers with placeholders (`[NAME]`, `[PHONE]`, `[EMAIL]`). BigQuery column-level security restricts PII access to authorized accounts only. Feature-only training (no text) is available as a fallback if legal review requires it.

---

## 5. Training Platform

### 5.1 Vertex AI Training

All model training uses **custom containers** on Vertex AI Training. This provides framework flexibility and full reproducibility.

| Framework                       | Use case                               | Container base   |
| ------------------------------- | -------------------------------------- | ---------------- |
| HuggingFace Transformers + PEFT | LLM fine-tuning (Gemma, Llama, etc.)   | `pytorch-gpu`    |
| PyTorch                         | Custom neural networks                 | `pytorch-gpu`    |
| TensorFlow                      | Legacy models, Keras                   | `tensorflow-gpu` |
| XGBoost / LightGBM              | Tabular classification, ranking        | `python-cpu`     |
| scikit-learn                    | Quick baselines, feature selection     | `python-cpu`     |
| PySpark (Dataproc Serverless)   | Distributed training on large datasets | Dataproc image   |

Each training container: reads config → downloads data from BigQuery/GCS → trains → logs metrics to Vertex AI Experiments → exports artifacts to GCS → registers in Model Registry (if eval gate passes).

### 5.2 Pipeline Orchestration

Pipelines are Python functions using KFP v2 SDK, compiled to YAML for Vertex AI.

```
┌──────────┐    ┌──────────────┐    ┌───────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Prepare  │───▶│ Engineer     │───▶│ Train     │───▶│ Evaluate │───▶│ Register │───▶│ Deploy   │
│ Dataset  │    │ Features     │    │ Model     │    │ (golden  │    │ Model    │    │ Endpoint │
│ (BQ→GCS) │    │ (BQ/Spark)   │    │ (Vertex   │    │  test)   │    │ (Vertex  │    │ (Vertex  │
│          │    │              │    │  AI Job)  │    │          │    │  AI MR)  │    │  AI EP)  │
└──────────┘    └──────────────┘    └───────────┘    └──────────┘    └──────────┘    └──────────┘
                                                          │
                                                    Eval gate pass?
                                                    ─ Yes → register + deploy
                                                    ─ No  → log failure, stop
```

| Pipeline                | Trigger                                    | Purpose                                 |
| ----------------------- | ------------------------------------------ | --------------------------------------- |
| `training-pipeline`     | Manual or Cloud Scheduler (weekly/monthly) | Full train + eval + register + deploy   |
| `evaluation-pipeline`   | Cloud Scheduler (nightly) or on-demand     | Run champion against latest golden set  |
| `data-refresh-pipeline` | Cloud Scheduler (daily)                    | ETL + feature engineering refresh       |
| `baseline-comparison`   | After any training run                     | Compare candidate vs. few-shot baseline |

### 5.3 Experiment Tracking

Each training run logs to **Vertex AI Experiments**:

- **Parameters:** Hyperparameters, base model, dataset version, feature set
- **Metrics:** Loss, per-axis P/R/F1, overall F1, training time
- **Artifacts:** Model checkpoint path, eval results, training config
- **System:** Hardware (GPU type, memory), framework versions

**TensorBoard** (integrated with Vertex AI) provides training curve visualization and cross-run metric comparison. **Vertex AI Workbench** (managed Jupyter) supports ad-hoc experimentation and EDA on BigQuery data.

### 5.4 Hyperparameter Tuning

**Vertex AI Vizier** runs hyperparameter sweeps with Bayesian optimization. Configurable search spaces for learning rate, batch size, LoRA rank, etc. Max 20 trials, 2 parallel. Best config auto-selected by target metric (F1).

---

## 6. Serving Platform

### 6.1 Endpoints

Custom models are deployed to **Vertex AI Endpoints** with auto-scaling and scale-to-zero.

| Endpoint       | Purpose                                              | Scaling      |
| -------------- | ---------------------------------------------------- | ------------ |
| `serving-dev`  | Latest candidate model, consumed by dev environments | min 0, max 1 |
| `serving-prod` | Promoted champion model, consumed by production      | min 0, max 2 |

At 10K inferences/month (~0.2 QPS), endpoints spend most time scaled down. Cold start latency (~10–30s) is acceptable. If sub-second cold start is needed: set `min_replica_count = 1` (~$50–100/month per endpoint).

The serving container is a FastAPI server that loads a model at startup and exposes prediction endpoints. It computes features inline (Phase 0) or fetches pre-computed features (Phase 1+), runs inference, and logs predictions to BigQuery asynchronously.

### 6.2 Prediction API

**Classification:**

```
POST /predict/classify

Request:
{
  "text": "Case narrative text...",
  "case_id": "abc-123",
  "features": { ... }            // optional pre-computed features
}

Response:
{
  "prediction": {
    "labels": {
      "INTENT": {"code": "INTENT.ROMANCE", "confidence": 0.92},
      "CHANNEL": {"code": "CHANNEL.SOCIAL_MEDIA", "confidence": 0.87}
    },
    "risk_score": 78.5
  },
  "model_info": {
    "model_id": "fraud_classifier_gemma2b",
    "version": 3,
    "stage": "champion"
  },
  "prediction_id": "pred-uuid-123"
}
```

**Feedback:**

```
POST /feedback

Request:
{
  "prediction_id": "pred-uuid-123",
  "case_id": "abc-123",
  "correction": {
    "INTENT": {"code": "INTENT.INVESTMENT", "confidence": 1.0}
  },
  "analyst_id": "analyst@example.com"
}
```

Consumers call `/predict/*` for inference and `/feedback` when a human corrects a prediction.

### 6.3 Prediction & Outcome Logging

Every prediction is logged to BigQuery `predictions/prediction_log` with: prediction ID, case ID, model ID + version, endpoint, capability, complete feature vector, full prediction output, latency, and timestamp.

When feedback arrives, it is logged to `predictions/outcome_log` linked by prediction ID.

**The prediction + outcome join is the foundation of continuous learning:** it provides per-model accuracy over time, training data generation (outcomes become labels), and feature importance analysis.

### 6.4 Batch Prediction

For bulk processing (e.g., re-classify all historical cases with a new model): Vertex AI Batch Prediction reads from BigQuery or GCS, runs a registered model, and writes results using the same prediction_log schema.

---

## 7. Model Registry & Promotion

### 7.1 Stages

All models are registered in **Vertex AI Model Registry** with metadata: model ID, version, framework, artifact URI, capability, eval metrics, training pipeline run ID, and dataset version.

```
experimental ──eval gate──▶ candidate ──shadow + approval──▶ champion
```

1. **Experimental** — just trained, eval results logged. Auto-promoted to candidate if eval gate passes.
2. **Candidate** — deployed to `serving-dev`. Optionally runs in shadow mode alongside champion on `serving-prod` (logged but not returned to caller).
3. **Champion** — deployed to `serving-prod`. One champion per capability. Previous champion becomes rollback target.

### 7.2 Eval Gate (Automated)

- Overall F1 ≥ current champion F1 (no regression)
- No per-axis regression > 5%
- If no champion exists: any model passes (Phase 0 default)

### 7.3 Rollback

Re-deploy previous champion version to `serving-prod`. Vertex AI Endpoint version swap (~2 min).

---

## 8. Monitoring & Continuous Learning

### 8.1 Drift Detection

**Vertex AI Model Monitoring** on production endpoints detects:

- **Input drift:** Feature distributions shift vs. training data
- **Prediction drift:** Prediction distributions shift over time
- **Feature skew:** Training-time features differ from serving-time features

Alerts go to Cloud Monitoring → notification channels.

### 8.2 Accuracy Monitoring

BigQuery scheduled query (daily) joins `prediction_log` with `outcome_log` to compute rolling accuracy per model per capability. Dashboard shows accuracy over time, correction rate trends, and top error patterns.

### 8.3 Cost Monitoring

Per-capability cost tracking from GCP billing export: Vertex AI Endpoint compute, training job costs, BigQuery query costs, per-prediction average cost. Compared against LLM API costs to demonstrate ROI.

### 8.4 Continuous Learning (Phase 2+)

**Retraining triggers:**

- **Data volume:** New outcomes exceed threshold since last training (e.g., 200+ new labels)
- **Drift alert:** Model monitoring detects significant drift
- **Scheduled:** Monthly retraining as baseline cadence
- **Manual:** Data scientist trigger after review

The retraining pipeline is the same training pipeline — only the trigger changes.

---

## 9. Consumer Integration

### 9.1 Dependency Model

| Direction                  | Dependency                                                                    |
| -------------------------- | ----------------------------------------------------------------------------- |
| **ML Platform ← data**     | ETL jobs read from source databases on a schedule. No runtime coupling.       |
| **Consumer → ML Platform** | Consumers call prediction endpoints (`/predict/*`). Standard HTTP.            |
| **Consumer → ML Platform** | Consumers send feedback (`/feedback`). Optional, enables continuous learning. |

No shared databases, no library imports, no code coupling. The platform's monitoring and evaluation are internal — they create no dependency on consumers.

### 9.2 Consumer Configuration (I4G Example)

I4G core needs only an HTTP client and a few settings:

```toml
# core/config/settings.default.toml
[ml]
inference_backend = "llm"           # "llm" | "ml_platform"
platform_base_url = ""              # ML platform endpoint URL
platform_auth_method = "iam"        # "iam" | "api_key" | "none"
fallback_to_llm = true              # fall back to LLM if ML endpoint unavailable
```

```python
# core/src/i4g/ml/client.py  — thin HTTP client

class MLPlatformClient:
    async def classify(self, text: str, case_id: str) -> dict: ...
    async def send_feedback(self, prediction_id: str, case_id: str,
                            correction: dict, analyst_id: str) -> None: ...
```

A `build_inference_client()` factory routes to `MLPlatformClient` or falls back to the existing LLM classifier based on configuration.

### 9.3 Migration Path

- **Phase 0:** I4G continues using LLM for classification. ML platform trains and evaluates independently. Shadow mode validates.
- **Phase 1:** Dual path — configuration switches between LLM and ML platform.
- **Phase 2+:** ML platform is primary for supported capabilities. LLM remains the always-available fallback.

### 9.4 Responsibility Boundary (I4G Example)

| I4G (application concerns)                            | ML Platform                                         |
| ----------------------------------------------------- | --------------------------------------------------- |
| Analyst corrections CRUD, UI-facing label API         | Model training, evaluation, serving                 |
| Case data, entity data, review queue                  | Feature engineering, dataset management             |
| LLM direct calls (RAG, report generation, SSI agent)  | Prediction/outcome logging, model registry          |
| `analyst_labels` table (stores corrections in app DB) | Monitoring, drift detection, continuous improvement |

---

## 10. Repository Structure

```
ml/                                    # Workspace root
├── .github/
│   └── copilot-instructions.md
├── pyproject.toml
├── Makefile
├── README.md
├── VERSION.txt
│
├── src/
│   └── ml_platform/
│       ├── __init__.py
│       ├── config.py                  # Settings
│       ├── data/
│       │   ├── etl.py                 # ETL logic (source DB → BigQuery)
│       │   ├── features.py            # Feature definitions
│       │   ├── datasets.py            # Dataset creation, versioning
│       │   ├── validation.py          # Data quality checks
│       │   └── pii.py                 # PII redaction for training data
│       ├── training/
│       │   ├── pipeline.py            # KFP pipeline definitions
│       │   ├── config.py              # Training config schemas
│       │   └── evaluation.py          # Eval harness, golden set, metrics
│       ├── serving/
│       │   ├── app.py                 # FastAPI prediction server
│       │   ├── predict.py             # Prediction logic
│       │   ├── features.py            # Feature serving / on-the-fly computation
│       │   └── logging.py             # Prediction + outcome logging
│       ├── registry/
│       │   ├── models.py              # Model registry helpers
│       │   └── promotion.py           # Promotion workflow, eval gates
│       └── monitoring/
│           ├── drift.py
│           ├── accuracy.py
│           └── cost.py
│
├── containers/
│   ├── train-pytorch/
│   │   ├── Dockerfile
│   │   └── train.py
│   ├── train-xgboost/
│   │   ├── Dockerfile
│   │   └── train.py
│   └── serve/
│       ├── Dockerfile
│       └── serve.py
│
├── pipelines/
│   ├── training_pipeline.py
│   ├── evaluation_pipeline.py
│   ├── data_refresh_pipeline.py
│   └── configs/
│       ├── classification_gemma2b.yaml
│       └── classification_xgboost.yaml
│
├── notebooks/
│   ├── eda/
│   ├── experiments/
│   └── evaluation/
│
├── tests/
│   ├── unit/
│   └── integration/
│
├── config/
│   ├── settings.default.toml
│   └── settings.dev.toml
│
├── scripts/
│   ├── build_container.sh
│   └── deploy_endpoint.sh
│
└── docs/
    └── design/
        └── ml_platform_tdd.md
```

### Infrastructure (in `infra/` repo)

```
infra/
├── stacks/ml/                         # ML platform infrastructure stack
├── environments/ml/                   # i4g-ml project environment
└── modules/
    ├── vertex_ai/                     # New modules
    │   ├── endpoint/
    │   ├── pipeline/
    │   └── workbench/
    └── bigquery/dataset/
```

---

## 11. Scope

### In Scope

- ML Platform repository (`ml/`) — structure, build system, CI
- GCP project provisioning (`i4g-ml`) — Terraform stack in `infra/`
- Data pipeline: source Cloud SQL → BigQuery (ETL Cloud Run Job)
- Feature engineering: SQL-based features in BigQuery
- Training infrastructure: Vertex AI Training + Pipelines (first model: classification)
- Model serving: Vertex AI Endpoints with FastAPI serving container
- Model registry: Vertex AI Model Registry with promotion workflow
- Prediction + outcome logging: BigQuery
- Evaluation harness: golden test set, per-axis metrics, regression gates
- Baseline benchmark: few-shot vs. custom model comparison
- Monitoring: Vertex AI Model Monitoring, BigQuery analytics
- Notebooks: Vertex AI Workbench for experimentation
- Prediction API contract
- I4G core changes: `MLPlatformClient` (thin HTTP client), `analyst_labels` table, configuration

### Out of Scope

- **Analyst correction UI** — separate Analyst Feedback Loop PRD; this PRD provides the backend schema
- **Embedding fine-tuning** — separate workstream; the platform supports it once ready
- **OCR modernization** — separate PRD
- **Real-time streaming inference** — batch + request/response is sufficient at current volume
- **Self-hosted orchestration** (Airflow, Prefect) — Vertex AI Pipelines; revisit if needed
- **Multi-region deployment** — single region (`us-central1`) is sufficient

---

## 12. Phased Delivery

### Phase 0 — Foundation (Platform Skeleton + First Model)

**Goal:** Stand up the ML platform end-to-end. Train a first model (classification) and deploy it to a serving endpoint. Prove pipeline completeness — model quality does not matter yet.

| #   | Deliverable                                            | Exit criteria                                                          |
| --- | ------------------------------------------------------ | ---------------------------------------------------------------------- |
| 1   | `ml/` repo created with structure from §10             | Repo exists, builds, tests pass                                        |
| 2   | `i4g-ml` GCP project provisioned (Terraform)           | Project exists, APIs enabled, SA created                               |
| 3   | GCS bucket `i4g-ml-data` provisioned                   | Bucket exists with path structure                                      |
| 4   | BigQuery dataset `i4g_ml` with `raw/` tables           | Schema created, empty tables exist                                     |
| 5   | ETL Cloud Run Job: source Cloud SQL → BigQuery         | Cases, classifications, entities synced daily                          |
| 6   | Feature engineering: SQL-based features                | `features/case_features` table populated                               |
| 7   | Bootstrap dataset: export first training set           | JSONL in GCS, registered in BigQuery metadata                          |
| 8   | Golden test set curated                                | Manually verified subset, version-controlled                           |
| 9   | Eval harness                                           | Runs model against golden set, outputs per-axis P/R/F1                 |
| 10  | Baseline benchmark                                     | Current few-shot F1 per axis measured and recorded                     |
| 11  | Training container (PyTorch, Gemma 2B / LoRA)          | Container builds, trains locally and on Vertex AI                      |
| 12  | Vertex AI Pipeline: train → eval → register            | Pipeline runs end-to-end                                               |
| 13  | Serving container (FastAPI)                            | Container builds, serves predictions locally and on Vertex AI Endpoint |
| 14  | Vertex AI Endpoint `serving-dev` deployed              | Endpoint returns predictions                                           |
| 15  | Prediction logging to BigQuery                         | Every prediction logged with features and model info                   |
| 16  | `analyst_labels` table in I4G core (Alembic migration) | Migration runs on SQLite + PostgreSQL                                  |
| 17  | `MLPlatformClient` in I4G core (thin HTTP client)      | Core can call ML platform endpoint                                     |
| 18  | Notebook: evaluation results visualization             | Jupyter notebook showing per-axis metrics                              |

**Exit criteria:** Data flows from source to BigQuery. A model is trained and deployed. Predictions are served and logged. Baseline is measured. The system works end-to-end.

### Phase 1 — Data Platform Maturity

| #   | Deliverable                                             | Exit criteria                                           |
| --- | ------------------------------------------------------- | ------------------------------------------------------- |
| 1   | Outcome logging (feedback API)                          | Analyst corrections flow to BigQuery                    |
| 2   | Automated dataset refresh with new outcomes             | Pipeline re-exports training data including corrections |
| 3   | Compute-heavy features (Spark on Dataproc Serverless)   | Network/graph features computed                         |
| 4   | Data quality dashboard                                  | Label distribution, staleness, quality metrics visible  |
| 5   | PII redaction in training export                        | Redacted text verified                                  |
| 6   | Second training framework (XGBoost on tabular features) | XGBoost model trained, evaluated, compared              |
| 7   | `serving-prod` endpoint                                 | Production endpoint deployed and serving                |

**Exit criteria:** Feedback loop operational. Multiple frameworks demonstrated. Production serving active. ≥ 200 real analyst labels.

### Phase 2 — Training Maturity + Continuous Learning

| #   | Deliverable                                                       | Exit criteria                                     |
| --- | ----------------------------------------------------------------- | ------------------------------------------------- |
| 1   | Vertex AI Vizier hyperparameter tuning                            | Automated sweep, best config auto-selected        |
| 2   | Shadow mode (candidate on prod, logged but not returned)          | Shadow predictions logged, compared to champion   |
| 3   | Continuous retraining pipeline (triggered by data volume / drift) | Retraining runs automatically when conditions met |
| 4   | Vertex AI Model Monitoring enabled on prod endpoint               | Drift / skew alerts working                       |
| 5   | Accuracy dashboard (predictions vs. outcomes)                     | Rolling accuracy per model per capability visible |
| 6   | Cost comparison (ML platform vs. LLM API)                         | Per-capability ROI calculated                     |
| 7   | NER model (entity extraction) trained and deployed                | Second capability on the platform                 |

**Exit criteria:** Continuous learning loop operational. Monitoring active. ≥ 2 capabilities. ≥ 500 labeled examples.

**Status:** Phase 2 code complete. Remaining items (NER E2E deployment, shadow activation, graph features verification) deferred to Phase 3 carry-overs.

### Phase 3 — Advanced Capabilities

| #   | Deliverable                                                | Exit criteria                           |
| --- | ---------------------------------------------------------- | --------------------------------------- |
| 1   | Champion/challenger A/B routing on endpoints               | Traffic splitting with outcome tracking |
| 2   | Batch prediction for historical re-classification          | Backfill job runs on full case corpus   |
| 3   | Feature store (Vertex AI Feature Store) for online serving | Sub-100ms feature retrieval             |
| 4   | Additional capabilities: risk scoring, document similarity | ≥ 4 capabilities on platform            |
| 5   | Cost-aware routing (cheapest model meeting quality bar)    | Factory considers cost + quality        |

**Exit criteria:** Multi-capability, continuously improving. Platform matures into steady-state operations.

---

## 13. Risks & Mitigations

| Risk                                          | Impact                                 | Mitigation                                                                                |
| --------------------------------------------- | -------------------------------------- | ----------------------------------------------------------------------------------------- |
| **Insufficient labeled data**                 | Custom models underperform few-shot    | Bootstrap from existing data. Data gates (500+/axis) before promotion. Few-shot fallback. |
| **Platform complexity exceeds team capacity** | Infrastructure becomes its own project | Strict phasing. GCP-managed services. Phase 0 proves end-to-end before expanding.         |
| **Model regression in production**            | Accuracy degrades                      | Eval gate. Shadow period. Instant rollback via Vertex AI Endpoint version swap.           |
| **Cross-project data access**                 | ETL requires cross-project IAM         | Cloud SQL Auth Proxy. Read-only service account.                                          |
| **Cold start latency**                        | Scale-to-zero has 10–30s cold start    | Acceptable at 10K/month. Set `min_replicas=1` if latency is critical.                     |
| **PII in training data**                      | Regulatory risk                        | PII redaction pipeline. BigQuery column-level security. Legal review before Phase 1.      |
| **Vendor lock-in (GCP)**                      | Hard to move to another cloud          | Containerized training. Standard artifact formats (ONNX, SafeTensors). BigQuery export.   |

---

## 14. Success Metrics

| Metric                          | Phase 0             | Phase 1               | Phase 2               | Phase 3                  |
| ------------------------------- | ------------------- | --------------------- | --------------------- | ------------------------ |
| **Classification F1**           | Baseline measured   | Measured              | Custom ≥ baseline     | Custom > baseline by 5%+ |
| **Labeled dataset size**        | Bootstrap (~50–100) | 200+ analyst labels   | 500+                  | 1,000+                   |
| **Pipeline completeness**       | End-to-end skeleton | Feedback loop working | Continuous retraining | Multi-capability         |
| **Capabilities on platform**    | 1 (classification)  | 1 + data maturity     | 2 (+ NER)             | 4+                       |
| **Prediction logging coverage** | 100%                | 100%                  | 100%                  | 100%                     |
| **Outcome capture rate**        | —                   | ≥ 10%                 | ≥ 20%                 | ≥ 30%                    |
| **Regression detection time**   | —                   | —                     | < 24 hours            | < 12 hours               |

---

## 15. Open Questions

1. **Google for Nonprofits eligibility:** Confirm qualification for $10K/year GCP credits.
2. **Read replica for ETL:** Does I4G have a Cloud SQL read replica? If not, ETL reads from primary during off-peak.
3. **Authentication:** IAP, API key, or service account token between consumers and ML endpoints? IAM is simplest for GCP-to-GCP.
4. **Bootstrap golden set verification:** How much manual verification before trusting baseline metrics? Minimum: 20% random sample review.
5. **LLM API cost tracking in core:** Structured logging + BigQuery log sink, or `llm_usage_log` table?

---

## 16. Dependencies

### This PRD Depends On

Nothing — foundational infrastructure.

### Other Work That Depends On This

- **Analyst Feedback Loop PRD** — uses `analyst_labels` table; feedback API connects to ML platform
- **OCR Modernization PRD** — can use the evaluation harness
- **Any future ML capability PRD** — consumes the platform

### External Dependencies

- GCP project creation (requires org-level admin)
- Google for Nonprofits enrollment
- Vertex AI API enablement in `i4g-ml` project

---

## References

- [ML Strategy & Roadmap](ml_strategy.md)
- [Fraud Taxonomy PRD](prd_fraud_taxonomy.md)
- [ML Platform TDD](../core/docs/design/ml_infrastructure_tdd.md) — technical design
