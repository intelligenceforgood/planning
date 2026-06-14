# CORE Digest
Generated: 2026-06-14T03:15:27.403234Z

## Public API
| Function/Class | File | Signature |
|:---|:---|:---|
| luhn_check | src/i4g/patterns.py | `def luhn_check(number: str) -> bool` |
| Observability | src/i4g/observability.py | `class Observability` |
| get_observability | src/i4g/observability.py | `def get_observability() -> Observability` |
| reset_observability_cache | src/i4g/observability.py | `def reset_observability_cache() -> None` |
| TaskStatusReporter | src/i4g/task_status.py | `class TaskStatusReporter` |
| detect_signals | src/i4g/classification/rules.py | `def detect_signals(text: str) -> dict[str, list[ScoredLabel]]` |
| DomainDiscovery | src/i4g/clients/merklemap.py | `class DomainDiscovery` |
| tail | src/i4g/clients/merklemap.py | `async def tail() -> AsyncIterator[DomainDiscovery]` |
| get_settings | src/i4g/settings/config.py | `def get_settings(env: str | None) -> Settings` |
| reload_settings | src/i4g/settings/config.py | `def reload_settings(env: str | None) -> Settings` |
| apply_local_defaults | src/i4g/settings/runtime_overrides.py | `def apply_local_defaults(settings: Settings) -> Settings` |
| resolve_paths | src/i4g/settings/runtime_overrides.py | `def resolve_paths(settings: Settings) -> Settings` |
| normalize_ingestion_paths | src/i4g/settings/runtime_overrides.py | `def normalize_ingestion_paths(settings: Settings) -> None` |
| apply_environment_overrides | src/i4g/settings/runtime_overrides.py | `def apply_environment_overrides(settings: Settings, read_env_value: Callable[..., str | None]) -> Settings` |
| detect_project_root | src/i4g/settings/sections/_paths.py | `def detect_project_root() -> Path` |
| build_fernet | src/i4g/pii/encryption.py | `def build_fernet(raw_key: str | None) -> Fernet | None` |
| encrypt_value | src/i4g/pii/encryption.py | `def encrypt_value(plaintext: str | None, raw_key: str | None) -> str | None` |
| decrypt_value | src/i4g/pii/encryption.py | `def decrypt_value(ciphertext: str | None, raw_key: str | None) -> str | None` |
| clean_text | src/i4g/ingestion/preprocess.py | `def clean_text(text: str) -> str` |
| chunk_text | src/i4g/ingestion/preprocess.py | `def chunk_text(text: str, chunk_size: int) -> list[str]` |
| prepare_documents | src/i4g/ingestion/preprocess.py | `def prepare_documents(ocr_results: list[dict[str, str]]) -> list[dict[str, str]]` |
| IngestSummary | src/i4g/ingestion/phishdestroy/destroylist.py | `class IngestSummary` |
| ingest_destroylist | src/i4g/ingestion/phishdestroy/destroylist.py | `def ingest_destroylist() -> IngestSummary` |
| IngestSummary | src/i4g/ingestion/phishdestroy/actors.py | `class IngestSummary` |
| ingest_actors | src/i4g/ingestion/phishdestroy/actors.py | `def ingest_actors(...) -> IngestSummary` |
| TeamFormat | src/i4g/ingestion/phishdestroy/archive/detector.py | `class TeamFormat(StrEnum)` |
| UnknownFormatError | src/i4g/ingestion/phishdestroy/archive/detector.py | `class UnknownFormatError(Exception)` |
| detect_team_format | src/i4g/ingestion/phishdestroy/archive/detector.py | `def detect_team_format(team_dir: Path) -> TeamFormat` |
| IngestArchiveSummary | src/i4g/ingestion/phishdestroy/archive/runner.py | `class IngestArchiveSummary` |
| ingest_team_archive | src/i4g/ingestion/phishdestroy/archive/runner.py | `def ingest_team_archive(team_dir: Path, ctx: ArchiveContext) -> IngestArchiveSummary` |
| FlatFilesAdapter | src/i4g/ingestion/phishdestroy/archive/flat_files_adapter.py | `class FlatFilesAdapter` |
| TeamBlobConfig | src/i4g/ingestion/phishdestroy/archive/team_config.py | `class TeamBlobConfig` |
| TeamConfig | src/i4g/ingestion/phishdestroy/archive/team_config.py | `class TeamConfig` |
| get_team_config | src/i4g/ingestion/phishdestroy/archive/team_config.py | `def get_team_config(team_name: str) -> TeamConfig` |
| TrustWalletPanelAdapter | src/i4g/ingestion/phishdestroy/archive/trustwalletpanel.py | `class TrustWalletPanelAdapter` |
| ArchiveBackfillSummary | src/i4g/ingestion/phishdestroy/archive/backfill.py | `class ArchiveBackfillSummary` |
| run_archive_backfill | src/i4g/ingestion/phishdestroy/archive/backfill.py | `def run_archive_backfill(archive_root: Path, ctx: ArchiveContext) -> ArchiveBackfillSummary` |
| DamageRecord | src/i4g/ingestion/phishdestroy/archive/damage.py | `class DamageRecord` |
| parse_deposit_messages | src/i4g/ingestion/phishdestroy/archive/damage.py | `def parse_deposit_messages(messages: Iterable[dict[str, Any]]) -> tuple[list[DamageRecord], int]` |
| lookup_indicators_for_domain | src/i4g/ingestion/phishdestroy/archive/brands.py | `def lookup_indicators_for_domain(session_factory: Callable[..., Any], domain: str) -> list[str]` |
| BlobKind | src/i4g/ingestion/phishdestroy/archive/evidence.py | `class BlobKind(StrEnum)` |
| EvidenceBlobRef | src/i4g/ingestion/phishdestroy/archive/evidence.py | `class EvidenceBlobRef` |
| predict_storage_uri | src/i4g/ingestion/phishdestroy/archive/evidence.py | `def predict_storage_uri(evidence_storage: EvidenceStorage, intake_id: str, file_name: str) -> str` |
| persist_chat_export | src/i4g/ingestion/phishdestroy/archive/evidence.py | `def persist_chat_export(evidence_storage: EvidenceStorage | None, team: str, file_path: Path) -> tuple[str, str] | None` |
| persist_team_blobs | src/i4g/ingestion/phishdestroy/archive/evidence.py | `def persist_team_blobs(evidence_storage: EvidenceStorage | None, team: str, team_dir: Path) -> list[EvidenceBlobRef]` |
| ArchiveContext | src/i4g/ingestion/phishdestroy/archive/base.py | `class ArchiveContext` |
| build_chat_provenance | src/i4g/ingestion/phishdestroy/archive/base.py | `def build_chat_provenance(team: str, record_id: str, ctx: ArchiveContext) -> dict[str, Any]` |
| build_infra_provenance | src/i4g/ingestion/phishdestroy/archive/base.py | `def build_infra_provenance(team: str, record_id: str, ctx: ArchiveContext) -> dict[str, Any]` |
| build_financial_damage_provenance | src/i4g/ingestion/phishdestroy/archive/base.py | `def build_financial_damage_provenance(team: str, record_id: str, ctx: ArchiveContext) -> dict[str, Any]` |
| TeamAdapter | src/i4g/ingestion/phishdestroy/archive/base.py | `class TeamAdapter(Protocol)` |
| ... | ... | `... and 660 more entries collapsed` |

