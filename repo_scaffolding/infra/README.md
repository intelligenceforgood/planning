# Intelligence for Good — Infrastructure

This repository manages Terraform modules, environment configuration, and automation for deploying the i4g platform on Google Cloud Platform.

## Structure (proposed)
- `environments/` — environment-specific configuration (e.g., `dev`, `staging`, `prod`).
- `modules/` — reusable Terraform modules (Cloud Run services, Cloud Storage buckets, IAM roles, etc.).
- `scripts/` — helper scripts for bootstrapping state, linting, or CI pipelines.
- `.github/workflows/` — automation for plan/apply, lint, and policy checks.

## Getting Started
1. Configure Terraform state storage (recommended: GCS bucket + DynamoDB-like locking via Cloud Storage backends or Terraform Cloud).
2. Set required environment variables/secrets for CI (service account JSON, project IDs).
3. Run `terraform init` within the target environment directory before planning/applying.

## Guidelines
- Keep Terraform versions pinned via `required_version`.
- Prefer least-privilege IAM roles and document every binding.
- Use pull requests for all infrastructure changes; plans must be reviewed before apply.

## Related Repositories
- `intelligenceforgood/i4g` — application services.
- `intelligenceforgood/docs` — public documentation site.
- `intelligenceforgood/proto` — experimental prototypes.
