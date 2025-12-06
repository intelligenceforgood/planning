# UI Task: LEA folder / ACL preview for Dossier Portal

This note captures the exact UI changes required to implement a Drive folder + ACL preview in the Next.js portal `reports/dossiers` view.

## Goals
- Surface the target Shared Drive folder for a dossier plan and provide a quick ACL preview for analysts to confirm LEA access.
- Provide a `Copy folder link` CTA and a `Preview ACL` control that fetches folder metadata + computed ACLs for the plan.

## Data contract
- Use existing endpoint `/reports/dossiers` that returns `downloads['drive']` and `remote` upload references.
- If `downloads.drive.shared_drive_parent_id` is present, call the Drive API to query the folder's `permissions` list and show a brief team-friendly summary: `i4g-admin group`, `project:service-account`, `allUsers` etc.

## UI UX
- On the dossier card, add a small `Drive folder` chip next to the `Manifest` chip.
- Clicking the `Drive folder` opens a small dialog rendering: folder name, created at, owner, permission list summary (group + role), and a CTA `Copy folder link`.
- If the `Drive` folder is not accessible to the current user, highlight the `Request Access` path or show the `Copy link` so admins can resolve offline.

## API considerations
- The portal may need a server-side proxy route (already present as `/api/dossiers/download` for artifacts) to call the Drive API with ADC. Add a versioned endpoint `/api/dossiers/{plan_id}/drive_acl` that returns the ACL summary.
- Guard the endpoint behind `IAP` and `sa-get-file` service account so return no sensitive details when the user is not authorized.

## Acceptance criteria
- The docket card shows the `Drive folder` chip that opens an ACL preview.
- The preview shows a list of identity principals and their roles (read-only).
- The preview doesn't leak raw PII or direct email addresses; show group names and service accounts only and mask sensitive identities.

## Implementation notes
- Use `service-account` ADC and `drive.permissions.list` to fetch perms; cache results (5 minutes) to avoid Drive API throttling.
- Map Drive permissions to simple badges: `group`, `domain`, `user`, `anyone` with role (`reader`, `writer`, `owner`).
