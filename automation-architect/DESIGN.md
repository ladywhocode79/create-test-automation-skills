# DESIGN.md — automation-architect (Orchestrator)

| Field        | Value                                                        |
|--------------|--------------------------------------------------------------|
| Version      | 2.2.0                                                        |
| Status       | Stable                                                       |
| Skill file   | `automation-architect/SKILL.md`                              |
| Invoked by   | User directly (`/automation-architect`)                      |
| Delegates to | `automation-architect-python`, `automation-architect-java`, `automation-architect-mock` |
| Gated by     | None (entry point)                                           |
| Last updated | 2026-05-01                                                   |

---

## 1. Purpose & Scope

### What this skill does

Acts as a **Lead SDET** that conducts a structured interview with the user, resolves their full automation configuration, and generates a production-grade 4-layer test framework scaffold. It coordinates all other skills in the suite.

Every session follows the same spine:
**PRD intake → Analysis → Interview → Config resolution → Preview → Confirm → Write files → Execute tests → Generate report**

### What this skill deliberately does NOT do

- Does not write any test logic itself — it delegates to language track skills
- Does not generate mock infrastructure directly — delegates to `automation-architect-mock`
- Does not handle non-functional testing (load, security, chaos) — that is Phase 2, gated behind `automation-architect-nfr`
- Does not skip the preview step or write files without explicit user confirmation
- Does not infer language or test type silently — it always asks and confirms

### Who uses it

End users (SDETs, QA engineers, developers) invoke it directly via `/automation-architect`.
No other skill invokes this orchestrator — it is always the entry point.

---

## 2. Architecture Overview

```
 USER
  │
  │  /automation-architect
  ▼
┌──────────────────────────────────────────────────────┐
│               PHASE 1 — DISCOVERY                    │
│                                                      │
│  ┌──────────────────┐   ┌──────────────────────┐    │
│  │  Block 1         │   │  Block 2             │    │
│  │  PRD Intake      │──▶│  PRD Analysis        │    │
│  │  (Round -1)      │   │  + Type Confirm      │    │
│  │  MANDATORY       │   │  (Round 0)           │    │
│  └──────────────────┘   └──────────┬───────────┘    │
│                                    │                 │
│  ┌──────────────────┐              │                 │
│  │  Block 3         │◀─────────────┘                 │
│  │  Language Track  │                                │
│  │  Discovery       │                                │
│  │  (Round 1)       │                                │
│  └──────────┬───────┘                                │
│             │                                        │
│  ┌──────────▼──────────────────────────┐             │
│  │  Block 4/5 (conditional)            │             │
│  │  API Config (Round 2A)              │             │
│  │     if test_type = API or Full-Stack│             │
│  │  UI Config  (Round 2B)              │             │
│  │     if test_type = UI or Full-Stack │             │
│  └──────────┬──────────────────────────┘            │
│             │                                        │
│  ┌──────────▼───────────────┐                        │
│  │  Block 6                 │                        │
│  │  Common Config (Round 3) │                        │
│  │  Env / Mock / Reports    │                        │
│  └──────────────────────────┘                        │
└──────────────────────────────────────────────────────┘
  │
  ▼
┌──────────────────────────────────────────────────────┐
│               PHASE 2 — RESOLUTION                   │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │  Block 7 — Config Resolution                 │    │
│  │  Reads pattern-registry.md                   │    │
│  │  Activates / Defers / Skips patterns         │    │
│  └──────────────┬───────────────────────────────┘    │
│                 │                                    │
│      ┌──────────▼──────────────────────┐             │
│      │  Block 8 — Track Delegation     │             │
│      │  Reads Python or Java SKILL.md  │             │
│      │  Passes resolved config         │             │
│      └──────────┬──────────────────────┘             │
│                 │                                    │
│      ┌──────────▼──────────────────────┐             │
│      │  Block 9 — Mock Delegation      │             │
│      │  (only if mock=B or mock=C)     │             │
│      │  Reads mock SKILL.md            │             │
│      └──────────────────────────────────┘            │
└──────────────────────────────────────────────────────┘
  │
  ▼
┌──────────────────────────────────────────────────────┐
│               PHASE 3 — OUTPUT                       │
│                                                      │
│  ┌────────────────────┐   ┌────────────────────┐     │
│  │  Block 10          │   │  Block 11          │     │
│  │  Config Summary    │──▶│  Scaffold Preview  │     │
│  │  (print always)    │   │  (print always)    │     │
│  └────────────────────┘   └──────────┬─────────┘     │
│                                      │               │
│                              User confirms            │
│                         [Y] / [P] / [E] / [N] / [T]  │
│                                      │               │
│                           ┌──────────▼──────────┐    │
│                           │  Block 12            │    │
│                           │  Write Files         │    │
│                           │  (only on Y or P)    │    │
│                           └──────────────────────┘    │
└──────────────────────────────────────────────────────┘
  │
  ▼
┌──────────────────────────────────────────────────────┐
│               PHASE 4 — EXECUTION & VERIFICATION     │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │  Block 13 — Offer (default: Run now)           │  │
│  │  [R] Run  [S] Show commands  [X] Skip          │  │
│  └──────────────┬─────────────────────────────────┘  │
│                 │                                    │
│  ┌──────────────▼────────────────────────────────┐   │
│  │  Dependency Pre-flight                        │   │
│  │  Check: pytest/mvn/playwright browsers        │   │
│  │  If missing → present fix → wait → re-check   │   │
│  └──────────────┬────────────────────────────────┘   │
│                 │                                    │
│  ┌──────────────▼────────────────────────────────┐   │
│  │  WireMock Health Check (if mock_mode = B/C)   │   │
│  │  curl /__admin/health                         │   │
│  │  If DOWN → fix options → restart → re-check   │   │
│  └──────────────┬────────────────────────────────┘   │
│                 │                                    │
│  ┌──────────────▼────────────────────────────────┐   │
│  │  Run Tests (happy-path + edge-case together)  │   │
│  │  pytest / mvn test                            │   │
│  │  Print results summary                        │   │
│  └──────────────┬────────────────────────────────┘   │
│                 │                                    │
│       ┌─────────┴──────────┐                         │
│       │                    │                         │
│  ┌────▼──────────┐  ┌──────▼──────────────────────┐  │
│  │ Happy-path    │  │ Edge-case failures           │  │
│  │ failures      │  │ (EXPECTED — PRD ambiguity)   │  │
│  │               │  │ Present as info, not errors  │  │
│  │ Diagnosis +   │  │ Link → EDGE_CASES.md         │  │
│  │ Fix Loop      │  └─────────────────────────────-┘  │
│  │ Re-run test   │                                    │
│  │ after each fix│                                    │
│  └───────┬───────┘                                    │
│          │                                           │
│  ┌───────▼────────────────────────────────────────┐  │
│  │  Report Generation                             │  │
│  │  Allure / HTML / JUnit XML / ReportPortal      │  │
│  │  Print path or URL                             │  │
│  └───────┬────────────────────────────────────────┘  │
│          │                                           │
│  ┌───────▼────────────────────────────────────────┐  │
│  │  Session Close — print summary + next actions  │  │
│  └────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
  │
  ▼
 DOWNSTREAM SKILLS (delegated, not chained)
  ├── automation-architect-python  (if language = Python)
  ├── automation-architect-java    (if language = Java)
  └── automation-architect-mock   (if mock = B or C)
```

