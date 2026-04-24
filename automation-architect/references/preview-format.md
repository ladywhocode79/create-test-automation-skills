# Preview Format — Scaffold Output Rules

This file defines the exact format the orchestrator MUST use when producing
the Config Summary and Scaffold Preview. Follow this format precisely.
Never deviate from the structure or skip sections.

---

## Compact Test Mode

If the user's message includes the word `--test` anywhere (e.g. "use run-a config --test"),
activate **Compact Mode** for the entire session:

- Phase A: print only the 5 key fields + pattern activation list (skip all other fields)
- Phase B: print the file tree with NO inline annotations and NO code snippets
- Confirmation prompt: add option `[T]` which exits after preview with no file writes and no next-steps output
- Purpose: validate routing and pattern activation logic at low token cost

Compact Mode Phase A format:
```
CONFIG (compact)
  test_type={value}  language={value}  mock={value}  auth={value}  ci={value}
  Patterns: {[+]PatternName  [~]PatternName  [-]PatternName ...}
  Files: {N}
```

Compact Mode Phase B format:
```
PREVIEW (compact)
  {file path}
  {file path}
  ... (one file per line, no tree art, no annotations)

[Y] write  [P] partial  [E] edit  [T] stop here (test mode)
```

---

## Phase A: Config Summary Block

Print immediately after Round 3 completes. No files are written yet.

```
══════════════════════════════════════════════════════════════════
  AUTOMATION ARCHITECT — RESOLVED CONFIGURATION
══════════════════════════════════════════════════════════════════

  Test Type     : {API | UI | Full-Stack (API + UI)}
  Language      : {Python | Java | Other}
  Test Runner   : {Pytest | TestNG | ...}
  API Tools     : {requests + Pydantic v2 | RestAssured + Jackson | N/A}
  UI Tools      : {Playwright (Python) | Selenium WebDriver + WebDriverManager | N/A}
  Auth          : {Bearer/JWT | OAuth2 Client Credentials | OAuth2 Auth Code |
                   API Key | Basic Auth | None}
  Browser(s)    : {Chrome | Chrome + Firefox | Chrome + Firefox + Safari | N/A}
  Execution     : {Headless | Headed | Both (env-controlled)}
  Locators      : {data-testid | CSS | XPath | Role-based | Mixed}
  UI Auth Mode  : {Login via form | Inject session token | Both}
  Environments  : {dev, staging, prod | ...}
  Secret Mgmt   : {.env files | Vault | CI secrets | None}
  Mock Mode     : {Real only | WireMock (mock only) | Both (mock + real)}
  Reporting     : {Allure | ReportPortal | HTML | JUnit XML | None}
  CI Platform   : {GitHub Actions | GitLab CI | Jenkins | Azure DevOps | None}
  Data Strategy : {Inline | External fixtures | Factory-generated | Mixed}

  Patterns activated:
  {checkmark} Singleton (Auth)    — {reason e.g. "OAuth2 Client Credentials selected"}
  {checkmark} Singleton (Driver)  — {reason e.g. "UI test type selected"}
  {checkmark} Factory (API Data)  — {reason e.g. "always included"}
  {checkmark} Factory (UI Forms)  — {reason e.g. "UI test type selected"}
  {checkmark} Factory (Browser)   — {reason e.g. "2 browser targets selected"}
  {checkmark} Strategy (Mock)     — {reason e.g. "mock=both selected"}
  {checkmark} Page Component      — {reason e.g. "UI test type selected"}
  {defer}     Builder (Payload)   — deferred (offer when complex payload needed)
  {cross}     Repository          — {reason e.g. "inline data strategy selected"}

  Files to generate: {N} files across {M} directories

══════════════════════════════════════════════════════════════════
```

Use plain text checkmarks:
- Activated patterns: [+]
- Deferred patterns:  [~]
- Skipped patterns:   [-]

---

## Phase B: Scaffold Preview Block

Print immediately after Phase A. Still no files written.

