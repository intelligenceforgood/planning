# SSI Digest
Generated: 2026-07-14T16:03:15Z

## Public API
| Function/Class | File | Signature |
| :--- | :--- | :--- |
| APISettings | src/ssi/settings/config.py | `class APISettings(BaseSettings)` |
| ActionType | src/ssi/models/action.py | `class ActionType(StrEnum)` |
| ActionType | src/ssi/models/agent.py | `class ActionType(StrEnum)` |
| AgentAction | src/ssi/models/action.py | `class AgentAction(BaseModel)` |
| AgentAction | src/ssi/models/agent.py | `class AgentAction` |
| AgentController | src/ssi/browser/agent_controller.py | `class AgentController` |
| AgentLLMClient | src/ssi/browser/llm_client.py | `class AgentLLMClient` |
| AgentMetrics | src/ssi/models/agent.py | `class AgentMetrics` |
| AgentSession | src/ssi/models/agent.py | `class AgentSession` |
| AgentSettings | src/ssi/settings/config.py | `class AgentSettings(BaseSettings)` |
| AgentState | src/ssi/models/states.py | `class AgentState(StrEnum)` |
| AgentStep | src/ssi/models/agent.py | `class AgentStep` |
| AllowlistFilter | src/ssi/wallet/allowlist.py | `class AllowlistFilter` |
| AutoSkipGuidance | src/ssi/browser/agent_controller.py | `class AutoSkipGuidance` |
| BatchInvestigateRequest | src/ssi/api/investigation_routes.py | `class BatchInvestigateRequest(BaseModel)` |
| BatchInvestigateResponse | src/ssi/api/investigation_routes.py | `class BatchInvestigateResponse(BaseModel)` |
| BlocklistRecord | src/ssi/osint/blocklist_aggregator.py | `class BlocklistRecord` |
| BrandSeries | src/ssi/api/ecx_routes.py | `class BrandSeries(BaseModel)` |
| BrandSeriesResponse | src/ssi/api/ecx_routes.py | `class BrandSeriesResponse(BaseModel)` |
| BrowserAgent | src/ssi/browser/agent.py | `class BrowserAgent` |
| BrowserProfile | src/ssi/browser/stealth.py | `class BrowserProfile` |
| BrowserSettings | src/ssi/settings/config.py | `class BrowserSettings(BaseSettings)` |
| BudgetExceededError | src/ssi/exceptions.py | `class BudgetExceededError(SSIError)` |
| CTLogEntry | src/ssi/osint/ctlog_lookup.py | `class CTLogEntry` |
| CampaignCorrelator | src/ssi/ecx/correlation.py | `class CampaignCorrelator` |
| CaptchaDetection | src/ssi/browser/captcha.py | `class CaptchaDetection` |
| CaptchaResult | src/ssi/browser/captcha.py | `class CaptchaResult` |
| CaptchaSettings | src/ssi/settings/config.py | `class CaptchaSettings(BaseSettings)` |
| CaptchaStrategy | src/ssi/browser/captcha.py | `class CaptchaStrategy(StrEnum)` |
| CaptchaType | src/ssi/browser/captcha.py | `class CaptchaType(StrEnum)` |
| CapturedDownload | src/ssi/browser/downloads.py | `class CapturedDownload` |
| CascadeDecision | src/ssi/browser/decision_cascade.py | `class CascadeDecision` |
| CascadeTier | src/ssi/browser/decision_cascade.py | `class CascadeTier(enum.StrEnum)` |
| ChainOfCustody | src/ssi/models/investigation.py | `class ChainOfCustody(BaseModel)` |
| CheckEmailDetector | src/ssi/browser/dom_inspector.py | `class CheckEmailDetector` |
| ConcurrentLimitError | src/ssi/exceptions.py | `class ConcurrentLimitError(SSIError)` |
| CostLineItem | src/ssi/monitoring/__init__.py | `class CostLineItem` |
| CostSettings | src/ssi/settings/config.py | `class CostSettings(BaseSettings)` |
| CostSummary | src/ssi/monitoring/__init__.py | `class CostSummary(BaseModel)` |
| CostTracker | src/ssi/monitoring/__init__.py | `class CostTracker` |
| CurrencyBreakdownEntry | src/ssi/api/ecx_routes.py | `class CurrencyBreakdownEntry(BaseModel)` |
| DNSRecords | src/ssi/models/investigation.py | `class DNSRecords(BaseModel)` |
| DOMInspection | src/ssi/browser/dom_inspector.py | `class DOMInspection` |
| DOMInspector | src/ssi/browser/dom_inspector.py | `class DOMInspector` |
| DOMSignal | src/ssi/browser/dom_inspector.py | `class DOMSignal` |
| DomainDiscovery | src/ssi/osint/merklemap_client.py | `class DomainDiscovery` |
| DownloadArtifact | src/ssi/models/investigation.py | `class DownloadArtifact(BaseModel)` |
| DownloadInterceptor | src/ssi/browser/downloads.py | `class DownloadInterceptor` |
| ECXApproveRequest | src/ssi/models/ecx.py | `class ECXApproveRequest(BaseModel)` |
| ECXClient | src/ssi/osint/ecrimex.py | `class ECXClient` |
| ... | ... | ... and 270 more entries collapsed |

