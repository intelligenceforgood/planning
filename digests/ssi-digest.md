# SSI Digest
Generated: 2026-06-14T03:15:27.483424Z

## Public API
| Function/Class | File | Signature |
|:---|:---|:---|
| SSIError | src/ssi/exceptions.py | `class SSIError(Exception)` |
| BudgetExceededError | src/ssi/exceptions.py | `class BudgetExceededError(SSIError)` |
| ConcurrentLimitError | src/ssi/exceptions.py | `class ConcurrentLimitError(SSIError)` |
| NavigationError | src/ssi/exceptions.py | `class NavigationError(SSIError)` |
| get_display_label | src/ssi/classification/labels.py | `def get_display_label(code: str) -> str` |
| ScoredLabel | src/ssi/classification/classifier.py | `class ScoredLabel` |
| FraudTaxonomyResult | src/ssi/classification/classifier.py | `class FraudTaxonomyResult` |
| classify_investigation | src/ssi/classification/classifier.py | `def classify_investigation(result: InvestigationResult) -> FraudTaxonomyResult` |
| get_settings | src/ssi/settings/config.py | `def get_settings() -> Settings` |
| PlaybookMatcher | src/ssi/playbook/matcher.py | `class PlaybookMatcher` |
| PlaybookStepType | src/ssi/playbook/models.py | `class PlaybookStepType(StrEnum)` |
| load_playbook_from_file | src/ssi/playbook/loader.py | `def load_playbook_from_file(path: Path) -> Playbook` |
| load_playbooks_from_dir | src/ssi/playbook/loader.py | `def load_playbooks_from_dir(directory: Path | str) -> list[Playbook]` |
| resolve_template | src/ssi/playbook/executor.py | `def resolve_template(template: str, identity: SyntheticIdentity) -> str` |
| PlaybookExecutor | src/ssi/playbook/executor.py | `class PlaybookExecutor` |
| create_llm_provider | src/ssi/llm/factory.py | `def create_llm_provider(provider: str | None) -> LLMProvider` |
| RetryingLLMProvider | src/ssi/llm/retry.py | `class RetryingLLMProvider(LLMProvider)` |
| OllamaProvider | src/ssi/llm/ollama_provider.py | `class OllamaProvider(LLMProvider)` |
| GeminiProvider | src/ssi/llm/gemini_provider.py | `class GeminiProvider(LLMProvider)` |
| LLMResult | src/ssi/llm/base.py | `class LLMResult` |
| LLMProvider | src/ssi/llm/base.py | `class LLMProvider(ABC)` |
| EvidenceStorageClient | src/ssi/evidence/storage.py | `class EvidenceStorageClient` |
| build_evidence_storage_client | src/ssi/evidence/storage.py | `def build_evidence_storage_client() -> EvidenceStorageClient` |
| route_google_osint_results | src/ssi/evidence/mapping.py | `def route_google_osint_results(osint_result: GoogleOSINTResult) -> tuple[list[ThreatIndicator], list[PiiExposure]]` |
| investigation_to_stix_bundle | src/ssi/evidence/stix.py | `def investigation_to_stix_bundle(result: InvestigationResult) -> dict[str, Any]` |
| SyntheticIdentity | src/ssi/identity/vault.py | `class SyntheticIdentity` |
| IdentityVault | src/ssi/identity/vault.py | `class IdentityVault` |
| SkippedResult | src/ssi/providers/gate.py | `class SkippedResult` |
| ProviderGate | src/ssi/providers/gate.py | `class ProviderGate` |
| SecGeminiProvider | src/ssi/providers/sec_gemini/provider.py | `class SecGeminiProvider` |
| build_investigation_prompt | src/ssi/providers/sec_gemini/prompts.py | `def build_investigation_prompt(url: str, existing_osint: dict[str, Any]) -> str` |
| parse_sec_gemini_response | src/ssi/providers/sec_gemini/parser.py | `def parse_sec_gemini_response(raw_response: str) -> SecGeminiAnalysis` |
| normalize_url | src/ssi/utils/url_normalization.py | `def normalize_url(url: str) -> str` |
| SiteStatus | src/ssi/models/results.py | `class SiteStatus(StrEnum)` |
| SiteResult | src/ssi/models/results.py | `class SiteResult` |
| ActionType | src/ssi/models/action.py | `class ActionType(StrEnum)` |
| ActionType | src/ssi/models/agent.py | `class ActionType(StrEnum)` |
| InteractiveElement | src/ssi/models/agent.py | `class InteractiveElement` |
| PageObservation | src/ssi/models/agent.py | `class PageObservation` |
| AgentAction | src/ssi/models/agent.py | `class AgentAction` |
| AgentStep | src/ssi/models/agent.py | `class AgentStep` |
| AgentMetrics | src/ssi/models/agent.py | `class AgentMetrics` |
| AgentSession | src/ssi/models/agent.py | `class AgentSession` |
| ScanType | src/ssi/models/investigation.py | `class ScanType(StrEnum)` |
| InvestigationStatus | src/ssi/models/investigation.py | `class InvestigationStatus(StrEnum)` |
| AgentState | src/ssi/models/states.py | `class AgentState(StrEnum)` |
| job_investigate | src/ssi/cli/job.py | `def job_investigate(url: str, scan_type: str, passive_only: bool, push_to_core: bool, dataset: str) -> None` |
| job_batch | src/ssi/cli/job.py | `def job_batch(manifest: str, scan_type: str, push_to_core: bool, dataset: str) -> None` |
| playbook_list | src/ssi/cli/playbook_cmd.py | `def playbook_list(json_output: bool, directory: Path | None) -> None` |
| playbook_show | src/ssi/cli/playbook_cmd.py | `def playbook_show(playbook_id: str, directory: Path | None, json_output: bool) -> None` |
| ... | ... | `... and 186 more entries collapsed` |

