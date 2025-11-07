# Intelligence for Good (i4g)

This repository will house the production-ready services, shared libraries, and runtime assets for the next-generation Intelligence for Good platform.

> Status: Milestone 2 (architecture + technology selection) in progress. Prototype experiments continue in the separate `proto` repo until decisions are locked.

## Repository Scope
- `services/` — application services (FastAPI APIs, Streamlit analyst UI, background workers).
- `packages/` — shared Python packages/modules reused across services.
- `docs/` — architecture notes and runbooks specific to production deployments.
- `ops/` — deployment scripts, CI/CD workflows, and runtime configuration (non-Terraform).

## Getting Started
1. Ensure Milestone 2 decisions (identity provider, retrieval backend, LLM host) are finalized.
2. Create a virtual environment and install dependencies once service scaffolding lands.
3. Follow CONTRIBUTING.md for branching, testing, and pull request guidelines.

## Related Repositories
- `intelligenceforgood/proto` — sandbox for experiments and throwaway prototypes.
- `intelligenceforgood/infra` — Terraform + infrastructure-as-code modules.
- `intelligenceforgood/docs` — public documentation site.
