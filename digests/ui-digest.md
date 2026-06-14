# UI Digest
Generated: 2026-06-14T03:15:27.559445Z

## Public API
| Function/Class | File | Signature |
|:---|:---|:---|
| Navigation | apps/web/src/app/(console)/navigation.tsx | `export function Navigation()` |
| ShareDashboardButton | apps/web/src/app/(console)/intelligence/components/share-dashboard-button.tsx | `export function ShareDashboardButton()` |
| LossTrendChart | apps/web/src/app/(console)/intelligence/components/loss-trend-chart.tsx | `export function LossTrendChart({ data }: LossTrendChartProps)` |
| EntityDetailPanel | apps/web/src/app/(console)/intelligence/entities/entity-detail-panel.tsx | `export function EntityDetailPanel({ entity, onClose }: EntityDetailPanelProps)` |
| formatDocumentName | apps/web/src/app/(console)/discovery/discovery-types.ts | `export function formatDocumentName(name?: string | null)` |
| formatDocumentId | apps/web/src/app/(console)/discovery/discovery-types.ts | `export function formatDocumentId(documentId?: string | null)` |
| formatJsonForDisplay | apps/web/src/app/(console)/discovery/discovery-types.ts | `export function formatJsonForDisplay(payload: unknown)` |
| buildPayload | apps/web/src/app/(console)/discovery/discovery-types.ts | `export function buildPayload(form: DiscoverySearchRequest)` |
| ComparisonGrid | apps/web/src/app/(console)/admin/engagements/compare/comparison-grid.tsx | `export function ComparisonGrid({ engagements }: Props)` |
| EngagementAnalyticsSummary | apps/web/src/app/(console)/admin/engagements/[id]/leaderboard/analytics-summary.tsx | `export function EngagementAnalyticsSummary({ analytics }: Props)` |
| AccountsTable | apps/web/src/app/(console)/admin/users/accounts-table.tsx | `export function AccountsTable({ accounts: initial }: AccountsTableProps)` |
| ActivityBarClient | apps/web/src/app/(console)/cases/[id]/case-detail-client.tsx | `export function ActivityBarClient({ caseId }: ActivityBarClientProps)` |
| formatCurrency | apps/web/src/app/(console)/reports/dossiers/dossier-utils.ts | `export function formatCurrency(value?: unknown)` |
| isHttpUrl | apps/web/src/app/(console)/reports/dossiers/dossier-utils.ts | `export function isHttpUrl(value?: string | null)` |
| formatPathPreview | apps/web/src/app/(console)/reports/dossiers/dossier-utils.ts | `export function formatPathPreview(value: string)` |
| formatBytes | apps/web/src/app/(console)/reports/dossiers/dossier-utils.ts | `export function formatBytes(value?: number | null)` |
| buildDownloadHref | apps/web/src/app/(console)/reports/dossiers/dossier-utils.ts | `export function buildDownloadHref(path: string)` |
| buildShareableLinks | apps/web/src/app/(console)/reports/dossiers/dossier-utils.ts | `export function buildShareableLinks(downloads: DossierDownloads)` |
| toHex | apps/web/src/app/(console)/reports/dossiers/dossier-utils.ts | `export function toHex(buffer: ArrayBuffer)` |
| extractCaseIds | apps/web/src/app/(console)/reports/dossiers/dossier-utils.ts | `export function extractCaseIds(record: DossierRecord)` |
| DossierList | apps/web/src/app/(console)/reports/dossiers/dossier-list.tsx | `export function DossierList({ response, includeManifest }: DossierListProps)` |
| StatsRow | apps/web/src/app/(console)/reports/dossiers/dossier-components.tsx | `export function StatsRow({ label, value }: { label: string; value: string })` |
| RemoteDownloadRow | apps/web/src/app/(console)/reports/dossiers/dossier-components.tsx | `export function RemoteDownloadRow({ entry }: { entry: DossierRemoteDownload })` |
| DownloadsPanel | apps/web/src/app/(console)/reports/dossiers/dossier-components.tsx | `export function DownloadsPanel({ downloads }: { downloads: DossierDownloads })` |
| HandoffBanner | apps/web/src/app/(console)/reports/dossiers/dossier-components.tsx | `export function HandoffBanner({ downloads }: { downloads: DossierDownloads })` |
| POST | apps/web/src/app/api/intakes/route.ts | `export function POST(request: Request)` |
| POST | apps/web/src/app/api/discovery/search/route.ts | `export function POST(request: Request)` |
| POST | apps/web/src/app/api/feedback/route.ts | `export function POST(request: Request)` |
| GET | apps/web/src/app/api/ssi/investigations/route.ts | `export function GET(request: NextRequest)` |
| POST | apps/web/src/app/api/ssi/investigate/route.ts | `export function POST(request: NextRequest)` |
| GET | apps/web/src/app/api/ssi/wallets/route.ts | `export function GET(request: NextRequest)` |
| GET | apps/web/src/app/api/ssi/ecx/polling-status/route.ts | `export function GET()` |
| GET | apps/web/src/app/api/ssi/ecx/feed/route.ts | `export function GET(request: NextRequest)` |
| GET | apps/web/src/app/api/ssi/ecx/submissions/route.ts | `export function GET(request: NextRequest)` |
| GET | apps/web/src/app/api/ssi/ecx/stats/wallet-heatmap/route.ts | `export function GET(request: NextRequest)` |
| GET | apps/web/src/app/api/ssi/ecx/stats/geo-infrastructure/route.ts | `export function GET(request: NextRequest)` |
| GET | apps/web/src/app/api/ssi/ecx/stats/phish-by-brand/route.ts | `export function GET(request: NextRequest)` |
| POST | apps/web/src/app/api/search/route.ts | `export function POST(request: Request)` |
| POST | apps/web/src/app/api/dossiers/verify/route.ts | `export function POST(request: Request)` |
| GET | apps/web/src/app/api/dossiers/download/route.ts | `export function GET(request: NextRequest)` |
| POST | apps/web/src/app/api/reviews/saved/route.ts | `export function POST(request: Request)` |
| PATCH | apps/web/src/app/api/reviews/saved/[searchId]/route.ts | `export function PATCH(request: NextRequest, context: RouteContext)` |
| DELETE | apps/web/src/app/api/reviews/saved/[searchId]/route.ts | `export function DELETE(_request: NextRequest, context: RouteContext)` |
| GET | apps/web/src/app/api/reviews/history/route.ts | `export function GET(request: Request)` |
| getHelpEntry | apps/web/src/content/help/registry.ts | `export function getHelpEntry(key: string)` |
| ThemeProvider | apps/web/src/components/theme-provider.tsx | `export function ThemeProvider({ children, ...props }: ThemeProviderProps)` |
| NoEngagementsPrompt | apps/web/src/components/no-engagements-prompt.tsx | `export function NoEngagementsPrompt()` |
| EngagementSummaryCard | apps/web/src/components/engagement-summary-card.tsx | `export function EngagementSummaryCard()` |
| TokenReveal | apps/web/src/components/token-reveal.tsx | `export function TokenReveal({ token, caseId, className }: TokenRevealProps)` |
| CommandPalette | apps/web/src/components/command-palette.tsx | `export function CommandPalette()` |
| ... | ... | `... and 54 more entries collapsed` |

