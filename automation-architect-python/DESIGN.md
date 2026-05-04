# DESIGN.md — automation-architect-python

| Field        | Value                                                                 |
|--------------|-----------------------------------------------------------------------|
| Version      | 2.1.0                                                                 |
| Status       | Stable                                                                |
| Skill file   | `automation-architect-python/SKILL.md`                                |
| Invoked by   | `automation-architect` orchestrator (not user-invocable directly)     |
| Delegates to | None                                                                  |
| Gated by     | Orchestrator must pass resolved config before this skill activates    |
| Last updated | 2026-05-02                                                            |

---

## 1. Purpose & Scope

### What this skill does

Generates all scaffold files for the **Python language track** of the automation-architect suite. It receives a fully resolved configuration from the orchestrator, loads the appropriate profile references (API / UI / both), and produces a production-grade 4-layer test framework with no manual wiring needed.

Every generated file is immediately runnable — no placeholders, no TODO comments in functional code.

### What this skill deliberately does NOT do

- Does not ask the user any questions — all config is resolved by the orchestrator before this skill runs
- Does not generate WireMock infrastructure — that is handled by `automation-architect-mock`
- Does not generate NFR tests (load, security, chaos) — that is Phase 2, handled by `automation-architect-nfr`
- Does not produce Java or any other language — strictly Python

### Who invokes it

`automation-architect` orchestrator invokes this skill after `language = Python` is confirmed. The orchestrator passes the fully resolved config object and pattern activation list.

---

## 2. Architecture Overview

```
  ORCHESTRATOR passes:
  resolved_config + pattern_list
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│         PROFILE LOADING (Block 1)                       │
│                                                         │
│  test_type = API        → load references/api/*         │
│                           + references/shared/*         │
│                                                         │
│  test_type = UI         → load references/ui/*          │
│                           + references/shared/*         │
│                                                         │
│  test_type = Full-Stack → load references/api/*         │
│                           + references/ui/*             │
│                           + references/shared/*         │
└─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│         4-LAYER FILE GENERATION                         │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │  LAYER 1 — Models / Data                         │   │
│  │  Block 2: API — Pydantic v2 models + factories   │   │
│  │  Block 5: UI  — Locators (dataclass) + FormData  │   │
│  └──────────────────────────────────────────────────┘   │
│                          │ imports                      │
│  ┌──────────────────────────────────────────────────┐   │
│  │  LAYER 2 — Clients / Infrastructure              │   │
│  │  Block 3: API — BaseApiClient (requests)         │   │
│  │              + Strategy (Real/Mock) if mock=B/C  │   │
│  │  Block 6: UI  — BrowserSession (Playwright)      │   │
│  │              ThreadLocal Singleton               │   │
│  └──────────────────────────────────────────────────┘   │
│                          │ imports                      │
│  ┌──────────────────────────────────────────────────┐   │
│  │  LAYER 3 — Services / Pages                      │   │
│  │  Block 4: API — UserService (typed in/out)       │   │
│  │  Block 7: UI  — LoginPage, DashboardPage,        │   │
│  │              HeaderComponent (fluent returns)    │   │
│  └──────────────────────────────────────────────────┘   │
│                          │ imports                      │
│  ┌──────────────────────────────────────────────────┐   │
│  │  LAYER 4 — Tests                                 │   │
│  │  Block 8: API — pytest test classes + conftest   │   │
│  │  Block 9: UI  — pytest test classes + conftest   │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │  CROSS-CUTTING (all test_types)                  │   │
│  │  Block 10: EnvConfig (pydantic-settings)         │   │
│  │  Block 11: Logger                                │   │
│  │  Block 12: AuthManager (Singleton variants)      │   │
│  │  Block 13: Allure / Reporting config             │   │
│  │  Block 14: File generation order + code rules    │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
         │
         ▼
  File manifest returned to orchestrator
  (all files written by orchestrator Write tool)
```

### Dependency direction (enforced in every file)

```
  Layer 4 (Tests)
      │ imports
  Layer 3 (Services / Pages)
      │ imports
  Layer 2 (Clients)
      │ imports
  Layer 1 (Models / Data)

  config/ is injected via conftest fixtures — never imported directly by test files.
  No layer imports from a layer above it. Ever.
```

---

## 3. Inputs (from orchestrator)

| Input | Values | Impact |
|-------|--------|--------|
| `test_type` | API / UI / Full-Stack | Selects which profiles to load |
| `auth_type` | Bearer/JWT, OAuth2-CC, OAuth2-AC, API Key, Basic, None | Selects AuthManager variant |
| `mock_mode` | A (real) / B (mock) / C (both) | Activates Strategy pattern in Layer 2 |
| `browser_targets` | Chrome / Chrome+Firefox / all / mobile | Activates Factory(Browser) |
| `execution_mode` | Headless / Headed / Both | Sets headless default + HEADLESS env var |
| `locator_strategy` | data-testid / CSS / XPath / Role-based / Mixed | Selects locator variant in Layer 1 UI |
| `ui_auth_mode` | Form / Token / Both | Selects UI auth fixture in conftest |
| `reporting` | Allure / ReportPortal / HTML / JUnit / None | Selects reporting config |
| `ci_platform` | GitHub / GitLab / Jenkins / Azure / None | Selects CI workflow template |
| `secret_mode` | .env / Vault / CI / None | Adds notes to .env.example |
| `pattern_list` | [+]/[~]/[-] per pattern | Controls which files are generated |

---

## 4. Outputs

