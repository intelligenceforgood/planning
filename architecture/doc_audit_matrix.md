# I4G Platform — Documentation Audit Matrix

**Last Updated:** March 2026  
**Audience:** Tech leads, CTO, Chief Architect  
**Tier:** 1 — System architecture (meta-documentation)  
**Purpose:** Single source of truth for the status of every document in the corpus. Update this table whenever a document is created, updated, verified, or archived.

**Status values:**

| Status         | Meaning                                              |
| -------------- | ---------------------------------------------------- |
| `CURRENT`      | Verified against code within the last 90 days        |
| `NEEDS_UPDATE` | Has known gaps or errors — tracked issues listed     |
| `STALE`        | Not verified in >90 days; may be outdated            |
| `ORPHAN`       | No longer reflects active system; should be archived |
| `GAP`          | Doesn't exist yet; needs to be created               |
| `ARCHIVED`     | Moved to archive; historical reference only          |

**Tiers:**

- **0** — System narrative (cross-repo)
- **1** — System architecture (cross-repo)
- **2** — Component design / TDD (per-repo)
- **3** — Operational guides (cookbooks, runbooks, deployment, infra)
- **4** — End-user documentation (GitBook)
- **5** — AI assistant intelligence (Copilot)
- **archive** — Archived; historical reference

---

## Tier 0 — System Narrative

| Path                                        | Tier | Status  | Issues                                                                                             | Owner           |
| ------------------------------------------- | ---- | ------- | -------------------------------------------------------------------------------------------------- | --------------- |
| `planning/architecture/system_narrative.md` | 0    | CURRENT | Created March 2026. Contains verification-needed banners for scheduler targets and UI→SSI routing. | Chief Architect |

---

## Tier 1 — System Architecture

| Path                                              | Tier     | Status       | Issues                                                                                                                                                                                                                                   | Owner           |
| ------------------------------------------------- | -------- | ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- |
| `planning/architecture/integration_contracts.md`  | 1        | CURRENT      | Created March 2026. Contains verification-needed banners for push_to_core endpoint and retention-purge target.                                                                                                                           | Chief Architect |
| `planning/architecture/doc_audit_matrix.md`       | 1        | CURRENT      | This file. Created March 2026.                                                                                                                                                                                                           | CTO             |
| `core/docs/design/architecture.md`                | 1        | NEEDS_UPDATE | SSI service absent from topology diagrams. TIFAP and PII vault not represented. Stale objectives fixed (March 2026); broken link to storage.md fixed (March 2026). Add SSI diagrams, TIFAP section, PII vault layer, Last Verified date. | Core tech lead  |
| `planning/architecture/documentation_strategy.md` | 1 (meta) | ?            | Not verified. May be superseded by this sprint plan.                                                                                                                                                                                     | CTO             |
| `planning/architecture/visualization_strategy.md` | archive  | ARCHIVED     | arch-viz repo was never created. Deferred. Banner added March 2026.                                                                                                                                                                      | CTO             |

---

## Tier 2 — Component Design / TDD

### Core — Design Documents

