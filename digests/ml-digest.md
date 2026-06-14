# ML Digest
Generated: 2026-06-14T03:15:27.509785Z

## Public API
| Function/Class | File | Signature |
|:---|:---|:---|
| get_settings | src/ml/config.py | `def get_settings() -> Settings` |
| log_prediction | src/ml/serving/logging.py | `def log_prediction() -> None` |
| log_outcome | src/ml/serving/logging.py | `def log_outcome() -> str` |
| SimilarCase | src/ml/serving/similarity.py | `class SimilarCase` |
| SimilarityIndex | src/ml/serving/similarity.py | `class SimilarityIndex` |
| get_similarity_index | src/ml/serving/similarity.py | `def get_similarity_index() -> SimilarityIndex` |
| rebuild_index_from_bq | src/ml/serving/similarity.py | `def rebuild_index_from_bq(project_id: str | None) -> SimilarityIndex` |
| run_batch_prediction | src/ml/serving/batch.py | `def run_batch_prediction() -> None` |
| load_model | src/ml/serving/predict.py | `def load_model(artifact_uri: str) -> None` |
| is_model_ready | src/ml/serving/predict.py | `def is_model_ready() -> bool` |
| load_shadow_model | src/ml/serving/predict.py | `def load_shadow_model(artifact_uri: str) -> None` |
| is_shadow_ready | src/ml/serving/predict.py | `def is_shadow_ready() -> bool` |
| classify_text | src/ml/serving/predict.py | `def classify_text(text: str, case_id: str) -> dict[str, Any]` |
| classify_text_shadow | src/ml/serving/predict.py | `def classify_text_shadow(text: str, case_id: str, champion_prediction_id: str) -> dict[str, Any] | None` |
| load_challenger_model | src/ml/serving/predict.py | `def load_challenger_model(artifact_uri: str) -> None` |
| is_challenger_ready | src/ml/serving/predict.py | `def is_challenger_ready() -> bool` |
| load_risk_model | src/ml/serving/predict.py | `def load_risk_model(artifact_uri: str) -> None` |
| is_risk_ready | src/ml/serving/predict.py | `def is_risk_ready() -> bool` |
| predict_risk_score | src/ml/serving/predict.py | `def predict_risk_score(text: str, features: dict[str, Any] | None) -> float` |
| load_ner_model | src/ml/serving/predict.py | `def load_ner_model(artifact_uri: str) -> None` |
| is_ner_ready | src/ml/serving/predict.py | `def is_ner_ready() -> bool` |
| EntitySpan | src/ml/serving/predict.py | `class EntitySpan` |
| extract_entities | src/ml/serving/predict.py | `def extract_entities(text: str, case_id: str) -> dict[str, Any]` |
| compute_inline_features | src/ml/serving/features.py | `def compute_inline_features(text: str) -> dict[str, Any]` |
| compute_embedding | src/ml/serving/embeddings.py | `def compute_embedding(text: str) -> list[float]` |
| get_embedding_dim | src/ml/serving/embeddings.py | `def get_embedding_dim() -> int` |
| load_traffic_config | src/ml/serving/routing.py | `def load_traffic_config() -> TrafficSplitConfig` |
| RoutingDecision | src/ml/serving/routing.py | `class RoutingDecision` |
| route_prediction | src/ml/serving/routing.py | `def route_prediction(case_id: str, config: TrafficSplitConfig | None) -> RoutingDecision` |
| load_cost_profiles | src/ml/serving/routing.py | `def load_cost_profiles() -> list[ModelCostProfile]` |
| select_cheapest_model | src/ml/serving/routing.py | `def select_cheapest_model(capability: str, profiles: list[ModelCostProfile] | None) -> ModelCostProfile | None` |
| route_prediction_cost_aware | src/ml/serving/routing.py | `def route_prediction_cost_aware(case_id: str, capability: str) -> RoutingDecision` |
| startup_event | src/ml/serving/app.py | `async def startup_event() -> None` |
| load_golden_set | src/ml/training/baseline.py | `def load_golden_set(path: str | Path) -> list[dict]` |
| run_baseline | src/ml/training/baseline.py | `def run_baseline(golden_path: str | Path, classifier_fn: Callable[[str], dict[str, str]]) -> EvalResult` |
| save_baseline_result | src/ml/training/baseline.py | `def save_baseline_result(result: EvalResult, output_path: str | Path) -> None` |
| AxisMetrics | src/ml/training/evaluation.py | `class AxisMetrics` |
| EvalResult | src/ml/training/evaluation.py | `class EvalResult` |
| compute_metrics | src/ml/training/evaluation.py | `def compute_metrics(predictions: list[dict[str, str]], ground_truth: list[dict[str, str]]) -> EvalResult` |
| EntityTypeMetrics | src/ml/training/evaluation.py | `class EntityTypeMetrics` |
| NerEvalResult | src/ml/training/evaluation.py | `class NerEvalResult` |
| NerPrediction | src/ml/training/evaluation.py | `class NerPrediction` |
| NerGolden | src/ml/training/evaluation.py | `class NerGolden` |
| spans_to_bio_tags | src/ml/training/evaluation.py | `def spans_to_bio_tags(text: str, spans: list[dict[str, Any]], tokens: list[str]) -> list[str]` |
| align_labels_with_tokens | src/ml/training/evaluation.py | `def align_labels_with_tokens(labels: list[str], word_ids: list[int | None]) -> list[str]` |
| evaluate_ner | src/ml/training/evaluation.py | `def evaluate_ner(predictions: list[NerPrediction], golden: list[NerGolden]) -> NerEvalResult` |
| RegressionResult | src/ml/training/evaluation.py | `class RegressionResult` |
| evaluate_regression | src/ml/training/evaluation.py | `def evaluate_regression(predictions: list[float], ground_truth: list[float]) -> RegressionResult` |
| submit_pipeline | src/ml/training/submission.py | `def submit_pipeline(...) -> str` |
| VizierSearchParam | src/ml/training/vizier.py | `class VizierSearchParam` |
| ... | ... | `... and 84 more entries collapsed` |

