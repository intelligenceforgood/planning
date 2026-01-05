# Performance Optimization: Case Classification

**Context:**
Bootstrapping the dev environment with ~8,000 cases using Gemini 2.5 and few-shot classification is too slow (estimated days) and risks hitting rate limits. The current implementation processes cases sequentially (1-by-1), sending the full taxonomy and few-shot examples with every request.

**Strategy:**
Implement batch processing and support for faster models to reduce latency and API calls.

## Phase 1: Immediate Mitigation (Bootstrap Unblock)
- [ ] **Use Mock Classifier**: For local/dev bootstrap where accurate classification isn't critical, use `I4G_LLM__PROVIDER=mock`.
- [ ] **Use Faster Model**: Configure `I4G_LLM__CHAT_MODEL=gemini-2.0-flash` (or similar) to trade some accuracy for speed.
- [ ] **Selective Classification**: Add a flag to `ingest-bootstrap` to limit classification to a subset of cases (e.g., first 100) and skip the rest.

## Phase 2: Batch Processing (Efficiency)
- [ ] **Update Prompt Template**: Modify `core/src/i4g/llm/prompts/fraud_classifier.md` to accept a list of inputs and return a list of JSON objects.
- [ ] **Implement `classify_batch`**: Add method to `FraudClassifier` in `core/src/i4g/services/classifier.py`.
    - [ ] Construct batched prompt (injecting taxonomy once for N items).
    - [ ] Parse list response.
    - [ ] Handle partial failures (if one item in batch fails).
- [ ] **Update Ingestion Job**: Modify `core/src/i4g/worker/jobs/ingest.py` to process records in batches (e.g., size=10).
    - [ ] Accumulate records in a buffer.
    - [ ] Call `classify_batch` when buffer is full.
    - [ ] Map results back to payloads.
    - [ ] Ingest results.

## Phase 3: Advanced Optimization (Scalability)
- [ ] **Async Classification**: Decouple classification from ingestion. Ingest raw text first, then trigger a background Cloud Task for classification.
- [ ] **Caching**: Cache classification results based on content hash to avoid re-processing duplicates.
- [ ] **Fine-tuning**: Distill the few-shot prompt into a fine-tuned Gemini 2.0 Flash model for lower latency and cost.
