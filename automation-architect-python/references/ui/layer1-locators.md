# Layer 1 — UI Locators & Form Data (Python / Playwright)

Generate these files for the UI profile.

---

## Design Principle: Locators in Layer 1, Not in Page Objects

Locator strings belong in the Data/Model layer, not scattered across page
object methods. This means:
- Page objects reference named constants (self.locators.USERNAME_INPUT)
- Changing a locator requires editing one file, not hunting through page objects
- Locators can be documented, reviewed, and version-controlled independently

---

## layer_1_models/ui/locators/login_locators.py

```python
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class LoginLocators:
    """
    All locators for the Login page.
    Strategy: data-testid attributes (decoupled from CSS/structure).

    To use in a Page Object:
        loc = LoginLocators()
        page.locator(loc.USERNAME_INPUT).fill("user@example.com")
    """
    # Form fields
    USERNAME_INPUT: str = "[data-testid='login-username']"
    PASSWORD_INPUT: str = "[data-testid='login-password']"
    SUBMIT_BUTTON:  str = "[data-testid='login-submit']"

    # Validation messages
    ERROR_MESSAGE:     str = "[data-testid='login-error']"
    FIELD_ERROR:       str = "[data-testid='field-error']"

    # Links
    FORGOT_PASSWORD_LINK: str = "[data-testid='forgot-password']"
    REGISTER_LINK:        str = "[data-testid='register-link']"

    # Loading state
    LOADING_SPINNER: str = "[data-testid='login-spinner']"
```

```python
# CSS selector variant (if user selected CSS locators)
@dataclass(frozen=True)
class LoginLocators:
    USERNAME_INPUT: str = "input[name='username']"
    PASSWORD_INPUT: str = "input[type='password']"
    SUBMIT_BUTTON:  str = "button[type='submit']"
    ERROR_MESSAGE:  str = ".alert-error"
```

```python
# Role-based variant (if user selected role-based / Playwright accessibility)
@dataclass(frozen=True)
class LoginLocators:
    # These are used with page.get_by_role() and page.get_by_label()
    # Not raw CSS strings — handled differently in the Page Object
    USERNAME_LABEL: str = "Email address"
    PASSWORD_LABEL: str = "Password"
    SUBMIT_LABEL:   str = "Sign in"
    ERROR_ROLE:     str = "alert"
```

---

## layer_1_models/ui/locators/dashboard_locators.py

```python
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class DashboardLocators:
    """All locators for the Dashboard page."""
    # Navigation
    NAV_MENU:         str = "[data-testid='nav-menu']"
    NAV_PROFILE:      str = "[data-testid='nav-profile']"
    NAV_LOGOUT:       str = "[data-testid='nav-logout']"

    # Content area
    WELCOME_HEADING:  str = "[data-testid='welcome-heading']"
    USER_NAME_DISPLAY:str = "[data-testid='user-name']"

    # Page loading
    PAGE_READY:       str = "[data-testid='dashboard-ready']"
```

---

## layer_1_models/ui/form_data/login_form_data.py

```python
from __future__ import annotations

from dataclasses import dataclass

from faker import Faker

fake = Faker()


@dataclass
class LoginFormData:
    """
    Typed data for filling the Login form.
    Used by LoginPage.login_as() to decouple form data from page interaction.
    """
    username: str
    password: str

    @staticmethod
    def build(
        username: str | None = None,
        password: str | None = None,
    ) -> LoginFormData:
        """Build valid login credentials for test use."""
        return LoginFormData(
            username=username or fake.email(),
            password=password or fake.password(length=12, special_chars=True),
        )

    @staticmethod
    def build_invalid_password(username: str | None = None) -> LoginFormData:
        """Build credentials with a deliberately wrong password."""
        return LoginFormData(
            username=username or fake.email(),
            password="wrongpassword123!",
        )

    @staticmethod
    def build_empty() -> LoginFormData:
        """Build empty credentials for validation tests."""
        return LoginFormData(username="", password="")
```

---

## requirements.txt entries for Layer 1 UI

```
faker>=24.0.0    # already included from API profile
```

No additional dependencies — locators and form data are pure Python dataclasses.
