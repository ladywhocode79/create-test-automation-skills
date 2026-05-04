# automation-architect-nfr — Design Document

**Version:** 2.0.0
**Last Updated:** 2026-05-04
**Skill:** automation-architect-nfr
**Invoked by:** User explicitly — never invoked automatically by the orchestrator

---

## Overview

This document captures every design decision and architectural rationale for the NFR
(Non-Functional Testing) skill. This is a **Phase 2 skill** — it extends an existing,
stable Phase 1 functional test suite with performance, security, and chaos testing.

This skill is intentionally gated. It does not activate until the functional baseline is
stable and the CI pipeline is reliably green. Premature NFR testing wastes cycles — running
load tests against untested endpoints or security scans against an unstable API produces
noise, not signal.

**What this skill does:**
1. Checks four gate conditions before generating anything
2. Runs a discovery interview to select NFR tracks (performance / security / chaos)
3. Generates additive files only — never touches Phase 1 scaffold files
4. Adds new CI jobs to existing pipeline files (appended, not replaced)

**Three NFR tracks:**
- **Track A — Performance/Load:** k6 (default), Locust (Python track), Gatling (Java track)
- **Track B — Security:** OWASP ZAP passive scan (per-PR) + active scan (nightly)
- **Track C — Chaos/Resilience:** WireMock fault stubs + Toxiproxy network injection

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  automation-architect-nfr  (user-invocable, Phase 2 only)                  │
│                                                                             │
│  Activation: User explicitly triggers /automation-architect-nfr            │
│  NEVER auto-activates. Gate check runs first, always.                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │       Block 1: Gate Check      │
                    │  All 4 gates must pass         │
                    │  Gate 1: API coverage          │
                    │  Gate 2: UI coverage (if UI)   │
                    │  Gate 3: CI stability          │
                    │  Gate 4: Explicit activation   │
                    └───────────────┬───────────────┘
                                    │
                         Gates pass ↓  Gates fail → stop + message
                                    │
                    ┌───────────────▼───────────────┐
                    │   Block 2: Discovery Interview │
                    │  [A] Performance               │
                    │  [B] Security                  │
                    │  [C] Chaos                     │
                    │  [D] All                       │
                    └──────────────┬────────────────┘
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        ▼                          ▼                          ▼
┌──────────────────┐   ┌───────────────────────┐  ┌──────────────────────┐
│  Track A: Load   │   │  Track B: Security    │  │  Track C: Chaos      │
│                  │   │                       │  │                      │
│  k6 (default)   │   │  ZAP passive (per-PR) │  │  WireMock faults     │
│  Locust (Python) │   │  ZAP active (nightly) │  │  Toxiproxy (network) │
│  Gatling (Java)  │   │  zap-config.yaml      │  │  fault_stubs.json    │
│                  │   │                       │  │  test_resilience.*   │
│  layer_4_tests/  │   │  security/            │  │  layer_4_tests/      │
│  load/           │   │  zap-config.yaml      │  │  chaos/              │
│  thresholds.js   │   │  active-scan.yml      │  │                      │
└──────────────────┘   └───────────────────────┘  └──────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  4-Layer Compatibility (Phase 1 unchanged)                                  │
│                                                                             │
│  Layer 1 (Models)   → unchanged — response validation under load            │
│  Layer 2 (Client)   → minor addition: ZAP proxy URL for security scan      │
│  Layer 3 (Services) → unchanged — reused directly by load + chaos tests    │
│  Layer 4 (Tests)    → new subdirectories added only:                       │
│                         layer_4_tests/load/                                │
│                         layer_4_tests/security/                            │
│                         layer_4_tests/chaos/                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Logic Blocks

---

### Block 1 — Phase Gate Check

**Purpose:** Enforce that Phase 2 only activates on a stable functional baseline.
Running NFR tests against an unstable or incomplete functional suite produces false signal.

**Four gate conditions (all must pass):**

