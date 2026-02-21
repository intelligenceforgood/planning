# SSI + AWH Consolidation — Index

> Planning documents for merging the **Scam Site Investigator** (SSI) and
> **Agentic Wallet Harvester** (AWH) into a unified product.

## Status

**Phase 0 decisions: RESOLVED** (2026-02-20). All 17 questions answered. Key decisions:

- Gemini Flash as primary LLM (Claude dropped)
- Dual browser engine (zendriver + Playwright)
- Decodo proxy from day one
- Single authenticated `/ssi` page with quick scan toggle
- Direct DB access to core (inter-repo coupling OK)
- Wallet allowlist: expanded + configurable JSON

## Documents

| #   | Document                                                                   | Purpose                                                                   |
| --- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| 01  | [AWH Technical Analysis](01_awh_analysis.md)                               | Deep dive into AWH architecture, tech stack, and user flow                |
| 02  | [Feature Comparison & Merge Plan](02_feature_comparison_and_merge_plan.md) | Side-by-side feature matrix, integration decisions, and what goes where   |
| 03  | [Architecture & TDD](03_architecture_tdd.md)                               | Technical design for the merged product: schema, API, deployment, testing |
| 04  | [Phased Roadmap](04_roadmap.md)                                            | 8-phase implementation plan with checkbox tracking                        |
| 05  | [Questions & Decisions](05_questions.md)                                   | 17 questions — all resolved with decisions                                |
| 06  | [Flexible Scan Research](06_flexible_scan_research.md)                     | Approaches for handling arbitrary site interactions (Q2 deep dive)        |
| 07  | [Gemini vs Claude Vision](07_gemini_vision_research.md)                    | Can Gemini replace Claude for browser automation? (Q16 deep dive)         |

## Reference Material

### SSI (Existing)

- PRD: `planning/prd_scam_site_investigator.md`
- Architecture: `ssi/docs/architecture.md`
- Developer Guide: `ssi/docs/developer_guide.md`
- User Guide: `ssi/docs/user_guide.md`
- Next Steps: `planning/ssi/ssi_next_steps.md`

### AWH (Being Absorbed)

- README: `agentic_wallet_harvester/README.md`
- Azure Guide: `agentic_wallet_harvester/azure/portal_guide.md`

### Core (Integration Target)

- Storage Design: `core/docs/design/storage.md`
- Factories: `core/src/i4g/services/factories.py`
- Schema: `core/src/i4g/store/sql.py`

### UI (Frontend Target)

- SSI Page: `ui/apps/web/src/app/ssi/page.tsx`
- Developer Guide: `ui/docs/developer-guide.md`

### Data Requirements (Resolved)

- Slides 12–17: eCX API endpoints (`/phish`, `/mal_domain`, `/crypto`, `/report_phishing`, `/mal_ip`, `/malicious-sms`). These are upstream data sources — future integration (post-Phase 8).
