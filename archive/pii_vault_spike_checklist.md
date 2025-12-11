# PII Vault Spike Checklist (Dec 2025)

Use this checklist to stand up dedicated vault projects and wire least-privileged access from app runtimes.

## Projects & State
- [x] Create `i4g-pii-vault-dev` and `i4g-pii-vault-prod` projects (or agreed naming).
- [x] Configure Terraform backends/state buckets for the vault roots (dev/prod) and document init commands.

## KMS & Secrets
- [x] Create KMS key ring/keys per env with rotation policy; record resource IDs for consumers.
- [x] Seed baseline Secret Manager entries (placeholders OK) and wire KMS protection where required (tokenization key added).
- [x] Document rotation/runbook (owners, cadence, break-glass).
	- Owners: security/infra (primary), backend TL (approver); break-glass held by SRE on-call with escalation to security lead.
	- Cadence: rotate vault KMS keys quarterly; rotate tokenization pepper version every 6 months or on incident; Secret Manager versions rotated at least quarterly or on leak suspicion.
	- Procedure: create new key version (do not destroy previous), update services to use new versioned pepper/secret, rewrap secrets if required, monitor detokenization success, then schedule old-key disablement after 30 days.
	- Break-glass: use pre-approved on-call with dual approval; log ticket + audit entries; revert to prior version if service health fails; rotate again after containment.

- [x] Approve `AAA-XXXXXXXX` token format (3-char prefix + 8-char hex) and publish prefix registry for a broad PII set: identity/contact (email, name, phone, address, DOB), gov IDs (SSN/TIN/national, passport/driver, student, employer, employer tax, student transcript, generic GOV), financial (card, bank, IBAN, routing/ABA, SWIFT/BIC, ACH), crypto (BTC, ETH, generic wallet), network/device (IP, ASN, MAC, device/advertising ID, browser/device fingerprint, cookie/session), health/insurance/medical (member ID, MRN, national health ID), biometric template hashes, vehicle (VIN, license plate), location (lat/long, place IDs), document/record IDs, and `UNK` fallback. Canonical catalog lives in `proto/docs/pii_vault.md`.
- [x] Define normalization + validation rules per prefix (e.g., emails lowercase, cards Luhn, IBAN checksum, SWIFT length, VIN check digit, geo rounding, cookie/fingerprint length checks) and codify as shared library with tests. See `proto/docs/pii_vault.md#normalization--validation` for the per-prefix rules to implement.
- [x] Choose deterministic HMAC scheme (KMS-wrapped salt/pepper, versioned, shared across environments) so identical PII maps to stable tokens everywhere while allowing rotation. See `proto/docs/pii_vault.md#hmac-scheme--rotation` for algorithm (HMAC-SHA256 with versioned KMS-wrapped pepper), collision handling, access controls, and rotation playbook.

## Schema Flexibility
- [x] Add a prefix registry table (code, name, description, validation rules, status) so new prefixes land without migrations; tokens table references the registry. See `proto/docs/pii_vault.md#prefix-registry--config` for table sketch and rule storage.
- [x] Ensure detectors/tokenizers read prefix config from the registry so deployments pick up new types via config rather than code changes when possible. Detectors should load registry rules at startup and prefer config-driven validation/disambiguation with `UNK` fallback on low confidence.

## Detection & Tokenization Pipeline
- [x] Implement PII detectors for structured ingestion fields plus OCR text from PDFs/screenshots; map detected values to prefixes and normalize before tokenization. See `proto/docs/pii_vault.md#detection--tokenization-pipeline` for structured/OCR flows and disambiguation rules.
- [x] Ensure ingestion writes only tokens to SQL/Vertex while original PII routes to the vault store; add rollback guards when detectors are uncertain. Routing and guardrails documented in `proto/docs/pii_vault.md#detection--tokenization-pipeline`.
- [x] Add sampling harness to measure false positives/negatives across common PII types and iteratively tune detectors. Sampling/metrics expectations captured in the pipeline section of the design doc.

## Vault Storage & Detokenization
- [x] Design vault data model: token, encrypted canonical value, type/prefix, case ID, artifact/file ref, hash of normalized value, timestamps, and retention markers. See `proto/docs/pii_vault.md#vault-data-model` for field list.
- [x] Build detokenization service with audit trails, dual-approval/subpoena workflow, and KMS-gated access; include rate limits and alerting on access. See `proto/docs/pii_vault.md#detokenization-service` for flow and controls.
- [x] Define retention, purge, and re-key procedures (rotation of HMAC salt/pepper and data re-encryption), with automation plan. See `proto/docs/pii_vault.md#retention-purge-and-re-key`.

## Artifact Handling
- [x] Store original PDFs/screenshots/text extracts in vault project storage with integrity hashes and pointers from case records; shard paths by artifact type then content hash (e.g., `pdf/ab/cd/<sha256>.pdf`) to avoid oversized folders regardless of PII density per file.
- [x] Add background job to verify hashes and enforce retention/lifecycle policies on vault artifacts; default retention is indefinite unless legal requires purge.

## Cross-Project Access
- [x] Grant app runtime SAs (dev/prod) secret accessor + cryptoKeyEncrypterDecrypter via WIF (resource and var created; pass app_service_accounts to enable).
- [x] Add a small verifier (script or test) that fetches a vault secret using the app SA to validate bindings.

## App Integration
- [x] Map Cloud Run env vars and tokenization salts to vault secrets; remove duplicated secrets from app projects.
- [x] Add regression/tests to ensure missing secret access fails loud with clear guidance.
- [x] Smoke: Cloud Run dev reads a vault-secret value and exercises tokenization/detokenization round trip; confirm prod plan before promotion.

## Observability & Audit
- [x] Emit structured logs/metrics for tokenization coverage, detector confidence, detokenization attempts, and failures; wire alerts for unusual access patterns. Metrics helper lives in `src/i4g/pii/observability.py` with optional instrumentation on `tokenize_text`/`tokenize_fields`.

## CI / Automation
- [x] Add Terraform fmt/plan coverage for new vault roots; set required GH Action vars (project/state bucket names). Added to `infra/.github/workflows/terraform-dev.yml` with `TF_GCP_PII_VAULT_PROJECT_ID`.

## Documentation
- [x] Update `infra/README.md` (vault layout, init, apply).
- [x] Update `docs/config/` (env-var table) and any app runbooks that reference secret sources.
- [x] Document subpoena/detokenization SOP (approvals, logging, retention) and publish in analyst/legal runbooks. See `docs/policies/detokenization_sop.md`.
