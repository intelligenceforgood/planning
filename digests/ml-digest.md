# ML Digest
Generated: 2026-07-14T16:03:15Z

## Public API
| Function/Class | File | Signature |
| :--- | :--- | :--- |
| AccuracyReport | src/ml/monitoring/accuracy.py | `class AccuracyReport` |
| AxisAccuracy | src/ml/monitoring/accuracy.py | `class AxisAccuracy` |
| AxisMetrics | src/ml/training/evaluation.py | `class AxisMetrics` |
| BigQuerySettings | src/ml/config.py | `class BigQuerySettings(BaseModel)` |
| ClassifyRequest | src/ml/serving/app.py | `class ClassifyRequest(BaseModel)` |
| ClassifyResponse | src/ml/serving/app.py | `class ClassifyResponse(BaseModel)` |
| ComponentCost | src/ml/monitoring/cost.py | `class ComponentCost` |
| ComputeConnectedComponents | src/ml/data/graph_features.py | `class ComputeConnectedComponents(beam.DoFn)` |
| ComputeMethod | src/ml/data/features.py | `class ComputeMethod(StrEnum)` |
| ComputePerCaseFeatures | src/ml/data/graph_features.py | `class ComputePerCaseFeatures(beam.DoFn)` |
| CostComparison | src/ml/monitoring/cost.py | `class CostComparison` |
| CostSummary | src/ml/monitoring/cost.py | `class CostSummary` |
| DriftReport | src/ml/monitoring/drift.py | `class DriftReport` |
| EmitCoOccurrencePairs | src/ml/data/graph_features.py | `class EmitCoOccurrencePairs(beam.DoFn)` |
| EntitySpan | src/ml/serving/predict.py | `class EntitySpan` |
| EntitySpanResponse | src/ml/serving/app.py | `class EntitySpanResponse(BaseModel)` |
| EntityTypeMetrics | src/ml/training/evaluation.py | `class EntityTypeMetrics` |
| EtlSettings | src/ml/config.py | `class EtlSettings(BaseModel)` |
| EvalGateConfig | src/ml/training/config.py | `class EvalGateConfig(BaseModel)` |
| EvalOutputs | src/ml/training/pipeline.py | `class EvalOutputs(NamedTuple)` |
| EvalResult | src/ml/training/evaluation.py | `class EvalResult` |
| ExtractEntitiesRequest | src/ml/serving/app.py | `class ExtractEntitiesRequest(BaseModel)` |
| ExtractEntitiesResponse | src/ml/serving/app.py | `class ExtractEntitiesResponse(BaseModel)` |
| FeatureDefinition | src/ml/data/features.py | `class FeatureDefinition(BaseModel)` |
| FeatureDrift | src/ml/monitoring/drift.py | `class FeatureDrift` |
| FeatureType | src/ml/data/features.py | `class FeatureType(StrEnum)` |
| FeedbackRequest | src/ml/serving/app.py | `class FeedbackRequest(BaseModel)` |
| FeedbackResponse | src/ml/serving/app.py | `class FeedbackResponse(BaseModel)` |
| HealthResponse | src/ml/serving/app.py | `class HealthResponse(BaseModel)` |
| IngestConfig | src/ml/data/etl.py | `class IngestConfig` |
| LoraConfig | src/ml/training/config.py | `class LoraConfig(BaseModel)` |
| MergeAndEmitRows | src/ml/data/graph_features.py | `class MergeAndEmitRows(beam.DoFn)` |
| ModelAccuracy | src/ml/monitoring/accuracy.py | `class ModelAccuracy` |
| ModelCostProfile | src/ml/serving/routing.py | `class ModelCostProfile` |
| ModelInfo | src/ml/serving/app.py | `class ModelInfo(BaseModel)` |
| NerEvalResult | src/ml/training/evaluation.py | `class NerEvalResult` |
| NerGolden | src/ml/training/evaluation.py | `class NerGolden` |
| NerPrediction | src/ml/training/evaluation.py | `class NerPrediction` |
| PlatformSettings | src/ml/config.py | `class PlatformSettings(BaseModel)` |
| PredictionDrift | src/ml/monitoring/drift.py | `class PredictionDrift` |
| PromotionDecision | src/ml/registry/promotion.py | `class PromotionDecision` |
| RegressionResult | src/ml/training/evaluation.py | `class RegressionResult` |
| RetrainingTrigger | src/ml/monitoring/triggers.py | `class RetrainingTrigger` |
| RiskScoreRequest | src/ml/serving/app.py | `class RiskScoreRequest(BaseModel)` |
| RiskScoreResponse | src/ml/serving/app.py | `class RiskScoreResponse(BaseModel)` |
| RoutingDecision | src/ml/serving/routing.py | `class RoutingDecision` |
| ServingSettings | src/ml/config.py | `class ServingSettings(BaseModel)` |
| Settings | src/ml/config.py | `class Settings(BaseModel)` |
| ShadowComparison | src/ml/monitoring/accuracy.py | `class ShadowComparison` |
| SimilarCase | src/ml/serving/similarity.py | `class SimilarCase` |
| ... | ... | ... and 118 more entries collapsed |

