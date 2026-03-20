# I4G Machine Learning Strategy & Roadmap

**Author:** Cross-functional task force (CTO / CPO / Chief Architect)
**Date:** March 2026
**Horizon:** 6–12 months
**Status:** Draft — drives PRD creation for individual tracks

---

## 1. Executive Summary

I4G already relies on machine learning at every critical decision point — classifying fraud, scoring risk, extracting entities, searching cases, analyzing scam sites, and navigating adversarial web pages. But all of these capabilities run on **third-party foundation models via prompting**. We have no training pipeline, no labeled dataset, no model registry, no evaluation harness, and no ability to deploy our own models.

This document does three things:

1. **Maps the current state** — a complete inventory of where ML is used today, which models power it, and how mature each capability is.
2. **Identifies the gaps** — both in improving what we already do and in unlocking capabilities we haven't built yet.
3. **Lays out a phased roadmap** — what to build now (ML infrastructure + inference framework), near-term (data collection + first custom models), and long-term (continuous learning + advanced capabilities).

The immediate deliverable from this strategy is a **PRD for ML Infrastructure & Pipeline**, covering training, evaluation, serving, and A/B testing. A second PRD for **Analyst Feedback Loop** (label collection) follows closely behind.

---

## 2. Current State: ML Inventory

### 2.1 Model Usage Map

| Capability                               | Repo       | Model(s)                                  | Technique                                             | Maturity   |
| ---------------------------------------- | ---------- | ----------------------------------------- | ----------------------------------------------------- | ---------- |
| **Fraud taxonomy classification**        | core       | Gemini 2.5 Flash / Ollama                 | Few-shot prompting (JSON mode)                        | Production |
| **Risk scoring**                         | core + ssi | Weighted formula on classification output | Deterministic algorithm on ML output                  | Production |
| **Semantic entity extraction**           | core       | Gemini / Ollama                           | Few-shot prompting + rule-based fallback              | Production |
| **Rule-based entity extraction**         | core       | —                                         | Regex (wallets, URLs, phones, names, crypto keywords) | Production |
| **OCR**                                  | core       | Tesseract                                 | Traditional CV (local binary)                         | Production |
| **Vector embeddings**                    | core       | Ollama `mxbai-embed-large`                | Pre-trained embeddings                                | Production |
| **Hybrid search (RAG retrieval)**        | core       | Embeddings + SQL                          | Vector similarity + structured filters                | Production |
| **RAG scam assessment**                  | core       | Gemini / Ollama via LangChain LCEL        | Retrieval-augmented generation                        | Production |
| **Scam site classification**             | ssi        | Gemini 2.5 Flash                          | Few-shot prompting (JSON mode)                        | Production |
| **Scam site risk scoring**               | ssi        | Weighted formula + infrastructure signals | Deterministic boost on ML output                      | Production |
| **Browser agent (site navigation)**      | ssi        | Gemini Vision / Ollama                    | Multimodal LLM agent with state machine               | Production |
| **Decision cascade (cost optimization)** | ssi        | DOM heuristics → text LLM → vision LLM    | Tiered routing by confidence                          | Production |
| **Wallet extraction**                    | ssi        | —                                         | Multi-blockchain regex (20+ networks)                 | Production |
| **PII exposure detection**               | ssi        | Browser agent (DOM + LLM)                 | Form field analysis during navigation                 | Production |
| **Campaign clustering**                  | core       | —                                         | Wallet/IP/ASN/brand co-occurrence                     | Production |
| **Graph analysis**                       | core       | —                                         | NetworkX co-occurrence (not ML)                       | Production |
| **Loss-indicator linkage**               | core       | LLM extraction job                        | Few-shot prompting                                    | Production |

### 2.2 Infrastructure Components

