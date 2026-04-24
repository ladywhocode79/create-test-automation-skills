# Layer 2 — HTTP Client (Python / requests)

Generate these files for the API profile.

---

## layer_2_clients/api/base_api_client.py

```python
from __future__ import annotations

import time
from typing import Any

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from config.env_config import settings
from config.logger import get_logger

logger = get_logger(__name__)


class BaseApiClient:
    """
    Base HTTP client for all API calls.

    Manages the requests Session lifecycle:
    - Base URL from environment config
    - Auth token injected per request via AuthManager
    - Automatic retry on transient server errors
    - Structured response logging at Layer 2 only
    """

    def __init__(self, token: str | None = None) -> None:
        self.base_url = settings.base_url.rstrip("/")
        self.session = self._build_session(token)

    def _build_session(self, token: str | None) -> requests.Session:
        session = requests.Session()
        session.headers.update({
            "Content-Type": "application/json",
            "Accept": "application/json",
        })
        if token:
            session.headers["Authorization"] = f"Bearer {token}"

        retry_strategy = Retry(
            total=settings.max_retries,
            backoff_factor=settings.retry_backoff_factor,
            status_forcelist=[500, 502, 503, 504],
            allowed_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
            raise_on_status=False,
        )
        adapter = HTTPAdapter(max_retries=retry_strategy)
        session.mount("https://", adapter)
        session.mount("http://", adapter)
        session.hooks["response"].append(self._log_response)
        return session

    def _log_response(
        self,
        response: requests.Response,
        *args: Any,
        **kwargs: Any,
    ) -> None:
        elapsed_ms = round(response.elapsed.total_seconds() * 1000)
        logger.info(
            "%s %s → %s (%dms)",
            response.request.method,
            response.url,
            response.status_code,
            elapsed_ms,
        )
        if settings.log_level == "DEBUG":
            logger.debug("Response body: %s", response.text[:500])

    def get(self, endpoint: str, **kwargs: Any) -> requests.Response:
        return self.session.get(f"{self.base_url}{endpoint}", **kwargs)

    def post(self, endpoint: str, **kwargs: Any) -> requests.Response:
        return self.session.post(f"{self.base_url}{endpoint}", **kwargs)

    def put(self, endpoint: str, **kwargs: Any) -> requests.Response:
        return self.session.put(f"{self.base_url}{endpoint}", **kwargs)

    def patch(self, endpoint: str, **kwargs: Any) -> requests.Response:
        return self.session.patch(f"{self.base_url}{endpoint}", **kwargs)

    def delete(self, endpoint: str, **kwargs: Any) -> requests.Response:
        return self.session.delete(f"{self.base_url}{endpoint}", **kwargs)
```

---

## layer_2_clients/api/real_api_client.py (generated when mock=both)

```python
from layer_2_clients.api.base_api_client import BaseApiClient
from config.env_config import settings


class RealApiClient(BaseApiClient):
    """Points at the real API base URL."""

    def __init__(self, token: str | None = None) -> None:
        # base_url already set to real URL in BaseApiClient via settings
        super().__init__(token=token)
```

---

## layer_2_clients/api/mock_api_client.py (generated when mock=both)

```python
from layer_2_clients.api.base_api_client import BaseApiClient


class MockApiClient(BaseApiClient):
    """Points at WireMock stub server."""

    def __init__(self, token: str | None = None) -> None:
        super().__init__(token=token)
        # Override base_url to point at WireMock
        self.base_url = "http://localhost:8080"
        self.session.headers.update({"X-Test-Mode": "mock"})
```

---

## config/client_factory.py (generated when mock=both)

```python
from __future__ import annotations

from config.env_config import settings
from layer_2_clients.api.base_api_client import BaseApiClient
from layer_2_clients.api.mock_api_client import MockApiClient
from layer_2_clients.api.real_api_client import RealApiClient


class ClientFactory:
    """
    Strategy pattern: return the correct client implementation
    based on TEST_MODE environment variable.

    TEST_MODE=real  → RealApiClient (hits live API)
    TEST_MODE=mock  → MockApiClient (hits WireMock at localhost:8080)
    """

    @staticmethod
    def build(token: str | None = None) -> BaseApiClient:
        mode = settings.test_mode.lower()
        if mode == "mock":
            return MockApiClient(token=token)
        if mode == "real":
            return RealApiClient(token=token)
        raise ValueError(
            f"Unsupported TEST_MODE='{mode}'. Expected 'real' or 'mock'."
        )
```

---

## requirements.txt entries for Layer 2

```
requests>=2.31.0
urllib3>=2.0.0
```

---

## Key Design Rules Enforced

1. **Auth is injected, not fetched** — BaseApiClient receives a token string.
   It never calls AuthManager directly. AuthManager is called in conftest.py
   and the token is passed to the client. This keeps Layer 2 ignorant of auth logic.

2. **No assertions here** — `raise_for_status()` is NOT called automatically
   in the base client. It is called in Layer 3 service methods. This allows
   Layer 4 tests to assert on non-2xx responses when testing error scenarios.

3. **Retry only on safe conditions** — Retry is configured only for 5xx errors
   and only for all HTTP methods. 4xx errors (client errors) are NOT retried.

4. **Logging at INFO is safe** — Authorization header value is never logged.
   Response body is only logged at DEBUG level (controlled by LOG_LEVEL env var).
