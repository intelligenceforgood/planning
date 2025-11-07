# Contributing to the Infrastructure Repository

## Workflow
1. Open an issue describing the change (new resource, update, fix).
2. Create a feature branch and implement the Terraform changes.
3. Run `terraform fmt`, `terraform validate`, and any lint/policy checks.
4. Capture the output of `terraform plan` and attach it to the pull request.
5. Request review before applying changes. Only designated maintainers should run `terraform apply` in shared environments.

## State Management
- Use the shared remote backend (GCS bucket) to avoid local state drift.
- Never commit `*.tfstate` files or credentials.
- Rotation of service account keys should follow the security checklist in the planning repo.

## CI/CD
- CI will run format, validate, and plan (no apply). Plans must succeed before merge.
- Policy-as-code (OPA or Terraform Cloud Sentinel) may be added later; follow the README for updates.

## Security
- Keep secrets in Secret Manager or GitHub Actions secrets; never in code.
- Audit IAM bindings for least privilege.
