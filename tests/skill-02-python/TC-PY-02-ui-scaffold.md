# TC-PY-02 — Python UI Scaffold

**Skill**: automation-architect-python  
**Total TCs**: 5  
**Level**: L2  
**Model**: Haiku  
**Config**: `test-configs/run-b-python-ui.md`  
**Pre-req**: TC-PY-01 passing

All TCs in this file use `--test` (no files written).

---

## TC-PY-02-01 — UI scaffold includes Playwright browser_session.py

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Layer 2 for UI contains a Playwright browser session manager.

### Steps
```
{paste run-b-python-ui.md block} --test
```
Inspect Layer 2 in the Scaffold Preview.

### Expected Results
- [ ] `layer_2_clients/ui/browser_session.py` present in file tree
- [ ] `layer_2_clients/api/` ABSENT (UI-only)
- [ ] Annotation or snippet references Playwright (not Selenium)
- [ ] `async_playwright` or `sync_playwright` visible in snippet (if full mode used)

### Pass Criteria
All 4 items checked.

### Debug Tips
- Selenium present instead of Playwright → Python UI track is using the Java reference by mistake
- Check `automation-architect-python/references/ui/layer2-browser-session.md`

---

## TC-PY-02-02 — UI scaffold includes Page Object in Layer 3

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Layer 3 contains Page Object classes for the UI workflow under test.

### Steps
```
{paste run-b-python-ui.md block} --test
```
Inspect Layer 3 in the Scaffold Preview.

### Expected Results
- [ ] `layer_3_pages/` directory present
- [ ] At least one page object file (e.g., `login_page.py`, `home_page.py`)
- [ ] `layer_3_services/` ABSENT (UI-only)
- [ ] Page Object annotation mentions "wraps locators, no assertions"

### Pass Criteria
All 4 items checked.

---

## TC-PY-02-03 — UI scaffold includes driver_manager.py

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify the Singleton Driver pattern generates `driver_manager.py` for UI test types.

### Steps
```
{paste run-b-python-ui.md block} --test
```
Inspect the `config/` section of the Scaffold Preview.

### Expected Results
- [ ] `config/driver_manager.py` present in file tree
- [ ] Singleton Driver pattern shown as `[+]` in pattern list
- [ ] `config/auth_manager.py` ABSENT (run-b uses token injection, not OAuth2 flow that needs auth_manager)

### Pass Criteria
All 3 items checked.

### Debug Tips
- driver_manager.py absent → Singleton Driver activation condition not met
- Check `references/pattern-registry.md` for `test_type includes UI` condition

---

## TC-PY-02-04 — UI-only scaffold excludes API client and service files

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Negative |
| Model | Haiku |

### Objective
Verify that a UI-only config produces zero API-related files.

### Steps
```
{paste run-b-python-ui.md block} --test
```
Search the entire Scaffold Preview for API-related file names.

### Expected Results
- [ ] No `base_api_client.py` in file tree
- [ ] No `layer_3_services/` directory
- [ ] No `layer_1_models/api/` directory
- [ ] No `layer_4_tests/api/` directory
- [ ] No `requests` import visible in any snippet
- [ ] No Pydantic model visible in any snippet

### Pass Criteria
All 6 items checked.

---

## TC-PY-02-05 — Chrome-only: Browser Factory pattern NOT activated

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L2 |
| Type | Negative |
| Model | Haiku |

### Objective
Verify the Browser Factory pattern is deferred (not activated) when only one
browser is selected. Activation only triggers when browser_targets > 1.

### Steps — Part A (Chrome only, run-b)
```
{paste run-b-python-ui.md block} --test
```

### Steps — Part B (Chrome + Firefox, run-f)
```
{paste run-f-python-ui-multi-browser.md block} --test
```

### Expected Results — Part A (Chrome only)
- [ ] Browser Factory pattern shown as `[~]` deferred (NOT `[+]`)
- [ ] No `browser_factory.py` in file tree

### Expected Results — Part B (Chrome + Firefox)
- [ ] Browser Factory pattern shown as `[+]` active
- [ ] `layer_2_clients/ui/browser_factory.py` present in file tree

### Pass Criteria
All 4 items checked.

### Debug Tips
- Factory active for single browser → check activation condition `browser_targets > 1` in `pattern-registry.md`
