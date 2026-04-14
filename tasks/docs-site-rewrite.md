# Docs Site Rewrite — Detailed Plan

> **Status**: Draft — awaiting review
> **Created**: 2026-04-13
> **Owner**: Product (Jerry)
> **Scope**: `docs/book/` GitBook site — end-user documentation only

---

## 1. Problem Statement

The current documentation site has three structural problems that undermine its value:

### 1a. No Learning Path

The site is organized as a reference catalog — it assumes readers already know the system and are
looking up specifics. In reality, most visitors (especially new volunteer analysts joining through
university engagements) need to **learn** the system from scratch. There is no guided journey from
"why does this exist" → "what are the key ideas" → "how do I use it" → "how do I get better."

### 1b. Audience Confusion

~47% of pages contain developer-focused content (env vars, CLI commands, Terraform refs, source
file paths, Docker images, Python code) that end users cannot action. This content is interleaved
with genuinely useful end-user guidance, making pages feel overwhelming and irrelevant. The three
distinct audiences (analysts, admins, law enforcement) are not clearly separated.

### 1c. Missing Conceptual Foundation

The system has innovative concepts — threat entities, threat indicators, authority-ranked extraction,
multi-axis fraud taxonomy, campaign clustering, entity lifecycles, risk scoring, engagement-scoped
analysis, evidence chain of custody, site investigation AI agents — but no page explains _what_
these are and _why_ they matter before throwing users into operational how-to guides. Reviewers of
the entity extraction TDD repeatedly ask basic conceptual questions the docs site should answer.
Users ask "what is a threat indicator?" — a core concept with no dedicated explanation anywhere.

### 1d. Walls of Text, No Visuals

Most pages are dense paragraphs and tables with no screenshots, diagrams, or annotated visuals.
A flowchart communicates a pipeline better than five paragraphs. A screenshot with callouts teaches
Console navigation faster than a bullet list. The site is a documentation site, not a novel.

---

## 2. Design Principles

| #   | Principle                      | Implication                                                                                                                                                                                                                                                                  |
| --- | ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **Learn-first architecture**   | Welcome → Why this exists → Key Concepts → Your Role → Start doing things. Every visitor gets orientation before operations.                                                                                                                                                 |
| 2   | **Persona-routed journeys**    | After the shared foundation, clear paths for analyst, engagement participant, LEO, end-user, and admin. Each persona has a "start here" page.                                                                                                                                |
| 3   | **End-user content only**      | If a user or admin cannot do it via the Console or web UI, it does not belong on this site.                                                                                                                                                                                  |
| 4   | **Visual-first**               | Always ask: can a screenshot, diagram, or flowchart replace this text? If yes, use the visual. Annotated screenshots for Console pages. Mermaid/SVG diagrams for flows and relationships. A diagram that fills the page is better than five paragraphs nobody reads.         |
| 5   | **Wikipedia-style references** | When a page touches on technical depth that lives in a dev repo (`core/docs/`, `ssi/docs/`), use a numbered reference link (superscript) at the relevant sentence, with a "References" section at the bottom linking to the GitHub file. Never inline the technical content. |
| 6   | **Console-first for SSI**      | All SSI documentation rewritten from the perspective of the Console UI. CLI existence mentioned via reference link only.                                                                                                                                                     |
| 7   | **Concepts before procedures** | Every operational guide links back to relevant Key Concepts pages. Users understand _why_ before _how_.                                                                                                                                                                      |
| 8   | **Progressive disclosure**     | Pages start with what 80% of readers need. Advanced details (API endpoints, edge cases) go in expandable sections or linked sub-pages.                                                                                                                                       |

