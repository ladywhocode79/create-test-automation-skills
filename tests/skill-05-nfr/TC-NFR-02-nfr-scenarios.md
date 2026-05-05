# TC-NFR-02 — NFR Test Scenario Generation

**Skill**: automation-architect-nfr  
**Total TCs**: 6  
**Level**: L3  
**Model**: Sonnet  
**Pre-req**: TC-NFR-01-01 passing (gate opens); Phase 1 scaffold present

These TCs verify the quality of NFR artifacts generated after the gate passes.
Use Sonnet — NFR output requires higher-quality reasoning to verify correctness.

---

## Setup (run once before all TCs in this file)

```bash
# Use the Phase 1 scaffold from TC-PY-04 setup (Python API)
cd /tmp/test-py-quality
claude
/model claude-sonnet-4-6
```
Trigger NFR skill using Scenario A from `test-configs/run-g-nfr-gate-check.md`.

---

## TC-NFR-02-01 — [A] k6 load test file generated with configured thresholds

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L3 |
| Type | Functional |
| Model | Sonnet |

### Objective
Verify selecting [A] Load Testing generates a valid k6 script with
performance thresholds that can be run against the existing Layer 3 services.

### Steps
After gate passes (TC-NFR-01-01 setup):
```
A
```
(select Load Testing option)

When asked for configuration:
```
Target: 50 concurrent virtual users
Duration: 5 minutes
Threshold: p95 response time < 500ms, error rate < 1%
```
Respond `[Y]` to write files.

### Post-write verification
```bash
find /tmp/test-py-quality/layer_4_tests/load/ -type f
cat /tmp/test-py-quality/layer_4_tests/load/load_test.js
```

### Expected Results
- [ ] `layer_4_tests/load/` directory created
- [ ] `load_test.js` (or `load_test_*.js`) present
- [ ] Script imports `k6` modules at the top
- [ ] `vus: 50` and `duration: "5m"` visible in options
- [ ] Threshold `p(95)<500` defined in `thresholds` block
- [ ] Script calls at least one API endpoint (not an empty test)
- [ ] `LOAD_TEST_README.md` generated explaining how to run

### Pass Criteria
All 7 items checked.

---

## TC-NFR-02-02 — [A-alt] Python track generates Locust file reusing Layer 3 services

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L3 |
| Type | Functional |
| Model | Sonnet |

### Objective
Verify that for Python track, the skill offers Locust as the preferred load
testing option and generates a Locust file that imports from `layer_3_services/`.

### Steps
After gate passes with Python framework context:
```
A
```
When asked for tool preference:
```
Locust
```

### Post-write verification
```bash
find /tmp/test-py-quality/layer_4_tests/load/ -name "*.py"
head -20 /tmp/test-py-quality/layer_4_tests/load/locustfile.py
```

### Expected Results
- [ ] `layer_4_tests/load/locustfile.py` present
- [ ] File imports from `layer_3_services/` (reuses existing service classes)
- [ ] `from locust import HttpUser, task` import present
- [ ] At least one `@task` decorated method defined
- [ ] `wait_time` defined (e.g., `between(1, 3)`)
- [ ] No duplicate HTTP calls that bypass Layer 3 (Locust uses services, not raw requests)

### Pass Criteria
All 6 items checked.

### Debug Tips
- Locust file uses raw `requests` instead of Layer 3 → NFR skill not reading existing scaffold structure
- Missing Layer 3 import → check how NFR skill discovers the existing service file names

---

## TC-NFR-02-03 — [A] Weekly CI job added to existing CI configuration

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L3 |
| Type | Functional |
| Model | Sonnet |

### Objective
Verify that the load test CI job is added as a scheduled weekly job to
the existing `.github/workflows/` CI configuration — not a new unrelated file.

### Post-write verification
```bash
ls /tmp/test-py-quality/.github/workflows/
cat /tmp/test-py-quality/.github/workflows/load-test.yml
```