## Data Models
| Model | File | Fields |
| :--- | :--- | :--- |
| BigQuerySettings | src/ml/config.py | `dataset_id: str, prediction_log_table: str, outcome_log_table: str` |
| ClassifyRequest | src/ml/serving/app.py | `text: str, case_id: str, features: dict | None` |
| ClassifyResponse | src/ml/serving/app.py | `prediction: dict[str, dict], risk_score: float | None, model_info: ModelInfo, prediction_id: st...` |
| EntitySpanResponse | src/ml/serving/app.py | `text: str, label: str, start: int, end: int, confidence: float` |
| EtlSettings | src/ml/config.py | `source_db_connection: str, source_instance: str, source_db_name: str, source_db_user: str, sour...` |
| EvalGateConfig | src/ml/training/config.py | `min_overall_f1: float, max_per_axis_regression: float, max_mse: float | None, min_spearman: flo...` |
| ExtractEntitiesRequest | src/ml/serving/app.py | `text: str, case_id: str` |
| ExtractEntitiesResponse | src/ml/serving/app.py | `prediction_id: str, entities: list[EntitySpanResponse], model_info: ModelInfo` |
| FeatureDefinition | src/ml/data/features.py | `name: str, feature_type: FeatureType, description: str, compute_method: ComputeMethod, version:...` |
| FeedbackRequest | src/ml/serving/app.py | `prediction_id: str, case_id: str, correction: dict[str, str], analyst_id: str` |
| FeedbackResponse | src/ml/serving/app.py | `outcome_id: str, status: str` |
| HealthResponse | src/ml/serving/app.py | `status: str, model_id: str | None, shadow_active: bool, challenger_active: bool, ner_active: bo...` |
| LoraConfig | src/ml/training/config.py | `r: int, alpha: int, dropout: float, target_modules: list[str]` |
| ModelInfo | src/ml/serving/app.py | `model_id: str, version: int, stage: str` |
| PlatformSettings | src/ml/config.py | `project_id: str, region: str` |
| RiskScoreRequest | src/ml/serving/app.py | `text: str, case_id: str, features: dict | None` |
| RiskScoreResponse | src/ml/serving/app.py | `case_id: str, risk_score: float, model_info: ModelInfo, prediction_id: str` |
| ServingSettings | src/ml/config.py | `dev_endpoint_name: str, prod_endpoint_name: str, min_replicas: int, max_replicas: int, machine_...` |
| Settings | src/ml/config.py | `platform: PlatformSettings, bigquery: BigQuerySettings, storage: StorageSettings, serving: Serv...` |
| SimilarCaseResult | src/ml/serving/app.py | `case_id: str, distance: float, score: float` |
| SimilarCasesRequest | src/ml/serving/app.py | `text: str, case_id: str, k: int` |
| SimilarCasesResponse | src/ml/serving/app.py | `case_id: str, similar_cases: list[SimilarCaseResult], prediction_id: str` |
| StorageSettings | src/ml/config.py | `data_bucket: str, datasets_prefix: str, models_prefix: str` |
| TrafficSplitConfig | src/ml/serving/routing.py | `champion_weight: float, challenger_weight: float, challenger_artifact_uri: str | None, split_st...` |
| TrainingConfig | src/ml/training/config.py | `model_id: str, capability: str, base_model: str, framework: str, training_type: str, epochs: in...` |
| TrainingSettings | src/ml/config.py | `default_machine_type: str, gpu_machine_type: str, gpu_type: str, gpu_count: int` |

