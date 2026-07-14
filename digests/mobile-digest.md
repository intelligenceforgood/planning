# MOBILE Digest
Generated: 2026-07-14T16:03:15Z

## Public API
| Function/Class | File | Signature |
| :--- | :--- | :--- |
| ActivityRow | app/src/features/dashboard/components/ActivityRow.tsx | `export function ActivityRow({ item }: Props)` |
| ApiClient | app/src/api/client.ts | `export interface ApiClient` |
| ApiError | app/src/api/errors.ts | `export class ApiError` |
| AuditLogSection | app/src/features/reviews/components/AuditLogSection.tsx | `export function AuditLogSection({ entries }: Props)` |
| AuthError | app/src/api/errors.ts | `export class AuthError` |
| AuthProvider | app/src/auth/provider.ts | `export interface AuthProvider` |
| AuthState | app/src/auth/provider.ts | `export type AuthState` |
| CaseClassificationSection | app/src/features/reviews/components/CaseClassificationSection.tsx | `export function CaseClassificationSection({ caseDetail }: Props)` |
| CaseHeader | app/src/features/reviews/components/CaseHeader.tsx | `export function CaseHeader({ review, onDecide }: Props)` |
| CaseSummarySection | app/src/features/reviews/components/CaseSummarySection.tsx | `export function CaseSummarySection({ caseDetail }: Props)` |
| CaseTimelineSection | app/src/features/reviews/components/CaseTimelineSection.tsx | `export function CaseTimelineSection({ timeline }: Props)` |
| DecisionSheet | app/src/features/reviews/components/DecisionSheet.tsx | `export function DecisionSheet({ visible, reviewId, onClose, onSuccess }: Props)` |
| ErrorBoundary | app/src/lib/error-boundary.tsx | `export class ErrorBoundary` |
| EvidenceGrid | app/src/features/evidence/components/EvidenceGrid.tsx | `export function EvidenceGrid({ documents, onPress }: Props)` |
| FilterBar | app/src/features/reviews/components/FilterBar.tsx | `export function FilterBar({ value, onChange }: Props)` |
| FilterBarValue | app/src/features/reviews/components/FilterBar.tsx | `export type FilterBarValue` |
| MetricCard | app/src/features/dashboard/components/MetricCard.tsx | `export function MetricCard({ metric }: Props)` |
| NetworkError | app/src/api/errors.ts | `export class NetworkError` |
| NotFoundError | app/src/api/errors.ts | `export class NotFoundError` |
| QueueFilter | app/src/store/ui.ts | `export type QueueFilter` |
| QueueRow | app/src/features/reviews/components/QueueRow.tsx | `export function QueueRow({ item }: Props)` |
| ReqOpts | app/src/api/client.ts | `export type ReqOpts` |
| SearchBox | app/src/features/reviews/components/SearchBox.tsx | `export function SearchBox({ onDebouncedChange, placeholder = 'Search cases…' }: Props)` |
| SectionErrorBoundary | app/src/lib/SectionErrorBoundary.tsx | `export class SectionErrorBoundary` |
| ServerError | app/src/api/errors.ts | `export class ServerError` |
| Toast | app/src/store/ui.ts | `export type Toast` |
| ToastHost | app/src/lib/ToastHost.tsx | `export function ToastHost()` |
| User | app/src/auth/provider.ts | `export type User` |
| User | app/src/store/ui.ts | `export type User` |
| ValidationError | app/src/api/errors.ts | `export class ValidationError` |
| buildErrorFromResponse | app/src/api/errors.ts | `export function buildErrorFromResponse(res: Response)` |
| createApiClient | app/src/api/client.ts | `export function createApiClient(auth: AuthProvider, baseUrl: string)` |
| getApi | app/src/api/index.ts | `export function getApi()` |
| initSentry | app/src/lib/sentry.ts | `export function initSentry()` |
| mapErrorToBanner | app/src/api/errors.ts | `export function mapErrorToBanner(err: unknown)` |
| redactEvent | app/src/lib/redact.ts | `export function redactEvent(event: Redactable)` |
| redactObject | app/src/lib/redact.ts | `export function redactObject(obj: unknown)` |
| resetApi | app/src/api/index.ts | `export function resetApi()` |
| useAuditLog | app/src/features/reviews/queries.ts | `export function useAuditLog(reviewId: string)` |
| useCase | app/src/features/reviews/queries.ts | `export function useCase(id: string)` |
| useCaseDetail | app/src/features/reviews/queries.ts | `export function useCaseDetail(caseId: string)` |
| useCaseFull | app/src/features/reviews/queries.ts | `export function useCaseFull(reviewId: string)` |
| useDashboard | app/src/features/dashboard/queries.ts | `export function useDashboard()` |
| useDecide | app/src/features/reviews/queries.ts | `export function useDecide(reviewId: string)` |
| useEvidenceItem | app/src/features/evidence/queries.ts | `export function useEvidenceItem(caseId: string, documentId: string)` |
| useEvidenceList | app/src/features/evidence/queries.ts | `export function useEvidenceList(caseId: string)` |
| useReport | app/src/features/reports/queries.ts | `export function useReport(reportId: string)` |
| useReportsLibrary | app/src/features/reports/queries.ts | `export function useReportsLibrary()` |
| useReviewsQueue | app/src/features/reviews/queries.ts | `export function useReviewsQueue(params: { status?: string; limit?: number } = {})` |
| useTheme | app/src/design/theme.ts | `export function useTheme()` |
| ... | ... | ... and 1 more entries collapsed |

## Data Models
| Model | File | Fields |
| :--- | :--- | :--- |
| ApiClient | app/src/api/client.ts | `` |
| AuthProvider | app/src/auth/provider.ts | `` |
| AuthState | app/src/auth/provider.ts | `user: User | null, isInitialized: boolean` |
| FilterBarValue | app/src/features/reviews/components/FilterBar.tsx | `status: string | undefined, priority: string | undefined` |
| QueueFilter | app/src/store/ui.ts | `status: string | undefined, priority: string | undefined` |
| ReqOpts | app/src/api/client.ts | `signal: AbortSignal` |
| Toast | app/src/store/ui.ts | `id: string, message: string, variant: 'info' | 'success' | 'warning' | 'error'` |
| User | app/src/auth/provider.ts | `email: string, name: string, roles: string[]` |
| User | app/src/store/ui.ts | `email: string, name: string, roles: string[]` |

## Routes
None found

## Config
None found