---

## 3. Skill Inputs

| Input | Source | Required? | Notes |
|-------|--------|-----------|-------|
| PRD document | User (text, markdown, PDF, link) | Strongly recommended | Sample provided if missing |
| Test type | User confirmation (Round 0) | Yes | Inferred from PRD, confirmed |
| Language | User (Round 1) | Yes | Drives track delegation |
| API protocol | User (Round 2A) | If API or Full-Stack | REST/GraphQL/gRPC/Mixed |
| Auth type | User (Round 2A) | If API or Full-Stack | OAuth2/Bearer/API Key/None |
| Browser targets | User (Round 2B) | If UI or Full-Stack | Chrome/Firefox/Safari/Mobile |
| Execution mode | User (Round 2B) | If UI or Full-Stack | Headless/Headed/Both |
| Locator strategy | User (Round 2B) | If UI or Full-Stack | data-testid/CSS/XPath/Role |
| UI Auth mode | User (Round 2B) | If UI or Full-Stack | Form/Token/Both |
| Environments | User (Round 3) | Yes | dev/staging/prod + secret mgmt |
| Mock mode | User (Round 3) | Yes | Real/WireMock/Both |
| Reporting | User (Round 3) | Yes | Allure/ReportPortal/HTML/XML |
| CI platform | User (Round 3) | Yes | GitHub/GitLab/Jenkins/Azure |

---

## 4. Skill Outputs

| Output | Type | Condition | Description |
|--------|------|-----------|-------------|
| PRD analysis summary | Printed | Always (if PRD provided) | Scope, ambiguities, recommendation |
| Resolved Config Summary | Printed | Always | Full resolved config table + pattern activation list |
| Scaffold Preview | Printed | Always | Annotated directory tree + 3-5 code snippets |
| Scaffold files | Written to disk | User confirms [Y] or [P] | All 4 layers + config + CI + mock files |
| EDGE_CASES.md | Written | Always with scaffold | PRD ambiguities mapped to test cases (P0/P1/P2) |
| PRD_CLARIFICATION_CHECKLIST.md | Written | Always with scaffold | P0 ambiguities requiring PRD action |
| TRACK-STUB.md | Written | language = Other | Contribution template for new language tracks |
| Test run results | Printed | Phase 4 [R] | Happy-path + edge-case results, structured summary |
| Fixed dependencies / .env | Applied | Phase 4, on user confirmation | pip install, playwright install, .env values filled |
| First test report | Generated | Phase 4, after run | Allure report / HTML / JUnit XML / RP launch |
| SESSION COMPLETE block | Printed | End of Phase 4 | Final summary + 4 next actions |

---

## 5. Logic Blocks

---

### Block 1 — PRD Intake (Round -1)

**Trigger:** Skill is invoked. This is the very first action, before any other question.

**Purpose:** Collect the Product Requirements Document that will drive the entire session — test type recommendation, edge-case detection, and test scope alignment.

**Logic:**

```
Ask user (alone, no other questions combined):
  [A] Yes — I have a PRD → user pastes/uploads content
  [B] No  — use sample   → load references/samples/sample-prd-user-management.md
  [C] Later              → warn and proceed without PRD
```

**Branch outcomes:**

```
[A] User provides PRD
    → Store PRD content in session
    → Proceed to Block 2

[B] Sample selected
    → Read references/samples/sample-prd-user-management.md
    → Display it to user (so they can see what a PRD looks like)
    → User can customize it now or accept as-is
    → Proceed to Block 2

[C] PRD deferred
    → Print warning:
       "PRD is essential for edge-case coverage and test type confirmation.
        Without it, the scaffold will use a generic resource (User API) as a
        placeholder. You can add a PRD at any time and re-run this skill."
    → Set prd_provided = false
    → Skip Block 2 (PRD analysis)
    → Jump to Block 3 (Language selection)
    → Test type is asked directly in Round 0 fallback question
```