```
Gate 1: API test coverage
  [ ] layer_4_tests/api/ exists with at least 5 test files
  [ ] pytest.ini or testng.xml references "smoke" and "regression" markers/groups

Gate 2: UI test coverage (only checked if test_type includes UI)
  [ ] layer_4_tests/ui/ exists with at least 2 test files

Gate 3: CI pipeline stability
  [ ] .github/workflows/*.yml (or equivalent CI config) exists
  [ ] Evidence of CI runs: allure-results/ or reports/ directory exists

Gate 4: Explicit activation
  [ ] User explicitly triggered /automation-architect-nfr
      (required — this skill never activates automatically)
```

**Gate check behavior:**

Gate 4 is always true when the skill is running (user invoked it).
Gates 1–3 are checked by reading the project file structure.

If any of Gates 1–3 fail, output the stop message and halt:

```
Phase 2 (NFR) is not ready yet.

The recommended order is:
1. Complete your functional test suite (API and/or UI)  ← You are here
2. Get your CI pipeline green for 5+ consecutive runs
3. Then trigger /automation-architect-nfr

Current status:
  Gate 1 (API coverage): ✗ — layer_4_tests/api/ has only 2 files (need 5+)
  Gate 2 (UI coverage):  ✓ — layer_4_tests/ui/ found with 3 files
  Gate 3 (CI pipeline):  ✗ — no .github/workflows/ found

Come back when you're ready. I'll be here.
```

**Why gate check runs first, before any questions:**
Asking the user "which NFR tracks do you want?" before they are ready implies they
should proceed. The gate message communicates clearly what is missing — the user is
never left guessing why NFR is not available.

---

### Block 2 — Discovery Interview

**Purpose:** Determine which NFR tracks to activate. User selects one, many, or all.

```
Welcome to Phase 2. Your functional baseline is ready.

Which types of non-functional testing do you want to add?
(Select all that apply — enter A, B, C, or D)

  [A] Performance / Load Testing
      Validate response times and throughput under realistic load.
      Tools: k6 (recommended) | Gatling | Locust

  [B] API Security Testing
      Identify OWASP Top 10 API vulnerabilities.
      Tools: OWASP ZAP (passive + active scan)

  [C] Chaos / Resilience Testing
      Validate graceful degradation when dependencies fail.
      Tools: WireMock fault stubs + Toxiproxy

  [D] All of the above
```

**Tool pre-selection by language track:**

| Track A tool | Condition                          |
|--------------|------------------------------------|
| k6           | Default (all language tracks)      |
| Locust       | Python track selected in Phase 1   |
| Gatling      | Java track selected in Phase 1     |

The skill detects the Phase 1 language track by checking for `pytest.ini` (Python)
or `pom.xml` (Java) in the project root. k6 is offered as a secondary option even
when Locust or Gatling is the primary recommendation.

---

### Block 3 — Track A: Performance / Load Testing

**Purpose:** Validate API behavior under realistic and peak load. Measure response times
and throughput; fail the build when thresholds are breached.

**Generated files:**

```
layer_4_tests/load/
├── k6_user_api.js        ← k6 scenario (default / all tracks)
├── thresholds.js         ← p95 < 500ms, error_rate < 1%
├── locust_user_api.py    ← Locust file (Python track)
└── LOAD_TEST_README.md   ← run commands, threshold explanation

.github/workflows/
└── load-tests.yml        ← scheduled weekly, NOT per-PR
```

**k6 scenario — key pattern:**