| File | Layer | Condition |
|------|-------|-----------|
| `layer_1_models/api/user_model.py` | 1 | API or Full-Stack |
| `layer_1_models/api/error_model.py` | 1 | API or Full-Stack |
| `layer_1_models/api/factories/user_factory.py` | 1 | Always (API or Full-Stack) |
| `layer_1_models/ui/locators/login_locators.py` | 1 | UI or Full-Stack |
| `layer_1_models/ui/locators/dashboard_locators.py` | 1 | UI or Full-Stack |
| `layer_1_models/ui/form_data/login_form_data.py` | 1 | UI or Full-Stack |
| `layer_2_clients/api/base_api_client.py` | 2 | API or Full-Stack |
| `layer_2_clients/api/real_api_client.py` | 2 | mock_mode = C (Both) |
| `layer_2_clients/api/mock_api_client.py` | 2 | mock_mode = B or C |
| `config/client_factory.py` | 2 | mock_mode = B or C |
| `layer_2_clients/ui/browser_session.py` | 2 | UI or Full-Stack |
| `layer_3_services/user_service.py` | 3 | API or Full-Stack |
| `layer_3_pages/login_page.py` | 3 | UI or Full-Stack |
| `layer_3_pages/dashboard_page.py` | 3 | UI or Full-Stack |
| `layer_3_pages/components/header_component.py` | 3 | UI or Full-Stack |
| `layer_4_tests/api/test_user_api.py` | 4 | API or Full-Stack |
| `layer_4_tests/ui/test_login_flow.py` | 4 | UI or Full-Stack |
| `config/env_config.py` | Cross | Always |
| `config/logger.py` | Cross | Always |
| `config/auth_manager.py` | Cross | auth_type != None |
| `conftest.py` | Cross | Always |
| `pytest.ini` | Cross | Always |
| `.importlinter` | Cross | Always |
| `requirements.txt` | Cross | Always |
| `.env.example` | Cross | Always |
| `docker-compose.yml` | Cross | mock_mode = B or C |
| `.github/workflows/api-tests.yml` | CI | GitHub Actions + API |
| `.github/workflows/ui-tests.yml` | CI | GitHub Actions + UI |

---

## 5. Logic Blocks

---

### Block 1 — Profile Loading

**Trigger:** Skill is invoked by orchestrator with resolved config.

**Purpose:** Determine which reference files to load before generating any code. Wrong profile loading = wrong files generated.

**Logic:**

```
test_type = "api":
    Load: references/api/layer1-pydantic-models.md
          references/api/layer2-requests-client.md
          references/api/layer3-services.md
          references/api/layer4-pytest-api-tests.md
          references/api/patterns/singleton-auth.md     (if auth != none)
          references/api/patterns/factory-data.md       (always)
          references/shared/env-pydantic-settings.md
          references/shared/logger.md
          references/shared/test-data-factories.md
          references/shared/allure-pytest-config.md     (if reporting = Allure)

test_type = "ui":
    Load: references/ui/layer1-locators.md
          references/ui/layer2-browser-session.md
          references/ui/layer3-page-objects.md
          references/ui/layer4-pytest-ui-tests.md
          references/ui/patterns/page-component.md
          references/ui/patterns/singleton-driver.md
          references/shared/env-pydantic-settings.md
          references/shared/logger.md
          references/shared/allure-pytest-config.md     (if reporting = Allure)

test_type = "full-stack":
    Load: all api references + all ui references + all shared references
```

**Output:** All relevant reference file contents loaded into context for generation.

---

### Block 2 — Layer 1: API Models (Pydantic v2)

**Reference:** `references/api/layer1-pydantic-models.md`

**Files generated:**
```
layer_1_models/api/user_model.py
layer_1_models/api/error_model.py
layer_1_models/api/factories/user_factory.py
```

**What each file contains:**

**`user_model.py`** — Three Pydantic v2 model classes:
```
CreateUserRequest  → request payload model with field_validators
UserResponse       → typed response model (id, username, email, role, timestamps)
UserListResponse   → paginated list wrapper (items, total, page, page_size)
```

Key implementation rules enforced:
- `field_validator` (v2 syntax) — not deprecated `@validator`
- `model_dump()` — not deprecated `.dict()`
- `EmailStr` from `pydantic[email]` for automatic email validation
- `str | None` union syntax (Python 3.10+). Falls back to `Optional[str]` for 3.9
- **Zero imports from Layer 2, 3, or 4** — dependency direction enforced

**`error_model.py`** — `ApiErrorResponse` model for typed 4xx/5xx error assertions:
```python
class ApiErrorResponse(BaseModel):
    error: str
    code: str | None = None
    details: dict | None = None
    request_id: str | None = None
```
Used in Layer 4 tests: `error = ApiErrorResponse(**resp.json()); assert error.code == "USER_NOT_FOUND"`

**`user_factory.py`** — `UserFactory` with static methods:
```
.build(**overrides)           → randomized valid payload, supports field pinning
.build_admin()                → role="admin" variant
.build_editor()               → role="editor" variant
.build_minimal()              → required fields only
.build_invalid_email()        → deliberately invalid email for negative tests
.build_invalid_role()         → deliberately invalid role for negative tests
.build_batch(count, **overrides) → N payloads for list endpoint tests
```
Uses Faker with `Faker.seed(0)` for reproducible data by default.

**Naming conventions enforced:**

| Concept | Pattern | Example |
|---------|---------|---------|
| Request model | `{Resource}Request` | `CreateUserRequest` |
| Response model | `{Resource}Response` | `UserResponse` |
| List response | `{Resource}ListResponse` | `UserListResponse` |
| Error response | `ApiErrorResponse` | shared across all resources |
| Factory class | `{Resource}Factory` | `UserFactory` |
| File | `{resource}_model.py` | `user_model.py` |