**Reference loaded:** `references/samples/sample-prd-user-management.md` (only if [B])

**Output:** `prd_content` stored in session. `prd_provided` flag set.

**Edge cases:**
- User pastes a very long PRD → read fully, do not truncate
- User provides a URL instead of content → ask them to paste the text (no web fetch in this skill)
- User provides a PRD in a language other than English → analyze as-is, note the language, proceed

---

### Block 2 — PRD Analysis & Test Type Confirmation (Round 0)

**Trigger:** `prd_provided = true` (Block 1 returned [A] or [B])

**Purpose:** Extract what needs testing from the PRD, surface ambiguities the team hasn't resolved, recommend the right automation type, and confirm it with the user before any framework decisions are made.

**Logic — Step 0a (Extract Scope):**

Read PRD and identify:
```
Endpoints:    List all REST/GraphQL/gRPC paths found
Pages:        List all UI pages or user flows mentioned
Use Cases:    Happy path + error path scenarios
Auth Pattern: Bearer / OAuth2 / API Key / None
Perf Notes:   Any SLAs, rate limits, concurrency mentions
```

**Logic — Step 0b (Identify Ambiguities):**

Apply the 10-category checklist from `references/templates/edge-case-checklist.md`:

```
Category 1: Input Validation    → empty, null, boundary values, special chars
Category 2: Business Logic      → duplicates, state transitions, permissions
Category 3: Data Integrity      → constraints, cascading deletes, invariants
Category 4: Resource Limits     → pagination, max page size, rate limits
Category 5: Error Handling      → error codes, error format consistency
Category 6: Performance         → SLAs, timeouts, concurrency
Category 7: Security            → auth rules, injection, data exposure
Category 8: Backwards Compat    → versioning, deprecated fields
Category 9: Time-Based          → timestamps, expiry, DST handling
Category 10: Platform-Specific  → encoding, float precision, file paths
```

For each ambiguity found, assign a priority:
```
P0 (Critical)  → blocks development; PRD must clarify before coding starts
P1 (High)      → affects test coverage; clarify before first sprint ends
P2 (Medium)    → nice to have; clarify during testing phase
```

**Logic — Step 0c (Recommend Test Type):**

Apply the decision matrix from `references/prd-analysis-guide.md`:

```
PRD mentions REST endpoints, JSON, response codes, no UI  → recommend API
PRD mentions browser flows, user clicks, pages, forms     → recommend UI
PRD mentions both endpoints and user flows                → recommend Full-Stack
PRD mentions SLAs, load, rate limits, security scans      → recommend NFR
```

**Output block printed to user:**
```
SCOPE IDENTIFIED:
  Endpoints/Pages: [2-3 key items]
  Use Cases: [2-3 key flows]

AMBIGUITIES DETECTED: N gaps
  P0: [1-2 critical items]
  P1: [1-2 high items]
  P2: [1-2 medium items]

RECOMMENDED: [Type] because [2 reasons from PRD]
Does this match your goals? [A] API  [B] UI  [C] Full-Stack  [D] NFR
```

**Wait for user confirmation.** If user disagrees → ask why → re-assess and re-present.

**Reference loaded:** `references/prd-analysis-guide.md`, `references/templates/edge-case-checklist.md`

**Output:** `test_type` resolved. `prd_ambiguities` list (P0/P1/P2) stored in session.

**Edge cases:**
- PRD mentions both API and performance SLAs → ask: "API first (Phase 1) or jump to NFR scope?"
- PRD is very thin (1-2 lines) → proceed but warn: "PRD has limited scope; edge cases may be sparse"
- User selects [D] NFR → note: NFR requires a functional baseline; recommend API/UI first, NFR gated behind Phase 2

---

### Block 3 — Language Track Discovery (Round 1)

**Trigger:** `test_type` is confirmed (from Block 2, or from fallback direct question if PRD skipped)

**Purpose:** Present only the language tracks that actually exist as installed skills. Avoid presenting options that would fail.

**Logic:**

```
Scan filesystem: ~/.claude/skills/automation-architect-*/SKILL.md
Extract track names from directory names
Present only discovered tracks + always include [Z] Other

Example (current install):
  [A] Python  — automation-architect-python found
  [B] Java    — automation-architect-java found
  [Z] Other   — always shown
```

**Branch outcomes:**

```
[A] Python → set language = "python", track_skill = automation-architect-python
[B] Java   → set language = "java",   track_skill = automation-architect-java
[Z] Other  → set language = user_description
              Apply references/track-contract.md directly
              Generate pseudocode scaffold
              Output TRACK-STUB.md
              No track delegation occurs
```

**Reference loaded:** Filesystem glob for track discovery. `references/track-contract.md` (only for [Z])

**Output:** `language` and `track_skill` resolved.

**Edge cases:**
- Zero tracks installed (only Other available) → still ask [Z], explain how to install a track
- User names a language that matches a future track (e.g., "TypeScript") → acknowledge it, use [Z] path, note: "TypeScript track is on the roadmap"

---

### Block 4 — API Configuration (Round 2A)

**Trigger:** `test_type IN [API, Full-Stack]`

**Purpose:** Resolve the API-specific configuration choices that drive which patterns and files are generated.

**Questions asked:**

```
Q2. API Protocol:  REST/JSON  |  GraphQL  |  gRPC  |  Mixed
Q3. Auth type:     Bearer/JWT | OAuth2-CC | OAuth2-AC | API Key | Basic | None
```

**Decision impacts:**

