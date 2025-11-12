# Intelligence for Good — Infrastructure

This repository manages Terraform modules, environment configuration, and automation for deploying the i4g platform on Google Cloud Platform. The workflow avoids Terraform Cloud/SaaS dependencies so everything can be executed locally or from GitHub Actions using Workload Identity Federation (WIF).

## Structure (proposed)
- `bootstrap/` — scripts to create the remote state bucket, enable APIs, and provision the automation service account.
- `environments/` — root modules for each environment (`dev`, `prod`) that compose reusable modules.
- `modules/` — building blocks for Cloud Run services, IAM roles, buckets, VPC connectors, schedulers, etc.
- `policy/` — optional Conftest/OPA policies for static analysis.
- `scripts/` — tooling wrappers for `terraform fmt`, `tflint`, drift detection, or credential helpers.
- `.github/workflows/` — GitHub Actions pipelines that run plan/apply via WIF.

## Remote State & Authentication
- Backend: native Terraform `gcs` backend per environment (`tfstate-i4g-dev`, `tfstate-i4g-prod`) with bucket versioning enabled. Locking relies on object generations; no external DB required.
- Bootstrap: run `bootstrap/create_state_bucket.sh <env>` once to create the bucket, enable required APIs, and configure `sa-infra@{project}` with least-privilege roles.
- Local auth: `gcloud auth login` then impersonate `sa-infra@{project}` in the backend block via `impersonate_service_account`.
- CI auth: GitHub Actions exchanges OIDC tokens for short-lived credentials through a WIF provider; grant `roles/iam.workloadIdentityUser` on `sa-infra@{project}`.

Example backend snippet:

```hcl
terraform {
	backend "gcs" {
		bucket                      = "tfstate-i4g-dev"
		prefix                      = "env/dev"
		impersonate_service_account = "sa-infra@i4g-dev.iam.gserviceaccount.com"
	}
	required_version = ">= 1.9.0, < 2.0.0"
}
```

## Dev → Prod Promotion Flow
1. Build and tag container images in dev (`:dev` tags) via application repo workflows.
2. Merge infra/app changes to `main`; `.github/workflows/terraform-dev.yml` applies to the `i4g-dev` project automatically.
3. After validation, retag approved image digests to `:prod` and update `environments/prod/terraform.tfvars` as needed.
4. Run `terraform plan/apply` from `environments/prod/` (manual or future GitHub Actions job) to promote infrastructure and service revisions.
5. Execute smoke tests (FastAPI/Streamlit health, Vertex AI Search connectivity) and log outcomes in `planning/change_log.md`.

## Getting Started
1. Install required tools: `terraform >=1.9`, `tflint`, `gcloud`.
2. Authenticate: `gcloud auth login && gcloud auth application-default login`.
3. Set quota project when working with Discovery Engine: `gcloud auth application-default set-quota-project i4g-dev`.
4. Run `./bootstrap/create_state_bucket.sh dev` to create the state bucket and automation SA.
5. `cd environments/dev && terraform init`.
6. `terraform plan` (override `-var "github_repository=owner/repo"` if using a fork).

## When Moving Projects Under the Official Org/Billing
1. Link projects to the nonprofit billing account:

		```bash
		gcloud beta billing projects link <project_id> \
			--billing-account=<BILLING_ACCOUNT_ID>
		```

2. Create a folder (optional) to group projects within the org, e.g. `i4g-environments`.
3. Move each project into the organization/folder:

		```bash
		gcloud beta projects move <project_id> \
			--organization=<ORG_ID>
		```

		Use `--folder=<FOLDER_ID>` when targeting a specific folder.
4. Update IAM so `sa-infra@{project}` keeps `roles/iam.serviceAccountTokenCreator`, `roles/iam.workloadIdentityUser`, and required admin roles at the new resource hierarchy level.
5. Re-run `terraform plan` from each environment to confirm IAM bindings remain aligned after the move.

## Guidelines
- Pin Terraform/core provider versions via `required_version` / `required_providers`.
- Model every IAM binding in Terraform; avoid manual grants to keep drift visible.
- Enforce PR review of plan output before apply; prefer automation via GitHub Actions.
- Never store long-lived service account keys—use impersonation or WIF.

## Related Repositories
- `intelligenceforgood/i4g` — application services.
- `intelligenceforgood/docs` — public documentation site.
- `intelligenceforgood/proto` — experimental prototypes.
