# Test Design Document — automation-architect Skill Suite

**Document type**: Test Design & Plan  
**Version**: 1.0  
**Date**: 2026-05-04  
**Author**: Senior SDET  
**Suite version under test**: 2.2.0

---

## 1. Purpose

This document defines the complete test strategy, test design, and execution approach
for the `automation-architect` Claude Code skill suite. It covers all 5 skills, all
4 test levels, and 106 individual test cases organized across 14 test case files.

---

## 2. Skills Under Test

| Skill | Type | User-Invocable | Primary Responsibility |
|---|---|---|---|
| `automation-architect` | Orchestrator | Yes | Interview flow, config resolution, routing, preview |
| `automation-architect-python` | Language Track | No (delegated) | Python scaffold: Pytest, Pydantic, Playwright, requests |
| `automation-architect-java` | Language Track | No (delegated) | Java scaffold: TestNG, RestAssured, Jackson, Selenium |
| `automation-architect-mock` | Cross-Cutting | No (delegated) | WireMock Docker, stub files, Strategy pattern |
| `automation-architect-nfr` | Phase 2 Gated | Yes (gated) | Load, security, and chaos testing |

---

## 3. Test Strategy

### 3.1 What Is Being Tested

These are **AI skill prompt files** — not traditional code. Testing them means:
- Verifying the AI produces the correct **conversation flow** (interview rounds, order, conditions)
- Verifying the AI generates the correct **files** (names, count, layer placement)
- Verifying the generated **code quality** (syntax, imports, compilation, test collection)
- Verifying **edge case handling** (invalid inputs, partial writes, gate failures)

### 3.2 Test Levels

| Level | Name | What It Catches | Model | Approx Cost |
|---|---|---|---|---|
| L1 | Skill Activation | Wrong trigger routing, missing phrases | Haiku | Low |
| L2 | Conversation Flow | Interview order, config summary, preview structure, file list | Haiku | Medium |
| L3 | Code Quality | Syntax errors, compilation failures, import violations, test collection | Sonnet | High |
| L4 | Edge Case Flows | [E]dit / [P]artial / [N]o-write / [Z]Other / gate failures | Haiku + Sonnet | Medium |

Levels are **cumulative** — L1 must pass before running L2, L2 before L3, etc.

### 3.3 Token Optimisation

| Strategy | How | Saving |
|---|---|---|
| `--test` flag | Appended to any prompt; suppresses code snippets | ~60% |
| Pre-scripted configs | Paste config block → skip 9-question interview | ~70% |
| Scope by change | Only run tests relevant to what changed | Up to 80% |
| Haiku for flow | Use Haiku for L1/L2, Sonnet only for L3 | ~10x cost |

### 3.4 Execution Modes

```
[Y] — Writes all scaffold files to disk (used for L3 code quality checks)
[N] — Outputs all files as fenced code blocks, writes nothing (safe for L2)
[T] — Compact mode preview only, auto-exits without writing (fastest for L2)
[E] — Edit single config field without restarting interview
[P] — Partial write by layer selection
[Z] — Other language track (pseudocode + TRACK-STUB.md)
```

---

## 4. Scope

### In Scope
- All 5 skill SKILL.md prompt files
- All reference templates in `references/` directories
- Generated scaffold file lists and code quality
- Design pattern activation rules
- Gate conditions for NFR skill
- Mock infrastructure generation

### Out of Scope
- Testing against a live API (real service mode)
- Browser-based UI test execution (requires a real app)
- ReportPortal integration (SaaS dependency)
- CI/CD pipeline execution (GitHub Actions / GitLab runs)

---

## 5. Test File Structure