| Path                                                                    | Tier | Status  | Issues                                                                                                                                                                                                                           | Owner          |
| ----------------------------------------------------------------------- | ---- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- |
| `core/docs/development/tdd.md`                                          | 2    | STALE   | Dec 2025, covers ~40% of system. Predates SSI integration, TIFAP, fraud taxonomy versioning, PII vault (March 2026), full analyst console API surface, eCX integration. Planned: restructure as master TDD with subsystem index. | Core tech lead |
| `core/docs/design/fraud_taxonomy_tdd.md`                                | 2    | ?       | Not verified against current implementation. Verify: multi-axis classification, LLM tagging pipeline, taxonomy versioning policy, relationship to review schema fraud type fields.                                               | Core tech lead |
| `core/docs/design/threat_intelligence_analytics_tdd.md`                 | 2    | ?       | Not verified. Verify: TIFAP data access pattern (DB direct, not API), campaign detection algorithm, entity linking logic, threat score output schema.                                                                            | Core tech lead |
| `core/docs/design/pii_vault.md`                                         | 2    | CURRENT | Recently updated March 2026. Covers Fernet encryption, encrypted fields, `IntakeStore.get_contact()`, audit logging. Does NOT yet contain the operational SOP (that remains in `detokenization_sop.md`).                         | Core tech lead |
| `core/docs/design/campaign_governance_bridge.md`                        | 2    | ?       | Not verified against current implementation.                                                                                                                                                                                     | Core tech lead |
| `core/docs/design/storage.md`                                           | 2    | ?       | Not verified. Was pointed to by broken link in architecture.md.                                                                                                                                                                  | Core tech lead |
| `core/docs/design/data_model.md`                                        | 2    | ?       | Not verified. Confirm `audit_log` table and PII vault field changes are reflected.                                                                                                                                               | Core tech lead |
| `core/docs/design/iam.md`                                               | 2    | ?       | Not verified against current WIF + service account configuration.                                                                                                                                                                | Core tech lead |
| `core/docs/design/rag.md`                                               | 2    | ?       | Not verified. Confirm HybridRetriever (vector + keyword) and Vertex AI Search integration are current.                                                                                                                           | Core tech lead |
| `core/docs/design/jobs.md`                                              | 2    | ?       | Not verified. Confirm job inventory matches Terraform: `ingest-bootstrap`, `process-intakes`, `generate-reports`, `dossier-queue`.                                                                                               | Core tech lead |
| `core/docs/design/accessibility_audit.md`                               | 2    | ?       | Not verified. Check whether audit recommendations have been implemented.                                                                                                                                                         | UI tech lead   |
| `core/docs/design/performance_audit.md`                                 | 2    | ?       | Not verified.                                                                                                                                                                                                                    | Core tech lead |
| `core/docs/design/security_audit.md`                                    | 2    | ?       | Not verified. Should reflect PII vault (March 2026) changes.                                                                                                                                                                     | Core tech lead |
| `core/docs/design/ftc_fraud_classification_low_cost_llm_design_spec.md` | 2    | ?       | Not verified. Relationship to `fraud_taxonomy_tdd.md` unclear — are these the same system?                                                                                                                                       | Core tech lead |

### Core — Development Docs

| Path                                                   | Tier | Status       | Issues                                                                                                                                                     | Owner           |
| ------------------------------------------------------ | ---- | ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- |
| `core/docs/development/glossary.md`                    | 2    | NEEDS_UPDATE | Missing SSI/TIFAP/taxonomy terms as identified in Phase 3-E inventory.                                                                                     | Chief Architect |
| `core/docs/development/dev_guide.md`                   | 3    | ?            | Not verified.                                                                                                                                              | Core SRE        |
| `core/docs/development/bundle_sources_and_coverage.md` | 2    | ?            | Not verified.                                                                                                                                              | Core tech lead  |
| `core/docs/development/retrieval_gcp_guide.md`         | 3    | ?            | Not verified.                                                                                                                                              | Core tech lead  |
| `core/docs/development/taxonomy_management.md`         | 3    | ?            | Not verified. Confirm current taxonomy bump/versioning workflow.                                                                                           | Core tech lead  |
| `core/api_reference.md` (planned)                      | 2    | GAP          | File path in plan was incorrect — file may be at `core/docs/design/` or doesn't exist yet. Verify full analyst console API surface via router enumeration. | Core tech lead  |

### SSI — Component Docs

| Path                              | Tier | Status | Issues                                                                                                                                                | Owner         |
| --------------------------------- | ---- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- |
| `ssi/docs/tdd.md`                 | 2    | ?      | Not verified post-AWH merge (Feb 2026). Verify: AWH architectural changes, live monitoring feature, deprecated endpoints/components.                  | SSI tech lead |
| `ssi/docs/tdd_ecx_integration.md` | 2    | ?      | Not verified. Verify: current eCX submission flow, payload schema, submission status tracking, eCX response schema, `submission_enabled` safety gate. | SSI tech lead |
| `ssi/docs/api_reference.md`       | 2    | ?      | Not verified.                                                                                                                                         | SSI tech lead |

### UI — Component Docs

| Path                         | Tier | Status       | Issues                                                                                                                                                                                                                                                                                           | Owner        |
| ---------------------------- | ---- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------ |
| `ui/docs/ui_architecture.md` | 2    | NEEDS_UPDATE | No API proxy detail, no state management, no auth token handling. Integration contracts now documented in `planning/architecture/integration_contracts.md`. UI architecture doc needs: monorepo structure, proxy layer, state management, auth flow, design token consumption, build/deployment. | UI tech lead |

---

## Tier 3 — Operational Guides

### Core — Cookbooks