## Data Models
| Model | File | Fields |
|:---|:---|:---|
| InvestigateRequest | apps/web/src/types/ssi.ts | `url: string, passive_only: boolean, scan_type: ScanType, skip_whois: boolean, skip_screenshot: bo...` |
| InvestigateResponse | apps/web/src/types/ssi.ts | `investigation_id: string, status: string, message: string, triggered: boolean, alreadyInvestigate...` |
| StatusResponse | apps/web/src/types/ssi.ts | `investigation_id: string, status: string, ssi_investigation_id: string | null, result: Investigat...` |
| WHOISRecord | apps/web/src/types/ssi.ts | `domain: string, registrar: string, creation_date: string, expiration_date: string, registrant_cou...` |
| DNSRecord | apps/web/src/types/ssi.ts | `type: string, value: string, ttl: number` |
| DNSRecords | apps/web/src/types/ssi.ts | `a: string[], aaaa: string[], mx: DNSRecord[], txt: string[], ns: string[], cname: string[]` |
| SSLInfo | apps/web/src/types/ssi.ts | `issuer: string, subject: string, serial_number: string, not_before: string, not_after: string, sa...` |
| GeoIPInfo | apps/web/src/types/ssi.ts | `ip: string, hostname: string, city: string, region: string, country: string, org: string, asn: st...` |
| ThreatIndicator | apps/web/src/types/ssi.ts | `indicator_type: string, value: string, context: string, source: string` |
| ScamClassification | apps/web/src/types/ssi.ts | `scam_type: string, confidence: number, summary: string` |
| FraudTaxonomyResult | apps/web/src/types/ssi.ts | `risk_score: number, explanation: string, intent: Array<{ label: string, channel: Array<{ label: s...` |
| InvestigationResult | apps/web/src/types/ssi.ts | `url: string, status: string, success: boolean, error: string, duration_seconds: number, passive_o...` |
| ScanSummary | apps/web/src/types/ssi.ts | `scan_id: string, url: string, domain: string, scan_type: string, status: ScanStatus, risk_score: ...` |
| InvestigationsListResponse | apps/web/src/types/ssi.ts | `items: ScanSummary[], count: number, limit: number, offset: number` |
| InvestigationDetailResponse | apps/web/src/types/ssi.ts | `scan: ScanSummary, wallets: WalletRecord[], piiExposures: PIIExposure[], agentActions: AgentAction[]` |
| WalletRecord | apps/web/src/types/ssi.ts | `wallet_id: string, scan_id: string, token_symbol: string, token_label: string, network_short: str...` |
| WalletsSearchResponse | apps/web/src/types/ssi.ts | `items: WalletRecord[], count: number` |
| PIIExposure | apps/web/src/types/ssi.ts | `exposure_id: string, scan_id: string, field_type: string, field_label: string, form_action: strin...` |
| AgentAction | apps/web/src/types/ssi.ts | `action_id: string, scan_id: string, state: string, sequence: number, action_type: string, action_...` |
| SSIEvent | apps/web/src/types/ssi.ts | `event_type: SSIEventType, timestamp: string, investigation_id: string, data: Record<string, unknown>` |
| SSISnapshot | apps/web/src/types/ssi.ts | `screenshot_b64: string, state: string, url: string, uptime_sec: number` |
| GuidanceCommand | apps/web/src/types/ssi.ts | `action: GuidanceAction, value: string, reason: string` |
| EcxSubmission | apps/web/src/types/ssi.ts | `submission_id: string, ecx_module: string, ecx_record_id: number | null, scan_id: string, case_id...` |
| EcxSubmissionsResponse | apps/web/src/types/ssi.ts | `count: number, submissions: EcxSubmission[]` |
| EcxApproveRequest | apps/web/src/types/ssi.ts | `release_label: string, analyst: string` |
| EcxRejectRequest | apps/web/src/types/ssi.ts | `analyst: string, reason: string` |
| EcxFeedRecord | apps/web/src/types/ssi.ts | `id: number, url: string, domain: string, ip: string, address: string, brand: string, confidence: ...` |
| EcxFeedResponse | apps/web/src/types/ssi.ts | `module: string, count: number, records: EcxFeedRecord[]` |
| EcxPollingState | apps/web/src/types/ssi.ts | `module: string, last_polled_id: number, last_polled_at: string, records_found: number, errors: nu...` |
| EcxPollingStatusResponse | apps/web/src/types/ssi.ts | `modules: EcxPollingState[]` |
| ThreatActorRow | apps/web/src/types/actors.ts | `actorId: string, displayName: string, role: string, campaignId: string, realName: string, confide...` |
| ActorListResponse | apps/web/src/types/actors.ts | `items: ThreatActorRow[], total: number, limit: number, offset: number` |
| ActorIdentityEdge | apps/web/src/types/actors.ts | `sourceIdentityId: string, targetIdentityId: string, edgeType: string` |
| ActorIdentityRow | apps/web/src/types/actors.ts | `identityId: string, platform: string, handle: string, metadata: Record<string, unknown>` |
| LeakRecordRow | apps/web/src/types/actors.ts | `leakId: string, sourceBreach: string, passwordCleartext: string, email: string` |
| ActorDetailResponse | apps/web/src/types/actors.ts | `actor: ThreatActorRow, identities: ActorIdentityRow[], edges: ActorIdentityEdge[], leaks: LeakRec...` |
| ChatSessionRow | apps/web/src/types/actors.ts | `sessionId: string, transcript: string` |
| DamageRow | apps/web/src/types/actors.ts | `currency: string, claimed_amount: number, confirmed_amount: number` |
| BrandRow | apps/web/src/types/actors.ts | `brand: string` |
| DiscoveryRow | apps/web/src/types/discoveries.ts | `discoveryId: string, domain: string, seenAt: string, source: string, filterMatch: boolean, filter...` |
| DiscoveryList | apps/web/src/types/discoveries.ts | `items: DiscoveryRow[], total: number, limit: number, offset: number` |
| EnqueueResponse | apps/web/src/types/discoveries.ts | `discoveryId: string, enqueuedScanId: string` |
| DismissRequest | apps/web/src/types/discoveries.ts | `reason: string` |
| Campaign | apps/web/src/types/campaigns.ts | `id: string, name: string, description: string, taxonomy_labels: Record<string, unknown>, taxonomy...` |
| CreateCampaignPayload | apps/web/src/types/campaigns.ts | `name: string, description: string, taxonomy_labels: Record<string, unknown>, associated_taxonomy_...` |
| UpdateCampaignPayload | apps/web/src/types/campaigns.ts | `name: string, description: string, taxonomy_labels: Record<string, unknown>, associated_taxonomy_...` |
| SavedSearchDescriptor | apps/web/src/types/reviews.ts | `id: string, name: string, owner: string | null, tags: string[]` |
| SearchHistoryEvent | apps/web/src/types/reviews.ts | `id: string, actor: string, createdAt: string, params: Record<string, unknown>, query: string, cla...` |
| SavedSearchRecord | apps/web/src/types/reviews.ts | `id: string, name: string, owner: string | null, favorite: boolean, tags: string[], createdAt: str...` |
| HybridSearchSchema | apps/web/src/types/reviews.ts | `indicatorTypes: string[], datasets: string[], classifications: string[], lossBuckets: string[], t...` |
| ... | ... | `... and 54 more entries collapsed` |

