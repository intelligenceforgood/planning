# CORE Digest
Generated: 2026-07-14T16:03:15Z

## Public API
| Function/Class | File | Signature |
| :--- | :--- | :--- |
| APISettings | src/i4g/settings/sections/basic.py | `class APISettings(BaseSettings)` |
| ASNInfo | src/i4g/services/enrichment/asn_lookup.py | `class ASNInfo` |
| AccountListResponse | src/i4g/api/accounts.py | `class AccountListResponse(CamelModel)` |
| AccountResponse | src/i4g/api/accounts.py | `class AccountResponse(CamelModel)` |
| AccountStore | src/i4g/store/account_store.py | `class AccountStore` |
| ActionHistoryResponse | src/i4g/api/response_models.py | `class ActionHistoryResponse(CamelModel)` |
| ActiveInvestigationsResponse | src/i4g/api/ssi_investigations.py | `class ActiveInvestigationsResponse(CamelModel)` |
| ActivityPoint | src/i4g/api/intelligence.py | `class ActivityPoint(CamelModel)` |
| ActorDetailResponse | src/i4g/api/phishdestroy_actors.py | `class ActorDetailResponse(CamelModel)` |
| ActorIdentityEdge | src/i4g/api/phishdestroy_actors.py | `class ActorIdentityEdge(CamelModel)` |
| ActorIdentityEdgeStore | src/i4g/store/actor_identity_edge_store.py | `class ActorIdentityEdgeStore` |
| ActorIdentityRow | src/i4g/api/phishdestroy_actors.py | `class ActorIdentityRow(CamelModel)` |
| ActorIdentityStore | src/i4g/store/actor_identity_store.py | `class ActorIdentityStore` |
| ActorListResponse | src/i4g/api/phishdestroy_actors.py | `class ActorListResponse(CamelModel)` |
| AdvancedSearchResultsResponse | src/i4g/api/response_models.py | `class AdvancedSearchResultsResponse(CamelModel)` |
| AlertingService | src/i4g/services/alerting.py | `class AlertingService` |
| AnalystFeedbackRequest | src/i4g/taxonomy/models.py | `class AnalystFeedbackRequest(BaseModel)` |
| AnalyticsMetric | src/i4g/api/response_models.py | `class AnalyticsMetric(CamelModel)` |
| AnalyticsOverviewResponse | src/i4g/api/response_models.py | `class AnalyticsOverviewResponse(CamelModel)` |
| AnalyticsSettings | src/i4g/settings/sections/jobs.py | `class AnalyticsSettings(BaseSettings)` |
| AnalyticsStore | src/i4g/store/analytics_store.py | `class AnalyticsStore` |
| AnnotateRequest | src/i4g/api/review_queue.py | `class AnnotateRequest(BaseModel)` |
| AnnotateResponse | src/i4g/api/response_models.py | `class AnnotateResponse(CamelModel)` |
| AnnotationCreateRequest | src/i4g/api/intelligence.py | `class AnnotationCreateRequest(CamelModel)` |
| AnnotationResponse | src/i4g/api/intelligence.py | `class AnnotationResponse(CamelModel)` |
| AnnotationStore | src/i4g/store/annotation_store.py | `class AnnotationStore` |
| AnnotationUpdateRequest | src/i4g/api/intelligence.py | `class AnnotationUpdateRequest(CamelModel)` |
| ArchiveBackfillSummary | src/i4g/ingestion/phishdestroy/archive/backfill.py | `class ArchiveBackfillSummary` |
| ArchiveContext | src/i4g/ingestion/phishdestroy/archive/base.py | `class ArchiveContext` |
| ArtifactSignature | src/i4g/reports/dossier_signatures.py | `class ArtifactSignature` |
| ArtifactVerification | src/i4g/reports/dossier_signatures.py | `class ArtifactVerification` |
| AttachmentPayload | src/i4g/services/intake.py | `class AttachmentPayload` |
| AutoInvestigateSettings | src/i4g/settings/sections/jobs.py | `class AutoInvestigateSettings(BaseSettings)` |
| BackendWriteAttempt | src/i4g/store/ingest.py | `class BackendWriteAttempt` |
| BackfillSettings | src/i4g/settings/sections/jobs.py | `class BackfillSettings(BaseSettings)` |
| BackfillTask | src/i4g/backfill/registry.py | `class BackfillTask` |
| BatchEntitiesRequest | src/i4g/api/cases.py | `class BatchEntitiesRequest(BaseModel)` |
| BatchEntitiesResponse | src/i4g/api/cases.py | `class BatchEntitiesResponse(CamelModel)` |
| BatchIndicatorsRequest | src/i4g/api/cases.py | `class BatchIndicatorsRequest(BaseModel)` |
| BatchIndicatorsResponse | src/i4g/api/cases.py | `class BatchIndicatorsResponse(CamelModel)` |
| BatchTimelineRequest | src/i4g/api/cases.py | `class BatchTimelineRequest(BaseModel)` |
| BatchTimelineResponse | src/i4g/api/cases.py | `class BatchTimelineResponse(CamelModel)` |
| BigQueryExportSettings | src/i4g/settings/sections/jobs.py | `class BigQueryExportSettings(BaseSettings)` |
| BlobKind | src/i4g/ingestion/phishdestroy/archive/evidence.py | `class BlobKind(StrEnum)` |
| BlockchainEnrichmentResult | src/i4g/services/enrichment/blockchain.py | `class BlockchainEnrichmentResult` |
| BlockchainVendor | src/i4g/services/enrichment/blockchain.py | `class BlockchainVendor(StrEnum)` |
| BlocklistHitStore | src/i4g/store/blocklist_hit_store.py | `class BlocklistHitStore` |
| BlocklistModule | src/i4g/extraction/modules/blocklist.py | `class BlocklistModule` |
| BrandImpersonationStore | src/i4g/store/brand_impersonation_store.py | `class BrandImpersonationStore` |
| BulkActionRequest | src/i4g/api/intelligence.py | `class BulkActionRequest(CamelModel)` |
| ... | ... | ... and 1159 more entries collapsed |

