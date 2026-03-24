# ML Platform — Phase 2 Deferred Tasks

> **Source:** Extracted from [tasks/ml_phase2_training_maturity.md](ml_phase2_training_maturity.md) at Phase 2 archive
> **Action:** Address in Phase 3 or as standalone work items

---

## Incomplete Sprint Tasks

### Vizier Sweep (Sprint 2.2)

- [ ] Run one XGBoost sweep manually on dev (10 trials), document results in `notebooks/experiments/vizier_xgboost_sweep.ipynb` (expensive — $50+, defer to budget approval)

### NER E2E Deployment (Sprint 4.7)

- [ ] Confirm NER model registered as `experimental` in Vertex AI Model Registry (awaiting pipeline completion)
- [ ] Promote to `candidate`, deploy to `serving-dev` (set `NER_MODEL_ARTIFACT_URI`)
- [ ] Run eval harness: entity F1 per type, compare to LLM extraction baseline
- [ ] Document baseline metrics in `notebooks/evaluation/ner_baseline.ipynb`

### Graph Features Validation (Sprint 5.3)

- [ ] Local validation: run pipeline with `DirectRunner` on synthetic entity data, confirm `features_graph_features` output (requires live BQ connection for ReadFromBigQuery — DoFn unit tests cover logic)
- [ ] Train classification model with/without graph features, document comparison in `notebooks/experiments/graph_features_ablation.ipynb` (blocked on sufficient training data)

---

## Manual Steps (Not Yet Completed)

- [ ] Create Looker Studio dashboard (Sprint 1.4) — connect to BigQuery `analytics_*` tables (requires manual GUI work):
  - **Accuracy:** Rolling F1 per model per axis (line chart), override rate trend (bar), confusion matrix (latest period)
  - **Cost:** Per-prediction cost comparison ML vs. LLM (bar chart by capability), cumulative savings (line), cost breakdown by GCP component (pie)
- [ ] Activate shadow mode on prod by setting `SHADOW_MODEL_ARTIFACT_URI` on Cloud Run service
- [ ] After NER deployed: set `NER_MODEL_ARTIFACT_URI` on prod Cloud Run service
- [ ] Verify Dataflow job completes and `features_graph_features` populated on dev (weekly Cloud Scheduler — will run Sunday)

---

## Phase 2 Exit → Phase 3 Handoff

- [x] Archive to `planning/archive/ml_platform_phase2_summary.md` (convert to past tense)
- [ ] Update `prd_ml_infrastructure.md` Phase 2 table with completion date
- [x] Add Phase 2 entry to `planning/change_log.md`
- [ ] Update `ml/docs/README.md` with any new runbooks or design docs
- [ ] Phase 3 kickoff: champion/challenger A/B routing, batch prediction backfill, Vertex AI Feature Store
