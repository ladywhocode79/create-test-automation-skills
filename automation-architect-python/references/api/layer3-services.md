# Layer 3 — Service Layer (Python / API)

Generate these files for the API profile.

---

## layer_3_services/user_service.py

```python
from __future__ import annotations

import requests

from layer_1_models.api.user_model import (
    CreateUserRequest,
    UserListResponse,
    UserResponse,
)
from layer_2_clients.api.base_api_client import BaseApiClient


class UserService:
    """
    Business operations for the User resource domain.

    Rules:
    - Accepts typed model objects as input (never raw dicts)
    - Returns typed model objects as output (never raw responses)
    - Calls raise_for_status() so Layer 4 catches HTTPError on failures
    - Contains zero assertions or test logic
    """

    ENDPOINT = "/api/v1/users"

    def __init__(self, client: BaseApiClient) -> None:
        self._client = client

    def create_user(self, payload: CreateUserRequest) -> UserResponse:
        """POST /api/v1/users — create a new user."""
        response = self._client.post(
            self.ENDPOINT,
            json=payload.model_dump(exclude_none=True),
        )
        response.raise_for_status()
        return UserResponse(**response.json())

    def get_user(self, user_id: int) -> UserResponse:
        """GET /api/v1/users/{id} — retrieve user by ID."""
        response = self._client.get(f"{self.ENDPOINT}/{user_id}")
        response.raise_for_status()
        return UserResponse(**response.json())

    def list_users(
        self,
        page: int = 1,
        page_size: int = 20,
    ) -> UserListResponse:
        """GET /api/v1/users — list users with pagination."""
        response = self._client.get(
            self.ENDPOINT,
            params={"page": page, "page_size": page_size},
        )
        response.raise_for_status()
        return UserListResponse(**response.json())

    def update_user(self, user_id: int, payload: CreateUserRequest) -> UserResponse:
        """PUT /api/v1/users/{id} — full update."""
        response = self._client.put(
            f"{self.ENDPOINT}/{user_id}",
            json=payload.model_dump(exclude_none=True),
        )
        response.raise_for_status()
        return UserResponse(**response.json())

    def delete_user(self, user_id: int) -> None:
        """DELETE /api/v1/users/{id}."""
        response = self._client.delete(f"{self.ENDPOINT}/{user_id}")
        response.raise_for_status()

    def get_user_raw_response(self, user_id: int) -> requests.Response:
        """
        Returns the raw Response object (not a model).
        Use ONLY in Layer 4 tests that need to assert on HTTP status
        codes or response headers directly (e.g., negative tests).
        """
        return self._client.get(f"{self.ENDPOINT}/{user_id}")
```

---

## Service Design Rules

### 1. Typed in, typed out
Every method signature uses model types. No `dict` parameters, no `Any` returns.
This makes the test code self-documenting and catches payload mistakes at IDE level.

### 2. `model_dump(exclude_none=True)`
Exclude `None` fields from the request body. APIs typically ignore missing optional
fields but reject `null` values for optional fields. Use `exclude_unset=True`
instead if the API distinguishes between "field not sent" and "field explicitly null".

### 3. `raise_for_status()` in service, not in test
Calling `raise_for_status()` here means Layer 4 tests can use `pytest.raises(HTTPError)`
to test error scenarios cleanly. Do not call it in the client layer — tests for
4xx scenarios need to receive the response without an exception first.

### 4. `get_raw_response` escape hatch
Some tests need the full `requests.Response` object (status code, headers, timing).
Provide one raw-response method per service as an explicit escape hatch.
This keeps the main service methods clean while still enabling HTTP-level assertions.

### 5. One service class per resource domain
Never mix User and Order operations in the same service class.
When the user's API grows, they create `order_service.py`, `product_service.py`, etc.
following the same structure.

---

## Adding a New Service

To add an `OrderService`, create `layer_3_services/order_service.py`:

```python
from layer_1_models.api.order_model import CreateOrderRequest, OrderResponse
from layer_2_clients.api.base_api_client import BaseApiClient


class OrderService:
    ENDPOINT = "/api/v1/orders"

    def __init__(self, client: BaseApiClient) -> None:
        self._client = client

    def create_order(self, payload: CreateOrderRequest) -> OrderResponse:
        response = self._client.post(self.ENDPOINT, json=payload.model_dump())
        response.raise_for_status()
        return OrderResponse(**response.json())

    def get_order(self, order_id: int) -> OrderResponse:
        response = self._client.get(f"{self.ENDPOINT}/{order_id}")
        response.raise_for_status()
        return OrderResponse(**response.json())
```

Zero changes to any other file needed.
