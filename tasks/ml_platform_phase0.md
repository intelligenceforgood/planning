# ML Platform — Phase 0 Implementation Plan

> **Status:** In Progress
> **Created:** 2026-03-21
> **PRD:** [planning/prd_ml_infrastructure.md](../prd_ml_infrastructure.md)
> **TDD:** [ml/docs/design/ml_infrastructure_tdd.md](../../ml/docs/design/ml_infrastructure_tdd.md)
> **Scratchpad:** [ml_platform_implementation_scratchpad.md](ml_platform_implementation_scratchpad.md)

**Goal:** Stand up the ML platform end-to-end. Train a first model (classification) and deploy it to a
serving endpoint. Prove pipeline completeness — model quality does not matter yet.

**Affected repos:** `ml/` (new), `infra/`, `core/`, `planning/`

---

## Sprint 1 — Infrastructure, Repo Scaffold, Core Integration (weeks 1–8)

**Exit criteria:** `i4g-ml` GCP project exists with all resources provisioned. `ml/` repo scaffolded and
builds. `core/` has analyst_labels table, ML client, settings, and factory wiring with unit tests.
Everything is merged and deployable independently of Sprint 2.

### 1.1 GCP Project Setup (manual — blocks all cloud tasks)

- [x] 1. Create `i4g-ml` GCP project and link billing (requires org admin)
- [x] 2. Confirm Google for Nonprofits eligibility for $10K/year GCP credits

### 1.2 Terraform Modules (no blockers — start immediately)

- [x] 3. Write `infra/modules/bigquery/dataset/` module (`main.tf`, `variables.tf`, `outputs.tf`)
- [x] 4. Write `infra/modules/vertex_ai/endpoint/` module (`main.tf`, `variables.tf`, `outputs.tf`)

### 1.3 Infrastructure Provisioning (blocked on 1.1 + 1.2)

- [ ] 5. Enable GCP APIs via Terraform (aiplatform, bigquery, storage, run, scheduler, AR, etc.)
- [ ] 6. Create `sa-ml` service account with IAM roles (aiplatform.user, bigquery.dataEditor, etc.)
- [ ] 7. Create GCS bucket `i4g-ml-data` (versioning, lifecycle: Nearline@90d, Coldline@365d)
- [ ] 8. Create Artifact Registry repo `ml-containers`
- [ ] 9. Create BigQuery dataset `i4g_ml` with all tables:
  - [ ] 9a. `raw_cases`, `raw_classification_results`, `raw_entities`, `raw_analyst_labels`
  - [ ] 9b. `features_case_features`
  - [ ] 9c. `predictions_prediction_log`, `predictions_outcome_log`
  - [ ] 9d. `training_dataset_registry`
  - [ ] 9e. `analytics_model_performance`
- [ ] 10. Create Vertex AI Endpoints (`serving-dev`, `serving-prod`)
- [ ] 11. Grant cross-project IAM:
  - [ ] 11a. `sa-ml` → `i4g-dev`: `roles/cloudsql.client` (ETL reads source DB)
  - [ ] 11b. `sa-core@i4g-dev` → `i4g-ml`: `roles/aiplatform.user` (dev consumer)
  - [ ] 11c. `sa-core@i4g-prod` → `i4g-ml`: `roles/aiplatform.user` (prod consumer)

### 1.4 Compose ML Stack (blocked on 1.3)

- [x] 12. Create `infra/stacks/ml/main.tf` composing all resources above
- [x] 13. Create `infra/environments/ml/` root module (`main.tf`, `terraform.tfvars`, `backend.tf`,
      `providers.tf`)
- [x] 14. Run `terraform fmt -check -recursive` — must pass
- [x] 15. Run `terraform plan` against `i4g-ml` — verify clean plan, no errors

### 1.5 ML Repo Scaffold (no blockers — start immediately)

