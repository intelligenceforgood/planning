# Milestone 4 Infra Spike Checklist (Dec 2025)

Use this list while landing the Milestone 4 infra work (custom domains + IAP, PII vault split).

## Domains, DNS, and Cloud Run
- [ ] Verify/create Cloud DNS zone for `intelligenceforgood.org` (or document external DNS owner).
- [x] Add DNS records for `api.intelligenceforgood.org` and `app.intelligenceforgood.org` pointing to Cloud Run (CNAME to `ghs.googlehosted.com`) (DNS owner has created them).
- [x] Create Cloud Run domain mappings: `api.intelligenceforgood.org` → `fastapi-gateway`; `app.intelligenceforgood.org` → primary UI (Streamlit or console).
- [x] Enable managed certs and output mapped HTTPS URLs.
- [x] Update app/console env vars (`I4G_API__BASE_URL`, `NEXT_PUBLIC_API_BASE_URL`, etc.) to the custom domains.

## IAP / OAuth Alignment
- [ ] Ensure IAP brand allows the new domains; set `iap_manage_clients=true` and regenerate clients/secrets if needed.
- [ ] Update OAuth redirect URIs/origins for fastapi/streamlit/console to match the custom domains.
- [ ] Document allowed domains and CORS preflight expectations.

## Environment Layout & State
- [x] Move app environments to `environments/app/{dev,prod}`.
- [ ] Bootstrap/confirm state buckets for app (`tfstate-i4g-dev`, `tfstate-i4g-prod`) with updated backend paths.
- [x] Add new env roots for PII vault (`environments/pii-vault/{dev,prod}`) with backends (e.g., `tfstate-i4g-pii-dev/prod`).

## PII Vault Projects (if adopted)
- [ ] Create projects `i4g-pii-vault-dev` and `i4g-pii-vault-prod` (or agreed naming) and enable required APIs (Secret Manager, KMS).
- [ ] Define baseline modules: KMS key ring/keys, Secret Manager placeholders, audit logging, bucket policy lock as needed.
- [ ] Output shared resources (secret names, KMS key IDs) for consumption by app projects.

## Cross-Project Access
- [ ] Grant app runtime service accounts the minimal roles on vault resources (Secret Manager accessor, KMS cryptoKeyEncrypterDecrypter).
- [ ] Add tests/docs showing how to wire env vars from vault secrets into Cloud Run without storing copies in the app project.

## CI / Automation
- [ ] Update GitHub Actions variables/paths to match `environments/app/*` (and future `pii-vault/*`).
- [ ] Add `terraform fmt/plan` coverage for new env roots.

## Documentation
- [ ] Refresh `infra/README.md` and runbooks with domain mapping steps, DNS record values, and cross-project IAM pattern.
- [ ] Note any manual DNS actions if zone is externally managed.
