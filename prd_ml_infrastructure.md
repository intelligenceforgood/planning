# ML Infrastructure & Pipeline (PRD)

**Scope:** End-to-end ML platform — data, training, evaluation, serving, monitoring (Phases 0–4 of the [ML Strategy & Roadmap](ml_strategy.md))

**Date:** March 2026</br>
**Status:** Draft PRD v2.0

---

## 1. Problem Statement

I4G ships real ML features — fraud classification, entity extraction, risk scoring, RAG-powered assessments, and autonomous scam site investigation — all powered by **third-party foundation models via prompting**. There is no training pipeline, no labeled dataset, no model registry, no evaluation harness, and no ability to deploy our own models.

The application layer is surprisingly mature; the infrastructure layer is nearly absent. We are building on sand:

- **No data lifecycle.** There is no labeled dataset, no dataset versioning, no feature store, no export pipeline. Analyst corrections have nowhere to go. Without data infrastructure, custom models are permanently out of reach.
- **No training pipeline.** There is no experiment tracking, no reproducible training workflow, no hyperparameter management, no model artifact storage. We cannot fine-tune a model even if we had labeled data.
- **No evaluation harness.** We cannot state the precision or recall of fraud classification on any axis. A prompt edit or model upgrade could silently degrade accuracy and we would not know.
- **No model registry or serving abstraction.** Every classifier, extractor, and scorer calls the LLM provider directly. There is no model registry, no versioned artifact storage, no promotion workflow, no ability to A/B test or shadow-deploy a candidate model. Introducing a custom model would require rewriting every call site.
- **No operational observability for ML.** Prompts are unversioned. Core has no cost tracking (SSI tracks per-session tokens only). There is no drift detection, no accuracy monitoring, no alerting on classification degradation.

This PRD defines **the complete ML platform** — data collection, dataset management, training pipelines, evaluation, model registry, unified inference, A/B testing, and monitoring — so that once designed and built, the team never has to retrofit missing platform pieces. Implementation is phased over multiple sprints, but the architecture is overarching and covers the entire lifecycle.

### Why Now

We have enough production data to bootstrap. Existing `classification_result` records, `cases.tags`, entity extractions, and risk scores can serve as an initial golden set. We can build and validate the end-to-end pipeline — data → training → evaluation → serving — using this bootstrapped data and compare custom model performance against the current few-shot prompt baseline. No external dependencies block Phase 0.

---

## 2. Solution Overview

Build a four-layer ML platform that supports the full model lifecycle, with a feedback loop from analyst corrections back into the pipeline:

### Layer 1 — Data

- **Label database** (`analyst_labels`) — stores analyst corrections (classification overrides, risk score adjustments, entity corrections, disposition outcomes)
- **Dataset registry** — versioned JSONL snapshots in GCS, referenced by a metadata table in the main DB; immutable once published
- **Feature store** — pre-computed, versioned features (case text, entity counts, structural attributes) ready for model training
- **Export pipeline** — CLI tooling to produce train/eval/test splits from the label database and bootstrap data, with stratification and reproducibility guarantees
- **Data quality** — validation rules on exported datasets, distribution checks, automated staleness detection

### Layer 2 — Training

- **Experiment tracking** (W&B, with MLflow as fallback) — hyperparameters, metrics, artifacts, reproducibility metadata
- **Training pipelines** — reproducible end-to-end workflows: data loading → preprocessing → training → evaluation → artifact export
- **Fine-tuning framework** — starting with Gemma 2B on classification; per-axis and multi-task configurations
- **Baseline benchmarking** — automated comparison of every candidate model against the current few-shot prompt baseline; a model that doesn't beat few-shot does not promote

### Layer 3 — Serving

- **Model registry** — GCS-backed artifact store with stage management (dev → staging → production), versioning, lineage tracking, and rollback
- **Unified inference framework** — `ModelClient` protocol + `build_model_client()` factory; application code programs against the protocol, the factory routes to LLM API, custom model endpoint, or mock transparently
- **A/B traffic router** — percentage-based traffic splitting between model versions, with outcome tracking
- **Shadow mode** — run a candidate model in parallel with production; both predict, only production output is used; enables risk-free comparison
- **Serving backends** — Vertex AI Endpoints (production), Cloud Run + FastAPI (lightweight/experimental), Ollama (local testing)

### Layer 4 — Monitoring

- **Accuracy tracking** — continuous measurement of model predictions vs. analyst labels; per-capability, per-axis dashboards
- **Cost tracking** — per-call token/cost/latency logging (`llm_usage_log` table), per-capability cost attribution, budget alerting
- **Prompt versioning** — version stamps on all prompt templates, logged with every LLM call for regression traceability
- **Drift detection** — distribution shift alerts on model inputs and outputs; triggers re-evaluation or retraining
- **Latency tracking** — P50/P95/P99 inference latency per capability and backend

### Design Principles

1. **Few-shot prompting remains the baseline and fallback forever.** Custom models are additive. Every capability must work with LLM-only mode.
2. **Infrastructure first, models second.** Build the pipeline end-to-end before investing in model quality. A mediocre model on solid infrastructure beats a great model on nothing.
3. **Bootstrap from existing data.** Use current production records as the initial golden set. Real analyst labels arrive later and improve quality incrementally.
4. **Application code is model-agnostic.** Classifiers, extractors, and scorers call `ModelClient`. They never know whether the backend is Gemini, a fine-tuned Gemma, or a mock.
5. **Every model change is measurable.** No model reaches production without passing eval gates. No prompt change ships without regression testing.

---

## 3. Scope

### 3.1 In Scope

**Data layer:**

- `analyst_labels` table, Alembic migration, CRUD API
- Dataset registry (metadata table + GCS JSONL storage)
- Export pipeline CLI (`i4g data export`) — train/eval/test splits with stratification
- Bootstrap dataset from existing production records
- Feature extraction pipeline for structured case attributes
- Data validation and distribution checks on exported datasets

**Training layer:**

- Experiment tracking integration (W&B)
- Reproducible training pipeline (data load → preprocess → train → eval → artifact export)
- Fine-tuning scripts for classification (Gemma 2B, per-axis and multi-task)
- Baseline benchmark pipeline — automated few-shot vs. custom model comparison
- Hyperparameter configuration and sweep support

**Evaluation layer:**

- Golden test set curation and storage (JSONL, version-controlled)
- Evaluation harness CLI (`i4g eval run`, `i4g eval report`) — per-axis P/R/F1, extensible to other capabilities
- Regression gates — model promotion requires eval score ≥ baseline
- Evaluation dataset versioning and refresh workflow