| Component               | What exists                                                  | What's missing                                                                               |
| ----------------------- | ------------------------------------------------------------ | -------------------------------------------------------------------------------------------- |
| **LLM providers**       | Gemini, Ollama, Mock — clean factory pattern                 | No provider-level cost tracking dashboard, no prompt versioning                              |
| **Embeddings**          | Ollama local (`mxbai-embed-large`), Vertex AI Search (cloud) | No fine-tuned domain embeddings, no embedding evaluation                                     |
| **Vector stores**       | Chroma (local), FAISS (offline), Vertex AI Search (cloud)    | No automated re-indexing pipeline, no pgvector integration yet                               |
| **Prompt management**   | Markdown templates + golden example JSON files               | No prompt registry, no A/B testing of prompts, no version control on prompt performance      |
| **Model configuration** | Settings via env vars / TOML                                 | No model registry, no model versioning, no rollback capability                               |
| **Cost tracking**       | Token counting per SSI session (`CostTracker`)               | No aggregated cost reporting, no budget alerting, no per-capability cost attribution in core |
| **Evaluation**          | None                                                         | No accuracy benchmarks, no regression tests on model outputs, no evaluation datasets         |
| **Training**            | None                                                         | No training pipeline, no feature store, no experiment tracking                               |
| **Data labeling**       | None                                                         | No analyst feedback UI, no label storage schema, no inter-annotator agreement                |
| **Model serving**       | Direct API calls to Gemini / Ollama                          | No custom model serving, no model endpoint management                                        |
| **A/B testing**         | None                                                         | No shadow mode, no traffic splitting, no outcome tracking                                    |
| **Monitoring**          | None                                                         | No drift detection, no quality dashboards, no alerting on classification degradation         |

### 2.3 Maturity Assessment

```
                        Foundation    Functional    Optimized    Autonomous
                        ──────────    ──────────    ─────────    ──────────
Fraud classification    ............[■■■■■]...........................
Risk scoring            ............[■■■■■]...........................
Entity extraction       ............[■■■■■]...........................
OCR                     ....[■■■■■]...................................
Vector search           ............[■■■■■]...........................
RAG pipeline            ....[■■■■■]...................................
Browser agent           ..................[■■■■■].....................
Decision cascade        ..................[■■■■■].....................
Campaign clustering     ....[■■■■■]...................................
ML infrastructure       [■■]..........................................
Data collection         [■]............................................
Evaluation              [■]............................................
```

**Key takeaway:** The _application layer_ is surprisingly mature — we ship real ML features. But the _infrastructure layer_ is nearly absent. We're building on sand: any model change requires manual testing, any regression goes undetected, and we have no path to custom models.

---

## 3. Improving What We Have

These are concrete improvements to existing capabilities, ordered by impact.

### 3.1 OCR: Tesseract → Document AI

**Current:** Tesseract (open source, CPU-based). Struggles with handwriting, rotated text, low-contrast images, and non-Latin scripts.

**Target:** Google Document AI (cloud) with Tesseract fallback (local).

**Impact:** Higher extraction accuracy on victim-submitted screenshots, which are the primary intake source. OCR errors cascade into entity extraction and classification failures.

**Effort:** Low — swap the backend in `core/src/i4g/ocr/`, add a `provider` setting mirroring the LLM pattern.

### 3.2 Embeddings: Generic → Domain-Tuned

**Current:** `mxbai-embed-large` (general purpose, 1024-dim). No evaluation of embedding quality for fraud-domain search.

**Target:** (1) Evaluate `text-embedding-005` (Google) and domain-specific alternatives. (2) Build an embedding evaluation harness using known-similar case pairs. (3) Long-term: fine-tune embeddings on fraud corpus.

**Impact:** Better search recall → fewer missed connections between cases → better campaign detection.

### 3.3 Classification Confidence Calibration

**Current:** LLM returns confidence scores (0.0–1.0), but these are uncalibrated. A "0.9 confidence" from Gemini doesn't mean 90% accuracy.

**Target:** Build a calibration curve from analyst corrections (see §5). Apply Platt scaling or isotonic regression to map raw scores to empirical probabilities.

**Impact:** The risk score formula multiplies confidence × weight. Miscalibrated confidence directly corrupts risk scores and auto-submit thresholds.

### 3.4 Prompt Versioning & Regression Testing

**Current:** Prompts live as static `.md` and `.py` files. Changes are tested manually.

**Target:** (1) Version-stamp all prompt templates. (2) Build an evaluation suite that runs each prompt version against a fixed test set and reports precision/recall/F1 per axis. (3) Gate prompt changes on regression tests.

**Impact:** Prevents silent quality degradation when prompts are edited or models are upgraded.

### 3.5 Cost Attribution & Budget Controls

**Current:** SSI tracks per-session tokens. Core has no cost tracking.

**Target:** Unified cost ledger across all LLM calls (classification, NER, RAG, SSI agent). Dashboard showing cost per capability per day. Budget alerts.

**Impact:** Enables informed decisions about model selection, cascade tuning, and where to invest in custom models (replace expensive LLM calls with cheaper fine-tuned models).

---

## 4. Untapped Opportunities

These are ML capabilities that a system like I4G should have but doesn't yet.