```javascript
// layer_4_tests/load/k6_user_api.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { thresholds } from './thresholds.js';

export const options = {
    stages: [
        { duration: '30s', target: 10  },   // ramp up to 10 users
        { duration: '1m',  target: 10  },   // hold at 10 users
        { duration: '30s', target: 50  },   // ramp up to 50 users
        { duration: '1m',  target: 50  },   // hold at 50 users
        { duration: '30s', target: 0   },   // ramp down
    ],
    thresholds,
};

export default function () {
    const payload = JSON.stringify({
        username: `user_${Date.now()}`,
        email:    `user_${Date.now()}@example.com`,
        role:     'viewer',
    });

    const res = http.post(`${__ENV.BASE_URL}/api/v1/users`, payload, {
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${__ENV.API_TOKEN}`,
        },
    });

    check(res, {
        'status is 201':          (r) => r.status === 201,
        'has user id':            (r) => r.json('id') !== null,
        'response time < 500ms':  (r) => r.timings.duration < 500,
    });

    sleep(1);
}
```

**Thresholds file:**

```javascript
// layer_4_tests/load/thresholds.js
export const thresholds = {
    http_req_duration: ['p(95)<500'],    // 95th percentile under 500ms
    http_req_failed:   ['rate<0.01'],    // error rate under 1%
    checks:            ['rate>0.99'],    // 99% of checks pass
};
```

**Locust scenario (Python track):**

```python
# layer_4_tests/load/locust_user_api.py
from locust import HttpUser, task, between
from layer3.user_service import UserService
from layer1.factories.user_factory import UserFactory

class UserApiLoadTest(HttpUser):
    wait_time = between(1, 3)

    @task(3)                             # weight 3 — create is the hot path
    def create_user(self):
        payload = UserFactory.build()
        with self.client.post(
            "/api/v1/users",
            json=payload.model_dump(exclude_none=True),
            catch_response=True
        ) as response:
            if response.status_code != 201:
                response.failure(f"Expected 201, got {response.status_code}")

    @task(1)
    def get_user(self):
        self.client.get("/api/v1/users/1001")
```

**Key rule — Layer 3 reuse:**
k6 and Gatling call the same API endpoints as Layer 3 services. The load test
scenarios reproduce Layer 3's HTTP calls in the load tool's native syntax —
no new endpoint knowledge is needed. Layer 1 models document the payload structure
that load tests use. This is the 4-layer structure paying off: tests at different
levels describe the same contract.

**CI integration — weekly schedule, NOT per-PR:**

```yaml
# .github/workflows/load-tests.yml
on:
  schedule:
    - cron: '0 2 * * 1'   # every Monday at 2am UTC
  workflow_dispatch:        # allow manual trigger
```

Load tests run weekly (not per-PR) because:
- Individual commits rarely change performance characteristics
- Running 5-minute load tests on every PR quadruples CI time
- Performance regressions are caught by trend comparison, not commit-by-commit

**Key metrics captured:**

| Metric                | Threshold (default) | Purpose                       |
|-----------------------|---------------------|-------------------------------|
| `http_req_duration p95` | < 500ms           | 95th percentile response time |
| `http_req_failed rate`  | < 1%              | Error rate under load         |
| `checks rate`           | > 99%             | Assertion pass rate           |
| `http_reqs/s`           | (informational)   | Throughput at peak load       |

---

### Block 4 — Track B: Security Testing (OWASP ZAP)

**Purpose:** Identify OWASP Top 10 API vulnerabilities by intercepting functional test
traffic through ZAP. Zero additional test code required for passive scanning.

**Generated files:**

```
security/
├── zap-config.yaml        ← scan rules, false positive suppressions
└── SECURITY_README.md     ← how to interpret findings, severity guide

.github/workflows/
├── api-tests.yml          ← existing file: ZAP proxy added to test step
└── security-scan.yml      ← new: nightly active scan (separate job)
```

**How ZAP passive scan works — zero test code changes:**

```
[Functional test]
      ↓
[Layer 2 BaseApiClient]  ← base_url points at ZAP proxy
      ↓
[ZAP Proxy (localhost:8090)]  ← intercepts every request
      ↓
[Real API or WireMock]
      ↓
[ZAP passive analysis] ← inspects all traffic, no additional requests
```

The existing functional tests drive all API traffic. ZAP passively inspects
every request and response looking for security issues (missing headers, sensitive
data in responses, etc.) — no separate security test code is written.

**ZAP proxy setup in CI:**

```yaml
# In existing .github/workflows/api-tests.yml — appended, not replaced
services:
  zap:
    image: ghcr.io/zaproxy/zaproxy:stable
    ports:
      - 8090:8090
    command: zap.sh -daemon -port 8090 -host 0.0.0.0
              -config api.disablekey=true

