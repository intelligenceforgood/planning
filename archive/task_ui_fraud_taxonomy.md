# Task: Implement Fraud Taxonomy display in UI

## Context
The backend API (`GET /reviews/{id}` and Search) now returns `explanation` and `few_shot_examples` in the `classification` object. The UI needs to display these details to the analyst.

## Checklist
- [x] **Update SDK Schema**:
    - [x] Edit `ui/packages/sdk/src/index.ts`
    - [x] Update `fraudClassificationResultSchema` to include:
        - `explanation`: `z.string().optional().nullable()`
        - `few_shot_examples`: `z.array(z.record(z.unknown())).optional()`
- [x] **Update Search UI**:
    - [x] Edit `ui/apps/web/src/app/(console)/search/search-experience.tsx`
    - [x] In the expanded view (render loop `expandedResultId === result.id`):
        - [x] Add a section to display the top-level `explanation` if present.
        - [x] Add a section (e.g. `<Accordion>` or simple list) to display `few_shot_examples`.
- [x] **Verify**:
    - [x] Check if the changes compile (`pnpm build` in ui).
    - [x] (Optional) Run the UI locally if possible, or verify code correctness.
