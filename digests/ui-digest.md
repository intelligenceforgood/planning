# UI Digest
Generated: 2026-07-14T16:03:15Z

## Public API
| Function/Class | File | Signature |
| :--- | :--- | :--- |
| AccountInfo | apps/web/src/lib/server/admin-accounts-service.ts | `export interface AccountInfo` |
| AccountsTable | apps/web/src/app/(console)/admin/users/accounts-table.tsx | `export function AccountsTable({ accounts: initial }: AccountsTableProps)` |
| ActivityBar | apps/web/src/components/case-detail/activity-bar.tsx | `export function ActivityBar({ activities, hasRunning, onInvestigationClick, }: ActivityBarProps)` |
| ActivityBarClient | apps/web/src/app/(console)/cases/[id]/case-detail-client.tsx | `export function ActivityBarClient({ caseId }: ActivityBarClientProps)` |
| ActorDetailResponse | apps/web/src/types/actors.ts | `export interface ActorDetailResponse` |
| ActorIdentityEdge | apps/web/src/types/actors.ts | `export interface ActorIdentityEdge` |
| ActorIdentityRow | apps/web/src/types/actors.ts | `export interface ActorIdentityRow` |
| ActorListResponse | apps/web/src/types/actors.ts | `export interface ActorListResponse` |
| AgentAction | apps/web/src/types/ssi.ts | `export interface AgentAction` |
| AnnotationPanel | apps/web/src/app/(console)/intelligence/components/annotation-panel.tsx | `export function AnnotationPanel({ targetType, targetId, }: AnnotationPanelProps)` |
| AuthProvider | apps/web/src/lib/auth-context.tsx | `export function AuthProvider({ children, user }: AuthProviderProps)` |
| AuthUser | apps/web/src/lib/auth-context.tsx | `export interface AuthUser` |
| Badge | packages/ui-kit/src/components/badge.tsx | `export function Badge({ className, variant = "default", ...props }: BadgeProps)` |
| BrandRow | apps/web/src/types/actors.ts | `export interface BrandRow` |
| BreadcrumbItem | apps/web/src/components/breadcrumbs.tsx | `export interface BreadcrumbItem` |
| Breadcrumbs | apps/web/src/components/breadcrumbs.tsx | `export function Breadcrumbs({ items }: BreadcrumbsProps)` |
| BuildSearchRequestOptions | apps/web/src/app/(console)/search/search-types.ts | `export type BuildSearchRequestOptions` |
| BulkActionToolbar | apps/web/src/app/(console)/intelligence/components/bulk-action-toolbar.tsx | `export function BulkActionToolbar({ selectedIds, onClear, onAction, }: BulkActionToolbarProps)` |
| Button | packages/ui-kit/src/components/button.tsx | `export function Button({ className, variant, size, ...props }: ButtonProps)` |
| Campaign | apps/web/src/types/campaigns.ts | `export interface Campaign` |
| CampaignAlerts | apps/web/src/components/campaign-alerts.tsx | `export function CampaignAlerts({ campaigns, maxItems = 5, }: CampaignAlertsProps)` |
| CampaignForm | apps/web/src/components/campaign-form.tsx | `export function CampaignForm({ taxonomy: _taxonomy, }: { taxonomy: TaxonomyResponse; })` |
| CampaignListOptions | packages/sdk/src/index.ts | `export interface CampaignListOptions` |
| Card | packages/ui-kit/src/components/card.tsx | `export function Card({ className, padded = true, ...props }: CardProps)` |
| CasesListOptions | packages/sdk/src/index.ts | `export interface CasesListOptions` |
| ChatSessionRow | apps/web/src/types/actors.ts | `export interface ChatSessionRow` |
| ClassificationBadges | apps/web/src/components/classification-badges.tsx | `export function ClassificationBadges({ classification, taxonomy, tags = [], keyPrefix = "", }: ClassificationBadgesProps)` |
| ClassificationBadgesProps | apps/web/src/components/classification-badges.tsx | `export interface ClassificationBadgesProps` |
| ClientConfig | packages/sdk/src/index.ts | `export interface ClientConfig` |
| ClientVerificationEntry | apps/web/src/app/(console)/reports/dossiers/dossier-utils.ts | `export type ClientVerificationEntry` |
| ClientVerificationPanel | apps/web/src/app/(console)/reports/dossiers/dossier-verification.tsx | `export function ClientVerificationPanel({ entry, }: { entry: ClientVerificationEntry | undefined; })` |
| ClientVerificationReport | apps/web/src/app/(console)/reports/dossiers/dossier-utils.ts | `export type ClientVerificationReport` |
| CodeTooltip | apps/web/src/components/code-tooltip.tsx | `export function CodeTooltip({ code, children, side = "top", }: CodeTooltipProps)` |
| CommandPalette | apps/web/src/components/command-palette.tsx | `export function CommandPalette()` |
| ComparisonGrid | apps/web/src/app/(console)/admin/engagements/compare/comparison-grid.tsx | `export function ComparisonGrid({ engagements }: Props)` |
| CompletedEngagementBanner | apps/web/src/components/completed-engagement-banner.tsx | `export function CompletedEngagementBanner()` |
| CreateCampaignPayload | apps/web/src/types/campaigns.ts | `export interface CreateCampaignPayload` |
| CurrentUser | apps/web/src/lib/server/user-service.ts | `export interface CurrentUser` |
| DELETE | apps/web/src/app/api/[...path]/route.ts | `export function DELETE(req: NextRequest, ctx: { params: Promise<{ path: string[] }> },)` |
| DELETE | apps/web/src/app/api/reviews/saved/[searchId]/route.ts | `export function DELETE(_request: NextRequest, context: RouteContext)` |
| DNSRecord | apps/web/src/types/ssi.ts | `export interface DNSRecord` |
| DNSRecords | apps/web/src/types/ssi.ts | `export interface DNSRecords` |
| DamageRow | apps/web/src/types/actors.ts | `export interface DamageRow` |
| DashboardKpiCards | apps/web/src/components/dashboard-kpi-cards.tsx | `export function DashboardKpiCards({ metrics }: { metrics: DashboardMetric[] })` |
| DedupWarningModal | apps/web/src/components/case-detail/dedup-warning-modal.tsx | `export function DedupWarningModal({ isOpen, onClose, caseId, url, existingScanId, existingRiskScore, daysSinceScan, onViewExisting, onReinvestigateSuccess, }: DedupWarningModalProps)` |
| DiscoveryDefaults | apps/web/src/lib/server/discovery-config.ts | `export type DiscoveryDefaults` |
| DiscoveryList | apps/web/src/types/discoveries.ts | `export interface DiscoveryList` |
| DiscoveryResult | apps/web/src/app/(console)/discovery/discovery-types.ts | `export type DiscoveryResult` |
| DiscoveryResultCardProps | apps/web/src/app/(console)/discovery/discovery-result-card.tsx | `export type DiscoveryResultCardProps` |
| DiscoveryRow | apps/web/src/types/discoveries.ts | `export interface DiscoveryRow` |
| ... | ... | ... and 244 more entries collapsed |