---

### Block 3 — Layer 2: HTTP Client (requests)

**Reference:** `references/api/layer2-requests-client.md`

**Files generated:**
```
layer_2_clients/api/base_api_client.py
layer_2_clients/api/real_api_client.py    (only if mock_mode = C)
layer_2_clients/api/mock_api_client.py    (only if mock_mode = B or C)
config/client_factory.py                  (only if mock_mode = B or C)
```

**`base_api_client.py`** — Core HTTP client wrapping `requests.Session`:

```
Session setup:
  - Content-Type and Accept headers set to application/json
  - Auth token injected as Bearer header (if provided)
  - Retry strategy via urllib3.util.retry.Retry:
      total=3, backoff_factor=0.3
      status_forcelist=[500, 502, 503, 504]
      allowed_methods=all HTTP verbs
      raise_on_status=False  ← critical: allows Layer 4 to test error responses
  - Response logging hook: _log_response() fires after every response

Exposes: get(), post(), put(), patch(), delete()
  Each appends endpoint to self.base_url from settings.
```

**`_log_response()` — Decorator(Logging) pattern:**
```
At INFO:  method + URL + status code + elapsed ms
At DEBUG: first 500 chars of response body (controlled by LOG_LEVEL env var)
Never:    Authorization header value, request body at INFO, PII fields
```

**`real_api_client.py` / `mock_api_client.py` — Strategy(Mock) pattern:**
```
RealApiClient  → extends BaseApiClient, base_url = settings.base_url (real service)
MockApiClient  → extends BaseApiClient, base_url = "http://localhost:8080" (WireMock)
               → adds X-Test-Mode: mock header for WireMock routing

ClientFactory.build(token) → reads TEST_MODE env var → returns Real or Mock instance
  TEST_MODE=real  → RealApiClient
  TEST_MODE=mock  → MockApiClient
  other value     → raises ValueError with clear message
```

**Key design rules enforced:**
- Auth token is **passed in**, never fetched inside the client (AuthManager stays separate)
- `raise_for_status()` is **not** called automatically — Layer 3 calls it per method
- 4xx errors are **not** retried (only 5xx + connection errors)
- Authorization header value is **never** logged

---

### Block 4 — Layer 3: Services (API)

**Reference:** `references/api/layer3-services.md`

**Files generated:**
```
layer_3_services/user_service.py
```

**`user_service.py`** — `UserService` class owning the User resource domain:

```
Methods:
  create_user(payload: CreateUserRequest) → UserResponse
  get_user(user_id: int) → UserResponse
  list_users(page, page_size) → UserListResponse
  update_user(user_id, payload) → UserResponse
  delete_user(user_id) → None
  get_user_raw_response(user_id) → requests.Response  ← escape hatch
```

**`get_user_raw_response()` escape hatch** — The only method that returns a raw `requests.Response`. Used when Layer 4 needs to assert on HTTP headers, timing, or status codes directly without going through model deserialization. Every service has exactly one of these.

**Design rules enforced in every service method:**
```
Rule 1: Typed in, typed out
  Inputs are model objects (CreateUserRequest), not raw dicts.
  Outputs are model objects (UserResponse), not raw responses.

Rule 2: model_dump(exclude_none=True)
  Optional fields with None values are excluded from the request body.
  Prevents APIs rejecting null for optional fields.
  Switch to exclude_unset=True if API distinguishes "not sent" vs "explicit null".

Rule 3: raise_for_status() in service, not in client
  Allows Layer 4 to catch HTTPError for 4xx/5xx negative test scenarios:
    with pytest.raises(requests.HTTPError) as exc:
        user_service.create_user(invalid_payload)
    assert exc.value.response.status_code == 400

Rule 4: One service class per resource domain
  UserService owns only User operations.
  OrderService, ProductService etc. each live in their own file.
  No cross-resource operations in a single service class.
```

---

### Block 5 — Layer 1: UI Locators & Form Data

**Reference:** `references/ui/layer1-locators.md`

**Files generated:**
```
layer_1_models/ui/locators/login_locators.py
layer_1_models/ui/locators/dashboard_locators.py
layer_1_models/ui/form_data/login_form_data.py
```

**Design principle:** Locator strings live in Layer 1 as named constants, not inside page object methods. This means:
- Changing a locator = edit one file, not hunt through page objects
- Locators are reviewable and version-controlled independently
- Page objects reference `self._loc.USERNAME_INPUT`, not raw strings

**`login_locators.py` / `dashboard_locators.py`** — `@dataclass(frozen=True)` classes:
```
Locator strategy determines the string format generated:

data-testid → "[data-testid='login-username']"   (default, recommended)
CSS         → "input[name='username']"
XPath       → "//input[@name='username']"
Role-based  → stores label strings used with page.get_by_role() / get_by_label()
              (different usage pattern in page objects — handled in Block 7)
Mixed       → combination at team discretion — scaffold uses data-testid as default
```

**`login_form_data.py`** — `LoginFormData` dataclass + factory:
```
LoginFormData(username, password)
  .build(username, password)          → valid credentials
  .build_invalid_password(username)   → wrong password for negative tests
  .build_empty()                      → empty fields for validation tests
```
Decouples form data from page interaction — same principle as API factories.

---

### Block 6 — Layer 2: Browser Session (Playwright)

**Reference:** `references/ui/layer2-browser-session.md`

**Files generated:**
```
layer_2_clients/ui/browser_session.py
conftest.py  (UI fixture section — appended or merged)
```