| Path                                                 | Tier    | Status   | Issues                                                                                        | Owner          |
| ---------------------------------------------------- | ------- | -------- | --------------------------------------------------------------------------------------------- | -------------- |
| `core/docs/cookbooks/bootstrap_environments.md`      | 3       | ?        | Not verified.                                                                                 | Core SRE       |
| `core/docs/cookbooks/smoke_test.md`                  | 3       | ?        | Not verified.                                                                                 | Core SRE       |
| `core/docs/cookbooks/cloud_sql_primer.md`            | 3       | ?        | Not verified.                                                                                 | Core SRE       |
| `core/docs/cookbooks/analytics_aggregation.md`       | 3       | ?        | Not verified.                                                                                 | Core tech lead |
| `core/docs/cookbooks/external_enrichment.md`         | 3       | ?        | Not verified.                                                                                 | Core tech lead |
| `core/docs/cookbooks/github_actions_setup.md`        | 3       | ?        | Not verified.                                                                                 | Core SRE       |
| `core/docs/cookbooks/google_workspace_smtp_setup.md` | 3       | ?        | Not verified.                                                                                 | Core SRE       |
| `core/docs/cookbooks/prepare_bootstrap_bundles.md`   | 3       | ?        | Not verified.                                                                                 | Core SRE       |
| `core/docs/cookbooks/azure_legacy_data.md`           | archive | ARCHIVED | Azure migration complete (2025). ARCHIVED banner added March 2026. Historical reference only. | Core SRE       |

### Core — Runbooks

| Path                                                       | Tier | Status | Issues                                                                               | Owner    |
| ---------------------------------------------------------- | ---- | ------ | ------------------------------------------------------------------------------------ | -------- |
| `core/docs/runbooks/analyst_runbook.md`                    | 3    | ?      | Not verified.                                                                        | Core SRE |
| `core/docs/runbooks/analytics_operations.md`               | 3    | ?      | Not verified.                                                                        | Core SRE |
| `core/docs/runbooks/hybrid_search_deployment_checklist.md` | 3    | ?      | Not verified.                                                                        | Core SRE |
| `core/docs/runbooks/dossiers_deployment_checklist.md`      | 3    | ?      | Not verified.                                                                        | Core SRE |
| `core/docs/runbooks/dossiers_subpoena_handoff.md`          | 3    | ?      | Not verified.                                                                        | Core SRE |
| `core/docs/runbooks/retention_purge.md`                    | 3    | ?      | Not verified. Confirm matches `retention-purge` Cloud Scheduler job (every 4 hours). | Core SRE |
| `core/docs/runbooks/console/campaign_management.md`        | 3    | ?      | Not verified.                                                                        | Core SRE |
| `core/docs/runbooks/console/dossier_monitoring.md`         | 3    | ?      | Not verified.                                                                        | Core SRE |
| `core/docs/runbooks/console/intelligence_dashboard.md`     | 3    | ?      | Not verified.                                                                        | Core SRE |
| `core/docs/runbooks/console/network_graph.md`              | 3    | ?      | Not verified.                                                                        | Core SRE |
| `core/docs/runbooks/console/partner_feed_monitoring.md`    | 3    | ?      | Not verified.                                                                        | Core SRE |
| `core/docs/runbooks/console/reports.md`                    | 3    | ?      | Not verified.                                                                        | Core SRE |
| `core/docs/runbooks/console/search.md`                     | 3    | ?      | Not verified.                                                                        | Core SRE |
| `core/docs/runbooks/console/watchlist_alerts.md`           | 3    | ?      | Not verified.                                                                        | Core SRE |

### Core — Policies

| Path                                       | Tier | Status  | Issues                                                                                                                                                                                                               | Owner          |
| ------------------------------------------ | ---- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- |
| `core/docs/policies/detokenization_sop.md` | 3    | CURRENT | Real operational content (dual-approval, subpoena procedure). Planned consolidation into `pii_vault.md` is deferred — `pii_vault.md` does not yet contain this SOP content. Cross-reference banner added March 2026. | Core tech lead |

### SSI — Operational Docs