## Data Models
| Model | File | Fields |
| :--- | :--- | :--- |
| APISettings | src/i4g/settings/sections/basic.py | `base_url: str, key: str, rate_limit_per_minute: int, cors_origins: list[str]` |
| AccountListResponse | src/i4g/api/accounts.py | `items: list[AccountResponse], count: int` |
| AccountResponse | src/i4g/api/accounts.py | `email: str, role: str, display_name: str | None, is_active: bool` |
| ActionHistoryResponse | src/i4g/api/response_models.py | `review_id: str, actions: list[dict[str, Any]]` |
| ActiveInvestigationsResponse | src/i4g/api/ssi_investigations.py | `active: list[dict[str, Any]], count: int` |
| ActivityPoint | src/i4g/api/intelligence.py | `week: str, case_count: int` |
| ActorDetailResponse | src/i4g/api/phishdestroy_actors.py | `actor: ThreatActorRow, identities: list[ActorIdentityRow], edges: list[ActorIdentityEdge], leak...` |
| ActorIdentityEdge | src/i4g/api/phishdestroy_actors.py | `source_identity_id: str, target_identity_id: str, edge_type: str` |
| ActorIdentityRow | src/i4g/api/phishdestroy_actors.py | `identity_id: str, platform: str, handle: str, metadata: dict[str, Any] | None` |
| ActorListResponse | src/i4g/api/phishdestroy_actors.py | `items: list[ThreatActorRow], total: int, limit: int, offset: int` |
| AdvancedSearchResultsResponse | src/i4g/api/response_models.py | `search_id: str, results: list[dict[str, Any]] | None, count: int | None, total: int | None` |
| AnalystFeedbackRequest | src/i4g/taxonomy/models.py | `original_classification: FraudClassificationResult | None, corrected_classification: FraudClass...` |
| AnalyticsMetric | src/i4g/api/response_models.py | `id: str, label: str, value: str, change: str, trend: str` |
| AnalyticsOverviewResponse | src/i4g/api/response_models.py | `metrics: list[AnalyticsMetric], detection_rate_series: list[DailySeries], pipeline_breakdown: l...` |
| AnalyticsSettings | src/i4g/settings/sections/jobs.py | `refresh_interval_minutes: int, loss_linkage_confidence_threshold: float, campaign_risk_weights:...` |
| AnnotateRequest | src/i4g/api/review_queue.py | `annotations: dict[str, Any], notes: str | None` |
| AnnotateResponse | src/i4g/api/response_models.py | `review_id: str, annotated: bool` |
| AnnotationCreateRequest | src/i4g/api/intelligence.py | `target_type: str, target_id: str, content: str` |
| AnnotationResponse | src/i4g/api/intelligence.py | `annotation_id: str, target_type: str, target_id: str, content: str, author: str, created_at: st...` |
| AnnotationUpdateRequest | src/i4g/api/intelligence.py | `content: str` |
| AutoInvestigateSettings | src/i4g/settings/sections/jobs.py | `enabled: bool, staleness_days: int, max_concurrent: int, domain_blocklist: list[str]` |
| BackfillSettings | src/i4g/settings/sections/jobs.py | `cycle_interval_seconds: int, default_lock_ttl_seconds: int, enabled_tasks: list[str]` |
| BatchEntitiesRequest | src/i4g/api/cases.py | `entities: list[EntityItem]` |
| BatchEntitiesResponse | src/i4g/api/cases.py | `case_id: str, created: int` |
| BatchIndicatorsRequest | src/i4g/api/cases.py | `indicators: list[IndicatorItem]` |
| BatchIndicatorsResponse | src/i4g/api/cases.py | `case_id: str, created: int` |
| BatchTimelineRequest | src/i4g/api/cases.py | `events: list[TimelineEventRequest]` |
| BatchTimelineResponse | src/i4g/api/cases.py | `case_id: str, created: int` |
| BigQueryExportSettings | src/i4g/settings/sections/jobs.py | `project_id: str, dataset_id: str, enabled: bool` |
| BulkActionRequest | src/i4g/api/intelligence.py | `entity_ids: list[str], action: str, tag: str | None, status: str | None` |
| BulkActionResult | src/i4g/api/intelligence.py | `processed: int, failed: int, errors: list[str]` |
| BulkTagResponse | src/i4g/api/response_models.py | `updated: int` |
| BulkTagUpdateRequest | src/i4g/api/review_search.py | `search_ids: list[str], add: list[str] | None, remove: list[str] | None, replace: list[str] | No...` |
| CamelModel | src/i4g/api/camel.py | `` |
| CampaignManagementRequest | src/i4g/api/intelligence.py | `action: str, name: str | None, description: str | None, status: str | None, case_ids: list[str]...` |
| CampaignResponse | src/i4g/api/campaigns.py | `id: str, name: str, description: str | None, taxonomy_labels: dict[str, Any] | None, taxonomy_r...` |
| CampaignTimelinePoint | src/i4g/api/intelligence.py | `date: str, case_count: int` |
| CaseActivity | src/i4g/api/cases.py | `type: str, status: str, started_at: datetime | None, completed_at: datetime | None, progress: i...` |
| CaseActivityResponse | src/i4g/api/cases.py | `case_id: str, activities: list[CaseActivity], has_running: bool` |
| CaseArtifact | src/i4g/api/cases.py | `id: str, type: str, name: str, url: str | None, metadata: dict[str, Any]` |
| CaseAssignment | src/i4g/api/engagements.py | `case_ids: list[str]` |
| CaseAssignmentResult | src/i4g/api/engagements.py | `count: int` |
| CaseDetail | src/i4g/api/cases.py | `id: str, title: str, status: CaseStatus, priority: CasePriority, assignee: str | None, updated_...` |
| CaseEntity | src/i4g/api/cases.py | `entity_type: str, entity_type_label: str, canonical_value: str, raw_value: str | None, confiden...` |
| CaseGraphLink | src/i4g/api/cases.py | `source: str, target: str, relation: str` |
| CaseGraphNode | src/i4g/api/cases.py | `id: str, label: str, type: str, data: dict[str, Any]` |
| CaseInvestigateRequest | src/i4g/api/cases.py | `url: str, force: bool` |
| CaseInvestigationSummary | src/i4g/api/cases.py | `scan_id: str, url: str, normalized_url: str | None, status: str, risk_score: float | None, comp...` |
| CaseListItem | src/i4g/api/response_models.py | `id: str, title: str, priority: str, status: str` |
| CaseQueue | src/i4g/api/response_models.py | `id: str, name: str, description: str, count: int` |
| ... | ... | ... and 212 more entries collapsed |