**`browser_session.py`** — `BrowserSession` class implementing ThreadLocal Singleton:

```
Lifecycle model:
  Playwright instance  → one per process (class-level)
  Browser instance     → one per process, reused across tests (class-level)
  BrowserContext       → one per test — isolated (cookies, storage, auth state)
  Page                 → one per test — clean browser tab

get_browser() class method:
  Uses threading.Lock for thread safety.
  Reads settings.browser (chromium/firefox/webkit) via getattr() on playwright instance.
  Fails fast with ValueError if BROWSER value is unsupported.
  Launches with headless=settings.headless and slow_mo=settings.slow_mo_ms.

new_context(storage_state=None):
  Creates isolated BrowserContext per test.
  Accepts optional storage_state path for session reuse (skip login flow).
  Sets base_url, viewport (1920×1080), optional video recording.
  Sets default timeout and navigation timeout from settings.

new_page(context):
  Creates a new Page within the context.
  Attaches pageerror listener — browser console errors are logged.

teardown():
  Closes browser + stops Playwright. Called in session fixture teardown.
```

**conftest.py UI fixtures** — fixture scope strategy:

```
browser_instance  → session scope  (browser starts once per run)
browser_context   → function scope (fresh cookies/storage per test — isolation)
page              → function scope (clean tab per test)
authenticated_state → session scope  (one login per run, saves auth-state.json)
authenticated_context → function scope (context with pre-loaded auth state)
authenticated_page → function scope (logged-in page per test, no login flow)

Screenshot on failure hook:
  pytest_runtest_makereport() fires on test failure.
  Captures full-page screenshot.
  Attaches to Allure report as PNG (if Allure selected).
```

**`authenticated_page` vs `page`:**
```
Use `page`              → for tests that test the login flow itself
Use `authenticated_page` → for tests that need to be logged in but don't test login
                           (skip the login form, reuse saved auth state — fast)
```

---

### Block 7 — Layer 3: Page Objects (Playwright)

**Reference:** `references/ui/layer3-page-objects.md`

**Files generated:**
```
layer_3_pages/login_page.py
layer_3_pages/dashboard_page.py
layer_3_pages/components/header_component.py
```

**Design rules enforced in every page object:**

```
Rule 1: No locator strings in page object methods
  All locators come from Layer 1 Locators classes.
  self._loc = LoginLocators() in __init__, then self._loc.USERNAME_INPUT in methods.

Rule 2: No assertions in page objects
  Methods return data (str, bool) or the next page object.
  Layer 4 receives the data and asserts.

Rule 3: Fluent returns
  Methods that navigate away return the destination page object.
  Methods that stay on the same page return self.
  Example: login_as() returns DashboardPage, login_and_expect_error() returns LoginPage.

Rule 4: Business action names
  login_as() not fill_username_and_click_submit()
  logout() not click_nav_profile_then_click_logout()

Rule 5: Built-in waits, never time.sleep()
  page.wait_for_url(), locator.wait_for(state="visible") — Playwright auto-waiting.
  time.sleep() anywhere in Layer 3 is wrong.

Rule 6: Constructor receives a Page object
  Page objects never create browser instances. BrowserSession is Layer 2.
```

**Circular import handling:**
```
LoginPage.login_as() needs to return DashboardPage.
DashboardPage.get_header() needs to return HeaderComponent.
HeaderComponent.logout() needs to return LoginPage.

Solution: inline import at the return point (inside the method body).
This is the accepted Python pattern for circular page object references.
```

**`login_and_expect_error()` vs `login_as()`:**
```
login_as(form_data)              → expects success, waits for URL change
                                   raises PlaywrightTimeoutError if login fails

login_and_expect_error(form_data) → expects failure, waits for error message
                                    returns self (stays on login page)
                                    caller calls get_error_message() to assert
```

---

### Block 8 — Layer 4: API Tests (pytest)

**Reference:** `references/api/layer4-pytest-api-tests.md`

**Files generated:**
```
layer_4_tests/api/test_user_api.py
conftest.py  (API fixture section — written or merged)
pytest.ini
```

**`test_user_api.py`** — Three test classes with clear scope separation:

```
TestUserCreation     → POST /users (happy path + invalid email + missing field)
TestUserRetrieval    → GET /users/{id} (existing user + not-found 404)
TestUserParametrized → Role boundary values via @pytest.mark.parametrize
```

**Fixture wiring in conftest.py:**

```
auth_manager  → session scope  (one AuthManager instance per run)
auth_token    → session scope  (auth_manager.get_token() — called once)
api_client    → session scope  (ClientFactory.build() — one session per run)
user_service  → function scope (new UserService per test — stateless wrapper)
user_factory  → function scope (returns UserFactory class — fresh Faker per test)
created_user  → function scope (creates a real user via API — for GET/UPDATE/DELETE tests)
```

**Why `user_service` is function-scoped when `api_client` is session-scoped:**
```
api_client   = expensive to create (Session, retry setup, auth header injection)
user_service = cheap to create (just wraps the client)
Function-scoped service ensures no state leaks between tests without re-creating the client.
```

**Allure decorators pattern in every test class:**
```
@allure.feature("User Management")  → class-level grouping in report
@allure.story("Create user")        → method-level sub-grouping
@allure.severity(CRITICAL/NORMAL)   → severity level
with allure.step("...")             → step blocks visible in report timeline
```

**Negative test pattern (testing 4xx responses):**
```python
with pytest.raises(requests.HTTPError) as exc_info:
    user_service.create_user(invalid_payload)
assert exc_info.value.response.status_code == 400
```
`raise_for_status()` is in the service layer — this is why it works cleanly.

