# Shared — Logger (Python)

Generate `config/logger.py` for all profiles.

---

## config/logger.py

```python
from __future__ import annotations

import logging
import sys

from config.env_config import settings


def get_logger(name: str) -> logging.Logger:
    """
    Return a configured logger for the given module name.

    Usage:
        from config.logger import get_logger
        logger = get_logger(__name__)

    Rules:
    - Always pass __name__ — creates a logger hierarchy that mirrors package structure
    - Level controlled by LOG_LEVEL env var (default: INFO)
    - Single handler per logger (prevents duplicate log lines in pytest)
    - Format: timestamp | level | module | message
    """
    logger = logging.getLogger(name)

    if logger.handlers:
        # Already configured — return as-is to prevent duplicate handlers
        return logger

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(
        logging.Formatter(
            fmt="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
    )
    logger.addHandler(handler)
    logger.setLevel(getattr(logging, settings.log_level, logging.INFO))
    logger.propagate = False   # prevent double-logging if root logger also has handlers
    return logger
```

---

## Usage Rules

```python
# In Layer 2 (BaseApiClient) — correct usage:
from config.logger import get_logger
logger = get_logger(__name__)

def _log_response(self, response, *args, **kwargs):
    logger.info("%s %s → %s", response.request.method, response.url, response.status_code)

# In Layer 2 (BrowserSession) — correct usage:
logger.info("Browser launched: %s (headless=%s)", browser_type, settings.headless)

# In Layer 4 tests — NEVER use logger:
# Tests do not log. They assert. Logging belongs in the infrastructure layers.
```

---

## What to Log (and What Not To)

| Layer | Log? | What |
|---|---|---|
| Layer 2 (Client) | Yes | request method, URL, status code, elapsed ms |
| Layer 2 (Browser) | Yes | browser launch, context creation, teardown |
| Config (AuthManager) | Yes | token fetch events (not credential values) |
| Layer 3 (Services/Pages) | Rarely | only on retry or exceptional conditions |
| Layer 4 (Tests) | Never | tests assert, never log |

| Content | Log at INFO? | Log at DEBUG? | Never log |
|---|---|---|---|
| Request method + URL | Yes | Yes | — |
| Response status code | Yes | Yes | — |
| Response time (ms) | Yes | Yes | — |
| Request body | No | Yes (truncated) | — |
| Response body | No | Yes (truncated) | — |
| Auth header value | No | No | Always |
| Credentials (secrets) | No | No | Always |
| User PII in payloads | No | No | Always |
