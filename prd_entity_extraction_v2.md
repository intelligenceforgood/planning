# Entity Extraction v2 — Product Requirements Document

**Status:** Leadership Sign-Off Pending
**Created:** 2026-04-10
**Team:** Entity Extraction v2 (EM + PM + Architect + 3 Engineers)
**Predecessor:** `tasks/entity_extraction_overhaul.md` (Sprint 1 & 2 — band-aid phase)
**Implementation:** `tasks/entity_extraction_v2_tasks.md`

---

## 1. Purpose & Goals

### 1.1 Purpose

Replace the current patchwork entity extraction pipeline with a first-class, encapsulated component
that has clear boundaries, modular extractors, a defined orchestration contract, and a developer-facing
quality framework that provides sub-minute feedback on any change.

### 1.2 Non-Goals

- Rewriting the DB schema (entities/indicators tables are sufficient)
- Building a standalone ML training pipeline for NER (handled by the ML team)
- Real-time streaming extraction (batch and ingest-time are sufficient for now)

---

## 2. Design Principles

1. **Encapsulation** — The extraction component has exactly one public interface: the Orchestrator.
   All other modules are internal. No caller reaches past the boundary.
2. **Module contract** — Every extractor implements the same protocol: `text in → scored entities out`.
   Modules declare which entity types they are authoritative for.
3. **Composition over union** — The orchestrator does not blindly merge. It applies per-type authority
   rankings, confidence gates, cross-module validation, and dedup before emitting a final entity set.
4. **Test without deploy** — Every module, and the full orchestrator, can be exercised from a laptop
   via `i4g entity-qa` CLI commands with real or synthetic data, in seconds.
5. **Measure everything** — Every extraction run produces a quality scorecard (precision, recall, F1,
   false-positive rate per type). Regressions are caught before merge, not after a 5-hour bootstrap.

---

## 3. Current State & Gaps

### 3.1 Current extraction entry points (3 — should be 1)

| Path                                     | When                      | What runs                                    | Problem                                                                                                  |
| ---------------------------------------- | ------------------------- | -------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| **Ingest-time** (`ingest_payloads.py`)   | During case ingestion     | Rule-based regex (high-precision types only) | Silently skips heuristic types; no LLM; entities appear "partial" until batch job runs                   |
| **Batch job** (`entity_extract.py`)      | `i4g jobs entity-extract` | LLM + rules, merged                          | Primary path but decoupled from ingest — can lag hours; merge logic is embedded in the job, not reusable |
| **Pre-structured** (`build_case_bundle`) | Golden bundle ingest      | Direct from classification JSON              | Bypasses all extraction — local env never exercises the real pipeline                                    |

**Gap:** There is no single orchestrator function that takes text and returns entities. The "merge
strategy" is duplicated in `semantic_ner.py` (LLM+rules merge) and `entity_extract.py` (confidence
calibration merge) with subtly different logic.

### 3.2 Current module inventory

| Module          | File              | Types covered                                          | Precision                                             | Recall                            |
| --------------- | ----------------- | ------------------------------------------------------ | ----------------------------------------------------- | --------------------------------- |
| Regex rules     | `ner_rules.py`    | wallet, email, phone, URL, bank_account, social_handle | High (0.9)                                            | Medium — misses obfuscated values |
| Heuristic rules | `ner_rules.py`    | person, crypto_token                                   | **Low (0.5)** — root cause of "Wells Fargo" as person | Low                               |
| LLM semantic    | `semantic_ner.py` | All 12 prompt keys                                     | Medium (0.7)                                          | Medium — depends on model         |
| ML NER          | `ml/client.py`    | Provider-dependent                                     | Unknown — no quality metrics                          | Unknown                           |

**Gap:** No module declares its authority. The orchestrator cannot know that regex-wallet at 0.9 is more
trustworthy than LLM-wallet at 0.7 without hard-coded logic in the job file.

### 3.3 Quality & testability gaps

1. No way to run extraction on a single document from CLI and see results
2. No way to run extraction against a curated test bundle and get precision/recall metrics
3. No way to compare modules head-to-head (rule vs LLM vs ML NER) on the same inputs
4. Golden test set exists (20 cases in `tests/fixtures/`) but golden _bad-example_ cases (the errors
   the team keeps hitting) are not systematically tracked as regression tests