```
tests/
├── TEST-DESIGN.md                        ← This document
├── TESTING.md                            ← Execution guide (moved from root)
├── test-configs/                         ← Pre-scripted interview configs
│   ├── run-a-python-api.md
│   ├── run-b-python-ui.md
│   ├── run-c-java-fullstack.md
│   ├── run-d-java-api.md
│   ├── run-e-python-api-no-mock.md       ← New (TC-MOCK-01-04)
│   ├── run-f-python-ui-multi-browser.md  ← New (TC-PY-03-05)
│   └── run-g-nfr-gate-check.md          ← New (TC-NFR-01-01)
│
├── skill-01-orchestrator/
│   ├── TC-ORCH-01-activation.md
│   ├── TC-ORCH-02-prd-intake.md
│   ├── TC-ORCH-03-interview-flow.md
│   ├── TC-ORCH-04-preview-output.md
│   └── TC-ORCH-05-confirmation-flows.md
│
├── skill-02-python/
│   ├── TC-PY-01-api-scaffold.md
│   ├── TC-PY-02-ui-scaffold.md
│   ├── TC-PY-03-fullstack-patterns.md
│   └── TC-PY-04-code-quality.md
│
├── skill-03-java/
│   ├── TC-JAVA-01-api-scaffold.md
│   ├── TC-JAVA-02-ui-scaffold.md
│   ├── TC-JAVA-03-fullstack-patterns.md
│   └── TC-JAVA-04-code-quality.md
│
├── skill-04-mock/
│   ├── TC-MOCK-01-wiremock-docker.md
│   ├── TC-MOCK-02-stub-generation.md
│   └── TC-MOCK-03-strategy-pattern.md
│
└── skill-05-nfr/
    ├── TC-NFR-01-gate-validation.md
    └── TC-NFR-02-nfr-scenarios.md
```

---

## 6. Test Case Inventory

### 6.1 Skill 01 — Orchestrator (35 TCs)

#### TC-ORCH-01 — Activation (9 TCs)

| TC-ID | Title | Priority | Level | Type |
|---|---|---|---|---|
| TC-ORCH-01-01 | "test automation framework" activates skill | P0 | L1 | Functional |
| TC-ORCH-01-02 | "api automation" activates skill | P0 | L1 | Functional |
| TC-ORCH-01-03 | "scaffold tests" activates skill | P0 | L1 | Functional |
| TC-ORCH-01-04 | "pytest framework" activates skill | P0 | L1 | Functional |
| TC-ORCH-01-05 | "playwright framework" activates skill | P1 | L1 | Functional |
| TC-ORCH-01-06 | "restassured framework" activates skill | P1 | L1 | Functional |
| TC-ORCH-01-07 | Non-trigger phrase does NOT activate skill | P1 | L1 | Negative |
| TC-ORCH-01-08 | Trigger phrase with `--test` flag stays compact | P1 | L1 | Functional |
| TC-ORCH-01-09 | Pre-scripted config block skips interview | P0 | L1 | Functional |

#### TC-ORCH-02 — PRD Intake (6 TCs)

| TC-ID | Title | Priority | Level | Type |
|---|---|---|---|---|
| TC-ORCH-02-01 | PRD Intake [A]: user pastes PRD text | P0 | L2 | Functional |
| TC-ORCH-02-02 | PRD Intake [B]: sample PRD loaded and displayed | P0 | L2 | Functional |
| TC-ORCH-02-03 | PRD Intake [C]: deferred PRD, scaffold continues | P1 | L2 | Functional |
| TC-ORCH-02-04 | PRD analysis extracts correct endpoints | P0 | L2 | Functional |
| TC-ORCH-02-05 | PRD analysis flags ambiguities with P0/P1/P2 priority | P1 | L2 | Functional |
| TC-ORCH-02-06 | PRD analysis recommends correct automation type | P1 | L2 | Functional |

#### TC-ORCH-03 — Interview Flow (8 TCs)