**Serving layer:**

- Model registry (GCS artifacts, metadata table, stage management)
- `ModelClient` protocol and `build_model_client()` factory
- `LLMModelClient` (wraps existing provider) and `CustomModelClient` (calls model endpoints)
- A/B routing and shadow mode in the factory
- Serving backend integration (Vertex AI Endpoints, Cloud Run, Ollama)
- Migration of `FraudClassifier` and `SemanticNER` to `ModelClient`

**Monitoring layer:**

- `llm_usage_log` table (tokens, cost, latency, capability, prompt version, model)
- Cost tracking in all core LLM call paths (extending SSI's `CostTracker`)
- Prompt version stamps on all templates; version logged with every LLM call
- Drift detection on input/output distributions
- Cost reporting CLI and admin API

**Cross-cutting:**

- Configuration sections (`I4G_EVAL__*`, `I4G_COST__*`, `I4G_ML__*`, `I4G_DATA__*`, `I4G_TRAINING__*`)
- Unit tests for all new components (≥ 90% coverage on new code)
- TDD before implementation begins

### 3.2 Out of Scope

- **Analyst correction UI** — that is the Analyst Feedback Loop PRD; this PRD provides the backend schema and API it will call
- **Embedding evaluation or fine-tuning** — separate initiative; domain-tuned embeddings are a distinct workstream
- **OCR modernization** (Document AI integration) — separate PRD
- **Advanced ML features** (auto-summarization, duplicate detection, predictive escalation, image similarity) — these consume the platform but are scoped in separate feature PRDs
- **Federated learning / cross-partner data sharing** — long-term; requires legal framework
- **Real-time streaming inference** — current workloads are request/response; streaming is a future optimization

---

## 4. Architecture

> **Note:** This section defines the platform architecture at PRD depth — enough to scope the work, identify components, and define integration points. A Technical Design Document (TDD) must be written and reviewed before implementation begins (see §5). The TDD will specify protocol signatures, schema DDL, API contracts, and implementation details.

### 4.1 Platform Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          APPLICATION LAYER                              │
│   FraudClassifier · SemanticNER · RAGChain · SSI Classifier · ...       │
│                              │                                          │
│                       ┌──────┴───────┐                                  │
│                       │ ModelClient  │  ← protocol interface            │
│                       │  Protocol    │                                  │
│                       └──────┬───────┘                                  │
├──────────────────────────────┼──────────────────────────────────────────┤
│                        SERVING LAYER                                    │
│                              │                                          │
│                  ┌───────────┴────────────┐                             │
│                  │  build_model_client()  │  ← factory + router         │
│                  │  - model registry      │                             │
│                  │  - A/B routing policy  │                             │
│                  │  - shadow mode         │                             │
│                  └───────────┬────────────┘                             │
│                              │                                          │
│              ┌───────────────┼───────────────┐                          │
│              ▼               ▼               ▼                          │
│        LLM Provider    Custom Model     Shadow Runner                   │
│        (Gemini/Ollama/ (Vertex AI EP/   (parallel eval,                 │
│         Mock)           Cloud Run/       discard output)                │
│                         Ollama)                                         │
│                                                                         │
│  ┌────────────────┐                                                     │
│  │ Model Registry │  GCS artifacts + metadata table                     │
│  │ dev → staging  │  Versioned, with lineage + eval scores              │
│  │ → production   │  Rollback = promote previous version                │
│  └────────────────┘                                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                        TRAINING LAYER                                   │
│                                                                         │
│  ┌──────────────┐  ┌──────────────────┐  ┌─────────────────────┐        │
│  │ Experiment   │  │ Training         │  │ Baseline            │        │
│  │ Tracker      │  │ Pipeline         │  │ Benchmark           │        │
│  │ (W&B)        │  │ (reproducible)   │  │ (few-shot vs.       │        │
│  │              │  │                  │  │  custom model)      │        │
│  └──────────────┘  └──────────────────┘  └─────────────────────┘        │
│         │                   │                      │                    │
│         └───────────────────┴──────────────────────┘                    │
│                             │                                           │
│                    ┌────────┴────────┐                                  │
│                    │  Eval Harness   │  Golden test set + metrics       │
│                    │  (P/R/F1 gate)  │  Regression gate on promotion    │
│                    └────────┬────────┘                                  │
│                             │                                           │
├─────────────────────────────┼───────────────────────────────────────────┤
│                         DATA LAYER                                      │
│                             │                                           │
│  ┌──────────────┐  ┌────────┴─────────┐  ┌─────────────────────┐        │
│  │ Label        │  │ Dataset          │  │ Feature             │        │
│  │ Database     │  │ Registry         │  │ Store               │        │
│  │ (analyst_    │  │ (versioned JSONL │  │ (pre-computed       │        │
│  │  labels)     │  │  in GCS)         │  │  case features)     │        │
│  └──────┬───────┘  └──────────────────┘  └─────────────────────┘        │
│         │                                                               │
│  ┌──────┴───────┐                                                       │
│  │ Export       │  Train/eval/test splits, stratified, reproducible     │
│  │ Pipeline     │  Bootstrap from existing data OR analyst labels       │
│  └──────────────┘                                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                       MONITORING LAYER                                  │
│                                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────┐  ┌──────────────┐     │
│  │ Cost         │  │ Prompt       │  │ Drift    │  │ Accuracy     │     │
│  │ Tracker      │  │ Registry     │  │ Detector │  │ Tracker      │     │
│  │ (llm_usage_  │  │ (versioned)  │  │          │  │ (model vs.   │     │
│  │  log)        │  │              │  │          │  │  analyst)    │     │
│  └──────────────┘  └──────────────┘  └──────────┘  └──────────────┘     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

                    ◄── Feedback Loop ──►
         Analyst corrections → labels → datasets → training
              → better models → fewer corrections needed
```

### 4.2 Key Abstractions

#### ModelClient Protocol

```python
class ModelClient(Protocol):
    """Unified interface for model inference — LLM API or custom model."""

    async def classify(self, text: str, **kwargs) -> ClassificationResult: ...
    async def extract_entities(self, text: str, **kwargs) -> list[Entity]: ...
    async def generate(self, prompt: str, **kwargs) -> str: ...

    @property
    def model_info(self) -> ModelInfo: ...
```

Application code programs against `ModelClient`. The factory decides which backend serves the request.

#### build_model_client() Factory

```python
def build_model_client(
    capability: str,        # e.g. "classification", "ner", "rag"
    settings: Settings,
) -> ModelClient:
    """
    Route to the appropriate model backend for a given capability.

    Checks the model registry for the active model version for this capability.
    Applies A/B routing policy if configured. Falls back to LLM provider if
    no custom model is registered or if the custom model is in shadow-only mode.
    """
```

In Phase 0, this always returns an `LLMModelClient`. In later phases, it checks the model registry, applies routing rules, and may return a `CustomModelClient` or a `ShadowRunner` that calls both.

#### Dataset Registry

```python
class DatasetEntry:
    dataset_id: str              # e.g. "classification_v3"
    version: int                 # auto-incrementing
    split: str                   # "train", "eval", "test"
    gcs_path: str                # gs://i4g-ml-datasets/classification_v3/train.jsonl
    record_count: int
    label_distribution: dict     # e.g. {"INTENT.ROMANCE": 42, "INTENT.INVESTMENT": 87, ...}
    created_at: datetime
    created_by: str              # pipeline run ID or user
    parent_dataset_id: str | None  # lineage — derived from which dataset?
    metadata: dict               # export params, stratification config, filters applied
```

Datasets are immutable once published. New versions are created for re-exports. The metadata table lives in the main DB; the JSONL files live in GCS.

#### Model Registry

```python
class ModelEntry:
    model_id: str                # e.g. "fraud_classifier_gemma2b"
    version: int                 # auto-incrementing
    capability: str              # "classification", "ner", etc.
    stage: str                   # "dev", "staging", "production"
    artifact_path: str           # gs://i4g-ml-models/fraud_classifier_gemma2b/v3/
    eval_scores: dict            # {"axis_a_f1": 0.87, "axis_b_f1": 0.91, ...}
    baseline_comparison: dict    # {"few_shot_f1": 0.82, "delta": +0.05}
    training_run_id: str         # W&B run ID for full reproducibility
    dataset_version: str         # which dataset was it trained on
    created_at: datetime
    promoted_at: datetime | None
    promoted_by: str | None
    metadata: dict               # hyperparams, training config, hardware used
```

Promotion workflow: dev → staging (passes eval gate) → production (manual approval + shadow period).

#### Training Pipeline

```
┌──────────┐     ┌────────────┐     ┌───────────┐     ┌──────────┐     ┌──────────┐
│  Export  │────▶│ Preprocess │────▶│  Train    │────▶│ Evaluate │────▶│ Register │
│  Dataset │     │ & Feature  │     │ (W&B      │     │ (golden  │     │ Artifact │
│  (CLI)   │     │  Engineer  │     │  tracked) │     │  test)   │     │ (GCS)    │
└──────────┘     └────────────┘     └───────────┘     └──────────┘     └──────────┘
     │                                                     │                │
     │                                              Pass eval gate?         │
     │                                              ─ Yes → register        │
     │                                              ─ No  → log & stop      │
     └────── Data from: label DB + bootstrap ───────────────────────────────┘
```

Each step is a standalone CLI command. The pipeline is a composition of steps. Experiment tracking wraps the train + evaluate steps.

#### CostTracker (Extended)

Adapt SSI's existing `CostTracker` pattern for core. Every LLM or model inference call records:

- Timestamp, capability, prompt version, model name/version
- Input/output token counts, estimated cost
- Latency (wall-clock ms)
- Whether this was a shadow call or production call

Persisted to `llm_usage_log` table. Queryable for per-capability cost reporting and custom-model-vs-LLM cost comparison.

#### Prompt Version Scheme

Each prompt template gets a version header:

```markdown
---
prompt_version: "fraud_classifier.v3"
last_modified: "2026-03-15"
capability: "classification"
---
```

The version string is logged with every LLM call. Format: `<template_name>.v<N>`.

### 4.3 Integration Points

| Component          | Integrates with                                       | How                                                                                            |
| ------------------ | ----------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Label database     | PostgreSQL / SQLite (via SQLAlchemy)                  | New `analyst_labels` table; CRUD via FastAPI endpoints                                         |
| Export pipeline    | Label DB + existing production tables                 | Reads labels + bootstrap data; writes versioned JSONL to GCS; registers in dataset registry    |
| Feature store      | Case data, entity extractions, classification results | Pre-computes structured features; stored as columns in exported JSONL                          |
| Experiment tracker | W&B API                                               | Training pipeline logs params, metrics, artifacts to W&B; eval harness logs comparison results |
| Training pipeline  | Export pipeline output → model artifacts              | Reads JSONL datasets; produces model artifacts in GCS; registers in model registry             |
| Eval harness       | Golden test set + any model (LLM or custom)           | Runs model against test set, compares outputs, emits per-axis P/R/F1, gates promotion          |
| Model registry     | GCS + metadata table in main DB                       | Stores model artifacts with stage management; queried by `build_model_client()`                |
| ModelClient        | `FraudClassifier`, `SemanticNER`, `RAGChain`          | Application code migrates from direct provider calls to `ModelClient`                          |
| A/B router         | `build_model_client()` + outcome logging              | Factory applies traffic split; logs which model served each request; tracks outcomes           |
| Shadow runner      | `build_model_client()` + eval comparison              | Runs candidate model in parallel; discards output; logs predictions for offline comparison     |
| Cost tracker       | `LLMProvider` (core), `CostTracker` (SSI)             | Wraps provider calls; writes to `llm_usage_log`; supports custom model cost tracking too       |
| Prompt registry    | All prompt templates (`.md`, inline `.py`)            | Adds version headers; LLM call sites read and propagate version                                |
| Drift detector     | `llm_usage_log` + production predictions              | Monitors input/output distributions; alerts on significant shift                               |
| Settings           | `I4G_*` env vars and TOML config                      | New settings sections following existing patterns                                              |

---

## 5. TDD Requirement

**This PRD requires a Technical Design Document before implementation begins.**

This is architecture-heavy work that introduces new protocols, multiple database tables, cross-cutting concerns, a factory pattern with routing, external service integrations (W&B, GCS, Vertex AI), and a training pipeline. The TDD must cover:

**Data layer:**

- `analyst_labels` and `dataset_registry` table DDL, indexes, constraints
- Feature extraction design — which features, how computed, where stored
- Export pipeline architecture — CLI interface, stratification algorithm, reproducibility guarantees
- GCS bucket structure and naming conventions for datasets and model artifacts
- Data validation rules and distribution checks

**Training layer:**

- W&B integration design — project structure, run naming, artifact logging
- Training pipeline architecture — step interfaces, composition, error handling
- Fine-tuning configuration — model selection, hyperparameter defaults, per-axis vs. multi-task
- Baseline benchmark automation — how few-shot and custom model are compared on the same test set

**Evaluation layer:**

- Eval harness runner design — CLI interface, output format, CI integration
- Golden test set structure, versioning, and refresh workflow
- Regression gate logic — what metrics, what thresholds, what happens on failure

**Serving layer:**

- `ModelClient` protocol — method signatures, error handling, async patterns, timeout/retry
- `build_model_client()` factory — registry lookup, A/B routing, shadow mode, fallback chain
- `CustomModelClient` — Vertex AI Endpoint and Cloud Run client implementations
- Model registry schema — DDL, promotion workflow, rollback mechanics
- A/B routing — traffic split configuration, outcome tracking, statistical significance

**Monitoring layer:**

- `llm_usage_log` table DDL, indexes, partitioning strategy
- `CostTracker` integration — decorator, middleware, or explicit calls
- Prompt version storage and propagation mechanism
- Drift detection algorithm and alerting thresholds
- Accuracy dashboard data pipeline

**Cross-cutting:**

- Migration strategy for existing LLM call sites to `ModelClient`
- PII handling in training data — anonymization requirements
- Test strategy — unit, integration, eval regression, pipeline end-to-end

The TDD should be placed at `core/docs/design/ml_infrastructure_tdd.md` and reviewed before any implementation sprint begins.

---

## 6. Phased Delivery Plan

The strategy roadmap (Phases 0–4) is expanded into implementation sprints. Each phase has explicit exit criteria. Implementation is incremental, but the architecture (this PRD + the TDD) is designed for the entire lifecycle from day one.

**Critical principle:** The end-to-end pipeline is built in Phase 0 using bootstrapped data. We do not wait for analyst labels to validate the data → training → evaluation → serving flow. Existing production records are the initial dataset.

### Phase 0 — Foundation (Infrastructure Skeleton + End-to-End Pipeline)

**Goal:** Build the complete pipeline end-to-end using bootstrapped data. Measure the few-shot baseline. Prove that data flows from export → training → evaluation → registry → inference without gaps.

#### Phase 0.0 — TDD (Architecture Design)

| #   | Deliverable                                                    | Exit criteria                                   |
| --- | -------------------------------------------------------------- | ----------------------------------------------- |
| 1   | Draft TDD covering all sections listed in §5                   | Document exists, covers all sections            |
| 2   | Architecture review with team                                  | Review comments addressed, TDD approved         |
| 3   | Spike: prototype `ModelClient` wrapping existing `LLMProvider` | Working prototype validates the protocol design |
| 4   | Spike: export bootstrapped classification data as JSONL        | JSONL file produced from existing DB records    |

**Exit criteria:** TDD approved. Spikes demonstrate ModelClient path and data export path both work.

#### Phase 0.1 — Data Layer + Evaluation Harness

| #   | Deliverable                                                        | Exit criteria                                                    |
| --- | ------------------------------------------------------------------ | ---------------------------------------------------------------- |
| 1   | `analyst_labels` table + Alembic migration                         | Migration runs cleanly on SQLite + PostgreSQL                    |
| 2   | Label CRUD API (`POST/GET/PUT/DELETE /api/labels`)                 | Endpoints functional, tested, audited via `store.log_action`     |
| 3   | `dataset_registry` metadata table + Alembic migration              | Migration runs cleanly on SQLite + PostgreSQL                    |
| 4   | Bootstrap export: extract existing `classification_result` → JSONL | ≥ 50 cases exported, balanced across intents                     |
| 5   | Export pipeline CLI (`i4g data export`)                            | Produces train/eval/test splits with configurable stratification |
| 6   | Golden test set curated from bootstrap data                        | JSONL file in `core/data/eval/`, version-controlled              |
| 7   | Evaluation runner (`i4g eval run`)                                 | Runs classifier against golden set, outputs per-axis P/R/F1      |
| 8   | Evaluation reporter (`i4g eval report`)                            | Renders results as Markdown table + JSON                         |
| 9   | Baseline benchmark recorded                                        | Per-axis F1 for current Gemini 2.5 Flash + current prompts       |
| 10  | Unit + integration tests                                           | ≥ 90% coverage on new code                                       |

**Exit criteria:** Data can be exported from the database into versioned datasets. Golden test set exists. Baseline F1 scores are recorded. Labels have a storage schema and API.

#### Phase 0.2 — Monitoring + Prompt Versioning

| #   | Deliverable                                       | Exit criteria                                                      |
| --- | ------------------------------------------------- | ------------------------------------------------------------------ |
| 1   | `llm_usage_log` table + Alembic migration         | Migration runs cleanly on SQLite + PostgreSQL                      |
| 2   | Core `CostTracker` (adapted from SSI pattern)     | All core LLM calls record tokens, cost, latency                    |
| 3   | Cost reporting CLI (`i4g cost report`)            | Outputs per-capability cost summary for date range                 |
| 4   | Cost reporting admin API (`GET /api/admin/costs`) | Returns aggregated cost data by capability and date range          |
| 5   | Version stamps on all prompt templates            | All `.md` prompt files have YAML frontmatter with `prompt_version` |
| 6   | Prompt version logged with every LLM call         | Log entries include `prompt_version` field; zero nulls             |
| 7   | Unit tests for cost tracker and prompt versioning | ≥ 90% coverage on new code                                         |

**Exit criteria:** Cost data accumulating in dev. Every LLM call in classification path logs prompt version. Cost queries return accurate per-capability breakdowns.

#### Phase 0.3 — Inference Framework + Training Skeleton

| #   | Deliverable                                                         | Exit criteria                                                         |
| --- | ------------------------------------------------------------------- | --------------------------------------------------------------------- |
| 1   | `ModelClient` protocol definition                                   | Protocol in `core/src/i4g/ml/`                                        |
| 2   | `LLMModelClient` implementation (wraps existing provider)           | All methods delegate to current `LLMProvider`                         |
| 3   | `build_model_client()` factory                                      | Returns `LLMModelClient` for all capabilities (Phase 0 behavior)      |
| 4   | Migrate `FraudClassifier` to use `ModelClient`                      | Classification behavior unchanged; existing tests pass                |
| 5   | Migrate `SemanticNER` to use `ModelClient`                          | Entity extraction behavior unchanged; existing tests pass             |
| 6   | Model registry metadata table + Alembic migration                   | Migration runs cleanly; registry accepts model entries                |
| 7   | W&B experiment tracking integration                                 | Training runs log to W&B; metrics and artifacts retrievable           |
| 8   | Training pipeline skeleton (classification, Gemma 2B)               | End-to-end: load bootstrap JSONL → fine-tune → evaluate → log results |
| 9   | Baseline comparison automation                                      | Script runs few-shot and custom model on same eval set, outputs delta |
| 10  | Settings: `I4G_ML__*`, `I4G_DATA__*`, `I4G_TRAINING__*` sections    | Documented in settings manifest                                       |
| 11  | Unit tests for protocol, factory, registry, and migrated call sites | All existing tests pass. New tests added.                             |

**Exit criteria:** Application code uses `ModelClient`. Model registry exists. Training pipeline runs end-to-end on bootstrap data (model quality does not matter — pipeline completeness does). Custom model performance compared to few-shot baseline automatically.

---

### Phase 1 — Data Collection (Analyst Labeling + Real Datasets)

> Depends on: Analyst Feedback Loop PRD for the UI; this PRD provides the backend.

| #   | Deliverable                                      | Exit criteria                                                     |
| --- | ------------------------------------------------ | ----------------------------------------------------------------- |
| 1   | Label API integration with analyst correction UI | UI writes to `analyst_labels`; corrections appear in DB           |
| 2   | Dataset refresh pipeline                         | Re-export incorporates new analyst labels automatically           |
| 3   | Feature extraction pipeline                      | Structured features (entity counts, text stats) added to datasets |
| 4   | Data quality dashboard                           | Distribution of labels visible; staleness alerts working          |
| 5   | Inter-annotator agreement tracking               | Where 2+ analysts label same case, agreement rate calculated      |
| 6   | Export to W&B as versioned dataset artifact      | Training can reference W&B dataset versions directly              |

**Exit criteria:** Analyst corrections flowing into label DB. Datasets automatically refreshed. ≥ 200 real analyst labels collected. Feature extraction producing structured training features.

---

### Phase 2 — Training Pipeline (First Custom Model)

> Goal: Train a custom model that matches or beats few-shot on at least one taxonomy axis.

| #   | Deliverable                                             | Exit criteria                                                                 |
| --- | ------------------------------------------------------- | ----------------------------------------------------------------------------- |
| 1   | Full fine-tuning pipeline (Gemma 2B on classification)  | Reproducible training run; tracked in W&B                                     |
| 2   | Per-axis and multi-task training configurations         | Both configs trainable; eval comparison logged                                |
| 3   | Hyperparameter sweep automation                         | W&B Sweeps or equivalent; best config auto-selected                           |
| 4   | Model artifact export to GCS + model registry           | Trained model registered with eval scores and lineage                         |
| 5   | `CustomModelClient` implementation                      | Calls Vertex AI Endpoint or Cloud Run model server                            |
| 6   | Shadow mode in `build_model_client()`                   | Custom model runs in parallel with LLM; predictions logged silently           |
| 7   | Shadow evaluation pipeline                              | Nightly comparison: shadow predictions vs. LLM predictions vs. analyst labels |
| 8   | Eval gate on model promotion                            | Model cannot promote to staging unless eval F1 ≥ baseline                     |
| 9   | PII anonymization in training data export (if required) | Anonymization pipeline tested; validated against original                     |

**Exit criteria:** Custom model trained, registered, and running in shadow mode. Shadow evaluation proves whether it beats few-shot. Eval gate enforced. ≥ 500 labeled examples.

---

### Phase 3 — Serving & Optimization (Custom Models Serve Traffic)

> Goal: Custom models serve real production traffic with A/B routing and monitored outcomes.

| #   | Deliverable                                                  | Exit criteria                                                    |
| --- | ------------------------------------------------------------ | ---------------------------------------------------------------- |
| 1   | A/B traffic router in `build_model_client()`                 | Configurable traffic split (e.g. 90/10) between model versions   |
| 2   | Outcome tracking for A/B comparisons                         | Per-request model version logged; analyst corrections correlated |
| 3   | Model promotion workflow (staging → production)              | Manual approval gate; automated eval check; one-click rollback   |
| 4   | Confidence calibration (Platt scaling / isotonic regression) | Calibrated scores align with empirical accuracy                  |
| 5   | Drift detection on production inputs                         | Distribution shift alerts trigger re-evaluation                  |
| 6   | Accuracy monitoring dashboard                                | Per-axis accuracy vs. analyst labels tracked continuously        |
| 7   | Cost comparison dashboard (LLM API vs. custom model)         | Per-capability cost delta visible; ROI calculated                |
| 8   | Latency tracking (P50/P95/P99 per backend)                   | Latency regression alerts working                                |

**Exit criteria:** At least one capability serving real traffic via custom model. A/B routing active. Accuracy monitored. Cost savings demonstrated. Rollback tested.

---

### Phase 4 — Maturity (Continuous Learning + Multi-Capability)

> Goal: Platform supports multiple ML capabilities with continuous improvement.

| #   | Deliverable                                                      | Exit criteria                                                   |
| --- | ---------------------------------------------------------------- | --------------------------------------------------------------- |
| 1   | Extend training pipeline to NER (entity extraction)              | Custom NER model trained, evaluated, and shadow-deployed        |
| 2   | Automated retraining trigger on dataset growth thresholds        | Retraining proposed when label count grows by X% since last run |
| 3   | Multi-capability eval dashboard                                  | Classification + NER + RAG eval scores visible in one view      |
| 4   | Dataset versioning with lineage                                  | Full traceability: model → training run → dataset → labels      |
| 5   | Eval test set refresh workflow                                   | Quarterly refresh procedure; distribution drift tracked         |
| 6   | Cost-based model routing (cheapest model that meets quality bar) | Factory considers cost and quality when routing                 |

**Exit criteria:** Platform supports ≥ 2 ML capabilities end-to-end. Retraining is semi-automated. Full lineage from label to production model. Platform considered stable — no further platform work needed.

---

## 7. Data Model Changes

### 7.1 New Table: `analyst_labels`

| Column            | Type                    | Description                                                                     |
| ----------------- | ----------------------- | ------------------------------------------------------------------------------- |
| `id`              | UUID (PK)               | Unique label entry                                                              |
| `case_id`         | UUID (FK → cases)       | The case being labeled                                                          |
| `label_type`      | VARCHAR(32)             | Enum: `classification`, `risk_score`, `entity`, `disposition`, `report_quality` |
| `original_value`  | JSONB                   | System-produced value at time of labeling                                       |
| `corrected_value` | JSONB                   | Analyst-provided correction                                                     |
| `analyst_id`      | VARCHAR(128)            | Identity of the labeling analyst                                                |
| `prompt_version`  | VARCHAR(128) (nullable) | Prompt version that produced the original value                                 |
| `model_name`      | VARCHAR(128) (nullable) | Model that produced the original value                                          |
| `model_version`   | VARCHAR(64) (nullable)  | Model version (registry version or LLM model version)                           |
| `created_at`      | TIMESTAMP               | When the label was created                                                      |
| `updated_at`      | TIMESTAMP               | Last modification                                                               |
| `metadata`        | JSONB                   | UI context, notes, additional signals                                           |

**Indexes:** `(case_id, label_type)`, `(label_type, created_at)`, `(analyst_id)`.
**Constraints:** `label_type` restricted to known enum values via CHECK constraint.

### 7.2 New Table: `llm_usage_log`

| Column               | Type                        | Description                                                            |
| -------------------- | --------------------------- | ---------------------------------------------------------------------- |
| `id`                 | UUID (PK)                   | Unique log entry                                                       |
| `timestamp`          | TIMESTAMP                   | When the call was made                                                 |
| `capability`         | VARCHAR(64)                 | `classification`, `ner`, `rag`, `ssi_classification`, etc.             |
| `model_name`         | VARCHAR(128)                | `gemini-2.5-flash`, `ollama/mistral`, `fraud_classifier_gemma2b`, etc. |
| `model_version`      | VARCHAR(64)                 | Model version (registry version or provider version)                   |
| `model_source`       | VARCHAR(32)                 | `llm_api`, `custom_model`, `shadow`                                    |
| `prompt_version`     | VARCHAR(128)                | e.g. `fraud_classifier.v3` (null for custom models)                    |
| `input_tokens`       | INTEGER                     | Token count for input                                                  |
| `output_tokens`      | INTEGER                     | Token count for output                                                 |
| `estimated_cost_usd` | NUMERIC(10,6)               | Estimated cost in USD                                                  |
| `latency_ms`         | INTEGER                     | Wall-clock latency                                                     |
| `case_id`            | UUID (nullable, FK → cases) | Associated case, if applicable                                         |
| `session_id`         | VARCHAR(128) (nullable)     | SSI session ID, if applicable                                          |
| `ab_experiment_id`   | VARCHAR(128) (nullable)     | A/B experiment identifier, if applicable                               |
| `metadata`           | JSONB                       | Temperature, max_tokens, routing decision reason, etc.                 |
| `created_at`         | TIMESTAMP                   | Row insert time                                                        |

**Indexes:** `(capability, timestamp)`, `(case_id)`, `(prompt_version)`, `(model_source, timestamp)`, `(ab_experiment_id)`.
**Partitioning:** Consider monthly partitioning on `timestamp` if volume exceeds 1M rows/month. Decide in TDD.

### 7.3 New Table: `dataset_registry`

| Column               | Type                | Description                                         |
| -------------------- | ------------------- | --------------------------------------------------- |
| `id`                 | UUID (PK)           | Unique dataset entry                                |
| `dataset_id`         | VARCHAR(128)        | Logical name, e.g. `classification_v3`              |
| `version`            | INTEGER             | Auto-incrementing per `dataset_id`                  |
| `split`              | VARCHAR(16)         | `train`, `eval`, `test`                             |
| `storage_path`       | VARCHAR(512)        | GCS path or local path to JSONL file                |
| `record_count`       | INTEGER             | Number of records in this split                     |
| `label_distribution` | JSONB               | Per-label counts for distribution visibility        |
| `export_config`      | JSONB               | Stratification params, filter criteria, random seed |
| `parent_dataset_id`  | UUID (nullable, FK) | Lineage — derived from which prior dataset?         |
| `created_at`         | TIMESTAMP           | When the dataset was exported                       |
| `created_by`         | VARCHAR(128)        | Pipeline run ID or user                             |
| `metadata`           | JSONB               | Additional context                                  |

**Indexes:** `(dataset_id, version)` UNIQUE, `(created_at)`.
**Constraint:** Datasets are immutable; no UPDATE allowed (enforced at application layer).

### 7.4 New Table: `model_registry`

| Column                | Type                         | Description                                              |
| --------------------- | ---------------------------- | -------------------------------------------------------- |
| `id`                  | UUID (PK)                    | Unique model entry                                       |
| `model_id`            | VARCHAR(128)                 | Logical name, e.g. `fraud_classifier_gemma2b`            |
| `version`             | INTEGER                      | Auto-incrementing per `model_id`                         |
| `capability`          | VARCHAR(64)                  | `classification`, `ner`, etc.                            |
| `stage`               | VARCHAR(16)                  | `dev`, `staging`, `production`                           |
| `artifact_path`       | VARCHAR(512)                 | GCS path to model artifacts                              |
| `eval_scores`         | JSONB                        | Per-axis metrics from eval harness                       |
| `baseline_comparison` | JSONB                        | Delta vs. few-shot baseline                              |
| `training_run_id`     | VARCHAR(256)                 | W&B run ID for reproducibility                           |
| `dataset_id`          | UUID (FK → dataset_registry) | Which dataset was it trained on                          |
| `created_at`          | TIMESTAMP                    | When the model was registered                            |
| `promoted_at`         | TIMESTAMP (nullable)         | When promoted to current stage                           |
| `promoted_by`         | VARCHAR(128) (nullable)      | Who approved the promotion                               |
| `metadata`            | JSONB                        | Hyperparams, training config, hardware, base model, etc. |

**Indexes:** `(model_id, version)` UNIQUE, `(capability, stage)`, `(stage)`.

### 7.5 Migrations

Four Alembic migrations (one per table), applied in order:

1. `add_analyst_labels`
2. `add_llm_usage_log`
3. `add_dataset_registry`
4. `add_model_registry`

All must run cleanly against SQLite (local) and PostgreSQL (dev/prod). Migrations 1–2 are Phase 0.1/0.2; migrations 3–4 are Phase 0.3.

---

## 8. API Surface

### 8.1 Label CRUD

| Method   | Path                                     | Description                                        |
| -------- | ---------------------------------------- | -------------------------------------------------- |
| `POST`   | `/api/labels`                            | Create a new analyst label                         |
| `GET`    | `/api/labels?case_id=...&label_type=...` | List labels, filtered by case and/or type          |
| `GET`    | `/api/labels/{id}`                       | Get a single label by ID                           |
| `PUT`    | `/api/labels/{id}`                       | Update a label (analyst corrects their correction) |
| `DELETE` | `/api/labels/{id}`                       | Delete a label                                     |

`analyst_id` extracted from authenticated request context. All mutations logged via `store.log_action`.

### 8.2 Cost Reporting (Admin)

| Method | Path                                                | Description                                         |
| ------ | --------------------------------------------------- | --------------------------------------------------- |
| `GET`  | `/api/admin/costs?start=...&end=...&capability=...` | Aggregated cost report by capability and date range |

Returns per-capability totals: total calls, total tokens, total cost, average latency. Supports `model_source` filter (LLM vs. custom).

### 8.3 Model Registry (Admin)

| Method | Path                                              | Description                               |
| ------ | ------------------------------------------------- | ----------------------------------------- |
| `GET`  | `/api/admin/models`                               | List all registered models                |
| `GET`  | `/api/admin/models/{model_id}/versions`           | List versions for a model                 |
| `GET`  | `/api/admin/models/{model_id}/versions/{version}` | Get model details including eval scores   |
| `POST` | `/api/admin/models/{model_id}/promote`            | Promote a model version to the next stage |

### 8.4 Dataset Registry (Admin)

| Method | Path                                        | Description                  |
| ------ | ------------------------------------------- | ---------------------------- |
| `GET`  | `/api/admin/datasets`                       | List all registered datasets |
| `GET`  | `/api/admin/datasets/{dataset_id}/versions` | List versions for a dataset  |

### 8.5 CLI Commands

| Command                                   | Description                                                   |
| ----------------------------------------- | ------------------------------------------------------------- |
| `i4g data export`                         | Export labels + bootstrap data to versioned JSONL with splits |
| `i4g eval run --test-set <path>`          | Run a model against golden test set, output metrics           |
| `i4g eval report --output <path>`         | Render eval results as Markdown + JSON                        |
| `i4g eval compare --baseline --candidate` | Compare two model runs side-by-side                           |
| `i4g cost report --start --end`           | Per-capability cost summary                                   |
| `i4g train run --config <path>`           | Execute a training pipeline run                               |
| `i4g model register --artifact <path>`    | Register a model artifact in the registry                     |
| `i4g model promote --model-id --version`  | Promote a model to the next stage                             |

---

## 9. Configuration Changes

### 9.1 New Settings Sections

```toml
[eval]
golden_set_path = "data/eval/golden_classification.jsonl"
output_dir = "data/reports/eval"
fail_threshold_f1 = 0.0                           # minimum F1 to pass; 0.0 = no gate

[cost]
enabled = true
pricing_model = "gemini-2.5-flash"
alert_daily_budget_usd = 0.0                       # 0 = no alerting

[ml]
inference_backend = "llm"                          # "llm" | "model_registry" | "shadow"
shadow_enabled = false                             # run shadow model alongside production
ab_routing_enabled = false                         # enable A/B traffic splitting

[data]
export_dir = "data/exports"                        # local export directory
gcs_bucket = ""                                    # GCS bucket for datasets and models (empty = local only)
bootstrap_min_cases = 50                           # minimum cases for bootstrap dataset
train_split = 0.7
eval_split = 0.15
test_split = 0.15

[training]
experiment_tracker = "wandb"                       # "wandb" | "mlflow" | "none"
wandb_project = "i4g-ml"
default_base_model = "gemma-2b"
default_epochs = 3
default_batch_size = 8
```

### 9.2 Env Var Mapping

Following existing `I4G_*` double-underscore convention:

- `I4G_EVAL__GOLDEN_SET_PATH`, `I4G_EVAL__FAIL_THRESHOLD_F1`
- `I4G_COST__ENABLED`, `I4G_COST__PRICING_MODEL`, `I4G_COST__ALERT_DAILY_BUDGET_USD`
- `I4G_ML__INFERENCE_BACKEND`, `I4G_ML__SHADOW_ENABLED`, `I4G_ML__AB_ROUTING_ENABLED`
- `I4G_DATA__GCS_BUCKET`, `I4G_DATA__BOOTSTRAP_MIN_CASES`
- `I4G_TRAINING__EXPERIMENT_TRACKER`, `I4G_TRAINING__WANDB_PROJECT`, `I4G_TRAINING__DEFAULT_BASE_MODEL`

### 9.3 Documentation

- Update `docs/config/settings_manifest.yaml` with all new sections
- Update `docs/config/` env-var table
- Add coverage under `tests/unit/settings/` per env + smoke discipline

---

## 10. Risks & Mitigations

| Risk                                              | Impact                                                                   | Likelihood   | Mitigation                                                                                                                                                                   |
| ------------------------------------------------- | ------------------------------------------------------------------------ | ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Insufficient labeled data**                     | Custom models underperform few-shot prompting                            | High (early) | Bootstrap from existing data. Set minimum sample size gates (500+ per axis) before training. Few-shot fallback always available.                                             |
| **Label quality / inconsistency**                 | Training data is noisy; model learns wrong patterns                      | Medium       | Inter-annotator agreement metrics. Label review process. Weight high-agreement labels higher.                                                                                |
| **Golden test set is unrepresentative**           | Eval metrics don't reflect production accuracy                           | Medium       | Sample from recent production data. Refresh quarterly. Track distribution drift between test set and production inputs.                                                      |
| **Pipeline complexity exceeds team capacity**     | Infrastructure becomes a project in itself, blocking product work        | Medium       | Strict phasing with exit criteria. Phase 0 builds skeleton — complexity added only as phases demand it. Pipeline steps are standalone CLI commands, not a monolithic system. |
| **Model regression in production**                | Custom model degrades accuracy for real users                            | Medium       | Eval gate on promotion. Mandatory shadow period. A/B routing with gradual rollout. Instant rollback to LLM.                                                                  |
| **Cost of custom model serving**                  | Infrastructure cost exceeds LLM API savings                              | Medium       | Track cost-per-prediction for both. Custom model must be cheaper AND better (or significantly one) to justify promotion.                                                     |
| **PII in training data**                          | Regulatory risk if case narratives with victim PII are used for training | Medium       | Anonymization pipeline before export. Legal review of data handling. Option to train on metadata-only features.                                                              |
| **W&B vendor dependency**                         | Hosted experiment tracking creates external dependency                   | Low          | W&B is the starting choice for speed. Architecture supports swap to MLflow if self-hosting is required. Abstract via thin adapter.                                           |
| **Migration compatibility (SQLite + PostgreSQL)** | Alembic migration works on one backend but not the other                 | Low          | Test migrations against both backends in CI. Use SQLAlchemy-native types only.                                                                                               |
| **Over-engineering the factory for Phase 0**      | Unnecessary complexity when only LLM backend exists                      | Low          | Phase 0 factory is simple (always returns `LLMModelClient`). A/B routing, shadow mode, and registry lookup are Phase 2–3 extensions. Protocol is minimal (3 methods).        |

---

## 11. Success Metrics

| Metric                           | Phase 0                                     | Phase 1                     | Phase 2                   | Phase 3                        | Phase 4                |
| -------------------------------- | ------------------------------------------- | --------------------------- | ------------------------- | ------------------------------ | ---------------------- |
| **Classification F1 (baseline)** | Measured                                    | Measured                    | Custom model ≥ baseline   | Custom model > baseline by 5%+ | Continuously improving |
| **Labeled dataset size**         | Bootstrap (existing records)                | 200+ analyst labels         | 500+                      | 1,000+                         | 2,000+                 |
| **Pipeline completeness**        | Export → train → eval → register (skeleton) | Data refresh automated      | Full training pipeline    | A/B + shadow in production     | Multi-capability       |
| **Eval coverage**                | 1 capability (classification)               | 1 capability + data quality | 2 capabilities            | 3 capabilities                 | All ML capabilities    |
| **Cost visibility**              | Per-call tracking                           | Per-capability dashboards   | LLM vs. custom comparison | ROI proven                     | Cost-based routing     |
| **Time to detect regression**    | —                                           | —                           | —                         | < 24 hours                     | < 12 hours             |
| **Model promotion cycle time**   | —                                           | —                           | Days (manual)             | Hours (semi-auto)              | Hours (semi-auto)      |
| **Analyst correction rate**      | —                                           | Collecting corrections      | Collecting                | < 15% need correction          | < 10%                  |

---

## 12. Open Questions

1. **Bootstrap data quality:** Existing `classification_result` records are LLM outputs treated as ground truth. How much manual verification of the bootstrap golden set is needed before we trust baseline metrics? At minimum, review a random sample for egregious errors.

2. **Per-axis vs. multi-task models:** Train one model for all 5 taxonomy axes, or separate models per axis? Multi-task is more data-efficient; per-axis allows independent iteration. May need to try both — this is a training-time decision, but the infrastructure must support both configurations.

3. **PII in training data:** Case narratives contain victim PII. What anonymization is required before export? Options: (a) full PII redaction, (b) train only on metadata features, (c) legal review deems acceptable with access controls. Blocks Phase 2 if unresolved.

4. **Minimum viable dataset size:** At what N do fine-tuned models start beating few-shot? Literature suggests 500–1,000 labeled examples per class. We should benchmark empirically and set data gates rather than guessing.

5. **SSI cost tracking unification:** SSI already has `CostTracker`. Do we unify into a shared implementation, or keep separate implementations writing to the same schema? Cross-repo dependency implications need resolution.

6. **Real-time vs. batch inference for custom models:** Current classification is synchronous (on ingestion). Custom models may have different latency profiles. Do we need an async/batch fallback path? Probably not initially — Vertex AI Endpoints support real-time inference.

7. **Eval harness CI integration:** Run eval on every PR (slow, costs money) or only on prompt/model-change PRs? Or: mock provider in CI, real provider on nightly schedule. This affects developer workflow and cost.

8. **GCS bucket strategy:** Single bucket with path-based separation (datasets, models, eval results) or separate buckets? Security and IAM implications. Resolve in TDD.

9. **Model serving cost model:** Vertex AI Endpoints charge for uptime, not just per-request. At low inference volumes, the always-on endpoint may be more expensive than LLM API calls. Need to model break-even volume. Could use serverless Cloud Run for low-volume capabilities.

10. **Partner data sharing:** Could law enforcement partners contribute labeled data? Legal and privacy framework needed. Defer to long-term.

---

## 13. Dependencies & Sequencing

### This PRD Depends On

- Nothing — this is foundational infrastructure with no upstream PRD dependencies.

### Other PRDs That Depend On This

- **Analyst Feedback Loop PRD** — uses the `analyst_labels` table and CRUD API; provides the UI that populates the data layer
- **OCR Modernization PRD** — uses the eval harness for accuracy benchmarking
- **Advanced ML Capabilities PRDs** — consume the training pipeline, model registry, and inference framework

### Internal Phase Sequencing

- **Phase 0.0 (TDD)** must complete before any implementation
- **Phase 0.1** (data + eval) and **Phase 0.2** (monitoring + prompts) can run in parallel after TDD
- **Phase 0.3** (inference + training skeleton) depends on TDD; can run in parallel with 0.1/0.2 for non-dependent deliverables
- **Phase 1** depends on Analyst Feedback Loop PRD for the UI; backend from this PRD is ready at end of Phase 0
- **Phase 2** depends on Phase 1 (needs analyst labels); pure training pipeline work can start earlier
- **Phase 3** depends on Phase 2 (needs a trained model to serve)
- **Phase 4** depends on Phase 3 (extends to additional capabilities)

### External Dependencies

- **W&B account** — needed for Phase 0.3 (experiment tracking)
- **GCS bucket provisioning** — needed for dataset/model storage (infra repo)
- **Vertex AI Endpoints** (or Cloud Run serving) — needed for Phase 2 (custom model serving)

---

## References

- [ML Strategy & Roadmap](ml_strategy.md) — the strategy document driving this PRD (§6–8 are the primary source)
- [Fraud Taxonomy PRD](prd_fraud_taxonomy.md) — classification system this infrastructure evaluates and improves
- SSI `CostTracker` — `ssi/src/ssi/` (existing cost tracking pattern to adapt)
- Core LLM provider — `core/src/i4g/llm/` (call sites to abstract behind `ModelClient`)
- Core prompt templates — `core/src/i4g/llm/prompts/` (files to version-stamp)
- Strategy §2.2 infrastructure gap table — the gaps this PRD closes
- Strategy §5 data strategy — labeling sources and bootstrap approach this PRD implements
- Strategy §11 technical decisions — decided items (W&B, Vertex AI, JSONL, Gemma 2B, few-shot-as-default) this PRD follows

---

**Owner:** Engineering
**Status:** Draft PRD v2.0
