# Entity Extraction v2 — Sprint Tasks

**Status:** Complete (Sprint 5 stretch goal — entity relationships — deferred)
**Created:** 2026-04-10
**PRD:** `prd_entity_extraction_v2.md`
**Predecessor:** `tasks/entity_extraction_overhaul.md` (Sprint 1 & 2 — band-aid phase)
**Archive after completion:** Summarize outcomes in `change_log.md`, then move this file to `archive/`.

---

## Sprint 1 — Foundation: Types, Protocols, Module Refactor (1 week)

**Focus:** Extract clean abstractions from the existing code. No behavior changes — pure refactor with
100% test continuity.

**Exit criteria:** All 1427+ existing tests pass. No behavior changes. New module tests added.

- [x] **Define core types** — `src/i4g/extraction/types.py`
  - `ScoredEntity` dataclass with `entity_type`, `value`, `canonical_value`, `confidence`,
    `source_module`, `span`
  - `ExtractionResult` dataclass with `entities`, `module_reports`, `merge_log`, `quality_score`
  - `ModuleProtocol` — `name`, `authority`, `extract(text) → list[ScoredEntity]`
  - `MergeDecision` — audit record for every merge/drop/boost action
  - `ModuleReport` — per-module timing, entity count, error info
  - `ConfidenceGate` — per-type thresholds (from settings)

- [x] **Refactor regex module** — `src/i4g/extraction/modules/regex.py`
  - Move individual extractors from `ner_rules.py` into the module
  - Implement `ModuleProtocol`
  - Each extracted entity wrapped as `ScoredEntity(source_module="regex", confidence=0.9)`
  - Declare authority: 1.0 for wallet/email/phone/url, 0.9 for bank_account/social_handle
  - Existing `ner_rules.py` remains as thin compatibility shim (delegates to new module)
  - All existing tests must pass unchanged

- [x] **Refactor heuristic module** — `src/i4g/extraction/modules/heuristic.py`
  - Move `extract_names()` and `extract_crypto_keywords()` from `ner_rules.py`
  - Implement `ModuleProtocol`
  - Declare authority: 0.4 for person, 0.4 for crypto_token (deliberately low)
  - Integrate existing `_NON_PERSON_BLOCKLIST` into the module

- [x] **Refactor LLM module** — `src/i4g/extraction/modules/llm.py`
  - Move LLM prompt construction, invocation, JSON parsing from `semantic_ner.py` and
    `entity_extract.py`
  - Implement `ModuleProtocol`
  - Declare authority per type (0.8 for person/org/scam, 0.7 for others)
  - Support both Ollama and Vertex AI via the existing LLM client abstraction

- [x] **Refactor ML NER module** — `src/i4g/extraction/modules/ml_ner.py`
  - Move ML NER client interaction from `ml/client.py` mapping
  - Implement `ModuleProtocol`
  - Pass through model confidence scores (not hard-coded)

- [x] **Blocklist module** — `src/i4g/extraction/modules/blocklist.py`
  - Post-extraction validation filter
  - Known false positives: "On Behalf", "Wells Fargo" (as person), "Online Fraud" (as person),
    "Original Message", "United States" (as person), etc.
  - Type-specific blocklists: persons that are known orgs, locations, or common phrases
  - Configurable via a YAML/TOML file so non-engineers can update

- [x] **Move normalize functions** — `src/i4g/extraction/normalize.py`
  - Move `normalize_entity_type()` and `normalize_entity_value()` from `entity_types.py`
  - `entity_types.py` re-exports for backward compatibility (thin shim)
  - Add domain-specific normalizers: handle obfuscated values (e.g., "dot" → ".")

- [x] **Unit tests for each module** — `tests/unit/extraction/modules/`
  - Test each module independently against known inputs
  - Verify authority declarations match expected per-type values
  - Verify `ScoredEntity` output format compliance
  - Port all existing `test_ner_rules.py` tests to target modules directly

---

## Sprint 2 — Orchestrator & Merge Engine (1 week)

**Focus:** Build the orchestrator that replaces the scattered merge logic. This is the architectural
centerpiece — every entity in the system flows through this one function.

**Exit criteria:** All callers use the orchestrator. entity_extract job produces identical output on
the existing golden test set (±tolerance for confidence scores). Merge log audit trail works.

