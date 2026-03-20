# ADR-005: Chroma vs. pgvector for Vector Storage

**Status:** ACCEPTED (under review)  
**Date:** 2025  
**Deciders:** CTO, Core tech lead

---

## Context

The I4G platform uses vector embeddings for hybrid semantic search over case records. Two candidate stores were evaluated at the time of the vector search implementation:

1. **Chroma** — embedded Python vector database, zero-infra for local dev, stores on disk
2. **pgvector** — PostgreSQL extension, uses the same Cloud SQL instance as the rest of the relational data; no separate service

The platform also uses **Vertex AI Search** (Google's managed search service) in cloud environments as a third option, distinct from the local dev vector store choice.

---

## Decision

**Use Chroma for local development and Vertex AI Search for cloud deployments (dev and prod). pgvector is the primary migration candidate when cloud infrastructure costs become a constraint, but no migration date is set.**

The current state:

- `local` → Chroma (local directory, zero infra, fast for development)
- `i4g-dev` / `i4g-prod` → Vertex AI Search (managed, scales with usage, no operational overhead)
- pgvector (via Cloud SQL extension) → configured in `settings.default.toml` as `vector.backend = pgvector` option but not yet deployed in any environment

---

## Alternatives Considered

| Alternative                                 | Why Evaluated                                                                                                                                                       |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Chroma (cloud)                              | Could be deployed as a persistent Cloud Run service; adds another managed service to maintain                                                                       |
| pgvector                                    | Co-located with Cloud SQL — no extra service; lower operational overhead than a separate vector DB service; supports filtered search natively via SQL WHERE clauses |
| FAISS                                       | In-process, high performance for approximate search; but no persistence, no filtering, requires rebuilding index on restart                                         |
| Vertex AI Search only (no local dev option) | Would require cloud connectivity for every local dev session; slow iteration cycle                                                                                  |
| Weaviate / Qdrant / Pinecone                | Evaluated briefly; all require additional managed services or self-hosting; Vertex AI Search has better GCP integration for a GCP-native platform                   |

---

## Current State and Migration Path

Chroma is retained as the local dev default because it requires zero infrastructure: developers can start the application with `uvicorn` and a local SQLite without any cloud setup.

**The planned migration**: When Vertex AI Search costs become a constraint (or if its API changes create friction), migrate cloud environments to pgvector. The migration would:

1. Enable the `pgvector` extension on the Cloud SQL instance
2. Create the `embeddings` table (schema in `core/docs/design/storage.md`)
3. Switch `I4G_VECTOR__BACKEND=pgvector` in Cloud Run job env vars
4. Re-index all existing case embeddings via a one-time `ingest-bootstrap` job run

Dependencies (`langchain-chroma`, `faiss-cpu`) remain in `core/pyproject.toml` until the migration completes.

---

## Consequences

**Positive:**

- Zero-infra local dev with Chroma; no managed service overhead for development
- Vertex AI Search handles production scaling without operational tuning
- pgvector migration path available when needed without changing the application architecture (backend is swappable via settings)

**Negative / trade-offs:**

- Two different vector backends means local dev results may differ from cloud for edge cases in similarity ranking
- `langchain-chroma` is a dependency even in cloud deployments (dead code until local-only builds are separated)
- pgvector migration has not been tested end-to-end; the migration script and re-indexing procedure are not yet documented

> ⚠️ **This ADR is under review.** If the pgvector migration has been completed since March 2026, update this status to SUPERSEDED and create ADR-006 documenting the completed migration.

---

## Related Decisions

- ADR-001: GCP migration — Vertex AI Search is the direct GCP alternative to Azure AI Search