## Data Models
| Model | File | Fields |
| :--- | :--- | :--- |
| APISettings | src/ssi/settings/config.py | `host: str, port: int, cors_origins: list[str], rate_limit_per_minute: int, max_concurrent_inves...` |
| AgentAction | src/ssi/models/action.py | `action: ActionType, selector: str, value: str, reasoning: str, confidence: float` |
| AgentSettings | src/ssi/settings/config.py | `stuck_threshold_default: int, stuck_threshold_load_site: int, stuck_threshold_find_register: in...` |
| BatchInvestigateRequest | src/ssi/api/investigation_routes.py | `manifest: list[dict[str, Any]] | None, manifest_uri: str | None, default_scan_type: Literal['pa...` |
| BatchInvestigateResponse | src/ssi/api/investigation_routes.py | `status: str, entry_count: int` |
| BrandSeries | src/ssi/api/ecx_routes.py | `brand: str, date: str, count: int` |
| BrandSeriesResponse | src/ssi/api/ecx_routes.py | `series: list[BrandSeries]` |
| BrowserSettings | src/ssi/settings/config.py | `headless: bool, timeout_ms: int, user_agent: str, proxy: str, record_har: bool, record_video: b...` |
| CaptchaSettings | src/ssi/settings/config.py | `strategy: str, solver_api_key: str, wait_seconds: int, screenshot_on_detect: bool` |
| ChainOfCustody | src/ssi/models/investigation.py | `investigation_id: str, target_url: str, collected_at: str, collected_by: str, collection_method...` |
| CostSettings | src/ssi/settings/config.py | `budget_per_investigation_usd: float, warn_at_pct: int, enabled: bool` |
| CostSummary | src/ssi/monitoring/__init__.py | `total_usd: float, llm_usd: float, api_usd: float, compute_usd: float, budget_usd: float, budget...` |
| CurrencyBreakdownEntry | src/ssi/api/ecx_routes.py | `token_symbol: str, count: int` |
| DNSRecords | src/ssi/models/investigation.py | `a: list[str], aaaa: list[str], mx: list[str], txt: list[str], ns: list[str], cname: list[str]` |
| DownloadArtifact | src/ssi/models/investigation.py | `url: str, filename: str, saved_path: str, sha256: str, md5: str, size_bytes: int, content_type:...` |
| ECXApproveRequest | src/ssi/models/ecx.py | `release_label: str, analyst: str` |
| ECXCryptoRecord | src/ssi/models/ecx.py | `id: int, currency: str, address: str, crime_category: str, site_link: str, price: int, source: ...` |
| ECXEnrichmentCacheResponse | src/ssi/api/ecx_routes.py | `scan_id: str, count: int, enrichments: list[dict[str, Any]]` |
| ECXEnrichmentResult | src/ssi/models/ecx.py | `phish_hits: list[ECXPhishRecord], domain_hits: list[ECXMalDomainRecord], ip_hits: list[ECXMalIP...` |
| ECXFeedResponse | src/ssi/api/ecx_routes.py | `module: str, count: int, records: list[dict[str, Any]]` |
| ECXMalDomainRecord | src/ssi/models/ecx.py | `id: int, domain: str, classification: str, confidence: int, status: str, discovered_at: int | N...` |
| ECXMalIPRecord | src/ssi/models/ecx.py | `id: int, ip: str, brand: str, description: str, confidence: int, status: str, asn: list[int], p...` |
| ECXPhishRecord | src/ssi/models/ecx.py | `id: int, url: str, brand: str, confidence: int, status: str, discovered_at: int | None, created...` |
| ECXPollingStatusResponse | src/ssi/api/ecx_routes.py | `modules: list[dict[str, Any]]` |
| ECXRejectRequest | src/ssi/models/ecx.py | `analyst: str, reason: str` |
| ECXSearchRequest | src/ssi/api/ecx_routes.py | `query: str, limit: int` |
| ECXSearchResponse | src/ssi/api/ecx_routes.py | `module: str, query: str, count: int, results: list[dict[str, Any]]` |
| ECXSettings | src/ssi/settings/config.py | `enabled: bool, api_key: str, base_url: str, attribution: str, timeout: int, enrichment_enabled:...` |
| ECXSubmissionListResponse | src/ssi/api/ecx_routes.py | `count: int, submissions: list[dict[str, Any]]` |
| ECXSubmissionRecord | src/ssi/models/ecx.py | `submission_id: str, ecx_module: str, ecx_record_id: int | None, case_id: str, scan_id: str, sub...` |
| ECXSubmissionResponse | src/ssi/models/ecx.py | `submission_id: str, ecx_module: str, ecx_record_id: int | None, scan_id: str, submitted_value: ...` |
| EmailSecurityPosture | src/ssi/providers/sec_gemini/models.py | `domain: str, spf_record: str | None, spf_valid: bool, dkim_configured: bool, dmarc_record: str ...` |
| Event | src/ssi/monitoring/event_bus.py | `event_type: EventType, timestamp: str, investigation_id: str, data: dict[str, Any]` |
| EvidenceArtifact | src/ssi/models/investigation.py | `file: str, sha256: str, size_bytes: int, description: str, mime_type: str` |
| EvidenceSettings | src/ssi/settings/config.py | `output_dir: str, storage_backend: str, gcs_bucket: str, gcs_prefix: str, retain_days: int` |
| FeedbackRecord | src/ssi/feedback/__init__.py | `feedback_id: str, investigation_id: str, outcome: OutcomeType, notes: str, lea_partner: str, ca...` |
| FeedbackSettings | src/ssi/settings/config.py | `db_path: str, enabled: bool` |
| FeedbackStats | src/ssi/feedback/__init__.py | `total_investigations: int, total_feedback: int, outcomes: dict[str, int], prosecution_rate: flo...` |
| FormField | src/ssi/models/investigation.py | `tag: str, field_type: str, name: str, label: str, placeholder: str, required: bool, pii_categor...` |
| FraudTaxonomyResult | src/ssi/models/investigation.py | `intent: list[TaxonomyScoredLabel], channel: list[TaxonomyScoredLabel], techniques: list[Taxonom...` |
| GeoEntry | src/ssi/api/ecx_routes.py | `country: str, count: int` |
| GeoIPInfo | src/ssi/models/investigation.py | `ip: str, hostname: str, city: str, region: str, country: str, loc: str, org: str, asn: str, as_...` |
| GeoInfrastructureResponse | src/ssi/api/ecx_routes.py | `distribution: list[GeoEntry]` |
| GuidanceCommand | src/ssi/monitoring/event_bus.py | `action: GuidanceAction, value: str, reason: str` |
| IdentityVaultSettings | src/ssi/settings/config.py | `default_locale: str, db_url: str, rotate_per_session: bool` |
| InfraFingerprint | src/ssi/providers/sec_gemini/models.py | `web_server: str | None, framework: str | None, cms: str | None, hosting_provider: str | None, c...` |
| IntegrationSettings | src/ssi/settings/config.py | `core_api_url: str, core_api_key: str, iap_audience: str, push_to_core: bool, trigger_dossier: b...` |
| InvestigateRequest | src/ssi/api/investigation_routes.py | `url: str, scan_type: Literal['passive', 'active', 'full'], scan_id: str | None, push_to_core: b...` |
| InvestigateRequest | src/ssi/api/routes.py | `url: str, scan_type: str, passive_only: bool | None, skip_whois: bool, skip_screenshot: bool, s...` |
| InvestigateResponse | src/ssi/api/investigation_routes.py | `scan_id: str | None, status: str, already_investigated: bool, existing_scan_id: str | None, exi...` |
| ... | ... | ... and 38 more entries collapsed |

