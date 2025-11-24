# i4g Quick Prompts Cheat-Sheet (1 Page)

## Backend (Copilot Chat - 5.1 Codex)
- **New endpoint**: “Create FastAPI endpoint in `src/i4g/api/{name}.py` with models, service, Firestore async, OAuth guard.”
- **Add field**: “Add `{field}` to models, service, and router; ensure backward compatibility.”
- **PII safety**: “Audit PII flow; apply tokenization + masking; no raw PII in logs.”
- **RAG classify**: “Attach LangChain classifier to case creation; async background task recommended.”

## Frontend (Next.js 15 / React 19)
- **New page**: “Create `src/app/{route}/page.tsx` with server-side proxy and UI-kit components.”
- **Client component**: “Build client UI with Suspense + shadcn/ui; strongly typed props.”
- **API proxy**: “Create server action calling FastAPI with secret-injected header.”

## Infra (GCP via Gemini 3.1)
- **Cloud Run deploy YAML**: “Generate cloudrun.yaml with min/max instances, CPU boost, secrets, HTTPS-only.”
- **Firestore rules**: “Write zero-trust rules: analysts masked access, LEO read-only approved, backend bypass.”
- **IAM fix**: “Diagnose 403 Firestore failure for Cloud Run SA and give `roles/datastore.user`.”

## CI/CD (Copilot or Gemini)
- **Deploy pipeline**: “Create GH Actions workflow: lint, test, docker build, push to GAR, deploy to Cloud Run.”
- **PR validation**: “Add PR workflow: black, isort, mypy, eslint, pytest.”

## Debugging / Failure Modes
- **Cloud Run cold start**: “Recommend autoscaling, min instances, CPU allocation, import optimizations.”
- **Firestore perf**: “Add index for filter {field}; avoid client-side filtering.”
- **IAM errors**: “List missing roles; generate gcloud fixes.”

## Model Usage
- **Copilot**: “Implement code inside repo; keep changes small.”
- **ChatGPT Codex**: “Multi-file refactor; architecture guidance.”
- **Gemini 3.1**: “GCP IAM, Cloud Run, Firestore modeling.”