### Expected Results
- [ ] `load-test.yml` (or equivalent) present in `.github/workflows/`
- [ ] `schedule:` trigger defined with a weekly cron expression (e.g., `cron: '0 2 * * 1'`)
- [ ] Job runs the load test tool (k6 or locust) — not just the regular pytest suite
- [ ] `on: workflow_dispatch` also present (allows manual trigger)

### Pass Criteria
All 4 items checked.

---

## TC-NFR-02-04 — [B] OWASP ZAP passive scan job added to CI

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L3 |
| Type | Functional |
| Model | Sonnet |

### Objective
Verify selecting [B] Security adds an OWASP ZAP passive scan to the CI pipeline.

### Steps
Trigger the NFR skill again (re-enter gate scenario), select:
```
B
```

### Post-write verification
```bash
ls /tmp/test-py-quality/.github/workflows/
find /tmp/test-py-quality -name "zap*.yml" -o -name "*zap*"
```

### Expected Results
- [ ] `security-scan.yml` (or similar) present in `.github/workflows/`
- [ ] ZAP Docker image referenced (`zaproxy/zap-stable` or equivalent)
- [ ] Passive scan configured (not active/attack scan — passive is safe for CI)
- [ ] ZAP report artifact uploaded after scan
- [ ] `ZAP_README.md` generated explaining the scan scope and how to interpret results

### Pass Criteria
All 5 items checked.

### Debug Tips
- Active scan configured instead of passive → security risk; ZAP active scan sends attack payloads
- Fix the scan type in `automation-architect-nfr/SKILL.md` security section

---

## TC-NFR-02-05 — [C] Fault stubs added to WireMock (timeout, 503 responses)

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L3 |
| Type | Functional |
| Model | Sonnet |

### Objective
Verify selecting [C] Chaos adds fault injection stubs to the existing
`mocks/stubs/` directory for testing application resilience.

### Steps
Trigger the NFR skill (requires mock=both in Phase 1 scaffold), select:
```
C
```

### Post-write verification
```bash
find /tmp/test-py-quality/mocks/stubs/ -name "*fault*" -o -name "*timeout*" -o -name "*chaos*"
cat /tmp/test-py-quality/layer_4_tests/chaos/test_resilience.py 2>/dev/null || \
  find /tmp/test-py-quality/layer_4_tests/chaos/ -type f
```

### Expected Results
- [ ] `layer_4_tests/chaos/` directory created
- [ ] At least one timeout fault stub in `mocks/stubs/` (e.g., `get-users-timeout.json`)
- [ ] At least one 503 fault stub (e.g., `post-users-service-unavailable.json`)
- [ ] Timeout stub uses WireMock `fixedDelayMilliseconds` (e.g., 5000ms)
- [ ] `CHAOS_README.md` generated explaining how to activate chaos mode

### Pass Criteria
All 5 items checked.

---

## TC-NFR-02-06 — [C] Chaos test scenarios assert graceful fault handling

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L3 |
| Type | Functional |
| Model | Sonnet |

### Objective
Verify the generated chaos tests actually assert that the application handles
faults gracefully — not that they simply trigger the fault.

### Post-write verification
```bash
cat /tmp/test-py-quality/layer_4_tests/chaos/test_resilience.py
```

### Expected Results
- [ ] Test functions test timeout behaviour (e.g., `test_handles_upstream_timeout`)
- [ ] Tests assert on graceful degradation — not just that an exception is raised
  (e.g., assert retry attempted, fallback returned, or meaningful error message surfaced)
- [ ] Tests import from `layer_3_services/` to reuse existing service layer
- [ ] At least one test for 503 scenario and at least one for timeout scenario
- [ ] `pytest.mark.chaos` marker applied to all chaos tests

### Pass Criteria
All 5 items checked.

### Debug Tips
- Tests only assert `pytest.raises(Exception)` → too weak; chaos tests should assert *how* the app handles faults
- Missing service import → chaos tests duplicate logic from Layer 3 (violates 4-layer contract)
