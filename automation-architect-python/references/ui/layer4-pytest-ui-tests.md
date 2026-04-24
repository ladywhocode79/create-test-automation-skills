# Layer 4 — UI Tests (Python / Playwright / Pytest)

Generate these files for the UI profile.

---

## layer_4_tests/ui/test_login_flow.py

```python
from __future__ import annotations

import allure
import pytest
from playwright.sync_api import Page, expect

from layer_1_models.ui.form_data.login_form_data import LoginFormData
from layer_3_pages.login_page import LoginPage


@allure.feature("Authentication")
class TestLoginFlow:
    """End-to-end tests for the Login user flow."""

    @allure.story("Successful login")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.smoke
    @pytest.mark.ui
    def test_valid_credentials_redirect_to_dashboard(
        self,
        page: Page,
    ) -> None:
        """User with valid credentials is redirected to dashboard after login."""
        with allure.step("Navigate to login page"):
            login_page = LoginPage(page).navigate()

        with allure.step("Submit valid credentials"):
            form_data = LoginFormData.build(
                username="test@example.com",
                password="ValidPass123!",
            )
            dashboard = login_page.login_as(form_data)

        with allure.step("Assert dashboard is loaded"):
            assert dashboard.is_loaded()
            assert "welcome" in dashboard.get_welcome_heading().lower()

    @allure.story("Invalid password")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.smoke
    @pytest.mark.ui
    def test_invalid_password_shows_error_message(
        self,
        page: Page,
    ) -> None:
        """User with wrong password sees an error message and stays on login page."""
        with allure.step("Navigate to login page"):
            login_page = LoginPage(page).navigate()

        with allure.step("Submit invalid credentials"):
            form_data = LoginFormData.build_invalid_password()
            login_page.login_and_expect_error(form_data)

        with allure.step("Assert error message is shown"):
            error = login_page.get_error_message()
            assert error  # non-empty
            assert "invalid" in error.lower() or "incorrect" in error.lower()

    @allure.story("Empty fields")
    @pytest.mark.regression
    @pytest.mark.ui
    def test_empty_credentials_submit_is_disabled_or_shows_error(
        self,
        page: Page,
    ) -> None:
        """Login form should not submit with empty fields."""
        login_page = LoginPage(page).navigate()

        # If the button is disabled before fill, assert that
        if not login_page.is_submit_enabled():
            assert True  # UI prevents empty submit via disabled button
            return

        # Otherwise, submit empty and expect error
        login_page.login_and_expect_error(LoginFormData.build_empty())
        error = login_page.get_error_message()
        assert error

    @allure.story("Logout")
    @pytest.mark.regression
    @pytest.mark.ui
    def test_user_can_logout_and_return_to_login(
        self,
        authenticated_page: Page,   # pre-authenticated page fixture
    ) -> None:
        """Authenticated user can log out and is returned to login page."""
        from layer_3_pages.dashboard_page import DashboardPage

        with allure.step("Start on dashboard"):
            dashboard = DashboardPage(authenticated_page).wait_until_ready()

        with allure.step("Logout via header"):
            login_page = dashboard.get_header().logout()

        with allure.step("Assert back on login page"):
            assert "/login" in authenticated_page.url


@allure.feature("Authentication")
class TestLoginParametrized:
    """Parametrized tests for login edge cases."""

    @pytest.mark.parametrize("username,password,expected_error", [
        ("",          "password123",  "required"),
        ("user@x.com", "",            "required"),
        ("not-email",  "password123", "valid email"),
    ])
    @pytest.mark.regression
    @pytest.mark.ui
    def test_field_validation_messages(
        self,
        page: Page,
        username: str,
        password: str,
        expected_error: str,
    ) -> None:
        """Form field validation messages contain expected text."""
        login_page = LoginPage(page).navigate()
        form_data = LoginFormData(username=username, password=password)
        login_page.login_and_expect_error(form_data)

        error = login_page.get_error_message()
        assert expected_error.lower() in error.lower(), (
            f"Expected error containing '{expected_error}', got: '{error}'"
        )
```

---

## conftest.py — UI Fixtures

```python
# conftest.py — UI section (append to existing conftest.py)
from __future__ import annotations

import pytest
from playwright.sync_api import Browser, BrowserContext, Page

from layer_2_clients.ui.browser_session import BrowserSession


@pytest.fixture(scope="session")
def browser_instance() -> Browser:
    browser = BrowserSession.get_browser()
    yield browser
    BrowserSession.teardown()


@pytest.fixture(scope="function")
def browser_context(browser_instance: Browser) -> BrowserContext:
    context = BrowserSession.new_context()
    yield context
    context.close()


@pytest.fixture(scope="function")
def page(browser_context: BrowserContext) -> Page:
    p = BrowserSession.new_page(browser_context)
    yield p
    # teardown handled by browser_context.close()


@pytest.fixture(scope="session")
def authenticated_state(browser_instance: Browser, tmp_path_factory) -> str:
    """
    One-time login to save auth state for the entire session.
    All tests using authenticated_page share this saved state.
    """
    from layer_1_models.ui.form_data.login_form_data import LoginFormData
    from layer_3_pages.login_page import LoginPage

    state_file = str(tmp_path_factory.mktemp("auth") / "auth-state.json")
    context = BrowserSession.new_context()
    p = BrowserSession.new_page(context)

    login_page = LoginPage(p).navigate()
    login_page.login_as(
        LoginFormData.build(
            username="test@example.com",
            password="ValidPass123!",
        )
    )
    login_page.save_auth_state(path=state_file)
    context.close()
    return state_file


@pytest.fixture(scope="function")
def authenticated_context(
    browser_instance: Browser,
    authenticated_state: str,
) -> BrowserContext:
    """Function-scoped context with pre-loaded auth state."""
    context = BrowserSession.new_context(storage_state=authenticated_state)
    yield context
    context.close()


@pytest.fixture(scope="function")
def authenticated_page(authenticated_context: BrowserContext) -> Page:
    """Function-scoped authenticated page."""
    p = BrowserSession.new_page(authenticated_context)
    yield p


# Screenshot on failure — attaches to Allure report
@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    rep = outcome.get_result()
    if rep.when == "call" and rep.failed:
        for fixture_name in ("page", "authenticated_page"):
            p = item.funcargs.get(fixture_name)
            if p:
                try:
                    import allure
                    allure.attach(
                        p.screenshot(full_page=True),
                        name=f"failure-{item.name}",
                        attachment_type=allure.attachment_type.PNG,
                    )
                except Exception:
                    pass
                break
```

---

## Key UI Testing Rules Enforced

1. **No `time.sleep()`** — Playwright's auto-waiting handles element readiness.
   If a wait is needed, use `page.wait_for_selector()` or `locator.wait_for()`.

2. **No raw locator strings in tests** — Tests interact through page objects only.
   Any test that contains a CSS selector or data-testid string directly is wrong.

3. **Fixture scope discipline**:
   - `page` is function-scoped — each test gets a clean browser tab
   - `browser_instance` is session-scoped — browser starts once per run
   - `authenticated_state` is session-scoped — one login per run, reused

4. **`authenticated_page` vs `page`**:
   - Use `page` for login/auth flow tests (tests the login itself)
   - Use `authenticated_page` for tests that need to be logged in but don't
     test the login flow

5. **Allure steps wrap logical actions**, not individual Playwright calls.
   One `with allure.step()` per business action, not per `locator().click()`.