```
protocol = GraphQL  → adds GraphQL client wrapper in Layer 2
protocol = gRPC     → adds gRPC channel setup in Layer 2 (stub note if track unsupported)
auth != none        → activates Singleton(Auth) pattern
auth in [oauth2_cc,
         oauth2_ac] → activates Adapter(Token) pattern
                      (OAuth2 flow complexity hidden behind AuthManager)
```

**Output:** `api_protocol`, `auth_type` resolved.

---

### Block 5 — UI Configuration (Round 2B)

**Trigger:** `test_type IN [UI, Full-Stack]`

**Purpose:** Resolve all browser and page interaction configuration choices.

**Questions asked:**

```
Q2. Browser targets:  Chrome | Chrome+Firefox | Chrome+Firefox+Safari | Mobile
Q3. Execution mode:   Headless | Headed | Both (env-controlled)
Q4. Locator strategy: data-testid | CSS | XPath | Role-based | Mixed
Q5. UI auth mode:     Login-form | Inject-token | Both
```

**Decision impacts:**

```
browser_targets > 1    → activates Factory(Browser) pattern
                          (BROWSER env var selects which browser to instantiate)
execution_mode = Both  → generated browser session reads HEADLESS env var
                          (headless=true in CI, false locally)
locator = data-testid  → note in README: "add data-testid to all interactive elements"
ui_auth = Inject-token → generated test skips login page,
                          injects token from AuthManager directly
ui_auth = Both         → generates both a full login test + token injection fixture
                          user selects per test class
```

**Output:** `browser_targets`, `execution_mode`, `locator_strategy`, `ui_auth_mode` resolved.

---

### Block 6 — Common Configuration (Round 3)

**Trigger:** After Rounds 2A/2B complete (or if only one applies)

**Purpose:** Resolve the cross-cutting configuration shared by all test types — environments, mocking, reporting, and CI.

**Questions asked:**

```
Q6. Environments + secret management:
      Number of envs (dev/staging/prod)
      Secret storage: .env | Vault | CI secrets | None

Q7. Service mode (mock):
      [A] Real only       → tests hit live running APIs
      [B] WireMock only   → tests hit stub server only
      [C] Both            → Strategy pattern, TEST_MODE env var switches

Q8. Reporting:
      Allure | ReportPortal | HTML | JUnit XML | None

Q9. CI platform:
      GitHub Actions | GitLab CI | Jenkins | Azure DevOps | Other/None
```

**Decision impacts:**

```
mock = B or C       → activates Strategy(Mock) pattern
                      → triggers Block 9 (Mock Delegation)
reporting = Allure  → adds allure-pytest / allure-testng dependency
                      adds @allure.title / @Story annotations in Layer 4
reporting = RP      → adds reportportal listener dependency + rp_uuid.ini
environments > 1    → generates multi-env config with ENV selector
ci = GitHub         → generates .github/workflows/*.yml
ci = GitLab         → generates .gitlab-ci.yml
ci = Jenkins        → generates Jenkinsfile
```

**Output:** `environments`, `secret_mode`, `mock_mode`, `reporting`, `ci_platform` resolved.
Session config is now fully resolved. No more questions are asked after this block.

---

### Block 7 — Config Resolution & Pattern Activation

**Trigger:** Immediately after Round 3 completes. No user interaction.

**Purpose:** Build the complete resolved configuration object and run it through the pattern activation matrix. This determines exactly which files will be generated.

**Logic:**

```
1. Assemble resolved config object:
   {
     test_type, language, api_protocol, auth_type,
     browser_targets, execution_mode, locator_strategy, ui_auth_mode,
     environments, secret_mode, mock_mode, reporting, ci_platform
   }

2. Read references/pattern-registry.md
   Apply activation matrix row by row:
   ─────────────────────────────────────────────────────
   Pattern              Condition           Decision
   ─────────────────────────────────────────────────────
   Singleton(Auth)      auth != none        [+] Activated
   Singleton(Driver)    test_type has UI    [+] Activated
   Factory(API Data)    always              [+] Activated
   Factory(UI Forms)    test_type has UI    [+] Activated
   Factory(Browser)     browsers > 1        [+] Activated
   Builder(Payload)     deferred            [~] Deferred (offer later)
   Page Component       test_type has UI    [+] Activated
   Strategy(Mock)       mock = B or C       [+] Activated
   Adapter(Token)       auth = OAuth2       [+] Activated
   Repository(Data)     data = external     [-] Skipped (inline default)
   Decorator(Retry)     always              [+] Activated
   Decorator(Logging)   always              [+] Activated
   ─────────────────────────────────────────────────────

3. Produce pattern_list:
   [+] = included in scaffold
   [~] = deferred, offer mid-session when complex payload detected
   [-] = skipped this session
```

**Reference loaded:** `references/pattern-registry.md`

**Output:** `resolved_config` + `pattern_list` (with [+]/[~]/[-] status for each pattern)

**Edge cases:**
- User selected Full-Stack → both API and UI pattern sets are activated simultaneously
- User selected None for auth + UI → Singleton(Auth) is [-], but Singleton(Driver) is [+]
- Deferred Builder triggers mid-session → offer it using the deferred pattern offer template in pattern-registry.md

---

### Block 8 — Track Delegation

**Trigger:** `resolved_config` and `pattern_list` are ready (Block 7 complete)

**Purpose:** Load the appropriate language track skill and pass the resolved config to it. The track skill knows which files to generate for each layer.

**Logic:**