## Routes
| Method | Path | Handler | File |
|:---|:---|:---|:---|
| POST | /api/intakes | POST | apps/web/src/app/api/intakes/route.ts |
| POST | /api/discovery/search | POST | apps/web/src/app/api/discovery/search/route.ts |
| POST | /api/feedback | POST | apps/web/src/app/api/feedback/route.ts |
| GET | /api/ssi/investigations | GET | apps/web/src/app/api/ssi/investigations/route.ts |
| GET | /api/ssi/investigations/[id] | GET | apps/web/src/app/api/ssi/investigations/[id]/route.ts |
| POST | /api/ssi/investigate | POST | apps/web/src/app/api/ssi/investigate/route.ts |
| GET | /api/ssi/investigate/[id] | GET | apps/web/src/app/api/ssi/investigate/[id]/route.ts |
| GET | /api/ssi/report/[id] | GET | apps/web/src/app/api/ssi/report/[id]/route.ts |
| GET | /api/ssi/wallets | GET | apps/web/src/app/api/ssi/wallets/route.ts |
| GET | /api/ssi/ecx/investigate/[id] | GET | apps/web/src/app/api/ssi/ecx/investigate/[id]/route.ts |
| GET | /api/ssi/ecx/polling-status | GET | apps/web/src/app/api/ssi/ecx/polling-status/route.ts |
| GET | /api/ssi/ecx/feed | GET | apps/web/src/app/api/ssi/ecx/feed/route.ts |
| GET | /api/ssi/ecx/submissions | GET | apps/web/src/app/api/ssi/ecx/submissions/route.ts |
| POST | /api/ssi/ecx/submissions/[id]/reject | POST | apps/web/src/app/api/ssi/ecx/submissions/[id]/reject/route.ts |
| POST | /api/ssi/ecx/submissions/[id]/approve | POST | apps/web/src/app/api/ssi/ecx/submissions/[id]/approve/route.ts |
| POST | /api/ssi/ecx/submissions/[id]/retract | POST | apps/web/src/app/api/ssi/ecx/submissions/[id]/retract/route.ts |
| GET | /api/ssi/ecx/stats/wallet-heatmap | GET | apps/web/src/app/api/ssi/ecx/stats/wallet-heatmap/route.ts |
| GET | /api/ssi/ecx/stats/geo-infrastructure | GET | apps/web/src/app/api/ssi/ecx/stats/geo-infrastructure/route.ts |
| GET | /api/ssi/ecx/stats/phish-by-brand | GET | apps/web/src/app/api/ssi/ecx/stats/phish-by-brand/route.ts |
| GET | /api/[...path] | GET | apps/web/src/app/api/[...path]/route.ts |
| POST | /api/[...path] | POST | apps/web/src/app/api/[...path]/route.ts |
| PUT | /api/[...path] | PUT | apps/web/src/app/api/[...path]/route.ts |
| DELETE | /api/[...path] | DELETE | apps/web/src/app/api/[...path]/route.ts |
| PATCH | /api/[...path] | PATCH | apps/web/src/app/api/[...path]/route.ts |
| POST | /api/search | POST | apps/web/src/app/api/search/route.ts |
| POST | /api/dossiers/verify | POST | apps/web/src/app/api/dossiers/verify/route.ts |
| GET | /api/dossiers/download | GET | apps/web/src/app/api/dossiers/download/route.ts |
| POST | /api/events/ssi/[scanId]/guidance | POST | apps/web/src/app/api/events/ssi/[scanId]/guidance/route.ts |
| GET | /api/events/ssi/[scanId]/stream | GET | apps/web/src/app/api/events/ssi/[scanId]/stream/route.ts |
| POST | /api/reviews/saved | POST | apps/web/src/app/api/reviews/saved/route.ts |
| DELETE | /api/reviews/saved/[searchId] | DELETE | apps/web/src/app/api/reviews/saved/[searchId]/route.ts |
| PATCH | /api/reviews/saved/[searchId] | PATCH | apps/web/src/app/api/reviews/saved/[searchId]/route.ts |
| GET | /api/reviews/history | GET | apps/web/src/app/api/reviews/history/route.ts |