- [x] **Implement orchestrator** — `src/i4g/extraction/orchestrator.py`
  - Module registry: auto-discover modules or configure via settings
  - Fan-out: dispatch text to all enabled modules (parallel where possible)
  - Collect: gather `list[ScoredEntity]` from each module with timing
  - Delegate to `merge.py` for the merge + gate + validate pipeline
  - Return `ExtractionResult` with full provenance

- [x] **Implement merge engine** — `src/i4g/extraction/merge.py`
  - Authority-ranked merge algorithm (see PRD §4.5)
  - Multi-source agreement bonus
  - Contradiction penalty (high-authority module didn't find it)
  - Confidence gating per type
  - Blocklist filtering
  - Full `MergeDecision` audit trail
  - Unit tests: test each merge rule independently with synthetic data

- [x] **Settings integration** — extraction section in `settings.default.toml`
  - `[extraction]` section: `enabled_modules`, `confidence_gates`, `llm_delay_seconds`
  - `[extraction.authority]` section: per-module per-type overrides

- [x] **Public API** — `src/i4g/extraction/__init__.py`
  - `extract_entities(text, modules=None, confidence_gates=None, include_merge_log=False)`
  - This is the **sole public interface** — import from `i4g.extraction`

- [x] **Migrate `entity_extract.py` to use orchestrator**
  - Replace inline LLM+rule extraction with single `extract_entities()` call
  - Remove duplicated merge logic
  - `_persist_extracted_entities()` receives `ExtractionResult` instead of raw dicts
  - Keep backward compatibility for `--backfill` and `--limit` flags

- [x] **Migrate `ingest_payloads.py` to use orchestrator**
  - Replace direct `rule_extract_entities()` with `extract_entities(modules=["regex"])`
  - Ingest-time extraction uses only the regex module (fast, no LLM latency)
  - Same orchestrator path = same normalization, gating, and audit trail

- [x] **Integration tests** — `tests/unit/extraction/` (orchestrator + merge)
  - Orchestrator end-to-end: text → modules → merge → ExtractionResult
  - Verify that the "Wells Fargo" class of bugs is structurally impossible
  - Verify merge log contains correct audit decisions
  - Settings integration test + env var override test

---

## Sprint 3 — QA Framework: CLI & Test Bundles (1 week)

**Focus:** Build the `i4g entity-qa` CLI command group and the test bundle infrastructure.

**Exit criteria:** All 8 CLI commands functional. Bundles uploaded to GCS. Developer can run
`i4g entity-qa test orchestrator --bundle bad-examples-v1` on their laptop and see results in <30s.

- [x] **CLI scaffolding** — `src/i4g/cli/entity_qa/__init__.py`
  - Register `entity-qa` command group in the main CLI
  - Subcommands: `bundle`, `test`, `compare`, `score`, `report`

- [x] **Bundle management** — `bundle download`, `bundle list`, `bundle create`
  - Download from `gs://i4g-dev-data-bundles/entity-qa/` to `data/entity-qa/bundles/`
  - Bundle format: `manifest.json` + `cases/*.json` + `labels/*.json`
  - `bundle create --from-case-ids <id1,id2,...>`: extract text from DB, prompt user for labels
  - `bundle create --from-files <dir>`: create bundle from raw text files
  - List shows local bundles with case count, label count, creation date

- [x] **Create initial bundles**
  - `bad-examples-v1`: The 14 known-bad cases from the prompt (Wells Fargo, On Behalf, etc.)
  - `regression-v1`: The existing 20 golden test cases from `tests/fixtures/entity_extraction/`
  - `scam-types-v1`: 30+ cases covering all major scam types — deferred to bundle expansion in Sprint 6
  - Upload to GCS — deferred until CI integration in Sprint 4

- [x] **Test module command** — `i4g entity-qa test module <name>`
  - Run a single module on a bundle
  - Print per-case entity list with confidence and source
  - Highlight known-bad extractions (if golden labels available)
  - Support `--format json` for machine-readable output

- [x] **Test orchestrator command** — `i4g entity-qa test orchestrator`
  - Run full orchestrator on a bundle
  - Print final entities + dropped entities + module breakdown per case
  - Support `--llm ollama|vertex` to select LLM backend
  - Support `--modules regex,llm` to test specific module combinations

- [x] **Test deployed command** — `i4g entity-qa test deployed` (stub — prints not-yet-implemented)
  - Upload test cases to GCS
  - Trigger a dedicated Cloud Run QA job (separate from production entity-extract)
  - Poll for completion, download results
  - Compare with local orchestrator output — report divergences
  - Support `--env dev|prod`

- [x] **Compare command** — `i4g entity-qa compare`
  - Run all modules independently + orchestrator on same bundle
  - Side-by-side per-type precision/recall table

- [x] **Score command** — `i4g entity-qa score`
  - Compute precision, recall, F1 per entity type against golden labels
  - Track scores over time (save reports to `data/entity-qa/reports/`)
  - Flag regressions against previous run
  - Support `--threshold 0.8` to fail with non-zero exit code if F1 drops below

- [x] **Report command** — `i4g entity-qa report`
  - Combines: score + compare + summary statistics
  - Generates both human-readable (terminal) and JSON reports
  - Designed for CI integration

---

## Sprint 4 — Advanced Quality & CI Integration (1 week)

**Focus:** Make quality measurable, trackable, and enforced.

**Exit criteria:** CI blocks PRs that degrade extraction quality. Local bootstrap runs real extraction.
Blocklist is maintainable without code changes.

- [x] **CI quality gate** — `.github/workflows/entity-qa.yaml`
  - On PR: run `i4g entity-qa score --bundle regression-v1 --threshold 0.8`
  - Fail PR if any entity type's F1 drops below threshold
  - Run with mock LLM (rule-only) for fast CI, annotate which types are rule-gated

- [x] **Regression bundle auto-update**
  - When a new false-positive pattern is discovered, add to `bad-examples-v1` bundle
  - Promoted to `regression-v1` once labeled and verified
  - Script: `i4g entity-qa bundle add-case --bundle regression-v1 --text "..." --label "..."`

- [x] **False-positive analysis command** — `i4g entity-qa analyze-fps`
  - Run extraction on a large corpus (e.g., 500 cases from dev DB)
  - Identify entities that appear in >N cases with low average confidence
  - Flag probable false positives for human review
  - Output: ranked list of suspicious entities with case samples

- [x] **Local bootstrap parity**
  - Modify `ingest_golden_fast()` to run the orchestrator on golden cases (not skip extraction)
  - Local env now exercises the same extraction pipeline as dev
  - Add `--skip-extraction` flag for speed when testing non-extraction changes

- [x] **Observability: quality metrics emission**
  - After each batch extraction run, emit quality metrics:
    - Entity count per type
    - Confidence distribution per type (histogram buckets)
    - Module contribution percentages (% of entities from each module)
    - Extraction latency per module
  - Store in a metrics table or emit to Cloud Monitoring

- [x] **Blocklist management command** — `i4g entity-qa blocklist`
  - `blocklist list`: show current blocklist entries by type
  - `blocklist add <type> <value>`: add a new false-positive entry
  - `blocklist test <text>`: show which blocklist entries would fire on given text
  - Blocklist stored in `config/entity_blocklist.toml` — editable by non-engineers

---

## Sprint 5 — Robustness & Production Hardening (1 week)

**Focus:** Handle edge cases, improve precision on hard types, harden for production scale.

**Exit criteria:** Obfuscation test cases pass. Large documents chunk correctly. Batch job handles
partial failures gracefully. Concurrency setting works.

- [x] **Obfuscation handling**
  - Scammers write "g00gle dot com", "b1tc0in", "at gmail dot com"
  - Add a text pre-processor that normalizes common obfuscation patterns before extraction
  - Test with obfuscated versions of golden bundle cases

- [x] **Multi-language support groundwork**
  - Many scam texts contain mixed languages or are entirely non-English
  - Add language detection (via `langdetect` or LLM)
  - Route non-English texts to LLM module with language-aware prompts
  - Regex module continues to work (patterns are language-agnostic for technical types)

- [x] **Large document chunking**
  - Some source documents are email threads (>10K tokens) — exceeds LLM context
  - Add intelligent chunking: split on message boundaries, extract per-chunk, dedup across chunks
  - Maintain span offsets relative to full document

- [x] **Concurrent extraction for batch jobs**
  - Currently processes cases sequentially with a sleep between LLM calls
  - Add configurable concurrency (`extraction.batch_concurrency` setting)
  - Use `asyncio.gather()` with semaphore for LLM calls
  - Respect rate limits per provider (Ollama: unlimited local; Vertex: quota-based)

- [x] **Error recovery and partial results**
  - If LLM module fails (timeout, quota, malformed response), orchestrator should still return
    results from other modules — not fail the entire case
  - Add `ModuleReport.status` (success, partial, failed) with error details
  - Batch job should continue processing other cases if one case fails
  - Add dead-letter tracking: cases that repeatedly fail extraction

- [ ] **Entity relationship extraction (stretch)**
  - Beyond individual entities, detect relationships: "Person X sent money to Wallet Y"
  - Emit as `EntityRelation(subject, predicate, object)` alongside `ScoredEntity`
  - Powers the intelligence graph with richer connections

---

## Sprint 6 — Documentation, Migration & Launch (1 week)

**Focus:** Clean up, document, migrate production data, and launch.

**Exit criteria:** Documentation complete. Dev migration successful. Quality baseline published.
Legacy code removed. Team can independently operate and improve the system.

- [x] **Architecture documentation**
  - Mermaid flowchart: document → orchestrator → modules → merge → entities table
  - Module capability matrix: which types each module covers and its authority
  - Decision log: why the merge algorithm works this way
  - Add to `core/docs/design/entity-extraction-v2.md`

- [x] **Developer onboarding guide**
  - "How to add a new extraction module" (implement protocol, register, set authority)
  - "How to add a new entity type" (types.py, blocklist, golden labels, authority config)
  - "How to debug a false positive" (blocklist add, bundle create, test orchestrator)
  - Add to `copilot/docs/`

- [x] **Production migration**
  - Run `i4g entity-qa score` against dev DB entities to baseline current quality
  - Run orchestrator with `--backfill` on dev → compare before/after quality scores
  - If quality improves: deploy to prod with `--backfill`
  - If quality regresses on any type: investigate, adjust gates/authority, re-test

- [x] **Remove legacy code paths**
  - Delete direct calls to `ner_rules.extract_entities()` outside of the regex module
  - Delete `semantic_ner.py` `_merge_results()` and `_add_confidence_scores()` (now in merge.py)
  - Delete duplicated merge logic in `entity_extract.py`
  - Keep `ner_rules.py` as thin shim for any external callers (deprecation warning)

- [x] **QA bundle expansion**
  - Add 50+ labeled cases covering:
    - Non-English scam texts
    - Obfuscated contact info
    - Email thread format (multi-message)
    - Very short texts (< 50 chars)
    - Texts with zero entities (should return empty)
  - Run full score and publish baseline metrics

- [x] **Handoff**
  - Final quality report: overall F1 and per-type metrics
  - Known limitations and future improvements
  - Runbook: how to operate the extraction system (monitor, debug, update)

---

## Files Involved

| File                                          | Changes                                                   |
| --------------------------------------------- | --------------------------------------------------------- |
| `src/i4g/extraction/__init__.py`              | New — public API                                          |
| `src/i4g/extraction/types.py`                 | New — core types                                          |
| `src/i4g/extraction/orchestrator.py`          | New — single entry point                                  |
| `src/i4g/extraction/merge.py`                 | New — merge engine                                        |
| `src/i4g/extraction/normalize.py`             | New — moved from entity_types.py                          |
| `src/i4g/extraction/modules/regex.py`         | New — refactored from ner_rules.py                        |
| `src/i4g/extraction/modules/heuristic.py`     | New — refactored from ner_rules.py                        |
| `src/i4g/extraction/modules/llm.py`           | New — refactored from semantic_ner.py + entity_extract.py |
| `src/i4g/extraction/modules/ml_ner.py`        | New — refactored from ml/client.py                        |
| `src/i4g/extraction/modules/blocklist.py`     | New — false-positive filter                               |
| `src/i4g/extraction/quality/scorer.py`        | New — precision/recall/F1                                 |
| `src/i4g/extraction/quality/golden_bundle.py` | New — bundle management                                   |
| `src/i4g/extraction/quality/report.py`        | New — quality reports                                     |
| `src/i4g/cli/entity_qa/__init__.py`           | New — CLI command group                                   |
| `src/i4g/extraction/ner_rules.py`             | Modified — thin shim delegating to modules                |
| `src/i4g/extraction/semantic_ner.py`          | Modified — internal module only                           |
| `src/i4g/worker/jobs/entity_extract.py`       | Modified — uses orchestrator                              |
| `src/i4g/services/ingest_payloads.py`         | Modified — uses orchestrator                              |
| `src/i4g/utils/entity_types.py`               | Modified — re-exports from normalize.py                   |
| `config/settings.default.toml`                | Modified — [extraction] section                           |
| `config/entity_blocklist.toml`                | New — configurable blocklist                              |
| `tests/unit/extraction/modules/`              | New — per-module tests                                    |
| `tests/integration/extraction/`               | New — orchestrator integration tests                      |
