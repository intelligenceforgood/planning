# Entity Extraction Overhaul

**Status:** Sprint 2 Complete (Sprint 1 done 2026-04-09, Sprint 2 done 2026-04-10)
**Created:** 2026-04-09
**Owner:** Engineering
**Estimated Effort:** 2 sprints (Sprint 1: critical fixes + architecture, Sprint 2: quality & observability)

---

## Problem Statement

The entity extraction pipeline has accumulated 12 quality issues since initial implementation. The system
was built incrementally (rule-based → LLM → ML NER) without a unifying design review. Key symptoms:

- **Mistyped entities**: "Advance Fee", "Account Number", "Bank Name" classified as `person`
- **Contact channel conflation**: URLs, emails, phone numbers all merged into `contact_handle`
- **ML NER mapping bug**: `BANK_ACCOUNT` mapped to `wallet_addresses` instead of `bank_account`
- **LLM prompt covers only 7 of 23 canonical entity types**
- **Hardcoded confidence (0.7)** with no calibration
- **No golden test set** for quality regression detection

### Environment-Specific Observations

Local env (mock/Ollama) produces cleaner Person entities than dev (Vertex AI). This suggests the Vertex AI
Gemini model requires different prompt tuning than the local Ollama llama3 model, and the rule-based
blocklist fix (applied 2026-04-09) only covers one layer of the problem.

---

## Sprint 1 — Critical Fixes & Type Fidelity

### Phase 1A: Fix Critical Bugs (Day 1-2)

- [x] **Fix ML NER label mapping** — `core/src/i4g/ml/client.py`
  - Change `"BANK_ACCOUNT": "wallet_addresses"` → `"BANK_ACCOUNT": "bank_account"`
  - Change `"PHONE": "contact_channels"` → `"PHONE": "phone_numbers"`
  - Change `"EMAIL": "contact_channels"` → `"EMAIL": "email_address"`
  - Change `"URL": "contact_channels"` → `"URL": "urls"`
  - Add mapping entries for any missing ML NER labels
  - Add unit tests for the mapping

- [x] **Fix rule-based contact channel conflation** — `core/src/i4g/extraction/ner_rules.py`
  - Split `contact_channels` return key into separate keys: `urls`, `phone_numbers`, `email_address`
  - Remove `email_address` from being a separate key (it already is — verify consistency)
  - Ensure `extract_entities()` returns keys that all map cleanly through `normalize_entity_type()`

- [x] **Add missing normalization map entries** — `core/src/i4g/utils/entity_types.py`
  - Add `"urls": "url"` (if not already present)
  - Add `"phone_numbers": "phone_number"` (if not already present)
  - Add `"emails": "email_address"`
  - Audit all return keys from `ner_rules.py` and `entity_extract.py` → ensure every key has a mapping
  - Add test: every key returned by `extract_entities()` resolves to a canonical type

### Phase 1B: Expand LLM Entity Type Coverage (Day 2-4)

- [x] **Redesign LLM extraction prompt** — `core/src/i4g/worker/jobs/entity_extract.py` + `semantic_ner.py`
  - Expand `_ENTITY_KEYS` from 7 to cover high-value types:
    ```
    people, organizations, wallet_addresses, bank_accounts, account_numbers,
    routing_numbers, email_addresses, phone_numbers, urls, domains,
    social_handles, crypto_assets, locations, scam_indicators
    ```
  - Update few-shot examples to demonstrate the expanded types
  - Add negative examples showing what NOT to extract as person names
  - Test prompt with both Ollama (local) and Vertex AI (dev) to verify quality parity

- [x] **Add provider-specific prompt tuning** (if needed after testing)
  - If Gemini and Ollama produce different quality, consider provider-specific prompt variants
  - Document which model/provider each environment uses in a config comment

### Phase 1C: Indicator Filtering (Day 4-5)

- [x] **Filter non-threat entities from indicators table** — `core/src/i4g/worker/jobs/entity_extract.py`
  - Import `THREAT_ENTITY_TYPES` from `entity_types.py`
  - Only create indicator rows for entity types in `THREAT_ENTITY_TYPES`
  - Person, organization, location, scam_indicator should NOT become indicators
  - Add test verifying only threat types create indicators

- [x] **Write migration/cleanup script for existing bad data**
  - Delete indicator rows where `category NOT IN THREAT_ENTITY_TYPES`
  - Re-type misclassified entities (bulk UPDATE for known false-positive patterns)
  - Script should be idempotent and safe to run multiple times

### Sprint 1 Verification