| TC-ID | Title | Priority | Level | Type |
|---|---|---|---|---|
| TC-ORCH-03-01 | Q0 asks test type before any language question | P0 | L2 | Functional |
| TC-ORCH-03-02 | API-only flow skips UI browser/locator questions | P0 | L2 | Functional |
| TC-ORCH-03-03 | UI-only flow skips API protocol/auth questions | P0 | L2 | Functional |
| TC-ORCH-03-04 | Full-Stack flow asks both API and UI question sets | P0 | L2 | Functional |
| TC-ORCH-03-05 | Invalid answer at Q0 triggers re-ask | P1 | L2 | Negative |
| TC-ORCH-03-06 | All interview answers stored correctly across rounds | P0 | L2 | Functional |
| TC-ORCH-03-07 | Python answer routes to automation-architect-python | P0 | L2 | Functional |
| TC-ORCH-03-08 | Java answer routes to automation-architect-java | P0 | L2 | Functional |

#### TC-ORCH-04 — Preview Output (7 TCs)

| TC-ID | Title | Priority | Level | Type |
|---|---|---|---|---|
| TC-ORCH-04-01 | Config Summary shows all 9 resolved answers | P0 | L2 | Functional |
| TC-ORCH-04-02 | Pattern list shows [+] active and [~] deferred correctly | P0 | L2 | Functional |
| TC-ORCH-04-03 | Scaffold Preview shows annotated file tree | P0 | L2 | Functional |
| TC-ORCH-04-04 | Preview file count is within expected range (18–27) | P1 | L2 | Functional |
| TC-ORCH-04-05 | Code snippets shown for correct layers | P1 | L2 | Functional |
| TC-ORCH-04-06 | Confirmation prompt [Y / P / E / N] present at end | P0 | L2 | Functional |
| TC-ORCH-04-07 | `--test` flag suppresses code snippets in preview | P1 | L2 | Functional |

#### TC-ORCH-05 — Confirmation Flows (5 TCs)

| TC-ID | Title | Priority | Level | Type |
|---|---|---|---|---|
| TC-ORCH-05-01 | [Y] writes all scaffold files to disk | P0 | L4 | Functional |
| TC-ORCH-05-02 | [N] outputs all files as code blocks, writes nothing | P0 | L4 | Edge Case |
| TC-ORCH-05-03 | [E] allows single-field edit without full interview restart | P1 | L4 | Edge Case |
| TC-ORCH-05-04 | [P] partial write by layer, offers remaining files | P1 | L4 | Edge Case |
| TC-ORCH-05-05 | [Z] generates pseudocode + TRACK-STUB.md | P2 | L4 | Edge Case |

---

### 6.2 Skill 02 — Python (24 TCs)

#### TC-PY-01 — API Scaffold (6 TCs)

| TC-ID | Title | Priority | Level | Type |
|---|---|---|---|---|
| TC-PY-01-01 | API scaffold includes all Layer 1 Pydantic model files | P0 | L2 | Functional |
| TC-PY-01-02 | API scaffold includes BaseApiClient with retry + logging decorators | P0 | L2 | Functional |
| TC-PY-01-03 | API scaffold includes UserService in Layer 3 | P0 | L2 | Functional |
| TC-PY-01-04 | API scaffold includes pytest test file in Layer 4 | P0 | L2 | Functional |
| TC-PY-01-05 | API-only scaffold excludes all UI files | P0 | L2 | Negative |
| TC-PY-01-06 | OAuth2 auth generates auth_manager.py | P0 | L2 | Functional |

#### TC-PY-02 — UI Scaffold (5 TCs)

| TC-ID | Title | Priority | Level | Type |
|---|---|---|---|---|
| TC-PY-02-01 | UI scaffold includes Playwright browser_session.py | P0 | L2 | Functional |
| TC-PY-02-02 | UI scaffold includes Page Object in Layer 3 | P0 | L2 | Functional |
| TC-PY-02-03 | UI scaffold includes driver_manager.py | P0 | L2 | Functional |
| TC-PY-02-04 | UI-only scaffold excludes API client and service files | P0 | L2 | Negative |
| TC-PY-02-05 | Chrome-only: Browser Factory pattern NOT activated | P1 | L2 | Negative |

#### TC-PY-03 — Full-Stack + Patterns (7 TCs)

