# ADR-004: PII Vault Design — Fernet Encryption + Audit-Logged Decryption

**Status:** ACCEPTED  
**Date:** March 2026  
**Deciders:** CTO, Chief Architect, Core tech lead

---

## Context

The I4G platform ingests victim intake submissions that include sensitive contact fields: reporter name, email, phone number, and contact handles. These fields are necessary for law enforcement follow-up but constitute PII that must be protected at rest and controlled at access time.

The prior design used a "TokenVault" / "VaultService" pattern with a more complex tokenization scheme. A sprint in March 2026 simplified this to Fernet symmetric encryption after determining the prior design was over-engineered for the access patterns and team size.

Key requirements:

- PII fields must be encrypted at rest in Cloud SQL
- Decryption must be logged — every access creates an immutable audit record
- Dual-approval must be enforced for production decryption (documented in the Detokenization SOP)
- The encryption key must be stored in Secret Manager, not in the database
- Plaintext PII must never appear in case text, search indexes, or vector embeddings

---

## Decision

**Use Fernet symmetric encryption (from Python's `cryptography` library) for PII fields in the `intakes` table. Store the Fernet key in Google Secret Manager under `crypto-pii-key`. Log every decryption event to the `audit_log` table.**

Encrypted fields in the `intakes` table:

- `reporter_name`
- `contact_email`
- `contact_phone`
- `contact_handle`

Not encrypted (evidence, not victim PII):

- `entities.value`
- `cases.text` / `cases.summary`

Additional protection for case text:

- The `ingest-bootstrap` job runs `redact_victim_contact()` before storing case text, replacing victim email/phone with `[VICTIM_EMAIL]` / `[VICTIM_PHONE]` markers

Decryption path:

- `IntakeStore.get_contact(intake_id, actor)` — the only authorized decryption entry point
- `GET /intakes/{id}/contact` endpoint — requires valid auth, creates audit log entry with actor, intake_id, action (`decrypt_contact`), outcome, and timestamp
- Audit log retained ≥ 400 days

The full operational procedure is in `core/docs/policies/detokenization_sop.md`.

---

## Alternatives Considered

| Alternative                                             | Why Rejected                                                                                                                                                                                   |
| ------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| TokenVault / VaultService (prior design)                | Over-engineered for actual access patterns; involved key hierarchy, token generation, and lookup tables that added complexity without proportionate security benefit for a small-team platform |
| Google Cloud KMS envelope encryption                    | More complex key management; KMS call required for every decrypt operation adds latency; Fernet + Secret Manager achieves equivalent protection for this threat model                          |
| Asymmetric encryption (RSA/ECIES)                       | No asymmetric benefit when the same service that encrypts also decrypts; Fernet (symmetric) is simpler and faster without losing security                                                      |
| Database-level encryption (Transparent Data Encryption) | Protects disk-at-rest but not application-level access control — a compromised query would still return plaintext; application-level encryption provides defense-in-depth                      |
| No encryption (access control only)                     | IAM and RBAC alone don't protect against SQL injection, rogue admin queries, or database backup access; encryption provides defense-in-depth                                                   |

---

## Consequences

**Positive:**

- Simple implementation: `Fernet.encrypt()` / `Fernet.decrypt()` — no key hierarchy, no token tables
- Fernet keys rotate via Secret Manager without changing the database schema
- Audit log provides compliance evidence for subpoena handling and privacy reviews
- `redact_victim_contact()` ensures PII never enters the search index — no leakage via vector similarity search
- The `contact_decrypt_alert_threshold` setting enables operational alerting on high-frequency decryption

**Negative / trade-offs:**

- Encrypted fields cannot be searched or sorted in SQL (must decrypt first, compare in application code)
- Key rotation requires re-encrypting all existing encrypted fields (a migration script is needed when keys rotate — no ad-hoc key rotation)
- Fernet uses authenticated encryption (GCM mode) — a corrupt ciphertext raises an exception; must handle `InvalidToken` gracefully at the API layer

---

## Related Decisions

- ADR-001: GCP migration — Secret Manager for key storage is a GCP-specific choice
