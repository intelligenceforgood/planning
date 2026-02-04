# Task: Bootstrap Consolidation (Seed Script Parity)

The goal of this task is to integrate the ad-hoc `core/scripts/seed_cases.py` script into the standard `i4g bootstrap` process to ensure environment parity and data consistency.

## Context
During the "Case Integration" phase, a standalone script (`seed_cases.py`) was created to populate `ReviewStore` with sample data for UI development. This script is now an outlier:
- It runs outside the standard `i4g bootstrap` command.
- It creates "orphan" cases that may not link properly to artifacts (files/blobs) in the storage service.
- It risks diverging from the data sets used in `local`, `dev`, and CI environments.

## Objectives
1.  **Review Bootstrap Design**:
    - Analyze `core/docs/cookbooks/bootstrap_environments.md`.
    - Analyze `core/docs/prepare_bootstrap_bundles.md`.

2.  **Merge Logic**:
    - Refactor the case generation logic from `seed_cases.py` into the standard bootstrap data generators/loaders.
    - Ensure it works with existing bootstrap bundles (e.g., standard demo data).

3.  **Fix Data Integrity**:
    - Ensure generated cases properly reference artifacts (documents, images) in the `StructuredStore` or `StorageService`.
    - Eliminate "orphan" cases that exist in SQLite but lack corresponding binary assets.

4.  **Verification**:
    - Verify that running `i4g bootstrap local reset` (or equivalent) populates the Case Workspace correctly without needing a separate script.
    - Confirm parity between local dev and other environments.

## References
- `core/scripts/seed_cases.py` (Source logic to be merged)
- `core/src/i4g/services/bootstrap.py` (Likely target for integration)