| TC-ID | Title | Priority | Level | Type |
|---|---|---|---|---|
| TC-PY-03-01 | Full-Stack includes both Layer 3 services AND pages | P0 | L2 | Functional |
| TC-PY-03-02 | Full-Stack includes both Layer 4 API and UI test files | P0 | L2 | Functional |
| TC-PY-03-03 | Singleton Auth activated when auth != none | P0 | L2 | Functional |
| TC-PY-03-04 | Singleton Driver activated for UI test types | P0 | L2 | Functional |
| TC-PY-03-05 | Browser Factory activated only when browser_targets > 1 | P1 | L2 | Functional |
| TC-PY-03-06 | Strategy Mock activated only when mock IN [both, mock-only] | P0 | L2 | Functional |
| TC-PY-03-07 | Builder pattern deferred (shown as [~] not [+]) | P1 | L2 | Functional |

#### TC-PY-04 — Code Quality (6 TCs)

| TC-ID | Title | Priority | Level | Type |
|---|---|---|---|---|
| TC-PY-04-01 | All Python files pass py_compile syntax check | P0 | L3 | Code Quality |
| TC-PY-04-02 | Layer imports pass import-linter (no upward deps) | P0 | L3 | Code Quality |
| TC-PY-04-03 | pytest --collect-only finds all tests with zero import errors | P0 | L3 | Code Quality |
| TC-PY-04-04 | WireMock stubs load into Docker without JSON parse errors | P0 | L3 | Code Quality |
| TC-PY-04-05 | Tests pass against WireMock in mock mode | P0 | L3 | Code Quality |
| TC-PY-04-06 | Allure report generated with steps visible | P1 | L3 | Code Quality |

---

### 6.3 Skill 03 — Java (24 TCs)

#### TC-JAVA-01 — API Scaffold (6 TCs)

| TC-ID | Title | Priority | Level | Type |
|---|---|---|---|---|
| TC-JAVA-01-01 | API scaffold includes Jackson model POJOs | P0 | L2 | Functional |
| TC-JAVA-01-02 | API scaffold includes BaseApiClient with RestAssured | P0 | L2 | Functional |
| TC-JAVA-01-03 | API scaffold includes UserService in Layer 3 | P0 | L2 | Functional |
| TC-JAVA-01-04 | API scaffold includes TestNG test class in Layer 4 | P0 | L2 | Functional |
| TC-JAVA-01-05 | API-only scaffold excludes all UI files | P0 | L2 | Negative |
| TC-JAVA-01-06 | Bearer auth generates AuthManager.java | P0 | L2 | Functional |

#### TC-JAVA-02 — UI Scaffold (5 TCs)

| TC-ID | Title | Priority | Level | Type |
|---|---|---|---|---|
| TC-JAVA-02-01 | UI scaffold includes BrowserSession with Selenium WebDriver | P0 | L2 | Functional |
| TC-JAVA-02-02 | UI scaffold includes Page Object in Layer 3 | P0 | L2 | Functional |
| TC-JAVA-02-03 | UI scaffold includes DriverManager.java | P0 | L2 | Functional |
| TC-JAVA-02-04 | UI-only scaffold excludes API client and service files | P0 | L2 | Negative |
| TC-JAVA-02-05 | Chrome-only: Browser Factory NOT activated | P1 | L2 | Negative |

#### TC-JAVA-03 — Full-Stack + Patterns (7 TCs)

| TC-ID | Title | Priority | Level | Type |
|---|---|---|---|---|
| TC-JAVA-03-01 | Full-Stack includes both service + page layers | P0 | L2 | Functional |
| TC-JAVA-03-02 | Full-Stack includes valid pom.xml with correct dependency versions | P0 | L2 | Functional |
| TC-JAVA-03-03 | testng.xml lists all test classes | P0 | L2 | Functional |
| TC-JAVA-03-04 | config.properties generated with correct env keys | P0 | L2 | Functional |
| TC-JAVA-03-05 | ArchUnit layer test file present for dependency enforcement | P1 | L2 | Functional |
| TC-JAVA-03-06 | GitLab CI template generated (not GitHub Actions) when GitLab selected | P1 | L2 | Functional |
| TC-JAVA-03-07 | Browser Factory activated when Chrome+Firefox selected | P1 | L2 | Functional |