### 4.1 Near-Term (build with current models, no training)

| Opportunity                              | Description                                                        | Approach                                                                                               |
| ---------------------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------ |
| **Case auto-summarization**              | Generate a 2–3 sentence summary for each case in the analyst queue | LLM prompting on case narrative + classification. Store as `cases.summary`.                            |
| **Duplicate / near-duplicate detection** | Flag cases that describe the same scam instance                    | Embedding similarity on case text. Threshold-based alerting. Cheaper than full dedup.                  |
| **Cross-language scam detection**        | Many victim reports arrive in non-English languages                | Gemini handles multilingual natively. Validate classification accuracy on non-English golden examples. |
| **Automated report quality scoring**     | Score generated investigation reports for completeness and clarity | LLM-as-judge on report content vs. checklist of required sections.                                     |
| **Proactive URL scoring**                | Score URLs from threat feeds before a victim reports them          | Lightweight classification on URL features + WHOIS + DNS, without full SSI investigation.              |

### 4.2 Medium-Term (requires labeled data or custom models)

| Opportunity                                  | Description                                                       | Approach                                                                                             |
| -------------------------------------------- | ----------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| **Predictive case escalation**               | Predict which cases will require law enforcement referral         | Supervised classification on case features → escalation outcome. Requires historical outcome labels. |
| **Analyst workload routing**                 | Auto-assign cases to analysts based on expertise and load         | Reinforcement learning or rule-based initially, ML-optimized over time.                              |
| **Image similarity for brand impersonation** | Detect reuse of brand logos/layouts across scam sites             | Embedding similarity on site screenshots. CLIP or SigLIP embeddings.                                 |
| **Campaign prediction**                      | Predict emerging campaigns before they scale                      | Time-series anomaly detection on entity/indicator velocity.                                          |
| **Recidivism scoring**                       | Score likelihood that a reported entity reappears in future scams | Survival analysis on entity first_seen → last_seen patterns.                                         |

### 4.3 Long-Term (requires mature infrastructure)

| Opportunity                            | Description                                                     | Approach                                                                                                    |
| -------------------------------------- | --------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **Custom fraud classifier**            | Replace few-shot prompting with a fine-tuned model              | Fine-tune on analyst-corrected classifications. Lower latency, lower cost, higher accuracy on our taxonomy. |
| **Custom entity extractor**            | Domain-specific NER model for fraud narratives                  | Fine-tune on annotated case text. Better recall on crypto-specific entities.                                |
| **Autonomous investigation agent**     | Multi-site, multi-session investigations without human guidance | Extend browser agent with memory, planning, and cross-site correlation.                                     |
| **Real-time threat scoring**           | Score incoming threat intel feeds in real time                  | Streaming inference on ingestion pipeline. Sub-second classification.                                       |
| **Federated learning across partners** | Train on combined partner data without sharing raw data         | Federated or privacy-preserving ML across law enforcement partners.                                         |

---

## 5. Data Strategy: From Zero Labels to Continuous Learning

### 5.1 The Labeling Problem

We have **zero labeled data** in the traditional ML sense. No human has validated a classification result, confirmed a risk score, or corrected an entity extraction. Every "ground truth" is an LLM output.

But we have a critical advantage: **the I4G system itself is the labeling platform**. Analysts review cases daily. Every review decision is an implicit label.

### 5.2 Labeling Sources (Ordered by Effort)

| Source                                 | Label type                                             | Collection mechanism                                                                             | Priority             |
| -------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------ | -------------------- |
| **Analyst classification corrections** | Taxonomy labels (all 5 axes)                           | UI widget: show auto-classification, let analyst override any axis. Store correction + original. | **P0 — build first** |
| **Analyst risk score overrides**       | Calibrated risk score                                  | UI widget: show computed score, let analyst adjust. Record delta.                                | P0                   |
| **Case disposition**                   | Outcome label (referred, dismissed, merged, escalated) | Already partially tracked in `review_actions`. Formalize as an outcome enum.                     | P1                   |
| **Entity corrections**                 | NER accuracy                                           | UI: highlight extracted entities, let analyst add/remove/correct.                                | P1                   |
| **Report quality ratings**             | Report completeness / accuracy                         | UI: thumbs up/down or 1–5 star on investigation reports.                                         | P2                   |
| **Search relevance**                   | Retrieval quality                                      | Implicit: which search results does the analyst click/use?                                       | P2                   |
| **Campaign membership**                | Clustering ground truth                                | UI: analyst confirms or rejects campaign auto-assignment.                                        | P2                   |

