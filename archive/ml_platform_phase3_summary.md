# ML Platform — Phase 3: Advanced Capabilities Summary (Archived)

> **Completed:** 2026-03-28 | **PRD:** [prd_ml_infrastructure.md §12 Phase 3](../prd_ml_infrastructure.md) | **Task plan:** [tasks/ml_phase3_advanced_capabilities.md](../tasks/ml_phase3_advanced_capabilities.md)

## What Was Built

**Goal:** Deliver multi-capability ML serving (≥ 4 capabilities), champion/challenger A/B routing with
outcome tracking, batch prediction backfill, Vertex AI Feature Store, cost-aware routing, and put the
platform into steady-state operations. Phase 2 delivered continuous retraining, shadow mode, and NER
training infrastructure; Phase 3 made the platform multi-capability and operationally mature.

**Repos touched:** `ml/` (primary), `infra/`, `core/`, `docs/`

---

## Phase 2 Carry-Overs

- **P2-A NER E2E deployment:** NER training pipeline succeeded (ner-bert-v1-r9) after fixing
  experiment context collision (`resume=True` on `aiplatform.start_run()` — earlier runs r1–r3
  failed). Model deployed to ml-serving via Terraform; `/predict/extract-entities` verified live. ✅
- **P2-B Shadow mode:** Activated on dev — prerequisite for A/B routing. ✅
- **P2-C Graph features:** Verified `features_graph_features` populated. ✅
- **P2-D/E PRD + docs updates:** Completed. ✅

---

## Sprint 1 — Champion/Challenger A/B Routing

- `TrafficSplitConfig` Pydantic model in `ml/src/ml/serving/routing.py` with weight validation,
  random and deterministic (hash-based) split strategies
- `route_prediction()` returns `(variant, model_state_key, routing_reason)`
- Challenger model loaded at startup alongside champion and shadow
- Variant column in `predictions_prediction_log`; per-variant accuracy in `analytics_variant_comparison`
- Terraform: `CHALLENGER_MODEL_ARTIFACT_URI`, `CHALLENGER_TRAFFIC_WEIGHT` env vars
- Verified 80/20 split on dev with outcome tracking in BQ

## Sprint 2 — Batch Prediction

- `ml/src/ml/serving/batch.py`: `run_batch_prediction()` reads from BQ, infers in batches, writes
  results. Supports classification, NER, and embedding capabilities.
- Cloud Run Job `batch-prediction` with `--capability`, `--model-artifact-uri`, `--source-query`,
  `--batch-size` args
- BQ table `batch_predictions` partitioned by `predicted_at`, clustered by `capability`
- Classification backfill completed on dev (1000 rows)
- NER backfill skipped (dev database wipe + re-prime planned; backfill would be discarded)

## Sprint 3 — Vertex AI Feature Store

- Terraform: `google_vertex_ai_featurestore` resource `i4g_ml_features`, entity type `case` with
  10 features matching `FEATURE_CATALOG`
- `ml/src/ml/data/feature_store.py`: `sync_features_to_store()` ingests from BQ with watermark logic
- `ml/src/ml/serving/features.py`: `fetch_online_features()` with LRU cache (128 entries, 60s TTL),
  fallback to `compute_inline_features()` when Feature Store unavailable
- Cloud Run Job `feature-store-sync` + Cloud Scheduler (Sunday 5 AM UTC)
- Initial sync: 100 entities. Online read latency: 161ms (single dev node; scales with node count)

## Sprint 4 — Risk Scoring Capability

- XGBoost regressor (`reg:squarederror`), features from `features_case_features` + `features_graph_features`
- `POST /predict/risk-score`: returns float 0.0–1.0, model_info, prediction_id
- Pipeline config: `pipelines/configs/risk_scoring_xgboost.yaml`
- Model deployed: `gs://i4g-ml-data/models/risk-scoring-xgboost-v1-20260328-0447`
- Eval gate: MSE ≤ champion threshold, Spearman ρ ≥ 0.6
- Core integration: `score_risk()` client + `build_risk_scoring_client()` factory

## Sprint 5 — Document Similarity