#### TC-JAVA-04 — Code Quality (6 TCs)

| TC-ID | Title | Priority | Level | Type |
|---|---|---|---|---|
| TC-JAVA-04-01 | pom.xml is valid XML and `mvn validate` passes | P0 | L3 | Code Quality |
| TC-JAVA-04-02 | `mvn compile` succeeds with zero errors | P0 | L3 | Code Quality |
| TC-JAVA-04-03 | `mvn test-compile` succeeds | P0 | L3 | Code Quality |
| TC-JAVA-04-04 | TestNG XML discovers all test classes | P1 | L3 | Code Quality |
| TC-JAVA-04-05 | WireMock stubs load without JSON parse errors | P0 | L3 | Code Quality |
| TC-JAVA-04-06 | Allure report generated after test run | P1 | L3 | Code Quality |

---

### 6.4 Skill 04 — Mock (13 TCs)

#### TC-MOCK-01 — WireMock Docker (4 TCs)

| TC-ID | Title | Priority | Level | Type |
|---|---|---|---|---|
| TC-MOCK-01-01 | docker-compose.yml includes WireMock service on port 8080 | P0 | L2 | Functional |
| TC-MOCK-01-02 | WireMock health endpoint returns `{"status":"Running"}` | P0 | L3 | Functional |
| TC-MOCK-01-03 | `docker-compose up -d` starts WireMock without errors | P0 | L3 | Functional |
| TC-MOCK-01-04 | No-mock mode: no docker-compose.yml generated | P1 | L2 | Negative |

#### TC-MOCK-02 — Stub Generation (5 TCs)

| TC-ID | Title | Priority | Level | Type |
|---|---|---|---|---|
| TC-MOCK-02-01 | Stub file names follow `verb-resource-scenario.json` convention | P0 | L2 | Functional |
| TC-MOCK-02-02 | POST stub returns correct response body and 201 status | P0 | L2 | Functional |
| TC-MOCK-02-03 | GET stub uses URL pattern matching, not exact match | P0 | L2 | Functional |
| TC-MOCK-02-04 | Error stubs (404, 422, 500) generated alongside each happy path | P0 | L2 | Functional |
| TC-MOCK-02-05 | All stubs load into running WireMock without mapping errors | P0 | L3 | Functional |

#### TC-MOCK-03 — Strategy Pattern (4 TCs)

| TC-ID | Title | Priority | Level | Type |
|---|---|---|---|---|
| TC-MOCK-03-01 | Strategy pattern present in Layer 2 client | P0 | L2 | Functional |
| TC-MOCK-03-02 | TEST_MODE=mock routes to WireMock client | P0 | L2 | Functional |
| TC-MOCK-03-03 | TEST_MODE=real routes to real HTTP client | P0 | L2 | Functional |
| TC-MOCK-03-04 | Real and mock clients share the same base class/interface | P1 | L2 | Functional |

---

### 6.5 Skill 05 — NFR (10 TCs)

#### TC-NFR-01 — Gate Validation (4 TCs)

| TC-ID | Title | Priority | Level | Type |
|---|---|---|---|---|
| TC-NFR-01-01 | Gate passes: ≥5 test files + smoke/regression markers + CI ran | P0 | L4 | Functional |
| TC-NFR-01-02 | Gate fails: <5 test files → blocked with clear message | P0 | L4 | Negative |
| TC-NFR-01-03 | Gate fails: no CI pipeline → blocked with clear message | P0 | L4 | Negative |
| TC-NFR-01-04 | Gate fails: missing markers → specific remediation advice given | P1 | L4 | Negative |

#### TC-NFR-02 — NFR Scenarios (6 TCs)