## Config
| Variable | File | Context |
|:---|:---|:---|
| I4G_IAP_CLIENT_ID | apps/web/src/app/api/intakes/route.ts | process.env reference |
| I4G_API_URL | apps/web/src/app/api/[...path]/route.ts | process.env reference |
| NEXT_PUBLIC_API_BASE_URL | apps/web/src/app/api/[...path]/route.ts | process.env reference |
| I4G_DOSSIER_BASE_PATH | apps/web/src/app/api/dossiers/download/route.ts | process.env reference |
| I4G_DATA_DIR | apps/web/src/app/api/dossiers/download/route.ts | process.env reference |
| I4G_API_URL | apps/web/src/app/api/events/ssi/[scanId]/guidance/route.ts | process.env reference |
| NEXT_PUBLIC_API_BASE_URL | apps/web/src/app/api/events/ssi/[scanId]/guidance/route.ts | process.env reference |
| I4G_API_URL | apps/web/src/app/api/events/ssi/[scanId]/stream/route.ts | process.env reference |
| NEXT_PUBLIC_API_BASE_URL | apps/web/src/app/api/events/ssi/[scanId]/stream/route.ts | process.env reference |
| I4G_IAP_CLIENT_ID | apps/web/src/app/api/reviews/saved/route.ts | process.env reference |
| I4G_IAP_CLIENT_ID | apps/web/src/app/api/reviews/saved/[searchId]/route.ts | process.env reference |
| NEXT_PUBLIC_FEEDBACK_ENABLED | apps/web/src/components/feedback-shell.tsx | process.env reference |
| NEXT_PUBLIC_SSI_WS_URL | apps/web/src/lib/use-investigation-monitor.ts | process.env reference |
| K_SERVICE | apps/web/src/lib/iap-token.ts | process.env reference |
| I4G_API_URL | apps/web/src/lib/i4g-client.ts | process.env reference |
| NEXT_PUBLIC_API_BASE_URL | apps/web/src/lib/i4g-client.ts | process.env reference |
| I4G_API_KIND | apps/web/src/lib/i4g-client.ts | process.env reference |
| I4G_API_KEY | apps/web/src/lib/i4g-client.ts | process.env reference |
| I4G_IAP_CLIENT_ID | apps/web/src/lib/i4g-client.ts | process.env reference |
| I4G_API_URL | apps/web/src/lib/server/api-client.ts | process.env reference |
| NEXT_PUBLIC_API_BASE_URL | apps/web/src/lib/server/api-client.ts | process.env reference |
| I4G_API_KEY | apps/web/src/lib/server/api-client.ts | process.env reference |
| I4G_ENV | apps/web/src/lib/server/auth-helpers.ts | process.env reference |
| I4G_API_URL | apps/web/src/lib/server/auth-helpers.ts | process.env reference |
| NEXT_PUBLIC_API_BASE_URL | apps/web/src/lib/server/auth-helpers.ts | process.env reference |
| I4G_IAP_CLIENT_ID | apps/web/src/lib/server/auth-helpers.ts | process.env reference |
| SSI_API_URL | apps/web/src/lib/server/ssi-proxy.ts | process.env reference |
| K_SERVICE | apps/web/src/lib/server/ssi-proxy.ts | process.env reference |
| I4G_ENV | apps/web/src/lib/server/discovery-config.ts | process.env reference |
| NODE_ENV | apps/web/src/lib/server/discovery-config.ts | process.env reference |
| I4G_VERTEX_SEARCH_PROJECT | apps/web/src/lib/server/discovery-config.ts | process.env reference |
| NEXT_PUBLIC_VERTEX_SEARCH_PROJECT | apps/web/src/lib/server/discovery-config.ts | process.env reference |
| I4G_VERTEX_SEARCH_LOCATION | apps/web/src/lib/server/discovery-config.ts | process.env reference |
| NEXT_PUBLIC_VERTEX_SEARCH_LOCATION | apps/web/src/lib/server/discovery-config.ts | process.env reference |
| I4G_VERTEX_SEARCH_DATA_STORE | apps/web/src/lib/server/discovery-config.ts | process.env reference |
| NEXT_PUBLIC_VERTEX_SEARCH_DATA_STORE | apps/web/src/lib/server/discovery-config.ts | process.env reference |
| I4G_VERTEX_SEARCH_SERVING_CONFIG | apps/web/src/lib/server/discovery-config.ts | process.env reference |
| NEXT_PUBLIC_VERTEX_SEARCH_SERVING_CONFIG | apps/web/src/lib/server/discovery-config.ts | process.env reference |
