# Test Config — Run G: NFR Gate Check (Phase 2 Activation)

Covers: TC-NFR-01-01/-02/-03/-04 — verifies the automation-architect-nfr skill
correctly gates on Phase 1 readiness conditions.

This is NOT a pre-scripted interview config. Instead it provides two distinct
conversation inputs — one that should PASS the gate, one that should FAIL.

---

## Scenario A — Gate Should PASS (TC-NFR-01-01)

Use this input verbatim in a Claude Code session after having described
an existing Phase 1 scaffold with the listed conditions met:

```
I have a Python API automation framework with:
- 7 test files in layer_4_tests/api/
- Tests are marked with @pytest.mark.smoke and @pytest.mark.regression
- CI pipeline (GitHub Actions) has run successfully 3 times this week
- I want to add load testing to this framework

Please activate automation-architect-nfr
```

### Expected: Gate PASSES
- [ ] Skill acknowledges all gate conditions are met
- [ ] Presents NFR discovery interview: [A] Load, [B] Security, [C] Chaos
- [ ] Does NOT block or show a gate failure message

---

## Scenario B — Gate Should FAIL: Too Few Test Files (TC-NFR-01-02)

```
I have a Python API automation framework with:
- 3 test files in layer_4_tests/api/
- CI pipeline exists but has only run once
- I want to add load testing

Please activate automation-architect-nfr
```

### Expected: Gate FAILS with specific message
- [ ] Skill blocks activation
- [ ] States that ≥5 test files are required (found 3)
- [ ] Provides actionable advice to reach the gate condition
- [ ] Does NOT present the NFR interview

---

## Scenario C — Gate Should FAIL: No CI Pipeline (TC-NFR-01-03)

```
I have a Python API automation framework with:
- 8 test files with smoke and regression markers
- No CI pipeline set up yet
- I want to add OWASP ZAP security scanning

Please activate automation-architect-nfr
```

### Expected: Gate FAILS with specific message
- [ ] Skill blocks activation
- [ ] States that a CI pipeline is required before enabling NFR testing
- [ ] Provides actionable advice (set up CI first)
- [ ] Does NOT present the NFR interview

---

## Scenario D — Gate Should FAIL: Missing Markers (TC-NFR-01-04)

```
I have a Python API automation framework with:
- 6 test files but no pytest markers applied
- GitHub Actions CI that has run successfully
- I want to add chaos testing

Please activate automation-architect-nfr
```

### Expected: Gate FAILS with remediation advice
- [ ] Skill identifies missing smoke/regression markers specifically
- [ ] Shows example of how to add @pytest.mark.smoke and @pytest.mark.regression
- [ ] Does NOT present the NFR interview
