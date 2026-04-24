# Pattern: Page Component (Python / Playwright)

The Page Component pattern extracts shared UI elements into reusable component
classes. See layer3-page-objects.md for the HeaderComponent implementation.

---

## When to Create a Component

Create a component class (in `layer_3_pages/components/`) when:
- The same UI element appears on 2+ pages (header, footer, sidebar, modal)
- The element has its own complex interaction logic
- The element has its own set of locators worth isolating

Do NOT create a component for one-off elements on a single page.

---

## Component vs Page Object Distinction

| Aspect | Page Object | Component |
|---|---|---|
| Scope | One full page | One reusable UI element |
| File location | `layer_3_pages/` | `layer_3_pages/components/` |
| Constructor | Receives `Page` | Receives `Page` |
| Navigation | Returns next page object | Returns calling page or component |
| Locators | From `layer_1_models/ui/locators/` | From `layer_1_models/ui/locators/` |

---

## Modal Component Example

```python
# layer_3_pages/components/modal_component.py
from __future__ import annotations

from dataclasses import dataclass

from playwright.sync_api import Page


@dataclass(frozen=True)
class ModalLocators:
    TITLE:    str = "[data-testid='modal-title']"
    BODY:     str = "[data-testid='modal-body']"
    CONFIRM:  str = "[data-testid='modal-confirm']"
    CANCEL:   str = "[data-testid='modal-cancel']"
    CLOSE_X:  str = "[data-testid='modal-close']"


class ModalComponent:
    """
    Generic confirmation/dialog modal component.
    Used by any page that triggers a modal.
    """

    def __init__(self, page: Page) -> None:
        self._page = page
        self._loc = ModalLocators()

    def wait_for_modal(self) -> ModalComponent:
        self._page.locator(self._loc.TITLE).wait_for(state="visible")
        return self

    def get_title(self) -> str:
        return self._page.locator(self._loc.TITLE).inner_text()

    def get_body(self) -> str:
        return self._page.locator(self._loc.BODY).inner_text()

    def confirm(self) -> None:
        """Click confirm/OK button. Returns None — modal closes, no navigation."""
        self._page.locator(self._loc.CONFIRM).click()
        self._page.locator(self._loc.TITLE).wait_for(state="hidden")

    def cancel(self) -> None:
        """Click cancel. Modal closes, user stays on current page."""
        self._page.locator(self._loc.CANCEL).click()
        self._page.locator(self._loc.TITLE).wait_for(state="hidden")
```

Usage in a page object:
```python
# In DashboardPage or any other page:
def delete_item(self, item_id: int) -> None:
    self._page.locator(f"[data-testid='delete-{item_id}']").click()
    modal = ModalComponent(self._page).wait_for_modal()
    assert "delete" in modal.get_title().lower()
    modal.confirm()
```

Usage in Layer 4 test:
```python
def test_delete_confirms_via_modal(self, authenticated_page):
    dashboard = DashboardPage(authenticated_page).wait_until_ready()
    dashboard.delete_item(item_id=42)
    # No modal interaction in the test — handled entirely in page object
    # Just assert on the final state
    assert not dashboard.item_exists(item_id=42)
```

---

## Component Locator Organization

When a component has its own locators (like `ModalLocators` above),
there are two valid approaches:

1. **Inline `@dataclass`** in the component file (for small components
   with < 5 locators — acceptable, kept close to usage)

2. **Separate file in Layer 1** at `layer_1_models/ui/locators/modal_locators.py`
   (for larger components with many locators — preferred for consistency)

Use approach 2 as the default. Use approach 1 only for small, self-contained
components where the overhead of a separate file is not justified.
