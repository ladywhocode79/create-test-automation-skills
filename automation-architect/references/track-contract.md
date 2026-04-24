# Track Contract — Universal 4-Layer Interface

Every language track added to the automation-architect skill suite MUST
implement all sections of this contract. This guarantees that users get
an identical conceptual framework and directory shape regardless of
which language they choose.

---

## Directory Shape Contract

Every track MUST generate this directory structure.
Only file extensions and internal syntax change between tracks.

```
{project_root}/
├── layer_1_models/
│   ├── api/                          (if test_type includes API)
│   │   ├── {resource}_model.{ext}    required: at least one resource model
│   │   └── factories/
│   │       └── {resource}_factory.{ext}
│   │   └── builders/                 (optional: activate when payload > 5 fields)
│   │       └── {resource}_builder.{ext}
│   └── ui/                           (if test_type includes UI)
│       ├── locators/
│       │   └── {page}_locators.{ext}
│       └── form_data/
│           └── {page}_form_data.{ext}
│
├── layer_2_clients/
│   ├── api/                          (if test_type includes API)
│   │   └── base_api_client.{ext}
│   └── ui/                           (if test_type includes UI)
│       └── browser_session.{ext}
│
├── layer_3_services/                 (API: one class per resource domain)
│   └── {resource}_service.{ext}
│
├── layer_3_pages/                    (UI: one class per page or major component)
│   ├── {page}_page.{ext}
│   └── components/
│       └── {component}_component.{ext}
│
├── layer_4_tests/
│   ├── api/
│   │   └── test_{resource}_api.{ext}
│   └── ui/
│       └── test_{page}_flow.{ext}
│
├── config/
│   ├── env_config.{ext}              required
│   ├── auth_manager.{ext}            required if auth != none
│   ├── driver_manager.{ext}          required if test_type includes UI
│   └── logger.{ext}                  required
│
├── mocks/                            (if mock != real-only)
│   ├── stubs/
│   │   └── {resource}_stubs.json
│   └── wiremock_lifecycle.{ext}
│
├── .env.example                      required
├── {dependency_file}                 requirements.txt / pom.xml / package.json / go.mod
├── docker-compose.yml                required if mock selected
└── .{ci_platform}/
    └── {pipeline_file}
```

---

## Layer 1 — Data/Model Layer Contract

**API profile must provide:**
- Request model: typed fields, required vs optional, default values
- Response model: typed fields matching the API response schema
- Field-level validation: email format, non-empty strings, value ranges
- Factory: `build(**overrides)` returning a valid request model instance
  - Uses Faker or equivalent for random-but-valid data
  - Accepts keyword overrides so tests can pin specific fields
- Builder (deferred, generate when payload has >5 optional fields):
  - Fluent interface: `with_field(value).build()`
  - Returns a dict/map, not a model object

**UI profile must provide:**
- Locator registry: named constants for every interactive element
  - Organized by page, not scattered across page object methods
  - Locator strategy matches user's Q4 selection
- Form data class: typed fields for every form the tests fill in
  - Factory method for generating valid form data with Faker

**Contract rule**: Layer 1 has NO imports from Layer 2, 3, or 4.
It is pure data — models, validators, factories.

---

## Layer 2 — Client Layer Contract