```
if language == "python":
    Read ~/.claude/skills/automation-architect-python/SKILL.md
    Load profile based on test_type:
      API only    → load track's references/api/*  + references/shared/*
      UI only     → load track's references/ui/*   + references/shared/*
      Full-Stack  → load track's references/api/*, references/ui/*, references/shared/*
    Track generates its full file list based on resolved config

if language == "java":
    Read ~/.claude/skills/automation-architect-java/SKILL.md
    Same profile loading logic as Python

if language == "other":
    Do not delegate — apply references/track-contract.md directly
    Generate pseudocode in user's stated language
    Output TRACK-STUB.md as a contribution template
```

**What the track skill returns:** A complete list of files to generate with their content templates, based on resolved config.

**Reference loaded:** The appropriate track `SKILL.md` + all its `references/` files for the active profile

**Output:** `file_manifest` — the complete ordered list of files to generate with their resolved content

---

### Block 9 — Mock Delegation

**Trigger:** `mock_mode IN [B, C]`

**Purpose:** Load the mock infrastructure skill to generate WireMock configuration, stubs, and the Strategy pattern glue code.

**Logic:**

```
Read ~/.claude/skills/automation-architect-mock/SKILL.md

Always load:   references/wiremock-docker-setup.md
If UI tests:   references/wiremock-ui-backend-mocking.md
               (WireMock mocks the backend the browser calls, not the browser itself)
Always load:   references/strategy-pattern-switch.md
               (Strategy code is actually generated inside the language track Layer 2,
                this reference provides the pattern guidance)

Files added to file_manifest:
  mocks/stubs/user_stubs.json
  mocks/stubs/auth_stubs.json        (if auth != none)
  mocks/wiremock_lifecycle.{ext}
  docker-compose.yml                 (merged with any existing compose config)
```

**Reference loaded:** `automation-architect-mock/SKILL.md` and its reference files

**Output:** Mock files appended to `file_manifest`

---

### Block 10 — Scaffold Preview Generation (Phase 3, Steps 1 & 2)

**Trigger:** `file_manifest` is complete (Blocks 7-9 done)

**Purpose:** Show the user exactly what will be generated before writing anything. This is a non-negotiable checkpoint — no files are written until the user explicitly confirms.

**Logic — Config Summary (Step 1):**

```
Print the full resolved config table using format from references/preview-format.md:
  - All resolved values in a table
  - Pattern list with [+] / [~] / [-] symbols and one-line reason for each
  - Total file count and directory count
```

**Logic — Scaffold Preview (Step 2):**

```
Print the annotated directory tree:
  - Every file listed with a one-line description
  - Tree uses ASCII art: ├── └── │
  - Each line shows: filename + "← description"

Then print 3-5 code snippets using snippet priority table from preview-format.md:
  Priority 1: Layer 1 model with validation
  Priority 2: Layer 3 service method (typed in, typed out)
  Priority 3: Layer 4 test with arrange/act/assert
  Priority 4: Auth Manager Singleton (if auth)
  Priority 5: Browser Session (if UI)

Special mode (--test flag):
  If user message contains "--test", activate Compact Mode:
  - Print only 5 key config fields
  - Print flat file list (no tree art, no annotations, no snippets)
  - Add [T] option to exit without writing files
  - Purpose: validate routing at low token cost during skill development
```

**Reference loaded:** `references/preview-format.md`

**Output:** Config Summary + Scaffold Preview printed to screen.

---

### Block 11 — Confirmation Handling & File Writing (Phase 3, Steps 3 & 4)

**Trigger:** Preview is printed (Block 10). Wait for user response.

**Purpose:** Act on the user's decision about what to generate.

**Confirmation options and logic:**

```
[Y] Yes — write all files
    → Write every file in file_manifest using the Write tool
    → Always write README.md first
    → README must cover:
         tech stack, project structure, setup, running tests (mock+real),
         environments, test groups (including edge_case group),
         adding a new resource, PRD ambiguities link, P0/P1/P2 priorities,
         CI/CD secrets, Phase 2 NFR gate conditions
    → Write EDGE_CASES.md
         Maps each PRD ambiguity → parametrized test case
         P0/P1/P2 priority labels
    → Write PRD_CLARIFICATION_CHECKLIST.md
         Lists all P0 ambiguities + acceptance criteria
    → Write edge-case test templates (language-specific)
         Python: pytest.mark.parametrize with data-driven cases
         Java: @DataProvider + @Test with descriptive scenario names
    → After all files: print NEXT_STEPS inline (do not write as a file)
    → Print file count confirmation

[P] Partial — ask which layers first
    → Ask: "Which layers would you like first?"
    → Write only the requested subset
    → Ask: "Write the remaining files?"

[E] Edit config — re-run changed questions
    → Ask: "Which answer would you like to change?"
    → Re-run only the affected round(s)
    → Update resolved config
    → Regenerate and reprint the full Preview
    → Do not restart the entire interview

[N] No — output as code blocks
    → Output every file as a fenced code block with file path comment
    → Group by directory
    → User copies manually

[T] Stop (test mode only)
    → Print: "TEST PASS — preview validated, no files written."
    → Stop all output immediately
    → Used for skill development validation
```

**Architecture Rules enforced in every generated file (non-negotiable):**

```
Rule 1: Dependency direction
        Layer 4 → Layer 3 → Layer 2 → Layer 1 only
        No upward imports. Config injected via fixtures/DI.

Rule 2: No assertions in Layer 3
        Service and Page Object methods return typed objects.
        They never assert/expect/verify.

Rule 3: No locators in Layer 4
        UI tests interact via Layer 3 Page Object methods only.
        No raw CSS selectors, XPath, or element handles in tests.

Rule 4: No hardcoded values
        Zero base URLs, credentials, or env-specific values in any layer.
        All external values from env config module.

Rule 5: Schema validation at the boundary
        API responses deserialized into model objects before any assertion.
        Raw dict/map access forbidden in Layer 4.

Rule 6: One responsibility per class/module
        Each service class owns one resource domain.
        Each page object owns one page or component.
        No "utility" god classes.
```

