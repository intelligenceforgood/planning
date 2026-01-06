# Proposal: Implementing the Strategic/Tactical Linkage

**Target Sprint:** Next
**Priority:** High
**Owner:** Backend / Fullstack

## 1. Objective
Enable the **Dual-Speed Architecture** by implementing the linkage between Operational Campaigns (Tactical) and Governance Taxonomy (Strategic). This feature empowers analysts to explicitly map their detection efforts to organizational risk categories.

## 2. Requirements

### 2.1 Backend (Core)
- [ ] **Schema Enhancement:** Extend the `Campaign` model (in `services/campaigns.py`) to support the strategic link: `associated_taxonomy_ids` (List[str]).
- [ ] **API Logic:** Enhance `create_campaign` and `update_campaign` to validate that selected taxonomy IDs represent valid nodes in the current Governance tree.
- [ ] **Reporting Foundation:** (Phase 2) Prepare the `CampaignService` to serve as an aggregation layer for Governance queries (e.g., "Show me volume for all campaigns linked to Financial Facilitation").

### 2.2 Frontend (UI)
- [ ] **Analyst Workflow:** Upgrade the Campaign creation/edit flow to include a "Governance Assignment" step.
- [ ] **UI Component:** Implement a multi-select component populated by the `/taxonomy` endpoint, allowing analysts to select the appropriate Policy Category for their Campaign.
- [ ] **Contextual Help:** Provide tooltips explaining that this selection drives executive reporting (answering "Why do I need to pick this?").

### 2.3 Documentation
- [ ] **User Guide:** Finalize `docs/book/guides/analyst/campaign_governance.md` to teach this concept (Draft updated).

## 3. Technical Approach

### Schema Strategy
To support this relationship as a first-class citizen, we will add a dedicated column to the `campaigns` table. This ensures the "Golden Thread" between tactics and strategy is queryable and explicit.

**Migration:**
```sql
ALTER TABLE campaigns ADD COLUMN taxonomy_rollup JSONB DEFAULT '[]';
```

### Validation Logic
The `CampaignService` will enforce the integrity of this link. It must ensure that an Analyst cannot link a Campaign to a non-existent Policy Category, preserving the reliability of downstream reporting.

## 4. Acceptance Criteria
1. **Workflow Success:** An analyst creating a "Labor Recruitment Scam" Campaign can easily find and select the "Trafficking" Governance Node.
2. **Data Integrity:** The system persists this relationship reliably.
3. **Dual-View:** The UI effectively distinguishes between the "Filter Definition" (Tactical) and the "Governance Assignment" (Strategic).