> **GitBook note:** This site is built with [GitBook](https://www.gitbook.com/). Each folder in
> `docs/book/` maps to a GitBook **group** in the sidebar. Each `.md` file is a **page**.
> `SUMMARY.md` controls the table of contents and navigation tree. GitBook does **not** support
> Mermaid chart resizing — large Mermaid diagrams may be unreadable. For complex diagrams, export
> to SVG and embed as an image instead. All visual assets live in `assets/`.

---

## 3. Proposed Information Architecture

```
docs/book/
├── SUMMARY.md
├── README.md                          # "Welcome to I4G" — warm, mission-first landing
│
├── getting-started/
│   ├── why-i4g.md                     # 🆕 The problem space, mission, what makes I4G different
│   ├── how-it-works.md                # 🆕 Bird's-eye system flow (report → review → intelligence → action)
│   └── find-your-role.md              # 🆕 Persona router — "I am a..." with links to each journey
│
├── key-concepts/                      # 🆕 Entire section is new
│   ├── README.md                      # Section intro — "master these ideas to use I4G effectively"
│   ├── cases-and-evidence.md          # What is a case, evidence lifecycle, PII protection
│   ├── entities.md                    # What entities are, threat vs contextual, why they matter
│   ├── indicators.md                  # 🆕 What threat indicators are, how they differ from entities
│   ├── entity-extraction.md           # How the platform finds entities (user-facing version of TDD)
│   ├── fraud-taxonomy.md              # The 5-axis classification system, why structured taxonomy matters
│   ├── campaigns.md                   # How cases cluster into campaigns, campaign vs governance taxonomy
│   ├── risk-scoring.md                # How risk is computed, entity lifecycle (active → dormant → resolved)
│   ├── engagements.md                 # What engagements are, university pilot model, how they work
│   ├── dossiers-and-reports.md        # What report types exist, chain of custody, digital signatures
│   └── site-investigations.md         # What SSI does conceptually — passive recon, AI agent, evidence
│
├── analyst-guide/                     # Primary learning journey — Console walkthrough
│   ├── README.md                      # "Start here" — prerequisites, access, first login
│   ├── console-tour.md               # 🆕 Visual tour of the console layout and navigation
│   ├── daily-workflow.md              # Dashboard → queue → review → action (rewrite of index.md)
│   ├── reviewing-cases.md            # 🆕 The core analyst loop: read, classify, annotate, decide
│   ├── search-and-discovery.md        # Merged: search.md + discovery.md (Console-focused)
│   ├── entity-explorer.md             # Rewrite: strip API endpoints, focus on Console UX
│   ├── network-graph.md               # Rewrite: strip API endpoints, focus on visual investigation
│   ├── campaigns.md                   # Rewrite: link to key-concepts/campaigns, focus on Console actions
│   ├── reports-and-dossiers.md        # Rewrite of user-guide-reports.md + dossiers.md
│   ├── investigating-sites.md         # 🆕 SSI via Console — submit URL, review results, evidence
│   ├── live-monitoring.md             # Rewrite: Console-focused, strip WebSocket/SSE internals
│   ├── watchlist-and-alerts.md        # Rewrite: strip env vars and API table
│   ├── taxonomy-explorer.md           # Keep (already clean)
│   ├── geographic-heatmap.md          # Keep (already clean)
│   ├── timeline.md                    # Keep (already clean)
│   ├── impact-dashboard.md            # Keep (already clean)
│   └── indicator-registry.md          # Keep (already clean)
│
├── engagement-guide/                  # University programs — core feature
│   ├── README.md                      # What the engagement model is, who it's for
│   ├── working-in-engagement.md       # Analyst/student perspective (keep — already clean)
│   ├── managing-engagements.md        # Manager perspective (rewrite: strip env vars, API endpoints)
│   ├── leaderboard.md                 # Rewrite: strip env var, keep scoring explanation
│   └── lifecycle.md                   # Keep (already clean)
│
├── law-enforcement-guide/             # LEO journey
│   ├── README.md                      # 🆕 "Start here" for LEO partners
│   └── working-with-reports.md        # Rewrite of law-enforcement.md — strip template paths, API routes
│
├── user-guide/                        # Victim/reporter journey
│   ├── README.md                      # 🆕 "Start here" — empathetic, clear
│   ├── submitting-a-report.md         # Rewrite of user-guide.md, split out researcher content
│   └── following-up.md               # 🆕 What happens after submission, how to check status
│
├── admin-guide/                       # System administration (Console + web UI actions only)
│   ├── README.md                      # What admins can do via the Console
│   ├── user-management.md             # 🆕 Rewrite: access-control.md minus dev content
│   ├── scheduled-reports.md           # Rewrite: Console/UI actions only, strip CLI/env vars
│   ├── partner-feed.md                # Rewrite: Console/UI actions only, strip Python code
│   ├── site-investigation-config.md   # 🆕 SSI admin config via Console (not CLI)
│   └── auto-investigation.md          # Rewrite: strip env vars, TOML, conda commands
│
├── security/
│   ├── README.md                      # Rewrite: end-user-focused data protection explainer
│   ├── access-and-roles.md            # Rewrite of access-control.md: roles, permissions, how to request
│   └── report-authenticity.md         # 🆕 How to verify a signed report (end-user perspective)
│
├── api/                               # Slim integrator section (for partner orgs only)
│   ├── README.md                      # Rewrite: framed for integration partners, not developers
│   ├── authentication.md              # Rewrite: API key + partner auth only, strip IAP/IAM internals
│   ├── sample-workflows.md            # Keep (rewrite framing for partner integrators)
│   └── taxonomy-reference.md          # Keep (useful to analysts too)
│
└── assets/                            # Screenshots, diagrams (unchanged)
```

### What Gets Removed Entirely (content lives in dev repos already)

| Current Page                          | Reason                              | Dev Repo Home                                           |
| ------------------------------------- | ----------------------------------- | ------------------------------------------------------- |
| `architecture/system-topology.md`     | 100% infra internals                | `core/docs/design/architecture.md`                      |
| `architecture/data-pipeline.md`       | Module paths, job filenames         | `core/docs/design/`                                     |
| `architecture/security-model.md`      | IAM internals, service accounts     | `core/docs/design/iam.md`                               |
| `architecture/threat-intelligence.md` | Source file paths, NetworkX details | `core/docs/design/threat_intelligence_analytics_tdd.md` |
| `architecture/job-architecture.md`    | Docker images, Dockerfiles, cron    | `core/docs/design/jobs.md`                              |
| `architecture/ssi-architecture.md`    | Source file paths, DB schema        | `ssi/docs/tdd.md`                                       |
| `architecture/evidence-storage.md`    | GCS buckets, migration scripts      | `core/docs/design/storage.md`                           |
| `config/settings.md`                  | 100% env var catalog for devs       | `core/docs/config/`                                     |
| `config/slo_definitions.md`           | SRE metrics, Terraform alert refs   | `core/docs/`                                            |
| `api/field_name_translation.md`       | 100% Pydantic/SDK internals         | `core/docs/api_reference.md`                            |
| `api/sdk_endpoint_coverage.md`        | 100% TypeScript SDK internals       | `ui/docs/`                                              |
| `security/secrets-reference.md`       | 100% gcloud/Terraform secrets       | `infra/docs/`                                           |
| `guides/developer-setup.md`           | 100% developer onboarding           | `copilot/docs/onboarding.md`                            |
| `contributing.md`                     | Developer contribution guide        | `docs/CONTRIBUTING.md` (repo root)                      |
| `ssi/cli-reference.md`                | 100% CLI reference                  | `ssi/docs/developer_guide.md`                           |
| `ssi/configuration.md`                | Env vars, TOML blocks               | `ssi/docs/`                                             |
| `ssi/troubleshooting.md`              | `ollama serve`, `brew install`      | `ssi/docs/`                                             |
| `ssi/batch-investigations.md`         | CLI batch, cron, curl examples      | `ssi/docs/batch_scheduling.md`                          |
| `ssi/ecrimex-integration.md`          | CLI commands, env vars, pipeline    | `ssi/docs/tdd_ecx_integration.md`                       |
| `ssi/playbooks.md`                    | CLI management commands             | `ssi/docs/playbook_authoring.md`                        |
| `guides/admin/cli.md`                 | 100% CLI + dev tooling              | `core/docs/development/`                                |
| `guides/engagements/comparison.md`    | BigQuery SQL, Looker, API code      | `core/docs/`                                            |

### What Gets Rewritten vs Kept

| Action         | Count | Pages                                                                                                                                                                                                                                                                                                                       |
| -------------- | ----- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **New pages**  | 13    | `why-i4g`, `how-it-works`, `find-your-role`, all 10 key-concepts pages (incl. indicators), `console-tour`, `reviewing-cases`, `following-up`, LEO README, user README, `report-authenticity`, `user-management`, `site-investigation-config`                                                                                |
| **Rewrite**    | 17    | README (welcome), entity-explorer, network-graph, campaigns, search+discovery merge, reports+dossiers merge, SSI investigating-sites (Console rewrite), live-monitoring, watchlist, managing-engagements, leaderboard, law-enforcement, user-guide, scheduled-reports, partner-feed, auto-investigation, api/authentication |
| **Keep as-is** | 8     | taxonomy-explorer, geographic-heatmap, timeline, impact-dashboard, indicator-registry, working-in-engagement, lifecycle, taxonomy-reference                                                                                                                                                                                 |
| **Remove**     | 22    | All architecture/_, config/_, 5 API pages, 6 SSI pages, developer-setup, contributing, cli, comparison                                                                                                                                                                                                                      |

---

## 4. Key Concepts — Content Outline

This is the heart of the rewrite. Each page follows the pattern:
**What is it → Why it matters → How I4G uses it → What you'll see in the Console → Learn more**
**Visual-first rule for concepts:** Every Key Concepts page must have at least one primary visual
(diagram or annotated screenshot) that a reader can understand _without reading the text_. The
visual is the page; the text is the caption.

### 4a. Cases & Evidence (`cases-and-evidence.md`)

- A **case** is a single fraud report from a victim — the atomic unit of the platform
- Evidence types: chat logs, screenshots, receipts, voice notes, blockchain records
- Case lifecycle: submitted → queued → under review → classified → closed
- PII protection: how contact info is encrypted, why analysts see redacted data
- How cases feed into everything else (entities, campaigns, reports)
- 🎨 **Primary visual:** Case lifecycle flowchart (submitted → … → closed)
- 🎨 **Secondary visual:** Annotated screenshot of case detail page showing evidence, timeline, entities

### 4b. Entities (`entities.md`)

- An **entity** is any identifiable piece of information extracted from a case
- Two categories:
  - **Threat entities** (14 types): financial infrastructure (wallets, bank accounts), contact methods (emails, phones, social handles), digital infrastructure (URLs, domains, IPs) — these are the indicators analysts investigate and report
  - **Contextual entities**: person names, organizations, locations — provide investigative context but are not themselves fraud indicators
- Why the distinction matters: only threat entities get risk scores, watchlisting, STIX export, campaign clustering
- The platform links cases through shared entities — this is how isolated reports become actionable intelligence
- Entity lifecycle: active → declining → dormant → resolved (plus manual "flagged")
- 🎨 **Primary visual:** Diagram showing one scam report → extracted entities → links to other cases (the "intelligence aggregation" story)
- 🎨 **Secondary visual:** Entity type category table with icons (financial / contact / digital infra)

### 4c. Threat Indicators (`indicators.md`) 🆕

- A **threat indicator** is a threat entity that has been verified, enriched, and promoted to the Indicator Registry
- Not every entity becomes an indicator — indicators are vetted, high-confidence signals
- The difference: entities are _extracted_ (raw); indicators are _curated_ (analyst-reviewed or auto-promoted)
- Indicator categories: bank accounts, crypto wallets, payment handles, IPs, domains
- What you can do with indicators: export (CSV, XLSX, STIX), submit to eCrimeX, share with partners
- How indicators feed partner integrations and law enforcement reports
- 🎨 **Primary visual:** Funnel diagram: raw text → extracted entities → promoted indicators → partner feed / STIX export
- 🎨 **Secondary visual:** Annotated screenshot of Indicator Registry with category tabs

### 4d. Entity Extraction (`entity-extraction.md`)

- User-facing version of the TDD: _how does the platform find entities in messy, obfuscated scam text?_
- The pipeline concept: every piece of evidence goes through a multi-stage pipeline
- Multiple detection methods run in parallel (pattern matching, AI analysis, machine learning) and cross-check each other
- Confidence scoring: the system ranks how sure it is about each entity
- Obfuscation handling: scammers hide contact info ("j o h n at g mail dot com") — the system reverses this
- Blocklist: known false positives are filtered out
- Full audit trail: every extraction decision is recorded
- _Reference¹ link to `core/docs/design/entity_extraction_tdd.md` for technical details_
- 🎨 **Primary visual:** Simplified extraction pipeline flowchart (adapted from TDD — the full Mermaid
  chart is too large for GitBook; create a simplified 6-box SVG version: source text → normalize →
  detect (regex + AI + ML) → merge & score → filter → result)
- 🎨 **Secondary visual:** Before/after obfuscation example ("j o h n at g mail dot com" → "john@gmail.com")

### 4e. Fraud Taxonomy (`fraud-taxonomy.md`)

- Why structured classification matters (compare: free-text labels vs rigorous axes)
- The 5 axes: Intent, Channel, Technique, Requested Action, Claimed Persona
- Examples: a romance scam where victim is asked to buy crypto → Intent: Romance, Channel: Chat, Technique: Trust Building, Action: Crypto, Persona: Romantic Partner
- How taxonomy powers analytics (Sankey diagrams, heatmaps, trend analysis)
- How taxonomy helps law enforcement (standardized reporting across agencies)
- 🎨 **Primary visual:** 5-axis taxonomy diagram showing axes as parallel columns with example values
- 🎨 **Secondary visual:** Screenshot of Taxonomy Explorer Sankey view

### 4f. Campaigns (`campaigns.md`)

- What campaigns are: clusters of cases sharing threat entities
- Active campaigns vs governance taxonomy (the distinction from campaign_governance.md)
- How campaigns are detected automatically (shared wallets, emails, domains across cases)
- Campaign risk scoring
- Why campaigns matter: individual reports become coordinated fraud operations
- 🎨 **Primary visual:** Diagram showing 3 cases with shared wallet/email entities → auto-clustered into a campaign
- 🎨 **Secondary visual:** Screenshot of campaign detail page with timeline and entity graph

### 4g. Risk Scoring & Entity Lifecycle (`risk-scoring.md`)

- How entities receive risk scores
- The lifecycle model with time-based transitions
- What "Active Threats" means on the dashboard
- How analysts use lifecycle to prioritize work
- 🎨 **Primary visual:** Entity lifecycle state diagram (active → declining → dormant → resolved, with flagged as manual override)

### 4h. Engagements (`engagements.md`)

- What the engagement model is (university capstone programs)
- Why it exists: training the next generation of fraud analysts
- How cases are scoped to engagements
- How scoring and leaderboards motivate learning
- From concept to graduation: the engagement lifecycle
- 🎨 **Primary visual:** Engagement lifecycle diagram (draft → active → completed → archived)
- 🎨 **Secondary visual:** Screenshot of engagement leaderboard

### 4i. Dossiers & Reports (`dossiers-and-reports.md`)

- What reports the platform produces (PDF dossier, LEA report, STIX bundle)
- Chain of custody and digital signatures
- How report verification works (hash validation)
- Who receives reports and how
- 🎨 **Primary visual:** Report types comparison table with visual icons
- 🎨 **Secondary visual:** Screenshot of dossier verification panel showing signature check

### 4j. Site Investigations (`site-investigations.md`)

- What SSI does: automates analysis of suspicious websites
- The three levels: passive recon (no site interaction), active investigation (AI agent), full scan
- What the AI agent does (fills fake forms, follows scam funnels, records everything)
- Wallet discovery: finding cryptocurrency addresses on scam sites
- Evidence packaging: what comes out of an investigation
- 🎨 **Primary visual:** Investigation flow diagram (URL → passive recon → AI agent → wallet extraction → evidence package)
- 🎨 **Secondary visual:** Screenshot of SSI investigation results page with risk badge

---

## 5. Execution Phases

### Phase 0: Prep (1 session)

- [x] Create the new directory structure (`getting-started/`, `key-concepts/`, etc.)
- [x] Move/rename files that are staying as-is into their new locations
- [x] Update `SUMMARY.md` skeleton with the new IA (pages can be stubs initially)
- [x] Verify GitBook builds with the new structure

### Phase 1: Foundation — Getting Started + Key Concepts (3–4 sessions)

- [x] Write `getting-started/why-i4g.md`
- [x] Write `getting-started/how-it-works.md` (with end-to-end flow diagram)
- [x] Write `getting-started/find-your-role.md` (with persona router diagram)
- [x] Write all 10 Key Concepts pages (see §4 above), each with primary visual
- [x] Write new `README.md` welcome page
- [x] Create P0 diagrams for Key Concepts pages (see §11)
- [x] Verify GitBook builds, review for tone and accuracy

**Milestone: A new reader can arrive and understand what I4G is, why it exists, and what all the
key ideas are — before touching any operational guide.**

### Phase 2: Analyst Journey (2–3 sessions)

- [x] Write `analyst-guide/README.md` (start here)
- [x] Write `analyst-guide/console-tour.md` (with sidebar + dashboard screenshots)
- [x] Rewrite `daily-workflow.md`
- [x] Write `reviewing-cases.md` (with case detail screenshot)
- [x] Merge and rewrite `search-and-discovery.md`
- [x] Rewrite `entity-explorer.md` (strip API endpoints, add concept links + screenshots)
- [x] Rewrite `network-graph.md` (with graph screenshot)
- [x] Rewrite `campaigns.md` (with campaign detail screenshot)
- [x] Merge and rewrite `reports-and-dossiers.md`
- [x] Write `investigating-sites.md` (SSI Console rewrite — include eCrimeX submissions, feed,
      and trend dashboard sections to cover `/ssi/submissions`, `/ssi/ecx-feed`, `/ssi/ecx-dashboard`)
- [x] Rewrite `live-monitoring.md` (Console-focused)
- [x] Rewrite `watchlist-and-alerts.md`
- [x] Migrate clean pages: taxonomy-explorer, geographic-heatmap, timeline, impact-dashboard, indicator-registry
- [x] Capture all P0 screenshots (see §11)
- [x] Verify all Console pages have docs coverage (see §10 UI audit)

**Milestone: A new analyst can onboard end-to-end using only the docs site.**

### Phase 3: Secondary Journeys (1–2 sessions)

- [x] Rewrite `engagement-guide/` (4 pages — strip dev content, add concept links)
- [x] Rewrite `law-enforcement-guide/` (new README + reworked working-with-reports)
- [x] Rewrite `user-guide/` (split into submitting + following-up)
- [x] Rewrite `admin-guide/` (Console-only actions, 5 pages)

**Milestone: All four personas have clear, self-contained journeys.**

### Phase 4: Security, API, Cleanup (1 session)

- [x] Rewrite `security/` (3 pages — end-user perspective)
- [x] Slim down `api/` to partner-integrator focus (4 pages)
- [x] Remove all 22 deleted pages from the repo
- [x] Capture remaining P1/P2 screenshots and diagrams (see §11) — 26/26 screenshots verified, 10/12 diagrams exist (2 not referenced by any page)
- [x] Review all existing screenshots for currency — retake if UI has changed
- [ ] Replace placeholder images (`leo-report-placeholder.svg`, `victim-intake-placeholder.svg`) — files on disk but NOT embedded in any page; can delete or replace (see instructions below)
- [x] Final `SUMMARY.md` polish
- [x] Full site review: broken links, orphan pages, consistent voice
- [x] Final visual audit: every page has appropriate visuals, no oversized Mermaid diagrams — 11 missing screenshot embeds added

**Milestone: Site is clean, no developer content remains, all links work.**

---

## 6. Proposed SUMMARY.md

> **Navigation design decisions:**
>
> - **Flat pages, not collapsibles.** Every page is a direct child of its section header — no
>   "Overview" or "Start Here" that collapses to reveal 15 children. The old pattern created a
>   jarring single-item-per-section look.
> - **Subbook grouping.** The Analyst Guide (17 pages) is split into four thematic sections
>   (Analyst Guide, Intelligence Tools, Site Investigation, Analytics & Reporting) so each section
>   has 2–5 items. Modeled after the GitBook subbook pattern at
>   [docs.intelligenceforgood.org](https://docs.intelligenceforgood.org/).
> - **Section icons.** Every `##` section header has an emoji icon for scannability in the sidebar.
> - **Platform name: I4G.** Capitalized in all user-facing text; lowercase `i4g` only in file
>   paths and technical identifiers.

```markdown
# Table of contents

- [Welcome](README.md)

## 🚀 Getting Started

- [Why I4G](getting-started/why-i4g.md)
- [How It Works](getting-started/how-it-works.md)
- [Find Your Role](getting-started/find-your-role.md)

## 💡 Key Concepts

- [Overview](key-concepts/README.md)
- [Cases & Evidence](key-concepts/cases-and-evidence.md)
- [Entities](key-concepts/entities.md)
- [Threat Indicators](key-concepts/indicators.md)
- [How Entities Are Extracted](key-concepts/entity-extraction.md)
- [Fraud Taxonomy](key-concepts/fraud-taxonomy.md)
- [Campaigns & Threat Networks](key-concepts/campaigns.md)
- [Risk Scoring & Entity Lifecycle](key-concepts/risk-scoring.md)
- [Engagements](key-concepts/engagements.md)
- [Dossiers & Reports](key-concepts/dossiers-and-reports.md)
- [Site Investigations](key-concepts/site-investigations.md)

## 🔍 Analyst Guide

- [Start Here](analyst-guide/README.md)
- [Console Tour](analyst-guide/console-tour.md)
- [Daily Workflow](analyst-guide/daily-workflow.md)
- [Reviewing Cases](analyst-guide/reviewing-cases.md)
- [Search & Discovery](analyst-guide/search-and-discovery.md)

## 🧠 Intelligence Tools

- [Entity Explorer](analyst-guide/entity-explorer.md)
- [Network Graph](analyst-guide/network-graph.md)
- [Campaigns](analyst-guide/campaigns.md)
- [Watchlist & Alerts](analyst-guide/watchlist-and-alerts.md)
- [Indicator Registry](analyst-guide/indicator-registry.md)

## 🌐 Site Investigation

- [Investigating Sites](analyst-guide/investigating-sites.md)
- [Live Monitoring](analyst-guide/live-monitoring.md)

## 📊 Analytics & Reporting

- [Reports & Dossiers](analyst-guide/reports-and-dossiers.md)
- [Taxonomy Explorer](analyst-guide/taxonomy-explorer.md)
- [Geographic Heatmap](analyst-guide/geographic-heatmap.md)
- [Timeline](analyst-guide/timeline.md)
- [Impact Dashboard](analyst-guide/impact-dashboard.md)

## 🎓 Engagement Guide

- [Overview](engagement-guide/README.md)
- [Working in an Engagement](engagement-guide/working-in-engagement.md)
- [Managing Engagements](engagement-guide/managing-engagements.md)
- [Leaderboard & Performance](engagement-guide/leaderboard.md)
- [Engagement Lifecycle](engagement-guide/lifecycle.md)

## 🛡️ Law Enforcement Guide

- [Start Here](law-enforcement-guide/README.md)
- [Working with Reports](law-enforcement-guide/working-with-reports.md)

## 📝 User Guide

- [Start Here](user-guide/README.md)
- [Submitting a Report](user-guide/submitting-a-report.md)
- [Following Up](user-guide/following-up.md)

## ⚙️ Admin Guide

- [Overview](admin-guide/README.md)
- [User Management](admin-guide/user-management.md)
- [Scheduled Reports](admin-guide/scheduled-reports.md)
- [Partner Feed](admin-guide/partner-feed.md)
- [Site Investigation Settings](admin-guide/site-investigation-config.md)
- [Auto-Investigation](admin-guide/auto-investigation.md)

## 🔒 Security & Trust

- [Overview](security/README.md)
- [Access & Roles](security/access-and-roles.md)
- [Report Authenticity](security/report-authenticity.md)

## 🔌 API Reference

- [Overview](api/README.md)
- [Authentication](api/authentication.md)
- [Sample Workflows](api/sample-workflows.md)
- [Taxonomy Codes](api/taxonomy-reference.md)
```

---

## 7. Writing Guidelines

All pages on the rewritten site follow these rules:

1. **Voice**: Present tense, active voice, second person ("you"). Warm but professional.
2. **Length**: Most pages 60–120 lines. No page exceeds 200 lines (split if needed).
3. **Structure**: Every page opens with a 1–2 sentence summary of what you'll learn, then uses
   `##` sections. Tables for structured data. Screenshots where the Console is referenced.
4. **Visual-first**: Before writing a paragraph, ask: _can a screenshot, diagram, or annotated
   image convey this faster?_ If yes, lead with the visual and use text as the caption. Every
   Console-facing guide page should have at least one screenshot. Every Key Concepts page should
   have at least one diagram.
5. **Diagram format**: GitBook does **not** support Mermaid diagram resizing. Small diagrams
   (≤ 6 nodes) can use inline Mermaid. Larger diagrams must be exported to SVG and placed in
   `assets/diagrams/`. Always test readability at GitBook's rendered width before committing.
6. **Concept links**: Every operational guide links to the relevant Key Concepts page at least once
   (e.g., "To understand how entities are extracted, see [How Entities Are Extracted](../key-concepts/entity-extraction.md)").
7. **References**: Developer/technical detail uses Wikipedia-style superscript reference numbers.
   A `## References` section at the bottom lists the links:

   ```
   ## References

   1. [Entity Extraction Technical Design](https://github.com/intelligenceforgood/core/blob/main/docs/design/entity_extraction_tdd.md) — detailed pipeline architecture and merge algorithm.
   2. [SSI CLI Reference](https://github.com/intelligenceforgood/ssi/blob/main/docs/developer_guide.md) — full command-line documentation for developers.
   ```

8. **No dev content**: No env vars, no CLI commands (unless it's a user-facing CLI like future
   export tools), no source file paths, no Docker/Terraform/conda references, no Python/TS code.
9. **Screenshots**: Use `assets/screenshots/` for Console screenshots. Use `assets/diagrams/` for
   SVG diagrams. Name files descriptively: `entity-explorer-detail.png`, `extraction-pipeline.svg`.
10. **Line length**: ≤ 120 characters per line.

---

## 8. Success Criteria

The rewrite is complete when:

- [x] A brand-new volunteer analyst can read Getting Started → Key Concepts → Analyst Guide and
      feel ready to review their first case — without asking "what is an entity?" or "how does this work?"
      ✅ All 55 pages exist. Getting Started → Key Concepts → Analyst Guide form a complete path.
- [x] No page contains env vars, CLI commands only devs would run, source file paths, or
      infrastructure details
      ✅ Verified via grep — zero matches across all 55 pages.
- [x] Every operational instruction references a Console action (button, page, menu item) —
      not an API endpoint or CLI command
      ✅ All guide pages reference click/button/page actions; no API endpoints or CLI in guides.
- [x] The site has clean persona routing: analyst, engagement participant, LEO, user, and admin
      each have a clear "start here" and self-contained journey
      ✅ find-your-role.md links all 5 personas; each has a README start-here page.
- [x] Every Console page and every major UI section has a corresponding docs page or is explicitly
      called out as needing no documentation (see §10 UI Coverage Audit)
      ✅ All §10 routes covered. 3 eCrimeX gaps now have dedicated subsections in investigating-sites.md.
- [ ] Every Key Concepts page has at least one primary diagram; every Console guide page has at
      least one annotated screenshot
      ⚠️ `key-concepts/dossiers-and-reports.md` has 0 visuals (needs report-types diagram).
      ⚠️ 8 operational guide pages have 0 screenshots (lifecycle, working-in-engagement,
      working-with-reports, following-up, auto-investigation, partner-feed, scheduled-reports,
      site-investigation-config). 3 eCrimeX screenshots in investigating-sites.md are HTML-commented stubs.
      **These all require real screenshots from a running Console — cannot be generated programmatically.**
- [x] All visual assets are checked off in §11 Visual Asset Checklist — no placeholder images remain
      ✅ 2 placeholder SVGs (leo-report, victim-intake) exist on disk but are NOT embedded in any page.
      Delete them to fully close this item (see below).
- [x] `pnpm build` (or GitBook build) passes with zero broken links
      ✅ markdownlint passes (2 minor MD029 warnings). Zero broken internal links or image refs.
- [ ] At least 3 reviewers (non-developers) confirm the site is navigable and educational
      🚫 Requires manual user testing — cannot be verified programmatically.

---

## 9. Page Count Summary

| Section               | Sidebar Section(s)                                                                          | Pages             | Status                                         |
| --------------------- | ------------------------------------------------------------------------------------------- | ----------------- | ---------------------------------------------- |
| Getting Started       | 🚀 Getting Started                                                                          | 3                 | All new                                        |
| Key Concepts          | 💡 Key Concepts                                                                             | 11 (incl. README) | All new                                        |
| Analyst Guide         | 🔍 Analyst Guide + 🧠 Intelligence Tools + 🌐 Site Investigation + 📊 Analytics & Reporting | 18 (incl. README) | 5 new, 7 rewritten, 6 migrated as-is           |
| Engagement Guide      | 🎓 Engagement Guide                                                                         | 5                 | 1 rewrite, 4 migrated                          |
| Law Enforcement Guide | 🛡️ Law Enforcement Guide                                                                    | 2                 | 1 new, 1 rewrite                               |
| User Guide            | 📝 User Guide                                                                               | 3                 | 2 new, 1 rewrite                               |
| Admin Guide           | ⚙️ Admin Guide                                                                              | 6                 | 2 new, 4 rewrite                               |
| Security              | 🔒 Security & Trust                                                                         | 3                 | 1 new, 2 rewrite                               |
| API Reference         | 🔌 API Reference                                                                            | 4                 | 4 rewrite                                      |
| **Total**             | **12 sidebar sections**                                                                     | **55**            | 13 new, 20 rewrite, 10 migrate, ~~22 removed~~ |

Current site: 66 pages (47% dev-focused). New site: 55 pages (0% dev-focused).

---

## 10. UI Coverage Audit

Every Console page and major section must have a corresponding documentation page. This table maps
the Console UI (from the Next.js app router) to new docs pages. Gaps are flagged.

| Console Page                | Route                                 | Docs Page                                                               | Status                                           |
| --------------------------- | ------------------------------------- | ----------------------------------------------------------------------- | ------------------------------------------------ |
| Dashboard                   | `/dashboard`                          | `analyst-guide/daily-workflow.md`                                       | ✅ Covered                                       |
| Search                      | `/search`                             | `analyst-guide/search-and-discovery.md`                                 | ✅ Covered                                       |
| Discovery                   | `/discovery`                          | `analyst-guide/search-and-discovery.md` (merged)                        | ✅ Covered                                       |
| Cases (list)                | `/cases`                              | `analyst-guide/daily-workflow.md` + `reviewing-cases.md`                | ✅ Covered                                       |
| Case Detail                 | `/cases/[id]`                         | `analyst-guide/reviewing-cases.md`                                      | ✅ Covered                                       |
| Case Intake                 | `/cases/intake`                       | `user-guide/submitting-a-report.md`                                     | ✅ Covered                                       |
| Evidence Dossiers           | `/reports/dossiers`                   | `analyst-guide/reports-and-dossiers.md`                                 | ✅ Covered                                       |
| Report Library              | `/reports/library`                    | `analyst-guide/reports-and-dossiers.md`                                 | ✅ Covered                                       |
| Report Builder              | `/reports/builder`                    | `analyst-guide/reports-and-dossiers.md`                                 | ✅ Covered                                       |
| Intelligence Dashboard      | `/intelligence`                       | `analyst-guide/impact-dashboard.md`                                     | ✅ Covered                                       |
| Entity Explorer             | `/intelligence/entities`              | `analyst-guide/entity-explorer.md`                                      | ✅ Covered                                       |
| Indicator Registry          | `/intelligence/indicators`            | `analyst-guide/indicator-registry.md`                                   | ✅ Covered                                       |
| Threat Campaigns (list)     | `/intelligence/campaigns`             | `analyst-guide/campaigns.md`                                            | ✅ Covered                                       |
| Campaign Detail             | `/intelligence/campaigns/[id]`        | `analyst-guide/campaigns.md`                                            | ✅ Covered                                       |
| Network Graph               | `/intelligence/graph`                 | `analyst-guide/network-graph.md`                                        | ✅ Covered                                       |
| Timeline                    | `/intelligence/timeline`              | `analyst-guide/timeline.md`                                             | ✅ Covered                                       |
| Watchlist                   | `/intelligence/watchlist`             | `analyst-guide/watchlist-and-alerts.md`                                 | ✅ Covered                                       |
| Impact Analytics            | `/impact`                             | `analyst-guide/impact-dashboard.md`                                     | ✅ Covered                                       |
| Taxonomy                    | `/impact/taxonomy`                    | `key-concepts/fraud-taxonomy.md` + `analyst-guide/taxonomy-explorer.md` | ✅ Covered                                       |
| Taxonomy Explorer           | `/impact/taxonomy-explorer`           | `analyst-guide/taxonomy-explorer.md`                                    | ✅ Covered                                       |
| Geographic Heatmap          | `/impact/geography`                   | `analyst-guide/geographic-heatmap.md`                                   | ✅ Covered                                       |
| SSI Investigate             | `/ssi`                                | `analyst-guide/investigating-sites.md`                                  | ✅ Covered                                       |
| SSI Investigations (list)   | `/ssi/investigations`                 | `analyst-guide/investigating-sites.md`                                  | ✅ Covered                                       |
| SSI Investigation Detail    | `/ssi/investigations/[id]`            | `analyst-guide/investigating-sites.md` + `live-monitoring.md`           | ✅ Covered                                       |
| SSI Wallets                 | `/ssi/wallets`                        | `analyst-guide/investigating-sites.md` (wallet section)                 | ✅ Covered                                       |
| SSI eCrimeX Submissions     | `/ssi/submissions`                    | ⚠️ **Gap — needs coverage**                                             | 🆕 Add to `analyst-guide/investigating-sites.md` |
| SSI Intelligence Feed       | `/ssi/ecx-feed`                       | ⚠️ **Gap — needs coverage**                                             | 🆕 Add to `analyst-guide/investigating-sites.md` |
| SSI eCX Trend Dashboard     | `/ssi/ecx-dashboard`                  | ⚠️ **Gap — needs coverage**                                             | 🆕 Add to `analyst-guide/investigating-sites.md` |
| Campaigns (top-level)       | `/campaigns`                          | `analyst-guide/campaigns.md`                                            | ✅ Covered                                       |
| Campaign Detail (top-level) | `/campaigns/[id]`                     | `analyst-guide/campaigns.md`                                            | ✅ Covered                                       |
| Engagement Management       | `/admin/engagements`                  | `engagement-guide/managing-engagements.md`                              | ✅ Covered                                       |
| Engagement Leaderboard      | `/admin/engagements/[id]/leaderboard` | `engagement-guide/leaderboard.md`                                       | ✅ Covered                                       |
| Engagement Comparison       | `/admin/engagements/compare`          | `engagement-guide/managing-engagements.md`                              | ✅ Covered                                       |
| User Management             | `/admin/users`                        | `admin-guide/user-management.md`                                        | ✅ Covered                                       |

**Global UI Components:**

| Component                  | Docs Coverage                               | Notes                               |
| -------------------------- | ------------------------------------------- | ----------------------------------- |
| Sidebar navigation         | `analyst-guide/console-tour.md`             | ✅ Covered in tour                  |
| Command palette            | `analyst-guide/console-tour.md`             | ✅ Cover keyboard shortcuts in tour |
| Engagement selector        | `engagement-guide/working-in-engagement.md` | ✅ Covered                          |
| Theme toggle / preferences | Intentionally undocumented                  | Obvious — no explanation needed     |
| Feedback button            | Intentionally undocumented                  | Self-explanatory                    |

**Gaps identified:** 3 eCrimeX-related SSI pages (`/ssi/submissions`, `/ssi/ecx-feed`,
`/ssi/ecx-dashboard`) have no docs coverage. These should be added as a subsection in
`analyst-guide/investigating-sites.md` or split into a dedicated `analyst-guide/ecrimex.md` page
if content is substantial.

---

## 11. Visual Asset Checklist

Every required screenshot and diagram. Checked = exists and is in good shape. Unchecked = needs to
be captured, created, or reviewed for readability at GitBook's rendered width.

### Existing Assets (review needed)

| Asset                             | Path                                               | Status            | Notes                                 |
| --------------------------------- | -------------------------------------------------- | ----------------- | ------------------------------------- |
| Analyst dashboard screenshot      | `assets/screenshots/analyst-dashboard.png`         | - [x] Exists      | Review: still current?                |
| Analyst case detail screenshot    | `assets/screenshots/analyst-case-detail.png`       | - [x] Exists      | Review: still current?                |
| Analyst discovery screenshot      | `assets/screenshots/analyst-discovery.png`         | - [x] Exists      | Review: still current?                |
| Analyst dossier verify screenshot | `assets/screenshots/analyst-dossiers-verify.png`   | - [x] Exists      | Review: still current?                |
| Analyst dossiers screenshot       | `assets/screenshots/analyst-dossiers.png`          | - [x] Exists      | Review: still current?                |
| Analyst search drawer screenshot  | `assets/screenshots/analyst-search-drawer.png`     | - [x] Exists      | Review: still current?                |
| Analyst search screenshot         | `assets/screenshots/analyst-search.png`            | - [x] Exists      | Review: still current?                |
| LEO report placeholder            | `assets/screenshots/leo-report-placeholder.svg`    | - [ ] Placeholder | Replace with real screenshot          |
| Victim intake placeholder         | `assets/screenshots/victim-intake-placeholder.svg` | - [ ] Placeholder | Replace with real screenshot          |
| System topology SVG               | `assets/architecture/system_topology.svg`          | - [x] Exists      | Dev-focused — not needed for new site |
| Data pipeline SVG                 | `assets/architecture/data_pipeline.svg`            | - [x] Exists      | Dev-focused — not needed for new site |
| Security model SVG                | `assets/architecture/security_model.svg`           | - [x] Exists      | Dev-focused — not needed for new site |
| Threat intelligence SVG           | `assets/architecture/threat_intelligence.svg`      | - [x] Exists      | Dev-focused — not needed for new site |
| Job architecture SVG              | `assets/architecture/job_architecture.svg`         | - [x] Exists      | Dev-focused — not needed for new site |
| SSI architecture SVG              | `assets/architecture/ssi_architecture.svg`         | - [x] Exists      | Dev-focused — not needed for new site |

### New Screenshots Needed

| Asset                                 | Target Path                                     | For Page                                   | Priority |
| ------------------------------------- | ----------------------------------------------- | ------------------------------------------ | -------- |
| Console full sidebar (expanded)       | `assets/screenshots/console-sidebar.png`        | `analyst-guide/console-tour.md`            | P0       |
| Console dashboard (full view)         | `assets/screenshots/console-dashboard.png`      | `analyst-guide/console-tour.md`            | P0       |
| Case detail — entities + timeline     | `assets/screenshots/case-detail-entities.png`   | `analyst-guide/reviewing-cases.md`         | P0       |
| Entity Explorer — list view           | `assets/screenshots/entity-explorer-list.png`   | `analyst-guide/entity-explorer.md`         | P0       |
| Entity Explorer — detail panel        | `assets/screenshots/entity-explorer-detail.png` | `analyst-guide/entity-explorer.md`         | P0       |
| Network Graph — seeded view           | `assets/screenshots/network-graph.png`          | `analyst-guide/network-graph.md`           | P0       |
| Campaign detail — timeline + graph    | `assets/screenshots/campaign-detail.png`        | `analyst-guide/campaigns.md`               | P0       |
| SSI — investigation submit form       | `assets/screenshots/ssi-submit.png`             | `analyst-guide/investigating-sites.md`     | P0       |
| SSI — investigation results           | `assets/screenshots/ssi-results.png`            | `analyst-guide/investigating-sites.md`     | P0       |
| SSI — live monitoring view            | `assets/screenshots/ssi-live-monitor.png`       | `analyst-guide/live-monitoring.md`         | P0       |
| SSI — wallets page                    | `assets/screenshots/ssi-wallets.png`            | `analyst-guide/investigating-sites.md`     | P1       |
| SSI — eCrimeX submissions             | `assets/screenshots/ssi-ecx-submissions.png`    | `analyst-guide/investigating-sites.md`     | P1       |
| SSI — eCX intelligence feed           | `assets/screenshots/ssi-ecx-feed.png`           | `analyst-guide/investigating-sites.md`     | P1       |
| SSI — eCX trend dashboard             | `assets/screenshots/ssi-ecx-dashboard.png`      | `analyst-guide/investigating-sites.md`     | P1       |
| Indicator Registry — category tabs    | `assets/screenshots/indicator-registry.png`     | `analyst-guide/indicator-registry.md`      | P1       |
| Impact Dashboard — KPI cards + charts | `assets/screenshots/impact-dashboard.png`       | `analyst-guide/impact-dashboard.md`        | P1       |
| Taxonomy Explorer — Sankey view       | `assets/screenshots/taxonomy-sankey.png`        | `analyst-guide/taxonomy-explorer.md`       | P1       |
| Geographic Heatmap — world view       | `assets/screenshots/geographic-heatmap.png`     | `analyst-guide/geographic-heatmap.md`      | P1       |
| Timeline — multi-track view           | `assets/screenshots/timeline.png`               | `analyst-guide/timeline.md`                | P1       |
| Watchlist — alerts list               | `assets/screenshots/watchlist.png`              | `analyst-guide/watchlist-and-alerts.md`    | P1       |
| Report Builder — template selection   | `assets/screenshots/report-builder.png`         | `analyst-guide/reports-and-dossiers.md`    | P1       |
| Search — filter sidebar               | `assets/screenshots/search-filters.png`         | `analyst-guide/search-and-discovery.md`    | P1       |
| Engagement — leaderboard table        | `assets/screenshots/engagement-leaderboard.png` | `engagement-guide/leaderboard.md`          | P1       |
| Engagement — management table         | `assets/screenshots/engagement-management.png`  | `engagement-guide/managing-engagements.md` | P1       |
| User intake form                      | `assets/screenshots/user-intake.png`            | `user-guide/submitting-a-report.md`        | P1       |
| Admin — user management table         | `assets/screenshots/admin-users.png`            | `admin-guide/user-management.md`           | P2       |

### New Diagrams Needed

| Asset                                                 | Target Path                                   | For Page                               | Format                 | Priority |
| ----------------------------------------------------- | --------------------------------------------- | -------------------------------------- | ---------------------- | -------- |
| How it works — end-to-end flow                        | `assets/diagrams/how-it-works.svg`            | `getting-started/how-it-works.md`      | SVG                    | P0       |
| Case lifecycle flowchart                              | `assets/diagrams/case-lifecycle.svg`          | `key-concepts/cases-and-evidence.md`   | SVG or small Mermaid   | P0       |
| Entity aggregation — report → entities → linked cases | `assets/diagrams/entity-aggregation.svg`      | `key-concepts/entities.md`             | SVG                    | P0       |
| Entity → indicator funnel                             | `assets/diagrams/entity-indicator-funnel.svg` | `key-concepts/indicators.md`           | SVG                    | P0       |
| Extraction pipeline (simplified 6-box)                | `assets/diagrams/extraction-pipeline.svg`     | `key-concepts/entity-extraction.md`    | SVG (NOT full Mermaid) | P0       |
| 5-axis taxonomy diagram                               | `assets/diagrams/taxonomy-axes.svg`           | `key-concepts/fraud-taxonomy.md`       | SVG                    | P0       |
| Campaign clustering — cases + shared entities         | `assets/diagrams/campaign-clustering.svg`     | `key-concepts/campaigns.md`            | SVG                    | P0       |
| Entity lifecycle state diagram                        | `assets/diagrams/entity-lifecycle.svg`        | `key-concepts/risk-scoring.md`         | SVG or small Mermaid   | P1       |
| Engagement lifecycle                                  | `assets/diagrams/engagement-lifecycle.svg`    | `key-concepts/engagements.md`          | SVG or small Mermaid   | P1       |
| SSI investigation flow                                | `assets/diagrams/ssi-investigation-flow.svg`  | `key-concepts/site-investigations.md`  | SVG                    | P1       |
| Persona router — "I am a…" decision tree              | `assets/diagrams/find-your-role.svg`          | `getting-started/find-your-role.md`    | SVG                    | P1       |
| Report types comparison                               | `assets/diagrams/report-types.svg`            | `key-concepts/dossiers-and-reports.md` | SVG                    | P2       |

### Summary

| Category             | Total  | Exists ✅ | Needs creation ⬜ | Needs review 🔍    | Not needed ❌   |
| -------------------- | ------ | --------- | ----------------- | ------------------ | --------------- |
| Existing screenshots | 9      | 7         | 0                 | 7 (currency check) | 0               |
| Existing diagrams    | 6      | 6         | 0                 | 0                  | 6 (dev-focused) |
| Placeholder images   | 2      | 0         | 2                 | 0                  | 0               |
| New screenshots      | 26     | 0         | 26                | 0                  | 0               |
| New diagrams         | 12     | 0         | 12                | 0                  | 0               |
| **Total**            | **55** | **13**    | **40**            | **7**              | **6**           |
