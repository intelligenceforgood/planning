# Gap Analysis

> **Date**: November 25, 2025
> **Scope**: `dtp` (Legacy) vs. `proto` (Current) vs. `prd_production.md` (Target)

## 1. Critical Functional Gaps

### 1.1. Account List Extraction (Bank/Crypto/Payments)
- **Legacy (`dtp`)**: `IFG-AzureFunctions/account_list_extract` uses LLMs to parse unstructured text and extract specific entities (IBANs, BTC addresses, etc.).
- **Current (`proto`)**: **MISSING**. Confirmed by architect review.
- **Action**: Port `function_app.py` logic from `dtp` to `i4g.ingestion`.

### 1.2. Account List Client (Reporting)
- **Legacy (`dtp`)**: `IFG-AzureFunctions/account_list_extract_client` calls the extract API, generates PDFs/XLSX, and uploads to Google Drive.
- **Current (`proto`)**: **MISSING**.
- **Action**: Port this logic. Decide if it belongs in `i4g.reports` (Cloud Run Job) or the Analyst Console.

### 1.2. Dual Extraction (Search & SQL)
- **Requirement**: Ingestion must populate **Vertex AI Search** (for "vague" queries) AND **Cloud SQL** (for "exact" queries).
- **Current (`proto`)**:
    - Uses `Chroma` (Local) or `Firestore` (Simple).
    - No SQL database configured.
    - No "Dual Write" logic in the worker.
- **Action**: Provision Cloud SQL (Postgres) via Terraform and update the ingestion worker.

### 1.3. Report Generation
- **Legacy**: Azure Function generates PDFs.
- **Current**: `src/i4g/reports/generator.py` exists but needs validation against the latest templates and LEO requirements.

## 2. Architectural Gaps

### 2.1. Search Infrastructure
- **Target**: Vertex AI Search + Cloud SQL.
- **Current**: Local Chroma + Firestore.
- **Gap**: Need to switch Terraform to provision the production search resources and update the application config (`i4g.settings`) to use them.

### 2.2. Authentication
- **Target**: IAP + OAuth (Google).
- **Current**: "Unauthed" script is being used for testing. IAP is configured in Terraform but currently bypassed.
- **Action**: Verify IAP flow works end-to-end before production.

### 2.3. PII Protection (FR-1)
- **Target**: Tokenization of all PII upon upload.
- **Current**: Basic PII masking exists, but full "Vault" architecture needs audit against PRD requirements.

## 3. Documentation Gaps
- `proto/docs/architecture.md` describes the *current* state well but misses the "Dual Extraction" intent.
- `planning/future_architecture.md` captures the intent but is disconnected from the codebase.
- **Action**: Merge these into a single, living Architecture document in `proto/docs/`.