- [x] 16. Create `ml/` repo with directory structure per PRD §10:
  - [x] 16a. `pyproject.toml` with core + train-pytorch + train-xgboost + dev dependencies
  - [x] 16b. `Makefile`, `README.md`, `VERSION.txt`
  - [x] 16c. `src/ml_platform/__init__.py`, `config.py`
  - [x] 16d. `src/ml_platform/data/` — `etl.py`, `features.py`, `datasets.py`, `validation.py`, `pii.py`
        (stubs)
  - [x] 16e. `src/ml_platform/training/` — `pipeline.py`, `config.py`, `evaluation.py`, `baseline.py`
        (stubs)
  - [x] 16f. `src/ml_platform/serving/` — `app.py`, `predict.py`, `features.py`, `logging.py` (stubs)
  - [x] 16g. `src/ml_platform/registry/` — `models.py`, `promotion.py` (stubs)
  - [x] 16h. `src/ml_platform/monitoring/` — `drift.py`, `accuracy.py`, `cost.py`, `triggers.py` (stubs)
  - [x] 16i. `containers/train-pytorch/`, `containers/train-xgboost/`, `containers/serve/` (empty dirs)
  - [x] 16j. `pipelines/`, `notebooks/`, `tests/unit/`, `tests/integration/`, `scripts/`, `docs/`
  - [x] 16k. `config/settings.default.toml`, `config/settings.dev.toml`
  - [x] 16l. `.github/copilot-instructions.md`
- [x] 17. Verify `pip install -e .` succeeds in a clean venv
- [x] 18. Implement `TrainingConfig` Pydantic model (`src/ml_platform/training/config.py`) — validates
      training YAML configs
- [x] 19. Implement `FeatureDefinition` catalog (`src/ml_platform/data/features.py`) — feature type enum,
      compute method enum, FEATURE_CATALOG list
- [x] 20. Add unit tests for `TrainingConfig` and `FeatureDefinition`

### 1.6 I4G Core Integration (no blockers — start immediately, parallel with 1.5)

- [x] 21. Add `analyst_labels` Alembic migration — FK → cases, indexed `(case_id, axis)`, columns:
      `id`, `case_id`, `axis`, `label_code`, `analyst_id`, `confidence`, `notes`, `created_at`
- [x] 22. Run migration on local SQLite — verify table created
- [x] 23. Add `[ml]` settings section to `core/config/settings.default.toml`:
      `inference_backend`, `platform_base_url`, `platform_auth_method`, `fallback_to_llm`
- [x] 24. Add settings unit test under `tests/unit/settings/`
- [x] 25. Implement `MLPlatformClient` (`core/src/i4g/ml/client.py`) — async httpx client with
      `classify(text, case_id)` and `send_feedback(prediction_id, case_id, correction, analyst_id)`
- [x] 26. Wire `build_inference_client()` factory in `core/src/i4g/services/factories.py` — routes to
      `MLPlatformClient` when `inference_backend == "ml_platform"`, else existing LLM client
- [x] 27. Unit tests for `MLPlatformClient` (mock HTTP) and `build_inference_client` (both backends)
- [x] 28. Run `conda run -n i4g pre-commit run --all-files` — two passes, must exit clean

### Sprint 1 — Verification Checklist

- [x] `terraform plan` on `infra/environments/ml/` produces a clean plan
- [x] `ml/` repo installs and passes `pytest tests/unit`
- [x] `core/` migration runs, settings load, ML client tests pass
- [x] Pre-commit passes in both `core/` and `ml/`
- [x] All three repos are in a mergeable state

---

## Sprint 2 — Data Pipeline, Training, Serving, Validation (weeks 9–18)

**Exit criteria:** Data flows from source Cloud SQL to BigQuery. A model trains on Vertex AI and deploys
to `serving-dev`. Predictions serve and log to BigQuery. Few-shot baseline measured and compared.
End-to-end smoke test passes. System works.

### 2.1 ETL Pipeline (blocked on Sprint 1 infra)

- [ ] 29. Implement `run_incremental_ingest()` in `ml/src/ml_platform/data/etl.py` — watermark-based
      incremental sync from Cloud SQL to BigQuery `raw.*` tables
