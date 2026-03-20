# ADR-001: Migration from Azure to GCP

**Status:** ACCEPTED  
**Date:** 2025  
**Deciders:** CTO, Chief Architect

---

## Context

The I4G platform began as a set of Azure scripts and services, using Azure Blob Storage, Azure AI Search (formerly Cognitive Search), and Azure-hosted infrastructure. As the platform grew from a prototype into a production system, several factors drove a platform migration decision:

- The team's primary cloud expertise was shifting toward GCP
- Google Cloud nonprofit credits provided a more favorable cost structure for a mission-driven organization
- Vertex AI (Gemini, Vertex AI Search) offered tighter LLM integration than the Azure AI stack
- Cloud Run's serverless model aligned better with the platform's usage pattern (spiky, low-base load) than Azure's always-on services
- Google IAP offered a simpler zero-trust front-door than the equivalent Azure AD B2C setup

The prototype also contained multiple non-reversible design choices that warranted a clean rebuild.

---

## Decision

**Migrate all infrastructure and services from Azure to Google Cloud Platform.**

The migration was implemented in phases: infrastructure first (Cloud SQL, GCS, Cloud Run), then vector search (Azure AI Search → Vertex AI Search → Chroma for local dev), then identity (Azure AD → Google IAP + OIDC).

The Azure data migration path was preserved in `core/docs/cookbooks/azure_legacy_data.md` for the transition period. That cookbook is now archived as the migration is complete.

---

## Alternatives Considered

| Alternative                                   | Why Rejected                                                                                                                       |
| --------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Stay on Azure                                 | Increasing costs, weaker LLM integration with target models (Gemini), less favorable nonprofit pricing                             |
| AWS                                           | No existing team expertise; would require rebuilding all integrations from scratch                                                 |
| Hybrid (Azure for some services, GCP for LLM) | Increased operational complexity; cross-cloud networking and auth overhead; not worth for a small team                             |
| Self-hosted / on-premise                      | Operational burden too high for an organization without full-time SRE; Cloud Run "serverless" reduces ops to near-zero at low load |

---

## Consequences

**Positive:**

- All infrastructure in a single cloud simplifies IAM, networking, and observability
- Vertex AI / Gemini integration is first-class (no cross-cloud calls)
- Cloud Run + Cloud Scheduler eliminates persistent server management
- Workload Identity Federation eliminates long-lived service account keys
- Nonprofit credits significantly reduce operating costs

**Negative / trade-offs:**

- Legacy Azure data required a migration script (now archived)
- Some dependencies (`azure-identity`, `azure-search-documents`) remain in `core/pyproject.toml` for legacy data access — these can be removed once all legacy data is migrated
- Google IAP requires a GCP project-level OAuth consent screen setup that is manual (documented in `infra/docs/iap_manual.md`)

---

## Related Decisions

- ADR-002: FastAPI + Pydantic v2 (chosen at same time as GCP migration)
- ADR-005: Chroma vs. pgvector (vector store choice made post-migration)
