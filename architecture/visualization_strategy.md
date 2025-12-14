# Architecture Visualization Strategy

## Executive Summary

We will establish a dedicated repository (`i4g/arch-viz`) to house the tooling and definitions for generating "Diagrams as Code". This approach treats architecture diagrams as software artifacts—versioned, reviewable, and reproducible—using the [Python Diagrams](https://diagrams.mingrammer.com/) library.

## 1. Repository Strategy

**Name:** `i4g/arch-viz` (Proposed)

**Purpose:**
*   Centralize all architecture diagram definitions.
*   Provide a consistent Python environment for rendering.
*   Decouple visualization logic from infrastructure code (`infra`) and documentation (`docs`), while linking them via outputs.

**Structure:**
```text
arch-viz/
├── README.md               # Setup and workflow guide
├── pyproject.toml          # Dependencies (diagrams, graphviz, etc.)
├── src/
│   ├── shared/             # Common clusters (e.g., "GCP Project Wrapper", "VPC")
│   └── views/              # Specific diagram definitions
│       ├── system_topology.py
│       ├── data_pipeline.py
│       └── security_model.py
├── output/                 # Generated PNG/SVG files (gitignored or committed)
└── scripts/
    └── generate_all.sh     # Batch generation
```

## 2. Technology Stack

*   **Core Library:** [Diagrams](https://diagrams.mingrammer.com/) (Python).
*   **Rendering Engine:** Graphviz.
*   **Infrastructure Source:** `i4g/infra` (Terraform HCL).
*   **AI Assistant:** GitHub Copilot / Gemini (for HCL-to-Python translation).

## 3. Workflow: "HCL to Diagram"

We will adopt a **Semi-Automated AI-Assisted Workflow** for Phase 1.

1.  **Select Scope:** Developer identifies a module in `infra` (e.g., `modules/run`) or an environment (`environments/app/dev`) to visualize.
2.  **Translate (AI Task):**
    *   Developer provides the HCL code to the LLM.
    *   Prompt: *"Read this Terraform HCL and generate a Python script using the `diagrams` library to visualize it. Use GCP nodes. Group resources by VPC/Subnet if visible."*
3.  **Refine (Human Task):**
    *   Save the script to `src/views/<view_name>.py`.
    *   Adjust logical groupings, labels, and data flow arrows to represent *intent* rather than just *dependency*.
4.  **Render:**
    *   Run `python src/views/<view_name>.py`.
5.  **Publish:**
    *   Copy the output image to `i4g/docs/book/assets/architecture/`.
    *   Commit the Python script to `arch-viz`.

## 4. Implementation Roadmap

### Phase 1: Scaffolding & Prototype (Immediate)
*   Initialize `arch-viz` structure.
*   Define dependency management (Poetry or pip).
*   **Milestone:** Re-create the existing "System Topology" diagram using Python code to prove the concept.

### Phase 2: Component Library
*   Create reusable Python classes for standard i4g patterns (e.g., `CloudRunService` wrapper that implies IAM binding).
*   Standardize styling (colors, fonts) to match i4g branding.

### Phase 3: Automation (Future)
*   Explore `python-hcl2` to parse `infra` files directly for dynamic updates.
*   CI/CD integration: Fail build if diagrams are outdated (requires deterministic generation).

## 5. Integration with Existing Repos

*   **`infra`**: Source of truth. We treat it as read-only input.
*   **`docs`**: Consumer. We export images here.
*   **`core`**: No direct dependency, though `core` architecture (FastAPI, Workers) will be depicted.

## 6. Next Steps

1.  Approve this plan.
2.  Create the `arch-viz` folder/repo.
3.  Install `diagrams` and `graphviz`.
4.  Draft the first script: `src/views/system_topology.py`.