### 5.3 Bootstrap: Treat Existing Data as Golden

Until analysts start correcting, we treat all current database records as correct:

- All existing `classification_result` JSONB → positive training examples for classification
- All existing `cases.tags` → high-confidence label set
- All existing `source_documents` entity extractions → NER training data
- All existing `risk_score` values → regression targets

This gives us enough data to **build and validate the infrastructure** even before real labels arrive.

### 5.4 Label Storage Schema

```
analyst_labels
  ├── id (UUID)
  ├── case_id (FK → cases)
  ├── label_type (enum: classification, risk_score, entity, disposition, report_quality)
  ├── original_value (JSONB)    -- what the system produced
  ├── corrected_value (JSONB)   -- what the analyst set
  ├── analyst_id (str)
  ├── created_at (timestamp)
  └── metadata (JSONB)          -- UI context, model version, prompt version
```

This table becomes the **single source of truth** for all human feedback. Every record is a training signal.

---

## 6. ML Infrastructure Roadmap

This is the core deliverable. The infrastructure must support the full lifecycle:

```
Data Collection → Processing → Training → Evaluation → Deployment → Serving → Monitoring
       ↑                                                                          │
       └──────────────────── Feedback Loop ────────────────────────────────────────┘
```

### 6.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ML PLATFORM                                  │
│                                                                     │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │  Data Layer  │  │  Training    │  │  Serving     │               │
│  │             │  │  Layer       │  │  Layer       │               │
│  │ • Label DB  │  │ • Pipelines  │  │ • Registry   │               │
│  │ • Feature   │  │ • Experiment │  │ • Endpoints  │               │
│  │   Store     │  │   Tracking   │  │ • A/B Router │               │
│  │ • Dataset   │  │ • Eval Suite │  │ • Shadow     │               │
│  │   Registry  │  │              │  │   Mode       │               │
│  └──────┬──────┘  └──────┬───────┘  └──────┬───────┘               │
│         │                │                  │                       │
│  ┌──────┴──────────────────┴──────────────────┴───────┐             │
│  │                   Monitoring                        │             │
│  │  • Accuracy drift  • Cost tracking  • Latency      │             │
│  │  • Label distribution shift  • Alerting             │             │
│  └─────────────────────────────────────────────────────┘             │
└─────────────────────────────────────────────────────────────────────┘
```

### 6.2 Component Breakdown

#### A. Data Layer

| Component                | Purpose                                             | Implementation                                                                                                  |
| ------------------------ | --------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| **Label database**       | Store all human feedback                            | Alembic migration for `analyst_labels` table (see §5.4)                                                         |
| **Dataset registry**     | Version and snapshot training/eval datasets         | File-based (JSONL in GCS) + metadata table. Each dataset is immutable, referenced by ID.                        |
| **Feature store**        | Pre-computed case features for training             | Materialized view or dedicated table: text features, entity counts, structural features, classification history |
| **Data export pipeline** | Extract train/eval/test splits from production data | CLI command: `i4g ml export-dataset --label-type classification --split 80/10/10 --min-corrections 1`           |

#### B. Training Layer

| Component               | Purpose                                           | Implementation                                                                                                                          |
| ----------------------- | ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Experiment tracker**  | Track hyperparameters, metrics, artifacts per run | Weights & Biases (cloud) or MLflow (self-hosted). Start with W&B for speed.                                                             |
| **Training pipelines**  | Reproducible model training                       | Python scripts under `core/src/i4g/ml/training/`. Initially: fine-tune classification model, fine-tune NER model, fine-tune embeddings. |
| **Evaluation suite**    | Standardized accuracy measurement                 | Per-capability eval scripts. Golden test set (frozen, never trained on). Metrics: precision, recall, F1 per axis, calibration error.    |
| **Baseline benchmarks** | Measure current few-shot performance              | Run current prompts against eval set. This becomes the bar to beat.                                                                     |

#### C. Serving Layer

| Component               | Purpose                                                    | Implementation                                                                                                          |
| ----------------------- | ---------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **Model registry**      | Version, stage, promote models                             | GCS bucket structure: `gs://i4g-ml-models/{capability}/{version}/`. Metadata in DB. Stages: dev → staging → production. |
| **Inference framework** | Unified interface to call LLM or custom model              | Extend existing `LLMClient` protocol with a `ModelClient` that routes to either LLM API or custom model endpoint.       |
| **A/B router**          | Split traffic between model versions                       | Request-level routing based on case_id hash. Log which model version served each prediction.                            |
| **Shadow mode**         | Run new model alongside production without affecting users | New model produces predictions stored for comparison but not surfaced. Analyst sees only production model output.       |

