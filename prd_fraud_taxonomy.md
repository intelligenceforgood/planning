# Online Fraud Classification & Intelligence System (PRD)

**Primary Use:** Victim-submitted content (chat, SMS, email, social posts) → probabilistic fraud classification → intelligence enrichment

## 1. Purpose & Goals

### 1.1 Purpose
Design and implement a **comprehensive, extensible, and explainable fraud taxonomy** to support automated classification of suspicious communications submitted by potential fraud victims.

The taxonomy must:
- Support **multi-label, probabilistic classification**
- Reflect **real-world scam evolution**
- Be understandable to **non-technical users**
- Integrate cleanly with **LLM + rules + signals** pipelines

### 1.2 Non-Goals
- Attribution to specific threat actors
- Legal determination of fraud
- Final victim remediation workflows (handled elsewhere)

---

## 2. Design Principles

1. **Multi-Axis Classification**  
   A single label is insufficient; scams combine multiple intents and techniques.

2. **Victim-Centric Language**  
   User-facing labels should align with how victims understand scams.

3. **Machine-Friendly Internals**  
   Internal tags should be structured, versioned, and composable.

4. **Explainability First**  
   Every classification should be explainable in plain language.

5. **Evolution Over Time**  
   Taxonomy must be versioned and allow new scam types without breaking models.

---

## 3. High-Level System Flow (Context)

1. User submits suspicious content
2. Content normalization (OCR, text extraction, language detection)
3. Classification engine assigns **probabilistic tags across multiple axes**
4. Intelligence layer enriches results (history, trends, known patterns)
5. Results returned to user and downstream systems

---

## 4. Taxonomy Architecture (Core Design)

> **Technical Detail:** For the full technical specification, schema, and storage strategy, see the [Technical Design Document (TDD)](../../core/docs/design/fraud_taxonomy_tdd.md).

The system uses **five primary classification axes**. Each axis is independently scored.

```
Submission
 ├─ Scam Intent (What is the fraud?)
 ├─ Delivery Channel (How was it delivered?)
 ├─ Social Engineering Technique (How are they manipulating?)
 ├─ Requested Action (What do they want the victim to do?)
 └─ Claimed Persona (Who are they pretending to be?)
```

Each axis returns **0..N labels**, each with a confidence score.

---

## 5. Axis Definitions & Initial Taxonomy

### 5.1 Axis A — Scam Intent (Primary Fraud Type)

**User-visible | FTC-aligned**

| Code | Label | Description |
|----|------|------------|
| INTENT.IMPOSTER | Imposter Scam | Pretending to be a trusted entity |
| INTENT.INVESTMENT | Investment Scam | Promises of financial returns |
| INTENT.ROMANCE | Romance Scam | Emotional relationship for fraud |
| INTENT.EMPLOYMENT | Job Scam | Fake job or task-based fraud |
| INTENT.SHOPPING | Online Shopping Scam | Fake goods or sellers |
| INTENT.TECH_SUPPORT | Tech Support Scam | Fake tech assistance |
| INTENT.PRIZE | Prize / Lottery Scam | Fake winnings |
| INTENT.EXTORTION | Extortion / Blackmail | Threat-based coercion |
| INTENT.CHARITY | Charity Scam | Fake disaster or cause appeals |

**Notes:**
- Multiple intents may coexist (e.g., Romance + Investment).
- Intent labels are **never mutually exclusive**.

---

### 5.2 Axis B — Delivery Channel

| Code | Label |
|----|------|
| CHANNEL.EMAIL | Email |
| CHANNEL.SMS | SMS / Smishing |
| CHANNEL.CHAT | Messaging App |
| CHANNEL.SOCIAL | Social Media |
| CHANNEL.PHONE | Phone / Vishing |
| CHANNEL.WEB | Website / Landing Page |

---

### 5.3 Axis C — Social Engineering Techniques

**Internal + explainable to users**

| Code | Technique | Indicators |
|----|----------|-----------|
| SE.URGENCY | Urgency | Time pressure, deadlines |
| SE.AUTHORITY | Authority | Government, bank, employer tone |
| SE.SCARCITY | Scarcity | Limited availability |
| SE.FEAR | Fear | Threats, loss, legal trouble |
| SE.RECIPROCITY | Reciprocity | Gifts, favors |
| SE.TRUST_BUILDING | Grooming | Long-term rapport |
| SE.CONFUSION | Complexity | Overwhelming steps |

---

### 5.4 Axis D — Requested Victim Action

