# i4g Model Workflow Guide (Option A – Full Version)

## Table of Contents
- [Overview of Each Model](#overview)
- [Strengths & Weaknesses](#strengths--weaknesses)
- [Decision Tree](#decision-tree)
- [Scenario Playbook](#scenario-playbook)
- [Daily Workflow Templates](#daily-workflow-templates)
- [Troubleshooting & Fallbacks](#troubleshooting--fallbacks)

---

# Overview
This guide compares ChatGPT 5.1 CODEX (Copilot), ChatGPT Codex (web), and Gemini 3.1.

- **Copilot 5.1 CODEX**: best inline coding and IDE automation.
- **ChatGPT Codex**: best for architecture/refactors.
- **Gemini 3.1**: best for GCP infrastructure and deployments.

---

# Strengths & Weaknesses
| Task | Copilot 5.1 CODEX | ChatGPT Codex | Gemini 3.1 |
|------|--------------------|----------------|--------------|
| FastAPI coding | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| Next.js coding | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| RAG + LangChain | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| Firestore | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| Cloud Run | ⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| IAM | ⭐⭐ | ⭐ | ⭐⭐⭐⭐⭐ |

---

# Decision Tree
<details><summary><strong>Click to Expand</strong></summary>

### Step 1: Is it code or infrastructure?
- Code → Copilot
- Infra → Gemini
- Architecture → ChatGPT Codex

### Step 2: Is it multi-file or repo-wide?
- Yes → ChatGPT Codex  
- No → Copilot

### Step 3: Does it involve GCP IAM/VPC?
- Yes → Gemini

</details>

---

# Scenario Playbook

<details><summary><strong>Backend Work</strong></summary>

### Use Copilot:
- CRUD endpoints
- Pydantic models
- Router/service refactor

### Use ChatGPT Codex:
- Repo-wide consistency check
- Large scale refactor
</details>

<details><summary><strong>Frontend Work</strong></summary>

### Use Copilot:
- Client components
- App router logic

### Use ChatGPT Codex:
- UI restructuring
</details>

<details><summary><strong>Infrastructure Work</strong></summary>

### Use Gemini:
- Cloud Run deploy YAML
- IAM fixes
- Firestore indexes
</details>

---

# Daily Workflow Templates

<details><summary><strong>Template: Coding Day</strong></summary>

1. Start in VS Code with Copilot 5.1 CODEX  
2. Ask high-level prompt  
3. Implement features incrementally  
4. Switch to ChatGPT Codex for bigger decisions  
</details>

<details><summary><strong>Template: Infra Day</strong></summary>

1. Open Gemini  
2. Ask for architecture/GCP patterns  
3. Implement IAM or Cloud Run fixes  
</details>

---

# Troubleshooting & Fallbacks

- If Copilot fails → switch to ChatGPT Codex.
- If GCP permissions fail → use Gemini.
- If structure drifts → have ChatGPT Codex repair repo hierarchy.

---

End of Workflow Guide.