#### D. Monitoring

| Component            | Purpose                                           | Implementation                                                                                           |
| -------------------- | ------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| **Accuracy tracker** | Compare model predictions vs. analyst corrections | Daily job: for cases with analyst labels, compute agreement rate per axis. Alert on drops.               |
| **Cost dashboard**   | Per-capability, per-model cost tracking           | Extend `CostTracker` to all core LLM calls. Aggregate in `platform_kpis`.                                |
| **Drift detector**   | Detect shifts in input or output distribution     | Monitor label distribution, confidence distribution, entity type frequency. Statistical tests (PSI, KS). |
| **Latency tracker**  | Model response time by provider and capability    | Already have token counts; add wall-clock latency. Alert on P95 spikes.                                  |

---

## 7. Inference Framework: Using Our Own Models

### 7.1 Design Principle

The inference framework should make switching between a foundation model (Gemini) and a custom fine-tuned model **transparent to the application code**. The classifier, NER extractor, and RAG pipeline should not know or care whether they're calling an API or a local model.

### 7.2 Architecture

```python
# Current: all paths lead to LLM API
classifier = FraudClassifier(llm_client=build_llm_client(settings))

# Target: router picks best available model
classifier = FraudClassifier(model_client=build_model_client(
    capability="fraud_classification",
    settings=settings,
))

# build_model_client() checks:
# 1. Is there a custom model registered for this capability? → use it
# 2. Is A/B testing active? → route based on policy
# 3. Fallback → use LLM provider (current behavior)
```

### 7.3 Model Client Protocol

```python
class ModelClient(Protocol):
    """Unified interface for any model — LLM API or custom."""

    async def predict(
        self,
        input_text: str,
        *,
        output_schema: type[BaseModel] | None = None,
        metadata: dict | None = None,
    ) -> ModelResult: ...

@dataclass
class ModelResult:
    output: str | dict           # Raw or parsed output
    model_id: str                # Registry ID (e.g., "fraud-classifier-v3" or "gemini-2.5-flash")
    model_type: str              # "llm_api" | "custom" | "shadow"
    latency_ms: float
    tokens_in: int | None
    tokens_out: int | None
    cost_usd: float | None
```

### 7.4 Custom Model Serving Options

| Option                   | When to use                         | How it works                                                                             |
| ------------------------ | ----------------------------------- | ---------------------------------------------------------------------------------------- |
| **Vertex AI Endpoints**  | Production custom models            | Upload model artifact → create endpoint → serve via predict API. Auto-scales.            |
| **Cloud Run + FastAPI**  | Lightweight models, quick iteration | Containerized model behind a FastAPI `/predict` endpoint. Same infra pattern as ssi-svc. |
| **Ollama custom models** | Local development, testing          | `ollama create` with GGUF or safetensors. Already have Ollama integration.               |

For the **testing-only** phase, Ollama custom models are sufficient. Production deployment via Vertex AI Endpoints.

---

## 8. Phased Roadmap

### Phase 0: Foundation (Now — Sprint 1–2)

**Goal:** Infrastructure skeleton + baseline measurements. No custom models yet.

| #   | Deliverable                      | Details                                                                                                                                                                 |
| --- | -------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0.1 | **Evaluation harness**           | Golden test set for classification (50–100 cases, manually verified). Eval script that runs current few-shot prompts and reports P/R/F1 per axis. This is the baseline. |
| 0.2 | **Prompt versioning**            | Add version headers to all prompt templates. Log prompt version with every LLM call.                                                                                    |
| 0.3 | **Cost tracking (core)**         | Extend SSI's `CostTracker` pattern to all core LLM calls. Store in `llm_usage_log` table.                                                                               |
| 0.4 | **Label storage schema**         | Alembic migration for `analyst_labels` table. API endpoints for CRUD.                                                                                                   |
| 0.5 | **Inference framework skeleton** | `ModelClient` protocol + `build_model_client()` factory. Initially always routes to LLM provider.                                                                       |

**Exit criteria:** We can measure current model accuracy. We can record analyst corrections. We can track LLM costs across the platform.

### Phase 1: Data Collection (Sprints 3–4)

**Goal:** Analysts start generating labeled data. Bootstrap datasets from existing records.