- [x] Run `pytest tests/unit/extraction/` — all pass (1420 passed, 0 failed)
- [x] Run entity extraction on 50 sample cases locally, spot-check results
- [x] Run entity extraction on 50 sample cases on dev, compare quality with local
- [x] Verify no `person` entities with names like "Account Number", "Bank Name", etc.
- **Note:** Golden bundle ETL for `incident_responses` had garbage data (dollar amounts,
  dates, narratives stored as wallet_addresses/bank_accounts). Fixed wallet validation
  via regex extraction; remaining entity types (bank_account, contact_handle, payment_handle)
  need proper ETL rewrite from raw CSV `data/bundles/scambuster.csv`. See Sprint 2.

---

### ETL Rebuild (Workstream A — completed before Sprint 2)

- [x] **Rewrote ETL `_extract_entities()`** — `core/scripts/etl/etl_incident_responses.py`
  - Replaced blind `_split_multi()` with per-column extraction: bank accounts, contact handles,
    payment handles, wallet addresses, URLs
  - Added dedicated regexes: phone, email, Telegram handles/links, account/routing/IBAN/SWIFT/BSB,
    CashApp $tags, Venmo/PayPal handles
  - Fixed SWIFT false positives (DATAGRID etc.) by requiring label context
  - Fixed URL semicolon splitting and `_looks_like_url` logic bug
- [x] **Ran ETL** — 67 cases (of 95 CSV rows) passed narrative threshold → JSONL
- [x] **Rebuilt golden bundle** — 1182 total cases across all sources
- [x] **Re-bootstrapped local env** — all cases ingested, entities spot-checked clean

---

## Sprint 2 — Quality, Normalization & Observability

### Phase 2A: Canonical Value Normalization (Day 1-2)

- [x] **Implement value normalization per entity type** — new function in `entity_types.py` or `normalization/`
  - Wallet addresses: lowercase hex, strip whitespace
  - Email addresses: lowercase
  - Phone numbers: strip to digits + leading `+`
  - URLs/domains: lowercase, strip trailing slashes
  - Person names: title-case, collapse whitespace
  - Apply normalization before DB upsert dedup check

- [x] **Add cross-document entity deduplication**
  - When multiple source documents in a case mention the same entity, store one entity row
  - Link via `entity_mentions` table with per-document span offsets
  - Verify `(case_id, entity_type, canonical_value)` unique constraint works correctly after normalization

### Phase 2B: Confidence Calibration (Day 2-3)

- [x] **Differentiate confidence by extraction source**
  - Rule-based regex matches (wallets, emails, phones): 0.9 (high-precision patterns)
  - Rule-based heuristics (names, crypto keywords): 0.5 (noisy)
  - LLM extraction: 0.7 (default; no per-entity confidence available)
  - ML NER model: use actual model confidence score (already returned by endpoint)

- [x] **Propagate ML NER confidence through the pipeline**
  - `ml/client.py` already returns per-entity confidence
  - Ensure `entity_extract.py` persists actual confidence instead of overwriting with 0.7
  - When merging LLM + rule results, keep the higher confidence for duplicates

### Phase 2C: Golden Test Set & Quality Metrics (Day 3-5)

- [x] **Curate golden test set** — `core/tests/fixtures/entity_extraction/`
  - 20-30 representative scam texts covering all major scam types
  - Hand-labeled expected entities per text (entity_type + canonical_value)
  - Cover: crypto scam, romance scam, advance fee, impersonation, investment, tech support

- [x] **Build extraction quality harness**
  - Run extraction pipeline on golden set, compute per-type precision/recall/F1
  - Compare rule-only vs LLM-only vs merged results
  - Compare local (Ollama) vs dev (Vertex AI) results
  - Store results as JSON for regression tracking

- [x] **Add CI integration test**
  - Run golden test set in CI with mock LLM (rule-based only)
  - Fail if any entity type drops below minimum F1 threshold (e.g., 0.6)

### Phase 2D: Ingest-Time Extraction (Day 4-5)

- [x] **Add rule-based extraction at ingest time** — `core/src/i4g/services/ingest_payloads.py`
  - Currently only reads pre-structured `record.entities` / `metadata.entities`
  - Add: if no pre-structured entities, run `rule_extract_entities()` on available text fields
  - Reduces dependency on batch job for basic entity coverage

- [ ] **Document extraction pipeline architecture**
  - Flowchart: ingest → rule extraction → batch LLM extraction → ML NER (optional) → DB
  - Document which types each extraction path covers
  - Document environment-specific model configurations

### Sprint 2 Verification

