# PII Vault Spike Checklist (Dec 2025)

Use this checklist to stand up dedicated vault projects and wire least-privileged access from app runtimes.

## Projects & State
- [ ] Create `i4g-pii-vault-dev` and `i4g-pii-vault-prod` projects (or agreed naming).
- [ ] Configure Terraform backends/state buckets for the vault roots (dev/prod) and document init commands.

## KMS & Secrets
- [ ] Create KMS key ring/keys per env with rotation policy; record resource IDs for consumers.
- [ ] Seed baseline Secret Manager entries (placeholders OK) and wire KMS protection where required.
- [ ] Document rotation/runbook (owners, cadence, break-glass).

## Cross-Project Access
- [ ] Grant app runtime SAs (dev/prod) secret accessor + cryptoKeyEncrypterDecrypter via WIF; avoid broad roles.
- [ ] Add a small verifier (script or test) that fetches a vault secret using the app SA to validate bindings.

## App Integration
- [ ] Map Cloud Run env vars to vault secrets; remove duplicated secrets from app projects.
- [ ] Add regression/tests to ensure missing secret access fails loud with clear guidance.
- [ ] Smoke: Cloud Run dev reads a vault-secret value; confirm prod plan before promotion.

## CI / Automation
- [ ] Add Terraform fmt/plan coverage for new vault roots; set required GH Action vars (project/state bucket names).

## Documentation
- [ ] Update `infra/README.md` (vault layout, init, apply).
- [ ] Update `docs/config/` (env-var table) and any app runbooks that reference secret sources.