| #   | Deliverable                      | Details                                                                                                      |
| --- | -------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| 1.1 | **Classification correction UI** | Widget on case detail page: shows auto-classification per axis, allows override. Writes to `analyst_labels`. |
| 1.2 | **Risk score override UI**       | Slider or input on case detail: shows computed risk score, allows analyst adjustment.                        |
| 1.3 | **Bootstrap dataset export**     | CLI command to export existing DB records as training data (treat current classifications as ground truth).  |
| 1.4 | **Dataset registry**             | GCS-based dataset storage with metadata table. Immutable snapshots. Train/eval/test split tooling.           |
| 1.5 | **Baseline benchmarks**          | Run eval harness on bootstrap dataset. Document accuracy per axis as the number to beat.                     |

**Exit criteria:** Analysts can correct classifications in the UI. We have a versioned dataset. We know exact accuracy of current few-shot approach.

### Phase 2: Training Pipeline (Sprints 5–7)

**Goal:** End-to-end training pipeline works. First custom model (even if it doesn't beat few-shot).

| #   | Deliverable                           | Details                                                                                                      |
| --- | ------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| 2.1 | **Experiment tracking**               | W&B or MLflow integration. Every training run logged with hyperparams, metrics, artifacts.                   |
| 2.2 | **Classification fine-tuning script** | Fine-tune a small model (e.g., Gemma 2B or Mistral 7B) on bootstrap classification data.                     |
| 2.3 | **Model registry**                    | GCS-based artifact store. Stage management (dev → staging → prod). `i4g ml register-model` CLI.              |
| 2.4 | **Shadow mode**                       | Run custom model alongside Gemini. Both predict, only Gemini output shown to analysts. Compare accuracy.     |
| 2.5 | **Evaluation pipeline**               | Automated: on model registration, run eval suite against frozen test set. Block promotion if accuracy drops. |

**Exit criteria:** We have trained a custom model. It's running in shadow mode. We can compare its accuracy to the production LLM.

### Phase 3: Serving & Optimization (Sprints 8–10)

**Goal:** Custom models serve real traffic. A/B testing validates improvements.

| #   | Deliverable                        | Details                                                                                                                       |
| --- | ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| 3.1 | **A/B testing framework**          | Case-ID-based traffic splitting. Outcome tracking (analyst corrections as ground truth). Statistical significance calculator. |
| 3.2 | **Custom model deployment**        | Vertex AI Endpoints (cloud) or Cloud Run (lightweight). Auto-scaling, health checks.                                          |
| 3.3 | **Model promotion workflow**       | Shadow → A/B → canary → full rollout. Requires eval gate + human approval.                                                    |
| 3.4 | **OCR upgrade**                    | Document AI integration with Tesseract fallback. A/B test on extraction accuracy.                                             |
| 3.5 | **Embedding evaluation & upgrade** | Evaluate cloud embeddings (text-embedding-005) vs. current Ollama. Benchmark on search relevance.                             |
| 3.6 | **Confidence calibration**         | Calibration curve from analyst corrections. Apply scaling to raw confidence scores.                                           |

**Exit criteria:** Custom model serves a percentage of production traffic. A/B tests prove it matches or exceeds LLM accuracy. Calibrated confidence scores.

### Phase 4: Advanced Capabilities (Sprints 11+, Long-Term)

**Goal:** New ML-powered features enabled by infrastructure maturity.

| #   | Deliverable                 | Details                                                                                            |
| --- | --------------------------- | -------------------------------------------------------------------------------------------------- |
| 4.1 | **Case auto-summarization** | LLM-generated summaries for analyst queue. Quality-gated by report quality feedback.               |
| 4.2 | **Duplicate detection**     | Embedding similarity pipeline on case ingestion. Threshold-based alerting.                         |
| 4.3 | **Predictive escalation**   | Supervised model on case features → escalation probability. Requires disposition labels (Phase 1). |
| 4.4 | **Image similarity**        | Screenshot embeddings (CLIP/SigLIP) for brand impersonation detection across scam sites.           |
| 4.5 | **Custom NER model**        | Fine-tuned entity extractor on analyst-corrected entities. Lower latency than LLM-based NER.       |
| 4.6 | **Drift monitoring**        | Automated detection of distribution shifts in inputs and outputs. Triggers re-training.            |

---

## 9. Immediate Priorities: What to Build Right Now

Given current resources and constraints, the **two most impactful tracks** are:

### Track A: ML Infrastructure (PRD candidate)

Build the skeleton that every future ML capability depends on:

1. **Evaluation harness** — without measurement, every improvement is a guess
2. **Label storage** — without feedback, we'll never have training data
3. **Inference framework** — without abstraction, switching models is a code change
4. **Cost tracking** — without visibility, we can't optimize spend

This is Phase 0 above. It touches core only, no UI changes, and can ship incrementally.

### Track B: Analyst Feedback Loop (PRD candidate)

The highest-leverage data collection mechanism:

1. **Classification correction widget** in the case detail UI
2. **Risk score override** in the case detail UI
3. Backend writes to `analyst_labels` table
4. Export pipeline to create training datasets from corrections

This is Phase 1 items 1.1–1.3. It requires coordinated core + UI work.

### Sequencing

```
Sprint 1–2:  Track A (infrastructure)
Sprint 3–4:  Track B (data collection) — depends on label storage from Track A
Sprint 5+:   Training pipeline, shadow mode, A/B testing
```

---

## 10. Risk Assessment

| Risk                          | Impact                                                    | Mitigation                                                                                                                         |
| ----------------------------- | --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **Insufficient labeled data** | Custom models underperform few-shot prompting             | Bootstrap from existing data. Set minimum sample size gates before training. Keep LLM fallback always available.                   |
| **Label quality**             | Analyst corrections may be inconsistent                   | Inter-annotator agreement metrics. Label review process. Weight high-agreement labels higher.                                      |
| **Model regression**          | Custom model scores worse than production                 | Eval gate on model promotion. Shadow mode before any traffic. Instant rollback to LLM.                                             |
| **Cost escalation**           | Custom model serving adds infrastructure cost             | Track cost-per-prediction. Custom model value prop must be: cheaper per prediction AND better accuracy. Otherwise stay on LLM API. |
| **Scope creep**               | ML infra becomes a project in itself                      | Tight scope per phase. Phase 0 is four deliverables, not a platform. Build only what's needed for the next phase.                  |
| **Evaluation validity**       | Golden test set doesn't represent production distribution | Refresh test set quarterly. Sample from recent cases. Track distribution drift between test set and production.                    |

---

## 11. Success Metrics

| Metric                             | Phase 0 Target                | Phase 2 Target          | Phase 3 Target                         |
| ---------------------------------- | ----------------------------- | ----------------------- | -------------------------------------- |
| **Classification accuracy (F1)**   | Measured (baseline)           | Custom model ≥ baseline | Custom model > baseline by 5%+         |
| **Analyst correction rate**        | —                             | Collecting corrections  | < 15% of cases need correction         |
| **Cost per classification**        | Measured                      | Measured                | Custom model 50%+ cheaper than LLM API |
| **Evaluation coverage**            | 1 capability (classification) | 3 capabilities          | All ML capabilities                    |
| **Mean time to detect regression** | —                             | —                       | < 24 hours                             |
| **Labeled dataset size**           | 0 (bootstrap)                 | 500+ corrections        | 2,000+ corrections                     |

---

## 12. Technical Decisions & Open Questions

### Decided

- **Experiment tracker:** W&B (hosted) for speed. Migrate to MLflow if self-hosting becomes a requirement.
- **Model hosting:** Vertex AI Endpoints for production. Ollama for local testing. Cloud Run for lightweight/experimental models.
- **Dataset format:** JSONL files in GCS, referenced by metadata table in main DB.
- **Custom model framework:** Gemma or Mistral family for fine-tuning (good size/cost/quality tradeoff). Start with Gemma 2B.
- **Few-shot remains default:** Custom models are additive. Few-shot prompting stays as the baseline and fallback forever.

### Open Questions

1. **When is enough data "enough"?** Minimum viable dataset size for fine-tuning classification. Need to benchmark: at what N do we start beating few-shot? Likely 500–1,000 labeled examples per axis.
2. **Multi-task vs. per-axis models?** Train one model for all 5 taxonomy axes, or separate models per axis? Multi-task is more data-efficient; per-axis allows independent iteration.
3. **Real-time vs. batch inference?** Current classification is synchronous (on ingestion). Custom models may have different latency profiles. Do we need a batch fallback?
4. **Privacy constraints on training data?** Can case narratives (which contain victim PII) be used for training? May need anonymization pipeline before export.
5. **Partner data sharing?** Could law enforcement partners contribute labeled data? Legal and privacy framework needed before this is feasible.

---

## 13. PRDs to Produce from This Strategy

| PRD                              | Scope                                                                                              | Source sections          | Priority                 |
| -------------------------------- | -------------------------------------------------------------------------------------------------- | ------------------------ | ------------------------ |
| **ML Infrastructure & Pipeline** | Eval harness, cost tracking, prompt versioning, model registry, inference framework, label storage | §6 (all), §7, §8 Phase 0 | **Immediate**            |
| **Analyst Feedback Loop**        | Classification correction UI, risk score override, entity correction, label export                 | §5, §8 Phase 1           | **Next**                 |
| **Custom Model Training**        | Training pipeline, experiment tracking, shadow mode, eval pipeline                                 | §8 Phase 2               | After data collection    |
| **A/B Testing & Model Serving**  | Traffic splitting, outcome tracking, Vertex AI Endpoints, promotion workflow                       | §8 Phase 3               | After first custom model |
| **OCR Modernization**            | Document AI integration, accuracy benchmarking, Tesseract fallback                                 | §3.1                     | Can run in parallel      |
| **Advanced ML Capabilities**     | Summarization, dedup, predictive escalation, image similarity                                      | §4, §8 Phase 4           | Long-term                |

---

## Appendix A: Current Model Configuration Reference

### Core (`I4G_LLM__*`)

```toml
[llm]
provider = "gemini"              # gemini | ollama | mock
chat_model = "gemini-2.5-flash"  # primary model
temperature = 0.1
vertex_ai_project = "i4g-dev"
vertex_ai_location = "us-central1"

[vector]
backend = "chroma"               # chroma | faiss | vertex_ai
embedding_model = "mxbai-embed-large"
```

### SSI (`SSI_LLM__*`)

```toml
[llm]
provider = "gemini"
model = "gemini-2.5-flash"
cheap_model = ""                 # optional lightweight model for simple states
vision_model = ""                # Ollama-specific vision override
temperature = 0.1
max_tokens = 4096
token_budget_per_session = 100000
gcp_project = "i4g-dev"
gcp_location = "us-central1"
```

### Prompt Templates

| Template           | Location                                           | Used by                        |
| ------------------ | -------------------------------------------------- | ------------------------------ |
| Fraud classifier   | `core/src/i4g/llm/prompts/fraud_classifier.md`     | `FraudClassifier`              |
| RAG assessment     | `core/src/i4g/llm/prompts/rag_assessment.md`       | `build_scam_detection_chain()` |
| Semantic NER       | `core/src/i4g/extraction/semantic_ner.py` (inline) | `extract_semantic_entities()`  |
| SSI classification | `ssi/src/ssi/classification/prompts.py` (inline)   | `classify_investigation()`     |
| Browser agent      | `ssi/src/ssi/browser/llm_client.py` (inline)       | `AgentLLMClient`               |
| Page analyzer      | `ssi/src/ssi/browser/page_analyzer.py` (inline)    | `PageAnalyzer`                 |

### Golden Example Files

| File                                         | Count      | Purpose                                    |
| -------------------------------------------- | ---------- | ------------------------------------------ |
| `core/src/i4g/taxonomy/golden_examples.json` | ~10        | Few-shot examples for fraud classification |
| `core/src/i4g/rag/golden_examples.json`      | ~5         | Few-shot examples for RAG assessment       |
| `core/src/i4g/extraction/semantic_ner.py`    | 3 (inline) | Few-shot examples for entity extraction    |

## Appendix B: Glossary

| Term                   | Definition                                                                                                                   |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| **Few-shot prompting** | Providing examples in the LLM prompt to guide output format and accuracy. No training involved.                              |
| **Fine-tuning**        | Training a pre-existing model on domain-specific data to specialize its behavior.                                            |
| **Shadow mode**        | Running a new model in parallel with production. Both predict, only production output is used. Enables risk-free comparison. |
| **A/B testing**        | Splitting traffic between model versions and measuring which performs better on real outcomes.                               |
| **Calibration**        | Adjusting raw model confidence scores so they correspond to actual empirical probabilities.                                  |
| **Golden test set**    | A fixed, human-verified evaluation dataset that is never used for training. The source of truth for accuracy measurement.    |
| **Feature store**      | Pre-computed, versioned features (case text, entity counts, structural attributes) ready for model training.                 |
| **Drift detection**    | Monitoring for changes in input data or model output distributions that signal degradation.                                  |
| **Model registry**     | A versioned catalog of trained model artifacts with stage management (dev → staging → production).                           |
