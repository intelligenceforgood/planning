# Fraud Taxonomy Implementation Tasks

This checklist tracks the implementation of the Fraud Taxonomy system.
**Status Legend:** `[ ]` Todo, `[x]` Done, `[-]` Skipped/Descoped

## Phase 0: Foundations (Completed)
- [x] Define initial taxonomy enums (`core/src/i4g/taxonomy/enums.py`)
- [x] Define JSON output schema (`core/templates/fraud_classification_schema.json`)

## Phase 1: Type-Safe Domain Models
- [x] Create Pydantic models in `core/src/i4g/taxonomy/models.py`
  - [x] `FraudClassificationResult` model
  - [x] `ScamIntent`, `DeliveryChannel`, etc. enum integration
  - [x] Validation logic (0.0-1.0 confidence scores)
- [x] Add unit tests for model validation

## Phase 1.5: Taxonomy Infrastructure (Tooling)
- [x] Create `data/taxonomy/definitions.yaml` (Single Source of Truth)
  - [x] Migrate existing enums to YAML format
  - [x] Add descriptions and metadata
- [x] Create `scripts/codegen/taxonomy.py`
  - [x] Implement `generate_python_enums`
  - [x] Implement `generate_typescript_enums`
  - [x] Implement `generate_markdown_docs`
- [x] Add `make taxonomy-gen` target to Makefile
- [x] Verify generated code matches existing `enums.py`

## Phase 2: LLM Classification Layer
- [x] **Golden Dataset**
  - [x] Create `data/taxonomy/golden_examples.json`
  - [x] Curate 20-50 examples covering all intents and techniques
  - [x] Validate examples against the schema
- [x] **Prompt Engineering**
  - [x] Create `core/src/i4g/llm/prompts/fraud_classifier.md`
  - [x] Implement dynamic injection of taxonomy definitions from SSOT
  - [x] Implement few-shot example selection logic
- [x] **Service Implementation**
  - [x] Create `core/src/i4g/services/classifier.py`
  - [x] Implement `classify_text(text: str) -> FraudClassificationResult`
  - [x] Add retry logic for malformed JSON
  - [x] Implement LLM providers (Ollama for local, Vertex AI for cloud)

## Phase 3: Confidence & Risk
- [x] Implement confidence calibration logic (Implemented via weighted risk scoring)
- [x] Define risk scoring formula (weighted sum of signals)
- [x] Update `FraudClassificationResult` to include `risk_score`

## Phase 4: Rules & Signals
- [x] Implement regex-based detectors (crypto addresses, URLs)
- [x] Integrate rule signals into the classification pipeline

## Phase 5: Integration
- [x] Map taxonomy labels to `Campaign` objects
- [x] Update `cases` table in DB to store `classification_result`
- [x] Ensure `taxonomy_version` is stored with results

## Phase 6: UI Integration (Frontend)
- [x] Generate TypeScript types from SSOT
- [x] Update Analyst Console to display classification tags
- [x] Add "Explain" tooltip support using taxonomy descriptions

## Phase 7: Governance
- [x] Create "Analyst Feedback" endpoint
- [x] Document taxonomy deprecation process