## Routes
| Method | Path | Handler | File |
| :--- | :--- | :--- | :--- |
| DELETE | /annotations/{annotation_id} | delete_annotation | src/i4g/api/intelligence.py |
| DELETE | /schedules/{schedule_id} | delete_report_schedule | src/i4g/api/reports.py |
| DELETE | /search/saved/{search_id} | delete_saved_search | src/i4g/api/review_search.py |
| DELETE | /watchlist/{watchlist_id} | remove_from_watchlist | src/i4g/api/intelligence.py |
| DELETE | /{case_id} | delete_case | src/i4g/api/cases.py |
| DELETE | /{engagement_id} | delete_engagement | src/i4g/api/engagements.py |
| DELETE | /{engagement_id}/cases | remove_cases | src/i4g/api/engagements.py |
| DELETE | /{playbook_id} | delete_playbook | src/i4g/api/ssi_playbooks.py |
| GET | / | list_intakes | src/i4g/api/intake.py |
| GET | /active | list_active_investigations | src/i4g/api/ssi_investigations.py |
| GET | /annotations | list_annotations | src/i4g/api/intelligence.py |
| GET | /campaigns | list_threat_campaigns | src/i4g/api/intelligence.py |
| GET | /campaigns/{campaign_id} | get_threat_campaign_detail | src/i4g/api/intelligence.py |
| GET | /campaigns/{campaign_id}/graph | get_campaign_graph | src/i4g/api/intelligence.py |
| GET | /campaigns/{campaign_id}/timeline | get_campaign_timeline | src/i4g/api/intelligence.py |
| GET | /case/{case_id} | reviews_by_case | src/i4g/api/review_detail.py |
| GET | /charts/{token_id}/embed | get_embedded_chart | src/i4g/api/intelligence.py |
| GET | /compare/kpis | compare_engagement_kpis | src/i4g/api/engagements.py |
| GET | /compare/trends | compare_engagement_trends | src/i4g/api/engagements.py |
| GET | /compare/universities | compare_universities | src/i4g/api/engagements.py |
| GET | /cumulative-indicators | get_cumulative_indicators | src/i4g/api/impact.py |
| GET | /dashboard | get_dashboard_widgets | src/i4g/api/intelligence.py |
| GET | /dashboard | get_impact_dashboard | src/i4g/api/impact.py |
| GET | /detection-velocity | get_detection_velocity | src/i4g/api/impact.py |
| GET | /dossiers | list_dossiers | src/i4g/api/reports.py |
| GET | /dossiers/{plan_id}/download/{artifact} | download_dossier_artifact | src/i4g/api/reports.py |
| GET | /dossiers/{plan_id}/drive_acl | fetch_drive_acl | src/i4g/api/reports.py |
| GET | /dossiers/{plan_id}/signature_manifest | fetch_signature_manifest | src/i4g/api/reports.py |
| GET | /entities | export_entities | src/i4g/api/exports.py |
| GET | /entities | list_entities | src/i4g/api/intelligence.py |
| GET | /entities/type-labels | list_entity_type_labels | src/i4g/api/intelligence.py |
| GET | /entities/types | list_entity_types | src/i4g/api/intelligence.py |
| GET | /entities/{entity_type}/{canonical_value} | get_entity | src/i4g/api/intelligence.py |
| GET | /entities/{entity_type}/{canonical_value}/activity | get_entity_activity | src/i4g/api/intelligence.py |
| GET | /entities/{entity_type}/{canonical_value}/cases | get_entity_cases | src/i4g/api/intelligence.py |
| GET | /entities/{entity_type}/{canonical_value}/neighbors | get_entity_neighbors | src/i4g/api/intelligence.py |
| GET | /export | export_evidence | src/i4g/api/evidence.py |
| GET | /geography | get_geography_summary | src/i4g/api/impact.py |
| GET | /geography/{country} | get_geography_detail | src/i4g/api/impact.py |
| GET | /graph | get_intelligence_graph | src/i4g/api/intelligence.py |
| GET | /graph/clusters | get_graph_clusters | src/i4g/api/intelligence.py |
| GET | /graph/export | export_graph | src/i4g/api/intelligence.py |
| GET | /graph/temporal | get_temporal_graph | src/i4g/api/intelligence.py |
| GET | /history | list_investigations | src/i4g/api/ssi_investigations.py |
| GET | /indicators | export_indicators | src/i4g/api/exports.py |
| GET | /indicators | list_indicators | src/i4g/api/intelligence.py |
| GET | /indicators | get_indicator_feed | src/i4g/api/partner_feed.py |
| GET | /indicators/{indicator_id} | get_indicator | src/i4g/api/intelligence.py |
| GET | /jobs/{job_id} | get_job | src/i4g/api/intake.py |
| GET | /lea-suggestions | get_lea_suggestions | src/i4g/api/intelligence.py |
| ... | ... | ... | ... and 107 more entries collapsed |