**pytest markers used:**
```
smoke      → core happy path, run on every commit
regression → full suite, run on PRs and nightly
api        → API tests only (use -m api to run subset)
ui         → UI tests only
slow       → tests > 10s
wip        → excluded from CI
edge_case  → PRD ambiguity tests (added via edge-case integration)
```

---

### Block 9 — Layer 4: UI Tests (pytest + Playwright)

**Reference:** `references/ui/layer4-pytest-ui-tests.md`

**Files generated:**
```
layer_4_tests/ui/test_login_flow.py
conftest.py  (UI fixtures section — appended)
```

**`test_login_flow.py`** — Two test classes:
```
TestLoginFlow        → E2E flows: valid login, invalid password, empty fields, logout
TestLoginParametrized → Field validation messages via @pytest.mark.parametrize
```

**Key UI testing rules enforced in generated code:**
```
Rule 1: No raw locator strings in test files
  Tests only interact through page object methods.
  login_page.login_as(form_data) — not page.locator("[data-testid='submit']").click()

Rule 2: No time.sleep()
  Playwright auto-waits. Any forced sleep = fragile test.

Rule 3: Allure steps wrap business actions, not individual Playwright calls
  with allure.step("Submit valid credentials"):  ← one step per business action
      dashboard = login_page.login_as(form_data)

Rule 4: Use authenticated_page for tests that don't test login
  Saves a login round-trip per test. One session-scoped login generates auth-state.json.
  All tests using authenticated_page reuse it.
```

---

### Block 10 — Cross-Cutting: Environment Config

**Reference:** `references/shared/env-pydantic-settings.md`

**Files generated:**
```
config/env_config.py
.env.example
```

**`env_config.py`** — `EnvConfig(BaseSettings)` class:

```
Loaded from: environment variables (priority 1) → .env file (priority 2)

Fields with NO defaults (fail-fast if missing):
  base_url       → required API base URL
  (secrets are also required but per auth_type selection)

Fields with defaults (safe to omit):
  test_mode      = "mock"      → tested by validator
  max_retries    = 3
  log_level      = "INFO"      → tested by validator
  browser        = "chromium"  → tested by validator
  headless       = True
  (all operational/non-secret settings)

Validators:
  test_mode_must_be_valid  → must be "real" or "mock"
  browser_must_be_valid    → must be chromium/firefox/webkit
  log_level_must_be_valid  → must be DEBUG/INFO/WARNING/ERROR/CRITICAL
```

**Why secrets have no defaults:**
```
If TOKEN_URL is missing, pydantic raises ValidationError at collection time.
This means: wrong config = zero tests run, not N tests fail mid-suite.
Fail fast before any test runs → clear error message → faster debugging.
```

**Module-level singleton:**
```python
settings = EnvConfig()  # loaded once at import time
```
Imported everywhere as `from config.env_config import settings`. No repeated disk reads.

**.env.example** — documents every environment variable with comments. Users copy this to `.env` and fill in real values. Secrets are empty by default (`CLIENT_SECRET=`), never contain placeholder strings that could accidentally be committed.

---

### Block 11 — Cross-Cutting: Logger

**Reference:** `references/shared/logger.md`

**Files generated:**
```
config/logger.py
```

**`logger.py`** — `get_logger(name)` factory function:

```
Usage: logger = get_logger(__name__)
       Passes module name → creates logger hierarchy mirroring package structure.

Handler check:
  if logger.handlers: return logger
  Prevents duplicate handlers when get_logger() is called multiple times for the same module.

Format: "YYYY-MM-DD HH:MM:SS | LEVEL    | module.name | message"
Level:  Controlled by LOG_LEVEL env var via settings (default: INFO).
propagate = False → prevents double-logging if root logger also has handlers.
```

**What to log and where (enforced):**

| Layer | Log? | Content |
|-------|------|---------|
| Layer 2 (BaseApiClient) | Yes | method, URL, status, elapsed ms (INFO); body (DEBUG, truncated 500 chars) |
| Layer 2 (BrowserSession) | Yes | browser launch, context events, teardown |
| config/AuthManager | Yes | token fetch events (never credential values) |
| Layer 3 (Services/Pages) | Rarely | only retry or exceptional conditions |
| Layer 4 (Tests) | Never | tests assert, never log |

**What is never logged, regardless of LOG_LEVEL:**
- `Authorization` header value
- `client_secret`, `api_key`, `api_token` values
- User PII in request or response bodies

---

### Block 12 — Cross-Cutting: Auth Manager

**Reference:** `references/api/patterns/singleton-auth.md`

**Files generated:**
```
config/auth_manager.py  (variant selected by auth_type)
```

**Three variants — selected by `auth_type`:**

**Variant A — OAuth2 Client Credentials (full Singleton with TTL):**
```
Double-checked locking Singleton:
  _instance checked outside lock (performance — avoids lock on every call)
  _instance checked again inside lock (thread-safety — handles race condition)

get_token() flow:
  1. Acquire lock
  2. Check if token is expired (_expires_at - 30s buffer)
  3. If expired → call _refresh() → POST to token_url
  4. Store token + expires_at (time.time() + expires_in, default 3600)
  5. Return token

Security rules:
  - client_id and client_secret never passed to logger
  - token value itself never logged
  - Token request has 10s timeout (no infinite hangs)
  - expires_in fallback = 3600 if missing from response

invalidate() method:
  Forces token refresh on next get_token() call.
  Used in tests that need to verify token expiry behavior.
```

