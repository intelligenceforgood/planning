# Milestone 2 – Target GCP Architecture

_Last updated: 11 Nov 2025_

Use this outline to track prep and execution tasks for Milestone 2 (designing the future-state i4g architecture on GCP).

## 1. Prep & Inputs
- Re-read `planning/migration_plan.md` Milestone 2 goals.
- Refresh `planning/future_architecture.md` and note sections that need deeper detail (data flows, IAM, component choices).
- Inventory current DT-IFG Azure components (functions, storage accounts, SQL schema) from `planning/system_review.md` for reference.
- Collect existing diagrams (if any) and decide whether to redraw in Excalidraw, CloudCraft, or Mermaid.

## 2. Workstreams
1. **Architecture Diagrams** — ✅ Complete
   - Draft updated logical and deployment diagrams showing Cloud Run, Firestore, Cloud Storage, retrieval layer, IAM.
   - Highlight managed vs. open/self-hosted options per capability.
   - ✅ High-level Mermaid topology committed 2025-11-07; added Cloud Run swimlane deployment diagram to `future_architecture.md` on 2025-11-10.

2. **Data Flow Narratives** — ✅ Complete
   - Document ingestion pathways (forms, groups.io, financial feeds) into Firestore/Storage.
   - Describe retrieval/RAG flow including vector store selection and LLM hosting.
   - Cover report generation pipeline and its interactions with stores and LLMs.
   - ✅ Initial workflows captured in `future_architecture.md` §3.10.

3. **Capability Replacement Matrix** — ✅ Complete
   - Map each Azure component to a proposed GCP substitute with rationale, trade-offs, and open-source alignment.
   - Call out decisions requiring PoC validation (Vertex AI Search vs AlloyDB + pgvector, IdP choice, etc.).
   - ✅ Draft matrix committed in `future_architecture.md` §4.

4. **Security & IAM Plan** — ⚠️ In Progress
   - Define service accounts, Secret Manager usage, tokenization/PII controls.
   - Outline Workload Identity Federation needs during transition.
   - ✅ Drafted in `future_architecture.md` §3.7 with scoped roles, secrets strategy, monitoring, and role-to-capability matrix (2025-11-08 update).
   - ⚙️ Implemented dev Terraform modules for service accounts + GitHub WIF impersonation (2025-11-09); prod stack scaffolded in `infra/environments/prod` with locked-down defaults (2025-11-11).
   - 🔄 CI: `.github/workflows/terraform-dev.yml` runs fmt/plan/apply via WIF; ensure repo variables stay in sync as environments expand.
   - ✅ Cloud Run smoke tests verified FastAPI + Streamlit revisions deploy cleanly with `/tmp` SQLite storage and documented manual `gcloud run services update ...` workflow for reused image tags (2025-11-09).

5. **Outstanding Decisions Register** — ✅ Complete
   - Update the table in `planning/future_architecture.md` with owners and due dates as decisions solidify.
   - ✅ Finalized milestone decisions on 2025-11-11 (Google Identity, Vertex AI Search, Vertex AI Gemini, deferred BigQuery, Terraform baseline).

6. **Local Sandbox Profile** — ✅ Complete
   - Lock in configuration defaults for `I4G_ENV=local` (mock auth, SQLite, Chroma, Ollama, scheduler off).
   - ✅ Implemented via `settings/config.py` environment overrides; documented in `future_architecture.md` §3.9.
   - Added `scripts/bootstrap_local_sandbox.py` to regenerate sample data end-to-end.

7. **Migration Runbooks (Azure → GCP)** — ✅ Drafted
   - Capture repeatable procedures for exporting Azure data, identity, and automation workloads and importing to GCP equivalents.
   - ✅ Initial draft recorded in `planning/migration_runbook.md` on 2025-11-11; refine during Milestone 3/4 as tooling solidifies.

## 3. Deliverables Checklist
- [x] Updated `planning/future_architecture.md` with refined diagrams and deployment swimlanes (Mermaid draft added 2025-11-07; Cloud Run swimlanes published 2025-11-10).
- [x] Outstanding decisions register refreshed with final owner sign-off (decisions logged 2025-11-11).
- [x] Appendix or inline section documenting managed vs local profiles for each capability (`future_architecture.md` §3.8 expanded 2025-11-11).
- [x] Draft migration runbooks outlining Azure → GCP cutover steps (`planning/migration_runbook.md` created 2025-11-11).
- [ ] Summary paragraph for change_log once Milestone 2 design is approved.

## 4. Open Questions
- Do we need stakeholder interviews to confirm ingestion requirements? If yes, schedule or assign owner.
- What sample workload do we need for retrieval PoC comparisons?

Keep this outline updated as tasks progress; it will serve as the persistent prompt for Milestone 2 work sessions.