# In existing test step — only change: proxy env var added
- name: Run API tests with ZAP proxy
  run: pytest layer_4_tests/ -m "smoke or regression"
  env:
    BASE_URL:   http://api.staging.yourcompany.com
    HTTP_PROXY: http://localhost:8090    # routes traffic through ZAP
    HTTPS_PROXY: http://localhost:8090

# New step after tests complete:
- name: ZAP passive scan report
  run: |
    curl http://localhost:8090/JSON/alert/view/alerts/ > zap-alerts.json
    # Fail if HIGH severity alerts found
    python security/check_zap_alerts.py zap-alerts.json --fail-on HIGH
```

**Active scan — separate nightly job:**

```yaml
# .github/workflows/security-scan.yml — new file
on:
  schedule:
    - cron: '0 1 * * *'    # nightly at 1am UTC
  workflow_dispatch:
```

Active scan is kept separate from passive scan because:
- Active scan sends malformed requests to the API (SQL injection attempts, etc.)
- Running active scans against a real staging API risks data corruption
- Active scan should only run against a dedicated security environment or sandboxed API

**OWASP API Top 10 checks covered:**

| OWASP API # | Vulnerability                                | ZAP check type |
|-------------|----------------------------------------------|----------------|
| API1        | Broken Object Level Authorization (BOLA)     | Passive        |
| API2        | Broken Authentication                        | Passive + Active|
| API3        | Broken Object Property Level Authorization   | Passive        |
| API5        | Broken Function Level Authorization          | Active         |
| API6        | Unrestricted Resource Consumption            | Active (rate)  |
| API8        | Security Misconfiguration                    | Passive (headers)|
| API10       | Unsafe Consumption of APIs                   | Passive        |

**`zap-config.yaml` — false positive suppression:**

```yaml
# security/zap-config.yaml
rules:
  ignore:
    - id: 10017      # Cross-Domain JavaScript Source File Inclusion — false positive
      url_pattern: ".*allure.*"
    - id: 10096      # Timestamp Disclosure — informational, not a vulnerability
  fail_on_severity: HIGH
  warn_on_severity: MEDIUM
```

---

### Block 5 — Track C: Chaos / Resilience Testing

**Purpose:** Validate graceful degradation when dependencies fail. Tests should confirm
the system handles timeouts, connection resets, and slow responses without crashing.

**Generated files:**

```
mocks/stubs/
└── fault_stubs.json       ← WireMock fault scenarios (added to existing stubs)

layer_4_tests/chaos/
├── test_resilience.py     ← Python: chaos test scenarios
│   test_resilience.java   ← Java: chaos test scenarios
└── CHAOS_README.md        ← how to run, what each scenario tests

.github/workflows/
└── chaos-tests.yml        ← new: nightly chaos job
```

**WireMock fault stubs — fault scenarios:**

```json
// mocks/stubs/fault_stubs.json (new file — does not replace user_stubs.json)
{
  "mappings": [
    {
      "name": "get-user-timeout",
      "priority": 1,
      "request": {
        "method": "GET",
        "urlPattern": "/api/v1/users/timeout-test"
      },
      "response": {
        "fixedDelayMilliseconds": 30000    // 30 second delay → triggers client timeout
      }
    },
    {
      "name": "get-user-connection-reset",
      "priority": 1,
      "request": {
        "method": "GET",
        "urlPattern": "/api/v1/users/reset-test"
      },
      "response": {
        "fault": "CONNECTION_RESET_BY_PEER"
      }
    },
    {
      "name": "get-user-empty-response",
      "priority": 1,
      "request": {
        "method": "GET",
        "urlPattern": "/api/v1/users/empty-test"
      },
      "response": {
        "fault": "EMPTY_RESPONSE"
      }
    },
    {
      "name": "post-user-service-unavailable",
      "priority": 1,
      "request": {
        "method": "POST",
        "urlPattern": "/api/v1/users/overload-test"
      },
      "response": {
        "status": 503,
        "fixedDelayMilliseconds": 2000,
        "jsonBody": {"error": "Service temporarily unavailable", "retry_after": 30}
      }
    }
  ]
}
```

**WireMock fault types:**

| Fault value               | What it simulates                          |
|---------------------------|--------------------------------------------|
| `CONNECTION_RESET_BY_PEER` | TCP connection reset mid-response         |
| `EMPTY_RESPONSE`           | Server closes connection with no response  |
| `MALFORMED_RESPONSE_CHUNK` | Corrupted HTTP response body               |
| `fixedDelayMilliseconds`   | Latency injection — triggers timeouts      |

**Python chaos tests:**

```python
# layer_4_tests/chaos/test_resilience.py
import pytest
from layer2.api_client import build_client
from mocks.wiremock_lifecycle import register_stub, reset_stubs