**Variant B — Bearer / JWT (static token):**
```
Simple Singleton (no TTL needed).
get_token() returns settings.api_token directly.
No network call, no expiry management.
```

**Variant C — API Key:**
```
Simple Singleton.
get_api_key() / get_token() returns settings.api_key.
BaseApiClient updated to use X-API-Key header instead of Authorization: Bearer.
```

---

### Block 13 — Cross-Cutting: Allure Reporting Config

**Reference:** `references/shared/allure-pytest-config.md`

**Files generated:**
```
pytest.ini  (updated with --alluredir=allure-results)
requirements.txt  (allure-pytest>=2.13.5 added)
```

**Allure annotation hierarchy:**
```
@allure.feature("User Management")   → test class level — top grouping in report
@allure.story("Create user")         → test method level — sub-grouping
@allure.severity(CRITICAL)           → priority: BLOCKER > CRITICAL > NORMAL > MINOR > TRIVIAL
@allure.title("...")                 → custom test name in report
with allure.step("...")              → visible step in report timeline

allure.attach(data, name, type)      → attach response payloads, screenshots, logs
```

**Severity guide:**
```
BLOCKER  → failure blocks release. Core auth, critical data paths.
CRITICAL → major bug. Core happy paths. Smoke tests.
NORMAL   → standard feature behavior. Default.
MINOR    → edge case or cosmetic issue.
TRIVIAL  → informational. Lowest priority.
```

**Run and view:**
```bash
pytest layer_4_tests/ -v                  # run + write allure-results/
allure serve allure-results/              # interactive local report
allure generate allure-results/ --clean   # static HTML for artifact sharing
```

**CI artifact upload (GitHub Actions):**
```yaml
- uses: actions/upload-artifact@v4
  with:
    name: allure-results-${{ github.run_number }}
    path: allure-results/
    retention-days: 30
```
For trend history across runs: `simple-elf/allure-report-action@master` with `allure_history`.

---

### Block 14 — File Generation Order & Code Style Rules

**File generation order:**

```
Always first:
  1. requirements.txt
  2. pytest.ini
  3. .importlinter
  4. .env.example
  5. config/env_config.py
  6. config/logger.py
  7. config/auth_manager.py         (if auth != none)
  8. conftest.py                    (skeleton — updated in layers below)
  9. docker-compose.yml             (if mock selected)

API profile (in order):
  10. layer_1_models/api/user_model.py
  11. layer_1_models/api/error_model.py
  12. layer_1_models/api/factories/user_factory.py
  13. layer_2_clients/api/base_api_client.py
  14. layer_2_clients/api/real_api_client.py   (if mock=C)
  15. layer_2_clients/api/mock_api_client.py   (if mock=B or C)
  16. config/client_factory.py                  (if mock=B or C)
  17. layer_3_services/user_service.py
  18. layer_4_tests/api/test_user_api.py

UI profile (in order):
  19. layer_1_models/ui/locators/login_locators.py
  20. layer_1_models/ui/locators/dashboard_locators.py
  21. layer_1_models/ui/form_data/login_form_data.py
  22. layer_2_clients/ui/browser_session.py
  23. layer_3_pages/login_page.py
  24. layer_3_pages/dashboard_page.py
  25. layer_3_pages/components/header_component.py
  26. layer_4_tests/ui/test_login_flow.py

Always last:
  27. CI workflow file(s) based on ci_platform
  28. README.md
```

**Python code style rules (enforced in every generated file):**

```
Type hints:     Required on all function signatures (parameters + return types)
Pydantic v2:    model_dump() not .dict(), field_validator not @validator
String format:  f-strings only — no % or .format()
Logging:        Use logger, never print()
Naming:         Classes = PascalCase, methods/vars = snake_case, constants = UPPER_SNAKE
Imports:        stdlib → third-party → local (isort order)
Tests:          All test methods start with test_, all test classes start with Test
Exceptions:     No bare except: — always catch specific exceptions
Line length:    88 chars (Black default) — use line continuation for long chains
```

---

## 6. Integration Map

```
automation-architect-python
  │
  ├── receives from ── automation-architect (orchestrator)
  │                    resolved_config + pattern_list
  │
  ├── reads ─────────── references/api/layer1-pydantic-models.md
  │                     references/api/layer2-requests-client.md
  │                     references/api/layer3-services.md
  │                     references/api/layer4-pytest-api-tests.md
  │                     references/api/patterns/singleton-auth.md
  │                     references/api/patterns/factory-data.md
  │                     references/ui/layer1-locators.md
  │                     references/ui/layer2-browser-session.md
  │                     references/ui/layer3-page-objects.md
  │                     references/ui/layer4-pytest-ui-tests.md
  │                     references/ui/patterns/page-component.md
  │                     references/ui/patterns/singleton-driver.md
  │                     references/shared/env-pydantic-settings.md
  │                     references/shared/logger.md
  │                     references/shared/test-data-factories.md
  │                     references/shared/allure-pytest-config.md
  │
  └── does NOT invoke ── automation-architect-mock (orchestrator does this separately)
                         automation-architect-nfr (Phase 2 only)
```

---

## 7. Reference Files