## Routes
| Method | Path | Handler | File |
| :--- | :--- | :--- | :--- |
| DELETE | /{playbook_id} | delete_playbook | src/ssi/api/playbook_routes.py |
| GET | / | index | src/ssi/api/web.py |
| GET | /feed | get_feed | src/ssi/api/ecx_routes.py |
| GET | /health | health | src/ssi/api/routes.py |
| GET | /investigate/{investigation_id} | get_investigation_status | src/ssi/api/routes.py |
| GET | /investigate/{scan_id} | get_investigation_ecx | src/ssi/api/ecx_routes.py |
| GET | /investigations | list_investigations | src/ssi/api/investigation_routes.py |
| GET | /investigations/active | list_active_investigations_endpoint | src/ssi/api/investigation_routes.py |
| GET | /investigations/{scan_id} | get_investigation | src/ssi/api/investigation_routes.py |
| GET | /investigations/{scan_id}/evidence-bundle | download_evidence_bundle | src/ssi/api/investigation_routes.py |
| GET | /investigations/{scan_id}/lea-package | download_lea_package | src/ssi/api/investigation_routes.py |
| GET | /investigations/{scan_id}/wallets.csv | export_wallets_csv | src/ssi/api/investigation_routes.py |
| GET | /investigations/{scan_id}/wallets.xlsx | export_wallets_xlsx | src/ssi/api/investigation_routes.py |
| GET | /polling-status | get_polling_status | src/ssi/api/ecx_routes.py |
| GET | /report/{task_id}/pdf | download_pdf | src/ssi/api/web.py |
| GET | /stats/geo-infrastructure | stats_geo_infrastructure | src/ssi/api/ecx_routes.py |
| GET | /stats/phish-by-brand | stats_phish_by_brand | src/ssi/api/ecx_routes.py |
| GET | /stats/wallet-heatmap | stats_wallet_heatmap | src/ssi/api/ecx_routes.py |
| GET | /status/{task_id} | investigation_status | src/ssi/api/web.py |
| GET | /submissions | list_submissions | src/ssi/api/ecx_routes.py |
| GET | /wallets | search_wallets | src/ssi/api/investigation_routes.py |
| GET | /{playbook_id} | get_playbook | src/ssi/api/playbook_routes.py |
| POST | /investigate | submit_investigation | src/ssi/api/routes.py |
| POST | /search/crypto | search_crypto | src/ssi/api/ecx_routes.py |
| POST | /search/domain | search_domain | src/ssi/api/ecx_routes.py |
| POST | /search/ip | search_ip | src/ssi/api/ecx_routes.py |
| POST | /search/phish | search_phish | src/ssi/api/ecx_routes.py |
| POST | /submissions/{submission_id}/approve | approve_submission | src/ssi/api/ecx_routes.py |
| POST | /submissions/{submission_id}/reject | reject_submission | src/ssi/api/ecx_routes.py |
| POST | /submissions/{submission_id}/retract | retract_submission | src/ssi/api/ecx_routes.py |
| POST | /submit | submit_investigation | src/ssi/api/web.py |
| POST | /test-match | test_match | src/ssi/api/playbook_routes.py |
| POST | /trigger/batch | trigger_batch_investigate | src/ssi/api/investigation_routes.py |
| POST | /trigger/investigate | trigger_investigate | src/ssi/api/investigation_routes.py |
| PUT | /{playbook_id} | update_playbook | src/ssi/api/playbook_routes.py |