**Output:** All files written to disk (if Y or P). NEXT_STEPS printed inline.

---

### Block 13 — Execution & Verification (Phase 4)

**Trigger:** Phase 3 Step 4 completes — all scaffold files written to disk.

**Purpose:** Close the loop between "framework generated" and "framework verified working." Runs the actual test suite against the scaffold, diagnoses any failures, fixes them collaboratively with the user, and generates the first test report. This is the difference between handing over a scaffold and handing over a *working* scaffold.

**Logic — Step 1: Offer with default pre-selected**

```
Print the Phase 4 offer block (see SKILL.md Phase 4 Step 1).
Default = [R]. If user presses Enter without input → treat as [R].

[R] → proceed to Step 2
[S] → print all commands, skip Steps 2-5, jump to Step 6 (print only)
[X] → jump to Step 7 (session close), no execution
```

**Logic — Step 2: Dependency pre-flight**

```
Python:
  Run: pip show pytest pydantic requests
  If any missing → show fix → wait for [A] Run now or [B] Manual
  If Playwright UI tests: check playwright install --list
  If missing browsers → offer: playwright install chromium --with-deps

Java:
  Run: mvn dependency:resolve -q
  If fails → show error → ask user to inspect pom.xml

On [A] (run fix): execute the install command, re-check, confirm ✓ or show error
On [B] (manual):  wait for user signal ("done") then re-check
```

**Logic — Step 3: WireMock health check (mock_mode = B or C only)**

```
Run: curl -s http://localhost:{WIREMOCK_PORT}/__admin/health

If 200 → "WireMock ✓" → continue
If fail → present 3 options:
  [A] docker-compose up -d wiremock  (run it now)
  [B] I'll start it — tell me when ready
  [C] Skip mock tests, run real-service only

If [A]: run command, re-check health every 10s, max 3 retries
  After 3 failures → print docker-compose logs wiremock, ask user to investigate
```

**Logic — Step 4: Run tests**

```
Run: pytest layer_4_tests/ -v --tb=short -m "api or ui or edge_case"
     + reporting flag based on resolved reporting config

Collect results into two buckets:
  Bucket A: happy-path tests      (failures = unexpected, need fixing)
  Bucket B: edge-case tests       (failures = expected, PRD gaps)

Print structured summary (see SKILL.md Phase 4 Step 4 format).

Edge-case failures are presented as informational:
  "EXPECTED FAILURE: {test} → Ambiguity: {description} → See EDGE_CASES.md"

Happy-path failures trigger Step 5.
```

**Logic — Step 5: Failure diagnosis & fix loop (happy-path only)**

```
For each happy-path failure:
  1. Match error text against root cause lookup table (9 patterns)
  2. Present: error → root cause → fix options [A], [B], [C skip], [D xfail all]
  3. If [A] or [B]: apply fix → re-run the single failing test only
  4. If test now passes: ✓ continue to next failure
  5. If test still fails: re-diagnose, present again
  6. If [C skip]: mark test xfail with a comment noting the reason
  7. If [D xfail all]: mark all remaining happy-path failures xfail, proceed to Step 6

Root cause lookup table (9 patterns — see SKILL.md Step 5 table):
  ConnectionRefusedError → service not running or wrong BASE_URL
  401 on token request   → wrong CLIENT_ID / CLIENT_SECRET
  FileNotFoundError .env → .env not created from .env.example
  ModuleNotFoundError    → pip install incomplete
  playwright executable  → playwright browsers not installed
  ClassNotFoundException → mvn compile failed
  WireMock 404           → stubs not registered
  docker not found       → Docker not installed
  SSLError               → self-signed cert, set VERIFY_SSL=false
```

**Logic — Step 6: Report generation**

```
Select generation command based on resolved reporting config:

Allure:
  allure generate allure-results/ --clean -o allure-report/
  allure open allure-report/
  Print: path, what it shows, note that trend baseline is now set

HTML (pytest-html / ExtentReports):
  Print: reports/report.html path, open in browser

JUnit XML:
  Print: test-results/TEST-*.xml path
  Offer: junit2html command for local HTML view

ReportPortal:
  Print: launch URL in RP dashboard
  Note: first launch recorded, future runs add to history

None:
  Print instructions to add reporting via /automation-architect [E]
```

**Logic — Step 7: Session close**

```
Print the SESSION COMPLETE block (see SKILL.md Phase 4 Step 7):
  - Framework summary
  - File count
  - Test results (happy-path + edge-case)
  - Report path
  - 4 NEXT ACTIONS (EDGE_CASES.md → .env → CI → NFR gate)
```

**References loaded:** None. All logic is self-contained using the resolved config from earlier blocks.

**Output:**
- Test run output (streamed)
- Results summary (printed)
- Fixed .env / installed deps (if user chose fixes)
- First report generated (Allure/HTML/XML/RP)
- SESSION COMPLETE block (printed)

**Edge cases:**
- All happy-path tests pass on first run → skip Step 5, go directly to Step 6
- All tests fail (e.g., wrong language installed) → offer `[D] xfail all` so report can still be generated
- User runs in an env with no Docker → present Step 3 [C] skip mock and continue
- Report generation command fails (e.g., `allure` CLI not on PATH) → print the manual install command, print report path anyway
- User is in [S] show-commands mode → print every command from Steps 2-6 as a numbered checklist, do not execute

---

