# Pattern Registry — Activation Rules

This file defines which design patterns are included in the scaffold and
under what conditions. The orchestrator reads this after resolving the
user's full config and activates patterns accordingly.

Patterns are never all-or-nothing. Each is independently activated or
deferred based on the resolved config values.

---

## Activation Matrix

```
Pattern              Condition                        Scope         Priority
─────────────────────────────────────────────────────────────────────────────
Singleton (Auth)     auth != "none" AND               API Layer 2   Required
                     auth != "public"                 + Config

Singleton (Driver)   test_type IN [UI, full-stack]    UI Layer 2    Required
                                                      + Config

Factory (API Data)   always included                  Layer 1 API   Required
                     (even inline data needs a        Factories
                      baseline factory)

Factory (UI Forms)   test_type IN [UI, full-stack]    Layer 1 UI    Required
                                                      form_data

Factory (Browser)    test_type IN [UI, full-stack]    Layer 2 UI    Required
                     AND browser_targets > 1          (multi-browser
                                                       factory method)

Builder (Payload)    DEFERRED                         Layer 1 API   Offered
                     Activated when user describes    builders/     on-demand
                     a request body with > 5 optional
                     fields, OR explicitly requests it

Page Component       test_type IN [UI, full-stack]    Layer 3       Required
                                                      pages/
                                                      components/

Strategy (Mock)      mock IN [both, mock-only]        Layer 2       Required
                     (real/mock client switching)     (both api
                                                       and ui)

Adapter (Token)      auth IN [oauth2_auth_code,       Config/       Required
                     oauth2_client_credentials]       AuthManager

Repository           data_strategy IN [external,      Layer 1       Required
(Data Loading)       mixed]                           fixtures/

Decorator (Retry)    always included                  Layer 2       Required
                     (retry is a base client feature) Client

Decorator (Logging)  always included                  Layer 2       Required
                     (response logging hook)          Client
```

---

## Pattern Descriptions and Implementation Guidance

### Singleton — Auth Manager

**Purpose**: Fetch the auth token once per test session. Prevent N test
methods each triggering a separate token request to the auth server.

**When**: Any authenticated API — Bearer, JWT, OAuth2 Client Credentials,
OAuth2 Auth Code, API Key, Basic Auth.

**Implementation rule**:
- The Singleton instance is created at session scope (pytest session fixture
  or TestNG @BeforeSuite)
- Token is stored in the instance with an expiry timestamp
- `get_token()` checks expiry before returning; refreshes if within 30s of expiry
- Thread-safe locking required if parallel execution is configured

**What it generates**:
```
config/auth_manager.{ext}
```

---

### Singleton — Driver Manager

**Purpose**: Manage WebDriver / Playwright browser lifecycle. Ensure browsers
are not spawned per test (expensive) but per suite or per thread.

**When**: test_type includes UI.

**Execution model selection**:
- Sequential execution → classic Singleton (one browser shared across all tests)
- Parallel execution → ThreadLocal (one browser per thread, isolated)

The orchestrator selects based on whether the user mentioned parallel
execution. Default to ThreadLocal (safer for future parallelism).

**What it generates**:
```
config/driver_manager.{ext}
```

---

### Factory — API Data Factory

**Purpose**: Generate valid, randomized request payload objects without
hardcoding test data. Each test call to `.build()` returns a fresh object.

**When**: Always included. Even if user selected "inline data", the factory
is scaffolded as the recommended pattern and used in at least one example.

**Rules**:
- Uses Faker (Python) / JavaFaker (Java) / equivalent for random values
- `.build(**overrides)` / `.build(Map<String, Object> overrides)` for field pinning
- Named builder variants for common scenarios:
  `.build_admin()`, `.build_invalid_email()`, `.build_minimal()`

**What it generates**:
```
layer_1_models/api/factories/{resource}_factory.{ext}
```

---

### Factory — UI Form Data Factory

**Purpose**: Generate typed form data objects for browser form filling.
Keeps test data out of test methods and page objects.

**When**: test_type includes UI.

**What it generates**:
```
layer_1_models/ui/form_data/{page}_form_data.{ext}
```

---

### Factory — Browser Factory

**Purpose**: Create the correct WebDriver or Playwright browser type
based on BROWSER environment variable. Enables cross-browser testing
without changing test code.

**When**: test_type includes UI AND browser_targets > 1 (Chrome + at least
one other browser).

**Implementation rule**:
- Returns the appropriate browser/driver instance for the current BROWSER value
- Supported values: chromium, firefox, webkit (Playwright) or
  chrome, firefox, safari (Selenium)
