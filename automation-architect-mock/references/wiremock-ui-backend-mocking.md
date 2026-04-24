# WireMock — UI Backend Mocking

When test_type includes UI, WireMock mocks the backend API that the
browser application calls — not the browser itself.

---

## Architecture

```
[Pytest/TestNG Test]
        ↓
[Browser (Playwright/Selenium)]
        ↓
[Your Application (AUT) running locally or in Docker]
        ↓
[WireMock — replaces real backend API]
```

The test code only interacts with the browser (via Page Objects).
WireMock transparently replaces the backend. The browser and application
are unaware they are talking to a stub server.

---

## Environment Setup for UI + WireMock

```bash
# .env — local development
AUT_BASE_URL=http://localhost:3000          # your app's frontend URL
BACKEND_URL=http://localhost:8080           # WireMock (mocking the API)
TEST_MODE=mock
```

The application must be configured to call WireMock's URL instead of the
real backend. This is typically done via an environment variable at app startup:

```bash
# Start your application pointing at WireMock:
API_BASE_URL=http://localhost:8080 npm start
# or:
REACT_APP_API_URL=http://localhost:8080 npm start
```

---

## Docker Compose for Full UI Test Stack

```yaml
# docker-compose.yml
services:
  wiremock:
    image: wiremock/wiremock:3.3.1
    container_name: wiremock
    ports:
      - "8080:8080"
    volumes:
      - ./mocks/stubs:/home/wiremock/mappings
    command: --global-response-templating --verbose
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/__admin/health"]
      interval: 5s
      retries: 10

  app:
    image: your-app:latest              # your application image
    container_name: app
    ports:
      - "3000:3000"
    environment:
      API_BASE_URL: http://wiremock:8080    # app calls wiremock, not real API
    depends_on:
      wiremock:
        condition: service_healthy
```

---

## CI Pipeline Setup (GitHub Actions)

```yaml
# In .github/workflows/ui-tests.yml:
services:
  wiremock:
    image: wiremock/wiremock:3.3.1
    ports:
      - 8080:8080
    options: >-
      --health-cmd "curl -f http://localhost:8080/__admin/health"
      --health-interval 5s
      --health-timeout 3s
      --health-retries 10

steps:
  - name: Start application with mock backend
    run: |
      API_BASE_URL=http://localhost:8080 npm start &
      # Wait for app to be ready
      timeout 60 bash -c "until curl -sf http://localhost:3000; do sleep 2; done"

  - name: Run UI tests
    run: pytest layer_4_tests/ui/ -v --alluredir=allure-results
    env:
      AUT_BASE_URL: http://localhost:3000
      BACKEND_URL:  http://localhost:8080
      TEST_MODE:    mock
      HEADLESS:     true
```

---

## Per-Test Stub Override Pattern

For UI tests that need specific backend behavior per test (e.g., test
"what happens when the API returns 500"):

```python
# Python conftest.py — WireMock fixture for UI tests
import pytest
from mocks.wiremock_lifecycle import register_stub, reset_stubs

@pytest.fixture(autouse=False)
def wiremock():
    """Yields WireMock control to tests that need per-test stub overrides."""
    yield
    reset_stubs()   # clean runtime stubs after each test


# In a UI test:
def test_dashboard_shows_error_when_api_fails(page, wiremock):
    # Override the default stub with an error response for this test
    register_stub({
        "request": {"method": "GET", "url": "/api/v1/users"},
        "response": {"status": 503, "jsonBody": {"error": "Service unavailable"}}
    })

    dashboard = DashboardPage(page).wait_until_ready()
    # Now assert that the UI handles the 503 gracefully
    assert dashboard.shows_error_banner()
```

```java
// Java — WireMock per-test override in TestNG
@BeforeMethod
public void resetWireMockStubs() {
    WireMockLifecycle.resetStubs();
}

@Test
public void testDashboardShowsErrorWhenApiFails() {
    WireMockLifecycle.registerStub(Map.of(
        "request", Map.of("method", "GET", "url", "/api/v1/users"),
        "response", Map.of("status", 503,
            "jsonBody", Map.of("error", "Service unavailable"))
    ));

    driver.get(EnvConfig.get().autBaseUrl() + "/dashboard");
    DashboardPage dashboard = new DashboardPage(driver).waitUntilReady();
    assertThat(dashboard.showsErrorBanner()).isTrue();
}
```

---

## Verifying Backend Calls from UI Tests

WireMock's request journal lets you verify that the application made
the expected API calls during a UI test:

```python
# After a UI action, verify the correct API was called:
def test_login_calls_auth_endpoint(page, wiremock):
    login_page = LoginPage(page).navigate()
    login_page.login_as(LoginFormData.build("user@example.com", "password"))

    # Verify the app called the token endpoint
    verify_called(url_pattern="/oauth/token", times=1)

    # Verify the app fetched user data after login
    verify_called(url_pattern="/api/v1/users/me", times=1)
```

This pattern provides cross-layer assertion confidence:
- Layer 4 (UI) asserts the user sees the correct page
- WireMock verifies the correct API calls were made underneath