### Block 12 — Scalability Contract (Other Language)

**Trigger:** `language = "Other"` (Block 3)

**Purpose:** Enable users with unsupported languages to still get value from the skill, and capture the information needed to contribute a new language track.

**Logic:**

```
1. Present Track Contract from references/track-contract.md
   (defines the 4-layer interface every track must implement)

2. Walk through each layer:
   Layer 1: "In [language], typed models are usually done with [X pattern]"
   Layer 2: "HTTP client in [language] — here is the base client pseudocode"
   Layer 3: "Service method signature in [language]"
   Layer 4: "Test structure in [language]"

3. Generate TRACK-STUB.md at project root:
   - Language track template with 4 layer placeholder sections
   - Notes on conventions observed during the session
   - Instructions for contributing the track:
       "Create ~/.claude/skills/automation-architect-{language}/SKILL.md
        following the Track Contract. The orchestrator discovers it
        automatically on next invocation via filesystem glob."
```

**Reference loaded:** `references/track-contract.md`

**Output:** Pseudocode scaffold + `TRACK-STUB.md` written to disk.

---

## 6. Integration Map

```
  /automation-architect  (this skill — user entry point)
         │
         ├── reads ──────────────────────────────────────────────────────────┐
         │   references/prd-analysis-guide.md     (Block 2)                  │
         │   references/templates/edge-case-checklist.md  (Block 2)          │
         │   references/samples/sample-prd-user-management.md (Block 1)      │
         │   references/pattern-registry.md       (Block 7)                  │
         │   references/preview-format.md         (Block 10)                 │
         │   references/track-contract.md         (Block 12)                 │
         │   references/nfr-roadmap.md            (NEXT_STEPS output)        │
         │   references/mock-options.md           (Q7 help text)             │
         │   references/reporting-options.md      (Q8 help text)             │
         │   references/ci-templates.md           (Q9 help text)             │
         │   references/edge-case-integration-guide.md  (Block 11, edge cases)
         └────────────────────────────────────────────────────────────────────┘
         │
         ├── delegates to ──────────────────────────────────────────────────┐
         │   automation-architect-python  (if language = Python)            │
         │   automation-architect-java    (if language = Java)              │
         │   automation-architect-mock    (if mock_mode = B or C)           │
         └───────────────────────────────────────────────────────────────────┘
         │
         └── does NOT invoke ────────────────────────────────────────────────
             automation-architect-nfr    (Phase 2 — user invokes directly)
             automation-architect-edge-cases (standalone skill, separate from this)
```

---

## 7. Reference Files

| File | Used in Block | Purpose |
|------|---------------|---------|
| `references/samples/sample-prd-user-management.md` | Block 1 | Shown when user has no PRD. Contains 19 annotated ambiguities. |
| `references/prd-analysis-guide.md` | Block 2 | 4-step PRD analysis methodology: Extract → Identify Ambiguities → Recommend Type → Plan Coverage |
| `references/templates/edge-case-checklist.md` | Block 2 | 10-category checklist for identifying ambiguities across Input/Business/Security/Performance/etc. |
| `references/pattern-registry.md` | Block 7 | Activation matrix: lists all design patterns, their trigger conditions, and what they generate |
| `references/preview-format.md` | Block 10 | Exact output format for Config Summary and Scaffold Preview — field order, table format, snippet rules, compact test mode |
| `references/track-contract.md` | Block 8, 12 | Interface specification every language track must implement. Used for [Z] Other path. |
| `references/mock-options.md` | Block 6 (Q7 help) | Comparison of WireMock vs Prism vs Mockoon — shown if user asks for help |
| `references/reporting-options.md` | Block 6 (Q8 help) | Comparison of Allure vs ReportPortal vs HTML — shown if user asks for help |
| `references/ci-templates.md` | Block 11 | CI workflow templates for GitHub/GitLab/Jenkins/Azure |
| `references/nfr-roadmap.md` | Block 11 (NEXT_STEPS) | Phase 2 gate conditions and NFR test types — printed in NEXT_STEPS |
| `references/edge-case-integration-guide.md` | Block 11 | File structure and templates for edge-case test generation |

---

## 8. Design Decisions Log