## Config
| Variable | File | Context |
| :--- | :--- | :--- |
| I4G_ANALYTICS__INFRASTRUCTURE_CLUSTERING_INTERVAL_HOURS | src/i4g/worker/jobs/infrastructure_clustering.py | Environment variable reference |
| I4G_ANALYTICS__REFRESH_INTERVAL_MINUTES | src/i4g/settings/sections/jobs.py | Environment variable reference |
| I4G_ANALYTICS__REFRESH_INTERVAL_MINUTES | src/i4g/worker/jobs/analytics_aggregation.py | Environment variable reference |
| I4G_ANALYTICS__SCHEDULED_REPORT_CHECK_INTERVAL_MINUTES | src/i4g/worker/jobs/scheduled_reports.py | Environment variable reference |
| I4G_ANALYTICS__WATCHLIST_CHECK_INTERVAL_MINUTES | src/i4g/worker/jobs/watchlist_check.py | Environment variable reference |
| I4G_API__KEY | src/i4g/api/auth.py | Environment variable reference |
| I4G_API__KEY | src/i4g/cli/smoke/runner.py | Environment variable reference |
| I4G_API__URL | src/i4g/cli/smoke/runner.py | Environment variable reference |
| I4G_APP__CLOUDSQL__ | src/i4g/cli/bootstrap/dev/verify.py | Environment variable reference |
| I4G_APP__CLOUDSQL__DATABASE | src/i4g/cli/bootstrap/dev/jobs.py | Environment variable reference |
| I4G_APP__CLOUDSQL__DATABASE | src/i4g/cli/bootstrap/dev/verify.py | Environment variable reference |
| I4G_APP__CLOUDSQL__DATABASE | src/i4g/settings/sections/basic.py | Environment variable reference |
| I4G_APP__CLOUDSQL__ENABLE_IAM_AUTH | src/i4g/cli/bootstrap/dev/jobs.py | Environment variable reference |
| I4G_APP__CLOUDSQL__ENABLE_IAM_AUTH | src/i4g/settings/sections/basic.py | Environment variable reference |
| I4G_APP__CLOUDSQL__INSTANCE | src/i4g/cli/bootstrap/dev/jobs.py | Environment variable reference |
| I4G_APP__CLOUDSQL__INSTANCE | src/i4g/cli/bootstrap/dev/verify.py | Environment variable reference |
| I4G_APP__CLOUDSQL__INSTANCE | src/i4g/settings/sections/basic.py | Environment variable reference |
| I4G_APP__CLOUDSQL__PASSWORD | src/i4g/cli/bootstrap/dev/verify.py | Environment variable reference |
| I4G_APP__CLOUDSQL__PASSWORD | src/i4g/settings/sections/basic.py | Environment variable reference |
| I4G_APP__CLOUDSQL__USER | src/i4g/cli/bootstrap/dev/jobs.py | Environment variable reference |
| I4G_APP__CLOUDSQL__USER | src/i4g/cli/bootstrap/dev/verify.py | Environment variable reference |
| I4G_APP__CLOUDSQL__USER | src/i4g/settings/sections/basic.py | Environment variable reference |
| I4G_BQ_EXPORT__ | src/i4g/worker/jobs/bq_export.py | Environment variable reference |
| I4G_BQ_EXPORT__ENABLED | src/i4g/worker/jobs/bq_export.py | Environment variable reference |
| I4G_BQ_EXPORT__PROJECT_ID | src/i4g/settings/sections/jobs.py | Environment variable reference |
| I4G_CRYPTO__PII_KEY | src/i4g/pii/encryption.py | Environment variable reference |
| I4G_DATABASE_URL | src/i4g/cli/bootstrap/local/steps.py | Environment variable reference |
| I4G_DATABASE_URL | src/i4g/migrations/env.py | Environment variable reference |
| I4G_DATABASE_URL | src/i4g/store/sql.py | Environment variable reference |
| I4G_DB_ADMIN__ | src/i4g/cli/db/__init__.py | Environment variable reference |
| I4G_DB_ADMIN__DEV_PASSWORD | src/i4g/settings/sections/basic.py | Environment variable reference |
| I4G_DB_ADMIN__PROD_PASSWORD | src/i4g/settings/sections/basic.py | Environment variable reference |
| I4G_EMAIL__FROM_ADDRESS | src/i4g/services/email_service.py | Environment variable reference |
| I4G_EMAIL__PROVIDER | src/i4g/services/email_service.py | Environment variable reference |
| I4G_EMAIL__PROVIDER | src/i4g/settings/sections/jobs.py | Environment variable reference |
| I4G_EMAIL__SMTP_HOST | src/i4g/services/email_service.py | Environment variable reference |
| I4G_EMAIL__SMTP_HOST | src/i4g/settings/sections/jobs.py | Environment variable reference |
| I4G_EMAIL__SMTP_PASSWORD | src/i4g/services/email_service.py | Environment variable reference |
| I4G_EMAIL__SMTP_PORT | src/i4g/services/email_service.py | Environment variable reference |
| I4G_EMAIL__SMTP_USER | src/i4g/services/email_service.py | Environment variable reference |
| I4G_ENRICHMENT__BLOCKCHAIN_API_KEY | src/i4g/services/enrichment/blockchain.py | Environment variable reference |
| I4G_ENRICHMENT__BLOCKCHAIN_VENDOR | src/i4g/services/enrichment/blockchain.py | Environment variable reference |
| I4G_ENRICHMENT__SECURITYTRAILS_API_KEY | src/i4g/services/enrichment/passive_dns.py | Environment variable reference |
| I4G_ENRICHMENT__SECURITYTRAILS_API_KEY | src/i4g/settings/sections/jobs.py | Environment variable reference |
| I4G_ENRICHMENT__TAKEDOWN_CHECK_INTERVAL_HOURS | src/i4g/worker/jobs/takedown_check.py | Environment variable reference |
| I4G_ENV | src/i4g/api/auth.py | Environment variable reference |
| I4G_ENV | src/i4g/api/feedback.py | Environment variable reference |
| I4G_ENV | src/i4g/cli/app.py | Environment variable reference |
| I4G_ENV | src/i4g/cli/bootstrap/dev/ingest.py | Environment variable reference |
| I4G_ENV | src/i4g/cli/bootstrap/dev/orchestrator.py | Environment variable reference |
| ... | ... | ... and 342 more entries collapsed |