## Data Models
| Model | File | Fields |
| :--- | :--- | :--- |
| AccountInfo | apps/web/src/lib/server/admin-accounts-service.ts | `email: string, role: string, displayName: string | null, isActive: boolean` |
| ActorDetailResponse | apps/web/src/types/actors.ts | `actor: ThreatActorRow, identities: ActorIdentityRow[], edges: ActorIdentityEdge[], leaks: LeakR...` |
| ActorIdentityEdge | apps/web/src/types/actors.ts | `sourceIdentityId: string, targetIdentityId: string, edgeType: string` |
| ActorIdentityRow | apps/web/src/types/actors.ts | `identityId: string, platform: string, handle: string, metadata: Record<string` |
| ActorListResponse | apps/web/src/types/actors.ts | `items: ThreatActorRow[], total: number, limit: number, offset: number` |
| AgentAction | apps/web/src/types/ssi.ts | `action_id: string, scan_id: string, state: string, sequence: number, action_type: string, actio...` |
| AuthUser | apps/web/src/lib/auth-context.tsx | `email: string, role: UserRole, displayName: string | null` |
| BrandRow | apps/web/src/types/actors.ts | `brand: string` |
| BreadcrumbItem | apps/web/src/components/breadcrumbs.tsx | `label: string, href: string` |
| BuildSearchRequestOptions | apps/web/src/app/(console)/search/search-types.ts | `includeSavedSearchContext: boolean` |
| Campaign | apps/web/src/types/campaigns.ts | `id: string, name: string, description: string, taxonomy_labels: Record<string, taxonomy_rollup:...` |
| CampaignListOptions | packages/sdk/src/index.ts | `status: string, limit: number, offset: number` |
| CasesListOptions | packages/sdk/src/index.ts | `limit: number, status: string, priority: string, queue: string, due_date: string` |
| ChatSessionRow | apps/web/src/types/actors.ts | `sessionId: string, transcript: string` |
| ClassificationBadgesProps | apps/web/src/components/classification-badges.tsx | `classification: FraudClassificationResult | null | undefined, taxonomy: TaxonomyResponse, tags:...` |
| ClientConfig | packages/sdk/src/index.ts | `baseUrl: string, apiKey: string, fetchImpl: FetchLike, additionalHeaders: Record<string` |
| ClientVerificationEntry | apps/web/src/app/(console)/reports/dossiers/dossier-utils.ts | `status: "idle" | "loading" | "success" | "error", report: ClientVerificationReport, error: stri...` |
| ClientVerificationReport | apps/web/src/app/(console)/reports/dossiers/dossier-utils.ts | `algorithm: string, artifacts: Array<{, label: string, path: string | null, expectedHash: string...` |
| CreateCampaignPayload | apps/web/src/types/campaigns.ts | `name: string, description: string, taxonomy_labels: Record<string, associated_taxonomy_ids: str...` |
| CurrentUser | apps/web/src/lib/server/user-service.ts | `email: string, role: string, displayName: string | null, isActive: boolean` |
| DNSRecord | apps/web/src/types/ssi.ts | `type: string, value: string, ttl: number` |
| DNSRecords | apps/web/src/types/ssi.ts | `a: string[], aaaa: string[], mx: DNSRecord[], txt: string[], ns: string[], cname: string[]` |
| DamageRow | apps/web/src/types/actors.ts | `currency: string, claimed_amount: number, confirmed_amount: number` |
| DiscoveryDefaults | apps/web/src/lib/server/discovery-config.ts | `project: string, location: string, dataStoreId: string, servingConfigId: string` |
| DiscoveryList | apps/web/src/types/discoveries.ts | `items: DiscoveryRow[], total: number, limit: number, offset: number` |
| DiscoveryResult | apps/web/src/app/(console)/discovery/discovery-types.ts | `rank: number, documentId: string, documentName: string, summary: string | null, label: string |...` |
| DiscoveryResultCardProps | apps/web/src/app/(console)/discovery/discovery-result-card.tsx | `result: DiscoveryResult, showRaw: boolean` |
| DiscoveryRow | apps/web/src/types/discoveries.ts | `discoveryId: string, domain: string, seenAt: string, source: string, filterMatch: boolean, filt...` |
| DiscoverySearchFormProps | apps/web/src/app/(console)/discovery/discovery-search-form.tsx | `form: DiscoverySearchRequest, advancedOpen: boolean, isSearching: boolean, isLoadingMore: boole...` |
| DiscoverySearchResponse | apps/web/src/app/(console)/discovery/discovery-types.ts | `results: DiscoveryResult[], totalSize: number, nextPageToken: string` |
| DismissRequest | apps/web/src/types/discoveries.ts | `reason: string` |
| DossierDownloads | packages/sdk/src/index.ts | `local: DossierLocalDownloads, remote: DossierRemoteDownload[]` |
| DossierListProps | apps/web/src/app/(console)/reports/dossiers/dossier-utils.ts | `response: import("@i4g/sdk").DossierListResponse, includeManifest: boolean` |
| DossierListResponse | packages/sdk/src/index.ts | `count: number, items: DossierRecord[]` |
| DossierLocalDownloads | packages/sdk/src/index.ts | `manifest: string | null, markdown: string | null, pdf: string | null, html: string | null, sign...` |
| DossierRecord | packages/sdk/src/index.ts | `planId: string, status: string, queuedAt: string | null, updatedAt: string | null, warnings: st...` |
| DossierRemoteDownload | packages/sdk/src/index.ts | `label: string, remoteRef: string | null, hash: string | null, algorithm: string | null, sizeByt...` |
| EcxApproveRequest | apps/web/src/types/ssi.ts | `release_label: string, analyst: string` |
| EcxFeedRecord | apps/web/src/types/ssi.ts | `id: number, url: string, domain: string, ip: string, address: string, brand: string, confidence...` |
| EcxFeedResponse | apps/web/src/types/ssi.ts | `module: string, count: number, records: EcxFeedRecord[]` |
| EcxPollingState | apps/web/src/types/ssi.ts | `module: string, last_polled_id: number, last_polled_at: string, records_found: number, errors: ...` |
| EcxPollingStatusResponse | apps/web/src/types/ssi.ts | `modules: EcxPollingState[]` |
| EcxRejectRequest | apps/web/src/types/ssi.ts | `analyst: string, reason: string` |
| EcxSubmission | apps/web/src/types/ssi.ts | `submission_id: string, ecx_module: string, ecx_record_id: number | null, scan_id: string, case_...` |
| EcxSubmissionsResponse | apps/web/src/types/ssi.ts | `count: number, submissions: EcxSubmission[]` |
| EngagementCreate | packages/sdk/src/index.ts | `name: string, description: string | null, status: string, starts_at: string | null, ends_at: st...` |
| EngagementUpdate | packages/sdk/src/index.ts | `name: string, description: string | null, status: string, starts_at: string | null, ends_at: st...` |
| EnqueueResponse | apps/web/src/types/discoveries.ts | `discoveryId: string, enqueuedScanId: string` |
| EntityFilterRow | apps/web/src/app/(console)/search/search-types.ts | `id: string, type: string, value: string, matchMode: MatchMode` |
| EntityListOptions | packages/sdk/src/index.ts | `entityType: string, status: string, minCaseCount: number, minLoss: number, orderBy: string, des...` |
| ... | ... | ... and 50 more entries collapsed |

