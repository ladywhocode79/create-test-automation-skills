# Layer 1 — API Models (Python / Pydantic v2)

Generate these files for the API profile.

---

## layer_1_models/api/user_model.py

```python
from __future__ import annotations

from pydantic import BaseModel, EmailStr, field_validator


class CreateUserRequest(BaseModel):
    username: str
    email: EmailStr
    role: str = "viewer"
    first_name: str | None = None
    last_name: str | None = None

    @field_validator("username")
    @classmethod
    def username_must_be_alphanumeric(cls, v: str) -> str:
        if not v.replace("_", "").isalnum():
            raise ValueError("username must contain only letters, numbers, or underscores")
        if len(v) < 3:
            raise ValueError("username must be at least 3 characters")
        return v

    @field_validator("role")
    @classmethod
    def role_must_be_valid(cls, v: str) -> str:
        allowed = {"viewer", "editor", "admin"}
        if v not in allowed:
            raise ValueError(f"role must be one of {allowed}")
        return v


class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    role: str
    first_name: str | None = None
    last_name: str | None = None
    created_at: str
    updated_at: str | None = None


class UserListResponse(BaseModel):
    items: list[UserResponse]
    total: int
    page: int
    page_size: int
```

**Rules enforced:**
- `EmailStr` handles email format validation automatically (requires `pydantic[email]` extra)
- `field_validator` replaces deprecated v1 `@validator`
- Response models use `| None` union type (Python 3.10+ syntax) — use `Optional[str]` for 3.9
- No imports from Layer 2, 3, or 4

---

## layer_1_models/api/error_model.py

```python
from pydantic import BaseModel


class ApiErrorResponse(BaseModel):
    """Typed error response for non-2xx API responses."""
    error: str
    code: str | None = None
    details: dict | None = None
    request_id: str | None = None
```

Use this in Layer 4 tests to validate error response shape:
```python
error = ApiErrorResponse(**resp.json())
assert error.code == "USER_NOT_FOUND"
```

---

## requirements.txt entries for Layer 1

```
pydantic>=2.6.0
pydantic[email]>=2.6.0    # required for EmailStr
```

---

## Naming Conventions

| Concept | Convention | Example |
|---|---|---|
| Request model | `{Resource}Request` | `CreateUserRequest` |
| Response model | `{Resource}Response` | `UserResponse` |
| List response | `{Resource}ListResponse` | `UserListResponse` |
| Error response | `ApiErrorResponse` | shared across all resources |
| File | `{resource}_model.py` | `user_model.py` |

---

## Adding a New Resource Model

To add an `Order` resource, create `layer_1_models/api/order_model.py`
following the exact same pattern. No changes to existing files needed.

```python
# layer_1_models/api/order_model.py
from pydantic import BaseModel, field_validator
from decimal import Decimal


class CreateOrderRequest(BaseModel):
    user_id: int
    items: list[dict]           # replace with OrderItemModel when defined
    shipping_address: str
    payment_token: str

    @field_validator("items")
    @classmethod
    def items_must_not_be_empty(cls, v: list) -> list:
        if not v:
            raise ValueError("order must contain at least one item")
        return v


class OrderResponse(BaseModel):
    id: int
    user_id: int
    status: str
    total: Decimal
    created_at: str
```