- `sentence-transformers` (`all-MiniLM-L6-v2`) for 384-dim embeddings
- In-process FAISS index rebuilt from BQ `features_case_embeddings` at startup
- `POST /predict/similar-cases`: returns top-k similar case_ids with distance/score
- Embedding batch pipeline: 1000 embeddings computed and stored in BQ
- Cloud Run Job `embedding-refresh` + Cloud Scheduler (Sunday 6 AM UTC)
- Core integration: `find_similar_cases()` client

## Sprint 6 — Cost-Aware Routing

- `ModelCostProfile` + `load_cost_profiles()` reads from `analytics_cost_summary` BQ table
- `select_cheapest_model()`: picks cheapest model meeting f1_score quality bar (default 0.8)
- `route_prediction_cost_aware()`: when `COST_AWARE_ROUTING=true`, overrides random A/B split
  with cost-optimal selection; falls back to standard A/B when profiles unavailable
- `routing_reason` column in `predictions_prediction_log`
- Verified: routing_reason=`cost_aware:model=classification-xgboost-v1-...,cost=0.0010` logged in BQ
- Fixed model-mapping bug: compare cheapest model_id against champion model_id, not string "champion"

## Sprint 7 — Integration Testing + Documentation + Exit

- 10 integration tests in `tests/integration/test_phase3_endpoints.py`: all passing
  - A/B routing + variant logging + feedback
  - Risk scoring + BQ logging
  - Similar cases with FAISS
  - Feature Store + health check
  - Cost-aware routing_reason verification
- Updated `ml/docs/design/architecture.md`, `monitoring.md`, runbooks
- No new public-facing endpoints for `docs/book/` (ML serving is internal)

---

## Exit Criteria Status

| Criterion                         | Status     | Notes                                                                            |
| --------------------------------- | ---------- | -------------------------------------------------------------------------------- |
| ≥ 4 capabilities operational      | ✅         | Classification, NER, risk scoring, document similarity all operational           |
| A/B routing with outcome tracking | ✅         | Variant + routing_reason logged in BQ; feedback records outcomes                 |
| Batch prediction backfill         | ✅         | 1000 rows classification + 1000 embeddings                                       |
| Feature Store sub-100ms           | ⚠️ Partial | 161ms on single dev node; scales with node count                                 |
| Cost-aware routing tested         | ✅         | XGBoost + PyTorch, cost profiles in BQ                                           |
| Labeled dataset ≥ 1,000           | ⚠️ Gap     | 346 predictions. Plan: production traffic + batch backfill of historical cases   |
| Regression detection < 12h        | ⚠️ Gap     | Infrastructure ready (drift tables + scheduler); needs production traffic volume |

---

## Key Code Changes

| File                                     | Change                                             |
| ---------------------------------------- | -------------------------------------------------- |
| `ml/src/ml/serving/routing.py`           | A/B routing, cost-aware routing, cost profiles     |
| `ml/src/ml/serving/app.py`               | Risk scoring, similarity, NER endpoints            |
| `ml/src/ml/serving/batch.py`             | Batch prediction module                            |
| `ml/src/ml/serving/similarity.py`        | FAISS index + search                               |
| `ml/src/ml/serving/embeddings.py`        | Sentence-transformer embedding                     |
| `ml/src/ml/serving/features.py`          | Online feature serving with cache + fallback       |
| `ml/src/ml/data/feature_store.py`        | Feature Store sync from BQ                         |
| `ml/src/ml/training/pipeline.py`         | Risk scoring eval gate, EvalOutputs fix            |
| `containers/train-ner/train.py`          | `resume=True` experiment context fix               |
| `infra/stacks/ml/main.tf`                | Feature Store, Cloud Run Jobs, env vars, BQ tables |
| `infra/environments/ml/terraform.tfvars` | Model URIs, routing config                         |

---

## Known Issues / Deferred

1. **NER backfill:** NER model deployed and serving; dev backfill skipped due to planned database
   wipe. Run backfill after dev re-prime.
2. **Feature Store latency:** 161ms > 100ms target on single dev node. Scale to 3 nodes for prod.
3. **HuggingFace rate limiting:** Unauthenticated downloads cause slow cold starts for similarity.
   Fix: set `HF_TOKEN` env var or bake model into container.
4. **Routing model-mapping fix:** Code committed locally; needs container rebuild + push (amd64).
   Use Cloud Build once project permissions are configured.
5. **Labeled dataset gap:** Need production traffic to reach 1,000 examples.