@pytest.mark.chaos
class TestResilienceScenarios:

    def test_timeout_triggers_retry_and_fails_gracefully(self, api_client):
        """
        When the API takes > request timeout, the client should:
        1. Raise a Timeout exception (not hang indefinitely)
        2. NOT retry a timeout (retries are for transient 5xx, not hangs)
        """
        with pytest.raises(requests.exceptions.Timeout):
            api_client.get("/api/v1/users/timeout-test")

    def test_connection_reset_raises_connection_error(self, api_client):
        """
        When TCP connection is reset, the client should raise ConnectionError —
        not return a 200 with empty body or silently swallow the error.
        """
        with pytest.raises(requests.exceptions.ConnectionError):
            api_client.get("/api/v1/users/reset-test")

    def test_service_unavailable_triggers_retry(self, api_client):
        """
        503 responses should trigger the retry mechanism (up to MAX_RETRIES times).
        The final attempt should raise an HTTPError (5xx), not return a 200.
        """
        with pytest.raises(requests.exceptions.HTTPError) as exc_info:
            api_client.get("/api/v1/users/overload-test")
        assert exc_info.value.response.status_code == 503
```

**Key rule — chaos tests in new directory only:**
Chaos scenarios are placed in `layer_4_tests/chaos/` — a new directory.
No changes to `layer_4_tests/api/` or `layer_4_tests/ui/`. This maintains the
principle that Phase 2 is purely additive. The chaos marker (`@pytest.mark.chaos`)
allows CI to run or skip chaos tests independently.

**Toxiproxy — network fault injection (advanced):**

Toxiproxy sits between the test client and WireMock (or real API), injecting
network-level faults: latency, bandwidth limits, connection drops. Used when
WireMock fault stubs are not sufficient (e.g., testing across a network boundary
in Docker Compose).

```yaml
# docker-compose additions for Toxiproxy
services:
  toxiproxy:
    image: ghcr.io/shopify/toxiproxy:2.9.0
    ports:
      - "8474:8474"    # Toxiproxy admin API
      - "8081:8081"    # Proxied WireMock port
    command: -host 0.0.0.0
