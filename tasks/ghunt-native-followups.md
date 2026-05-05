# Plan: GHunt Native Follow-ups

## 1. Clarify Scope

- **Objective:** Address unresolved tasks and architecture constraints identified during the initial GHunt Native implementation.
- **Outcome:** Complete the database schema updates in `core/` and resolve the browser lifecycle state issue for `GoogleAuthManager` in `orchestrator.py`.

## 2. Identify Affected Repos

- **`ssi/` (Scam Site Investigator):** `orchestrator.py` and `auth.py` to handle cookie persistence or browser lifecycle management.
- **`core/`:** Update `passive_result` JSONB/Pydantic structures to accept the new Google OSINT dict in `core/src/i4g/store/sql.py`.

## 3. Check Architecture

- **Auth Persistence:** `GoogleAuthManager(browser=...)` expects an active `ZenBrowserManager`. Since `orchestrator.py` closes the browser after Phase 2 (capture), we either need to extract and pass the cookies directly, or keep the browser alive until the OSINT phase is completed.

## 4. Break Into Steps

1. **Resolve Browser State for OSINT**: Update `orchestrator.py` to correctly preserve `ZenBrowserManager` across phases or extract the necessary authentication cookies from the sandbox before it closes and pass them into `GoogleAuthManager` securely.
   - Target: `@file:ssi/src/ssi/investigator/orchestrator.py`
   - Target: `@file:ssi/src/ssi/osint/google/auth.py`
2. **Database Schema Updates**: Update `passive_result` structures to accept the new Google OSINT dictionary (Gaia IDs, probable locations, activated services) for backward compatibility.
   - Target: `@file:core/src/i4g/store/sql.py`

## 5. Identify Risks

- Keeping the browser alive longer could increase memory consumption per worker.

## 6. Track with Todos

- [ ] Step 1: Resolve Browser State for OSINT
- [ ] Step 2: Database Schema Updates