```
══════════════════════════════════════════════════════════════════
  SCAFFOLD PREVIEW  — no files written yet
══════════════════════════════════════════════════════════════════

  {project_name}/                              ← project root
  ├── layer_1_models/
  │   ├── api/
  │   │   ├── user_model.py                    ← CreateUserRequest, UserResponse (Pydantic)
  │   │   └── factories/
  │   │       └── user_factory.py              ← UserFactory.build(**overrides)
  │   └── ui/
  │       ├── locators/
  │       │   └── login_locators.py            ← LoginLocators.USERNAME, PASSWORD, SUBMIT
  │       └── form_data/
  │           └── login_form_data.py           ← LoginFormData dataclass + factory
  │
  ├── layer_2_clients/
  │   ├── api/
  │   │   └── base_api_client.py               ← requests.Session + retry + auth injection
  │   └── ui/
  │       └── browser_session.py               ← Playwright browser lifecycle + Singleton
  │
  ├── layer_3_services/
  │   └── user_service.py                      ← create_user(), get_user() → UserResponse
  │
  ├── layer_3_pages/
  │   ├── login_page.py                        ← login_as() → DashboardPage (Playwright)
  │   ├── dashboard_page.py                    ← verify_welcome_message(), navigate_to()
  │   └── components/
  │       └── header_component.py              ← HeaderComponent: nav, profile menu
  │
  ├── layer_4_tests/
  │   ├── api/
  │   │   └── test_user_api.py                 ← TestUserCreation, TestUserRetrieval
  │   └── ui/
  │       └── test_login_flow.py               ← TestLoginFlow, TestLoginValidation
  │
  ├── config/
  │   ├── env_config.py                        ← pydantic-settings BaseSettings (all env vars)
  │   ├── auth_manager.py                      ← Singleton token manager, TTL refresh
  │   ├── driver_manager.py                    ← Singleton/ThreadLocal browser instance
  │   └── logger.py                            ← Structured logger, LOG_LEVEL controlled
  │
  ├── mocks/
  │   ├── stubs/
  │   │   ├── user_stubs.json                  ← WireMock: POST /users, GET /users/{id}
  │   │   └── auth_stubs.json                  ← WireMock: POST /oauth/token
  │   └── wiremock_lifecycle.py                ← register_stub(), verify_called(), reset()
  │
  ├── conftest.py                              ← pytest fixtures: client, auth, browser, stubs
  ├── pytest.ini                               ← markers: api, ui, smoke, regression
  ├── .importlinter                            ← layer dependency enforcement config
  ├── requirements.txt                         ← pinned dependencies
  ├── .env.example                             ← all required env vars documented
  ├── docker-compose.yml                       ← WireMock service
  └── .github/workflows/
      ├── api-tests.yml                        ← API CI pipeline
      └── ui-tests.yml                         ← UI CI pipeline (browser install included)

  {N} files across {M} directories

══════════════════════════════════════════════════════════════════
  KEY CODE SNIPPETS
══════════════════════════════════════════════════════════════════

[Include 3-5 snippets showing the most architecturally significant patterns.
Always include at minimum:]

  1. The Layer 1 model with validation (Pydantic or Jackson)
  2. The Layer 3 service method signature (typed in, typed out)
  3. A complete Layer 4 test showing arrange/act/assert with fixtures
  4. The Auth Manager Singleton (if auth != none)
  5. The Browser Session Singleton (if test_type includes UI)

[Format each snippet as:]

  --- {filename} ---
  ```{language}
  {code}
  ```

══════════════════════════════════════════════════════════════════
  CONFIRMATION
══════════════════════════════════════════════════════════════════

  Ready to generate {N} files.

  [Y] Yes, write all files     — scaffold the full project now
  [P] Partial                  — tell me which layers/files to start with
  [E] Edit configuration       — change an answer before generating
  [N] No, show me the code     — output all file contents as code blocks
                                  (I will copy the files myself)
  [T] Stop here                — testing only: validate preview, write nothing

  Your choice:
══════════════════════════════════════════════════════════════════
```

---

## Handling Each Confirmation Response

### [Y] — Write All Files

1. Write every file listed in the preview using the Write tool
2. After all files written, print this inline (do not write as a file):

```
══════════════════════════════════════════════════════════════════
  SCAFFOLD COMPLETE
══════════════════════════════════════════════════════════════════

  Written: {N} files to {project_name}/

  NEXT STEPS
  ──────────
  1. Copy .env.example to .env and fill in your values:
       cp .env.example .env

  2. Start WireMock (if mock selected):
       docker-compose up -d wiremock
       # verify: curl http://localhost:8080/__admin/health

  3. Install dependencies:
       # Python:
       pip install -r requirements.txt
       playwright install chromium --with-deps    # (if UI tests)

       # Java:
       mvn dependency:resolve

  4. Run the API test suite:
       pytest layer_4_tests/api/ -v -m "api"
       # Java: mvn test -Dgroups=api

  5. Run the UI test suite:
       pytest layer_4_tests/ui/ -v -m "ui"
       # Java: mvn test -Dgroups=ui

  6. View the Allure report:
       allure serve allure-results/
       # (if reporting = allure)

  ADDING A NEW LANGUAGE TRACK
  ────────────────────────────
  See the Track Contract:
    ~/.claude/skills/automation-architect/references/track-contract.md

  PHASE 2 — NON-FUNCTIONAL TESTING
  ──────────────────────────────────
  Available once:
    [ ] API test suite has >= 80% endpoint coverage
    [ ] CI pipeline is green on at least one environment
    [ ] You trigger: /automation-architect-nfr
  Details: ~/.claude/skills/automation-architect/references/nfr-roadmap.md

══════════════════════════════════════════════════════════════════
```

### [P] — Partial Write

Ask: "Which layers would you like me to generate first?"
Common answer: "Start with Layer 1 and Layer 2" or "Just the config files"
Write only the requested subset, then ask: "Write the remaining files?"

### [E] — Edit Configuration

Ask: "Which answer would you like to change?"
Re-run only that round's questions, update the Resolved Config,
then regenerate and reprint the full Preview. Do not restart the interview.

### [T] — Stop Here (Test Mode)

Print one line: `TEST PASS — preview validated, no files written.`
Then stop. Do not print next steps, do not write any files.
Used during skill development to validate routing and pattern activation
at minimal token cost.

### [N] — No Write

Output every file's content as a fenced code block with the file path as
a comment on the first line. Group by directory. User copies manually.
```
# {project_name}/config/env_config.py
```python
... file contents ...
```
```

---

## Snippet Selection Rules

Select snippets in this priority order based on what was activated:

| Priority | Snippet | Condition |
|---|---|---|
| 1 | Layer 1 API model with validation | test_type includes API |
| 2 | Layer 3 service method (typed in, typed out) | test_type includes API |
| 3 | Layer 4 API test with arrange/act/assert | test_type includes API |
| 4 | Auth Manager Singleton with TTL | auth != none |
| 5 | Browser Session Singleton | test_type includes UI |
| 6 | Layer 3 Page Object with fluent return | test_type includes UI |
| 7 | Layer 4 UI test using page objects | test_type includes UI |
| 8 | WireMock stub + verify_called | mock selected |
| 9 | Factory with Faker + overrides | always |

Show maximum 5 snippets. If Full-Stack selected, show 3 API + 2 UI snippets.
Prioritize snippets that demonstrate the patterns the user may not have
seen before (e.g., typed service return, fluent page object, TTL singleton).
