# Implementation Roadmap (MVP → Production)

_Last updated: 15 Nov 2025_

This roadmap is the single source of truth for how we move from today’s MVP-ready Vertex AI Search demo to a production cutover. It consolidates workstreams, milestones, and status so we avoid conflicting plans.

## Snapshot

| Phase | Target Window | Primary Outcomes | Status |
|---|---|---|---|
| **Foundation** | Complete (Milestone 2) | Architecture decisions locked (Identity Platform, Vertex AI Search, Gemini, Terraform baseline). Dev + prod Terraform stacks scaffolding. | ✅ Done |
| **MVP Search Preview** | Nov → Dec 2025 | Shareable Streamlit dashboard on Cloud Run, Discovery Engine seeded with exported data, stakeholder feedback loop open. | 🔄 In flight |
| **Cloud Run Hardening & Ingestion** | Dec 2025 → Jan 2026 | GCP-native ingestion jobs live, FastAPI endpoints hardened, secrets/monitoring policies enforced. | ⏳ Upcoming |
| **Migration & Production Cutover** | Feb → Mar 2026 | Azure data migrations complete, identity cutover rehearsed, production go-live checklist satisfied. | ⏳ Upcoming |

### Roles & Assumptions
- Primary engineer: Jerry (≈10 hrs/week). Copilot supports automation and documentation.
- Stakeholder availability is limited; prioritise async updates via `planning/change_log.md`.
- Two GCP projects (`i4g-dev`, `i4g-prod`) remain the deployment targets; Azure stays read-only until cutover.

## Phase Detail

### 1. Foundation (Complete)
Outcomes already delivered:
- Finalised architecture & tech stack (`planning/future_architecture.md`, `planning/technology_stack_decisions.md`).
- Terraform modules for Cloud Run, IAM, storage, Vertex AI Search; dev + prod environments scaffolded.
- Discovery Engine indexing validated with Azure exports, Streamlit dashboard querying dev data store.

Residual actions:
- Keep change log current when infra modules evolve.
- Archive superseded planning docs (handled by this consolidation effort).

### 2. MVP Search Preview (Current Focus)
Goal: deliver a stable, shareable analyst search experience on `i4g-dev` with clear deployment runbooks.

Key tasks:
- **Discovery Engine & UX**
	- [ ] Finalise Discovery Engine metadata hygiene (dataset labels, sample queries, evaluation notes).
	- [ ] Harden Streamlit UX (caption metadata, error states, download flows) and document rapid redeploy workflow (`docs/dev_guide.md`).
	- [ ] Automate container build + deploy steps (GitHub Action or reusable script) so iterative redeploys stay consistent.
- **Weekly Incremental Migration Cadence**
	- [ ] Schedule and execute a Friday incremental Azure SQL → Firestore import using the existing ETL script; log results in `planning/migration_runbook.md` and store reports under `data/intake_migration_report_*.json`.
	- [ ] Add a diff summary mode to the migration script so new or updated records surface explicitly after each run.
	- [ ] Track Azure Blob ↔ GCS deltas in the same cadence (reuse blob migration helper) and archive reports under `data/blob_migration_incremental_*.json`.
	- [ ] Export Azure Cognitive Search indexes weekly, transform for Vertex AI Search, and re-import into `retrieval-poc`, saving artifacts under `data/search_exports/<run_date>/` and noting LRO IDs in the runbook.
- **Stakeholder Feedback & Docs**
	- [ ] Stand up the GitBook space linked to the repo (or nightly export) and capture structure (home, analyst search guide, data freshness notes).
	- [ ] Draft the initial MVP stakeholder guide (search walkthrough, feedback instructions, release cadence) and sync it with GitBook so non-technical reviewers can comment.
	- [ ] Create a lightweight feedback backlog (e.g., `planning/mvp_feedback.md` or GitHub issues label) fed by weekly syncs and GitBook comments.

Exit criteria:
- Streamlit dev URL shareable without manual gcloud tweaks.
- Sample queries + evaluation notes recorded in repo for stakeholders.
- Feedback backlog + GitBook user guide created to inform next phases.