## Config
| Variable | File | Context |
| :--- | :--- | :--- |
| SSI_AGENT__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_AGENT__DOM_DIRECT_THRESHOLD | src/ssi/browser/dom_inspector.py | Environment variable reference |
| SSI_API__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_BROWSER__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_BROWSER__CAPTCHA_SOLVER | src/ssi/browser/captcha.py | Environment variable reference |
| SSI_BROWSER__CAPTCHA_SOLVER_KEY | src/ssi/browser/captcha.py | Environment variable reference |
| SSI_CAPTCHA__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_COST__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_ECX__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_ECX__API_KEY | src/ssi/cli/ecx_cmd.py | Environment variable reference |
| SSI_ECX__BASE_URL | src/ssi/settings/config.py | Environment variable reference |
| SSI_ECX__ENABLED | src/ssi/cli/ecx_cmd.py | Environment variable reference |
| SSI_ECX__POLLING_ENABLED | src/ssi/cli/ecx_cmd.py | Environment variable reference |
| SSI_ECX__SUBMISSION_AGREEMENT_SIGNED | src/ssi/cli/ecx_cmd.py | Environment variable reference |
| SSI_ECX__SUBMISSION_AGREEMENT_SIGNED | src/ssi/ecx/submission.py | Environment variable reference |
| SSI_ECX__SUBMISSION_ENABLED | src/ssi/cli/ecx_cmd.py | Environment variable reference |
| SSI_ECX__SUBMISSION_ENABLED | src/ssi/ecx/submission.py | Environment variable reference |
| SSI_ENV | src/ssi/settings/config.py | Environment variable reference |
| SSI_EVIDENCE__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_EVIDENCE__GCS_BUCKET | src/ssi/investigator/orchestrator.py | Environment variable reference |
| SSI_FEEDBACK__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_IDENTITY__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_INTEGRATION__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_LLM__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_LLM__PROVIDER | src/ssi/llm/gemini_provider.py | Environment variable reference |
| SSI_MONITORING__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_OSINT__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_OSINT__VIRUSTOTAL_API_KEY | src/ssi/browser/downloads.py | Environment variable reference |
| SSI_OSINT__VIRUSTOTAL_API_KEY | src/ssi/osint/virustotal.py | Environment variable reference |
| SSI_PHISHDESTROY__ | src/ssi/osint/__init__.py | Environment variable reference |
| SSI_PHISHDESTROY__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_PLAYBOOK__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_PROJECT_ROOT | src/ssi/settings/config.py | Environment variable reference |
| SSI_PROVIDERS__ | src/ssi/providers/gate.py | Environment variable reference |
| SSI_PROVIDERS__MERKLEMAP__ | src/ssi/providers/gate.py | Environment variable reference |
| SSI_PROVIDERS__MERKLEMAP__API_KEY | src/ssi/osint/merklemap_client.py | Environment variable reference |
| SSI_PROVIDERS__MERKLEMAP__ENABLED | src/ssi/osint/merklemap_client.py | Environment variable reference |
| SSI_PROXY__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_SEC_GEMINI__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_SEC_GEMINI__API_KEY | src/ssi/settings/config.py | Environment variable reference |
| SSI_SEC_GEMINI__ENABLED | src/ssi/providers/sec_gemini/__init__.py | Environment variable reference |
| SSI_STEALTH__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_STORAGE__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_STORAGE__CLOUDSQL_ | src/ssi/store/sql.py | Environment variable reference |
| SSI_STORAGE__CLOUDSQL_DATABASE | src/ssi/store/sql.py | Environment variable reference |
| SSI_STORAGE__CLOUDSQL_INSTANCE | src/ssi/store/sql.py | Environment variable reference |
| SSI_STORAGE__CLOUDSQL_USER | src/ssi/store/sql.py | Environment variable reference |
| SSI_TASK_STORE__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_WALLET__ALLOWLIST_PATH | src/ssi/wallet/allowlist.py | Environment variable reference |
| SSI_ZEN_BROWSER__ | src/ssi/settings/config.py | Environment variable reference |
| ... | ... | ... and 162 more entries collapsed |
