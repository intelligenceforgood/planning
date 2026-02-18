# SSI Next Steps: Local → Cloud → Platform Integration

> **Last Updated**: February 18, 2026
> **Status**: Planning
> **Prerequisite**: Complete local prototype testing

This document outlines the roadmap to take SSI from a locally-running prototype to a production service integrated with the i4g platform on GCP.

---

## Current State

SSI runs locally on a developer laptop with:

- **Ollama** (Llama 3.3) for LLM inference
- **Playwright** for browser automation
- **Local filesystem** for evidence storage
- **CLI** (`ssi investigate url ...`) as the primary interface
- **FastAPI** on port 8100 as the API interface

All core capabilities are implemented: passive OSINT, AI agent interaction, synthetic identity generation, fraud classification, evidence packaging (JSON, Markdown, STIX 2.1, ZIP with chain-of-custody), and i4g core bridge.

---

## Phase 1: Local Testing & Validation

**Goal**: Thoroughly test the prototype against real scam sites and validate evidence quality.

**Status**: Ready to begin

| Task                       | Description                                                                                          |
| -------------------------- | ---------------------------------------------------------------------------------------------------- |
| Test against 20+ scam URLs | Cover different scam types: phishing, fake shops, tech support, crypto, romance                      |
| Validate evidence packages | Confirm reports are readable, STIX bundles import into threat intel tools, ZIP manifests are correct |
| Measure agent reliability  | Track success rate of end-to-end funnel traversal across scam types                                  |
| Test CAPTCHA handling      | Verify detection and graceful degradation across reCAPTCHA, hCaptcha, Turnstile                      |
| Benchmark performance      | Measure investigation time and Ollama token usage per scam type                                      |
| Test batch mode            | Run `ssi investigate batch` against a curated URL list                                               |
| Document failure modes     | Identify and log sites where the agent fails (anti-bot, complex JS, CAPTCHAs)                        |
| Refine prompts             | Tune LLM prompts based on failure analysis                                                           |

**Exit criteria**: ≥70% of submitted URLs are successfully traversed; evidence quality is LEA-acceptable.

---

## Phase 2: GCP Cloud Run Deployment

**Goal**: Deploy SSI as Cloud Run services/jobs in the `i4g-dev` GCP project.

**Depends on**: Phase 1 exit criteria met.

| Task                       | Description                                                                                                         |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| **Docker image hardening** | Verify `ssi-api.Dockerfile` and `ssi-job.Dockerfile` build cleanly; test with Playwright in headless + sandbox mode |
| **Artifact Registry**      | Push images to `us-central1-docker.pkg.dev/i4g-dev/applications/ssi-api:dev` and `ssi-job:dev`                      |
| **Secret Manager**         | Store API keys (`ssi-virustotal-api-key`, `ssi-ipinfo-token`, `ssi-urlscan-api-key`) in GCP Secret Manager          |
| **Cloud Run Service**      | Deploy `ssi-api` as a Cloud Run service (2 vCPU / 4GB RAM, min 0 / max 3 instances)                                 |
| **Cloud Run Job**          | Deploy `ssi-investigate-job` for async investigations (2 vCPU / 4GB, 10-min timeout)                                |
| **GCS evidence bucket**    | Create `i4g-dev-ssi-evidence` bucket; configure SSI to write evidence there (`SSI_EVIDENCE__STORAGE_BACKEND=gcs`)   |
| **Vertex AI integration**  | Switch LLM from Ollama to Vertex AI Gemini 2.0 Flash (`SSI_LLM__PROVIDER=vertex`)                                   |
| **Terraform**              | Add SSI resources as `ssi_*.tf` in `infra/environments/app/dev/`                                                    |
| **IAM**                    | Create `sa-ssi` service account; grant Cloud Run invoker, GCS writer, Secret Manager accessor, Vertex AI user       |
| **CI/CD**                  | GitHub Actions workflow: lint → test → build → push → deploy to Cloud Run                                           |
| **Monitoring**             | Cloud Logging structured logs; Cloud Monitoring alerts for error rate and latency                                   |
| **Smoke tests**            | Automated post-deploy smoke: `ssi job investigate --url <test-url> --passive`                                       |

**Exit criteria**: SSI API reachable at `https://ssi-api-*.run.app`; Cloud Run Job completes investigations; evidence lands in GCS.

---

## Phase 3: i4g Platform Integration

**Goal**: Wire SSI into the i4g platform so investigations can be triggered from the analyst console and results flow into the case management pipeline.

