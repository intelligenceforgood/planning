# Plan: GHunt Native Replacement

## 1. Clarify Scope

- **Objective:** Replace the external GHunt dependency with native Google OSINT scrapers within the SSI service.
- **Outcome:** Eliminate external credentials overhead, leverage the existing `zendriver` for sandbox authentication, and natively persist Google identity, active services, and location data to the core platform.

## 2. Identify Affected Repos

- **`ssi/` (Scam Site Investigator):** Requires a new `osint/google` module, browser automation logic for intercepting Google auth, API scraper clients, and integration into the investigation orchestrator.
- **`core/`:** Minor database schema and typing adjustments to store newly structured Google OSINT (Gaia IDs, probable locations, activated services).

## 3. Check Architecture

- **Worker Patterns:** Module will be triggered natively within the existing SSI worker lifecycle.
- **Store Patterns:** Will write to Core using existing evidence ingestion methods (`ScanStore.create_case_record()`).
- **Resilience:** All API clients must wrap calls in the native `@with_retries` decorator.
- **Auth:** Relies on `zendriver` (Playwright) to intercept `SAPISID` and `authuser` cookies instead of managing static tokens.

## 4. Break Into Steps

**Phase 1: Foundation**

1. **Setup Google Module**: Create the new `osint/google` package and configure shared endpoints/constants.
   - Target: `@folder:ssi/src/ssi/osint/google/`
2. **Sandboxed Authentication**: Implement Playwright cookie extraction and `sapisidhash` header generation using the internal browser.
   - Target: `@file:ssi/src/ssi/osint/google/auth.py`
   - Target: `@folder:ssi/src/ssi/browser/` (if zendriver interactions need exposing)

**Phase 2: OSINT Scrapers** 3. **Identity Resolution**: Implement HTTP clients to resolve Email -> Gaia ID -> Profile.

- Target: `@file:ssi/src/ssi/osint/google/people.py`

4. **Maps & Location Scraper**: Implement parser for location history protobufs to extract geographic confidence scores.
   - Target: `@file:ssi/src/ssi/osint/google/maps.py`
5. **Drive File Exposure**: Implement endpoints to scrape internal Drive file metadata and comments.
   - Target: `@file:ssi/src/ssi/osint/google/drive.py`

**Phase 3: Data & Pipeline Updates** 6. **Database Schema Updates**: Update `passive_result` JSONB/Pydantic structures to accept the new Google OSINT dict.

- Target: `@file:core/src/i4g/store/sql.py`

7. **Entity & PII Mapping**: Route newly discovered Gaia IDs to indicators and secondary emails to the PII vault.
   - Target: `@file:ssi/src/ssi/evidence/mapping.py`
8. **Investigation Orchestrator Wiring**: Trigger `people.py` / `maps.py` when an email is scraped, and `drive.py` when a Drive link is extracted.
   - Target: `@file:ssi/src/ssi/investigator/orchestrator.py`

## 5. Identify Risks

- **Undocumented APIs:** Google's internal APIs (Maps protobufs, People v2) can change without notice. Code must fail cleanly without halting the broader investigation.
- **Anti-Bot Detection:** Scraping could get `zendriver` flagged by Google, requiring future proxy rotation strategies.
- **Schema Compatibility:** Adding the `google_osint` block to the JSONB payload must be backward-
compatible with older `site_scans` records.

## 6. Track with Todos

- [x] Step 1: Setup Google Module
- [x] Step 2: Sandboxed Authentication
- [x] Step 3: Identity Resolution
- [x] Step 4: Maps & Location Scraper
- [x] Step 5: Drive File Exposure
- [ ] Step 6: Database Schema Updates
- [x] Step 7: Entity & PII Mapping
- [x] Step 8: Investigation Orchestrator Wiring

## 7. Decide the Handoff

**Decision: Use `/handoff` / Agent Mode Batch Sprints**

_Reasoning:_ This spans 8 distinct steps, touches multiple repositories (`ssi/` and `core/`), updates database schemas, and integrates with complex underlying tools (`zendriver` and `orchestrator.py`). The skip-threshold is safely exceeded. The work should be executed with Agent Mode **ON**, working iteratively through the tracked phases while heavily scoping context per file.