## Data Models
| Model | File | Fields |
|:---|:---|:---|
| PlaybookStep | src/ssi/playbook/models.py | `action: PlaybookStepType, selector: str, value: str, description: str, retry_on_failure: int, fal...` |
| Playbook | src/ssi/playbook/models.py | `playbook_id: str, url_pattern: str, description: str, steps: list[PlaybookStep], fallback_to_llm:...` |
| PlaybookStepResult | src/ssi/playbook/models.py | `step_index: int, action: PlaybookStepType, selector: str, value: str, success: bool, attempts: in...` |
| PlaybookResult | src/ssi/playbook/models.py | `playbook_id: str, url: str, success: bool, completed_steps: int, total_steps: int, step_results: ...` |
| EmailSecurityPosture | src/ssi/providers/sec_gemini/models.py | `domain: str, spf_record: str | None, spf_valid: bool, dkim_configured: bool, dmarc_record: str | ...` |
| VulnerabilityFinding | src/ssi/providers/sec_gemini/models.py | `cve_id: str, software: str, severity: str, cvss_score: float | None, is_exploited: bool, patch_av...` |
| InfraFingerprint | src/ssi/providers/sec_gemini/models.py | `web_server: str | None, framework: str | None, cms: str | None, hosting_provider: str | None, cdn...` |
| SecGeminiAnalysis | src/ssi/providers/sec_gemini/models.py | `email_security: list[EmailSecurityPosture], infrastructure: InfraFingerprint | None, threat_synth...` |
| AgentAction | src/ssi/models/action.py | `action: ActionType, selector: str, value: str, reasoning: str, confidence: float` |
| ECXPhishRecord | src/ssi/models/ecx.py | `id: int, url: str, brand: str, confidence: int, status: str, discovered_at: int | None, created_a...` |
| ECXCryptoRecord | src/ssi/models/ecx.py | `id: int, currency: str, address: str, crime_category: str, site_link: str, price: int, source: st...` |
| ECXMalDomainRecord | src/ssi/models/ecx.py | `id: int, domain: str, classification: str, confidence: int, status: str, discovered_at: int | Non...` |
| ECXMalIPRecord | src/ssi/models/ecx.py | `id: int, ip: str, brand: str, description: str, confidence: int, status: str, asn: list[int], por...` |
| ECXEnrichmentResult | src/ssi/models/ecx.py | `phish_hits: list[ECXPhishRecord], domain_hits: list[ECXMalDomainRecord], ip_hits: list[ECXMalIPRe...` |
| ECXSubmissionRecord | src/ssi/models/ecx.py | `submission_id: str, ecx_module: str, ecx_record_id: int | None, case_id: str, scan_id: str, submi...` |
| ECXApproveRequest | src/ssi/models/ecx.py | `release_label: str, analyst: str` |
| ECXRejectRequest | src/ssi/models/ecx.py | `analyst: str, reason: str` |
| ECXSubmissionResponse | src/ssi/models/ecx.py | `submission_id: str, ecx_module: str, ecx_record_id: int | None, scan_id: str, submitted_value: st...` |
| TaxonomyScoredLabel | src/ssi/models/investigation.py | `label: str, confidence: float, explanation: str` |
| FraudTaxonomyResult | src/ssi/models/investigation.py | `intent: list[TaxonomyScoredLabel], channel: list[TaxonomyScoredLabel], techniques: list[TaxonomyS...` |
| ScamClassification | src/ssi/models/investigation.py | `scam_type: str, confidence: float, intent: str, channel: str, technique: str, action: str, person...` |
| WHOISRecord | src/ssi/models/investigation.py | `domain: str, registrar: str, creation_date: str, expiration_date: str, updated_date: str, registr...` |
| DNSRecords | src/ssi/models/investigation.py | `a: list[str], aaaa: list[str], mx: list[str], txt: list[str], ns: list[str], cname: list[str]` |
| SSLInfo | src/ssi/models/investigation.py | `issuer: str, subject: str, serial_number: str, not_before: str, not_after: str, san: list[str], f...` |
| GeoIPInfo | src/ssi/models/investigation.py | `ip: str, hostname: str, city: str, region: str, country: str, loc: str, org: str, asn: str, as_na...` |
| FormField | src/ssi/models/investigation.py | `tag: str, field_type: str, name: str, label: str, placeholder: str, required: bool, pii_category:...` |
| PiiExposure | src/ssi/models/investigation.py | `field_type: str, field_label: str, form_action: str, page_url: str, is_required: bool, was_submit...` |
| PageSnapshot | src/ssi/models/investigation.py | `url: str, final_url: str, status_code: int, title: str, screenshot_path: str, dom_snapshot_path: ...` |
| ThreatIndicator | src/ssi/models/investigation.py | `indicator_type: str, value: str, context: str, source: str` |
| DownloadArtifact | src/ssi/models/investigation.py | `url: str, filename: str, saved_path: str, sha256: str, md5: str, size_bytes: int, content_type: s...` |
| EvidenceArtifact | src/ssi/models/investigation.py | `file: str, sha256: str, size_bytes: int, description: str, mime_type: str` |
| ChainOfCustody | src/ssi/models/investigation.py | `investigation_id: str, target_url: str, collected_at: str, collected_by: str, collection_method: ...` |
| InvestigationResult | src/ssi/models/investigation.py | `investigation_id: UUID, url: str, started_at: datetime, completed_at: datetime | None, status: In...` |
| FeedbackRecord | src/ssi/feedback/__init__.py | `feedback_id: str, investigation_id: str, outcome: OutcomeType, notes: str, lea_partner: str, case...` |
| FeedbackStats | src/ssi/feedback/__init__.py | `total_investigations: int, total_feedback: int, outcomes: dict[str, int], prosecution_rate: float...` |
| PersonProfile | src/ssi/osint/google/models.py | `account_id: str, email: str, display_name: str, profile_photo_url: str, cover_photo_url: str, is_...` |
| MapContributionStats | src/ssi/osint/google/models.py | `account_id: str, reviews: int, ratings: int, photos: int, profile_url: str` |
| DriveFileInfo | src/ssi/osint/google/models.py | `file_id: str, title: str, mime_type: str, owner_email: str, owner_account_id: str, created_date: ...` |
| GoogleOSINTResult | src/ssi/osint/google/models.py | `profiles: list[PersonProfile], map_stats: list[MapContributionStats], drive_files: list[DriveFile...` |
| TokenNetwork | src/ssi/wallet/models.py | `token_name: str, token_symbol: str, network: str, network_short: str` |
| WalletEntry | src/ssi/wallet/models.py | `site_url: str, token_label: str, token_symbol: str, network_label: str, network_short: str, walle...` |
| WalletHarvest | src/ssi/wallet/models.py | `site_url: str, site_id: str, run_id: str, entries: list[WalletEntry], started_at: datetime, compl...` |
| ECXSearchRequest | src/ssi/api/ecx_routes.py | `query: str, limit: int` |
| ECXSearchResponse | src/ssi/api/ecx_routes.py | `module: str, query: str, count: int, results: list[dict[str, Any]]` |
| ECXEnrichmentCacheResponse | src/ssi/api/ecx_routes.py | `scan_id: str, count: int, enrichments: list[dict[str, Any]]` |
| ECXSubmissionListResponse | src/ssi/api/ecx_routes.py | `count: int, submissions: list[dict[str, Any]]` |
| ECXFeedResponse | src/ssi/api/ecx_routes.py | `module: str, count: int, records: list[dict[str, Any]]` |
| ECXPollingStatusResponse | src/ssi/api/ecx_routes.py | `modules: list[dict[str, Any]]` |
| BrandSeries | src/ssi/api/ecx_routes.py | `brand: str, date: str, count: int` |
| BrandSeriesResponse | src/ssi/api/ecx_routes.py | `series: list[BrandSeries]` |
| ... | ... | `... and 18 more entries collapsed` |

