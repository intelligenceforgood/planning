# Implementation Roadmap – Fraud Classification System

This roadmap translates the approved PRD and initial artifacts into an executable, engineering-ready plan.
It is designed to work well with GitHub Copilot and to integrate cleanly into the IntelligenceForGood system.

---

## Phase 0 – Foundations (Completed)

### Artifacts Delivered
- `fraud_taxonomy_enums.py`
  - Canonical source of truth for fraud labels
  - Stable, versionable enums aligned with PRD
- `fraud_classification_schema.json`
  - Output contract for classifiers
  - Enforces multi-label, probabilistic structure

### Outcomes
- Shared vocabulary between humans, models, and code
- Clear separation between taxonomy (what) and detection logic (how)

---

## Phase 1 – Type-Safe Domain Models (Next Step)

### Goals
- Prevent schema drift
- Catch invalid model outputs early
- Make Copilot generate correct code by default

### Tasks
1. Create Pydantic models wrapping enums and schema
2. Add automatic validation and serialization
3. Attach taxonomy version metadata to every result

### Deliverables
- `models/fraud_classification.py`
- Unit tests for validation edge cases

---

## Phase 1.5 – Taxonomy Infrastructure (New)

### Goals
- Single Source of Truth (SSOT) for all languages (Python, TS)
- Automate documentation updates

### Tasks
1. Define `taxonomy_definitions.yaml` (The SSOT).
2. Create `scripts/generate_taxonomy.py`:
   - Generate `enums.py` (Python)
   - Generate `enums.ts` (TypeScript)
   - Generate Markdown tables for Docs
3. Add CI check to verify generated files match the YAML source.

### Deliverables
- `data/taxonomy/definitions.yaml`
- `scripts/codegen/taxonomy.py`

---

## Phase 2 – LLM Classification Layer

### Goals
- Reliable multi-axis tagging
- Minimize hallucinated or out-of-taxonomy labels

### Tasks
1. **Curate Golden Dataset**: Create 20-50 labeled examples covering all axes.
2. Design a strict prompt contract:
   - Enumerate allowed labels explicitly (injected from SSOT)
   - Require JSON-only output
3. Implement zero-shot / few-shot classifiers per axis
   - Implement "Example Selector" logic for few-shot prompting.
4. Add retry + repair logic for invalid outputs

### Deliverables
- `data/taxonomy/golden_examples.json`
- `llm/prompts/fraud_classifier.md`
- `services/llm_classifier.py`

---

## Phase 3 – Confidence Calibration & Risk Scoring

### Goals
- Avoid overconfidence (common LLM failure mode)
- Produce user-safe outputs

### Tasks
1. Calibrate raw model scores
2. Define confidence thresholds (high / medium / low)
3. Implement composite risk scoring across axes

### Deliverables
- `services/confidence_calibrator.py`
- Calibration documentation

---

## Phase 4 – Rules & Signal Enrichment

### Goals
- Improve precision
- Catch obvious scams deterministically

### Tasks
1. Add regex / heuristic detectors (crypto wallets, gift cards, URLs)
2. Combine rules + LLM signals
3. Weight signals by reliability

### Deliverables
- `rules/heuristics.py`
- Signal weighting configuration

---

## Phase 5 – IntelligenceForGood Integration

### Goals
- Turn classification into actionable intelligence

### Tasks
1. Map taxonomy labels to known scam campaigns
2. Attach historical trends and damage estimates
3. Enable campaign clustering

### Deliverables
- `intelligence/campaign_mapping.py`
- Campaign data schema

---

## Phase 6 – Feedback Loop & Governance

### Goals
- Continuous improvement
- Safe taxonomy evolution

### Tasks
1. Capture user confirmations / corrections
2. Enable analyst overrides
3. Version and deprecate taxonomy labels safely

### Deliverables
- Feedback ingestion pipeline
- Taxonomy governance guide

---

## Phase 7 – Metrics & Monitoring

### Goals
- Measure trust, not just accuracy

### Metrics
- Precision / recall per intent
- False reassurance rate (critical)
- Analyst agreement rate
- User comprehension feedback

---

## Guiding Principles (Do Not Break)

- Multi-label > single label
- Explainability over raw accuracy
- Version everything
- Never silently change taxonomy semantics

---

## Status
- Current: Phase 0 complete
- Next recommended step: Phase 1 (Type-safe domain models)

Owner: IntelligenceForGood
