# Performance Optimization: Case Classification

**Context:**
Case classification is currently a bottleneck. We are moving from synchronous inline classification to an **asynchronous "Sweeper" pattern** using Cloud Run Jobs. This decouples ingestion speed from LLM latency and improves resilience.

**Strategy:**
Ingest cases with a `PENDING` status. A scheduled Cloud Run Job periodically wakes up, fetches a batch of pending cases, classifies them in bulk, and updates the database.

## Phase 1: Foundation (Schema & Logic)
- [x] **Data Model Updates**:
    - [x] Update `Case` model schema to support `status` (PENDING, CLASSIFIED, UNMATCHED).
    - [x] Ensure ingestion sets initial status to `PENDING`.
- [x] **Implement `classify_batch`**: Add method to `FraudClassifier` in `core/src/i4g/services/classifier.py`.
    - [x] Construct batched prompt (injecting taxonomy once for N items).
    - [x] Return list of `FraudClassificationResult`.
    - [x] Handle partial failures (return `None` or error for specific items).

## Phase 2: Sweeper Job Implementation
- [x] **Create Sweeper Job**: Create `core/src/i4g/worker/jobs/classification_sweeper.py`.
    - [x] **Logic**: Loop-until-empty pattern.
        1. Fetch `N` (e.g., 50) cases where `status='PENDING'`.
        2. If empty: Exit immediately (Job success).
        3. Classify batch via `classify_batch`.
        4. Update DB with results (or `UNMATCHED` if no label found).
        5. Check remaining execution time; if < 5 mins left, Exit (let next run handle rest).
        6. Repeat Loop.

## Phase 3: Infrastructure & Deployment
- [x] **Infrastructure Definition**:
    - [x] Define Cloud Run Job `classification-sweeper` in Terraform (`infra/environments/app/dev/terraform.tfvars`).
    - [x] Configure Cloud Scheduler `classification-trigger` (Cron: `*/5 * * * *`).
    - [x] Set `parallelism` to 1.
- [x] **Deployment**:
    - [x] Deploy updated core image (`ingest-job:dev`).
    - [x] Apply Terraform changes.

## Phase 4: Optimization (Future)
- [ ] **Fine-tuning**: Distill the few-shot prompt into a fine-tuned Gemini 2.0 Flash model.
- [ ] **Caching**: Cache classification results based on content hash.