## Data Models
| Model | File | Fields |
|:---|:---|:---|
| TrafficSplitConfig | src/ml/serving/routing.py | `champion_weight: float, challenger_weight: float, challenger_artifact_uri: str | None, split_stra...` |
| ModelCostProfile | src/ml/serving/routing.py | `model_id: str, capability: str, cost_per_prediction: float, avg_latency_ms: float, f1_score: float` |
| ClassifyRequest | src/ml/serving/app.py | `text: str, case_id: str, features: dict | None` |
| ModelInfo | src/ml/serving/app.py | `model_id: str, version: int, stage: str` |
| ClassifyResponse | src/ml/serving/app.py | `prediction: dict[str, dict], risk_score: float | None, model_info: ModelInfo, prediction_id: str` |
| FeedbackRequest | src/ml/serving/app.py | `prediction_id: str, case_id: str, correction: dict[str, str], analyst_id: str` |
| FeedbackResponse | src/ml/serving/app.py | `outcome_id: str, status: str` |
| HealthResponse | src/ml/serving/app.py | `status: str, model_id: str | None, shadow_active: bool, challenger_active: bool, ner_active: bool...` |
| ExtractEntitiesRequest | src/ml/serving/app.py | `text: str, case_id: str` |
| EntitySpanResponse | src/ml/serving/app.py | `text: str, label: str, start: int, end: int, confidence: float` |
| ExtractEntitiesResponse | src/ml/serving/app.py | `prediction_id: str, entities: list[EntitySpanResponse], model_info: ModelInfo` |
| RiskScoreRequest | src/ml/serving/app.py | `text: str, case_id: str, features: dict | None` |
| RiskScoreResponse | src/ml/serving/app.py | `case_id: str, risk_score: float, model_info: ModelInfo, prediction_id: str` |
| SimilarCasesRequest | src/ml/serving/app.py | `text: str, case_id: str, k: int` |
| SimilarCaseResult | src/ml/serving/app.py | `case_id: str, distance: float, score: float` |
| SimilarCasesResponse | src/ml/serving/app.py | `case_id: str, similar_cases: list[SimilarCaseResult], prediction_id: str` |
| LoraConfig | src/ml/training/config.py | `r: int, alpha: int, dropout: float, target_modules: list[str]` |
| EvalGateConfig | src/ml/training/config.py | `min_overall_f1: float, max_per_axis_regression: float, max_mse: float | None, min_spearman: float...` |
| TrainingConfig | src/ml/training/config.py | `model_id: str, capability: str, base_model: str, framework: str, training_type: str, epochs: int,...` |
| ModelAccuracy | src/ml/monitoring/accuracy.py | `model_id: str, model_version: int, total_predictions: int, outcomes_received: int, correct_predic...` |
| FeatureDefinition | src/ml/data/features.py | `name: str, feature_type: FeatureType, description: str, compute_method: ComputeMethod, version: int` |