## Routes
| Method | Path | Handler | File |
| :--- | :--- | :--- | :--- |
| DELETE | /api/[...path] | DELETE | apps/web/src/app/api/[...path]/route.ts |
| DELETE | /api/reviews/saved/[searchId] | DELETE | apps/web/src/app/api/reviews/saved/[searchId]/route.ts |
| GET | /api/[...path] | GET | apps/web/src/app/api/[...path]/route.ts |
| GET | /api/dossiers/download | GET | apps/web/src/app/api/dossiers/download/route.ts |
| GET | /api/events/ssi/[scanId]/stream | GET | apps/web/src/app/api/events/ssi/[scanId]/stream/route.ts |
| GET | /api/reviews/history | GET | apps/web/src/app/api/reviews/history/route.ts |
| GET | /api/ssi/ecx/feed | GET | apps/web/src/app/api/ssi/ecx/feed/route.ts |
| GET | /api/ssi/ecx/investigate/[id] | GET | apps/web/src/app/api/ssi/ecx/investigate/[id]/route.ts |
| GET | /api/ssi/ecx/polling-status | GET | apps/web/src/app/api/ssi/ecx/polling-status/route.ts |
| GET | /api/ssi/ecx/stats/geo-infrastructure | GET | apps/web/src/app/api/ssi/ecx/stats/geo-infrastructure/route.ts |
| GET | /api/ssi/ecx/stats/phish-by-brand | GET | apps/web/src/app/api/ssi/ecx/stats/phish-by-brand/route.ts |
| GET | /api/ssi/ecx/stats/wallet-heatmap | GET | apps/web/src/app/api/ssi/ecx/stats/wallet-heatmap/route.ts |
| GET | /api/ssi/ecx/submissions | GET | apps/web/src/app/api/ssi/ecx/submissions/route.ts |
| GET | /api/ssi/investigate/[id] | GET | apps/web/src/app/api/ssi/investigate/[id]/route.ts |
| GET | /api/ssi/investigations | GET | apps/web/src/app/api/ssi/investigations/route.ts |
| GET | /api/ssi/investigations/[id] | GET | apps/web/src/app/api/ssi/investigations/[id]/route.ts |
| GET | /api/ssi/report/[id] | GET | apps/web/src/app/api/ssi/report/[id]/route.ts |
| GET | /api/ssi/wallets | GET | apps/web/src/app/api/ssi/wallets/route.ts |
| PATCH | /api/[...path] | PATCH | apps/web/src/app/api/[...path]/route.ts |
| PATCH | /api/reviews/saved/[searchId] | PATCH | apps/web/src/app/api/reviews/saved/[searchId]/route.ts |
| POST | /api/[...path] | POST | apps/web/src/app/api/[...path]/route.ts |
| POST | /api/discovery/search | POST | apps/web/src/app/api/discovery/search/route.ts |
| POST | /api/dossiers/verify | POST | apps/web/src/app/api/dossiers/verify/route.ts |
| POST | /api/events/ssi/[scanId]/guidance | POST | apps/web/src/app/api/events/ssi/[scanId]/guidance/route.ts |
| POST | /api/feedback | POST | apps/web/src/app/api/feedback/route.ts |
| POST | /api/intakes | POST | apps/web/src/app/api/intakes/route.ts |
| POST | /api/reviews/saved | POST | apps/web/src/app/api/reviews/saved/route.ts |
| POST | /api/search | POST | apps/web/src/app/api/search/route.ts |
| POST | /api/ssi/ecx/submissions/[id]/approve | POST | apps/web/src/app/api/ssi/ecx/submissions/[id]/approve/route.ts |
| POST | /api/ssi/ecx/submissions/[id]/reject | POST | apps/web/src/app/api/ssi/ecx/submissions/[id]/reject/route.ts |
| POST | /api/ssi/ecx/submissions/[id]/retract | POST | apps/web/src/app/api/ssi/ecx/submissions/[id]/retract/route.ts |
| POST | /api/ssi/investigate | POST | apps/web/src/app/api/ssi/investigate/route.ts |
| PUT | /api/[...path] | PUT | apps/web/src/app/api/[...path]/route.ts |

