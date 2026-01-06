# Task: Expose Fraud Taxonomy in API

**Status:** Completed
**Owner:** Copilot
**Related PRD:** [planning/prd_fraud_taxonomy.md](../prd_fraud_taxonomy.md)
**Related TDD:** [core/docs/design/fraud_taxonomy_tdd.md](../../core/docs/design/fraud_taxonomy_tdd.md)

## Overview
Implement the persistence and API exposure of the new Fraud Taxonomy fields (explanation, tags, few-shot examples) to support the frontend display.

## Implementation Checklist

### Phase 1: Data Modeling & Schema
- [x] **Create Taxonomy Models** (`core/src/i4g/taxonomy/models.py`)
    - Define `ScoredLabel` (label, confidence).
    - Define `ClassificationResult` Pydantic model matching the TDD, adding fields for `explanation` and `few_shot_examples`.
- [x] **Update Database Schema** (`core/src/i4g/store/sql.py` & `review_store.py`)
    - Add `classification_result` (JSON/JSONB) column to `review_queue` table.
    - Add `tags` (JSON/Array) column to `review_queue` table (for high-level filtering).
    - Update `ReviewStore._init_tables` (SQLite) to include these columns in `CREATE TABLE`.

### Phase 2: Store Implementation
- [x] **Update ReviewStore Interface**
    - Update `enqueue_case` signature to accept `classification` and `tags` arguments.
- [x] **Update SQLite Implementation** (`ReviewStore`)
    - Modify `enqueue_case` to INSERT `classification_result` and `tags`.
    - Modify `get_review` (and `get_queue`) to SELECT and parse these fields from JSON.
- [x] **Update SQLAlchemy Implementation** (`SqlAlchemyReviewStore`)
    - Modify `enqueue_case` to persist the new fields.

### Phase 3: API Layer Integration
- [x] **Update API Models** (`core/src/i4g/api/review.py`)
    - Update `EnqueueRequest` to strictly type `classification` using `ClassificationResult`.
    - Define a `ReviewResponse` model (if not already present) to document the output schema for `GET /reviews/{id}`.
- [x] **Update API Endpoints**
    - Ensure `POST /reviews/` passes the new fields to `store.enqueue_case`.
    - Verify `GET /reviews/{id}` returns the enriched object.

### Phase 4: Verification
- [x] **Add Unit Tests**
    - Test enqueuing a case with full taxonomy data (intents, explanation, examples).
    - Test retrieving the case and verifying data integrity.
- [x] **Manual Verification**
    - Run `manual_review_demo.py` (updated) to verify the flow end-to-end.