- [ ] 30. Implement `IngestConfig` dataclass and `TABLE_CONFIGS` mapping (cases, classification_results,
      entities, analyst_labels)
- [ ] 31. Build ETL container image and push to `ml-containers` Artifact Registry
- [ ] 32. Deploy ETL as Cloud Run Job (`ml-etl-ingest`), triggered daily at 2 AM UTC via Cloud Scheduler
- [ ] 33. Run ETL manually once — verify rows land in BigQuery `raw.*` tables
- [ ] 34. Unit tests for ETL (mock BigQuery + SQLAlchemy)

### 2.2 Feature Engineering (blocked on 2.1)

- [ ] 35. Create BigQuery SQL view `v_case_features` joining `raw_cases`, `raw_entities`,
      `raw_classification_results`
- [ ] 36. Set up scheduled query to materialize view into `features_case_features` table
- [ ] 37. Verify `features_case_features` populates after ETL + materialization

### 2.3 Dataset & Golden Set (blocked on 2.2)

- [ ] 38. Implement `create_dataset_version()` in `ml/src/ml_platform/data/datasets.py` — joins features
      - labels, validates, stratified split, exports JSONL to GCS, registers in `training_dataset_registry`
- [ ] 39. Implement data validation (`ml/src/ml_platform/data/validation.py`) — min samples, class
      balance, null rates, dedup
- [ ] 40. Curate first golden test set (~50–100 manually verified cases) — export to
      `gs://i4g-ml-data/datasets/classification/golden/test.jsonl`
- [ ] 41. Bootstrap first training dataset from existing LLM classifications — export v1 to GCS
- [ ] 42. Unit tests for dataset creation and validation

### 2.4 Evaluation Harness & Baseline (blocked on 2.3)

- [ ] 43. Implement evaluation harness (`ml/src/ml_platform/training/evaluation.py`) — per-axis P/R/F1,
      overall F1, `EvalResult` dataclass
- [ ] 44. Implement eval gate (`ml/src/ml_platform/registry/promotion.py`) — `_passes_eval_gate()` checks
      overall F1 ≥ champion, no per-axis regression > 5%
- [ ] 45. Implement baseline benchmark (`ml/src/ml_platform/training/baseline.py`) — runs current few-shot
      LLM classifier against golden set, records per-axis F1
- [ ] 46. Run baseline benchmark — record results as the number to beat
- [ ] 47. Unit tests for eval harness and eval gate

### 2.5 Training Containers (no blockers — start when 1.5 complete)

- [ ] 48. Build PyTorch training container (`containers/train-pytorch/`):
  - [ ] 48a. `Dockerfile` based on Vertex AI PyTorch GPU image
  - [ ] 48b. `train.py` — load config from GCS, load data, Gemma 2B + LoRA fine-tune, log metrics to
        Vertex AI Experiments, upload artifacts to GCS
  - [ ] 48c. `requirements.txt`
- [ ] 49. Build XGBoost training container (`containers/train-xgboost/`):
  - [ ] 49a. `Dockerfile` based on python:3.11-slim
  - [ ] 49b. `train.py` — load tabular features from BigQuery, train XGBoost, log metrics, upload model
  - [ ] 49c. `requirements.txt`
- [ ] 50. Build serving container (`containers/serve/`):
  - [ ] 50a. `Dockerfile` based on python:3.11-slim
  - [ ] 50b. `serve.py` — FastAPI with `/predict/classify`, `/feedback`, `/health`
  - [ ] 50c. `requirements.txt`
- [ ] 51. Build and push all three container images to Artifact Registry via `scripts/build_container.sh`
- [ ] 52. Test serving container locally (`docker run`, curl `/health` and `/predict/classify`)

### 2.6 Training Pipeline (blocked on 2.4 + 2.5)

- [ ] 53. Create training config YAML (`pipelines/configs/classification_gemma2b.yaml`) — model_id,
      capability, base_model, LoRA params, hyperparams, label_schema, eval_gate
