# TC-NFR-01 — Gate Validation (Phase 2 Activation Conditions)

**Skill**: automation-architect-nfr  
**Total TCs**: 4  
**Level**: L4  
**Model**: Haiku  
**Config**: `test-configs/run-g-nfr-gate-check.md` (all 4 scenarios)  
**Pre-req**: Phase 1 functional testing complete (or simulated via description)

The NFR skill is gated — it must refuse activation unless all Phase 1
conditions are met. These TCs verify both pass and fail gate paths.

---

## TC-NFR-01-01 — Gate passes when all conditions are met

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L4 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify the skill proceeds to the NFR discovery interview when the user
describes a project that satisfies all three gate conditions.

### Steps
Use Scenario A from `test-configs/run-g-nfr-gate-check.md`:
```
I have a Python API automation framework with:
- 7 test files in layer_4_tests/api/
- Tests are marked with @pytest.mark.smoke and @pytest.mark.regression
- CI pipeline (GitHub Actions) has run successfully 3 times this week
- I want to add load testing to this framework

Please activate automation-architect-nfr
```

### Expected Results
- [ ] Skill does NOT show a blocking gate failure message
- [ ] Skill acknowledges all conditions are met
- [ ] NFR discovery interview presented: options [A] Load, [B] Security, [C] Chaos
- [ ] Skill references the user's existing framework (Python) when presenting options
- [ ] Locust mentioned as the preferred load testing tool for Python track (not just k6)

### Pass Criteria
All 5 items checked.

### Debug Tips
- Gate blocks even with valid conditions → gate condition check logic in `automation-architect-nfr/SKILL.md` is too strict
- Wrong tool recommended (k6 for Python) → language track detection missing in NFR skill

---

## TC-NFR-01-02 — Gate fails when fewer than 5 test files present

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L4 |
| Type | Negative |
| Model | Haiku |

### Objective
Verify the skill refuses activation and gives a specific, actionable message
when the test file count is below the threshold.

### Steps
Use Scenario B from `test-configs/run-g-nfr-gate-check.md`:
```
I have a Python API automation framework with:
- 3 test files in layer_4_tests/api/
- CI pipeline exists but has only run once
- I want to add load testing

Please activate automation-architect-nfr
```

### Expected Results
- [ ] Skill does NOT present the NFR interview
- [ ] Skill explicitly states the minimum required (≥5 test files)
- [ ] Skill states the current count found (3 files)
- [ ] Skill gives actionable advice (e.g., "add at least 2 more test files")
- [ ] Message is specific — not a generic "requirements not met" error

### Pass Criteria
All 5 items checked.

### Debug Tips
- Skill activates anyway → gate condition `>= 5 test files` not enforced in `SKILL.md`
- Generic error message → gate failure messaging in NFR skill needs improvement

---

## TC-NFR-01-03 — Gate fails when no CI pipeline is configured

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L4 |
| Type | Negative |
| Model | Haiku |

### Objective
Verify the skill blocks activation when the CI pipeline condition is not met.

### Steps
Use Scenario C from `test-configs/run-g-nfr-gate-check.md`:
```
I have a Python API automation framework with:
- 8 test files with smoke and regression markers
- No CI pipeline set up yet
- I want to add OWASP ZAP security scanning

Please activate automation-architect-nfr
```

### Expected Results
- [ ] Skill does NOT present the NFR interview
- [ ] Skill specifically identifies missing CI pipeline as the blocking condition
- [ ] Skill provides actionable advice (e.g., "set up CI first — see references/ci-templates.md")
- [ ] Other gate conditions (test count, markers) are acknowledged as passing

### Pass Criteria
All 4 items checked.

---

## TC-NFR-01-04 — Gate fails with specific advice when pytest markers are missing

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L4 |
| Type | Negative |
| Model | Haiku |

### Objective
Verify the skill identifies missing `smoke` and `regression` markers specifically
and shows example code for adding them.

### Steps
Use Scenario D from `test-configs/run-g-nfr-gate-check.md`:
```
I have a Python API automation framework with:
- 6 test files but no pytest markers applied
- GitHub Actions CI that has run successfully
- I want to add chaos testing

Please activate automation-architect-nfr
```

### Expected Results
- [ ] Skill does NOT present the NFR interview
- [ ] Skill specifically names missing `@pytest.mark.smoke` and `@pytest.mark.regression`
- [ ] Skill shows an example of how to add the markers to a test function
- [ ] Skill explains WHY markers are required (NFR tests filter on these markers)

### Pass Criteria
All 4 items checked.

### Debug Tips
- Generic "markers missing" message without example → improve NFR gate messaging in `SKILL.md`
- Wrong marker names → check gate condition spec in `automation-architect-nfr/SKILL.md`
