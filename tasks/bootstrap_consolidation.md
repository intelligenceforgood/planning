# Task: Bootstrap Consolidation (Seed Script Parity)

The goal of this task is to integrate the ad-hoc `core/scripts/seed_cases.py` script into the standard `i4g bootstrap` process to ensure environment parity and data consistency.

## Context
During the "Case Integration" phase, a standalone script (`seed_cases.py`) was created to populate `ReviewStore` with sample data for UI development. This script is now an outlier:
- It runs outside the standard `i4g bootstrap` command.
- It creates "orphan" cases that may not link properly to artifacts (files/blobs) in the storage service.
- It risks diverging from the data sets used in `local`, `dev`, and CI environments.

## Objectives
1.  **Review Bootstrap Design**: [Completed]
    - Analyze `core/docs/cookbooks/bootstrap_environments.md`.
    - Analyze `core/docs/prepare_bootstrap_bundles.md`.

2.  **Merge Logic**: [Completed]
    - Refactor the case generation logic from `seed_cases.py` into the standard bootstrap data generators/loaders (`seed.py`, `local.py`).
    - Ensure it works with existing bootstrap bundles (e.g., standard demo data).
    - **Deleted**: `core/scripts/seed_cases.py`

3.  **Fix Data Integrity**: [Completed - Local]
    - Ensure generated cases properly reference artifacts (documents, images) in the `StructuredStore` or `StorageService`.
    - Added valid PDF/PNG fixtures to `core/fixtures/mock` to ensure properly rendering artifacts.
    - Updated Backend (`app.py`) to serve static artifacts from `/artifacts`.
    - Updated UI Proxy to route artifact requests correctly.

4.  **Verification**:
    - [x] Verify that running `i4g bootstrap local reset` (or equivalent) populates the Case Workspace correctly without needing a separate script.
    - [x] Verify UI loads Cases and details without Zod errors.
    - [ ] Confirm parity between local dev and other environments (Next Step: Dev Bootstrap).

## Next Steps
- Apply bootstrap seeding logic to `dev` environment (`container-job` or `cloud-run-job` context).
- Ensure fixture files are correctly handled in the cloud build process.

## References
- `core/scripts/seed_cases.py` (Source logic to be merged)
- `core/src/i4g/services/bootstrap.py` (Likely target for integration)
The 