## Data Models
| Model | File | Fields |
|:---|:---|:---|
| CitationSource | src/i4g/rag/models.py | `chunk_id: str, excerpt: str` |
| RagAssessment | src/i4g/rag/models.py | `is_scam: bool, confidence: float, reasoning: str, citations: list[CitationSource]` |
| ScoredLabel | src/i4g/taxonomy/models.py | `label: str, confidence: float, explanation: str | None` |
| FraudClassificationResult | src/i4g/taxonomy/models.py | `intent: list[ScoredLabel], channel: list[ScoredLabel], techniques: list[ScoredLabel], actions: li...` |
| AnalystFeedbackRequest | src/i4g/taxonomy/models.py | `original_classification: FraudClassificationResult | None, corrected_classification: FraudClassif...` |
| IntakeSubmission | src/i4g/api/intake.py | `reporter_name: str, summary: str, details: str, submitted_by: str | None, contact_email: str | No...` |
| IntakeJobUpdate | src/i4g/api/intake.py | `status: str, message: str | None, metadata: dict[str, Any] | None` |
| IntakeStatusUpdate | src/i4g/api/intake.py | `status: str, message: str | None` |
| IntakeCaseAttachment | src/i4g/api/intake.py | `case_id: str | None, review_id: str | None` |
| ItemListResponse | src/i4g/api/response_models.py | `items: list[dict[str, Any]], count: int` |
| EventListResponse | src/i4g/api/response_models.py | `events: list[dict[str, Any]], count: int` |
| IdResponse | src/i4g/api/response_models.py | `search_id: str` |
| MutationResponse | src/i4g/api/response_models.py | `updated: bool | None, deleted: bool | None, search_id: str | None` |
| BulkTagResponse | src/i4g/api/response_models.py | `updated: int` |
| TaskStatusResponse | src/i4g/api/response_models.py | `task_id: str, status: str, message: str | None, investigation_id: str | None, risk_score: float |...` |
| TaskUpdateResponse | src/i4g/api/response_models.py | `task_id: str, updated: bool` |
| ReportTriggerResponse | src/i4g/api/response_models.py | `status: str, task_id: str` |
| EnqueueResponse | src/i4g/api/response_models.py | `review_id: str, case_id: str` |
| ClaimResponse | src/i4g/api/response_models.py | `review_id: str, status: str` |
| AnnotateResponse | src/i4g/api/response_models.py | `review_id: str, annotated: bool` |
| FeedbackResponse | src/i4g/api/response_models.py | `review_id: str, feedback_recorded: bool` |
| DecisionResponse | src/i4g/api/response_models.py | `review_id: str, status: str` |
| CaseReviewsResponse | src/i4g/api/response_models.py | `case_id: str, reviews: list[dict[str, Any]], count: int` |
| ActionHistoryResponse | src/i4g/api/response_models.py | `review_id: str, actions: list[dict[str, Any]]` |
| SearchResultsResponse | src/i4g/api/response_models.py | `results: list[dict[str, Any]], count: int, offset: int, limit: int, total: int, vector_hits: int ...` |
| AdvancedSearchResultsResponse | src/i4g/api/response_models.py | `search_id: str, results: list[dict[str, Any]] | None, count: int | None, total: int | None` |
| SearchSchemaResponse | src/i4g/api/response_models.py | `classifications: list[str] | None, campaigns: list[dict[str, Any]] | None` |
| PresetListResponse | src/i4g/api/response_models.py | `presets: list[dict[str, Any]], count: int` |
| TokenizeResponse | src/i4g/api/response_models.py | `token: str, prefix: str, digest: str, normalized_value: str, pepper_version: int` |
| DetokenizeResponse | src/i4g/api/response_models.py | `token: str, prefix: str, canonical_value: str, pepper_version: int, case_id: str | None, detector...` |
| TokenizationHealthResponse | src/i4g/api/response_models.py | `pepper_configured: bool, pepper_version: int, encryption_enabled: bool` |
| IntakeCreateResponse | src/i4g/api/response_models.py | `intake_id: str, job_id: str | None, attachments: list[dict[str, Any]], status: str, job: dict[str...` |
| IntakeJobUpdateResponse | src/i4g/api/response_models.py | `updated: bool, job_id: str` |
| IntakeStatusUpdateResponse | src/i4g/api/response_models.py | `updated: bool, intake_id: str` |
| IntakeCaseAttachResponse | src/i4g/api/response_models.py | `updated: bool, intake_id: str, case_id: str | None, review_id: str | None` |
| VerifyArtifact | src/i4g/api/response_models.py | `label: str, path: str | None, expected_hash: str | None, actual_hash: str | None, exists: bool, m...` |
| DossierVerifyResponse | src/i4g/api/response_models.py | `plan_id: str, algorithm: str, warnings: list[str], missing_count: int, mismatch_count: int, all_v...` |
| DriveAclResponse | src/i4g/api/response_models.py | `plan_id: str, folder_id: str | None, folder_name: str | None, link: str | None, drive_id: str | N...` |
| DashboardMetric | src/i4g/api/response_models.py | `label: str, value: str, change: str` |
| DashboardActivity | src/i4g/api/response_models.py | `id: str, title: str, actor: str, when: str` |
| DashboardAlert | src/i4g/api/response_models.py | `id: str, title: str, detail: str, time: str, variant: str` |
| DashboardReminder | src/i4g/api/response_models.py | `id: str, text: str, category: str` |
| DashboardOverviewResponse | src/i4g/api/response_models.py | `metrics: list[DashboardMetric], alerts: list[DashboardAlert], activity: list[DashboardActivity], ...` |
| AnalyticsMetric | src/i4g/api/response_models.py | `id: str, label: str, value: str, change: str, trend: str` |
| DailySeries | src/i4g/api/response_models.py | `label: str, value: int` |
| PipelineStep | src/i4g/api/response_models.py | `label: str, value: int` |
| WeeklyIncident | src/i4g/api/response_models.py | `week: str, incidents: int, interventions: int` |
| GeographyBreakdown | src/i4g/api/response_models.py | `region: str, value: int` |
| AnalyticsOverviewResponse | src/i4g/api/response_models.py | `metrics: list[AnalyticsMetric], detection_rate_series: list[DailySeries], pipeline_breakdown: lis...` |
| DiscoveryResult | src/i4g/api/response_models.py | `document_id: str | None, document_name: str | None` |
| ... | ... | `... and 175 more entries collapsed` |

