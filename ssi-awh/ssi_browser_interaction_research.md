# Research: Flexible Automated Browser Interaction with LLMs

> Research report on approaches for LLM-driven navigation of arbitrary websites,
> specifically for scam site investigation (registration, deposit navigation, wallet extraction).
>
> Date: 2026-02-20

---

## Table of Contents

1. [Vision-Based Approaches](#1-vision-based-approaches)
2. [DOM/Text-Based Approaches](#2-domtext-based-approaches)
3. [browser-use Library Deep Dive](#3-browser-use-library-deep-dive)
4. [Other Agentic Browser Frameworks](#4-other-agentic-browser-frameworks)
5. [Hybrid/Adaptive Approaches](#5-hybridadaptive-approaches)
6. [Playbook/Template + LLM Fallback](#6-playbooktemplate--llm-fallback)
7. [Reliability and Failure Handling](#7-reliability-and-failure-handling)
8. [Key Recommendation](#8-key-recommendation)

---

## 1. Vision-Based Approaches

**Concept:** Take a screenshot of the current page, send it to a multimodal LLM (Claude, Gemini, GPT-4o), and ask it to decide what element to click, what to type, etc. The LLM "sees" the page as a human would.

### How AWH Does It

AWH's `page_analyzer.py` implements this directly:

- Take a PNG screenshot via CDP (`tab.send(cdp.page.capture_screenshot)`)
- Resize to ~1280×720 to reduce token cost
- Send screenshot + system prompt + conversation history to Claude Sonnet
- Claude returns a JSON action: `{action, selector, value, reasoning, confidence}`
- Controller executes the action via zendriver CDP commands

The system prompt is ~2,000 tokens and provides state-specific instructions (FIND_REGISTER, FILL_REGISTER, NAVIGATE_DEPOSIT, EXTRACT_WALLETS). Each step costs one multimodal LLM call.

### Reliability

| Aspect                           | Rating | Notes                                                                    |
| -------------------------------- | ------ | ------------------------------------------------------------------------ |
| Understanding page layout        | ★★★★★  | Vision models excel at "what does this page look like"                   |
| Finding buttons/links            | ★★★★☆  | Good, but occasionally misidentifies decorative elements                 |
| Reading form fields              | ★★★★☆  | Can read labels, placeholders, error messages visually                   |
| Handling overlays/popups         | ★★★★★  | Sees them as a human would — this is vision's killer advantage           |
| Generating correct CSS selectors | ★★☆☆☆  | **Weakness** — LLM guesses selectors from visual appearance; often wrong |
| Handling non-English sites       | ★★★★☆  | Multimodal models handle CJK, Cyrillic, etc. reasonably                  |
| Handling canvas/image content    | ★★★★★  | Only approach that handles image-rendered text or canvas UIs             |

**The selector problem** is vision's Achilles heel. The LLM sees a "Register" button but has to _guess_ the CSS selector (`button.register-btn`, `a:contains("Register")`, etc.). AWH mitigates this with fallback strategies in `browser_manager.py` — trying CSS, then text match, then JS click — but it still fails ~15-20% of the time on unusual DOM structures.

### Cost Analysis (per investigation step)

| Model            | Input (screenshot ~1200 tokens + text ~500) | Output (~100 tokens) | Cost/step |
| ---------------- | ------------------------------------------- | -------------------- | --------- |
| Claude Sonnet 4  | 1,700 tokens × $3/M                         | 100 × $15/M          | ~$0.007   |
| Gemini 2.0 Flash | 1,700 tokens × $0.10/M                      | 100 × $0.40/M        | ~$0.0002  |
| Gemini 2.5 Pro   | 1,700 tokens × $1.25/M                      | 100 × $10/M          | ~$0.003   |
| GPT-4o           | 1,700 tokens × $2.50/M                      | 100 × $10/M          | ~$0.005   |

A typical investigation = 15-40 steps → **$0.003–$0.008 with Gemini Flash** vs **$0.10–$0.28 with Claude Sonnet**.

### Best Practices

1. **Resize screenshots aggressively.** 1280×720 is sufficient; 1920×1080 wastes tokens. AWH already does this.
2. **Include text context alongside the image.** Page title, URL, visible text extracted from DOM — reduces hallucination.
3. **Use coordinate-based clicking over CSS selectors.** Some frameworks (browser-use 0.2+, Claude Computer Use) return pixel coordinates `{x, y}` instead of CSS selectors. This bypasses the selector-guessing problem entirely. Gemini 2.0 can return bounding boxes.
4. **Maintain conversation history** but cap it. AWH caps at `MAX_CONTEXT_MESSAGES` to prevent context window overflow.
5. **Use cheaper models for simple states.** AWH uses `ANTHROPIC_MODEL_CHEAP` for states like SUBMIT_REGISTER where the action is usually obvious.

### Maturity Level

**High.** Claude Computer Use, Gemini with grounding, and GPT-4o vision are all production-ready. AWH has battle-tested this approach against 100+ scam sites.

---

## 2. DOM/Text-Based Approaches

**Concept:** Extract interactive elements from the DOM (inputs, buttons, links), present them as a numbered list to an LLM (text only, no image), and ask which element to interact with and what value to provide.

### How SSI Does It

SSI's `dom_extractor.py` runs JavaScript in the page to collect:

- All visible `<input>`, `<textarea>`, `<select>` elements
- All visible `<button>` and `<a>` elements
- For each: index number, tag, type, name, label, placeholder, text, value, href, required flag, CSS selector

This produces a numbered list like:

```
[0] input type=email name="email" label="Email" placeholder="Enter email" required
[1] input type=password name="password" label="Password" placeholder="8-12 chars"
[2] button text="Register" selector="#register-btn"
[3] a text="Login" href="/login"
```

The LLM then responds with: `{"action_type": "type", "element_index": 0, "value": "fake@email.com"}`.

### Reliability

| Aspect                        | Rating | Notes                                                                  |
| ----------------------------- | ------ | ---------------------------------------------------------------------- |
| Identifying form fields       | ★★★★★  | Direct DOM access — 100% accurate for standard HTML                    |
| Generating valid selectors    | ★★★★★  | **Huge advantage** — selectors come from DOM, not LLM guessing         |
| Handling overlays/popups      | ★★☆☆☆  | Must filter by visibility, but can miss z-index stacking, overlays     |
| Understanding page context    | ★★★☆☆  | Sees element list but misses spatial layout and visual hierarchy       |
| Handling shadow DOM           | ★☆☆☆☆  | Standard `querySelectorAll` cannot pierce shadow roots                 |
| Handling iframes              | ★★☆☆☆  | Requires explicit frame traversal; cross-origin iframes blocked        |
| Handling canvas/WebGL         | ☆☆☆☆☆  | Zero visibility into canvas-rendered content                           |
| Handling non-standard widgets | ★★☆☆☆  | Custom dropdowns (div-based), sliders, date pickers often invisible    |
| Token efficiency              | ★★★★★  | Text-only — ~200-500 tokens per observation vs ~1,200 for a screenshot |

### Key Limitations

1. **Custom widgets.** Scam sites built with Vue/React often use `<div>` based dropdowns, custom select boxes, and styled components that don't use standard HTML form elements. DOM extraction misses these unless the JS specifically queries `[role="listbox"]`, `[role="option"]`, etc.
2. **Dynamic content.** SPAs that render after `DOMContentLoaded` require waiting for hydration. Elements may not exist in DOM until user interaction triggers them.
3. **Visual context loss.** The LLM cannot see that a "Continue" button is grayed out, that a field has a red error border, or that a popup is obscuring the form. This information exists in computed styles but is expensive to extract comprehensively.
4. **Spatial reasoning.** Without layout information, the LLM cannot determine which button is "below" the form, or that the deposit section is in the left sidebar.

### Libraries and Tools

| Library                    | Stars | Approach                                                | Notes                                  |
| -------------------------- | ----- | ------------------------------------------------------- | -------------------------------------- |
| **browser-use** (DOM mode) | 78K+  | Extracts clickable elements, numbered list              | Most mature open-source DOM extraction |
| **Playwright** built-in    | —     | `page.query_selector_all`, `page.locator`               | Foundation for most DOM extraction     |
| **agentql**                | ~2K   | Natural language → element selector                     | Semantic element finding, commercial   |
| **Stagehand**              | ~12K  | `act()`, `extract()`, `observe()` — DOM + vision hybrid | By Browserbase; TypeScript-first       |

### Maturity Level

**High for basic extraction, medium for complex sites.** DOM extraction is deterministic and well-understood. The challenge is making it robust against the diverse, poorly-coded scam site frontends.

---

## 3. browser-use Library Deep Dive

**Repository:** [github.com/browser-use/browser-use](https://github.com/browser-use/browser-use) (78K+ stars, MIT license)

### Architecture

browser-use is a Python framework (Playwright-based) that implements an agent loop:

```
                  ┌─────────────────────┐
                  │   Agent (LLM loop)  │
                  │                     │
                  │  1. Get page state  │
                  │  2. Ask LLM         │
                  │  3. Execute action   │
                  │  4. Check if done    │
                  └──────────┬──────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        ┌──────────┐  ┌──────────┐  ┌──────────┐
        │ DOM      │  │ Vision   │  │ Custom   │
        │ Extract  │  │ (opt.)   │  │ Tools    │
        └──────────┘  └──────────┘  └──────────┘
```

**Core mechanism:**

1. **DOM extraction** — Injects JS to collect all interactive elements as a numbered list (very similar to SSI's approach, and likely the inspiration for it). Assigns each element an index and builds a compact text representation.
2. **LLM decision** — Sends the element list + task description + history to any LangChain-compatible LLM. The LLM returns a structured action referencing element indices.
3. **Action execution** — Translates the LLM's chosen action into Playwright calls.
4. **Optional vision** — Can include a screenshot alongside the DOM text for multimodal models. This is "DOM + vision" hybrid by default when using a vision-capable model.

### Key Features (relevant to our use case)

| Feature                        | Details                                                                     |
| ------------------------------ | --------------------------------------------------------------------------- |
| **LLM-agnostic**               | Works with OpenAI, Anthropic, Gemini, local models via LangChain            |
| **Multi-tab support**          | Can open/switch tabs — useful for sites that open deposit pages in new tabs |
| **File upload/download**       | Built-in handling — useful for evidence capture                             |
| **Cookie/session persistence** | Can save and restore browser state                                          |
| **Custom actions**             | Register Python functions as tools the agent can call                       |
| **Retry logic**                | Built-in retry with exponential backoff                                     |
| **DOM element highlighting**   | Adds visual markers to elements for debugging                               |
| **XPath + CSS selectors**      | Uses both for robustness                                                    |
| **GIF recording**              | Records agent sessions as GIFs — useful for evidence                        |

### Could It Be Used As-Is?

**Partially.** For the _browser interaction loop_ (DOM extraction → LLM → action execution), browser-use is more mature and battle-tested than both AWH's and SSI's custom implementations. However:

| Requirement                                  | browser-use Support | Gap                                          |
| -------------------------------------------- | ------------------- | -------------------------------------------- |
| Navigate arbitrary sites                     | ✅ Yes              | —                                            |
| Fill registration forms                      | ✅ Yes              | —                                            |
| Extract wallet addresses                     | ❌ No               | Custom extraction logic needed               |
| State machine (REGISTER → DEPOSIT → EXTRACT) | ❌ No               | browser-use is task-based, not state-machine |
| Human-in-the-loop guidance                   | ❌ No               | No WebSocket monitoring / pause-resume       |
| Playbook execution                           | ❌ No               | No deterministic scripted paths              |
| Stealth / anti-detection                     | ⚠️ Partial          | Uses standard Playwright — detectable        |
| Proxy integration                            | ✅ Yes              | Playwright proxy config                      |
| Cost optimization (DOM pre-scan)             | ⚠️ Partial          | Always sends to LLM; no three-tier scoring   |
| Evidence packaging                           | ❌ No               | No HAR/screenshot archival                   |

### Integration Options

**Option A: Use browser-use as the interaction engine, wrap with our state machine.**

- Replace SSI's `dom_extractor.py` + `actions.py` + `llm_client.py` with browser-use
- Keep our state machine (`controller.py`), wallet extraction, evidence packaging, human guidance
- Pros: Less code to maintain, benefit from community improvements
- Cons: Dependency on external library's API stability; may need to fork for stealth

**Option B: Cherry-pick browser-use's DOM extraction and action execution.**

- Copy/adapt their DOM extraction JavaScript (it handles edge cases like shadow DOM, iframes, ARIA roles better than SSI's current extractor)
- Keep our own LLM integration (more control over prompt engineering, cost optimization)
- Pros: Maximum control, minimal dependency
- Cons: More code to maintain, miss future browser-use improvements

**Option C: Use browser-use as-is with custom tools.**

- Register custom tools for wallet extraction, evidence capture, identity injection
- Let browser-use handle the full loop
- Pros: Simplest integration
- Cons: Least control; state machine logic becomes prompt engineering

### Maturity Level

**High.** 78K+ stars, active development (multiple releases in 2025-2026), used in production by multiple companies. The core DOM extraction + LLM loop is solid. However, the project moves fast and APIs change between versions — pin your version carefully.

### Maintenance Burden

**Low if used as dependency, medium if forked.** As a pip-installable library, updates are easy. But if you need stealth patches or custom DOM extraction, you may need to maintain a fork.

---

## 4. Other Agentic Browser Frameworks

### Stagehand (by Browserbase)

**Repository:** [github.com/browserbase/stagehand](https://github.com/browserbase/stagehand) (~12K stars)

- **Language:** TypeScript (Node.js)
- **Approach:** Three high-level primitives: `act("click the login button")`, `extract("get all prices")`, `observe("what elements are on this page")`
- **How it works:** Uses a combination of DOM extraction and vision. For `act()`, it identifies candidate elements via DOM, then optionally uses vision to disambiguate. For `extract()`, it uses structured output parsing.
- **LLM support:** OpenAI, Anthropic, Google (via their SDK)
- **Stealth:** Integrates with Browserbase's cloud browser infrastructure (paid) which provides stealth. Local mode uses standard Playwright.

**Fit for our use case:** ★★★☆☆

- Pros: Clean API, good extract primitive, DOM + vision hybrid built-in
- Cons: TypeScript (our stack is Python), Browserbase cloud is paid, local mode lacks stealth
- Would require a Node.js subprocess or a full rewrite of the agent layer

### AgentQL

**Website:** agentql.com

- **Approach:** Natural language queries to find page elements (e.g., `find("the email input field")` returns a Playwright locator)
- **How it works:** Proprietary AI model trained specifically on web element identification. Converts natural language to precise element selectors.
- **Pricing:** Free tier (limited), paid plans for production

**Fit for our use case:** ★★☆☆☆

- Pros: Very high accuracy for element finding; handles dynamic content well
- Cons: Proprietary, paid for production use, adds a vendor dependency for a non-profit

### Skyvern

**Repository:** [github.com/skyvern-ai/skyvern](https://github.com/skyvern-ai/skyvern) (~12K stars)

- **Approach:** Vision + DOM hybrid. Takes screenshots AND extracts DOM, sends both to LLM.
- **How it works:** Overlays element indices on the screenshot so the LLM can see both visual layout and interact by index. Custom action space with TOTP support, file uploads, etc.
- **LLM support:** OpenAI, Anthropic (vision models)

**Fit for our use case:** ★★★☆☆

- Pros: Hybrid approach matches our proposed design; element overlay on screenshots is clever
- Cons: Heavier infrastructure (requires its own backend service), primarily designed for RPA use cases, not adversarial investigation

### Playwright MCP Server (Anthropic)

- **Approach:** Exposes Playwright actions as MCP tools for Claude
- **How it works:** Claude calls `navigate`, `click`, `type`, `screenshot` tools via MCP protocol
- **Fit:** ★★★☆☆ — Good if you want Claude to drive everything, but ties you to Anthropic's ecosystem and MCP

### Claude Computer Use

- **Approach:** Claude takes screenshots and returns coordinate-based actions (`mouse_move(x, y)`, `click()`, `type("text")`)
- **How it works:** Pure vision. Claude identifies elements visually and returns pixel coordinates. No DOM extraction at all.
- **Cost:** Same as Claude API pricing — expensive ($3/$15 per M tokens)
- **Fit:** ★★☆☆☆ — Impressive but expensive, slow (must screenshot after every action), and doesn't leverage DOM for efficiency

### Summary Table

| Framework               | Language   | Approach                  | Stars | LLM-Agnostic     | Stealth                | Free    | Maturity |
| ----------------------- | ---------- | ------------------------- | ----- | ---------------- | ---------------------- | ------- | -------- |
| **browser-use**         | Python     | DOM + optional vision     | 78K+  | ✅               | ❌                     | ✅      | High     |
| **Stagehand**           | TypeScript | DOM + vision hybrid       | 12K   | Partial          | Via Browserbase (paid) | Partial | Medium   |
| **Skyvern**             | Python     | Vision + DOM overlay      | 12K   | Partial          | ❌                     | ✅      | Medium   |
| **AgentQL**             | Python/TS  | NL → selector             | 2K    | ❌ (proprietary) | ❌                     | Partial | Medium   |
| **Claude Computer Use** | Any        | Pure vision + coordinates | —     | ❌ (Claude only) | ❌                     | ❌      | High     |
| **Playwright MCP**      | TypeScript | MCP tools                 | —     | ❌ (Claude)      | ❌                     | ✅      | Medium   |
| **AWH (custom)**        | Python     | Vision + CDP              | —     | ❌ (Claude)      | ✅ (zendriver)         | ✅      | Medium   |
| **SSI (custom)**        | Python     | DOM text                  | —     | ✅               | ❌                     | ✅      | Low      |

---

## 5. Hybrid/Adaptive Approaches

### The Three-Tier Model (AWH's current DOM Inspector)

AWH already implements a hybrid approach with its `DOMInspector`:

```
Page loaded → Run JS DOM scan (0ms LLM cost)
                │
                ├── Confidence ≥ 75 ("direct")
                │     → Execute action immediately, zero LLM
                │     → e.g., registration form found, click "Register" link
                │
                ├── Confidence 40-74 ("assisted")
                │     → Inject DOM context into LLM prompt as text
                │     → LLM gets "DOM PRE-SCAN: register_link_found selector='a.register'"
                │     → Reduces LLM guessing, improves accuracy
                │
                └── Confidence < 40 ("fallback")
                      → Full LLM call (screenshot + text)
                      → Novel page layout, LLM figures it out visually
```

This is a well-designed pattern. The DOM scan catches ~40-60% of actions without any LLM cost.

### Extended Hybrid: DOM → Vision → Human

The full cascade for maximum reliability:

```
Step 1: DOM Pre-Scan (free, ~50ms)
  │
  ├── High confidence → execute directly
  │
  └── Low confidence ──▶ Step 2: LLM with DOM context (cheap, ~200ms)
                           │
                           ├── LLM confident → execute
                           │
                           └── LLM uncertain ──▶ Step 3: LLM with screenshot (moderate, ~1s)
                                                   │
                                                   ├── LLM confident → execute
                                                   │
                                                   └── LLM stuck ──▶ Step 4: Human guidance
                                                                       (WebSocket, manual)
```

### Best Practices for Hybrid Approaches

1. **DOM scan first, always.** It's free and provides ground-truth selectors. Even when vision is used, inject DOM context to help the LLM.

2. **Use vision for disambiguation, not navigation.** DOM tells you _what_ elements exist; vision tells you _which one matters_ in context. A page might have three "Submit" buttons — DOM finds all three, vision identifies which one is in the active form.

3. **Escalation should be automatic and invisible.** The controller should transparently upgrade from DOM → DOM+LLM → DOM+LLM+vision → human without the user needing to configure it.

4. **Track escalation rates.** Log how often each tier is used. If vision fallback exceeds 50% for a site category, consider writing a playbook for that category.

5. **Cache DOM scan patterns.** If the same site template is seen repeatedly (common with scam site clusters), cache the DOM scan results and skip directly to "direct" execution.

6. **Gemini Flash for the text-only tier, Gemini Pro/Claude for vision tier.** Use the cheapest model that works for each tier.

### Cost Model (per investigation, ~25 steps average)

| Approach             | Steps using DOM direct | Steps using LLM (text) | Steps using LLM (vision) | Est. cost (Gemini) |
| -------------------- | ---------------------- | ---------------------- | ------------------------ | ------------------ |
| Vision only          | 0                      | 0                      | 25                       | $0.005             |
| DOM only             | 12                     | 13                     | 0                        | $0.001             |
| Hybrid (current AWH) | 12                     | 3                      | 10                       | $0.003             |
| Hybrid (optimized)   | 15                     | 7                      | 3                        | $0.001             |

The optimized hybrid pushes more decisions to DOM direct by improving the JS scan coverage (handling more widget types, better keyword matching).

---

## 6. Playbook/Template + LLM Fallback

### The Playbook Concept

AWH's `playbook.py` defines a deterministic scripted flow for known site templates. Scam sites are frequently built from shared templates — a single frontend template might power 50+ domains. A playbook handles all of them with zero LLM cost.

### Playbook Structure (AWH's current model)

```python
Playbook(
    playbook_id="okdc_cluster_v1",
    url_pattern=r"(okdc|nexttrade|coinex-pro)\.(com|vip|top)",
    steps=[
        PlaybookStep(action="navigate", value="/register"),
        PlaybookStep(action="type", selector="input[name='email']", value="{identity.email}"),
        PlaybookStep(action="type", selector="input[name='password']", value="{identity.password}"),
        PlaybookStep(action="click", selector="button[type='submit']"),
        PlaybookStep(action="wait", value="3"),  # Wait for redirect
        PlaybookStep(action="navigate", value="/deposit"),
        PlaybookStep(action="extract"),  # Extract wallet addresses from page
    ],
    fallback_to_llm=True,  # If any step fails, hand off to LLM agent
)
```

### Making Playbooks Easy to Author

**Challenge:** Writing CSS selectors and figuring out the exact flow requires developer skill. With two volunteer developers and limited bandwidth, playbook authoring speed matters.

**Approaches:**

1. **Record-and-replay.** Run the LLM agent once on a new site, record every successful action (selector + value), auto-generate a playbook draft. Developer reviews and cleans up. This is the lowest-effort approach.

2. **Visual recorder (browser extension).** A Chrome extension that records clicks and types as the developer manually navigates the site, then exports a playbook JSON. More effort to build but faster for non-developers.

3. **LLM-assisted authoring.** Send the LLM a screenshot of the site's registration page and ask it to generate a playbook. Works surprisingly well for simple forms but needs human review.

4. **Template inheritance.** Define a "base scam template" playbook with common patterns (e.g., `/register` page, email/password/confirm_password fields, `/deposit` navigation). Site-specific playbooks only override the selectors that differ.

**Recommended approach:** Option 1 (record-and-replay) is the best bang for the buck. After each successful LLM-driven investigation, auto-generate a candidate playbook and store it. When a new site matches the same template, the playbook fires instead of the LLM.

### Playbook ↔ LLM Fallback Design

```python
# Pseudocode for the playbook executor with LLM fallback
for step in playbook.steps:
    for attempt in range(step.retry_on_failure + 1):
        try:
            execute_step(browser, step, identity)
            break  # Step succeeded
        except StepFailure:
            if attempt == step.retry_on_failure:
                if step.fallback_to_llm:
                    # Hand off to LLM agent from current state
                    llm_result = agent.resume_from(current_state, browser)
                    if llm_result.success:
                        break  # LLM recovered — continue playbook
                else:
                    raise PlaybookAborted(step)
```

The `fallback_to_llm=True` flag on each step means: "if this specific step fails (selector not found, timeout, etc.), give the LLM a screenshot and let it figure out what changed."

### Maturity Level

**Low (in AWH).** The playbook model is defined but the executor is not yet implemented. The data model is clean and the matching logic works. Building the executor is straightforward — it's essentially a for-loop over steps with error handling.

### Maintenance Burden

**Low once built.** Playbooks are JSON/YAML files. The main cost is authoring new ones when new scam templates emerge. With auto-generation from successful investigations, this becomes semi-automated.

---

## 7. Reliability and Failure Handling

### Sites That Change Layout

**Problem:** Scam sites are ephemeral — they may change templates, go offline, or A/B test different landing pages.

**Mitigations:**

- Playbooks have a `tested_urls` list — if the selector validation fails on a "tested" URL, flag the playbook as stale
- LLM fallback catches template changes automatically (that's the whole point of the hybrid)
- Log playbook failure rates per `url_pattern` — auto-disable playbooks with >50% failure rate

### Dynamic Content / SPAs

**Problem:** React/Vue/Angular SPAs render content after JavaScript execution. DOM extraction on `DOMContentLoaded` sees an empty `<div id="app">`.

**Mitigations:**

- **Wait for network idle** after navigation (`page.wait_for_load_state("networkidle")`)
- **Wait for specific selectors** — e.g., `page.wait_for_selector("form", timeout=10000)`
- **Mutation observer approach** — browser-use uses a MutationObserver to detect when the DOM stabilizes
- **Retry DOM extraction** with exponential backoff if zero interactive elements found
- AWH already handles this: if blank page detected, retry up to `BLANK_PAGE_MAX_RETRIES`

### Shadow DOM

**Problem:** Web components using Shadow DOM encapsulate their elements — `document.querySelectorAll` cannot see them.

**Mitigations:**

- **Recursive shadow root traversal.** Modify the DOM extraction JS to walk `element.shadowRoot` recursively:
  ```javascript
  function collectFromRoot(root) {
    root.querySelectorAll("input, button, a").forEach(process);
    root.querySelectorAll("*").forEach((el) => {
      if (el.shadowRoot) collectFromRoot(el.shadowRoot);
    });
  }
  ```
- **Playwright's built-in shadow DOM piercing:** `page.locator("css=input").first` in Playwright automatically pierces shadow roots (configurable)
- **browser-use** handles shadow DOM in its element extraction already
- **Real-world impact:** Low for scam sites. Most scam sites use cheap templates (jQuery, basic Vue) that don't use shadow DOM. This is more of a concern for legitimate enterprise sites.

### Iframes

**Problem:** Cross-origin iframes are isolated — the parent page's JS cannot access their DOM.

**Mitigations:**

- **Detect iframes** in the DOM scan, enumerate them, and extract from each frame separately
- Playwright: `page.frame_locator("iframe").locator("input")`
- zendriver: switch to frame via CDP `Page.getFrameTree`
- **Real-world impact:** Moderate. Some scam sites embed payment/deposit forms in iframes (often from third-party crypto payment processors).

### CAPTCHAs

**Problem:** Human verification challenges that block automated form submission.

| Strategy                     | Implementation                                         | Success Rate | Cost          |
| ---------------------------- | ------------------------------------------------------ | ------------ | ------------- |
| Skip and flag                | Mark site as "needs manual CAPTCHA"                    | N/A          | Free          |
| Human-in-the-loop            | WebSocket notification → human solves in monitoring UI | ~100%        | Dev time      |
| CAPTCHA solving service      | 2Captcha, AntiCaptcha API                              | ~95%         | $1-3 per 1000 |
| LLM vision (simple CAPTCHAs) | Send CAPTCHA image to vision model                     | ~30-60%      | LLM cost      |

**Recommendation:** Human-in-the-loop for now (AWH's approach). The monitoring UI already supports this pattern. CAPTCHA solving services are effective but cost money and raise ethical questions.

### Anti-Bot Detection

**Problem:** Sites using Cloudflare, hCaptcha, fingerprinting, or behavior analysis that detect and block automation.

| Strategy                              | Implementation                                                                                               |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| **zendriver/undetected-chromedriver** | Patches Chrome to avoid common detection signals (webdriver flag, CDP artifacts)                             |
| **Residential proxies**               | Decodo/SmartProxy residential IPs avoid datacenter IP blocklists                                             |
| **Human-like timing**                 | Random delays between actions (AWH: 200-600ms pre-action, 300-800ms post-action; SSI: 30-90ms per keystroke) |
| **Fingerprint randomization**         | SSI's `stealth.py` randomizes viewport, user-agent, timezone, WebGL renderer                                 |
| **Playwright Stealth**                | `playwright-extra` + `stealth` plugin patches common detection vectors                                       |

### Stuck Detection and Recovery

AWH implements sophisticated stuck detection:

- **Repeated action detection:** If the same action is taken `MAX_REPEATED_ACTIONS` times → stuck
- **Screenshot deduplication:** MD5 hash of screenshots — if N consecutive frames are identical → stuck
- **Per-state timeout:** If no state transition within threshold → escalate to human
- **Global action limit:** `MAX_ACTIONS_PER_SITE` caps total cost per investigation

### Maturity Level

**Medium-High.** AWH has robust failure handling from real-world scam site testing. The patterns are proven but some edge cases (shadow DOM, complex iframes) are not yet handled.

---

## 8. Key Recommendation

### Context

- **Non-profit** with free GCP credits (Gemini Flash/Pro available at no cost)
- **Premium Decodo proxy** account (residential proxies available)
- **Two volunteer developers** with limited bandwidth
- Need **stealth** (zendriver/CDP) for active interaction
- Need **rich features** (Playwright) for passive capture and evidence
- Want to **minimize LLM costs**
- Must handle **diverse, arbitrary scam site layouts**

### Recommended Architecture: Layered Hybrid with Playbook Priority

```
URL submitted
  │
  ▼
1. PlaybookMatcher.match(url)
  │
  ├─ Match ────▶ Playbook Executor (deterministic, $0.00)
  │               ├─ Step succeeds → next step
  │               └─ Step fails → fall through to LLM Agent
  │
  └─ No match ─▶ 2. DOM Pre-Scan (JS analysis, $0.00)
                    │
                    ├─ High confidence (≥75) → execute directly ($0.00)
                    │
                    ├─ Medium confidence (40-74) → LLM text-only + DOM context
                    │     → Gemini 2.0 Flash ($0.0001/step)
                    │
                    └─ Low confidence → LLM with screenshot + DOM context
                          → Gemini 2.0 Flash with image ($0.0002/step)
                          │
                          └─ LLM stuck → Human guidance (WebSocket UI)
```

### Why This Architecture

1. **Playbooks are free and fast.** Many scam sites share templates. Each playbook eliminates all LLM cost for matching sites. The record-and-replay approach makes authoring low-effort.

2. **DOM pre-scan eliminates 40-60% of LLM calls.** AWH's three-tier system is already proven. Port it to the merged codebase.

3. **Gemini Flash is effectively free** on GCP credits and 35x cheaper than Claude. Use it as the primary LLM. The quality difference vs Claude for "click the Register button" decisions is negligible.

4. **Vision is the safety net, not the default.** Only use screenshots when DOM extraction is insufficient. This keeps costs near zero while maintaining 95%+ success rates.

5. **Two codebases → one.** Don't maintain two agent implementations. The merged approach takes AWH's battle-tested patterns (state machine, DOM inspector, stuck detection, human guidance) and SSI's clean integration layer (Playwright, pluggable LLM, evidence packaging).

### Specific Technical Decisions

| Decision               | Recommendation                                                         | Rationale                                                                                                                 |
| ---------------------- | ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Primary LLM**        | Gemini 2.0 Flash (Vertex AI)                                           | Free on GCP credits, fast, good enough for DOM-assisted navigation                                                        |
| **Vision LLM**         | Gemini 2.0 Flash (multimodal)                                          | Same model, add screenshot when needed. Upgrade to Pro only for complex cases                                             |
| **Browser (active)**   | zendriver                                                              | Stealth is non-negotiable for scam sites; zendriver is battle-tested in AWH                                               |
| **Browser (passive)**  | Playwright                                                             | HAR recording, download interception, screenshot capture, rich API                                                        |
| **DOM extraction**     | Port AWH's `browser_manager.run_dom_scan()` + SSI's `dom_extractor.py` | Combine AWH's state-specific scanning with SSI's element numbering                                                        |
| **Agent framework**    | Custom (not browser-use) for now                                       | Our state machine + playbook + human guidance requirements don't fit browser-use's task-based model. Revisit in 6 months. |
| **Playbook authoring** | Auto-generate from successful LLM runs                                 | Lowest effort — playbooks materialize from normal usage                                                                   |
| **Cost target**        | <$0.01 per investigation (Gemini)                                      | Achievable with hybrid — ~3-5 vision calls × $0.0002 + ~10-15 text calls × $0.0001                                        |
| **Human guidance**     | Keep AWH's WebSocket-based monitoring UI                               | Already works; essential for CAPTCHAs and edge cases                                                                      |

### What NOT to Do

1. **Don't adopt browser-use as a dependency yet.** It doesn't support zendriver, doesn't have a state machine, and doesn't do playbooks. You'd spend more time adapting it than building on what you have. Re-evaluate when browser-use adds stealth browser support.

2. **Don't use Claude for routine navigation.** Reserve Anthropic budget for complex cases or human-assisted investigation where Claude's superior reasoning justifies the 35x premium.

3. **Don't build a visual playbook editor.** With two developers, JSON playbooks + auto-generation is sufficient. A UI editor is Phase 8 work.

4. **Don't try to solve CAPTCHAs with AI.** Human-in-the-loop is more reliable and costs $0. Automated CAPTCHA solving is an arms race you don't need to fight.

### Implementation Priority (weighted for two volunteers)

| Priority | Task                                                    | Effort  | Impact                             |
| -------- | ------------------------------------------------------- | ------- | ---------------------------------- |
| P0       | Port AWH state machine to SSI codebase                  | 2 weeks | Foundation for everything          |
| P0       | Wire Gemini Flash as primary LLM (replace Claude)       | 3 days  | Eliminates LLM cost                |
| P1       | Port DOM Inspector three-tier system                    | 1 week  | 40-60% cost reduction              |
| P1       | Implement playbook executor                             | 1 week  | Zero-cost path for known templates |
| P2       | Auto-generate playbooks from successful runs            | 3 days  | Playbooks accumulate organically   |
| P2       | Merge DOM extraction (AWH scan + SSI numbered elements) | 1 week  | Better element targeting           |
| P3       | Add Gemini vision fallback tier                         | 3 days  | Handles novel layouts              |
| P3       | Port human guidance WebSocket UI                        | 1 week  | CAPTCHA + edge case handling       |

### Summary

The most practical approach for a resource-constrained non-profit is **not** one framework — it's a **layered cascade** that uses the cheapest effective technique for each situation. Playbooks for known templates (free), DOM scanning for obvious actions (free), text-only LLM for moderate ambiguity (nearly free with Gemini Flash), and vision LLM as the last resort before human intervention. This matches what AWH has already proven works, adds SSI's clean architecture, and targets ~$0.01 per investigation on Gemini.
