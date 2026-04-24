---
name: automation-architect-nfr
description: >
  Phase 2 Non-Functional Testing skill for the automation-architect suite.
  Activates ONLY when the user explicitly requests it AND has met the Phase 1
  gate conditions. Use when user mentions "load testing", "performance testing",
  "security testing", "chaos testing", "NFR", "non-functional",
  "k6", "Gatling", "Locust", "OWASP ZAP", or "Toxiproxy" in the context
  of their existing automation-architect scaffold.
version: 2.0.0
tools: Read, Glob, Write
---

# NFR Skill — Phase 2 (Gated)

This skill extends an existing automation-architect Phase 1 scaffold with
non-functional testing capabilities.

## Gate Check (Run First)

Before generating anything, check whether Phase 1 gate conditions are met.

Read the project structure to verify:

```
Gate 1: API test coverage
  [ ] layer_4_tests/api/ directory exists with at least 5 test files
  [ ] pytest.ini or testng.xml references "smoke" and "regression" markers

Gate 2: UI test coverage (if project has UI tests)
  [ ] layer_4_tests/ui/ directory exists with at least 2 test files

Gate 3: CI pipeline
  [ ] .github/workflows/*.yml (or equivalent) exists
  [ ] CI has run at least once (check for allure-results/ or reports/)

Gate 4: Explicit activation
  [ ] User explicitly triggered /automation-architect-nfr or asked for NFR
      (required — this skill never activates automatically)
```

If Gates 1-3 are NOT met, output this message and stop:

```
Phase 2 (NFR) is not ready yet.

The recommended order is:
1. Complete your functional test suite (API and/or UI) ← You are here
2. Get your CI pipeline green for 5+ consecutive runs
3. Then trigger /automation-architect-nfr

This sequencing ensures NFR tests run against a stable functional baseline.
Running load or security tests against untested endpoints wastes cycles.

Current status based on your project:
  {list which gates are passed/failed with brief explanation}

Come back when you're ready. I'll be here.
```

If all gates ARE met, proceed to the Discovery section.

---

## Discovery Interview

Ask these questions before generating anything:

```
Welcome to Phase 2. Your functional baseline is ready.

Which types of non-functional testing do you want to add?
(Select all that apply)

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

---

## Output per Selection

### [A] Performance — k6

Generate:
- `layer_4_tests/load/k6_user_api.js` — k6 load test scenario using Layer 3 endpoints
- `layer_4_tests/load/thresholds.js` — p95 < 500ms, error_rate < 1% thresholds
- `.github/workflows/load-tests.yml` — scheduled weekly CI job (not per-PR)
- `LOAD_TEST_README.md` — how to run k6 locally

Key rule: k6 tests call the same API endpoints as Layer 3 services.
They test the same contracts under load — no new endpoint knowledge needed.

### [A] Performance — Locust (if Python track)

Generate:
- `layer_4_tests/load/locust_user_api.py` — Locust file reusing Layer 3 service methods
- `locust.conf` — headless mode, users, spawn rate defaults
- `.github/workflows/load-tests.yml`

### [B] Security — OWASP ZAP

Generate:
- `.github/workflows/security-scan.yml` — ZAP passive scan on every PR
- `security/zap-config.yaml` — scan rules, false positive suppressions
- `security/active-scan.yml` — nightly active scan job (separate, destructive)
- `SECURITY_README.md` — how to interpret ZAP findings

Key rule: ZAP passive scan is wired as a proxy between the API client and
the real API. Zero test code changes needed — existing functional tests
trigger the passive scan automatically.

### [C] Chaos — WireMock Fault Stubs

Generate:
- `mocks/stubs/fault_stubs.json` — WireMock fault scenarios (timeouts, resets)
- `layer_4_tests/chaos/test_resilience.py (or .java)` — chaos test scenarios
- `CHAOS_README.md`

Key rule: Chaos tests are added in `layer_4_tests/chaos/` — new directory
only. No changes to existing `layer_4_tests/api/` or `layer_4_tests/ui/`.

---

## Additive-Only Rule

This skill NEVER overwrites Phase 1 files.

It only:
1. Creates new files in new directories
2. Adds new CI jobs to existing pipeline files (appended, not replaced)

If a conflict is detected (e.g., file already exists), report it and ask
the user to confirm before overwriting.

---

## Architecture Compatibility

The 4-layer structure is fully NFR-compatible by design:

```
Layer 3 (Services/Pages)  → reused unchanged by load + chaos tests
Layer 1 (Models)          → reused unchanged for response validation
Layer 2 (Client)          → minor addition: ZAP proxy URL for security scan
Layer 4                   → new subdirectories added:
                              layer_4_tests/load/
                              layer_4_tests/security/
                              layer_4_tests/chaos/
```

For detailed NFR architecture and tool options, see:
`~/.claude/skills/automation-architect/references/nfr-roadmap.md`
