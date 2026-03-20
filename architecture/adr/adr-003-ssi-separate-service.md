# ADR-003: SSI as a Separate Service, Not Embedded in Core

**Status:** ACCEPTED  
**Date:** 2025  
**Deciders:** CTO, Chief Architect, SSI tech lead

---

## Context

The Scam Site Investigator (SSI) performs autonomous browser-based investigations of scam URLs using Playwright and zendriver (undetected Chrome). It was initially developed as a standalone tool and later integrated into the platform. At integration time, the team had to decide whether to embed SSI's logic in `core-svc` or run it as a separate service.

Key tensions:

- SSI requires a full Chromium browser installation (Playwright), which significantly increases the Docker image size
- SSI investigations are long-running (minutes to tens of minutes), while core API requests are expected to respond in seconds
- SSI has its own database schema, LLM configuration, proxy configuration, and storage patterns
- SSI was being developed by a separate team track with independent deployments
- SSI needed its own rate limiting, cost controls (Gemini token budget, investigation budget cap), and proxy management

---

## Decision

**SSI runs as a separate Cloud Run service (`ssi-svc`) on port 8100. Core-svc communicates with SSI via HTTP API calls, not library imports.**

The integration contract is documented in `planning/architecture/integration_contracts.md`:

- Core triggers SSI investigations via `POST {ssi.service_url}/trigger/investigate`
- SSI pushes results back to core via `push_to_core=true` (HTTP POST to core's case API)
- SSI streams live investigation events to core via `HttpEventSink`
- The UI routes investigation lifecycle calls through core; eCX-specific calls go directly to SSI

---

## Alternatives Considered

| Alternative                                         | Why Rejected                                                                                                                                                                                 |
| --------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Embed SSI as a Python library in `core-svc`         | Docker image bloat (Chromium ~600MB); long-running browser sessions would hold core API worker threads; independent scaling impossible; SSI's LLM cost controls would constrain core         |
| SSI as a Cloud Run job (not a long-lived service)   | Investigations need persistent WebSocket connections for live monitoring; job model doesn't support long-lived bidirectional streams; startup latency too high for interactive investigation |
| SSI as a background task within core (same process) | Same as library embedding — resource contention, coupling, independent deployment blocked                                                                                                    |
| Shared codebase, separate Docker targets            | Deployment separation satisfied, but code coupling would make SSI and core's dependency graphs entangle; Playwright import at core startup even when not needed                              |

---

## Consequences

**Positive:**

- SSI has independent scaling configuration (separate Cloud Run service with its own concurrency and memory limits suitable for running Chromium)
- SSI can be deployed, updated, and rolled back independently of core
- SSI's Gemini token budget, investigation cost cap, and proxy configuration are isolated from core's LLM settings
- Core remains a lightweight API service without Chromium or browser dependencies
- `ssi-svc` can be turned off without affecting the core review workflow

**Negative / trade-offs:**

- Cross-service communication adds latency and failure modes (SSI unreachable → core must handle gracefully)
- Shared data (investigation results, case enrichment) requires explicit contracts instead of shared ORM models
- Two FastAPI services means two sets of CORS configs, auth configurations, Docker images, and Cloud Run deployments to maintain
- The `ssi_*` router group in core is the proxy/adapter layer — it must be kept in sync with SSI's actual API

---

## Related Decisions

- ADR-001: GCP migration (both services run on Cloud Run)
- ADR-002: FastAPI + Pydantic v2 (SSI uses the same stack independently)
