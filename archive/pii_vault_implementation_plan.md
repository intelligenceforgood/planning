# PII Vault Implementation Plan

**Status:** Draft
**Based on:** `core/docs/design/pii_vault.md`
**Target Phase:** Next Phase (Post-Assessment)

This document outlines the step-by-step implementation plan for the PII Vault, a critical security component for tokenizing sensitive data before it enters the main storage and search systems.

## Phase 1: Infrastructure & Security Foundation
*Objective: Provision the secure enclave (Vault) resources using Terraform.*

### 1.1. Vault Project / Stack Setup
- [x] **Define Stack:** Create a new Terraform stack `infra/environments/pii-vault/{dev,prod}`.
- [x] **State Bucket:** Bootstrap the state bucket for the vault stack.
- [x] **Service APIs:** Enable required APIs (Secret Manager, KMS, Cloud Run, SQL Admin).

### 1.2. Key Management Service (KMS)
- [x] **Key Ring:** Create `i4g-vault-ring` in the vault project.
- [x] **Encryption Key:** Create `i4g-vault-encrypt` (HSM-backed recommended for Prod, Software for Dev).
- [x] **IAM:** Grant `roles/cloudkms.cryptoKeyEncrypterDecrypter` to the Vault Service SA.

### 1.3. Secret Manager
- [x] **Pepper Secret:** Create `tokenization-pepper` container (no versions in TF).
- [x] **App Key Secret:** Create `pii-tokenization-key` container (no versions in TF).
- [x] **Manual Seeding:** Document the process for seeding the initial random pepper and key versions via `gcloud`.

### 1.4. Database (Vault DB)
- [x] **Instance:** Provision a Cloud SQL (PostgreSQL) instance for the Vault.
- [x] **Isolation:** Ensure this instance is *distinct* from the main application DB.
- [x] **Networking:** Configure Private Service Connect or VPC Peering for secure access from Cloud Run.

## Phase 2: Core Library (`i4g.pii`)
*Objective: Implement the deterministic tokenization logic in the Core repo.*

### 2.1. Normalization & Validation
- [x] **Module Structure:** Create `src/i4g/pii/normalization.py`.
- [x] **Validators:** Implement validators for each prefix type (`EID`, `PHN`, `TIN`, etc.) defined in the design.
- [x] **Normalizers:** Implement canonicalization logic (e.g., lowercase emails, E.164 phones).

### 2.2. Tokenization Engine
- [x] **HMAC Logic:** Implement `HMAC-SHA256(value + prefix + versioned_pepper)`.
- [x] **Token Formatting:** Implement the `AAA-XXXXXXXX` format generation.
- [x] **Collision Handling:** Design the logic for detecting and handling 8-char suffix collisions (append disambiguator).

### 2.3. Encryption Helpers
- [x] **Envelope Encryption:** Implement helpers to encrypt the raw PII using the `pii-tokenization-key` (or KMS) before storing in the Vault DB.

## Phase 3: Vault Service & Storage
*Objective: Build the API that manages the mapping between Tokens and Raw PII.*

### 3.1. Database Schema
- [x] **Migration:** Create Alembic migrations for the Vault DB.
    - Table: `token_map`
        - `token` (PK, Indexed)
        - `prefix`
        - `encrypted_blob` (The raw PII, encrypted)
        - `pepper_version`
        - `created_at`
        - `hash_digest` (Full SHA256 for collision checks)

### 3.2. Vault API (FastAPI)
- [x] **Service:** Create a new FastAPI app (or router mounted on a separate port/service) for Vault operations.
- [x] **Endpoint: `/tokenize`:**
    - Input: List of `{type, value}`.
    - Logic: Normalize -> Check DB for existing hash -> Return existing token OR Generate new -> Encrypt -> Store -> Return new token.
- [x] **Endpoint: `/detokenize`:**
    - Input: List of `tokens`.
    - Logic: **Strict Audit Logging** -> Lookup token -> Decrypt blob -> Return raw value.
    - **Access Control:** This endpoint requires high-privilege scopes (e.g., `pii:read`).

### 3.3. Audit Logging
- [x] **Immutable Log:** Implement a separate audit log (BigQuery or append-only SQL table) for *every* detokenization request.
- [x] **Context:** Capture `who`, `when`, `reason`, and `count` of records accessed.

## Phase 4: Integration & Migration
*Objective: Switch the main application to use the Vault.*

### 4.1. Ingestion Pipeline Update
- [x] **Refactor:** Update `i4g.ingestion` to call the Vault Service (or library if running in trusted context) for all PII fields.
- [x] **Replacement:** Ensure only tokens are written to the Main DB and Vector Store.

### 4.2. Review API Update
- [x] **Display:** Update the UI/API to show tokens by default.
- [x] **Reveal Flow:** Implement the "Reveal PII" button flow in the UI that calls the `/detokenize` endpoint (with justification).

### 4.3. Backfill (If applicable)
- [x] **Script:** Create a job to scan existing records, tokenize PII, and update the records. *Note: Since we are pre-production/prototype, a wipe-and-reload is preferred over complex migration.*

## Phase 5: Verification & Compliance
*Objective: Prove the system works and is secure.*

### 5.1. Smoke Tests
- [x] **Round Trip:** Verify `Input -> Tokenize -> Store -> Detokenize -> Output` matches exactly.
- [x] **Determinism:** Verify the same input produces the same token across multiple calls.

### 5.2. Security Review
- [x] **Access Review:** Verify only the Vault Service SA has access to the Pepper and Encryption Keys.
- [x] **Audit Check:** Verify detokenization events are correctly logged.

## Dependencies
- `core/docs/design/pii_vault.md` (Source of Truth)
- `core/docs/compliance.md` (Retention & Policy)