| Code | Action |
|----|-------|
| ACTION.SEND_MONEY | Send money |
| ACTION.GIFT_CARDS | Buy gift cards |
| ACTION.CRYPTO | Transfer cryptocurrency |
| ACTION.CREDENTIALS | Share credentials |
| ACTION.INSTALL | Install software |
| ACTION.CLICK_LINK | Click links |
| ACTION.PROVIDE_PII | Provide personal info |

---

### 5.5 Axis E — Claimed Persona / Impersonation

| Code | Persona |
|----|--------|
| PERSONA.GOVERNMENT | Government |
| PERSONA.BANK | Bank / Financial Institution |
| PERSONA.TECH | Tech Support |
| PERSONA.EMPLOYER | Employer |
| PERSONA.ROMANTIC | Romantic Partner |
| PERSONA.MARKETPLACE | Buyer / Seller |
| PERSONA.CHARITY | Charity |

---

> **Note:** The authoritative schema and Pydantic models are defined in the [TDD](../../core/docs/design/fraud_taxonomy_tdd.md).

Each submission returns structured results containing labels and confidence scores for each axis.persona": [{"label": "PERSONA.ROMANTIC", "confidence": 0.85}]
}
```

---

## 7. Confidence Scoring Guidelines

- Scores represent **model belief**, not probability of guilt
- Thresholds:
  - `>= 0.85`: High confidence
  - `0.60–0.85`: Moderate confidence
  - `< 0.60`: Weak signal

Multiple weak signals across axes may still indicate high overall risk.

---

## 8. Explainability Requirements

For each top label, the system must be able to produce:
- Key phrases or behaviors detected
- Plain-language explanation

Example:
> "This message shows signs of an **investment scam** because it promises guaranteed returns and asks you to move funds to cryptocurrency quickly."

---

## 9. Versioning & Evolution

- Taxonomy versioned as `fraud-taxonomy.vX.Y`
- New labels added without removing old ones
- Deprecated labels remain for backward compatibility

---

## 10. Integration with IntelligenceForGood

### 10.1 Internal Mapping

- Map taxonomy labels to:
  - Known scam campaigns
  - Historical trend data
  - Damage estimates

### 10.2 Feedback Loop

- User confirmations feed training data
- Analyst overrides logged for review

---

## 11. Implementation Phases

**Phase 1:**
- Implement taxonomy + schema
- LLM-based zero/few-shot classification

**Phase 2:**
- Add rules and pattern detectors
- Confidence calibration

**Phase 3:**
- Campaign clustering
- Trend and evolution tracking

---

## 12. Success Metrics

- Precision/recall per intent
- False reassurance rate (critical)
- User comprehension scores
- Analyst review agreement rate

---

## 14. Taxonomy Management & Tooling

To ensure consistency across the Python backend, TypeScript frontend, and documentation, the taxonomy must be managed as a **Single Source of Truth (SSOT)**.

### 14.1 Definition Format
The taxonomy will be defined in a machine-readable format (e.g., `taxonomy_definitions.yaml`) containing:
- Label Codes (e.g., `INTENT.IMPOSTER`)
- Human-readable Labels
- Descriptions/Tooltips
- Deprecation status
- Version introduced

This definition serves as the **Single Source of Truth** for the entire system.

### 14.2 API-Driven Dynamic Loading
> **Implementation Note:** Unlike traditional systems that compile taxonomy enums into static frontend bundles, this system uses a **Dynamic Loading** approach.
> Frontend clients fetch the current taxonomy tree from the API at runtime (`GET /taxonomy`). This allows descriptions, tooltips, and even new labels to be updated in the backend without requiring a rebuild or redeploy of the client applications.

> See [Section 2.2 of the TDD](../../core/docs/design/fraud_taxonomy_tdd.md#22-single-source-of-truth-ssot) for technical details on the SSOT pipeline.

---

## 15. Storage Strategy

> **Moved to TDD:** See [Section 4 of the TDD](../../core/docs/design/fraud_taxonomy_tdd.md#4-storage-strategy) for database schema and indexing details.

---

## 16. AI Training Strategy (Few-Shot)

> **Moved to TDD:** See [Section 5 of the TDD](../../core/docs/design/fraud_taxonomy_tdd.md#5-ai-classification-strategy) for details on the Golden Dataset and prompt engineering
## Appendix A — Source Alignment

- [FTC Consumer Fraud Categories](https://www.ftc.gov/system/files/attachments/data-sets/category_definitions.pdf)
- FBI IC3 Internet Crime Report
- APWG Phishing Taxonomy
- [MISP Fraud & Social Engineering Taxonomies](https://www.misp-project.org/taxonomies.html#_misp_taxonomies)

---

**Owner:** IntelligenceForGood  
**Status:** Draft PRD v1.0