```

```python
# Setup: route traffic through Toxiproxy → WireMock
# Tests use BASE_URL=http://localhost:8081 (Toxiproxy)
# Toxiproxy forwards to http://wiremock:8080
# Faults are added via Toxiproxy admin API at :8474
```

Toxiproxy is optional — most chaos scenarios are covered by WireMock fault stubs.
Toxiproxy is recommended only when testing network-level behavior (packet loss,
bandwidth throttling) that WireMock cannot simulate.

---

### Block 6 — Additive-Only Rule

**Purpose:** Phase 2 never modifies Phase 1 files. Every generated file is either new
or an additive change (appended section) to an existing CI file.

**Enforcement:**

Before writing any file, the skill checks:
1. Does this file exist already? → If yes, warn and ask for confirmation before overwriting
2. Is this a Phase 1 file? (`SKILL.md`, `layer_4_tests/api/`, `layer_4_tests/ui/`, `pom.xml`, `pytest.ini`, etc.) → Never overwrite under any circumstances
3. Is this a CI file? (`*.yml` in `.github/workflows/`) → Append new job, do not replace existing jobs

**CI file append pattern:**
Load test job is appended to a new file (`load-tests.yml`), not merged into `api-tests.yml`.
ZAP passive scan adds a new step to the existing `api-tests.yml` job — only a step is added,
not the entire job replaced.

**New directories created:**

```
layer_4_tests/
├── api/          ← Phase 1 — never touched
├── ui/           ← Phase 1 — never touched
├── load/         ← Phase 2A — new directory
├── security/     ← Phase 2B — new directory
└── chaos/        ← Phase 2C — new directory
```

---

### Block 7 — Planned Sub-Skill Structure

**Status:** The NFR orchestrator skill (this skill) is built. The sub-skills below
are documented here for when they are implemented. Their SKILL.md and reference files
will follow the same conventions as the language track skills.

```
~/.claude/skills/
├── automation-architect-nfr/          ← EXISTS (orchestrator — this skill)
│   ├── SKILL.md
│   └── DESIGN.md
│
├── automation-architect-perf/         ← PLANNED
│   ├── SKILL.md (user-invocable: false)
│   └── references/
│       ├── k6-scenarios.md
│       ├── gatling-scenarios.md
│       └── locust-scenarios.md
│
├── automation-architect-security/     ← PLANNED
│   ├── SKILL.md (user-invocable: false)
│   └── references/
│       ├── zap-passive-scan.md
│       ├── zap-active-scan.md
│       └── owasp-api-top10.md
│
└── automation-architect-chaos/        ← PLANNED
    ├── SKILL.md (user-invocable: false)
    └── references/
        ├── toxiproxy-setup.md
        ├── wiremock-fault-stubs.md
        └── chaos-test-patterns.md
