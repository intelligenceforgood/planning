# i4g Gemini 3.1 Prompt Pack (Option A – Full Version)
## Table of Contents
- [Overview](#overview)
- [GCP Infra](#gcp-infra)
- [Firestore Rules & Modeling](#firestore-rules--modeling)
- [Cloud Run Deployment & Performance](#cloud-run-deployment--performance)
- [Secret Manager & IAM](#secret-manager--iam)
- [Networking / VPC / Egress](#networking--vpc--egress)
- [CI/CD (Gemini-Specific)](#cicd-gemini-specific)
- [RAG / Embeddings / Model Selection](#rag--embeddings--model-selection)
- [Failure Analysis / Debugging](#failure-analysis--debugging)

---

# Overview
Gemini excels at:
- Understanding **Google Cloud** primitives.
- Generating **IAM policies**, **Cloud Run configs**, **Firestore rules**, **VPC connectors**.
- Debugging GCP deployments and permission errors.
- Optimizing Cloud Run performance and egress settings.

Use these prompts inside **Copilot Chat with the Gemini 3.1 Code model** or directly in Gemini Studio.

---

# GCP Infra

<details><summary><strong>G1: Generate Cloud Run IaC</strong></summary>

```
I need a Cloud Run deployment config for the i4g backend.

Requirements:
- region: us-central1
- container: ghcr.io/jsoung/i4g-backend:latest
- always use Cloud Run CPU-boosting
- request concurrency = 10
- min instances = 0
- max instances = 5
- mount Secret Manager secrets as env vars
- set connection to Firestore and GCS automatically via ADC
- enforce HTTPS-only ingress

Produce cloudrun.yaml using gcloud / YAML format.
```
</details>

<details><summary><strong>G2: Architecture Diagram (Text)</strong></summary>

```
Generate a text-based architecture diagram of the i4g system showing:

User → Cloud Run frontend → Cloud Run API → Firestore, GCS, Secret Manager → Ollama (local or remote)
```
</details>

<details><summary><strong>G3: Cloud Run Autoscaling Tuning</strong></summary>

```
Given this workload profile, tune Cloud Run autoscaling:
- each request performs Firestore reads/writes
- optional RAG calls
- average runtime: 120ms
- occasional spikes to 40 concurrent users

Provide recommended:
- min/max instances
- max concurrency
- CPU/memory sizing
- connection pooling strategy
```
</details>

---

# Firestore Rules & Modeling

<details><summary><strong>F1: Zero-Trust Firestore Rules</strong></summary>

```
Write Firestore security rules for i4g enforcing:

Collections:
- cases
- analysts
- pii_vault

Rules:
- analysts cannot read PII vault
- analysts can read masked cases only
- LEOs can read approved cases only
- users can write only their own case
- backend service account bypasses these restrictions

Include full Firestore rules syntax.
```
</details>

<details><summary><strong>F2: Firestore Index Definitions</strong></summary>

```
Generate firestore.indexes.json definitions for:

Collection: cases
Queries:
- where status = X order by created_at desc
- where analyst_id = X order by updated_at desc
- where scam_type = X order by created_at desc
```
</details>

<details><summary><strong>F3: Modeling Recommendations</strong></summary>

```
Recommend Firestore document structure for cases with subcollections:

cases/{id}
- metadata
- classification
- audit_log/*
- attachments/*

Explain trade-offs of subcollections vs embedding fields.
```
</details>

---

# Cloud Run Deployment & Performance

<details><summary><strong>C1: Cold Start Reduction</strong></summary>

```
i4g backend has occasional cold starts.
Suggest optimizations:
- min instances
- CPU boost flags
- keep-alive strategies
- Python optimization flags
- GCP-specific environment tweaks
```
</details>

<details><summary><strong>C2: Analyze a Deployment Error</strong></summary>

```
Given this error:

ERROR: Permission 'run.services.update' denied for service account.

Diagnose likely causes and provide Cloud IAM commands to fix it.
```
</details>

<details><summary><strong>C3: Side-by-Side Diff of Two YAMLs</strong></summary>

```
Compare these two Cloud Run YAMLs and explain differences in:
- scaling
- environment
- IAM
- networking

Return a diff and summary.
```
</details>

---

# Secret Manager & IAM

<details><summary><strong>S1: Secret Manager Template</strong></summary>

```
Generate a Secret Manager usage snippet in Python for FastAPI startup:

- load SECRET_KEY
- load OPENAI_API_KEY
- load GEMINI_API_KEY
- cache secrets

Use google-cloud-secretmanager asynchronous client.
```
</details>

<details><summary><strong>S2: IAM Policy for Backend</strong></summary>

```
Create IAM policy allowing:
- read/write to Firestore
- read/write to GCS bucket i4g-evidence
- read-only access to secrets
- Cloud Run invoke permissions for frontend

Produce gcloud CLI commands.
```
</details>

<details><summary><strong>S3: Diagnose IAM 403 Errors</strong></summary>

```
Diagnose IAM 403 for Firestore read/write on Cloud Run service account.

Provide:
- likely root causes
- how to check permissions
- gcloud commands to fix
```
</details>

---

# Networking / VPC / Egress

<details><summary><strong>N1: VPC Connector Setup</strong></summary>

```
Generate commands to create a VPC Serverless Connector for Cloud Run:

- region: us-central1
- name: i4g-connector
- egress: all-traffic
- required firewall rules

Explain when it's needed.
```
</details>

<details><summary><strong>N2: Cloud NAT Configuration</strong></summary>

```
Show how to configure Cloud NAT so Cloud Run services have stable outbound IPs.
```
</details>

---

# CI/CD (Gemini-Specific)

<details><summary><strong>D1: GitHub Actions → GCP Deploy</strong></summary>

```
Write a deploy.yaml workflow:

- build Docker
- push to Artifact Registry
- auth using Workload Identity Federation
- deploy to Cloud Run
- run smoke test after deployment
```
</details>

<details><summary><strong>D2: Slack Notification Integration</strong></summary>

```
Add a Slack webhook step to notify deployment status.
```
</details>

---

# RAG / Embeddings / Model Selection

<details><summary><strong>R1: Recommend Embedding Models</strong></summary>

```
Based on constraints:
- Cloud Run CPU only
- local Ollama fallback
- ChromaDB usage

Recommend:
- best embedding model (BGE-small, nomic-embed-text, etc)
- caching strategy
- warm-start technique
```
</details>

<details><summary><strong>R2: Gemini Embedding Pipeline</strong></summary>

```
Show code for calling Gemini embedding model; compare vs local embedding model in Ollama.
```
</details>

---

# Failure Analysis / Debugging

<details><summary><strong>X1: Diagnose Timeout</strong></summary>

```
Case ingestion endpoint timing out after 10s.

Diagnose:
- Firestore latency
- Cloud Run CPU throttling
- missing indexes
- blocking synchronous code
```
</details>

<details><summary><strong>X2: Cloud Run CrashLoop Debugging</strong></summary>

```
API keeps restarting.
Check:
- memory limits
- startup health check
- missing environment vars
- secret manager failures
```
</details>

---

End of Gemini 3.1 Prompt Pack.