## Config
| Variable | File | Context |
| :--- | :--- | :--- |
| I4G_API_KEY | apps/web/src/lib/i4g-client.ts | Environment variable reference |
| I4G_API_KEY | apps/web/src/lib/server/api-client.ts | Environment variable reference |
| I4G_API_KIND | apps/web/src/lib/i4g-client.ts | Environment variable reference |
| I4G_API_URL | apps/web/src/app/api/[...path]/route.ts | Environment variable reference |
| I4G_API_URL | apps/web/src/app/api/discovery/search/route.ts | Environment variable reference |
| I4G_API_URL | apps/web/src/app/api/events/ssi/[scanId]/guidance/route.ts | Environment variable reference |
| I4G_API_URL | apps/web/src/app/api/events/ssi/[scanId]/stream/route.ts | Environment variable reference |
| I4G_API_URL | apps/web/src/lib/i4g-client.ts | Environment variable reference |
| I4G_API_URL | apps/web/src/lib/server/api-client.ts | Environment variable reference |
| I4G_API_URL | apps/web/src/lib/server/auth-helpers.ts | Environment variable reference |
| I4G_DATA_DIR | apps/web/src/app/api/dossiers/download/route.ts | Environment variable reference |
| I4G_DOSSIER_BASE_PATH | apps/web/src/app/api/dossiers/download/route.ts | Environment variable reference |
| I4G_ENV | apps/web/src/lib/server/auth-helpers.ts | Environment variable reference |
| I4G_ENV | apps/web/src/lib/server/discovery-config.ts | Environment variable reference |
| I4G_IAP_CLIENT_ID | apps/web/src/app/api/intakes/route.ts | Environment variable reference |
| I4G_IAP_CLIENT_ID | apps/web/src/app/api/reviews/saved/[searchId]/route.ts | Environment variable reference |
| I4G_IAP_CLIENT_ID | apps/web/src/app/api/reviews/saved/route.ts | Environment variable reference |
| I4G_IAP_CLIENT_ID | apps/web/src/lib/i4g-client.ts | Environment variable reference |
| I4G_IAP_CLIENT_ID | apps/web/src/lib/server/auth-helpers.ts | Environment variable reference |
| I4G_VERTEX_SEARCH_DATA_STORE | apps/web/src/lib/server/discovery-config.ts | Environment variable reference |
| I4G_VERTEX_SEARCH_LOCATION | apps/web/src/lib/server/discovery-config.ts | Environment variable reference |
| I4G_VERTEX_SEARCH_PROJECT | apps/web/src/lib/server/discovery-config.ts | Environment variable reference |
| I4G_VERTEX_SEARCH_SERVING_CONFIG | apps/web/src/lib/server/discovery-config.ts | Environment variable reference |
| SSI_API_URL | apps/web/src/lib/server/ssi-proxy.ts | Environment variable reference |