| File | Block | Purpose |
|------|-------|---------|
| `api/layer1-pydantic-models.md` | Block 2 | Pydantic v2 model classes: request, response, list, error. Naming conventions. |
| `api/layer2-requests-client.md` | Block 3 | BaseApiClient, Real/Mock variants, ClientFactory (Strategy). Auth injection, retry, logging rules. |
| `api/layer3-services.md` | Block 4 | UserService with typed in/out methods. raise_for_status() placement. Escape hatch pattern. |
| `api/layer4-pytest-api-tests.md` | Block 8 | Test classes, conftest fixtures, fixture scoping table, Allure annotations, negative test pattern. |
| `api/patterns/singleton-auth.md` | Block 12 | All three AuthManager variants: OAuth2 CC (with TTL + threading), Bearer, API Key. |
| `api/patterns/factory-data.md` | Block 2 | UserFactory with Faker, .build(**overrides), named variants. Faker seed strategy. |
| `ui/layer1-locators.md` | Block 5 | Locator dataclasses for data-testid/CSS/Role-based strategies. LoginFormData factory. |
| `ui/layer2-browser-session.md` | Block 6 | BrowserSession ThreadLocal Singleton. Context/page lifecycle. conftest UI fixtures. Screenshot hook. |
| `ui/layer3-page-objects.md` | Block 7 | LoginPage, DashboardPage, HeaderComponent. Fluent returns. Circular import handling. |
| `ui/layer4-pytest-ui-tests.md` | Block 9 | UI test classes, authenticated_page vs page, parametrized tests, Playwright testing rules. |
| `ui/patterns/page-component.md` | Block 7 | Component pattern: shared UI elements (header, nav, modal) as separate classes. |
| `ui/patterns/singleton-driver.md` | Block 6 | ThreadLocal browser details and parallel execution guidance. |
| `shared/env-pydantic-settings.md` | Block 10 | EnvConfig full field list, validators, fail-fast design, .env.example. |
| `shared/logger.md` | Block 11 | get_logger() factory, what/where to log, PII and credential logging rules. |
| `shared/test-data-factories.md` | Block 2 | Additional factory patterns and Faker usage guidance. |
| `shared/allure-pytest-config.md` | Block 13 | Annotations, severity guide, run/view commands, CI artifact upload. |

---

## 8. Design Decisions Log

| # | Decision | Options Considered | Chosen | Rationale | Trade-offs |
|---|----------|--------------------|--------|-----------|------------|
| D1 | Pydantic v2 (not v1) | pydantic v1, v2, marshmallow, dataclasses | **Pydantic v2** | ~2× faster than v1, `field_validator` is cleaner than `@validator`, `model_dump()` is explicit. v2 is the current standard. | v2 syntax (`field_validator`, `model_dump()`) differs from v1 — users upgrading existing projects need to update. |
| D2 | Locators in Layer 1 (not in page objects) | Strings inside page object methods, constants in page object class, separate Layer 1 file | **Separate Layer 1 file** | Locators are data — they belong in the data/model layer. A CSS selector is not business logic. Separating them makes locator changes a 1-file edit. | More files. Worth it: locator changes are the single most common UI maintenance task. |
| D3 | ThreadLocal Singleton for BrowserSession | Classic Singleton (one global browser), new browser per test, pytest-playwright's fixture | **ThreadLocal Singleton** | Classic Singleton fails for parallel test execution — threads share state. New browser per test is too slow. ThreadLocal gives one browser per thread — safe for both sequential and parallel. | Slightly more complex setup code. The class handles it — test code is unaffected. |
| D4 | `raise_for_status()` in Layer 3, not Layer 2 | Raise in client (always), raise in service (per method), raise in test (manual) | **Raise in Layer 3 service methods** | Layer 4 tests for 4xx/5xx scenarios need to receive the response without an exception first. If the client raises, negative tests become awkward. Layer 3 raises for happy-path methods; `get_raw_response()` escape hatch for negative tests. | Service methods look slightly more verbose (one extra line). Justified by cleaner test code. |
| D5 | Double-checked locking in AuthManager | Single lock (always), no lock (not thread-safe), double-checked lock | **Double-checked locking** | The outer `if cls._instance is None` check avoids acquiring the lock on every call (hot path performance). The inner check inside the lock handles the race condition where two threads both pass the outer check simultaneously. | Slightly complex to read. The pattern is well-established in Python concurrency. |
| D6 | `Faker.seed(0)` as default | No seed (fully random), fixed seed, per-test seed (request.node lineno) | **Fixed seed 0 as default, with comment** | Reproducible data means failures are reproducible. The same test run generates the same data — easier to debug. Comment tells users how to remove the seed for fuzzing behavior. | Same data every run may miss some edge cases. Mitigated by PRD-driven edge-case tests, which cover the specific inputs that matter. |
| D7 | `authenticated_page` fixture using `storage_state` | Re-login for each test, session-scoped login + reuse, token injection | **Session-scoped login + storage_state reuse** | One login per test run is expensive (network round-trip + page load per test). Playwright's `storage_state` saves cookies + localStorage after one login. All tests sharing `authenticated_page` reuse it — zero login overhead. | The saved auth state can expire. Tests using `authenticated_page` will fail if the state expires mid-run. Mitigated by short-lived states in CI; local runs rarely hit this. |
| D8 | Screenshot on failure via `pytest_runtest_makereport` hook | Manual screenshot in each test, global fixture with yield + screenshot on failure, hookimpl | **`pytest_runtest_makereport` hookimpl** | The hook fires after every test call, checks `rep.failed`, and attaches the screenshot automatically. Zero changes needed in any test file. Attaches directly to Allure as PNG. | None significant. This is the standard Pytest+Allure pattern. |
| D9 | `pydantic-settings` for environment config | `python-dotenv` + `os.environ`, `dynaconf`, `pydantic-settings` | **pydantic-settings** | Same ecosystem as model validation. Gets type coercion for free (`HEADLESS=true` → Python `True`). Field validators can validate env var values at startup. `extra="ignore"` prevents failures from CI-injected env vars. | Requires `pydantic-settings` as an additional dependency. Minimal overhead for the value delivered. |

