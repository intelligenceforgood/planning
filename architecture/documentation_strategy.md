# Architecture Documentation Strategy

## 1. The "Map of the World" Concept

We will structure the architecture documentation like a mapping application: starting with a "Global View" (System Topology) and allowing developers to "zoom in" to specific regions (Data Pipeline, Security, Infrastructure).

### Hierarchy of Diagrams

1.  **Level 1: System Topology (The "Metro Map")**
    *   **Goal:** Show the big picture. Who uses the system? What are the main boxes? Where does data live?
    *   **Scope:** Users -> Ingress -> Core Services -> Storage -> External Systems.
    *   **Detail:** Low. No internal implementation details (e.g., no specific Cloud Run revisions or Pub/Sub subscriptions).

2.  **Level 2: Subsystem Views (The "Neighborhood Maps")**
    *   **Data Pipeline:** Focus on the journey of a "Case" from ingestion to vector search. (OCR, PII redaction, Embedding).
    *   **Security & Identity:** Focus on Auth flows, IAM roles, PII Vault access patterns, and WIF.
    *   **Infrastructure/Networking:** Focus on VPCs, Subnets, Load Balancers, and DNS.

3.  **Level 3: Component Views (The "Building Blueprints")**
    *   **Worker Internals:** How the `worker` service processes a specific job type.
    *   **API Layering:** FastAPI routers, middleware, and dependency injection graph.

## 2. Improving Diagram Quality (Addressing Feedback)

### A. Density & Layout
*   **Problem:** "Sparse" diagrams with bad line routing.
*   **Solution:**
    *   **Clusters:** Use nested `Cluster()` contexts aggressively to group related items (e.g., "Ingestion Pipeline" inside "Worker").
    *   **Direction:** Experiment with `direction="TB"` (Top-Bottom) vs `LR` (Left-Right). Data flows often look better LR; hierarchies look better TB.
    *   **Invisible Edges:** Use `Edge(style="invis")` to force nodes to align without drawing a line.

### B. Sizing & Readability
*   **Problem:** Icons/Text too large.
*   **Solution:**
    *   **Graph Attributes:** Tweak `graph_attr` in the Python script.
        *   `fontsize`: Reduce for nodes (e.g., "12" instead of default).
        *   `nodesep` / `ranksep`: Control spacing between nodes and ranks.
    *   **Node Attributes:** Pass `fontsize` to individual nodes if needed.

### C. Editability
*   **Problem:** Static PNGs are hard to tweak.
*   **Solution:**
    *   **Output Format:** Generate **SVG** (`filename="output/system_topology", outformat="svg"`). SVGs are vector-based, scale infinitely in Markdown, and can be opened in tools like Inkscape or Adobe Illustrator for manual touch-ups if absolutely necessary (though we prefer "Code First").

## 3. Action Plan: Next Diagrams

We will create three new scripts in `arch-viz/src/views/`:

1.  `data_pipeline.py`: Zoom in on the "Worker" and "AI & Processing" clusters. Show the flow: `Upload -> PubSub -> Worker -> Document AI -> PII Redaction -> Cloud SQL -> Vertex AI`.
2.  `security_model.py`: Zoom in on Identity. Show `User -> Identity Platform -> Cloud Run (Invoker) -> Service Account -> Secret Manager`.

## 4. The "Architecture Guide" Doc

We will create a new top-level guide in `docs/book/architecture/README.md` that serves as the entry point.

**Structure:**
*   **Introduction:** What is i4g? (High-level mission).
*   **System Topology:** Embed the Level 1 diagram. Brief description of the 4 main pillars (Ingress, Compute, Data, AI).
*   **Deep Dives:** Links to sub-pages (`data-pipeline.md`, `security.md`, `infra.md`), each embedding their respective Level 2 diagrams.
*   **Code Map:** A brief "Where is what?" mapping repos (`core`, `infra`, `ui`) to the diagram components.