| Path                                | Tier | Status | Issues                                                                                                                                                                     | Owner         |
| ----------------------------------- | ---- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- |
| `ssi/docs/batch_scheduling.md`      | 3    | ?      | Not verified. Confirm matches current Cloud Scheduler configuration (ssi-ecx-poller every 15 min).                                                                         | SSI tech lead |
| `ssi/docs/failure_modes.md`         | 3    | ?      | Not verified.                                                                                                                                                              | SSI tech lead |
| `ssi/docs/playbook_authoring.md`    | 3    | ?      | Not verified.                                                                                                                                                              | SSI tech lead |
| `ssi/docs/submission_governance.md` | 3    | ?      | Not verified. Confirm matches `submission_enabled=false` safety gate and `submission_agreement_signed=true` requirement.                                                   | SSI tech lead |
| `ssi/docs/developer_guide.md`       | 3    | ?      | Not verified.                                                                                                                                                              | SSI tech lead |
| `ssi/docs/ops_runbook.md`           | 3    | GAP    | Does not exist. Needs: confirming scheduled investigations are running, Cloud Logging failure indicators, manual investigation trigger, eCX submission rejection handling. | SSI tech lead |

### UI — Operational Docs

| Path                          | Tier | Status | Issues                                                                                                                                               | Owner        |
| ----------------------------- | ---- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
| `ui/docs/developer-guide.md`  | 3    | ?      | Not verified.                                                                                                                                        | UI tech lead |
| `ui/docs/deployment-guide.md` | 3    | ?      | Not verified.                                                                                                                                        | UI tech lead |
| `ui/docs/user-guide.md`       | 3    | ?      | Not verified. Scope unclear — may overlap with `docs/book/`. If developer-facing, clarify scope; if analyst-facing, consider moving to `docs/book/`. | UI tech lead |

### Infra — Operational Docs

| Path                                | Tier | Status       | Issues                                                                                                                                                                                       | Owner      |
| ----------------------------------- | ---- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| `infra/docs/README.md`              | 3    | NEEDS_UPDATE | Does not index new docs from Phase 3-D (service_catalog, scheduler_inventory, module_reference).                                                                                             | Infra lead |
| `infra/docs/domain_mapping.md`      | 3    | ?            | Not verified.                                                                                                                                                                                | Infra lead |
| `infra/docs/iap_manual.md`          | 3    | ?            | Not verified.                                                                                                                                                                                | Infra lead |
| `infra/docs/service_catalog.md`     | 3    | GAP          | Does not exist. Needs: Cloud Run services and jobs table (name, image, CPU/memory, scaling, env vars, service account, ingress). Read from `infra/modules/run/` + `infra/environments/app/`. | Infra lead |
| `infra/docs/scheduler_inventory.md` | 3    | GAP          | Does not exist. Needs: full table of Cloud Scheduler jobs (name, schedule, target, purpose). Read from `infra/environments/app/dev/terraform.tfvars`.                                        | Infra lead |
| `infra/docs/module_reference.md`    | 3    | GAP          | Does not exist. Needs: per-module description, required variables, outputs, constraints. Cover `run/service`, `run/job`, `scheduler/job`, `iam/`, `database/`, `lb/`, `iap/`, `monitoring/`. | Infra lead |

---

## Tier 4 — End-User Documentation (GitBook)

| Path                                   | Tier | Status       | Issues                                                                                                                                   | Owner          |
| -------------------------------------- | ---- | ------------ | ---------------------------------------------------------------------------------------------------------------------------------------- | -------------- |
| `docs/book/SUMMARY.md`                 | 4    | ?            | Verify all entries resolve to existing files. Verify no new files are missing from SUMMARY.                                              | CPO            |
| `docs/book/architecture/` (8 pages)    | 4    | NEEDS_UPDATE | After Phases 1–2: verify all 8 pages agree with system_narrative.md and integration_contracts.md. SSI must appear in system-topology.md. | CPO + leads    |
| `docs/book/api/`                       | 4    | ?            | Spot-check against FastAPI OpenAPI schema. Verify Q1 2026 endpoints (PII vault, TIFAP, campaign governance) are documented.              | Core tech lead |
| `docs/book/ssi/`                       | 4    | ?            | Verify AWH merge and live monitoring feature are represented. `live-monitoring.md` should exist.                                         | SSI tech lead  |
| `docs/book/guides/analyst/` (14 pages) | 4    | ?            | Spot-check: entity explorer, watchlist, campaign governance, features added since last doc pass.                                         | CPO            |
| `docs/book/security/`                  | 4    | ?            | Verify `access-control.md` reflects PII vault model (March 2026). Confirm `secrets-reference.md` is accurate.                            | Core tech lead |
| `docs/book/config/settings.md`         | 4    | ?            | Compare against `core/docs/config/settings_manifest.yaml` and `ssi/config/settings.default.toml`.                                        | Core tech lead |
| `docs/book/overview/`                  | 4    | ?            | Not verified.                                                                                                                            | CPO            |

---