- [ ] 54. Implement KFP v2 training pipeline (`pipelines/training_pipeline.py`) — 5 components:
      `prepare_dataset` → `train_model` → `evaluate_model` → `register_model` → `deploy_model`
- [ ] 55. Implement model promotion workflow (`ml/src/ml_platform/registry/promotion.py`) —
      `promote_model()` with stage transitions (experimental → candidate → champion)
- [ ] 56. Implement prediction logging (`ml/src/ml_platform/serving/logging.py`) — `log_prediction()` and
      `log_outcome()` writing to BigQuery (fire-and-forget)
- [ ] 57. Test training pipeline locally (dry-run with mock data, verify component contracts)

### 2.7 Deploy & Verify (blocked on 2.6 + Sprint 1 infra)

- [ ] 58. Run training pipeline on Vertex AI — first real training run
- [ ] 59. Verify model registered in Vertex AI Model Registry with correct metadata and stage label
- [ ] 60. Pipeline deploys model to `serving-dev` endpoint (auto if eval gate passes)
- [ ] 61. Call `serving-dev` `/predict/classify` — verify prediction response structure
- [ ] 62. Verify prediction logged in BigQuery `predictions_prediction_log`
- [ ] 63. Call `/feedback` — verify outcome logged in BigQuery `predictions_outcome_log`

### 2.8 End-to-End Validation

- [ ] 64. E2E smoke test: Core `MLPlatformClient` → ML platform endpoint → prediction logged in BigQuery
- [ ] 65. Compare custom model F1 vs. few-shot baseline (may not beat it — OK for Phase 0)
- [ ] 66. Create Jupyter notebook showing per-axis evaluation metrics (`notebooks/evaluation/`)
- [ ] 67. Document in `ml/docs/`:
  - [ ] 67a. Architecture diagram (Mermaid)
  - [ ] 67b. Deployment runbook (build containers, run pipeline, deploy endpoint)
  - [ ] 67c. Monitoring setup (BigQuery queries, model monitoring config)
- [ ] 68. Run pre-commit in `ml/`, `core/`, `infra/` — all pass

### Sprint 2 — Verification Checklist

- [ ] ETL runs and populates BigQuery `raw.*` tables
- [ ] Feature materialization produces `features_case_features` rows
- [ ] Golden test set exists in GCS, baseline F1 recorded
- [ ] Training pipeline runs end-to-end on Vertex AI
- [ ] Model deployed to `serving-dev`, returns predictions
- [ ] Prediction + outcome logging verified in BigQuery
- [ ] Core `MLPlatformClient` calls ML endpoint successfully
- [ ] Documentation complete
- [ ] Pre-commit passes in all repos
- [ ] All repos are in a mergeable state

---

## Risks

| Risk                                     | Impact                                    | Mitigation                                               |
| ---------------------------------------- | ----------------------------------------- | -------------------------------------------------------- |
| GCP project creation blocked (org admin) | All cloud tasks blocked                   | Start non-cloud tasks immediately (repos, modules, core) |
| Cross-project IAM misconfigured          | ETL can't read source, Core can't call ML | Test IAM grants with `gcloud` before pipeline runs       |
| Insufficient labeled data                | Model underperforms baseline              | Expected for Phase 0 — bootstrap from LLM outputs        |
| Alembic migration on SQLite + PostgreSQL | Schema drift                              | Test migration on both backends                          |
| Cold start latency on scale-to-zero      | 10–30s first request                      | Acceptable at 10K/month; set min_replicas=1 if needed    |
| New Terraform modules untested           | Infra provisioning fails                  | Write modules early, test with `terraform plan`          |

## Post-Sprint Deliverables

- **Task checkboxes:** Check off every completed task immediately
- **Manual steps:** `terraform apply` on `environments/ml/`, Alembic migration on dev/prod,
  container image builds, pipeline submission
- **Risk assessment:** Breaking-change risks + validation tests to run locally and on dev
- **Merge readiness:** Each sprint produces a mergeable state across all affected repos
