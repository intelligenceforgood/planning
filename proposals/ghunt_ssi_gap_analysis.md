# GHunt vs. SSI Gap Analysis & Implementation Plan

## 1. Executive Summary
Currently, SSI relies on GHunt as an external dependency to perform Google-specific OSINT. This creates fragility, increases investigation cost overhead, and breaks the integrated resilience model (e.g., our `@with_retries` decorator and budget trackers). This report outlines the capabilities GHunt provides, the specific Google endpoints it targets, and a technical plan to rebuild these features natively within `ssi.osint`, allowing us to deprecate GHunt entirely.

## 2. Capability Gap Analysis

The following Google-specific intelligence is currently missing from SSI's native passive/active recon phases but exists in GHunt:

| Feature | GHunt Implementation | SSI Native Gap |
| :--- | :--- | :--- |
| **Identity Resolution** | Resolves an email to a Gaia ID, fetching profile images, names, and user types. | SSI only extracts emails (PII) but does not resolve them to Google identities. |
| **Extended Account Data** | Checks Google Chat (`DynamiteData`) and activated Google services (`inAppReachability`). | No Google service enumeration. |
| **Maps & Location** | Fetches reviews, ratings, and photos via Gaia ID; calculates a probable location/confidence score. | Relies strictly on IP GeoIP and WHOIS registration addresses. |
| **Drive File Exposure** | Scrapes internal Drive metadata, comments, and file children. | No native Drive link parsing. |
| **Calendar & Play Games**| Discovers public calendar events and gamer profile info. | No equivalent. |

## 3. Targeted Google Endpoints

By analyzing the GHunt source code (`ghunt/apis` and `ghunt/modules`), we have identified the primary endpoints required for our native implementation:

1.  **People API (Identity & Gaia ID)**
    *   **Host:** `people-pa.clients6.google.com`
    *   **Endpoint:** `/v2/people/lookup` (Email to Gaia) and `/v2/people` (Gaia to Profile)
    *   **Auth:** Requires Android OAuth scopes (`profile.agerange.read`, `contacts`, etc.) or `sapisidhash`.
2.  **Maps / Location History**
    *   **Host:** `www.google.com`
    *   **Endpoint:** `/locationhistory/preview/mas`
    *   **Auth:** Standard web cookies (`authuser=0`). Requires specific `pb` protobuf parameter formats.
3.  **Drive (Internal v2)**
    *   **Host:** `www.googleapis.com`
    *   **Endpoint:** `/drive/v2internal/files/{file_id}`, `/comments`, and `/children`
4.  **Google Calendar**
    *   **Endpoint:** Requires standard web calendar scraping using target email.

## 4. Implementation Plan

To cleanly add these capabilities to SSI's architecture and fully replace GHunt, we will execute the following phases:

### Phase 1: Native `ssi.osint.google` Module
Create a new module dedicated to Google intelligence:
*   `ssi/src/ssi/osint/google/auth.py`: Utilize SSI's existing **Sandboxed Browser (`zendriver`)** to generate the required cookies (`SAPISID`, etc.) and `sapisidhash` headers automatically, removing the need for external GHunt credentials.
*   `ssi/src/ssi/osint/google/people.py`: Implement the People API endpoints to map discovered email addresses to Gaia IDs.
*   `ssi/src/ssi/osint/google/maps.py`: Implement the location history protobuf scraping to retrieve reviews and probable geographic locations.
*   `ssi/src/ssi/osint/google/drive.py`: Implement file metadata scraping for any Drive links discovered during the Active Interaction phase.

### Phase 2: Resilience and Integration
*   Decorate all new Google API clients with SSI's `@with_retries` decorator to handle transient 429/5xx errors natively.
*   Integrate calls into `CostTracker`. Since these are primarily internal/undocumented endpoints, the API cost is $0, but they consume compute time and bandwidth.

### Phase 3: Data Architecture Updates
Update the schema and core ingestion mapping in `ssi.data`:
*   **`site_scans` table:** Update the `passive_result` JSONB schema to include a `"google_osint"` block containing `gaia_id`, `probable_location`, and `activated_services`.
*   **Core Entity Mapping:** Ensure discovered Gaia IDs are written as `indicators` linked to the core `case`.
*   **PII Vault:** Any names, photos, or secondary emails discovered via the People API must be routed to the `pii_exposures` table.

### Phase 4: Pipeline Orchestration
In `ssi/src/ssi/orchestrator/pipeline.py`:
*   During **Phase 1 (Passive Recon)**: Trigger the Google OSINT module if an email is present in WHOIS or scraped from the target's homepage.
*   During **Phase 2 (Active Interaction)**: If the Playbook or LLM extracts a Google Drive link, immediately trigger the `drive.py` module to capture metadata and comments before the link is potentially taken down.

By leveraging SSI's existing `zendriver` for authentication and `@with_retries` for stability, this native implementation will be faster and more reliable than the legacy GHunt wrapper.