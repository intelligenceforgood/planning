# I4G Machine Learning Strategy & Roadmap

**Date:** March 2026</br>
**Horizon:** 6–12 months</br>
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

## 6. ML Platform Architecture (Summary)

The ML Platform is a **standalone system** — separate codebase (`ml/`), separate GCP project (`i4g-ml`) — that i4g consumes as an external service through REST APIs. It is not embedded in core's business logic layer.

The platform has four layers:

- **Data layer** — ETL pipelines (i4g Cloud SQL → BigQuery), feature engineering (BigQuery SQL + Spark), versioned dataset management, data quality validation, PII redaction
- **Training layer** — Vertex AI Training (multi-framework: PyTorch, TF, XGBoost, Spark ML, HuggingFace), Vertex AI Pipelines (orchestration), Vertex AI Experiments + TensorBoard, Vertex AI Workbench (notebooks), hyperparameter tuning (Vizier)
- **Serving layer** — Vertex AI Endpoints (auto-scaling, scale-to-zero), prediction logging (features + model version + result → BigQuery), outcome logging (analyst corrections), batch prediction
- **Monitoring & continuous learning** — Vertex AI Model Monitoring (drift, skew), accuracy tracking (predictions vs outcomes), cost attribution, automated retraining triggers

Integration with i4g is through a thin `MLPlatformClient` HTTP client in core that calls prediction endpoints and sends feedback. A `build_inference_client()` factory routes to the ML platform or falls back to LLM.

> **Full details:** See `planning/prd_ml_infrastructure.md` for platform architecture, GCP resource design, integration contracts, and phased delivery.
>
> **Technical design:** See [ML Platform TDD](../core/docs/design/ml_infrastructure_tdd.md) for BigQuery schemas, pipeline specifications, Terraform modules, API contracts, and implementation details.

---

## 7. Phased Roadmap (Summary)

| Phase                               | Horizon   | Focus                                                 | Key deliverables                                                                                               |
| ----------------------------------- | --------- | ----------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| **Phase 0: Foundation**             | Now       | Infrastructure skeleton + baselines                   | Evaluation harness, prompt versioning, cost tracking, label storage schema, inference framework skeleton       |
| **Phase 1: Data Collection**        | Near-term | Analyst labeling + bootstrap datasets                 | Classification correction UI, risk score override UI, dataset export CLI, baseline benchmarks                  |
| **Phase 2: Training Pipeline**      | Mid-term  | First custom model (even if it doesn't beat few-shot) | Experiment tracking, fine-tuning scripts, model registry, shadow mode, eval pipeline                           |
| **Phase 3: Serving & Optimization** | Mid-term  | Custom models serve real traffic                      | A/B testing framework, model deployment, promotion workflow, OCR upgrade, confidence calibration               |
| **Phase 4: Advanced Capabilities**  | Long-term | New ML-powered features                               | Auto-summarization, duplicate detection, predictive escalation, image similarity, custom NER, drift monitoring |

Each phase has explicit exit criteria before the next begins. Few-shot prompting remains the baseline and fallback at every phase.

> **Full details:** See `planning/prd_ml_infrastructure.md` for sprint-level deliverables, exit criteria, and sequencing.

---

## 8. PRDs from This Strategy

| PRD                             | Scope                                                                                                        | Priority                                            |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------ | --------------------------------------------------- |
| **ML Platform**                 | Standalone ML platform: data pipelines, training (multi-framework), serving, monitoring, continuous learning | **Immediate** — `planning/prd_ml_infrastructure.md` |
| **Analyst Feedback Loop**       | Classification correction UI, risk score override, entity correction, label export                           | **Next**                                            |
| **Custom Model Training**       | Training pipeline, experiment tracking, shadow mode, eval pipeline                                           | After data collection                               |
| **A/B Testing & Model Serving** | Traffic splitting, outcome tracking, Vertex AI Endpoints, promotion workflow                                 | After first custom model                            |
| **OCR Modernization**           | Document AI integration, accuracy benchmarking, Tesseract fallback                                           | Can run in parallel                                 |
| **Advanced ML Capabilities**    | Summarization, dedup, predictive escalation, image similarity                                                | Long-term                                           |

---

## 9. Risk Assessment

| Risk                          | Impact                                                    | Mitigation                                                                                                                         |
| ----------------------------- | --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **Insufficient labeled data** | Custom models underperform few-shot prompting             | Bootstrap from existing data. Set minimum sample size gates before training. Keep LLM fallback always available.                   |
| **Label quality**             | Analyst corrections may be inconsistent                   | Inter-annotator agreement metrics. Label review process. Weight high-agreement labels higher.                                      |
| **Model regression**          | Custom model scores worse than production                 | Eval gate on model promotion. Shadow mode before any traffic. Instant rollback to LLM.                                             |
| **Cost escalation**           | Custom model serving adds infrastructure cost             | Track cost-per-prediction. Custom model value prop must be: cheaper per prediction AND better accuracy. Otherwise stay on LLM API. |
| **Scope creep**               | ML infra becomes a project in itself                      | Tight scope per phase. Phase 0 is four deliverables, not a platform. Build only what's needed for the next phase.                  |
| **Evaluation validity**       | Golden test set doesn't represent production distribution | Refresh test set quarterly. Sample from recent cases. Track distribution drift between test set and production.                    |

---

## 10. Success Metrics

| Metric                             | Phase 0 Target                | Phase 2 Target          | Phase 3 Target                         |
| ---------------------------------- | ----------------------------- | ----------------------- | -------------------------------------- |
| **Classification accuracy (F1)**   | Measured (baseline)           | Custom model ≥ baseline | Custom model > baseline by 5%+         |
| **Analyst correction rate**        | —                             | Collecting corrections  | < 15% of cases need correction         |
| **Cost per classification**        | Measured                      | Measured                | Custom model 50%+ cheaper than LLM API |
| **Evaluation coverage**            | 1 capability (classification) | 3 capabilities          | All ML capabilities                    |
| **Mean time to detect regression** | —                             | —                       | < 24 hours                             |
| **Labeled dataset size**           | 0 (bootstrap)                 | 500+ corrections        | 2,000+ corrections                     |

---

## 11. Technical Decisions & Open Questions

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

## Appendix A: Current Model Configuration Reference

### Core (`I4G_LLM__*`)

```toml
[llm]
provider = "gemini"              # gemini | ollama | mock
chat_model = "gemini-3-flash-preview"  # primary model
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
model = "gemini-3-flash-preview"
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