5. Local bootstrap uses pre-structured entities — never exercises the real pipeline
6. Dev bootstrap takes 5 hours — feedback loop is untenable for iterative improvement

### 3.4 Known false-positive patterns (regression baseline)

```
person,On Behalf       person,Wells Fargo      person,Online Fraud
person,Henderson Internal   person,Mark Mark    person,Revenue Service
person,Ruth Grover     person,Contact Needed    person,Original Message
person,United States   person,New York          person,On Mon
person,On Wed          person,Chase Bank
```

---

## 4. Component Architecture

### 4.1 Package structure

```
src/i4g/extraction/
├── __init__.py                  # Public API: extract_entities(), ExtractionResult
├── types.py                     # ScoredEntity, ExtractionResult, ModuleAuthority, EntityType enum
├── orchestrator.py              # Single entry point — coordinates modules, merges, gates
├── modules/
│   ├── __init__.py              # Module registry, ModuleProtocol
│   ├── regex.py                 # High-precision regex patterns (wallets, emails, phones, URLs, etc.)
│   ├── heuristic.py             # Lower-precision pattern matching (names, crypto keywords)
│   ├── llm.py                   # LLM-based semantic extraction (Ollama / Vertex AI)
│   ├── ml_ner.py                # ML NER model client (Vertex AI endpoint)
│   └── blocklist.py             # Post-extraction validation filter (known false positives)
├── merge.py                     # Authority-ranked merge, confidence gating, cross-module validation
├── normalize.py                 # Value normalization (moved from entity_types.py)
└── quality/
    ├── __init__.py
    ├── scorer.py                # Precision/recall/F1 computation against golden labels
    ├── golden_bundle.py         # Load/download golden test bundles from GCS
    └── report.py                # Human-readable + machine-readable quality reports
```

### 4.2 Core types

```python
class ScoredEntity:
    """A single extracted entity with provenance."""
    entity_type: str              # Canonical type (e.g., "person", "wallet_address")
    value: str                    # Raw extracted value
    canonical_value: str          # Normalized value
    confidence: float             # 0.0–1.0
    source_module: str            # "regex", "heuristic", "llm", "ml_ner"
    span: tuple[int, int] | None  # Character offsets in source text

class ExtractionResult:
    """Output of the orchestrator — the component's public contract."""
    entities: list[ScoredEntity]
    module_reports: dict[str, ModuleReport]  # Per-module timing, counts, errors
    merge_log: list[MergeDecision]           # Audit trail of merge/drop decisions
    quality_score: float | None              # If golden labels provided, overall F1

class ModuleProtocol(Protocol):
    """Every extraction module implements this."""
    name: str
    authority: dict[str, float]   # entity_type → authority weight (0–1)

    def extract(self, text: str) -> list[ScoredEntity]: ...
```

### 4.3 Orchestrator design

```
┌────────────────────────────────────────────────────────────────────┐
│                        Orchestrator                                │
│                                                                    │
│  1. Dispatch: fan-out text to all registered modules               │
│  2. Collect: gather ScoredEntity lists + timing from each module   │
│  3. Merge:                                                         │
│     a. Group by (entity_type, canonical_value)                     │
│     b. For each group: pick winner by authority ranking             │
│     c. If multiple modules found same value: boost confidence      │
│     d. Apply confidence gate (configurable per type)               │
│  4. Validate: blocklist filter → drop known false positives        │
│  5. Normalize: canonical value normalization                       │
│  6. Emit: ExtractionResult with full provenance                    │
└────────────────────────────────────────────────────────────────────┘
```

### 4.4 Module authority registry

Configurable via `settings.default.toml` `[extraction.authority]` section:

| Entity Type      | Primary Module | Secondary       | Confidence Gate |
| ---------------- | -------------- | --------------- | --------------- |
| `wallet_address` | regex (1.0)    | llm (0.7)       | 0.5             |
| `email_address`  | regex (1.0)    | llm (0.7)       | 0.5             |
| `phone_number`   | regex (1.0)    | llm (0.7)       | 0.5             |
| `url`            | regex (1.0)    | llm (0.7)       | 0.5             |
| `bank_account`   | regex (0.9)    | llm (0.7)       | 0.5             |
| `social_handle`  | regex (0.9)    | llm (0.7)       | 0.5             |
| `person`         | llm (0.8)      | ml_ner (0.7)    | 0.6             |
| `organization`   | llm (0.8)      | ml_ner (0.7)    | 0.6             |
| `location`       | llm (0.7)      | ml_ner (0.7)    | 0.5             |
| `crypto_token`   | llm (0.7)      | heuristic (0.4) | 0.4             |
| `scam_indicator` | llm (0.8)      | —               | 0.5             |