## Routes
| Method | Path | Handler | File |
| :--- | :--- | :--- | :--- |
| GET | /health | health | src/ml/serving/app.py |
| POST | /feedback | feedback | src/ml/serving/app.py |
| POST | /predict/classify | predict_classify | src/ml/serving/app.py |
| POST | /predict/extract-entities | predict_extract_entities | src/ml/serving/app.py |
| POST | /predict/risk-score | predict_risk | src/ml/serving/app.py |
| POST | /predict/similar-cases | predict_similar_cases | src/ml/serving/app.py |

## Config
| Variable | File | Context |
| :--- | :--- | :--- |
| I4G_ML_ | src/ml/cli/app.py | Environment variable reference |
| I4G_ML_ | src/ml/config.py | Environment variable reference |
| I4G_ML_BQ_DATASET | src/ml/serving/similarity.py | Environment variable reference |
| I4G_ML_ETL__SOURCE_INSTANCE | src/ml/config.py | Environment variable reference |
| I4G_ML_PIPELINE_ROOT | src/ml/training/submission.py | Environment variable reference |
| I4G_ML_PROJECT | src/ml/serving/similarity.py | Environment variable reference |
| I4G_ML_PROJECT | src/ml/training/submission.py | Environment variable reference |
| I4G_ML_PROJECT_ROOT | src/ml/config.py | Environment variable reference |
| I4G_ML_REGION | src/ml/training/submission.py | Environment variable reference |
| batch_size | src/ml/config.py | Settings field in EtlSettings |
| bigquery | src/ml/config.py | Settings field in Settings |
| data_bucket | src/ml/config.py | Settings field in StorageSettings |
| dataset_id | src/ml/config.py | Settings field in BigQuerySettings |
| datasets_prefix | src/ml/config.py | Settings field in StorageSettings |
| default_machine_type | src/ml/config.py | Settings field in TrainingSettings |
| dev_endpoint_name | src/ml/config.py | Settings field in ServingSettings |
| etl | src/ml/config.py | Settings field in Settings |
| gpu_count | src/ml/config.py | Settings field in TrainingSettings |
| gpu_machine_type | src/ml/config.py | Settings field in TrainingSettings |
| gpu_type | src/ml/config.py | Settings field in TrainingSettings |
| machine_type | src/ml/config.py | Settings field in ServingSettings |
| max_replicas | src/ml/config.py | Settings field in ServingSettings |
| min_replicas | src/ml/config.py | Settings field in ServingSettings |
| models_prefix | src/ml/config.py | Settings field in StorageSettings |
| outcome_log_table | src/ml/config.py | Settings field in BigQuerySettings |
| platform | src/ml/config.py | Settings field in Settings |
| prediction_log_table | src/ml/config.py | Settings field in BigQuerySettings |
| prod_endpoint_name | src/ml/config.py | Settings field in ServingSettings |
| project_id | src/ml/config.py | Settings field in PlatformSettings |
| region | src/ml/config.py | Settings field in PlatformSettings |
| serving | src/ml/config.py | Settings field in Settings |
| source_db_connection | src/ml/config.py | Settings field in EtlSettings |
| source_db_name | src/ml/config.py | Settings field in EtlSettings |
| source_db_user | src/ml/config.py | Settings field in EtlSettings |
| source_enable_iam_auth | src/ml/config.py | Settings field in EtlSettings |
| source_instance | src/ml/config.py | Settings field in EtlSettings |
| storage | src/ml/config.py | Settings field in Settings |
| training | src/ml/config.py | Settings field in Settings |
