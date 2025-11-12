# Public-Facing Infrastructure TODO (docs.i4g.io / app.i4g.cloud / GitHub org)

Last updated: 2025-11-06

This is a short, shareable todo for setting up public-facing infrastructure for i4g. Save this as a reference and pick up items when you have time.

## Objectives
- Launch a public documentation site: `docs.i4g.io` (Docusaurus or MkDocs)
- Launch a hosted app: `app.i4g.cloud` (Cloud Run + Firebase Auth)
- Create a GitHub organization and repo conventions for i4g development

---

## Tasks

- [ ] Decide domain names and GitHub org
  - ✅ GitHub org created: `intelligenceforgood`
  - Domain strategy still pending (`i4g.org` vs `i4g.io`/`i4g.cloud`).
  - Note: choose a short, recognizable org name if available (keeps repo links short).

- [ ] Scaffold docs site
  - Repo: `intelligenceforgood/docs` (baseline README/CONTRIBUTING/PR template in place; generator TBD)
  - Tech: Docusaurus (React) or MkDocs (Python) — Docusaurus recommended for extensibility.
  - CI/CD: GitHub Actions building and deploying to GitHub Pages or Cloud Run + Cloud CDN.
  - Content skeleton: Quickstart, Architecture, API, Contributing, FAQ.
  - Template starter in repo: see `planning/repo_scaffolding/docs/` for README, LICENSE, CONTRIBUTING, PR template.

- [x] Scaffold hosted app repo (baseline docs committed 2025-11-06)
  - Repo: `intelligenceforgood/i4g`
  - Deploy: Cloud Run (managed)
  - Auth: Google Cloud Identity or Firebase Auth (decision pending Milestone 2)
  - Environments: `i4g-dev`, `i4g-prod` GCP projects (two-environment strategy; no staging tier)
  - CI/CD: GitHub Actions + Terraform in the `infra` repo for infra-as-code
  - Template starter in repo: see `planning/repo_scaffolding/i4g/` for README, LICENSE, CONTRIBUTING, issue/PR templates.

- [ ] Create `infra` repo and Terraform templates
  - Repo: `intelligenceforgood/infra` (baseline README/CONTRIBUTING/PR template in place; modules pending)
  - Modules for: Cloud Run service, Cloud Storage buckets, Cloud DNS records, Cloud CDN, Certificate Manager, IAM roles
  - Include a minimal `bootstrap` script for initial project & DNS setup
  - Template starter in repo: see `planning/repo_scaffolding/infra/` for README, LICENSE, CONTRIBUTING, PR template.

- [ ] GitHub org & repo standards
  - Create repo templates (service, library, docs)
  - Configure branch protection, issue & PR templates, CODEOWNERS
  - Enable Dependabot, pre-commit hooks, and basic code scanning

- [ ] Security & operations checklist
  - DNS and TLS (use Certificate Manager or managed certificates)
  - Secret storage: Secret Manager; never commit secrets
  - Service accounts: least-privilege roles, separate SA per workload
  - Monitoring: Cloud Monitoring (uptime, errors), Logging exports if needed
  - On-call / runbooks: simple incident process and contact list

- [ ] Community & governance
  - Decide communication channels (docs, forum, Slack/Discord)
  - Create CONTRIBUTING.md, CODE_OF_CONDUCT.md, and LICENSE (MIT recommended)
  - Prepare short onboarding for volunteers (how to get access, repo etiquette)

---

## Notes for volunteers / non-technical stakeholders
- I will prepare short, plain-English status updates weekly (1–2 paragraphs) so volunteers can stay informed without attending meetings.
- The default strategy is to prioritize the docs site first (easy to publish) and then the hosted app.
- I recommend we start with free-tier GCP projects and request nonprofit credits before incurring costs.

---

## Where to start (quick picks)
1. Configure domain + DNS (`i4g.org` vs `i4g.io`) and stand up `docs` / `app` subdomains.
2. Populate the new repos using the templates in `planning/repo_scaffolding/`.
3. Stand up CI pipelines (lint/tests for app, terraform plan for infra, docs build/deploy).


*Saved in `dtp/system_review/public_infra_todo.md`*
