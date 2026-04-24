# Pattern: Singleton (Driver) + Factory (Browser) — Python / Playwright

Both patterns are woven into `layer_2_clients/ui/browser_session.py`
and the conftest.py fixtures. No separate file is generated.

---

## Singleton Pattern (Browser Instance)

The `BrowserSession` class in layer2-browser-session.md already implements
the Singleton via class-level `_browser_instance` and double-checked locking.

Key decisions:
- `_browser_instance` at class level (not instance level) ensures one browser
  across all test classes in the session
- `threading.Lock` makes it safe for `pytest-xdist` parallel runs
- `is_connected()` guard handles edge cases where the browser crashes mid-session

---

## Factory Pattern (Browser Type)

When `browser_targets > 1`, the `get_browser()` method becomes a factory:

```python
# In BrowserSession.get_browser() — replace the launcher line:

SUPPORTED_BROWSERS = {"chromium", "firefox", "webkit"}

browser_type = settings.browser.lower()
if browser_type not in SUPPORTED_BROWSERS:
    raise ValueError(
        f"Unsupported BROWSER='{browser_type}'. "
        f"Supported: {', '.join(sorted(SUPPORTED_BROWSERS))}"
    )
launcher = getattr(cls._playwright_instance, browser_type)
cls._browser_instance = launcher.launch(
    headless=settings.headless,
    slow_mo=settings.slow_mo_ms,
)
```

To run against a different browser:
```bash
BROWSER=firefox pytest layer_4_tests/ui/ -v
BROWSER=webkit pytest layer_4_tests/ui/ -v
```

In CI matrix (from ci-templates.md):
```yaml
strategy:
  matrix:
    browser: [chromium, firefox]
env:
  BROWSER: ${{ matrix.browser }}
```

---

## Auth State Reuse (Session Token Pattern)

When `ui_auth_mode = inject_session_token` or `both`, generate this
setup script in addition to the conftest fixtures:

```python
# scripts/save_auth_state.py
"""
Run once to save authenticated browser state.
Used by CI to avoid repeated logins slowing the suite.

Usage:
    python scripts/save_auth_state.py
    # Saves: auth-state.json
"""
from playwright.sync_api import sync_playwright
from config.env_config import settings

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    context = browser.new_context(base_url=settings.aut_base_url)
    page = context.new_page()

    page.goto("/login")
    page.locator("[data-testid='login-username']").fill(settings.test_username)
    page.locator("[data-testid='login-password']").fill(settings.test_password)
    page.locator("[data-testid='login-submit']").click()
    page.wait_for_url("**/dashboard**")

    context.storage_state(path="auth-state.json")
    browser.close()
    print("Auth state saved to auth-state.json")
```

The `authenticated_state` fixture in conftest.py calls this logic at
session scope, so it runs once per test run automatically.

---

## .env.example additions for auth state

```bash
TEST_USERNAME=test@example.com
TEST_PASSWORD=ValidPass123!
```

Add to EnvConfig:
```python
test_username: str = ""    # used only by save_auth_state script
test_password: str = ""    # used only by save_auth_state script
```