### 3. Cloud Run Hardening & Ingestion (Next)
Goal: move core workloads fully onto GCP services with observability and security controls in place.

Streams & tasks:

**Ingestion & Data Pipelines**
- [ ] Containerise remaining Azure ingestion logic; deploy as Cloud Run Jobs with Scheduler triggers.
- [ ] Store source credentials in Secret Manager; document rotation procedures.
- [ ] Instrument jobs with structured logging + alerting (Cloud Monitoring uptime checks, failure alerts).
- [ ] Rehearse dual-run period where Azure + GCP ingestion operate in parallel, comparing outputs.

**API & Retrieval Hardening**
- [ ] Expose FastAPI endpoints for search/chat/report using Discovery Engine client abstraction.
- [ ] Implement PII tokenization service backing Firestore vault collections.
- [ ] Integrate LangChain evaluation harness to monitor response quality + latency.

**Security & Observability**
- [ ] Finalise IAM roles via Terraform custom roles (e.g., Discovery Engine search role already staged in dev/prod).
- [ ] Configure dashboards/alerts (ingest duration, Cloud Run errors, IAM policy drift checks).
- [ ] Document incident response (who to page, where to look) in `planning/migration_runbook.md` appendices.

Exit criteria:
- All ingestion paths can run in GCP without Azure dependencies.
- FastAPI + Streamlit talk exclusively to GCP resources (Discovery Engine, Firestore, Storage).
- Monitoring/alerts in place for ingestion failures and Cloud Run errors.

### 4. Migration & Production Cutover (Later)
Goal: deliver parity with Azure production, execute rehearsed cutover, and sunset Azure workloads.

Key tracks:
- Structured/unstructured data migrations rehearsed with validation logs (continue updating `planning/migration_runbook.md`).
- Identity migration from Azure AD B2C to Identity Platform completed with user comms.
- Rollout checklist finalised (DNS, signed URLs, legal review for reports).
- Rollback & hypercare plans validated.

Exit criteria:
- Dry Run 3 (prod rehearsal) passes without manual fixes.
- Stakeholders sign off on go-live; cutover scheduled with comms plan prepared.
- Azure access scaled back to read-only then decommissioned post-hypercare.

## Cross-Stream Dependencies

| Dependency | Blocks |
|---|---|
| Vertex AI Search reliability metrics | Production cutover sign-off |
| Streamlit feedback backlog | Scope for Cloud Run hardening (decide which UX gaps matter) |
| Weekly incremental migration reports | Stakeholder confidence in MVP data freshness |
| Search export/import cadence | Vertex tuning backlog prioritisation |
| Secret Manager credential inventory | Scheduler/ingestion deployment |
| PII vault implementation | Report generation + LEO portal readiness |

## Risk Log (Rolling)

| Risk | Impact | Mitigation |
|---|---|---|
| Discovery Engine quota or relevance issues delay analyst adoption | High | Monitor usage, capture mis-ranked queries, keep AlloyDB fallback plan on deck. |
| Single-operator bandwidth | Medium | Keep roadmap lightweight, focus on highest leverage tasks; defer non-essential polish. |
| Identity migration surprises (MFA, account recovery) | Medium | Rehearse with pilot users early; document support flow in runbook. |
| Report workflow requirements still evolving | Medium | Prototype minimal PDF delivery now; collect requirements before committing to automation scope. |

## Next 2-Week Focus
1. Run the first full Friday cadence (Azure SQL import + blob sync + Cognitive Search export/import) and capture all reports/LRO IDs in `planning/migration_runbook.md`.
2. Finish Discovery Engine data hygiene + sample query documentation for stakeholder testing.
3. Automate Streamlit image build/redeploy workflow (script or GH Action).
4. Outline the GitBook MVP stakeholder guide and publish the initial table of contents for review.

Update this roadmap whenever a phase status changes or new risks emerge. When a task moves to “Done”, add a bullet to `planning/change_log.md` and prune the corresponding TODO here.