**Confidence gating** — entities below the gate threshold for their type are dropped before DB
persistence. This is the structural fix for the "Wells Fargo as person" class of bugs.

**Cross-module validation** — when both regex and LLM extract the same value, confidence is boosted
(not just max'd). When only heuristic extracts a value that LLM explicitly did NOT extract, confidence
is penalized.

### 4.5 Merge algorithm specification

```
for (entity_type, canonical_value) group:
    sources = [(module, entity) for each module that extracted this value]

    # 1. Authority-weighted confidence
    weighted = max(module.authority[type] * entity.confidence for module, entity in sources)

    # 2. Multi-source agreement bonus
    if len(sources) > 1:
        weighted = min(1.0, weighted + 0.1 * (len(sources) - 1))

    # 3. Contradiction penalty — if a high-authority module ran but did NOT find this value
    for module in registered_modules:
        if module.authority.get(type, 0) >= 0.7 and module not in sources and module.ran_successfully:
            weighted *= 0.8  # penalize unconfirmed values

    # 4. Confidence gate
    if weighted < CONFIDENCE_GATES[entity_type]:
        merge_log.append(MergeDecision(action="dropped", reason="below_gate", ...))
        continue

    # 5. Blocklist check
    if is_blocklisted(entity_type, canonical_value):
        merge_log.append(MergeDecision(action="dropped", reason="blocklisted", ...))
        continue

    result.append(ScoredEntity(confidence=weighted, source_module=best_source, ...))
```

### 4.6 Public API contract

The orchestrator is the **only** public interface to the extraction subsystem:

```python
from i4g.extraction import extract_entities, ExtractionResult

result: ExtractionResult = extract_entities(
    text=document_text,
    modules=None,            # Default: all registered modules; override for testing
    confidence_gates=None,   # Default: from settings; override for testing
    include_merge_log=False, # Performance: skip audit trail in production batch
)
```

**Callers that must migrate to this single entry point:**

1. `ingest_payloads.py` — replace direct `rule_extract_entities()` call
2. `entity_extract.py` — replace inline LLM+rule extraction + merge logic
3. `semantic_ner.py` — becomes an internal module, no longer called directly by consumers
4. Any future extraction path (SSI, real-time API, etc.)

### 4.7 Settings

```toml
[extraction]
enabled_modules = ["regex", "llm"]         # heuristic off by default
confidence_gates = {person = 0.6, organization = 0.6, location = 0.5}
llm_delay_seconds = 0.5
batch_concurrency = 4

[extraction.authority]
# Override default authority weights per module per type
# regex.wallet_address = 1.0
# llm.person = 0.8
```

---

## 5. Quality Assurance Framework — `i4g entity-qa`

### 5.1 CLI command group

```
i4g entity-qa
├── bundle download          # Download test bundles from gs://i4g-dev-data-bundles
├── bundle list              # List available bundles (local + remote)
├── bundle create            # Create a new bundle from case IDs or raw text files
├── test module <name>       # Run a single module on bundle, print results
├── test orchestrator        # Run full orchestrator on bundle, print results with provenance
├── test deployed            # Run against deployed Cloud Run entity-extract job
├── compare                  # Run all modules side-by-side on same inputs, diff output
├── score                    # Compute precision/recall/F1 against golden labels
└── report                   # Generate full quality report (all of the above)
```

### 5.2 Bundle format

Bundles live on `gs://i4g-dev-data-bundles/entity-qa/` and locally in `data/entity-qa/`:

```
data/entity-qa/
├── bundles/
│   ├── regression-v1/
│   │   ├── manifest.json       # Bundle metadata: source, creation date, case count
│   │   ├── cases/
│   │   │   ├── case_001.json   # {text, source_metadata}
│   │   │   └── ...
│   │   └── labels/
│   │       ├── case_001.json   # {entities: [{type, value, canonical_value}], notes}
│   │       └── ...
│   └── bad-examples-v1/       # The "Wells Fargo" etc. regression bundle
│       ├── manifest.json
│       ├── cases/
│       └── labels/
└── reports/
    └── 2026-04-10_regression-v1.json  # Score output
```

### 5.3 Command: `i4g entity-qa test module`

```bash
$ i4g entity-qa test module regex --bundle bad-examples-v1

╭──────────────────────────────────────────────────────╮
│ Module: regex   │ Bundle: bad-examples-v1 (14 cases) │
╰──────────────────────────────────────────────────────╯

Case: case_001 (Wells Fargo complaint)
  ✓ email_address: victim@gmail.com         (0.90)
  ✓ phone_number:  +1-800-555-0199         (0.90)
  ✓ url:           wellsfargo-secure.com    (0.90)
  ✗ person:        Wells Fargo              (0.50)  ← KNOWN BAD

Summary: 14 cases │ 47 entities │ 6 known-bad │ 41 correct
```

### 5.4 Command: `i4g entity-qa test orchestrator`

```bash
$ i4g entity-qa test orchestrator --bundle bad-examples-v1 --llm ollama

╭──────────────────────────────────────────────────────────────╮
│ Orchestrator   │ Bundle: bad-examples-v1   │ LLM: ollama    │
╰──────────────────────────────────────────────────────────────╯

Case: case_001 (Wells Fargo complaint)
  FINAL ENTITIES:
    email_address: victim@gmail.com          (0.95) ← regex(0.90) + llm(0.70) → boosted
    phone_number:  +1-800-555-0199          (0.95) ← regex(0.90) + llm(0.70) → boosted
    organization:  Wells Fargo               (0.72) ← llm(0.80) → authority-weighted
    person:        Ruth Grover               (0.70) ← llm(0.80) → authority-weighted

  DROPPED:
    person: "Wells Fargo"                    (0.32) ← heuristic(0.50) * no-llm-confirm(0.8) * gate(0.6)=FAIL
    person: "On Behalf"                      (0.00) ← blocklisted

  MODULE BREAKDOWN:
    regex:     5 extracted, 5 passed to merge
    llm:       7 extracted, 6 passed to merge
    heuristic: 3 extracted, 0 survived (all gated or blocklisted)

Summary: 14 cases │ 52 final entities │ 0 known-bad │ F1=0.94
```

### 5.5 Command: `i4g entity-qa test deployed`

```bash
$ i4g entity-qa test deployed --bundle bad-examples-v1 --env dev

Triggering Cloud Run job: entity-extract-qa (dev)
  Uploading 14 test cases to gs://i4g-dev-data-bundles/entity-qa/runs/2026-04-10_001/
  Job submitted...
  Waiting for completion... done (2m 14s)

Score vs local orchestrator:
  Agreement: 48/52 entities match (92.3%)
  Divergences:
    case_007: local found "crypto_token: USDT" (llm), deployed did not (model difference?)
    case_012: deployed found "person: Mark Stevens" (0.68), local dropped (0.58 < gate 0.6)
```

### 5.6 Command: `i4g entity-qa compare`

```bash
$ i4g entity-qa compare --bundle bad-examples-v1 --modules regex,llm,heuristic

Entity Type      │ regex │ llm  │ heuristic │ Orchestrator │ Golden
─────────────────┼───────┼──────┼───────────┼──────────────┼───────
wallet_address   │  8/8  │ 7/8  │    0/8    │     8/8      │   8
email_address    │ 12/12 │ 11/12│   0/12    │    12/12     │  12
phone_number     │ 10/11 │ 9/11 │   0/11    │    10/11     │  11
person           │  2/9* │ 8/9  │   2/9*    │     8/9      │   9
organization     │  0/6  │ 5/6  │   0/6     │     5/6      │   6
url              │ 15/15 │ 14/15│   0/15    │    15/15     │  15

* = includes false positives
Per-type F1: wallet=1.00, email=1.00, phone=0.95, person=0.89, org=0.83, url=1.00
Overall F1: 0.94
```

### 5.7 Command: `i4g entity-qa score`

```bash
$ i4g entity-qa score --bundle regression-v1 --output data/entity-qa/reports/

Overall: P=0.91  R=0.87  F1=0.89

Per-Type Breakdown:
  wallet_address:  P=1.00  R=1.00  F1=1.00  (n=24)
  email_address:   P=1.00  R=0.96  F1=0.98  (n=31)
  person:          P=0.85  R=0.78  F1=0.81  (n=42)
  organization:    P=0.80  R=0.72  F1=0.76  (n=19)

Regression Alerts:
  ⚠ person P dropped from 0.90 → 0.85 (previous: 2026-04-08)
  ✓ All other types within tolerance
```

---

## 6. Success Metrics

| Metric                                   | Current State            | Target (Launch) | Target (90-day) |
| ---------------------------------------- | ------------------------ | --------------- | --------------- |
| Person entity precision                  | ~0.60 (estimated)        | ≥ 0.85          | ≥ 0.92          |
| Person entity recall                     | ~0.70 (estimated)        | ≥ 0.78          | ≥ 0.85          |
| Overall F1 (all types)                   | ~0.75 (estimated)        | ≥ 0.88          | ≥ 0.93          |
| Known-bad false positives                | 14 recurring patterns    | 0               | 0               |
| Feedback loop (local test)               | 5 hours (full bootstrap) | < 30 seconds    | < 10 seconds    |
| Feedback loop (CI)                       | None                     | < 3 minutes     | < 2 minutes     |
| Extraction modules testable in isolation | 0                        | All 4+          | All             |
| Entity types with quality metrics        | 0                        | All 18          | All 18          |
| Documented extraction contract           | No                       | Yes             | Yes             |

---

## 7. Risk Assessment

| Risk                                                          | Likelihood | Impact | Mitigation                                                                                  |
| ------------------------------------------------------------- | ---------- | ------ | ------------------------------------------------------------------------------------------- |
| LLM module quality differs between Ollama and Vertex AI       | High       | Medium | Test both in QA framework; provider-specific prompt tuning                                  |
| Merge algorithm over-gates legitimate entities (hurts recall) | Medium     | High   | Start with permissive gates, tighten based on QA metrics; `include_merge_log` for debugging |
| Refactor breaks existing entity pipelines                     | Medium     | High   | Sprint 1 is pure refactor with 100% test continuity; integration tests before migration     |
| Bundle curation is labor-intensive                            | Medium     | Medium | Start with known-bad examples (already identified); automate FP discovery in Sprint 4       |
| ML NER module unavailable in some environments                | Low        | Low    | Orchestrator handles module failures gracefully; regex+LLM sufficient                       |
| Team unfamiliar with new architecture                         | Medium     | Medium | Onboarding guide + pair programming during Sprint 1                                         |

---

## 8. Dependencies & Assumptions

1. **GCS bucket** `gs://i4g-dev-data-bundles` exists and team has read/write access
2. **Developers have GCP auth** for LLM testing (Vertex AI) — confirmed in requirements
3. **Ollama available locally** for LLM module testing without cloud costs
4. **Existing tests** (1427+) remain the regression baseline throughout refactoring
5. **No DB schema changes** — the entities/indicators tables are sufficient; changes are in
   application code only
6. **SSI repo** — if SSI has its own extraction paths, they should migrate to use the same
   orchestrator via cross-repo import (tracked separately)

---

## 9. Phasing Summary

| Sprint | Focus                             | Duration | Key Deliverable                                    |
| ------ | --------------------------------- | -------- | -------------------------------------------------- |
| 1      | Types, protocols, module refactor | 1 week   | Clean abstractions, zero behavior change           |
| 2      | Orchestrator & merge engine       | 1 week   | Single entry point, callers migrated               |
| 3      | QA CLI & test bundles             | 1 week   | `i4g entity-qa` commands, <30s feedback loop       |
| 4      | CI integration & observability    | 1 week   | PR quality gate, FP analysis                       |
| 5      | Robustness & production hardening | 1 week   | Obfuscation, chunking, concurrency, error recovery |
| 6      | Documentation, migration & launch | 1 week   | Production backfill, legacy cleanup, handoff       |

> See `tasks/entity_extraction_v2_tasks.md` for the detailed sprint task checklist.

---

## 10. Sign-Off

| Role                | Name | Date | Approved |
| ------------------- | ---- | ---- | -------- |
| Engineering Manager | —    | —    | [ ]      |
| Product Manager     | —    | —    | [ ]      |
| Architect           | —    | —    | [ ]      |

### Approval criteria

- [ ] Architecture review: module protocol, orchestrator contract, and merge algorithm are sound
- [ ] Sprint sequencing: each sprint is independently testable and deployable
- [ ] Quality framework: CLI commands cover the team's daily development workflow
- [ ] Risk mitigations: acceptable for each identified risk
- [ ] Success metrics: achievable and measurable
