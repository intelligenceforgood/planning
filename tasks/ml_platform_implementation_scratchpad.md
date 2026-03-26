# ML Platform — Implementation Scratchpad

> **Purpose:** Reference code for implementing the ML Platform TDD.
> Extracted from the TDD to keep design docs conceptual. Use these as starting points —
> they will need adaptation as implementation progresses.

---

## Table of Contents

1. [Terraform — GCP APIs](#1-terraform--gcp-apis)
2. [Terraform — Cloud Storage](#2-terraform--cloud-storage)
3. [Terraform — Artifact Registry](#3-terraform--artifact-registry)
4. [Python Package — pyproject.toml](#4-python-package--pyprojecttoml)
5. [Settings — settings.default.toml](#5-settings--settingsdefaulttoml)
6. [BigQuery DDL — All Tables](#6-bigquery-ddl--all-tables)
7. [ETL Pipeline — Python](#7-etl-pipeline--python)
8. [Feature Engineering — SQL View](#8-feature-engineering--sql-view)
9. [Feature Definitions — Python](#9-feature-definitions--python)
10. [Dataset Export — Python](#10-dataset-export--python)
11. [Training Container — PyTorch (Dockerfile + train.py)](#11-training-container--pytorch)
12. [Training Container — XGBoost (Dockerfile + train.py)](#12-training-container--xgboost)
13. [Training Pipeline — KFP v2](#13-training-pipeline--kfp-v2)
14. [Training Config — YAML](#14-training-config--yaml)
15. [Model Promotion — Python](#15-model-promotion--python)
16. [Serving Container — Python](#16-serving-container--python)
17. [Prediction Logging — Python](#17-prediction-logging--python)
18. [Terraform — Vertex AI Endpoints](#18-terraform--vertex-ai-endpoints)
19. [Monitoring — Model Monitoring Setup](#19-monitoring--model-monitoring-setup)
20. [Monitoring — Accuracy Query (BigQuery)](#20-monitoring--accuracy-query)
21. [Monitoring — Cost Query (BigQuery)](#21-monitoring--cost-query)
22. [Monitoring — Retraining Triggers](#22-monitoring--retraining-triggers)
23. [Consumer Integration — analyst_labels Migration](#23-consumer-integration--analyst_labels-migration)
24. [Consumer Integration — MLPlatformClient](#24-consumer-integration--mlplatformclient)
25. [Consumer Integration — Settings](#25-consumer-integration--settings)
26. [Consumer Integration — Factory Update](#26-consumer-integration--factory-update)
27. [Terraform — ML Stack (main.tf)](#27-terraform--ml-stack)
28. [Terraform — IAM Roles](#28-terraform--iam-roles)
29. [Terraform — Cross-Project Access](#29-terraform--cross-project-access)
30. [Terraform — BigQuery PII Access](#30-terraform--bigquery-pii-access)
31. [Evaluation Harness — Python](#31-evaluation-harness--python)
32. [Baseline Benchmark — Python](#32-baseline-benchmark--python)
33. [Training Config Schema — Python](#33-training-config-schema--python)

---

## 1. Terraform — GCP APIs

```hcl
resource "google_project_service" "ml_apis" {
  for_each = toset([
    "aiplatform.googleapis.com",       # Vertex AI (Training, Pipelines, Endpoints, etc.)
    "bigquery.googleapis.com",          # BigQuery
    "bigquerydatatransfer.googleapis.com",
    "storage.googleapis.com",           # Cloud Storage
    "run.googleapis.com",              # Cloud Run (ETL jobs)
    "cloudscheduler.googleapis.com",   # Cloud Scheduler (pipeline triggers)
    "artifactregistry.googleapis.com", # Container images
    "dataproc.googleapis.com",         # Dataproc Serverless (Phase 1+ Spark)
    "pubsub.googleapis.com",           # Pub/Sub (Phase 1+ event-driven data)
    "monitoring.googleapis.com",       # Cloud Monitoring
    "logging.googleapis.com",          # Cloud Logging
    "sqladmin.googleapis.com",         # Cloud SQL Admin (for proxy connections)
    "iam.googleapis.com",
    "compute.googleapis.com",          # Vertex AI requires Compute Engine
    "notebooks.googleapis.com",        # Vertex AI Workbench
  ])

  project = var.project_id
  service = each.value
}
```

---

## 2. Terraform — Cloud Storage

```hcl
resource "google_storage_bucket" "ml_data" {
  name          = "i4g-ml-data"
  project       = var.project_id
  location      = var.region
  storage_class = "STANDARD"

  versioning { enabled = true }

  lifecycle_rule {
    condition { age = 90 }
    action { type = "SetStorageClass", storage_class = "NEARLINE" }
  }

  lifecycle_rule {
    condition { age = 365 }
    action { type = "SetStorageClass", storage_class = "COLDLINE" }
  }

  uniform_bucket_level_access = true
}
```

---

## 3. Terraform — Artifact Registry

```hcl
resource "google_artifact_registry_repository" "ml_containers" {
  project       = var.project_id
  location      = var.region
  repository_id = "containers"
  format        = "DOCKER"
  description   = "Training and serving container images for ML platform"
}
```

---

## 4. Python Package — pyproject.toml

```toml
# ml/pyproject.toml
[project]
name = "ml-platform"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "google-cloud-aiplatform>=1.40",
    "google-cloud-bigquery>=3.10",
    "google-cloud-storage>=2.10",
    "kfp>=2.5",
    "fastapi>=0.110",
    "uvicorn>=0.27",
    "httpx>=0.27",
    "pydantic>=2.5",
    "pandas>=2.1",
    "numpy>=1.26",
]

[project.optional-dependencies]
train-pytorch = [
    "torch>=2.1",
    "transformers>=4.38",
    "peft>=0.8",
    "datasets>=2.18",
    "evaluate>=0.4",
    "accelerate>=0.27",
]
train-xgboost = [
    "xgboost>=2.0",
    "scikit-learn>=1.4",
]
dev = [
    "pytest>=8.0",
    "ruff>=0.3",
    "black>=24.2",
]
```

---

## 5. Settings — settings.default.toml

```toml
# ml/config/settings.default.toml
[platform]
project_id = "i4g-ml"
region = "us-central1"

[bigquery]
dataset_id = "i4g_ml"
prediction_log_table = "predictions.prediction_log"
outcome_log_table = "predictions.outcome_log"

[storage]
data_bucket = "i4g-ml-data"
datasets_prefix = "datasets"
models_prefix = "models"

[serving]
dev_endpoint_name = "serving-dev"
prod_endpoint_name = "serving-prod"
min_replicas = 0
max_replicas = 2
machine_type = "n1-standard-4"

[training]
default_machine_type = "n1-standard-4"
gpu_machine_type = "n1-standard-4"
gpu_type = "NVIDIA_TESLA_T4"
gpu_count = 1

[etl]
source_db_connection = ""  # Cloud SQL connection string, set via env
batch_size = 1000
```

---

## 6. BigQuery DDL — All Tables

### raw_cases

```sql
CREATE TABLE IF NOT EXISTS `i4g-ml.i4g_ml.raw_cases` (
  case_id         STRING NOT NULL,
  narrative       STRING,
  case_type       STRING,
  status          STRING,
  created_at      TIMESTAMP,
  updated_at      TIMESTAMP,
  tags            ARRAY<STRING>,
  -- ingestion metadata
  _ingested_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  _source_updated TIMESTAMP   -- watermark from source
)
PARTITION BY DATE(_ingested_at)
CLUSTER BY case_id;
```

### ~~raw_classification_results~~ (REMOVED)

> `classification_result` is a JSON column on the `cases` table, not a separate table.
> Classification features are extracted from `raw_cases.classification_result` in the feature view.

```
(no BigQuery table — data lives in raw_cases.classification_result)
```

### raw_entities

```sql
CREATE TABLE IF NOT EXISTS `i4g-ml.i4g_ml.raw_entities` (
  entity_id       STRING NOT NULL,
  case_id         STRING NOT NULL,
  entity_type     STRING NOT NULL,    -- CRYPTO_WALLET, PHONE, EMAIL, etc.
  entity_value    STRING,             -- redacted at feature engineering, not here
  confidence      FLOAT64,
  source          STRING,             -- llm_extraction, manual, etc.
  created_at      TIMESTAMP,
  _ingested_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(_ingested_at)
CLUSTER BY case_id, entity_type;
```

### raw_analyst_labels

```sql
CREATE TABLE IF NOT EXISTS `i4g-ml.i4g_ml.raw_analyst_labels` (
  label_id        STRING NOT NULL,
  case_id         STRING NOT NULL,
  axis            STRING NOT NULL,
  label_code      STRING NOT NULL,    -- analyst-provided correct label
  analyst_id      STRING NOT NULL,
  confidence      FLOAT64 DEFAULT 1.0,
  notes           STRING,
  created_at      TIMESTAMP,
  _ingested_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(_ingested_at)
CLUSTER BY case_id, axis;
```

### features_case_features

```sql
CREATE TABLE IF NOT EXISTS `i4g-ml.i4g_ml.features_case_features` (
  case_id                       STRING NOT NULL,
  -- text features
  text_length                   INT64,
  word_count                    INT64,
  avg_sentence_length           FLOAT64,
  lexical_diversity             FLOAT64,
  -- entity features
  entity_count                  INT64,
  unique_entity_types           INT64,
  has_crypto_wallet             BOOL,
  has_bank_account              BOOL,
  has_phone                     BOOL,
  has_email                     BOOL,
  -- indicator features
  indicator_count               INT64,
  indicator_diversity           INT64,
  max_indicator_confidence      FLOAT64,
  -- classification features
  current_classification_axis   STRING,
  current_classification_conf   FLOAT64,
  classification_axis_count     INT64,
  -- structural features
  document_count                INT64,
  evidence_file_count           INT64,
  case_age_days                 INT64,
  has_attachments               BOOL,
  -- metadata
  _computed_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  _feature_version              INT64 DEFAULT 1
)
PARTITION BY DATE(_computed_at)
CLUSTER BY case_id;
```

### predictions_prediction_log

```sql
CREATE TABLE IF NOT EXISTS `i4g-ml.i4g_ml.predictions_prediction_log` (
  prediction_id   STRING NOT NULL,
  case_id         STRING NOT NULL,
  model_id        STRING NOT NULL,
  model_version   INT64 NOT NULL,
  endpoint        STRING NOT NULL,    -- serving-dev, serving-prod
  capability      STRING NOT NULL,    -- classification, ner, risk_scoring
  features_used   JSON,               -- complete feature vector
  request_payload JSON,               -- raw request (text redacted in Phase 1+)
  prediction      JSON,               -- full prediction output
  latency_ms      INT64,
  timestamp       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(timestamp)
CLUSTER BY model_id, capability;
```

### predictions_outcome_log

```sql
CREATE TABLE IF NOT EXISTS `i4g-ml.i4g_ml.predictions_outcome_log` (
  outcome_id      STRING NOT NULL,
  prediction_id   STRING NOT NULL,    -- FK to prediction_log
  case_id         STRING NOT NULL,
  correction      JSON,               -- analyst-provided correct labels
  analyst_id      STRING NOT NULL,
  timestamp       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(timestamp)
CLUSTER BY prediction_id;
```

### training_dataset_registry

```sql
CREATE TABLE IF NOT EXISTS `i4g-ml.i4g_ml.training_dataset_registry` (
  dataset_id      STRING NOT NULL,    -- e.g., classification_v3
  version         INT64 NOT NULL,
  capability      STRING NOT NULL,
  gcs_path        STRING NOT NULL,    -- gs://i4g-ml-data/datasets/...
  train_count     INT64,
  eval_count      INT64,
  test_count      INT64,
  label_distribution JSON,            -- {"INTENT.ROMANCE": 45, ...}
  config          JSON,               -- dataset creation config
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  created_by      STRING
);
```

---

## 7. ETL Pipeline — Python

```python
# ml/src/ml_platform/data/etl.py

from dataclasses import dataclass
from google.cloud import bigquery
import sqlalchemy as sa

@dataclass
class IngestConfig:
    source_connection: str
    bq_project: str
    bq_dataset: str
    batch_size: int = 1000

TABLE_CONFIGS = [
    {
        "source_table": "cases",
        "target_table": "raw_cases",
        "watermark_column": "updated_at",
        "columns": ["case_id", "narrative", "case_type", "status",
                     "classification_result", "created_at", "updated_at"],
    },
    {
        "source_table": "entities",
        "target_table": "raw_entities",
        "watermark_column": "created_at",
        "columns": ["id", "case_id", "entity_type", "entity_value",
                     "confidence", "source", "created_at"],
    },
    {
        "source_table": "analyst_labels",
        "target_table": "raw_analyst_labels",
        "watermark_column": "created_at",
        "columns": ["id", "case_id", "axis", "label_code", "analyst_id",
                     "confidence", "notes", "created_at"],
    },
]

def run_incremental_ingest(config: IngestConfig) -> dict[str, int]:
    """Run incremental ETL for all configured tables.

    Returns dict of table_name -> rows_ingested.
    """
    bq_client = bigquery.Client(project=config.bq_project)
    engine = sa.create_engine(config.source_connection)
    results = {}

    for table_config in TABLE_CONFIGS:
        watermark = _get_watermark(bq_client, config.bq_dataset, table_config)
        rows = _extract_since(engine, table_config, watermark, config.batch_size)
        count = _load_to_bigquery(bq_client, config.bq_dataset, table_config, rows)
        results[table_config["target_table"]] = count

    return results
```

---

## 8. Feature Engineering — SQL View

```sql
CREATE OR REPLACE VIEW `i4g-ml.i4g_ml.v_case_features` AS
WITH case_text AS (
  SELECT
    case_id,
    narrative,
    LENGTH(narrative) AS text_length,
    ARRAY_LENGTH(SPLIT(narrative, ' ')) AS word_count,
    SAFE_DIVIDE(
      ARRAY_LENGTH(ARRAY(SELECT DISTINCT w FROM UNNEST(SPLIT(LOWER(narrative), ' ')) w)),
      ARRAY_LENGTH(SPLIT(narrative, ' '))
    ) AS lexical_diversity
  FROM `i4g-ml.i4g_ml.raw_cases`
  WHERE narrative IS NOT NULL
),
case_entities AS (
  SELECT
    case_id,
    COUNT(*) AS entity_count,
    COUNT(DISTINCT entity_type) AS unique_entity_types,
    LOGICAL_OR(entity_type = 'CRYPTO_WALLET') AS has_crypto_wallet,
    LOGICAL_OR(entity_type = 'BANK_ACCOUNT') AS has_bank_account,
    LOGICAL_OR(entity_type = 'PHONE') AS has_phone,
    LOGICAL_OR(entity_type = 'EMAIL') AS has_email
  FROM `i4g-ml.i4g_ml.raw_entities`
  GROUP BY case_id
),
-- Classification features extracted from raw_cases.classification_result JSON
case_classifications AS (
  SELECT
    case_id,
    (SELECT COUNT(DISTINCT axis) FROM UNNEST(['intent','channel','techniques','actions','persona']) AS axis
     WHERE JSON_EXTRACT(classification_result, CONCAT('$.', axis)) IS NOT NULL
       AND ARRAY_LENGTH(JSON_EXTRACT_ARRAY(classification_result, CONCAT('$.', axis))) > 0
    ) AS classification_axis_count,
    CAST(JSON_EXTRACT_SCALAR(classification_result, '$.risk_score') AS FLOAT64) / 100.0 AS current_classification_conf
  FROM `i4g-ml.i4g_ml.raw_cases`
  WHERE classification_result IS NOT NULL
)
SELECT
  t.case_id,
  t.text_length,
  t.word_count,
  t.lexical_diversity,
  COALESCE(e.entity_count, 0) AS entity_count,
  COALESCE(e.unique_entity_types, 0) AS unique_entity_types,
  COALESCE(e.has_crypto_wallet, FALSE) AS has_crypto_wallet,
  COALESCE(e.has_bank_account, FALSE) AS has_bank_account,
  COALESCE(e.has_phone, FALSE) AS has_phone,
  COALESCE(e.has_email, FALSE) AS has_email,
  COALESCE(c.classification_axis_count, 0) AS classification_axis_count,
  c.latest.axis AS current_classification_axis,
  c.latest.confidence AS current_classification_conf,
  CURRENT_TIMESTAMP() AS _computed_at,
  1 AS _feature_version
FROM case_text t
LEFT JOIN case_entities e USING (case_id)
LEFT JOIN case_classifications c USING (case_id);
```

---

## 9. Feature Definitions — Python

```python
# ml/src/ml_platform/data/features.py

from dataclasses import dataclass
from enum import Enum

class FeatureType(Enum):
    NUMERIC = "numeric"
    CATEGORICAL = "categorical"
    BOOLEAN = "boolean"
    TEXT = "text"
    EMBEDDING = "embedding"

class ComputeMethod(Enum):
    BIGQUERY_SQL = "bigquery_sql"
    SPARK = "spark"
    PYTHON = "python"

@dataclass(frozen=True)
class FeatureDefinition:
    name: str
    feature_type: FeatureType
    description: str
    compute_method: ComputeMethod
    version: int = 1

FEATURE_CATALOG: list[FeatureDefinition] = [
    FeatureDefinition("text_length", FeatureType.NUMERIC,
                      "Character count of case narrative", ComputeMethod.BIGQUERY_SQL),
    FeatureDefinition("word_count", FeatureType.NUMERIC,
                      "Word count of case narrative", ComputeMethod.BIGQUERY_SQL),
    FeatureDefinition("lexical_diversity", FeatureType.NUMERIC,
                      "Unique words / total words ratio", ComputeMethod.BIGQUERY_SQL),
    FeatureDefinition("entity_count", FeatureType.NUMERIC,
                      "Total entities extracted from case", ComputeMethod.BIGQUERY_SQL),
    FeatureDefinition("unique_entity_types", FeatureType.NUMERIC,
                      "Distinct entity types in case", ComputeMethod.BIGQUERY_SQL),
    FeatureDefinition("has_crypto_wallet", FeatureType.BOOLEAN,
                      "Case contains a crypto wallet entity", ComputeMethod.BIGQUERY_SQL),
    FeatureDefinition("has_bank_account", FeatureType.BOOLEAN,
                      "Case contains a bank account entity", ComputeMethod.BIGQUERY_SQL),
    FeatureDefinition("has_phone", FeatureType.BOOLEAN,
                      "Case contains a phone entity", ComputeMethod.BIGQUERY_SQL),
    FeatureDefinition("has_email", FeatureType.BOOLEAN,
                      "Case contains an email entity", ComputeMethod.BIGQUERY_SQL),
    FeatureDefinition("classification_axis_count", FeatureType.NUMERIC,
                      "Number of taxonomy axes with classifications", ComputeMethod.BIGQUERY_SQL),
    FeatureDefinition("current_classification_conf", FeatureType.NUMERIC,
                      "Confidence of latest classification", ComputeMethod.BIGQUERY_SQL),
]
```

---

## 10. Dataset Export — Python

```python
# ml/src/ml_platform/data/datasets.py

from dataclasses import dataclass

@dataclass
class DatasetConfig:
    capability: str            # "classification"
    train_ratio: float = 0.70
    eval_ratio: float = 0.15
    test_ratio: float = 0.15
    min_samples: int = 50
    stratify_column: str = "label"

def create_dataset_version(config: DatasetConfig) -> str:
    """Create a new versioned dataset from BigQuery features + labels.

    Steps:
    1. Query BigQuery: join features + analyst_labels (or bootstrap labels).
    2. Validate: check min_samples, class balance, nulls.
    3. Stratified split into train/eval/test.
    4. Export each split as JSONL to GCS.
    5. Register version in training_dataset_registry.
    6. Return dataset version ID.
    """
    ...
```

---

## 11. Training Container — PyTorch

### Dockerfile

```dockerfile
# ml/containers/train-pytorch/Dockerfile
FROM us-docker.pkg.dev/vertex-ai/training/pytorch-gpu.2-2:latest

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY train.py .

ENTRYPOINT ["python", "train.py"]
```

### train.py

```python
# ml/containers/train-pytorch/train.py (simplified)

import argparse
import json
from pathlib import Path

from google.cloud import aiplatform, bigquery, storage
from peft import LoraConfig, get_peft_model, TaskType
from transformers import (
    AutoModelForSequenceClassification,
    AutoTokenizer,
    Trainer,
    TrainingArguments,
)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config-path", required=True,
                        help="GCS path to training config YAML")
    parser.add_argument("--dataset-version", required=True)
    parser.add_argument("--experiment-name", required=True)
    parser.add_argument("--run-name", required=True)
    args = parser.parse_args()

    config = load_config(args.config_path)
    train_ds, eval_ds = load_datasets(args.dataset_version)

    # Load base model + apply LoRA
    tokenizer = AutoTokenizer.from_pretrained(config["base_model"])
    model = AutoModelForSequenceClassification.from_pretrained(
        config["base_model"],
        num_labels=config["num_labels"],
    )
    lora_config = LoraConfig(
        task_type=TaskType.SEQ_CLS,
        r=config.get("lora_r", 16),
        lora_alpha=config.get("lora_alpha", 32),
        lora_dropout=config.get("lora_dropout", 0.1),
        target_modules=config.get("target_modules", ["q_proj", "v_proj"]),
    )
    model = get_peft_model(model, lora_config)

    training_args = TrainingArguments(
        output_dir="/tmp/checkpoints",
        num_train_epochs=config.get("epochs", 3),
        per_device_train_batch_size=config.get("batch_size", 8),
        learning_rate=config.get("learning_rate", 2e-4),
        evaluation_strategy="epoch",
        save_strategy="epoch",
        load_best_model_at_end=True,
        metric_for_best_model="eval_f1",
        report_to="none",  # metrics logged to Vertex AI Experiments
    )

    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_ds,
        eval_dataset=eval_ds,
        tokenizer=tokenizer,
        compute_metrics=compute_classification_metrics,
    )
    trainer.train()

    # Log metrics to Vertex AI Experiments
    aiplatform.init(experiment=args.experiment_name)
    with aiplatform.start_run(args.run_name):
        metrics = trainer.evaluate()
        aiplatform.log_metrics(metrics)
        aiplatform.log_params(config)

    # Save model artifacts to GCS
    output_dir = (
        f"gs://{config['data_bucket']}/models/"
        f"{config['model_id']}/v{config['version']}/"
    )
    trainer.save_model("/tmp/final_model")
    upload_to_gcs("/tmp/final_model", output_dir)
```

---

## 12. Training Container — XGBoost

### Dockerfile

```dockerfile
# ml/containers/train-xgboost/Dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY train.py .

ENTRYPOINT ["python", "train.py"]
```

### train.py

```python
# ml/containers/train-xgboost/train.py (simplified)

import xgboost as xgb
from sklearn.metrics import classification_report
from google.cloud import aiplatform

def main():
    # Load tabular features + labels from BigQuery
    train_df, eval_df = load_from_bigquery(dataset_version)

    feature_cols = [c for c in train_df.columns if c not in ("case_id", "label")]
    dtrain = xgb.DMatrix(train_df[feature_cols], label=train_df["label"])
    deval = xgb.DMatrix(eval_df[feature_cols], label=eval_df["label"])

    params = {
        "objective": "multi:softprob",
        "num_class": num_labels,
        "max_depth": config.get("max_depth", 6),
        "learning_rate": config.get("learning_rate", 0.1),
        "eval_metric": "mlogloss",
    }

    model = xgb.train(
        params, dtrain, num_boost_round=config.get("rounds", 100),
        evals=[(deval, "eval")], early_stopping_rounds=10,
    )

    # Evaluate and log
    preds = model.predict(deval)
    report = classification_report(
        eval_df["label"], preds.argmax(axis=1), output_dict=True,
    )

    aiplatform.init(experiment=experiment_name)
    with aiplatform.start_run(run_name):
        aiplatform.log_metrics({
            "overall_f1": report["weighted avg"]["f1-score"],
        })

    # Save model
    model.save_model("/tmp/model.json")
    upload_to_gcs("/tmp/model.json", artifact_uri)
```

---

## 13. Training Pipeline — KFP v2

```python
# ml/pipelines/training_pipeline.py

from kfp import dsl
from kfp.dsl import Output, Artifact, Metrics

@dsl.component(
    base_image="python:3.11-slim",
    packages_to_install=["google-cloud-bigquery"],
)
def prepare_dataset(
    capability: str,
    version: int,
    bq_project: str,
    bq_dataset: str,
    gcs_bucket: str,
    dataset_info: Output[Artifact],
):
    """Export training dataset from BigQuery to GCS."""
    ...

@dsl.component(
    base_image="python:3.11-slim",
    packages_to_install=["google-cloud-aiplatform"],
)
def train_model(
    config_path: str,
    dataset_version: int,
    experiment_name: str,
    container_uri: str,
    model_artifact: Output[Artifact],
    training_metrics: Output[Metrics],
):
    """Submit Vertex AI Training job with custom container."""
    from google.cloud import aiplatform

    job = aiplatform.CustomContainerTrainingJob(
        display_name=f"train-{experiment_name}",
        container_uri=container_uri,
        model_serving_container_image_uri=None,
    )
    model = job.run(
        args=[
            "--config-path", config_path,
            "--dataset-version", str(dataset_version),
            "--experiment-name", experiment_name,
            "--run-name", f"run-v{dataset_version}",
        ],
        replica_count=1,
        machine_type="n1-standard-4",
        accelerator_type="NVIDIA_TESLA_T4",
        accelerator_count=1,
    )
    ...

@dsl.component(
    base_image="python:3.11-slim",
    packages_to_install=["google-cloud-bigquery"],
)
def evaluate_model(
    model_artifact_uri: str,
    golden_test_path: str,
    eval_results: Output[Metrics],
) -> bool:
    """Run model against golden test set. Returns True if eval gate passes."""
    ...

@dsl.component(
    base_image="python:3.11-slim",
    packages_to_install=["google-cloud-aiplatform"],
)
def register_model(
    model_artifact_uri: str,
    model_id: str,
    eval_metrics: dict,
    framework: str,
):
    """Register model in Vertex AI Model Registry if eval gate passed."""
    from google.cloud import aiplatform

    model = aiplatform.Model.upload(
        display_name=model_id,
        artifact_uri=model_artifact_uri,
        serving_container_image_uri=(
            f"{region}-docker.pkg.dev/{project}/containers/serve:latest"
        ),
        labels={"stage": "experimental", "capability": "classification"},
    )
    ...

@dsl.component(
    base_image="python:3.11-slim",
    packages_to_install=["google-cloud-aiplatform"],
)
def deploy_model(
    model_resource_name: str,
    endpoint_name: str,
    min_replicas: int,
    max_replicas: int,
):
    """Deploy model to Vertex AI Endpoint."""
    from google.cloud import aiplatform

    endpoint = aiplatform.Endpoint.list(
        filter=f'display_name="{endpoint_name}"'
    )[0]
    model = aiplatform.Model(model_resource_name)
    endpoint.deploy(
        model=model,
        traffic_percentage=100,
        min_replica_count=min_replicas,
        max_replica_count=max_replicas,
        machine_type="n1-standard-4",
    )

@dsl.pipeline(name="ml-training-pipeline")
def training_pipeline(
    capability: str,
    dataset_version: int,
    config_path: str,
    container_uri: str,
    experiment_name: str,
    endpoint_name: str = "serving-dev",
    bq_project: str = "i4g-ml",
    bq_dataset: str = "i4g_ml",
    gcs_bucket: str = "i4g-ml-data",
    min_replicas: int = 0,
    max_replicas: int = 1,
):
    prepare_task = prepare_dataset(
        capability=capability,
        version=dataset_version,
        bq_project=bq_project,
        bq_dataset=bq_dataset,
        gcs_bucket=gcs_bucket,
    )

    train_task = train_model(
        config_path=config_path,
        dataset_version=dataset_version,
        experiment_name=experiment_name,
        container_uri=container_uri,
    ).after(prepare_task)

    eval_task = evaluate_model(
        model_artifact_uri=train_task.outputs["model_artifact"],
        golden_test_path=(
            f"gs://{gcs_bucket}/datasets/{capability}/golden/test.jsonl"
        ),
    ).after(train_task)

    with dsl.Condition(eval_task.output == True):
        register_task = register_model(
            model_artifact_uri=train_task.outputs["model_artifact"],
            model_id=f"{capability}_model",
            eval_metrics=eval_task.outputs["eval_results"],
            framework="pytorch",
        )
        deploy_model(
            model_resource_name=register_task.output,
            endpoint_name=endpoint_name,
            min_replicas=min_replicas,
            max_replicas=max_replicas,
        ).after(register_task)
```

---

## 14. Training Config — YAML

```yaml
# ml/pipelines/configs/classification_gemma2b.yaml
model_id: fraud_classifier_gemma2b
capability: classification
base_model: google/gemma-2b
framework: pytorch
training_type: lora

# LoRA config
lora_r: 16
lora_alpha: 32
lora_dropout: 0.1
target_modules: ["q_proj", "v_proj"]

# Training hyperparameters
epochs: 3
batch_size: 8
learning_rate: 2e-4
warmup_ratio: 0.1

# Labels
label_schema:
  INTENT:
    - INTENT.ROMANCE
    - INTENT.INVESTMENT
    - INTENT.IMPERSONATION
    - INTENT.EXTORTION
    - INTENT.COMMERCE
    - INTENT.OTHER
  CHANNEL:
    - CHANNEL.SOCIAL_MEDIA
    - CHANNEL.EMAIL
    - CHANNEL.PHONE
    - CHANNEL.MESSAGING
    - CHANNEL.WEBSITE
    - CHANNEL.OTHER

# Eval gate
eval_gate:
  min_overall_f1: 0.0 # Phase 0: any model passes
  max_per_axis_regression: 0.05

# Resources
data_bucket: i4g-ml-data
machine_type: n1-standard-4
gpu_type: NVIDIA_TESLA_T4
gpu_count: 1
```

---

## 15. Model Promotion — Python

```python
# ml/src/ml_platform/registry/promotion.py

from enum import Enum
from google.cloud import aiplatform

class ModelStage(Enum):
    EXPERIMENTAL = "experimental"
    CANDIDATE = "candidate"
    CHAMPION = "champion"
    RETIRED = "retired"

def promote_model(
    model_resource_name: str,
    target_stage: ModelStage,
    eval_metrics: dict | None = None,
    champion_metrics: dict | None = None,
) -> bool:
    """Promote a model to the next stage.

    Rules:
    - experimental → candidate: eval gate must pass
    - candidate → champion: eval gate + manual approval
    - champion → retired: only when a new champion is promoted
    """
    model = aiplatform.Model(model_resource_name)

    if target_stage == ModelStage.CANDIDATE:
        if not _passes_eval_gate(eval_metrics, champion_metrics):
            return False
        model.update(labels={"stage": "candidate"})
        return True

    if target_stage == ModelStage.CHAMPION:
        current_champions = aiplatform.Model.list(
            filter='labels.stage="champion"',
        )
        for champ in current_champions:
            champ.update(labels={"stage": "retired"})
        model.update(labels={"stage": "champion"})
        return True

    return False


def _passes_eval_gate(
    candidate_metrics: dict,
    champion_metrics: dict | None,
    max_regression: float = 0.05,
) -> bool:
    """Check if candidate passes eval gate against current champion."""
    if champion_metrics is None:
        return True  # No champion — first model always passes

    candidate_f1 = candidate_metrics.get("overall_f1", 0.0)
    champion_f1 = champion_metrics.get("overall_f1", 0.0)

    if candidate_f1 < champion_f1:
        return False

    for axis in candidate_metrics.get("per_axis", {}):
        candidate_axis_f1 = candidate_metrics["per_axis"][axis].get("f1", 0.0)
        champion_axis_f1 = (
            champion_metrics.get("per_axis", {}).get(axis, {}).get("f1", 0.0)
        )
        if champion_axis_f1 - candidate_axis_f1 > max_regression:
            return False

    return True
```

---

## 16. Serving Container — Python

```python
# ml/containers/serve/serve.py

import os
import uuid
from contextlib import asynccontextmanager

import google.cloud.bigquery as bigquery
from fastapi import FastAPI
from pydantic import BaseModel

# --- Request/Response models ---

class ClassifyRequest(BaseModel):
    text: str
    case_id: str
    features: dict | None = None

class LabelPrediction(BaseModel):
    code: str
    confidence: float

class ClassifyResponse(BaseModel):
    prediction: dict[str, LabelPrediction]
    risk_score: float | None = None
    model_info: dict
    prediction_id: str

class FeedbackRequest(BaseModel):
    prediction_id: str
    case_id: str
    correction: dict
    analyst_id: str

# --- App ---

model = None
bq_client = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global model, bq_client
    model = load_model(os.environ["MODEL_ARTIFACT_URI"])
    bq_client = bigquery.Client()
    yield

app = FastAPI(title="I4G ML Platform — Serving", lifespan=lifespan)

@app.post("/predict/classify", response_model=ClassifyResponse)
async def classify(request: ClassifyRequest):
    prediction_id = str(uuid.uuid4())

    # Compute features inline (Phase 0) or fetch pre-computed (Phase 1+)
    features = request.features or compute_features(request.text)

    # Run inference
    result = model.predict(request.text, features)

    # Log prediction asynchronously
    log_prediction(
        bq_client=bq_client,
        prediction_id=prediction_id,
        case_id=request.case_id,
        model_id=os.environ["MODEL_ID"],
        model_version=int(os.environ["MODEL_VERSION"]),
        endpoint=os.environ.get("ENDPOINT_NAME", "unknown"),
        capability="classification",
        features_used=features,
        prediction=result,
    )

    return ClassifyResponse(
        prediction=result["labels"],
        risk_score=result.get("risk_score"),
        model_info={
            "model_id": os.environ["MODEL_ID"],
            "version": int(os.environ["MODEL_VERSION"]),
            "stage": os.environ.get("MODEL_STAGE", "experimental"),
        },
        prediction_id=prediction_id,
    )

@app.post("/feedback")
async def feedback(request: FeedbackRequest):
    log_outcome(
        bq_client=bq_client,
        prediction_id=request.prediction_id,
        case_id=request.case_id,
        correction=request.correction,
        analyst_id=request.analyst_id,
    )
    return {"status": "ok"}

@app.get("/health")
async def health():
    return {"status": "healthy", "model": os.environ.get("MODEL_ID")}
```

---

## 17. Prediction Logging — Python

```python
# ml/src/ml_platform/serving/logging.py

import json
import uuid
from datetime import datetime, timezone

from google.cloud import bigquery

PREDICTION_LOG_TABLE = "{project}.{dataset}.predictions_prediction_log"
OUTCOME_LOG_TABLE = "{project}.{dataset}.predictions_outcome_log"

def log_prediction(
    bq_client: bigquery.Client,
    prediction_id: str,
    case_id: str,
    model_id: str,
    model_version: int,
    endpoint: str,
    capability: str,
    features_used: dict,
    prediction: dict,
    latency_ms: int | None = None,
) -> None:
    table_id = PREDICTION_LOG_TABLE.format(project="i4g-ml", dataset="i4g_ml")
    rows = [{
        "prediction_id": prediction_id,
        "case_id": case_id,
        "model_id": model_id,
        "model_version": model_version,
        "endpoint": endpoint,
        "capability": capability,
        "features_used": json.dumps(features_used),
        "prediction": json.dumps(prediction),
        "latency_ms": latency_ms,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }]
    errors = bq_client.insert_rows_json(table_id, rows)
    if errors:
        import logging
        logging.warning("Failed to log prediction: %s", errors)

def log_outcome(
    bq_client: bigquery.Client,
    prediction_id: str,
    case_id: str,
    correction: dict,
    analyst_id: str,
) -> None:
    table_id = OUTCOME_LOG_TABLE.format(project="i4g-ml", dataset="i4g_ml")
    rows = [{
        "outcome_id": str(uuid.uuid4()),
        "prediction_id": prediction_id,
        "case_id": case_id,
        "correction": json.dumps(correction),
        "analyst_id": analyst_id,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }]
    errors = bq_client.insert_rows_json(table_id, rows)
    if errors:
        import logging
        logging.warning("Failed to log outcome: %s", errors)
```

---

## 18. Terraform — Vertex AI Endpoints

```hcl
resource "google_vertex_ai_endpoint" "serving_dev" {
  display_name = "serving-dev"
  project      = var.project_id
  location     = var.region
  description  = "I4G ML Platform — dev serving endpoint"

  labels = {
    env        = "dev"
    component  = "serving"
    managed-by = "terraform"
  }
}

resource "google_vertex_ai_endpoint" "serving_prod" {
  display_name = "serving-prod"
  project      = var.project_id
  location     = var.region
  description  = "I4G ML Platform — prod serving endpoint"

  labels = {
    env        = "prod"
    component  = "serving"
    managed-by = "terraform"
  }
}
```

---

## 19. Monitoring — Model Monitoring Setup

```python
from google.cloud import aiplatform

endpoint = aiplatform.Endpoint("serving-prod")
endpoint.create_monitoring_job(
    objective_configs={
        "training_dataset": aiplatform.ModelMonitoringObjectiveConfig.TrainingDataset(
            bigquery_source="bq://i4g-ml.i4g_ml.features_case_features",
        ),
        "training_prediction_skew_detection_config": {
            "skew_thresholds": {
                "text_length": {"value": 0.3},
                "entity_count": {"value": 0.3},
            },
        },
        "prediction_drift_detection_config": {
            "drift_thresholds": {
                "prediction": {"value": 0.3},
            },
        },
    },
    alert_config={
        "email_alert_config": {
            "user_emails": ["alerts@intelligenceforgood.org"],
        },
    },
    schedule="0 */6 * * *",  # every 6 hours
)
```

---

## 20. Monitoring — Accuracy Query

```sql
CREATE OR REPLACE TABLE `i4g-ml.i4g_ml.analytics_model_performance` AS
WITH predictions_with_outcomes AS (
  SELECT
    p.model_id,
    p.model_version,
    p.capability,
    DATE(p.timestamp) AS computed_at,
    JSON_VALUE(p.prediction, '$.INTENT.code') AS predicted_intent,
    JSON_VALUE(o.correction, '$.INTENT.code') AS actual_intent,
    o.prediction_id IS NOT NULL AS has_outcome,
    CASE
      WHEN o.prediction_id IS NULL THEN NULL
      WHEN JSON_VALUE(p.prediction, '$.INTENT.code')
           = JSON_VALUE(o.correction, '$.INTENT.code') THEN TRUE
      ELSE FALSE
    END AS is_correct
  FROM `i4g-ml.i4g_ml.predictions_prediction_log` p
  LEFT JOIN `i4g-ml.i4g_ml.predictions_outcome_log` o USING (prediction_id)
)
SELECT
  model_id,
  model_version,
  capability,
  computed_at,
  COUNT(*) AS total_predictions,
  COUNTIF(has_outcome) AS outcomes_received,
  COUNTIF(is_correct) AS correct_predictions,
  SAFE_DIVIDE(COUNTIF(is_correct), COUNTIF(has_outcome)) AS accuracy,
  SAFE_DIVIDE(
    COUNTIF(has_outcome AND NOT is_correct),
    COUNTIF(has_outcome)
  ) AS correction_rate
FROM predictions_with_outcomes
GROUP BY 1, 2, 3, 4;
```

---

## 21. Monitoring — Cost Query

```sql
-- Per-capability monthly cost (from GCP billing export)
SELECT
  labels.value AS capability,
  SUM(cost) AS total_cost,
  SUM(cost) / NULLIF(SUM(usage.amount), 0) AS cost_per_unit
FROM `i4g-ml.billing_export.gcp_billing_export_v1_*`
WHERE service.description IN ('Vertex AI', 'Cloud Run', 'BigQuery')
  AND labels.key = 'capability'
GROUP BY 1;
```

---

## 22. Monitoring — Retraining Triggers

```python
# ml/src/ml_platform/monitoring/triggers.py

def check_retraining_triggers(capability: str) -> bool:
    """Check if retraining should be triggered for a capability.

    Returns True if any trigger fires:
    1. New labeled data exceeds threshold (200+ new labels since last training)
    2. Model monitoring alert for drift/skew
    3. Time since last training exceeds max interval (30 days default)
    """
    ...
```

---

## 23. Consumer Integration — analyst_labels Migration

```python
# core/src/i4g/db/migrations/versions/xxx_add_analyst_labels.py

def upgrade():
    op.create_table(
        "analyst_labels",
        sa.Column("id", sa.String, primary_key=True),
        sa.Column("case_id", sa.String, sa.ForeignKey("cases.id"),
                  nullable=False, index=True),
        sa.Column("axis", sa.String, nullable=False),
        sa.Column("label_code", sa.String, nullable=False),
        sa.Column("analyst_id", sa.String, nullable=False),
        sa.Column("confidence", sa.Float, server_default="1.0"),
        sa.Column("notes", sa.Text, nullable=True),
        sa.Column("created_at", sa.DateTime, server_default=sa.func.now()),
    )
    op.create_index(
        "ix_analyst_labels_case_axis",
        "analyst_labels",
        ["case_id", "axis"],
    )
```

---

## 24. Consumer Integration — MLPlatformClient

```python
# core/src/i4g/ml/client.py

import httpx
from i4g.settings import get_settings

class MLPlatformClient:
    """HTTP client for ML Platform prediction endpoints."""

    def __init__(self):
        settings = get_settings()
        self._base_url = settings.ml.platform_base_url
        self._timeout = 30.0

    async def classify(self, text: str, case_id: str) -> dict:
        async with httpx.AsyncClient(timeout=self._timeout) as client:
            resp = await client.post(
                f"{self._base_url}/predict/classify",
                json={"text": text, "case_id": case_id},
            )
            resp.raise_for_status()
            return resp.json()

    async def send_feedback(
        self,
        prediction_id: str,
        case_id: str,
        correction: dict,
        analyst_id: str,
    ) -> None:
        async with httpx.AsyncClient(timeout=self._timeout) as client:
            await client.post(
                f"{self._base_url}/feedback",
                json={
                    "prediction_id": prediction_id,
                    "case_id": case_id,
                    "correction": correction,
                    "analyst_id": analyst_id,
                },
            )
```

---

## 25. Consumer Integration — Settings

```toml
# core/config/settings.default.toml — add:
[ml]
inference_backend = "llm"   # "llm" | "ml_platform"
platform_base_url = ""
platform_auth_method = "iam"
fallback_to_llm = true
```

---

## 26. Consumer Integration — Factory Update

```python
# core/src/i4g/services/factories.py — add:

def build_inference_client():
    """Return the configured inference backend.

    Returns MLPlatformClient if inference_backend == "ml_platform",
    otherwise returns the existing LLM-based classifier.
    """
    settings = get_settings()
    if settings.ml.inference_backend == "ml_platform":
        from i4g.ml.client import MLPlatformClient
        return MLPlatformClient()
    from i4g.llm.client import build_llm_client
    return build_llm_client()
```

---

## 27. Terraform — ML Stack

```hcl
# infra/stacks/ml/main.tf — ML Platform infrastructure stack

# ----- Storage -----

module "ml_data_bucket" {
  source = "../../modules/storage/buckets"

  project_id   = var.project_id
  bucket_name  = "i4g-ml-data"
  location     = var.region
  versioning   = true
}

# ----- BigQuery -----

module "ml_bigquery" {
  source = "../../modules/bigquery/dataset"

  project_id = var.project_id
  dataset_id = "i4g_ml"
  location   = var.region
}

# ----- Artifact Registry -----

resource "google_artifact_registry_repository" "ml_containers" {
  project       = var.project_id
  location      = var.region
  repository_id = "containers"
  format        = "DOCKER"
}

# ----- Vertex AI Endpoints (Serving — isolated from training) -----

module "serving_dev" {
  source = "../../modules/vertex_ai/endpoint"

  project_id   = var.project_id
  region       = var.region
  display_name = "serving-dev"
  labels       = { env = "dev", component = "serving" }
}

module "serving_prod" {
  source = "../../modules/vertex_ai/endpoint"

  project_id   = var.project_id
  region       = var.region
  display_name = "serving-prod"
  labels       = { env = "prod", component = "serving" }
}

# ----- Cloud Run Job (ETL — data ingestion) -----

resource "google_cloud_run_v2_job" "ml_etl_ingest" {
  name     = "etl-ingest"
  project  = var.project_id
  location = var.region

  template {
    template {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/containers/etl:latest"
        env {
          name  = "I4G_ML_ETL__SOURCE_INSTANCE"
          value = var.source_cloudsql_instance
        }
        env {
          name  = "I4G_ML_ETL__SOURCE_DB_NAME"
          value = var.source_db_name
        }
        env {
          name  = "I4G_ML_ETL__SOURCE_DB_USER"
          value = "sa-ml-platform@${var.project_id}.iam"
        }
        resources {
          limits = {
            cpu    = "2"
            memory = "2Gi"
          }
        }
      }
      timeout     = "3600s"
      max_retries = 1
    }
  }
}

# ----- Cloud Scheduler (ETL trigger) -----

resource "google_cloud_scheduler_job" "ml_etl_daily" {
  name      = "etl-daily"
  project   = var.project_id
  region    = var.region
  schedule  = "0 2 * * *"   # Daily at 2 AM UTC
  time_zone = "UTC"

  http_target {
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/etl-ingest:run"
    http_method = "POST"
    oauth_token {
      service_account_email = google_service_account.sa_ml.email
    }
  }
}

# ----- IAM -----

resource "google_service_account" "sa_ml" {
  project      = var.project_id
  account_id   = "sa-ml-platform"
  display_name = "ML Platform Service Account"
}
```

---

## 28. Terraform — IAM Roles

```hcl
locals {
  sa_ml_roles = [
    "roles/aiplatform.user",                # Vertex AI (Training, Pipelines, Endpoints)
    "roles/bigquery.dataEditor",             # BigQuery read/write
    "roles/bigquery.jobUser",                # BigQuery query execution
    "roles/storage.objectAdmin",             # GCS read/write
    "roles/run.invoker",                     # Cloud Run (ETL jobs)
    "roles/artifactregistry.reader",         # Pull container images
    "roles/logging.logWriter",               # Cloud Logging
    "roles/monitoring.metricWriter",         # Cloud Monitoring
  ]
}

resource "google_project_iam_member" "sa_ml_roles" {
  for_each = toset(local.sa_ml_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.sa_ml.email}"
}
```

---

## 29. Terraform — Cross-Project Access

```hcl
# In infra/environments/app/dev/ (the i4g-dev project)
resource "google_project_iam_member" "ml_cloudsql_client" {
  project = "i4g-dev"
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:sa-ml-platform@i4g-ml.iam.gserviceaccount.com"
}

# In infra/stacks/ml/main.tf
resource "google_project_iam_member" "core_dev_vertex_user" {
  project = var.project_id  # i4g-ml
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:sa-core@i4g-dev.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "core_prod_vertex_user" {
  project = var.project_id  # i4g-ml
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:sa-core@i4g-prod.iam.gserviceaccount.com"
}
```

---

## 30. Terraform — BigQuery PII Access

```hcl
resource "google_bigquery_table_iam_member" "pii_access" {
  project    = var.project_id
  dataset_id = "i4g_ml"
  table_id   = "raw_cases"
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.sa_ml.email}"
}
```

---

## 31. Evaluation Harness — Python

```python
# ml/src/ml_platform/training/evaluation.py

from dataclasses import dataclass
from sklearn.metrics import classification_report, f1_score

@dataclass
class EvalResult:
    overall_f1: float
    per_axis: dict[str, dict[str, float]]  # axis -> {precision, recall, f1}
    classification_report: str
    sample_count: int

def evaluate_model(
    model,
    golden_test_data: list[dict],
    label_schema: dict[str, list[str]],
) -> EvalResult:
    """Evaluate a model against the golden test set.

    Args:
        model: Any model with a .predict(text, features) method
        golden_test_data: List of dicts with 'text', 'features', 'labels'
        label_schema: Dict mapping axis -> list of possible labels

    Returns:
        EvalResult with per-axis and overall metrics
    """
    per_axis_metrics = {}

    for axis, labels in label_schema.items():
        y_true = [item["labels"].get(axis, "UNKNOWN")
                  for item in golden_test_data]
        y_pred = [
            model.predict(item["text"], item.get("features", {}))
            .get(axis, {})
            .get("code", "UNKNOWN")
            for item in golden_test_data
        ]

        report = classification_report(
            y_true, y_pred, output_dict=True, zero_division=0,
        )
        per_axis_metrics[axis] = {
            "precision": report["weighted avg"]["precision"],
            "recall": report["weighted avg"]["recall"],
            "f1": report["weighted avg"]["f1-score"],
        }

    overall_f1 = (
        sum(m["f1"] for m in per_axis_metrics.values())
        / len(per_axis_metrics)
    )

    return EvalResult(
        overall_f1=overall_f1,
        per_axis=per_axis_metrics,
        classification_report=classification_report(
            [item["labels"] for item in golden_test_data],
            [model.predict(item["text"], item.get("features", {}))
             for item in golden_test_data],
        ),
        sample_count=len(golden_test_data),
    )
```

---

## 32. Baseline Benchmark — Python

```python
# ml/src/ml_platform/training/baseline.py

async def measure_few_shot_baseline(
    golden_test_data: list[dict],
    llm_classifier,  # existing FraudClassifier from I4G core
    label_schema: dict[str, list[str]],
) -> EvalResult:
    """Run the current few-shot LLM classifier against the golden test set.

    This establishes the baseline that custom models must beat.
    """
    ...
```

---

## 33. Training Config Schema — Python

```python
# ml/src/ml_platform/training/config.py

from pydantic import BaseModel

class LoraConfig(BaseModel):
    r: int = 16
    alpha: int = 32
    dropout: float = 0.1
    target_modules: list[str] = ["q_proj", "v_proj"]

class EvalGateConfig(BaseModel):
    min_overall_f1: float = 0.0
    max_per_axis_regression: float = 0.05

class TrainingConfig(BaseModel):
    model_id: str
    capability: str
    base_model: str
    framework: str  # pytorch, xgboost, tensorflow
    training_type: str  # lora, full, tabular

    # Hyperparameters
    epochs: int = 3
    batch_size: int = 8
    learning_rate: float = 2e-4
    warmup_ratio: float = 0.1

    # LoRA (only for fine-tuning)
    lora: LoraConfig | None = None

    # Label schema
    label_schema: dict[str, list[str]]

    # Eval gate
    eval_gate: EvalGateConfig = EvalGateConfig()

    # Resources
    data_bucket: str = "i4g-ml-data"
    machine_type: str = "n1-standard-4"
    gpu_type: str | None = "NVIDIA_TESLA_T4"
    gpu_count: int = 1
```
