# Architecture Decision Records (ADRs)

This directory contains the Architecture Decision Records for the I4G Platform. ADRs capture significant architectural choices: the context that made them necessary, the alternatives considered, the decision made, and its consequences.

## What Makes a Decision ADR-Worthy?

Not every design choice needs an ADR. Write one when:

- The decision is hard to reverse or has broad consequences
- Reasonable engineers could disagree — you want to record _why_ this path was chosen
- Future engineers will wonder "why didn't they just do X?" — and the answer matters
- The decision closes off alternatives that would otherwise seem attractive

## Format

Each ADR follows this structure (see any existing ADR for a working example):

```
Title: ADR-NNN: [Decision title]
Status: [PROPOSED | ACCEPTED | SUPERSEDED by ADR-NNN | DEPRECATED]
Date: YYYY-MM-DD
```

Sections: Context → Decision → Alternatives Considered → Consequences → Related Decisions

## Index

| ADR                                          | Title                                                         | Status   | Date                |
| -------------------------------------------- | ------------------------------------------------------------- | -------- | ------------------- |
| [ADR-001](adr-001-azure-to-gcp-migration.md) | Migration from Azure to GCP                                   | ACCEPTED | 2025                |
| [ADR-002](adr-002-fastapi-pydantic-v2.md)    | FastAPI + Pydantic v2 as core API framework                   | ACCEPTED | 2025                |
| [ADR-003](adr-003-ssi-separate-service.md)   | SSI as a separate service, not embedded in core               | ACCEPTED | 2025                |
| [ADR-004](adr-004-pii-vault-fernet.md)       | PII vault design: Fernet encryption + audit-logged decryption | ACCEPTED | 2026-03             |
| [ADR-005](adr-005-chroma-vs-pgvector.md)     | Chroma vs. pgvector for vector storage                        | ACCEPTED | 2025 (under review) |

## Adding a New ADR

1. Pick the next sequence number.
2. Copy the template from the last ADR in the index.
3. Fill in all sections.
4. Update the index table above.
5. If the new ADR supersedes an existing one, update the old ADR's status.
