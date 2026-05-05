# TC-PY-03 — Python Full-Stack & Design Pattern Activation

**Skill**: automation-architect-python  
**Total TCs**: 7  
**Level**: L2  
**Model**: Haiku  
**Pre-req**: TC-PY-01 and TC-PY-02 passing

For Full-Stack configs, use run-a answers modified to `test_type: Full-Stack`
or paste a custom config block. Use `--test` throughout.

### Reference Config — Python Full-Stack (use inline)
```
Use the automation-architect skill with these answers — skip the interview and go straight to the Config Summary and Scaffold Preview:

test_type: Full-Stack (API + UI)
language: Python
protocol: REST/JSON
auth: OAuth2 Client Credentials
browsers: Chrome only
execution: both (headless + headed via env var)
locator_strategy: data-testid
ui_auth: login via form
environments: dev, staging
secret_management: .env files
mock: both (real + WireMock)
reporting: Allure
ci: GitHub Actions
data_strategy: mixed (fixtures + factory)
project_name: my-fullstack-py --test
```

---

## TC-PY-03-01 — Full-Stack includes both Layer 3 services AND pages

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify that Full-Stack generates both `layer_3_services/` and `layer_3_pages/`.

### Steps
Paste the Full-Stack reference config above.

### Expected Results
- [ ] `layer_3_services/` directory present with at least one service file
- [ ] `layer_3_pages/` directory present with at least one page file
- [ ] Neither directory is empty

### Pass Criteria
All 3 items checked.

---

## TC-PY-03-02 — Full-Stack includes both Layer 4 API and UI test files

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Layer 4 contains separate test directories for API and UI.

### Steps
Paste the Full-Stack reference config.

### Expected Results
- [ ] `layer_4_tests/api/` directory present with at least one `test_*.py`
- [ ] `layer_4_tests/ui/` directory present with at least one `test_*.py`
- [ ] `conftest.py` covers shared fixtures for both

### Pass Criteria
All 3 items checked.

---

## TC-PY-03-03 — Singleton Auth activated when auth is not none

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Singleton Auth pattern [+] when auth is OAuth2 or Bearer.
Verify it is absent when auth is none.

### Steps — Part A (OAuth2, Full-Stack config above)
Paste Full-Stack reference config.

### Steps — Part B (no auth — modify config)
```
... same but auth: None/Public ...
```

### Expected Results — Part A
- [ ] Singleton Auth `[+]` active in pattern list
- [ ] `config/auth_manager.py` present

### Expected Results — Part B
- [ ] Singleton Auth `[~]` deferred or absent
- [ ] `config/auth_manager.py` absent

### Pass Criteria
All 4 items checked.

---

## TC-PY-03-04 — Singleton Driver activated for UI test types

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Singleton Driver is [+] for any test_type that includes UI (UI-only or Full-Stack).
Verify it is absent for API-only.

### Steps — Part A (Full-Stack includes UI)
Paste Full-Stack reference config.

### Steps — Part B (API-only)
Paste `test-configs/run-a-python-api.md`.

### Expected Results — Part A
- [ ] Singleton Driver `[+]` active
- [ ] `config/driver_manager.py` present

### Expected Results — Part B
- [ ] Singleton Driver absent or `[~]` deferred
- [ ] `config/driver_manager.py` absent

### Pass Criteria
All 4 items checked.

---

## TC-PY-03-05 — Browser Factory activated only when browser_targets > 1

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Browser Factory activates only for multi-browser configs.

### Steps — Part A (Chrome + Firefox)
```
{paste run-f-python-ui-multi-browser.md block} --test
```

### Steps — Part B (Chrome only)
```
{paste run-b-python-ui.md block} --test
```

### Expected Results — Part A
- [ ] Browser Factory `[+]` active
- [ ] `layer_2_clients/ui/browser_factory.py` present

### Expected Results — Part B
- [ ] Browser Factory `[~]` deferred
- [ ] `browser_factory.py` absent

### Pass Criteria
All 4 items checked.

---

## TC-PY-03-06 — Strategy Mock activated only when mock is "both" or "mock-only"

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify the Strategy pattern for real/mock client switching is only generated
when the user chose to include WireMock.

### Steps — Part A (mock=both, run-a)
```
{paste run-a-python-api.md block} --test
```

### Steps — Part B (mock=real service only, run-e)
```
{paste run-e-python-api-no-mock.md block} --test
```

### Expected Results — Part A
- [ ] Strategy Mock `[+]` active in pattern list
- [ ] `docker-compose.yml` present in file tree
- [ ] `mocks/` directory present

### Expected Results — Part B
- [ ] Strategy Mock `[~]` deferred or absent
- [ ] `docker-compose.yml` ABSENT
- [ ] `mocks/` directory ABSENT

### Pass Criteria
All 6 items checked.

---

## TC-PY-03-07 — Builder pattern always shown as deferred [~]

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify the Builder (Payload) pattern is NEVER auto-activated — it is always
listed as [~] deferred regardless of config choices. It requires explicit on-demand request.

### Steps
Run two different configs and check the pattern list in both:
```
{paste run-a-python-api.md block} --test
```
```
{paste Full-Stack reference config} --test
```

### Expected Results
- [ ] Builder Payload `[~]` deferred in run-a config
- [ ] Builder Payload `[~]` deferred in Full-Stack config
- [ ] Builder Payload is never `[+]` active in any pre-scripted config run

### Pass Criteria
All 3 items checked.