## Routes
| Method | Path | Handler | File |
|:---|:---|:---|:---|
| GET | /health | health | src/ssi/api/routes.py |
| POST | /investigate | submit_investigation | src/ssi/api/routes.py |
| GET | /investigate/{investigation_id} | get_investigation_status | src/ssi/api/routes.py |

## Config
| Variable | File | Context |
|:---|:---|:---|
| SSI_ENV | src/ssi/settings/config.py | Environment variable reference |
| SSI_PROJECT_ROOT | src/ssi/settings/config.py | Environment variable reference |
| SSI_LLM__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_BROWSER__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_OSINT__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_EVIDENCE__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_IDENTITY__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_STEALTH__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_CAPTCHA__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_ZEN_BROWSER__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_PROXY__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_AGENT__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_COST__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_STORAGE__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_FEEDBACK__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_API__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_PLAYBOOK__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_MONITORING__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_INTEGRATION__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_ECX__BASE_URL | src/ssi/settings/config.py | Environment variable reference |
| SSI_ECX__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_TASK_STORE__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_SEC_GEMINI__API_KEY | src/ssi/settings/config.py | Environment variable reference |
| SSI_SEC_GEMINI__ | src/ssi/settings/config.py | Environment variable reference |
| SSI_PHISHDESTROY__ | src/ssi/settings/config.py | Environment variable reference |
| provider | src/ssi/settings/config.py | Settings field in LLMSettings |
| model | src/ssi/settings/config.py | Settings field in LLMSettings |
| cheap_model | src/ssi/settings/config.py | Settings field in LLMSettings |
| vision_model | src/ssi/settings/config.py | Settings field in LLMSettings |
| ollama_base_url | src/ssi/settings/config.py | Settings field in LLMSettings |
| temperature | src/ssi/settings/config.py | Settings field in LLMSettings |
| max_tokens | src/ssi/settings/config.py | Settings field in LLMSettings |
| token_budget_per_session | src/ssi/settings/config.py | Settings field in LLMSettings |
| gcp_project | src/ssi/settings/config.py | Settings field in LLMSettings |
| gcp_location | src/ssi/settings/config.py | Settings field in LLMSettings |
| gemini_api_key | src/ssi/settings/config.py | Settings field in LLMSettings |
| headless | src/ssi/settings/config.py | Settings field in BrowserSettings |
| timeout_ms | src/ssi/settings/config.py | Settings field in BrowserSettings |
| user_agent | src/ssi/settings/config.py | Settings field in BrowserSettings |
| proxy | src/ssi/settings/config.py | Settings field in BrowserSettings |
| record_har | src/ssi/settings/config.py | Settings field in BrowserSettings |
| record_video | src/ssi/settings/config.py | Settings field in BrowserSettings |
| sandbox | src/ssi/settings/config.py | Settings field in BrowserSettings |
| virustotal_api_key | src/ssi/settings/config.py | Settings field in OSINTSettings |
| urlscan_api_key | src/ssi/settings/config.py | Settings field in OSINTSettings |
| ipinfo_token | src/ssi/settings/config.py | Settings field in OSINTSettings |
| maxmind_license_key | src/ssi/settings/config.py | Settings field in OSINTSettings |
| whois_timeout_sec | src/ssi/settings/config.py | Settings field in OSINTSettings |
| dns_timeout_sec | src/ssi/settings/config.py | Settings field in OSINTSettings |
| output_dir | src/ssi/settings/config.py | Settings field in EvidenceSettings |
| ... | ... | ... and 162 more entries collapsed |