| # | Decision | Options Considered | Chosen | Rationale | Trade-offs |
|---|----------|--------------------|--------|-----------|------------|
| D1 | PRD intake as mandatory first step | (a) optional, (b) mandatory, (c) ask after language | **Mandatory before test type** | PRD determines what *kind* of automation is needed. Without it, users guess test type. PRD-first prevents re-work when the wrong type is scaffolded. | Adds friction for returning users who already know their config. Mitigated by [C] "Later" option. |
| D2 | Preview before write | (a) write immediately, (b) ask first, (c) always preview | **Always preview, never skip** | SDETs invest significant effort customizing a scaffold. A surprise file dump is hard to undo. Preview also educates users on what will be generated. | Adds 1 extra round-trip to every session. Cost is worth the safety. |
| D3 | WireMock as the default mock tool | WireMock, Prism (OpenAPI), Mockoon, custom stub server | **WireMock** | Language-agnostic (Docker-based), supports both API and UI backend mocking, has a well-documented admin API, widely used in enterprise Java/Python shops. | Requires Docker. Prism is lighter and OpenAPI-native but lacks request verification. Mockoon has a GUI but no programmatic API. **Gap:** WireMock has no built-in OpenAPI spec import — stubs must be hand-authored. Teams who have an OpenAPI spec and want auto-generated stubs should consider Prism instead. Surface this trade-off to the user at Q7 (Service Mode) if they mention an OpenAPI/Swagger spec. |
| D4 | Strategy pattern for real/mock switching | (a) env var in client directly, (b) Strategy with interface, (c) separate test suites | **Strategy pattern** | Single `TEST_MODE` env var switches clients without any test code changes. Tests remain unaware of whether they're hitting real or mock. Forces good design: defines a clear client interface that both implementations must follow. | More boilerplate upfront (interface + 2 implementations). Justified by long-term maintainability. |
| D5 | 4-layer architecture | 3-layer (no separate models), page object only, flat structure | **4 layers: Models → Client → Services/Pages → Tests** | Clear separation of concerns prevents the most common test debt patterns: raw dict access in tests, locators in test methods, hardcoded URLs. Each layer has one job. | More files than a quick-and-dirty setup. Justified for interview-ready, production-grade frameworks. |
| D6 | Track discovery via filesystem glob | (a) hardcoded list, (b) config file, (c) filesystem scan | **Filesystem glob** (`automation-architect-*/SKILL.md`) | New language tracks are automatically discovered without editing the orchestrator. Adding a track = create a directory. Extensible without code changes. | Relies on naming convention discipline. A misnamed skill directory won't be discovered. |
| D7 | Edge-case tests generated from PRD ambiguities | (a) generic edge-case templates, (b) PRD-driven, (c) separate skill only | **PRD-driven, integrated into scaffold** | Generic edge-case templates test nothing specific. PRD-driven tests expose the exact ambiguities *this* team needs to clarify. Tests that fail with meaningful messages are more actionable than hypothetical checklists. | Requires a PRD. Quality of edge-case tests depends on PRD quality. Sample PRD mitigates this. |
| D8 | Allure as recommended reporting | pytest-html, JUnit XML, Allure, ReportPortal | **Allure (recommended)**, others available | Rich HTML, historical trends, test categorization, and screenshot/log attachments in one free tool. Widely understood across Python and Java teams. Works with both pytest and TestNG without project restructure. | Needs a separate Allure server or `allure serve` CLI to view reports. ReportPortal offered as alternative for teams needing a persistent dashboard. |
| D9 | data-testid as recommended locator | CSS selectors, XPath, role-based, data-testid | **data-testid (recommended)**, others available | Decoupled from visual styling and DOM structure changes. Tests survive CSS refactors and layout changes. Easy to explain to developers ("add this attribute"). Works across Playwright and Selenium. | Requires developer cooperation to add test IDs. Some existing apps lack them. User can choose XPath/CSS if needed. |
| D10 | No assertions in Layer 3 (service/page methods) | (a) assertions in service layer, (b) return typed objects | **Return typed objects, no assertions** | Services and page objects are infrastructure. If they assert, a single structural change breaks many tests in ways that are hard to diagnose. Assertions belong in Layer 4 where test intent is explicit. | Slightly more verbose Layer 4 tests. The clarity gained far outweighs the verbosity. |

---

## 9. Known Limitations & Open Questions

| # | Item | Type | Status |
|---|------|------|--------|
| L1 | Language tracks exist only for Python and Java | Limitation | Known. JavaScript/TypeScript is the next planned track. Use [Z] Other path until it exists. |
| L2 | GraphQL and gRPC config is collected but the code templates are thinner than REST | Limitation | GraphQL uses the same HTTP client with a different query wrapper. gRPC needs a channel setup. Both are scaffolded with a note to extend. |
| L3 | NFR (Phase 2) is completely separate — no NFR awareness in Phase 1 scaffold | Design choice | Intentional. NFR on top of unstable functional tests creates noise. Gate conditions ensure NFR runs on a verified baseline. |
| L4 | PRD URL provided by user cannot be fetched (no web tool in this skill) | Limitation | User must paste content. Known friction point. Future: add WebFetch tool to SKILL.md tool list. |
| L5 | Builder pattern is deferred and only offered mid-session | Design choice | Avoids polluting the scaffold with an unneeded pattern. Offered only when the complexity warrants it. |
| O1 | Session resume — re-running skill on an existing project restarts from Round -1 | Open question | **Recommended approach (Option C):** Add a Round -2 gate: "New project or existing scaffold?" If README.md with config table is detected → offer jump to [E] Edit Config, skipping full re-interview. This is the cleanest UX with no extra files. Planned for v2.3. |
| O2 | Monorepo / multi-service support — skill generates one scaffold per run with no shared root | Open question | **Current:** Document in README — "For monorepos, run once per service." **Planned Option B design (v3.x):** Add a project-type gate before Round -1: "Single service or monorepo?" If monorepo → ask service names (e.g., `user-service`, `order-service`) → generate one root with `shared/` (auth, config, base client, reporting) + `services/{name}/layer_3_*/` and `services/{name}/layer_4_tests/` per service → CI runs all service test suites in parallel. Skill detects `shared/` on re-run and reuses it rather than overwriting. Single-service runs are unaffected — the gate defaults to single-service. Ready to implement when single-service flows are stable across both language tracks. |

---

## 10. Change History

| Date | Version | Change | Reason |
|------|---------|--------|--------|
| 2026-04-24 | 1.0.0 | Initial skill created | Interview-style orchestrator with 4 rounds |
| 2026-04-24 | 2.0.0 | Added pattern registry, preview format, track delegation | Production-grade scaffold with design patterns |
| 2026-05-01 | 2.1.0 | Added PRD Intake (Round -1), PRD Analysis (Round 0), edge-case integration | PRD-first approach: test type derived from PRD; edge-case tests now included in every scaffold |
| 2026-05-01 | 2.2.0 | Added Phase 4 (Execution & Verification) — Block 13 | Close the loop: scaffold generation now ends with a verified working test suite and first report generated |