**Depends on**: Phase 2 deployed and stable.

| Task                    | Description                                                                                              |
| ----------------------- | -------------------------------------------------------------------------------------------------------- |
| **Core API endpoint**   | Add `POST /investigations/ssi` to core API that triggers an SSI Cloud Run Job                            |
| **Task tracking**       | SSI job reports progress to core's TASK_STATUS system (same pattern as report generation)                |
| **Evidence attachment** | SSI evidence ZIP attaches to case records via the existing evidence attachment system                    |
| **Taxonomy mapping**    | SSI classification output maps to core's five-axis fraud taxonomy; store as a classification record      |
| **Analyst console UI**  | Add "Investigate URL" action in the Next.js console — form submits URL, shows progress, displays results |
| **Victim intake flow**  | When a victim submits a scam URL via intake, optionally trigger an SSI investigation automatically       |
| **Dossier enrichment**  | SSI infrastructure intelligence (WHOIS, DNS, GeoIP, IOCs) feeds into dossier generation                  |
| **Shared types**        | Extract `ScamClassification` and common models into `i4g-common` or use SSI as a direct dependency       |
| **Auth**                | SSI API authenticates via IAP or API key (same as core)                                                  |

**Exit criteria**: Analyst can trigger investigation from console; results appear in case view; evidence is attached.

---

## Phase 4: Hardening & Scale

**Goal**: Production-grade reliability, security, and cost management.

| Task                         | Description                                                                    |
| ---------------------------- | ------------------------------------------------------------------------------ |
| **Rate limiting**            | Enforce per-tenant investigation limits                                        |
| **Cost budgets**             | Per-investigation and per-tenant budget caps with alerts                       |
| **Proxy infrastructure**     | Deploy residential proxy rotation for anti-detection                           |
| **CAPTCHA solver**           | Integrate a CAPTCHA solving service (2Captcha, Anti-Captcha)                   |
| **Redis task queue**         | Replace in-memory task tracking with Redis (shared with core)                  |
| **Database-backed feedback** | Move feedback loop from SQLite to Cloud SQL                                    |
| **Multi-region**             | Deploy in multiple regions for geographic diversity in investigations          |
| **Retention policy**         | Automated evidence retention/cleanup per `SSI_EVIDENCE__RETAIN_DAYS`           |
| **Legal review**             | Obtain legal opinion on automated interaction with scam sites under CFAA / CMA |
| **LEA pilot**                | Partner with 1-3 law enforcement agencies for real-world testing               |

---

## Phase 5: Advanced Capabilities

**Goal**: Extend SSI beyond the initial scope.

| Task                     | Description                                                                           |
| ------------------------ | ------------------------------------------------------------------------------------- |
| **Malware sandbox**      | Integrate Joe Sandbox or ANY.RUN API for downloaded file analysis                     |
| **Campaign linking**     | Identify related scam sites using shared infrastructure (IP, hosting, registrar, SSL) |
| **Threat intel sharing** | Publish STIX bundles to TAXII feeds for community threat intel                        |
| **Multi-language**       | Test and tune LLM prompts for non-English scam sites                                  |
| **Mobile deep links**    | Investigate scam links that target mobile apps (e.g., fake banking apps)              |
| **Real-time monitoring** | Continuous monitoring of known scam infrastructure for changes                        |
| **API marketplace**      | Offer SSI as a service for other anti-fraud organizations                             |

---

## Resource Estimates

| Phase                          | Duration  | Effort                    |
| ------------------------------ | --------- | ------------------------- |
| Phase 1 — Local testing        | 1–2 weeks | 1 engineer                |
| Phase 2 — GCP deployment       | 2–3 weeks | 1 engineer + infra        |
| Phase 3 — Platform integration | 2–3 weeks | 1–2 engineers (core + UI) |
| Phase 4 — Hardening            | Ongoing   | Part-time                 |
| Phase 5 — Advanced             | Future    | TBD                       |

---

## Decision Points

| Decision                        | When    | Options                                                |
| ------------------------------- | ------- | ------------------------------------------------------ |
| Switch from Ollama to Vertex AI | Phase 2 | Gemini 2.0 Flash (recommended) vs. GPT-4o via proxy    |
| Dedicated GCP project           | Phase 4 | Stay in `i4g-dev` (recommended) vs. split to `ssi-dev` |
| CAPTCHA strategy                | Phase 4 | External solver service vs. graceful skip              |
| Malware analysis                | Phase 5 | Joe Sandbox API vs. ANY.RUN vs. in-house               |