- Fails fast with a clear error if BROWSER value is unsupported

**What it generates** (woven into):
```
layer_2_clients/ui/browser_session.{ext}  (factory method inside class)
```

---

### Builder — Request Payload Builder

**Purpose**: Fluent interface for constructing complex request bodies
with many optional fields. Makes test intent readable.

**When**: DEFERRED. Not generated by default.
Activated when:
a) User describes a request payload with more than 5 optional fields, OR
b) User explicitly asks "add a builder for X"

**When activated, offer the user**:
"Your {Resource} payload has many optional fields. Want me to generate
a Builder for cleaner test construction?"

**What it generates**:
```
layer_1_models/api/builders/{resource}_builder.{ext}
```

---

### Page Component Pattern

**Purpose**: Encapsulate shared UI elements (navigation, header, modals,
footers) in reusable component classes. Tests and page objects use
components instead of duplicating locator logic.

**When**: test_type includes UI.

**Rules**:
- Components live in `layer_3_pages/components/`
- Components follow the same contract as page objects (no assertions,
  no raw locators, fluent returns)
- At minimum: generate HeaderComponent as a starting example

**What it generates**:
```
layer_3_pages/components/{component}_component.{ext}
```

---

### Strategy — Mock/Real Client Switch

**Purpose**: Allow switching between a real API client and a WireMock-backed
client via a single environment variable (TEST_MODE=real|mock).
Zero test code changes required when switching modes.

**When**: mock IN [both, mock-only].

**Implementation**:
- Define a client interface / abstract base class
- RealApiClient implements it (wraps the actual HTTP calls)
- MockApiClient implements it (points base_url to WireMock at localhost:8080)
- ClientFactory.build(mode) returns the correct implementation
- For UI tests: the Strategy switches the AUT_BASE_URL pointed at a
  real backend vs the WireMock-backed one — the browser client is unchanged

**What it generates**:
```
layer_2_clients/api/base_api_client.{ext}  (updated with strategy interface)
layer_2_clients/api/real_api_client.{ext}
layer_2_clients/api/mock_api_client.{ext}
config/client_factory.{ext}
```

---

### Adapter — Token Refresh (OAuth2)

**Purpose**: Wrap the token fetch + refresh logic so the rest of the
system sees a simple `get_token()` interface regardless of the OAuth2
flow complexity underneath.

**When**: auth IN [oauth2_client_credentials, oauth2_auth_code].

**Distinction from Singleton**:
- Singleton controls instance count (one AuthManager)
- Adapter controls interface shape (hides OAuth2 flow complexity)
- Both are always generated together for OAuth2

**What it generates** (woven into):
```
config/auth_manager.{ext}  (adapter logic inside the singleton)
```

---

### Repository — External Data Loading

**Purpose**: Load test data from JSON/YAML fixture files rather than
generating it inline. Provides a consistent interface regardless of
the data file format.

**When**: data_strategy IN [external_fixtures, mixed].

**What it generates**:
```
layer_1_models/api/fixtures/        (directory for JSON/YAML data files)
layer_1_models/api/data_loader.{ext}  (Repository class: load_fixture(name))
```

---

### Decorator — Retry Logic

**Purpose**: Wrap HTTP calls with configurable retry on transient failures
(5xx errors, connection timeouts). Built into the base client.

**When**: Always.

**Config**:
- MAX_RETRIES: default 3, from env
- RETRY_BACKOFF_FACTOR: default 0.3, from env
- Retry on: 500, 502, 503, 504, ConnectionError, Timeout

---

### Decorator — Response Logging

**Purpose**: Log every request and response at the HTTP client layer.
Tests never need to add logging.

**When**: Always.

**Rules**:
- Log at INFO: method, URL, status code, response time
- Log at DEBUG: request headers, response body (controlled by LOG_LEVEL)
- Never log Authorization header value (security)
- Never log request body at INFO level (may contain PII)

---

## Deferred Pattern Offer Template

When the Builder pattern triggers mid-session (user describes a complex
payload), offer it using this format:

```
I noticed your {Resource} request has {N} optional fields
({field1}, {field2}, {field3}...).

A Builder pattern would make your tests significantly more readable:

  payload = (
      {Resource}Builder()
          .with_{field1}(value)
          .with_{field2}(value)
          .build()
  )

Want me to generate the Builder for {Resource}?
[Y] Yes   [N] No, keep using the factory with overrides
```