**API profile must provide:**
- Base HTTP client class wrapping the language's HTTP library
- Constructor reads base_url from env config — never hardcoded
- Session/connection management (reuse connections, don't recreate per request)
- Default headers: Content-Type, Accept
- Auth injection: loads from AuthManager, applied to every request automatically
- Retry logic: configurable attempts and backoff for transient failures (5xx, timeout)
- Response logging hook: logs method, URL, status code at INFO level
  - Does NOT log request bodies or response bodies by default (security)
  - Log bodies only at DEBUG level, controlled by LOG_LEVEL env var
- raise_for_status equivalent: non-2xx responses throw a typed exception

**UI profile must provide:**
- Browser session class managing WebDriver or Playwright browser lifecycle
- Browser type selection from env var (BROWSER=chromium|firefox|safari)
- Headless mode from env var (HEADLESS=true|false)
- Singleton or ThreadLocal pattern:
  - Single-threaded tests: Singleton browser instance
  - Parallel tests: ThreadLocal driver pool (one driver per thread)
- Screenshot on failure: captured automatically in teardown if test fails
- Implicit wait / default timeout from env config (not hardcoded)
- Base URL injected from env config

**Contract rule**: Layer 2 imports from Layer 1 (for models) and Config.
It does NOT import from Layer 3 or Layer 4.

---

## Layer 3 — Service / Page Layer Contract

**API profile (Service classes) must provide:**
- One service class per API resource domain (UserService, OrderService, etc.)
- Constructor accepts a BaseApiClient instance (dependency injection)
- One method per API operation (create_user, get_user, delete_user, etc.)
- Every method:
  - Accepts typed model objects as parameters (not raw dicts)
  - Calls base client session methods
  - Deserializes response into typed response model
  - Returns the typed model object
  - Does NOT contain any assertions or test logic
- HTTP status errors propagate upward to Layer 4 (not swallowed here)

**UI profile (Page Object classes) must provide:**
- One class per page or major reusable component
- Constructor accepts a browser session/driver instance
- Page element references loaded from Layer 1 locator registry
  - Page objects do NOT contain inline locator strings
- Interaction methods:
  - Named after business actions, not element actions
    (login_as(username, password) not click_username_field() then type())
  - Waits are built into interaction methods (explicit waits only, no sleep())
  - Fluent return: return the next page object after navigation
    (login_page.login_as("user", "pass") returns DashboardPage instance)
- Do NOT contain assertions
- Components: shared UI elements (header, nav, modal) in components/ subdirectory

**Contract rule**: Layer 3 imports from Layer 2 and Layer 1.
It does NOT import from Layer 4.

---

## Layer 4 — Test Layer Contract

**API profile must provide:**
- Test classes organized by resource domain and operation type
- Test methods follow Arrange / Act / Assert structure:
  - Arrange: build test data using Layer 1 factories
  - Act: call Layer 3 service methods
  - Assert: assert on properties of the returned model object
- Test methods NEVER call HTTP methods directly
- Test methods NEVER contain locator strings or CSS selectors
- Negative tests: 4xx errors tested alongside happy path
- Parameterized tests for boundary values and equivalence classes
- Tags/markers: smoke, regression, api, and per-resource tags

**UI profile must provide:**
- Test classes organized by user flow (not by page)
- Test methods use Layer 3 page objects exclusively
- No raw browser/driver calls in test files
- No locator strings in test files
- Screenshots attached to report on failure (via reporter hook)
- Tags/markers: smoke, regression, ui, and per-flow tags

**Contract rule**: Layer 4 imports from Layer 3 and Layer 1 only.
It does NOT import from Layer 2 directly.

---

## Cross-Cutting Contract (Config, Auth, Logger)

**Environment Config must:**
- Read ALL external values from environment variables
- Fail fast at startup if required vars are missing (not at first test run)
- Provide typed fields (not raw string access)
- Support .env file loading for local development
- Never contain default values for secrets (only for non-sensitive config like LOG_LEVEL)

**Auth Manager must (if auth != none):**
- Implement Singleton pattern: one instance, one token fetch per session
- Cache token with TTL check: refresh 30 seconds before actual expiry
- Thread-safe if parallel execution is configured
- Read all auth credentials from env config (never hardcoded)

**Driver Manager must (if test_type includes UI):**
- Singleton for sequential execution
- ThreadLocal for parallel execution (one driver per thread)
- quit() / teardown called in fixture/hook, never in test code

**Logger must:**
- Structured format: timestamp | level | module | message
- Level controlled by LOG_LEVEL env var
- Used at Layer 2 for request/response logging only
- Never used directly in Layer 4 test files

---

## CI Pipeline Contract

Every track MUST generate a CI pipeline file that:
- Reads all secrets from the CI platform's secret store (never in YAML)
- Runs API and UI test suites in separate jobs (if Full-Stack)
- Installs browser binaries if test_type includes UI
- Starts WireMock service if mock is selected
- Uploads test report artifacts (allure-results/, screenshots/, etc.)
- Uses `if: always()` on artifact upload so failures still produce reports
- Enforces layer dependency rules via a lint step (import-linter, ArchUnit, etc.)

---

## Track Contribution Guide

To add a new language track to the suite:

1. Create `~/.claude/skills/automation-architect-{language}/SKILL.md`
2. Set `user-invocable: false` in frontmatter (orchestrator invokes it)
3. Create `references/api/`, `references/ui/`, `references/shared/` subdirectories
4. Implement all 4 layers per this contract in the references files
5. The orchestrator will discover the track automatically at next invocation

Naming convention for track IDs: lowercase, hyphenated
  automation-architect-javascript
  automation-architect-go
  automation-architect-csharp
  automation-architect-ruby
