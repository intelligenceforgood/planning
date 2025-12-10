# PII Vault Spike Checklist (Dec 2025)

Use this checklist to stand up dedicated vault projects and wire least-privileged access from app runtimes.

## Projects & State
- [x] Create `i4g-pii-vault-dev` and `i4g-pii-vault-prod` projects (or agreed naming).
- [x] Configure Terraform backends/state buckets for the vault roots (dev/prod) and document init commands.

## KMS & Secrets
- [x] Create KMS key ring/keys per env with rotation policy; record resource IDs for consumers.
- [x] Seed baseline Secret Manager entries (placeholders OK) and wire KMS protection where required (tokenization key added).
- [ ] Document rotation/runbook (owners, cadence, break-glass).

- [ ] Approve `AAA-XXXXXXXX` token format (3-char prefix + 8-char hex) and publish prefix registry for a broad PII set: identity/contact (email, name, phone, address, DOB), gov IDs (SSN/TIN/national, passport/driver, student, employer, employer tax, student transcript, generic GOV), financial (card, bank, IBAN, routing/ABA, SWIFT/BIC, ACH), crypto (BTC, ETH, generic wallet), network/device (IP, ASN, MAC, device/advertising ID, browser/device fingerprint, cookie/session), health/insurance/medical (member ID, MRN, national health ID), biometric template hashes, vehicle (VIN, license plate), location (lat/long, place IDs), document/record IDs, and `UNK` fallback.
- [ ] Define normalization + validation rules per prefix (e.g., emails lowercase, cards Luhn, IBAN checksum, SWIFT length, VIN check digit, geo rounding, cookie/fingerprint length checks) and codify as shared library with tests.
- [ ] Choose deterministic HMAC scheme (KMS-wrapped salt/pepper, versioned, shared across environments) so identical PII maps to stable tokens everywhere while allowing rotation.

## Schema Flexibility
- [ ] Add a prefix registry table (code, name, description, validation rules, status) so new prefixes land without migrations; tokens table references the registry.
- [ ] Ensure detectors/tokenizers read prefix config from the registry so deployments pick up new types via config rather than code changes when possible.

## Detection & Tokenization Pipeline
- [ ] Implement PII detectors for structured ingestion fields plus OCR text from PDFs/screenshots; map detected values to prefixes and normalize before tokenization.
- [ ] Ensure ingestion writes only tokens to SQL/Vertex while original PII routes to the vault store; add rollback guards when detectors are uncertain.
- [ ] Add sampling harness to measure false positives/negatives across common PII types and iteratively tune detectors.

## Vault Storage & Detokenization
- [ ] Design vault data model: token, encrypted canonical value, type/prefix, case ID, artifact/file ref, hash of normalized value, timestamps, and retention markers.
- [ ] Build detokenization service with audit trails, dual-approval/subpoena workflow, and KMS-gated access; include rate limits and alerting on access.
- [ ] Define retention, purge, and re-key procedures (rotation of HMAC salt/pepper and data re-encryption), with automation plan.

## Artifact Handling
- [ ] Store original PDFs/screenshots/text extracts in vault project storage with integrity hashes and pointers from case records; shard paths by artifact type then content hash (e.g., `pdf/ab/cd/<sha256>.pdf`) to avoid oversized folders regardless of PII density per file.
- [ ] Add background job to verify hashes and enforce retention/lifecycle policies on vault artifacts; default retention is indefinite unless legal requires purge.

## Cross-Project Access
- [x] Grant app runtime SAs (dev/prod) secret accessor + cryptoKeyEncrypterDecrypter via WIF (resource and var created; pass app_service_accounts to enable).
- [ ] Add a small verifier (script or test) that fetches a vault secret using the app SA to validate bindings.

## App Integration
- [ ] Map Cloud Run env vars and tokenization salts to vault secrets; remove duplicated secrets from app projects.
- [ ] Add regression/tests to ensure missing secret access fails loud with clear guidance.
- [ ] Smoke: Cloud Run dev reads a vault-secret value and exercises tokenization/detokenization round trip; confirm prod plan before promotion.

## Observability & Audit
- [ ] Emit structured logs/metrics for tokenization coverage, detector confidence, detokenization attempts, and failures; wire alerts for unusual access patterns.

## CI / Automation
- [ ] Add Terraform fmt/plan coverage for new vault roots; set required GH Action vars (project/state bucket names).

## Documentation
- [ ] Update `infra/README.md` (vault layout, init, apply).
- [ ] Update `docs/config/` (env-var table) and any app runbooks that reference secret sources.
- [ ] Document subpoena/detokenization SOP (approvals, logging, retention) and publish in analyst/legal runbooks.