| TC-ID | Title | Priority | Level | Type |
|---|---|---|---|---|
| TC-NFR-02-01 | [A] k6 load test file generated with configured thresholds | P0 | L3 | Functional |
| TC-NFR-02-02 | [A-alt] Python track: Locust file reuses Layer 3 services | P0 | L3 | Functional |
| TC-NFR-02-03 | [A] Weekly CI job added to existing CI configuration | P1 | L3 | Functional |
| TC-NFR-02-04 | [B] OWASP ZAP passive scan job added to CI | P0 | L3 | Functional |
| TC-NFR-02-05 | [C] Fault stubs added to WireMock (timeout, 503 responses) | P0 | L3 | Functional |
| TC-NFR-02-06 | [C] Chaos test scenarios assert app handles faults gracefully | P1 | L3 | Functional |

---

## 7. Coverage Matrix

| Skill | L1 | L2 | L3 | L4 | Total |
|---|---|---|---|---|---|
| Orchestrator | 9 | 18 | 0 | 8 | **35** |
| Python | 0 | 18 | 6 | 0 | **24** |
| Java | 0 | 18 | 6 | 0 | **24** |
| Mock | 0 | 9 | 4 | 0 | **13** |
| NFR | 0 | 0 | 6 | 4 | **10** |
| **Total** | **9** | **63** | **22** | **12** | **106** |

---

## 8. Priority Breakdown

| Priority | Count | Description |
|---|---|---|
| P0 | 62 | Must pass before any release — core flows, file accuracy, code quality |
| P1 | 35 | Should pass — pattern activation, edge cases, optional features |
| P2 | 9 | Nice to have — [Z] Other language, UI multi-browser, Allure details |

---

## 9. Execution Phases

### Phase 1 — Smoke (~15 min, Haiku, no files written)
Validates the skill activates from trigger phrases before any deeper testing.

```
Run: TC-ORCH-01-01 through TC-ORCH-01-06
cd /tmp && claude
"help me design an api automation framework"  → expect Lead SDET response
"I need a pytest framework"                   → expect Lead SDET response
"general coding help"                         → expect NO skill activation
```

### Phase 2 — Flow (~45 min, Haiku, --test flag, no files written)
Validates interview flow and preview output using pre-scripted configs.

```
Run: TC-ORCH-02, TC-ORCH-03, TC-ORCH-04
     TC-PY-01, TC-PY-02, TC-PY-03
     TC-JAVA-01, TC-JAVA-02, TC-JAVA-03
     TC-MOCK-01-01, TC-MOCK-02, TC-MOCK-03
     TC-NFR-01

# Use --test flag + config blocks:
{paste run-a-python-api.md block} --test   → respond [T]
{paste run-b-python-ui.md block} --test    → respond [T]
{paste run-c-java-fullstack.md block} --test → respond [T]
{paste run-d-java-api.md block} --test     → respond [T]
```

### Phase 3 — Code Quality (~60 min, Sonnet, writes real files)
Validates generated code is syntactically correct and structurally sound.

```
Run: TC-PY-04, TC-JAVA-04, TC-MOCK-01-02/-03, TC-MOCK-02-05

mkdir /tmp/test-scaffold-py && cd /tmp/test-scaffold-py
claude → {paste run-a-python-api.md} → respond [Y]
# Then run: py_compile, import-linter, pytest --collect-only, docker-compose

mkdir /tmp/test-scaffold-java && cd /tmp/test-scaffold-java
claude → {paste run-d-java-api.md} → respond [Y]
# Then run: mvn validate, mvn compile, mvn test-compile
```

### Phase 4 — Edge Cases (~30 min, Haiku + Sonnet)
Validates non-happy-path flows and gate conditions.