## Tier 5 — AI Assistant Intelligence (Copilot)

| Path                                                             | Tier | Status | Issues                                                                                                                                            | Owner           |
| ---------------------------------------------------------------- | ---- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- |
| `copilot/.github/shared/architecture-cheatsheet.instructions.md` | 5    | ?      | Verify against system_narrative.md. This file is auto-loaded on every Copilot session — contradictions are high-impact.                           | CTO             |
| `copilot/.github/shared/doc-governance.instructions.md`          | 5    | GAP    | Does not exist. Create in Phase 5: definition of done for documentation, ownership model, staleness detection protocol, quarterly review cadence. | CTO             |
| `copilot/.github/shared/tdd-template.md`                         | 5    | GAP    | Does not exist. Create in Phase 5: template for new component TDDs with required sections.                                                        | Chief Architect |
| `copilot/.github/shared/general-coding.instructions.md`          | 5    | ?      | Not verified in this sprint.                                                                                                                      | CTO             |
| `copilot/.github/shared/pre-merge-checklist.instructions.md`     | 5    | ?      | Not verified in this sprint.                                                                                                                      | CTO             |

---

## Archive

| Path                                                       | Tier    | Status   | Notes                                                                 | Owner          |
| ---------------------------------------------------------- | ------- | -------- | --------------------------------------------------------------------- | -------------- |
| `planning/archive/prd_prototype_streamlit.md`              | archive | ARCHIVED | Streamlit prototype PRD. Retired 2025. Banner added March 2026.       | CPO            |
| `planning/prd_prototype.md`                                | archive | ARCHIVED | Redirect file pointing to archive copy. Banner added March 2026.      | CPO            |
| `core/docs/cookbooks/azure_legacy_data.md`                 | archive | ARCHIVED | Azure-era cookbook. Migration complete 2025. Banner added March 2026. | Core SRE       |
| `planning/archive/visualization_strategy_deferred.md`      | archive | ARCHIVED | arch-viz repo deferred. Banner added March 2026.                      | CTO            |
| `planning/archive/feature_completeness_plan.md`            | archive | ARCHIVED | 5-week sprint Feb 2026. ARCHIVED banner added March 2026.             | CPO            |
| `planning/archive/consolidation_plan.md`                   | archive | ARCHIVED | —                                                                     | CPO            |
| `planning/archive/debt_remediation_plan.md`                | archive | ARCHIVED | —                                                                     | CTO            |
| `planning/archive/ecx_integration_summary.md`              | archive | ARCHIVED | Historical summary.                                                   | SSI tech lead  |
| `planning/archive/gemini_model_migration.md`               | archive | ARCHIVED | Historical summary.                                                   | Core tech lead |
| `planning/archive/production_launch_summary.md`            | archive | ARCHIVED | Historical summary.                                                   | CPO            |
| `planning/archive/quality_elevation_plan.md`               | archive | ARCHIVED | Historical summary.                                                   | CTO            |
| `planning/archive/ssi_awh_merge_summary.md`                | archive | ARCHIVED | Historical summary.                                                   | SSI tech lead  |
| `planning/archive/ssi_case_enrichment_and_live_monitor.md` | archive | ARCHIVED | Historical summary.                                                   | SSI tech lead  |
| `planning/archive/ssi_case_integration_summary.md`         | archive | ARCHIVED | Historical summary.                                                   | SSI tech lead  |
| `planning/archive/ssi_development_summary.md`              | archive | ARCHIVED | Historical summary.                                                   | SSI tech lead  |
| `planning/archive/tifap_implementation_summary.md`         | archive | ARCHIVED | Historical summary.                                                   | Core tech lead |

---

## ADR Directory

| Path                                  | Tier | Status | Issues                                                                  | Owner           |
| ------------------------------------- | ---- | ------ | ----------------------------------------------------------------------- | --------------- |
| `planning/architecture/adr/README.md` | 1    | GAP    | ADR directory not yet established. Create in Phase 5 with first 5 ADRs. | Chief Architect |

---

## Summary

| Status         | Count |
| -------------- | ----- |
| CURRENT        | 5     |
| NEEDS_UPDATE   | 5     |
| STALE          | 1     |
| ? (unverified) | ~60   |
| GAP            | 7     |
| ARCHIVED       | 16+   |

**Sprint target**: Bring all `?` Tier 1–2 documents to either `CURRENT` (verified) or `NEEDS_UPDATE` (with specific issues documented). Close all `GAP` items in Phases 3–5.
