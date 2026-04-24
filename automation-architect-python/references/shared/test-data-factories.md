# Shared — Test Data Strategy (Python)

Applies to both API and UI profiles.

---

## Requirements

```
faker>=24.0.0
```

---

## Data Strategy Summary

| Strategy | When | Files generated |
|---|---|---|
| Factory (default) | Always | `layer_1_models/api/factories/user_factory.py` |
| External fixtures | data_strategy IN [external, mixed] | `layer_1_models/api/fixtures/` + `data_loader.py` |
| Builder | Deferred (complex payloads) | `layer_1_models/api/builders/user_builder.py` |
| UI form data | test_type includes UI | `layer_1_models/ui/form_data/login_form_data.py` |

---

## External Fixture Files (generated when data_strategy includes external)

```json
// layer_1_models/api/fixtures/users.json
{
  "valid_users": [
    {
      "username": "testuser_viewer",
      "email": "viewer@example.com",
      "role": "viewer"
    },
    {
      "username": "testuser_admin",
      "email": "admin@example.com",
      "role": "admin"
    }
  ],
  "invalid_users": [
    {
      "username": "bad",
      "email": "not-an-email",
      "role": "superuser"
    }
  ]
}
```

```python
# layer_1_models/api/data_loader.py
from __future__ import annotations

import json
from pathlib import Path

from layer_1_models.api.user_model import CreateUserRequest

FIXTURES_DIR = Path(__file__).parent / "fixtures"


class DataLoader:
    """
    Repository pattern: load test data from JSON fixture files.
    Provides typed access — returns model objects, not raw dicts.
    """

    @staticmethod
    def load_valid_users() -> list[CreateUserRequest]:
        data = DataLoader._load("users.json")
        return [CreateUserRequest(**u) for u in data["valid_users"]]

    @staticmethod
    def load_invalid_users() -> list[dict]:
        """Returns raw dicts for invalid data (won't pass Pydantic validation)."""
        data = DataLoader._load("users.json")
        return data["invalid_users"]

    @staticmethod
    def _load(filename: str) -> dict:
        path = FIXTURES_DIR / filename
        if not path.exists():
            raise FileNotFoundError(
                f"Fixture file not found: {path}. "
                f"Create it or use the Factory for dynamic data."
            )
        with path.open() as f:
            return json.load(f)
```

---

## Builder Pattern (generated on demand for complex payloads)

```python
# layer_1_models/api/builders/order_builder.py
from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class OrderBuilder:
    """
    Fluent builder for complex OrderRequest payloads.
    Use when the payload has many optional fields and test readability matters.

    Usage:
        payload = (
            OrderBuilder()
            .with_item("SKU-001", qty=2)
            .with_item("SKU-002", qty=1)
            .with_shipping("123 Test St", method="express")
            .with_payment("tok_test_visa")
            .build()
        )
    """

    _items: list[dict] = field(default_factory=list)
    _shipping: dict = field(default_factory=dict)
    _payment: dict = field(default_factory=dict)
    _notes: str | None = None

    def with_item(self, sku: str, qty: int = 1) -> OrderBuilder:
        self._items.append({"sku": sku, "quantity": qty})
        return self

    def with_shipping(
        self,
        address: str,
        method: str = "standard",
    ) -> OrderBuilder:
        self._shipping = {"address": address, "method": method}
        return self

    def with_payment(self, token: str) -> OrderBuilder:
        self._payment = {"token": token}
        return self

    def with_notes(self, notes: str) -> OrderBuilder:
        self._notes = notes
        return self

    def build(self) -> dict:
        if not self._items:
            raise ValueError("OrderBuilder: at least one item is required")
        payload = {
            "items": self._items,
            "shipping": self._shipping,
            "payment": self._payment,
        }
        if self._notes:
            payload["notes"] = self._notes
        return payload
```

---

## Combined Strategy (Recommended for Most Projects)

For the "mixed" data strategy, use Factories for random data and external
fixtures for stable reference data:

```python
# In Layer 4 tests:

# Random data: use factory (different every run, catches more edge cases)
def test_create_user_success(self, user_service, user_factory):
    payload = user_factory.build()
    user = user_service.create_user(payload)
    assert user.role == payload.role

# Reference data: use fixtures (stable known values, predictable assertions)
def test_get_known_admin_user(self, user_service):
    users = DataLoader.load_valid_users()
    admin = next(u for u in users if u.role == "admin")
    user = user_service.create_user(admin)
    assert user.role == "admin"
    assert user.email == admin.email
```