```
Run: TC-ORCH-05, TC-NFR-01-02 through TC-NFR-01-04

# [E] edit flow:
{paste run-a-python-api.md} → at confirmation type [E]
→ change auth from OAuth2 to Bearer
→ verify preview regenerates with only that field changed

# [N] no-write flow:
{paste run-b-python-ui.md} → at confirmation type [N]
→ verify all files output as code blocks, disk empty

# NFR gate failure:
"I want to add load testing" (without Phase 1 conditions)
→ verify skill blocks with specific gate failure message
```

---

## 10. New Test Configs Required

Three new pre-scripted configs are needed to cover gaps in the existing `run-a` through `run-d` set:

| File | Covers TCs | Gap |
|---|---|---|
| `test-configs/run-e-python-api-no-mock.md` | TC-MOCK-01-04 | Verifies no docker-compose.yml when mock=none |
| `test-configs/run-f-python-ui-multi-browser.md` | TC-PY-03-05 | Verifies Browser Factory activated on Chrome+Firefox |
| `test-configs/run-g-nfr-gate-check.md` | TC-NFR-01-01 | NFR gate pass scenario description |

---

## 11. Pass / Fail Criteria

### Test Case Level
- **Pass**: ALL checklist items in "Expected Results" are checked
- **Fail**: ANY checklist item is unchecked

### Skill Level
- **Pass**: All P0 test cases pass + ≤10% P1 failures
- **Fail**: Any P0 failure

### Suite Level
- **Pass**: All 5 skills pass at skill level
- **Fail**: Any skill fails at skill level

---

## 12. Defect Classification

| Severity | Definition | Example |
|---|---|---|
| S1 — Blocker | Skill does not activate, or writes wrong files | Wrong language track delegated |
| S2 — Critical | Generated code has syntax error or fails compilation | Missing import in base_api_client.py |
| S3 — Major | Wrong pattern activated or omitted | Strategy pattern missing when mock=both |
| S4 — Minor | Cosmetic, non-blocking | Wrong file count in preview annotation |

---

## 13. Defect Reporting

When a test fails, log it with:
```
TC-ID:        [e.g., TC-PY-04-01]
Severity:     [S1/S2/S3/S4]
Title:        Short description
Steps:        What you ran
Expected:     What should have happened
Actual:       What actually happened
Skill file:   Which SKILL.md or references/*.md to fix
Fix approach: Suggested fix
```

---

## 14. Scope Matrix — What Each Config Covers

| Config | TCs Covered | Skills Exercised |
|---|---|---|
| run-a (Python API + WireMock) | TC-ORCH-03, TC-PY-01, TC-PY-03-03/-06, TC-MOCK-01/-02/-03 | Orchestrator, Python, Mock |
| run-b (Python UI + WireMock) | TC-ORCH-03, TC-PY-02, TC-PY-03-04/-05 | Orchestrator, Python, Mock |
| run-c (Java Full-Stack, no mock) | TC-ORCH-03, TC-JAVA-01/-02/-03, TC-MOCK-01-04 | Orchestrator, Java |
| run-d (Java API + WireMock) | TC-ORCH-03, TC-JAVA-01, TC-JAVA-04 | Orchestrator, Java, Mock |
| run-e (Python API, no mock) | TC-MOCK-01-04 | Orchestrator, Python |
| run-f (Python UI, multi-browser) | TC-PY-03-05 | Orchestrator, Python |
| run-g (NFR gate check) | TC-NFR-01-01 | NFR |

---

## 15. Related Reference Files

| File | Purpose |
|---|---|
| `automation-architect/references/pattern-registry.md` | Design pattern activation conditions |
| `automation-architect/references/track-contract.md` | Abstract contract for language tracks |
| `automation-architect/references/preview-format.md` | Expected Config Summary + Preview format |
| `automation-architect-python/references/edge-case-tests-pytest.md` | Pytest edge-case templates |
| `automation-architect-java/references/edge-case-tests-testng.md` | TestNG edge-case templates |
| `automation-architect-mock/references/strategy-pattern-switch.md` | Strategy pattern reference |
| `sample-prd/edge-case-checklist.md` | 10-category edge-case input for PRD analysis |