## Routes
| Method | Path | Handler | File |
|:---|:---|:---|:---|
| POST | / | submit_intake | src/i4g/api/intake.py |
| GET | / | list_intakes | src/i4g/api/intake.py |
| GET | /{intake_id} | get_intake | src/i4g/api/intake.py |
| GET | /{intake_id}/contact | get_intake_contact | src/i4g/api/intake.py |
| GET | /jobs/{job_id} | get_job | src/i4g/api/intake.py |
| POST | /jobs/{job_id} | update_job | src/i4g/api/intake.py |
| POST | /{intake_id}/status | update_intake_status | src/i4g/api/intake.py |
| POST | /{intake_id}/case | attach_case | src/i4g/api/intake.py |
| GET | /entities | export_entities | src/i4g/api/exports.py |
| GET | /indicators | export_indicators | src/i4g/api/exports.py |
| GET | /researcher/entities | export_researcher_entities | src/i4g/api/exports.py |
| POST | / | enqueue_case | src/i4g/api/review_queue.py |
| GET | /queue | list_queue | src/i4g/api/review_queue.py |
| POST | /{review_id}/claim | claim_review | src/i4g/api/review_queue.py |
| POST | /{review_id}/annotate | annotate_review | src/i4g/api/review_queue.py |
| POST | /{review_id}/feedback | submit_feedback | src/i4g/api/review_queue.py |
| POST | /{review_id}/decision | decision | src/i4g/api/review_queue.py |
| GET | /history | list_investigations | src/i4g/api/ssi_investigations.py |
| GET | /active | list_active_investigations | src/i4g/api/ssi_investigations.py |
| GET | /{scan_id} | get_investigation | src/i4g/api/ssi_investigations.py |
| PATCH | /{scan_id} | update_investigation | src/i4g/api/ssi_investigations.py |
| GET | unknown | list_discoveries | src/i4g/api/phishdestroy_discoveries.py |
| POST | /{discovery_id}/enqueue | enqueue_discovery | src/i4g/api/phishdestroy_discoveries.py |
| POST | /{discovery_id}/dismiss | dismiss_discovery | src/i4g/api/phishdestroy_discoveries.py |
| GET | /search | discovery_search | src/i4g/api/discovery.py |
| GET | /me | get_current_user | src/i4g/api/accounts.py |
| GET | unknown | list_accounts | src/i4g/api/accounts.py |
| PUT | /{email}/role | update_user_role | src/i4g/api/accounts.py |
| PUT | /{email}/deactivate | deactivate_account | src/i4g/api/accounts.py |
| PUT | /{email}/reactivate | reactivate_account | src/i4g/api/accounts.py |
| POST | unknown | submit_feedback | src/i4g/api/feedback.py |
| GET | /wallets | search_wallets | src/i4g/api/ssi_wallets.py |
| GET | /{scan_id}/wallets.csv | export_wallets_csv | src/i4g/api/ssi_wallets.py |
| GET | /{scan_id}/wallets.xlsx | export_wallets_xlsx | src/i4g/api/ssi_wallets.py |
| POST | unknown | create_engagement | src/i4g/api/engagements.py |
| GET | unknown | list_engagements | src/i4g/api/engagements.py |
| GET | /{engagement_id} | get_engagement | src/i4g/api/engagements.py |
| PATCH | /{engagement_id} | update_engagement | src/i4g/api/engagements.py |
| DELETE | /{engagement_id} | delete_engagement | src/i4g/api/engagements.py |
| POST | /{engagement_id}/cases | assign_cases | src/i4g/api/engagements.py |
| DELETE | /{engagement_id}/cases | remove_cases | src/i4g/api/engagements.py |
| GET | /{engagement_id}/summary | get_engagement_summary | src/i4g/api/engagements.py |
| GET | /{engagement_id}/analytics | get_engagement_analytics | src/i4g/api/engagements.py |
| GET | /{engagement_id}/leaderboard | get_engagement_leaderboard | src/i4g/api/engagements.py |
| GET | /{engagement_id}/export | export_engagement | src/i4g/api/engagements.py |
| GET | /compare/kpis | compare_engagement_kpis | src/i4g/api/engagements.py |
| GET | /compare/trends | compare_engagement_trends | src/i4g/api/engagements.py |
| GET | /compare/universities | compare_universities | src/i4g/api/engagements.py |
| GET | /entities/types | list_entity_types | src/i4g/api/intelligence.py |
| GET | /entities/type-labels | list_entity_type_labels | src/i4g/api/intelligence.py |
| ... | ... | ... | ... and 120 more entries collapsed |

