# Layer 3 — Page Objects (Python / Playwright)

Generate these files for the UI profile.

---

## Design Rules for Page Objects

1. **No locator strings in page object methods** — all locators come from Layer 1
2. **No assertions in page objects** — return data; assert in Layer 4
3. **Fluent returns** — navigation methods return the next page object
4. **Business action names** — `login_as()` not `click_submit_button()`
5. **Built-in waits** — use Playwright's auto-waiting; no `time.sleep()`
6. **Constructor receives a `Page` object** — page objects never create browser instances

---

## layer_3_pages/login_page.py

```python
from __future__ import annotations

from playwright.sync_api import Page, expect

from layer_1_models.ui.locators.login_locators import LoginLocators
from layer_1_models.ui.form_data.login_form_data import LoginFormData


class LoginPage:
    """
    Page Object for the Login page.

    Fluent interface: methods that navigate away return the next page object.
    Methods that stay on the same page return self.
    """

    URL = "/login"

    def __init__(self, page: Page) -> None:
        self._page = page
        self._loc = LoginLocators()

    def navigate(self) -> LoginPage:
        """Navigate to the login page."""
        self._page.goto(self.URL)
        self._page.wait_for_url(f"**{self.URL}")
        return self

    def login_as(self, form_data: LoginFormData) -> DashboardPage:
        """
        Perform the full login flow.
        Returns DashboardPage on success.
        Raises PlaywrightTimeoutError if login fails (no dashboard navigation).
        """
        self._page.locator(self._loc.USERNAME_INPUT).fill(form_data.username)
        self._page.locator(self._loc.PASSWORD_INPUT).fill(form_data.password)
        self._page.locator(self._loc.SUBMIT_BUTTON).click()

        # Wait for navigation away from login page (success indicator)
        self._page.wait_for_url(lambda url: "/login" not in url, timeout=10000)

        from layer_3_pages.dashboard_page import DashboardPage
        return DashboardPage(self._page)

    def login_and_expect_error(self, form_data: LoginFormData) -> LoginPage:
        """
        Attempt login expecting failure.
        Returns self (stays on login page) so caller can assert on error state.
        """
        self._page.locator(self._loc.USERNAME_INPUT).fill(form_data.username)
        self._page.locator(self._loc.PASSWORD_INPUT).fill(form_data.password)
        self._page.locator(self._loc.SUBMIT_BUTTON).click()

        # Wait for error message to appear
        self._page.locator(self._loc.ERROR_MESSAGE).wait_for(state="visible")
        return self

    def get_error_message(self) -> str:
        """Return the visible error message text. Call after login_and_expect_error()."""
        return self._page.locator(self._loc.ERROR_MESSAGE).inner_text()

    def is_submit_enabled(self) -> bool:
        """Return True if the submit button is enabled."""
        return self._page.locator(self._loc.SUBMIT_BUTTON).is_enabled()

    def save_auth_state(self, path: str = "auth-state.json") -> None:
        """
        Save current browser context storage state (cookies + localStorage).
        Use after a successful login to enable session reuse across tests.
        """
        self._page.context.storage_state(path=path)


# Avoid circular import — DashboardPage imported inline inside login_as()
```

---

## layer_3_pages/dashboard_page.py

```python
from __future__ import annotations

from playwright.sync_api import Page

from layer_1_models.ui.locators.dashboard_locators import DashboardLocators


class DashboardPage:
    """Page Object for the Dashboard (post-login landing page)."""

    URL_PATTERN = "**/dashboard**"

    def __init__(self, page: Page) -> None:
        self._page = page
        self._loc = DashboardLocators()

    def wait_until_ready(self) -> DashboardPage:
        """Wait for the dashboard to fully load."""
        self._page.wait_for_url(self.URL_PATTERN, timeout=15000)
        self._page.locator(self._loc.PAGE_READY).wait_for(state="visible")
        return self

    def get_welcome_heading(self) -> str:
        """Return the welcome heading text."""
        return self._page.locator(self._loc.WELCOME_HEADING).inner_text()

    def get_displayed_username(self) -> str:
        """Return the username shown in the welcome section."""
        return self._page.locator(self._loc.USER_NAME_DISPLAY).inner_text()

    def get_header(self) -> HeaderComponent:
        """Return the header component for nav interactions."""
        from layer_3_pages.components.header_component import HeaderComponent
        return HeaderComponent(self._page)

    def is_loaded(self) -> bool:
        """Return True if dashboard is visible and ready."""
        return self._page.locator(self._loc.WELCOME_HEADING).is_visible()
```

---

## layer_3_pages/components/header_component.py

```python
from __future__ import annotations

from playwright.sync_api import Page

from layer_1_models.ui.locators.dashboard_locators import DashboardLocators


class HeaderComponent:
    """
    Shared header/navigation component.
    Used by multiple page objects — DashboardPage, ProfilePage, etc.
    """

    def __init__(self, page: Page) -> None:
        self._page = page
        self._loc = DashboardLocators()

    def logout(self) -> LoginPage:
        """Click the logout link and return the Login page."""
        self._page.locator(self._loc.NAV_PROFILE).click()
        self._page.locator(self._loc.NAV_LOGOUT).click()
        self._page.wait_for_url("**/login**")

        from layer_3_pages.login_page import LoginPage
        return LoginPage(self._page)

    def is_visible(self) -> bool:
        return self._page.locator(self._loc.NAV_MENU).is_visible()
```

---

## Page Object Extension Pattern

To add a new page (e.g., `ProfilePage`):

```python
# layer_3_pages/profile_page.py
from layer_1_models.ui.locators.profile_locators import ProfileLocators

class ProfilePage:
    def __init__(self, page: Page) -> None:
        self._page = page
        self._loc = ProfileLocators()

    def get_email(self) -> str:
        return self._page.locator(self._loc.EMAIL_DISPLAY).inner_text()

    def update_name(self, first: str, last: str) -> ProfilePage:
        self._page.locator(self._loc.FIRST_NAME_INPUT).fill(first)
        self._page.locator(self._loc.LAST_NAME_INPUT).fill(last)
        self._page.locator(self._loc.SAVE_BUTTON).click()
        return self
```

Zero changes to existing pages needed.
