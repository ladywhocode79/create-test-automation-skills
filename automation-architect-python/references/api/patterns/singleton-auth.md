# Pattern: Singleton — Auth Manager (Python / API)

Generate `config/auth_manager.py` when auth != none.

---

## config/auth_manager.py — OAuth2 Client Credentials

```python
from __future__ import annotations

import threading
import time

import requests

from config.env_config import settings
from config.logger import get_logger

logger = get_logger(__name__)


class AuthManager:
    """
    Singleton token manager for OAuth2 Client Credentials flow.

    Guarantees:
    - Token is fetched exactly once per session (or after expiry)
    - Thread-safe: concurrent test threads won't trigger simultaneous refreshes
    - Token is refreshed 30 seconds before actual expiry (buffer)
    - Credentials are never logged
    """

    _instance: AuthManager | None = None
    _lock: threading.Lock = threading.Lock()

    def __new__(cls) -> AuthManager:
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super().__new__(cls)
                    cls._instance._token: str | None = None
                    cls._instance._expires_at: float = 0.0
        return cls._instance

    def get_token(self) -> str:
        """Return a valid access token, refreshing if needed."""
        with self._lock:
            if self._is_token_expired():
                self._refresh()
            return self._token  # type: ignore[return-value]

    def _is_token_expired(self) -> bool:
        buffer_seconds = 30
        return time.time() >= (self._expires_at - buffer_seconds)

    def _refresh(self) -> None:
        logger.info("Fetching new access token from %s", settings.token_url)
        response = requests.post(
            settings.token_url,
            data={
                "grant_type": "client_credentials",
                "client_id": settings.client_id,
                "client_secret": settings.client_secret,
            },
            timeout=10,
        )
        response.raise_for_status()
        data = response.json()
        self._token = data["access_token"]
        self._expires_at = time.time() + data.get("expires_in", 3600)
        logger.info(
            "Access token acquired. Expires in %d seconds.",
            data.get("expires_in", 3600),
        )

    def invalidate(self) -> None:
        """Force token refresh on next get_token() call. Useful for testing."""
        with self._lock:
            self._expires_at = 0.0
```

---

## config/auth_manager.py — Bearer / JWT (static token)

Use this variant when the token is provided directly via env var (no token endpoint).

```python
from __future__ import annotations

from config.env_config import settings
from config.logger import get_logger

logger = get_logger(__name__)


class AuthManager:
    """
    Simple auth manager for static Bearer token configuration.
    Token is read from API_TOKEN environment variable.
    """

    _instance: AuthManager | None = None

    def __new__(cls) -> AuthManager:
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def get_token(self) -> str:
        return settings.api_token
```

---

## config/auth_manager.py — API Key

```python
from __future__ import annotations

from config.env_config import settings


class AuthManager:
    """Auth manager for API Key header authentication."""

    _instance: AuthManager | None = None

    def __new__(cls) -> AuthManager:
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def get_api_key(self) -> str:
        return settings.api_key

    def get_token(self) -> str:
        """Alias for compatibility with BaseApiClient token injection."""
        return self.get_api_key()
```

When API Key auth is selected, the BaseApiClient must be updated to use
a different header (e.g., `X-API-Key`) instead of `Authorization: Bearer`.
This is handled in the Layer 2 generation.

---

## Singleton Pattern — Key Points

1. **Double-checked locking**: The outer `if` check avoids lock acquisition
   on every call (performance). The inner `if` check inside the lock handles
   the race condition between two threads both passing the outer check.

2. **`invalidate()` method**: Allows tests to force token refresh without
   restarting the session. Useful for testing token expiry behavior:
   ```python
   auth_manager.invalidate()
   token = auth_manager.get_token()  # triggers a fresh fetch
   ```

3. **Never log credentials**: The `client_id` and `client_secret` are never
   passed to the logger. The token value itself is never logged.

4. **Timeout on token request**: The `requests.post` call has a 10-second
   timeout. Token endpoint slowness should not cause indefinite hangs.

5. **`expires_in` fallback**: If the token response omits `expires_in`,
   default to 3600 seconds (1 hour) rather than crashing.