```

Until the sub-skills are built, the NFR orchestrator generates all NFR files directly
from inline templates in its own SKILL.md. The sub-skill split is planned for v3.x —
it mirrors how the orchestrator delegates to `automation-architect-python` and
`automation-architect-java` in Phase 1.

---

## Design Decisions

---

### D1 — Phase 2 is Gated (Never Auto-Activates)

**Options considered:**

| Option | Approach                                       | Trade-offs                                              |
|--------|------------------------------------------------|---------------------------------------------------------|
| A      | Always gated — user must explicitly invoke     | Safe. User is never surprised by NFR tests appearing.   |
| B      | Auto-suggest after Phase 1 completes           | Convenient. May pressure user to skip gate conditions.  |
| C      | Time-delayed auto-suggest (e.g., after 10 runs)| Clever. Complex to implement and easy to ignore.        |

**Chosen:** Option A — always gated, explicit invocation only.

**Why:** Running load tests against an unstable or incomplete functional suite wastes cycles.
Security scans against an untested API produce noise — findings may relate to test gaps, not
real vulnerabilities. The gate conditions (5+ API test files, CI green, explicit trigger) ensure
NFR tests add signal, not noise. Automatic suggestion (Option B) creates implicit pressure to skip
gates — the skill should never make the user feel they should rush into Phase 2.

---

### D2 — k6 as Default Load Tool

**Options considered:**

| Option | Tool    | Language  | CI integration | Learning curve |
|--------|---------|-----------|----------------|----------------|
| A      | k6      | JavaScript| Native GitHub Actions service | Low — JS familiar |
| B      | Gatling | Scala/Java| Maven plugin + HTML reports | High — Scala DSL |
| C      | Locust  | Python    | pip install + headless mode | Low for Python teams |

**Chosen:** Option A — k6 as default, with Locust for Python track and Gatling for Java track.

**Why k6 is default:** k6 runs as a single binary with no runtime dependencies —
`brew install k6`, done. Its JavaScript syntax is familiar to most developers.
It has native Grafana Cloud integration for trend dashboards and outputs InfluxDB-compatible
metrics. CI integration is two lines: `docker run grafana/k6 run script.js`.

**Why also offer Locust for Python:** Python teams reuse their Faker/pydantic model knowledge
in Locust tasks. A `HttpUser.task` method reads identically to a pytest test — lower
cognitive overhead when reading load scenarios alongside functional tests.

**Why Gatling for Java:** Java teams already have Maven/Gradle. Gatling's Maven plugin
integrates naturally and produces detailed HTML reports that match the Allure report workflow.

---

### D3 — ZAP Passive Per-PR, Active Scan Nightly

**Options considered:**

| Option | Passive scan | Active scan | Trade-offs                                        |
|--------|-------------|-------------|---------------------------------------------------|
| A      | Per-PR      | Nightly     | Passive is fast + safe; active is slow + destructive |
| B      | Per-PR      | Per-PR      | Full coverage every commit. 20+ minute CI time.  |
| C      | Nightly     | Weekly      | No security signal on PRs.                        |

**Chosen:** Option A — passive per-PR, active nightly.

**Why:** Passive scan adds 30–60 seconds to the CI run (ZAP inspects existing test traffic —
no extra requests). Active scan sends thousands of malformed requests (SQLi, XSS payloads,
path traversal) — 20–45 minutes and risk of corrupting test data. Separating them ensures
every PR gets security signal without blocking the feedback loop, while active scan runs
nightly against a dedicated security environment.

**Active scan environment rule:** Active scan should NEVER run against a shared staging
environment — SQL injection payloads and brute-force attempts will corrupt data and trigger
WAF bans. A dedicated isolated environment (or against WireMock in mock mode) is required.

---

### D4 — WireMock Fault Stubs First, Toxiproxy as Optional Advanced

**Options considered:**

| Option | Tool                    | Trade-offs                                                 |
|--------|-------------------------|------------------------------------------------------------|
| A      | WireMock fault stubs only | Zero new dependencies. Limited to HTTP-layer faults.    |
| B      | Toxiproxy only          | Network-level faults. Requires Docker + extra container.  |
| C      | Both (WireMock default, Toxiproxy optional) | Covers HTTP and network faults. Complexity on demand. |

**Chosen:** Option C — WireMock fault stubs as default, Toxiproxy as opt-in.

**Why:** WireMock is already present (Phase 1 mock infrastructure). Adding fault stubs
requires zero new dependencies — just a new JSON file. WireMock covers the most common
chaos scenarios: timeouts, connection resets, 503 responses. Toxiproxy covers network-level
faults that WireMock cannot simulate (packet loss, bandwidth throttling, latency distribution).
Generating Toxiproxy config by default would add Docker complexity that most teams don't need.
It is generated only when the user explicitly asks for "network fault injection" or "Toxiproxy".

---

### D5 — Additive-Only Rule (Phase 1 Files Never Touched)

**Options considered:**

| Option | Approach                                  | Trade-offs                                            |
|--------|-------------------------------------------|-------------------------------------------------------|
| A      | Additive only — new files and append only | Safe. User's Phase 1 work is preserved.               |
| B      | Merge strategy — update existing files    | More integrated. Higher risk of breaking Phase 1.     |
| C      | Full regenerate — overwrite everything    | Simpler implementation. Destroys user's customizations.|

**Chosen:** Option A — additive only.

**Why:** Phase 1 scaffolds are customized by users after generation — they add test cases,
refactor helpers, and tweak configuration. Overwriting Phase 1 files would destroy that work.
The 4-layer structure makes additive-only natural: Layer 4 new subdirectories (`load/`, `chaos/`)
are completely separate from existing Layer 4 directories (`api/`, `ui/`). CI jobs are
appended to new workflow files, not inserted into existing ones.

**Conflict detection:** If the user ran Phase 2 before (unusual) and files already exist,
the skill detects the collision, lists the existing files, and asks for confirmation before
any overwrite. Default answer is "no" — preserve existing work.

---

### D6 — Layer 3 Services Reused Directly by Load Tests

**Options considered:**

| Option | Approach                                   | Trade-offs                                           |
|--------|--------------------------------------------|------------------------------------------------------|
| A      | Load tests call same API endpoints as Layer 3 | Consistent contracts. Layer 3 documents the API.  |
| B      | Load tests have separate endpoint definitions | Duplicate knowledge. Drift risk.                 |
| C      | Load tests use Layer 3 service classes directly | Maximum reuse. Python-only (Locust). Not k6-compatible. |

**Chosen:** Option A for k6/Gatling, Option C for Locust (Python track).

**Why:** k6 and Gatling are not Python/JVM — they cannot import Layer 3 service classes.
They reproduce the same HTTP calls from the same Layer 1 model documentation. The contract
is the same; only the implementation syntax differs. Locust (Python) can import service
classes directly — `UserFactory.build()` generates the same payload, `UserService.create_user()`
performs the same call. This is the maximum reuse scenario and is exclusive to the Python track.

The key insight: **Layer 3 is the load test specification.** The load test author reads
`UserService.createUser()` to know the endpoint, payload shape, and expected response.
No separate API documentation is needed.

---

### D7 — NFR Tests in Separate Subdirectories (Not Mixed with Functional)

**Options considered:**

| Option | Approach                              | Trade-offs                                           |
|--------|---------------------------------------|------------------------------------------------------|
| A      | Separate `load/`, `security/`, `chaos/` subdirectories | Clear separation. CI can run each independently. |
| B      | Mixed into existing `api/` directory with markers | Fewer directories. Load tests mixed with unit tests. |
| C      | Separate top-level `nfr_tests/` directory | Maximum separation. Breaks the Layer 4 naming convention. |

**Chosen:** Option A — subdirectories within `layer_4_tests/`.

**Why:** The `layer_4_tests/` convention is established in Phase 1. Adding subdirectories
(`load/`, `chaos/`) preserves the convention while cleanly separating NFR from functional.
CI can run each category independently: `pytest layer_4_tests/chaos/` for chaos only,
`pytest layer_4_tests/api/ layer_4_tests/ui/` for functional only. Mixing (Option B)
would require marker-based filtering to isolate NFR tests — fragile when markers are forgotten.

---

## Known Limitations

1. **Sub-skills not yet built** — The NFR orchestrator generates all content inline.
   The planned `automation-architect-perf`, `automation-architect-security`, and
   `automation-architect-chaos` sub-skills are documented (Block 7) but not implemented.
   Their reference files will be built in v3.x.

2. **No real API baseline required for WireMock chaos** — Chaos tests run against WireMock
   fault stubs, which means they test the client's error handling, not the real API's
   resilience. Testing real API resilience requires a staging environment with real
   network fault injection (Toxiproxy or cloud chaos tools like AWS Fault Injection Simulator).

3. **ZAP active scan requires dedicated environment** — Active scan sends destructive
   payloads. Running it against a shared staging environment risks data corruption and
   WAF bans. This is documented in `SECURITY_README.md` but is a team responsibility to enforce.

4. **Gatling requires Scala knowledge** — Gatling's simulation DSL is Scala. Java teams
   unfamiliar with Scala will find k6 easier. Gatling is offered as a secondary option;
   the default for Java track is still k6 unless the user specifically requests Gatling.

5. **Gate 3 check is heuristic** — The skill checks for `allure-results/` or `reports/`
   directories as evidence of CI runs. A team that stores reports elsewhere (S3, Artifactory)
   will fail Gate 3 even if CI is healthy. The gate message explains this and allows the user
   to confirm CI is stable and proceed manually.

---

## Open Questions / Future Options

### O1 — ReportPortal Integration for NFR Trend Dashboards
Load test metrics should be compared across runs to detect regression.
ReportPortal (already in the Phase 1 reporting options) supports metric dashboards.
k6 can push metrics to InfluxDB → Grafana for trend visualization.
Planned: add `references/k6-influxdb-grafana.md` in v3.x.

### O2 — Gatling Sub-Skill for Java Track
Full Gatling reference with simulation DSL, Maven plugin config, HTML report configuration.
Planned for `automation-architect-perf/references/gatling-scenarios.md` in v3.x.

### O3 — Contract Testing (Pact) as Track D
Consumer-driven contract testing (Pact) fits between functional and NFR.
It validates API contracts between consumer (tests) and provider (API) without a live server.
Planned as Track D in v2.x discovery interview.

---

*End of automation-architect-nfr DESIGN.md v2.0.0*