## Config
| Variable | File | Context |
|:---|:---|:---|
| I4G_TASK_ID | src/i4g/task_status.py | Environment variable reference |
| I4G_TASK_STATUS_URL | src/i4g/task_status.py | Environment variable reference |
| I4G_ENV | src/i4g/settings/config.py | Environment variable reference |
| I4G_SETTINGS_FILE | src/i4g/settings/config.py | Environment variable reference |
| I4G_RUNTIME__PROJECT_ROOT | src/i4g/settings/config.py | Environment variable reference |
| env | src/i4g/settings/config.py | Settings field in Settings |
| project_root | src/i4g/settings/config.py | Settings field in Settings |
| data_dir | src/i4g/settings/config.py | Settings field in Settings |
| runtime | src/i4g/settings/config.py | Settings field in Settings |
| api | src/i4g/settings/config.py | Settings field in Settings |
| identity | src/i4g/settings/config.py | Settings field in Settings |
| storage | src/i4g/settings/config.py | Settings field in Settings |
| vector | src/i4g/settings/config.py | Settings field in Settings |
| llm | src/i4g/settings/config.py | Settings field in Settings |
| crypto | src/i4g/settings/config.py | Settings field in Settings |
| secrets | src/i4g/settings/config.py | Settings field in Settings |
| ingestion | src/i4g/settings/config.py | Settings field in Settings |
| observability | src/i4g/settings/config.py | Settings field in Settings |
| intake | src/i4g/settings/config.py | Settings field in Settings |
| search | src/i4g/settings/config.py | Settings field in Settings |
| report | src/i4g/settings/config.py | Settings field in Settings |
| ingest_retry_job | src/i4g/settings/config.py | Settings field in Settings |
| sweep | src/i4g/settings/config.py | Settings field in Settings |
| dossier_job | src/i4g/settings/config.py | Settings field in Settings |
| smoke | src/i4g/settings/config.py | Settings field in Settings |
| ssi | src/i4g/settings/config.py | Settings field in Settings |
| redis | src/i4g/settings/config.py | Settings field in Settings |
| feedback | src/i4g/settings/config.py | Settings field in Settings |
| analytics | src/i4g/settings/config.py | Settings field in Settings |
| bq_export | src/i4g/settings/config.py | Settings field in Settings |
| enrichment | src/i4g/settings/config.py | Settings field in Settings |
| extraction | src/i4g/settings/config.py | Settings field in Settings |
| email | src/i4g/settings/config.py | Settings field in Settings |
| partner_feed | src/i4g/settings/config.py | Settings field in Settings |
| phishdestroy | src/i4g/settings/config.py | Settings field in Settings |
| db_admin | src/i4g/settings/config.py | Settings field in Settings |
| auto_investigate | src/i4g/settings/config.py | Settings field in Settings |
| backfill | src/i4g/settings/config.py | Settings field in Settings |
| ml | src/i4g/settings/config.py | Settings field in Settings |
| env_files | src/i4g/settings/config.py | Settings field in Settings |
| config_files | src/i4g/settings/config.py | Settings field in Settings |
| I4G_LLM__PROVIDER | src/i4g/settings/runtime_overrides.py | Environment variable reference |
| I4G_LLM_PROVIDER | src/i4g/settings/runtime_overrides.py | Environment variable reference |
| I4G_PROJECT_ROOT | src/i4g/settings/sections/_paths.py | Environment variable reference |
| I4G_RUNTIME__PROJECT_ROOT | src/i4g/settings/sections/_paths.py | Environment variable reference |
| I4G_VERTEX_SEARCH_PROJECT | src/i4g/settings/sections/ml.py | Environment variable reference |
| I4G_VERTEX_SEARCH_LOCATION | src/i4g/settings/sections/ml.py | Environment variable reference |
| I4G_VERTEX_SEARCH_DATA_STORE | src/i4g/settings/sections/ml.py | Environment variable reference |
| I4G_VERTEX_SEARCH_BRANCH | src/i4g/settings/sections/ml.py | Environment variable reference |
| I4G_VERTEX_SEARCH_SERVING_CONFIG | src/i4g/settings/sections/ml.py | Environment variable reference |
| ... | ... | ... and 341 more entries collapsed |
