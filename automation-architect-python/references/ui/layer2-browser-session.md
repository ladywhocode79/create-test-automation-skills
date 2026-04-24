# Layer 2 — Browser Session (Python / Playwright)

Generate this file for the UI profile.

---

## layer_2_clients/ui/browser_session.py

```python
from __future__ import annotations

import threading

from playwright.sync_api import Browser, BrowserContext, Page, Playwright, sync_playwright

from config.env_config import settings
from config.logger import get_logger

logger = get_logger(__name__)


class BrowserSession:
    """
    Manages the Playwright browser lifecycle.

    Pattern: ThreadLocal Singleton
    - One Playwright instance per process
    - One Browser instance per process (reused across tests)
    - One BrowserContext per test (isolated: cookies, storage, auth state)
    - One Page per test (clean tab)

    ThreadLocal ensures parallel test runs each get their own browser.
    Sequential runs reuse the same browser (performance).
    """

    _playwright_instance: Playwright | None = None
    _browser_instance: Browser | None = None
    _lock: threading.Lock = threading.Lock()

    @classmethod
    def get_browser(cls) -> Browser:
        """Return (or create) the shared browser instance."""
        with cls._lock:
            if cls._browser_instance is None or not cls._browser_instance.is_connected():
                cls._playwright_instance = sync_playwright().start()
                browser_type = settings.browser.lower()
                launcher = getattr(cls._playwright_instance, browser_type, None)
                if launcher is None:
                    raise ValueError(
                        f"Unsupported BROWSER='{browser_type}'. "
                        f"Expected: chromium, firefox, webkit."
                    )
                cls._browser_instance = launcher.launch(
                    headless=settings.headless,
                    slow_mo=settings.slow_mo_ms,
                )
                logger.info(
                    "Browser launched: %s (headless=%s)",
                    browser_type,
                    settings.headless,
                )
        return cls._browser_instance

    @classmethod
    def new_context(cls, storage_state: str | None = None) -> BrowserContext:
        """
        Create a new isolated browser context per test.

        Args:
            storage_state: Path to a saved auth state JSON file.
                           Pass this to skip the login flow for tests that
                           need an authenticated state.
        """
        browser = cls.get_browser()
        context = browser.new_context(
            base_url=settings.aut_base_url,
            viewport={"width": 1920, "height": 1080},
            storage_state=storage_state,
            record_video_dir="videos/" if settings.record_video else None,
        )
        context.set_default_timeout(settings.default_timeout_ms)
        context.set_default_navigation_timeout(settings.navigation_timeout_ms)
        return context

    @classmethod
    def new_page(cls, context: BrowserContext) -> Page:
        """Create a new page within a context."""
        page = context.new_page()
        page.on("pageerror", lambda err: logger.error("Browser console error: %s", err))
        return page

    @classmethod
    def teardown(cls) -> None:
        """Close browser and Playwright. Call in session teardown."""
        with cls._lock:
            if cls._browser_instance:
                cls._browser_instance.close()
                cls._browser_instance = None
            if cls._playwright_instance:
                cls._playwright_instance.stop()
                cls._playwright_instance = None
            logger.info("Browser session closed.")
```

---

## config/driver_manager.py (Playwright conftest fixtures)

For Playwright, the "DriverManager" concept is implemented as pytest fixtures
rather than a class, because Playwright's fixture model maps naturally to pytest:

```python
# conftest.py — UI fixture section

import pytest
from playwright.sync_api import Browser, BrowserContext, Page

from layer_2_clients.ui.browser_session import BrowserSession


@pytest.fixture(scope="session")
def browser_instance() -> Browser:
    """Session-scoped: browser launched once, shared across all UI tests."""
    browser = BrowserSession.get_browser()
    yield browser
    BrowserSession.teardown()


@pytest.fixture(scope="function")
def browser_context(browser_instance: Browser) -> BrowserContext:
    """
    Function-scoped: new isolated context per test.
    Each test gets clean cookies, storage, and auth state.
    """
    context = BrowserSession.new_context()
    yield context
    context.close()


@pytest.fixture(scope="function")
def page(browser_context: BrowserContext) -> Page:
    """Function-scoped: new tab per test."""
    p = BrowserSession.new_page(browser_context)
    yield p
    # Screenshot on failure is handled in conftest hook


@pytest.fixture(scope="session")
def authenticated_context(browser_instance: Browser, auth_state_file: str) -> BrowserContext:
    """
    Session-scoped authenticated context.
    Reuses a saved Playwright storage state (cookies + localStorage).
    Skips the login form — fastest auth approach for UI tests.

    Usage: pass auth_state_file = "auth-state.json" (generated by setup script)
    """
    context = BrowserSession.new_context(storage_state=auth_state_file)
    yield context
    context.close()


@pytest.fixture(scope="function")
def authenticated_page(authenticated_context: BrowserContext) -> Page:
    """Function-scoped authenticated page — already logged in."""
    p = BrowserSession.new_page(authenticated_context)
    yield p


# Screenshot on failure hook
@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    rep = outcome.get_result()
    if rep.when == "call" and rep.failed:
        p = item.funcargs.get("page") or item.funcargs.get("authenticated_page")
        if p:
            import allure
            allure.attach(
                p.screenshot(full_page=True),
                name=f"screenshot-{item.name}",
                attachment_type=allure.attachment_type.PNG,
            )
```

---

## env_config.py additions for UI

```python
# Additional fields in EnvConfig (added to existing class):
aut_base_url: str           = "http://localhost:3000"
browser: str                = "chromium"
headless: bool              = True
slow_mo_ms: int             = 0
default_timeout_ms: int     = 10000
navigation_timeout_ms: int  = 30000
record_video: bool          = False
```

---

## .env.example additions for UI

```bash
AUT_BASE_URL=http://localhost:3000
BROWSER=chromium                    # chromium | firefox | webkit
HEADLESS=true
SLOW_MO_MS=0                        # add delay between actions (ms), useful for debugging
DEFAULT_TIMEOUT_MS=10000
NAVIGATION_TIMEOUT_MS=30000
RECORD_VIDEO=false
```

---

## requirements.txt additions for Layer 2 UI

```
playwright>=1.44.0
```

Post-install step (run once):
```bash
playwright install chromium --with-deps
# Or for all browsers:
playwright install --with-deps
```
