# NFR Roadmap — Phase 2 Design

Non-Functional Testing (NFR) is planned as Phase 2 of the automation-architect
skill suite. It is intentionally deferred until the functional baseline is
stable and the CI pipeline is reliably green.

This file is included in the NEXT STEPS output after every Phase 1 scaffold
generation so users know what is coming and what gate conditions to meet.

---

## Phase Gate Conditions

Phase 2 (NFR) activates ONLY when ALL of the following are true:

```
Gate 1: API test suite coverage
  [ ] Layer 4 API tests cover >= 80% of planned API endpoints
  [ ] All smoke-tagged tests pass in CI (zero flaky failures)

Gate 2: UI test suite coverage (if test_type includes UI)
  [ ] Critical user flows are covered (login, core feature, error states)
  [ ] Screenshot artifacts are being captured in CI on failure

Gate 3: CI pipeline stability
  [ ] CI pipeline is green for at least 5 consecutive runs
  [ ] At least one non-development environment (staging or prod) is tested

Gate 4: Explicit activation
  [ ] User triggers: /automation-architect-nfr
```

Meeting gates 1-3 without gate 4 does NOT activate Phase 2.
The skill will never automatically transition to NFR testing.

---

## NFR Testing Scope (Phase 2 Plan)

### 2A — Performance / Load Testing

**Skill**: `automation-architect-perf`

Goal: Validate API and/or UI behavior under realistic and peak load conditions.

```
Tools:
  k6          — JavaScript-based, excellent CI integration, cloud option
  Gatling     — Scala/Java DSL, enterprise-grade, detailed HTML reports
  Locust      — Python, same language as functional tests if Python track used

Architecture fit:
  Layer 3 (Service) methods are reused directly by load test scenarios
  — no rewrite of endpoint calls needed.
  Only Layer 4 changes: load test scenarios replace pytest test methods.

Key metrics to capture:
  - Response time (p50, p90, p95, p99)
  - Throughput (requests/second)
  - Error rate under load
  - Concurrency ceiling (where error rate exceeds threshold)

CI integration:
  - Run performance baseline weekly (not on every PR)
  - Fail build if p95 response time exceeds configured threshold
  - Store baseline metrics for trend comparison
```

### 2B — Security Testing

**Skill**: `automation-architect-security`

Goal: Identify OWASP Top 10 API vulnerabilities and common web security issues.

```
Tools:
  OWASP ZAP   — API scanning, active scan, OpenAPI import
  Burp Suite  — Enterprise API scanning (requires license)
  Trivy       — Container and dependency vulnerability scanning

Architecture fit:
  Layer 2 (Client) base URL is pointed at ZAP proxy instead of direct API.
  ZAP intercepts all requests made by functional tests and performs
  passive analysis — zero additional test code required for passive scan.
  Active scan is a separate ZAP-driven step.

Key checks:
  - SQL injection via API parameters
  - Authentication bypass
  - Broken object level authorization (BOLA/IDOR)
  - Sensitive data exposure in responses
  - Insecure direct object references
  - Rate limiting absence

CI integration:
  - Run ZAP passive scan on every PR (fast, non-destructive)
  - Run ZAP active scan nightly or on release branches only
  - Fail build on HIGH severity findings; report MEDIUM as warnings
```

### 2C — Chaos / Resilience Testing

**Skill**: `automation-architect-chaos`

Goal: Validate system behavior when dependencies fail (timeouts, errors,
partial failures). Ensure graceful degradation.

```
Tools:
  Toxiproxy   — Network fault injection (latency, bandwidth, errors)
                Works with WireMock: proxy sits between client and WireMock
  Chaos Monkey — Service-level termination (for microservices)
  WireMock fault simulation — Already included in Phase 1 WireMock setup:
    {"fault": "CONNECTION_RESET_BY_PEER"}
    {"fixedDelayMilliseconds": 5000}

Architecture fit:
  Uses the same Layer 3 services and Layer 4 test structure.
  Chaos scenarios are new test classes in layer_4_tests/chaos/
  tagged with @pytest.mark.chaos or @Test(groups={"chaos"}).

Key scenarios:
  - Auth service timeout (what happens to token refresh?)
  - Downstream API returning 503 (does retry logic kick in?)
  - Network latency injection (do timeouts trigger correctly?)
  - Partial response / truncated body handling
```

---

## NFR Skill Structure (Phase 2)

When built, the NFR sub-skills will follow the same skill suite conventions:

```
~/.claude/skills/
├── automation-architect-perf/
│   ├── SKILL.md               (user-invocable: false — only from automation-architect-nfr)
│   └── references/
│       ├── k6-scenarios.md
│       ├── gatling-scenarios.md
│       └── locust-scenarios.md
│
├── automation-architect-security/
│   ├── SKILL.md
│   └── references/
│       ├── zap-passive-scan.md
│       ├── zap-active-scan.md
│       └── owasp-api-top10.md
│
└── automation-architect-chaos/
    ├── SKILL.md
    └── references/
        ├── toxiproxy-setup.md
        ├── wiremock-fault-stubs.md
        └── chaos-test-patterns.md
```

The gating `automation-architect-nfr` skill orchestrates the above three.

---

## Phase 2 Upgrade Path

When the user triggers `/automation-architect-nfr`, the NFR orchestrator will:

1. Read the existing Phase 1 scaffold (detect language, tools, CI platform)
2. Confirm which NFR tracks to add (perf / security / chaos / all)
3. Generate additive files only — never overwrite Phase 1 files
4. Add new CI jobs to existing pipeline files (do not replace them)
5. Preview changes using the same preview-format.md convention
6. Wait for confirmation before writing

The 4-layer structure is NFR-compatible by design:
- Layer 3 (Service/Page) works unchanged for load and chaos scenarios
- Layer 1 (Model) works unchanged for response validation under load
- Layer 2 (Client) needs only minor additions (ZAP proxy config, Toxiproxy URL)
- Layer 4 gets new test subdirectories: `layer_4_tests/load/`, `layer_4_tests/security/`, `layer_4_tests/chaos/`