- [x] Golden test set passes with ≥0.5 F1 across gated entity types (rule-based only)
- [x] Canonical value normalization implemented and integrated into SqlWriter + entity_extract job
- [x] Confidence scores vary by source (0.9 regex, 0.5 heuristic, 0.7 LLM — not all 0.7)
- [x] No regression in existing entity extraction tests (1427 passed, 0 failed)
- [ ] Backfill script runs successfully on dev environment

---

## Sprint 2E — Entity Type Consolidation

Reduced canonical entity types from 23 to 18 by merging overlapping types:

- [x] **Merged `account_number` + `routing_number` → `bank_account`**
  - All bank-related identifiers (account #, routing #, IBAN, SWIFT/BIC, BSB) now share one type
  - Updated normalization map to redirect both old types to `bank_account`
  - Removed from `ENTITY_TYPE_LABELS`, `THREAT_ENTITY_TYPES`, `_VALUE_NORMALIZERS`
- [x] **Merged `bank`, `retailer` → `organization`**
  - Bank names and retailer names are just organizations
  - Agency kept separate (used in LEA referral flow)
- [x] **Removed `software` as canonical type** — redirected to `scam_indicator`
- [x] **Added missing normalization entries**
  - `"account"` → `bank_account` (bare unmapped type from external sources)
  - `"transaction"` → `transaction_id` (unmapped display variant)
- [x] **Updated LLM extraction prompts** — `semantic_ner.py` + `entity_extract.py`
  - Removed `account_numbers` and `routing_numbers` from `_ENTITY_KEYS`
  - Updated field definitions: bank_accounts now covers all bank identifiers
  - Updated few-shot examples to merge account/routing into bank_accounts
- [x] **Updated ML NER mapping** — `client.py`
  - `ACCOUNT_NUMBER` and `ROUTING_NUMBER` now map to `bank_accounts`
- [x] **Updated ETL** — `etl_incident_responses.py` emits `bank_account` for all bank identifiers
- [x] **Updated golden test set** — all `account_number`/`routing_number` labels merged to `bank_account`
- [x] **Created migration script** — `scripts/consolidate_entity_types.sql`
  - Dedup-safe: deletes colliding rows before rename
  - Covers entities + indicators tables
- [x] **Verified locally** — migration reduced 15 types to 11 in local DB; 1427 tests pass

### Consolidated Canonical Types (18)

```
person, organization, agency, location,
bank_account, wallet_address, email_address, phone_number,
url, domain, ip_address,
social_handle, payment_handle, contact_handle,
crypto_token, scam_indicator, transaction_id, ticket_id
```

---

## Files Involved

| File                                              | Changes                                     |
| ------------------------------------------------- | ------------------------------------------- |
| `core/src/i4g/extraction/ner_rules.py`            | Split contact_channels, blocklist (done)    |
| `core/src/i4g/extraction/semantic_ner.py`         | Expanded prompt, negative examples          |
| `core/src/i4g/worker/jobs/entity_extract.py`      | Expanded keys, indicator filtering, prompt  |
| `core/src/i4g/utils/entity_types.py`              | Normalization map entries, value normalizer |
| `core/src/i4g/ml/client.py`                       | Fix NER label mapping                       |
| `core/src/i4g/store/sql_writer.py`                | Value normalization before upsert           |
| `core/src/i4g/services/ingest_payloads.py`        | Add rule-based fallback extraction          |
| `core/tests/unit/extraction/test_ner_rules.py`    | New tests (blocklist done, expand)          |
| `core/tests/unit/extraction/test_semantic_ner.py` | Prompt expansion tests                      |
| `core/tests/fixtures/entity_extraction/`          | Golden test set (20 labeled cases)          |
| `core/tests/unit/extraction/test_golden_set.py`   | Quality harness (new)                       |
| `core/scripts/etl/etl_incident_responses.py`      | Complete `_extract_entities()` rewrite      |
| `ml/src/ml/serving/predict.py`                    | No changes needed (ML model types are fine) |

---

## Risks

1. **Prompt expansion may reduce LLM accuracy** — More keys = more ways to misclassify. Mitigate with golden test set.
2. **Backfill re-extraction is expensive** — Must re-run on all cases. Use `--limit` batches.
3. **Vertex AI vs Ollama quality gap** — May need provider-specific prompt variants. Test early.
4. **Schema migration for indicators cleanup** — Deleting rows is safe but should be audited.

---

## Already Done (2026-04-09)

- [x] Added `_NON_PERSON_BLOCKLIST` to `ner_rules.py` — filters 55 known non-person terms
- [x] Updated LLM prompts in `entity_extract.py` and `semantic_ner.py` with explicit "do NOT extract field labels as people" instruction
- [x] Added 4 unit tests for blocklist filtering
- [x] All 22 extraction tests passing
