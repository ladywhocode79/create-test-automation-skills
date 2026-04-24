# Shared — Environment Config (Python / pydantic-settings)

Generate these files for all profiles (API, UI, Full-Stack).

---

## config/env_config.py

```python
from __future__ import annotations

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class EnvConfig(BaseSettings):
    """
    Centralised environment configuration.

    All external values (URLs, credentials, feature flags) are read here.
    No other file in the project should read os.environ directly.

    Loaded from:
    1. Environment variables (highest priority)
    2. .env file in the project root (local development)

    Startup validation: if a required field is missing, pydantic-settings
    raises a clear ValidationError BEFORE any test runs, not mid-suite.
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,          # BASE_URL and base_url both work
        extra="ignore",                # ignore unknown env vars
    )

    # ── API Configuration ──────────────────────────────────────────────────
    base_url: str                      # required — no default (fails fast)
    test_mode: str = "mock"            # "real" | "mock"

    # ── Auth Configuration (included when auth != none) ───────────────────
    token_url: str = ""
    client_id: str = ""
    client_secret: str = ""
    api_token: str = ""                # for Bearer/JWT static token
    api_key: str = ""                  # for API Key auth

    # ── HTTP Client Configuration ──────────────────────────────────────────
    max_retries: int = 3
    retry_backoff_factor: float = 0.3
    request_timeout: int = 30          # seconds

    # ── UI Configuration (included when test_type includes UI) ─────────────
    aut_base_url: str = "http://localhost:3000"
    browser: str = "chromium"          # chromium | firefox | webkit
    headless: bool = True
    slow_mo_ms: int = 0
    default_timeout_ms: int = 10000
    navigation_timeout_ms: int = 30000
    record_video: bool = False
    test_username: str = ""
    test_password: str = ""

    # ── WireMock (included when mock selected) ─────────────────────────────
    wiremock_base_url: str = "http://localhost:8080"

    # ── Reporting ──────────────────────────────────────────────────────────
    log_level: str = "INFO"            # INFO | DEBUG | WARNING | ERROR

    # ── ReportPortal (included when reporting = ReportPortal) ─────────────
    rp_endpoint: str = ""
    rp_uuid: str = ""
    rp_project: str = ""

    @field_validator("test_mode")
    @classmethod
    def test_mode_must_be_valid(cls, v: str) -> str:
        allowed = {"real", "mock"}
        if v.lower() not in allowed:
            raise ValueError(f"TEST_MODE must be one of {allowed}, got '{v}'")
        return v.lower()

    @field_validator("browser")
    @classmethod
    def browser_must_be_valid(cls, v: str) -> str:
        allowed = {"chromium", "firefox", "webkit"}
        if v.lower() not in allowed:
            raise ValueError(f"BROWSER must be one of {allowed}, got '{v}'")
        return v.lower()

    @field_validator("log_level")
    @classmethod
    def log_level_must_be_valid(cls, v: str) -> str:
        allowed = {"DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"}
        if v.upper() not in allowed:
            raise ValueError(f"LOG_LEVEL must be one of {allowed}")
        return v.upper()


# Module-level singleton — imported everywhere as `from config.env_config import settings`
settings = EnvConfig()
```

---

## .env.example

```bash
# ── API Configuration ──────────────────────────────────────────────────────
BASE_URL=https://api.staging.yourcompany.com

# Set to "mock" to use WireMock stubs, "real" to hit the live API
TEST_MODE=mock

# ── Auth Configuration (fill in based on your auth type) ──────────────────
# OAuth2 Client Credentials:
TOKEN_URL=https://auth.yourcompany.com/oauth/token
CLIENT_ID=your-client-id
CLIENT_SECRET=your-client-secret

# Bearer / JWT (static token):
# API_TOKEN=your-static-token

# API Key:
# API_KEY=your-api-key

# ── HTTP Client ────────────────────────────────────────────────────────────
MAX_RETRIES=3
RETRY_BACKOFF_FACTOR=0.3
REQUEST_TIMEOUT=30

# ── UI Configuration ───────────────────────────────────────────────────────
AUT_BASE_URL=http://localhost:3000
BROWSER=chromium
HEADLESS=true
SLOW_MO_MS=0
DEFAULT_TIMEOUT_MS=10000
NAVIGATION_TIMEOUT_MS=30000
RECORD_VIDEO=false
TEST_USERNAME=test@example.com
TEST_PASSWORD=

# ── WireMock ───────────────────────────────────────────────────────────────
WIREMOCK_BASE_URL=http://localhost:8080

# ── Reporting ──────────────────────────────────────────────────────────────
LOG_LEVEL=INFO

# ReportPortal (if using ReportPortal reporter):
# RP_ENDPOINT=http://localhost:8080
# RP_UUID=your-rp-api-key
# RP_PROJECT=your-project-name
```

---

## requirements.txt entries

```
pydantic-settings>=2.2.0
pydantic>=2.6.0
python-dotenv>=1.0.0     # loaded automatically by pydantic-settings
```

---

## Key Design Decisions

1. **`settings = EnvConfig()`** at module level: the config is loaded once
   at import time. Any misconfiguration (missing required var, invalid value)
   fails at collection time, before any test runs.

2. **`extra="ignore"`**: Unknown env vars are silently ignored. This prevents
   failures when running in environments that inject many CI-specific vars.

3. **`case_sensitive=False`**: Allows `BASE_URL`, `base_url`, `Base_Url`
   to all map to the same setting. Prevents common CI/local discrepancies.

4. **No secrets have defaults**: `base_url`, `token_url`, etc. have no
   default values. If they are missing, pydantic-settings raises:
   ```
   pydantic_core.InitErrorDetails: Field required [type=missing, ...]
   ```
   This is the desired behavior: fail loudly before any test runs.

5. **Only `LOG_LEVEL`, `TEST_MODE`, and non-secret operational settings
   have defaults.** Defaults should only exist for values that are safe and
   reasonable to omit in all environments.