## Routes
| Method | Path | Handler | File |
|:---|:---|:---|:---|
| GET | /health | health | src/ml/serving/app.py |
| POST | /predict/classify | predict_classify | src/ml/serving/app.py |
| POST | /predict/extract-entities | predict_extract_entities | src/ml/serving/app.py |
| POST | /feedback | feedback | src/ml/serving/app.py |
| POST | /predict/risk-score | predict_risk | src/ml/serving/app.py |
| POST | /predict/similar-cases | predict_similar_cases | src/ml/serving/app.py |

## Config
| Variable | File | Context |
|:---|:---|:---|
| I4G_ML_ | src/ml/config.py | Environment variable reference |
| I4G_ML_ETL__SOURCE_INSTANCE | src/ml/config.py | Environment variable reference |
| I4G_ML_PROJECT_ROOT | src/ml/config.py | Environment variable reference |
| project_id | src/ml/config.py | Settings field in PlatformSettings |
| region | src/ml/config.py | Settings field in PlatformSettings |
| dataset_id | src/ml/config.py | Settings field in BigQuerySettings |
| prediction_log_table | src/ml/config.py | Settings field in BigQuerySettings |
| outcome_log_table | src/ml/config.py | Settings field in BigQuerySettings |
| data_bucket | src/ml/config.py | Settings field in StorageSettings |
| datasets_prefix | src/ml/config.py | Settings field in StorageSettings |
| models_prefix | src/ml/config.py | Settings field in StorageSettings |
| dev_endpoint_name | src/ml/config.py | Settings field in ServingSettings |
| prod_endpoint_name | src/ml/config.py | Settings field in ServingSettings |
| min_replicas | src/ml/config.py | Settings field in ServingSettings |
| max_replicas | src/ml/config.py | Settings field in ServingSettings |
| machine_type | src/ml/config.py | Settings field in ServingSettings |
| default_machine_type | src/ml/config.py | Settings field in TrainingSettings |
| gpu_machine_type | src/ml/config.py | Settings field in TrainingSettings |
| gpu_type | src/ml/config.py | Settings field in TrainingSettings |
| gpu_count | src/ml/config.py | Settings field in TrainingSettings |
| source_db_connection | src/ml/config.py | Settings field in EtlSettings |
| source_instance | src/ml/config.py | Settings field in EtlSettings |
| source_db_name | src/ml/config.py | Settings field in EtlSettings |
| source_db_user | src/ml/config.py | Settings field in EtlSettings |
| source_enable_iam_auth | src/ml/config.py | Settings field in EtlSettings |
| batch_size | src/ml/config.py | Settings field in EtlSettings |
| platform | src/ml/config.py | Settings field in Settings |
| bigquery | src/ml/config.py | Settings field in Settings |
| storage | src/ml/config.py | Settings field in Settings |
| serving | src/ml/config.py | Settings field in Settings |
| training | src/ml/config.py | Settings field in Settings |
| etl | src/ml/config.py | Settings field in Settings |
| I4G_ML_PROJECT | src/ml/serving/similarity.py | Environment variable reference |
| I4G_ML_BQ_DATASET | src/ml/serving/similarity.py | Environment variable reference |
| I4G_ML_PROJECT | src/ml/training/submission.py | Environment variable reference |
| I4G_ML_REGION | src/ml/training/submission.py | Environment variable reference |
| I4G_ML_PIPELINE_ROOT | src/ml/training/submission.py | Environment variable reference |
| I4G_ML_ | src/ml/cli/app.py | Environment variable reference |