---

## 9. Known Limitations & Open Questions

| # | Item | Type | Status |
|---|------|------|--------|
| L1 | Role-based locators (Playwright aria) use a different API pattern (`get_by_role()`, `get_by_label()`) than CSS/data-testid (`page.locator()`). The page object generation handles this but it is more complex than other strategies. | Limitation | Known. Role-based strategy works but generates more complex page object code. |
| L2 | The `authenticated_state` fixture uses hardcoded credentials (`test@example.com`, `ValidPass123!`). Users must update these in conftest.py after scaffold generation. | Limitation | Known. After scaffold, the README will instruct users to replace with real test credentials from `.env`. |
| L3 | `pytest-xdist` (parallel execution) is listed as an optional dependency but the scaffold does not configure it by default. ThreadLocal BrowserSession supports it, but `conftest.py` is written for sequential execution. | Limitation | Offered on-demand if user mentions parallel execution. Not generated by default — avoids confusing scope/ordering issues for new users. |
| L4 | ReportPortal setup requires an RP server running and a UUID API key. The generated config is correct but requires additional user setup that the scaffold cannot automate. | Limitation | README includes RP setup instructions. Phase 4 execution step will detect missing RP config and provide guidance. |
| O1 | Add a `test_data_factories.md` shared reference that covers `build_batch()`, `build_for_parametrize()`, and seeding strategies more deeply. | Open | Low priority. Current factory coverage is sufficient for scaffolding. |

---

## 10. Change History

| Date | Version | Change | Reason |
|------|---------|--------|--------|
| 2026-04-24 | 1.0.0 | Initial Python track created | Pytest + Pydantic + requests + Playwright scaffold |
| 2026-04-24 | 2.0.0 | Added UI profile, Singleton(Driver), Page Component pattern | Full-Stack support added |
| 2026-05-02 | 2.0.0 | DESIGN.md created | Design documentation for all 14 logic blocks, 9 design decisions, reference map |

---

### Block 15 — Edge-Case Tests (PRD-Driven)

**Purpose:** Generate parametrized tests from PRD ambiguities. These tests are expected
to fail until the PRD is clarified — failures are signal, not bugs.

**Reference file:** `references/edge-case-tests-pytest.md`
(merged from standalone automation-architect-edge-cases skill, 2026-05-04)

**Generated files (alongside standard scaffold):**

```
layer_4_tests/
└── test_{resource}_edge_cases.py      ← parametrized edge-case tests
{resource}_edge_case_models.py         ← edge-case data builders in Layer 1

EDGE_CASES.md                          ← PRD ambiguities mapped to test cases (P0/P1/P2)
PRD_CLARIFICATION_CHECKLIST.md         ← P0 items requiring PRD updates
```

**10 test patterns (full code in reference file):**

| Pattern | What it covers | pytest markers |
|---------|---------------|----------------|
| 1 | Input validation — email format ambiguity | `edge_case`, `validation` |
| 2 | Boundary values — min/max length undefined | `edge_case`, `boundaries` |
| 3 | Concurrency — duplicate email race condition | `edge_case`, `concurrency` |
| 4 | State transitions — which role changes are valid | `edge_case`, `regression` |
| 5 | Authorization — role-based permission boundaries | `edge_case`, `security` |
| 6 | Error response consistency — error code format | `edge_case`, `error_handling` |
| 7 | Idempotence — POST/DELETE duplicate behavior | `edge_case`, `idempotence` |
| 8 | Pagination — page 0, negative, oversized page | `edge_case`, `pagination` |
| 9 | Fixtures — `created_user`, `api_client_factory` | (supporting patterns) |
| 10 | Marker organization — run/exclude edge cases | (pytest.ini config) |

**pytest marker additions to `pytest.ini`:**

```ini
markers =
    edge_case:     mark test as an edge-case test (PRD ambiguity exposure)
    validation:    input validation edge cases
    boundaries:    boundary value testing
    concurrency:   concurrency and race condition tests
    security:      authorization and security edge cases
    error_handling: error scenario coverage
    idempotence:   idempotence testing
    pagination:    pagination edge cases
```

**Run commands:**

```bash
# Run all edge-case tests
pytest -m edge_case

# Run only critical (P0) edge cases
pytest -m "edge_case and p0"

# Run specific category
pytest -m "edge_case and validation"

# Run all tests except edge cases (CI happy-path only)
pytest -m "not edge_case"

# Run happy-path + edge cases together (Phase 4 default)
pytest layer_4_tests/ -v --tb=short -m "api or ui or edge_case" \
  --alluredir=allure-results/
```

**Why edge-case tests are expected to fail:**
Tests are generated from PRD gaps — cases where the spec is silent or ambiguous.
A failing edge-case test is a valid finding: "this scenario is not covered by the PRD".
Use EDGE_CASES.md to map each failing test back to the ambiguity, then use the failures
as input for PRD clarification meetings. Once the PRD is updated, update the test
expectation to match and the test will pass.

**Ambiguity priority levels:**

| Level | Label    | Meaning                                       |
|-------|----------|-----------------------------------------------|
| P0    | Critical | Ambiguity could cause data loss or security issue |
| P1    | High     | Ambiguity causes inconsistent user experience |
| P2    | Medium   | Ambiguity is cosmetic or low-impact           |

Run P0 tests first: `pytest -m "edge_case and p0"` — these are the must-clarify items.
