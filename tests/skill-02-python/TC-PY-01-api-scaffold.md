# TC-PY-01 — Python API Scaffold

**Skill**: automation-architect-python  
**Total TCs**: 6  
**Level**: L2  
**Model**: Haiku (preview checks); Sonnet (if writing files)  
**Config**: `test-configs/run-a-python-api.md`  
**Pre-req**: Orchestrator interview flow passing (TC-ORCH-03 green)

All TCs in this file use `--test` (no files written) unless stated otherwise.

---

## TC-PY-01-01 — API scaffold includes all Layer 1 Pydantic model files

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Layer 1 contains Pydantic model files that cover request and response schemas.

### Steps
```
{paste run-a-python-api.md block} --test
```
Inspect the Scaffold Preview file tree, Layer 1 section.

### Expected Results
- [ ] `layer_1_models/api/` directory present in file tree
- [ ] At least one model file (e.g., `user_model.py` or equivalent)
- [ ] At least one factory file (e.g., `user_factory.py` or `factories.py`)
- [ ] `layer_1_models/ui/` directory ABSENT (API-only config)
- [ ] Model files use `.py` extension (not `.java`)

### Pass Criteria
All 5 items checked.

### Debug Tips
- Layer 1 missing → check profile loading in `automation-architect-python/SKILL.md`
- UI models present → test_type filter not applied correctly

---

## TC-PY-01-02 — API scaffold includes BaseApiClient with retry and logging decorators

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Layer 2 contains the HTTP client with retry and logging built in as decorators.

### Steps
```
{paste run-a-python-api.md block} --test
```
Inspect Layer 2 in the Scaffold Preview and the code snippet (if not using --test, use full mode).

### Expected Results
- [ ] `layer_2_clients/api/base_api_client.py` present in file tree
- [ ] File annotation or snippet references retry logic
- [ ] File annotation or snippet references logging decorator
- [ ] `layer_2_clients/ui/` ABSENT (API-only)

### Pass Criteria
All 4 items checked.

---

## TC-PY-01-03 — API scaffold includes UserService in Layer 3

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Layer 3 contains service classes that wrap Layer 2 and return typed objects.

### Steps
```
{paste run-a-python-api.md block} --test
```
Inspect Layer 3 in the Scaffold Preview.

### Expected Results
- [ ] `layer_3_services/` directory present
- [ ] At least one service file present (e.g., `user_service.py`)
- [ ] `layer_3_pages/` ABSENT (API-only)
- [ ] Service file annotation mentions "returns typed Pydantic model" or equivalent

### Pass Criteria
All 4 items checked.

---

## TC-PY-01-04 — API scaffold includes pytest test file in Layer 4

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Layer 4 contains pytest test files that exercise the API service.

### Steps
```
{paste run-a-python-api.md block} --test
```
Inspect Layer 4 in the Scaffold Preview.

### Expected Results
- [ ] `layer_4_tests/api/` directory present
- [ ] At least one `test_*.py` file present (e.g., `test_user_api.py`)
- [ ] `layer_4_tests/ui/` ABSENT (API-only)
- [ ] `conftest.py` present (pytest fixtures file)
- [ ] `pytest.ini` or `pyproject.toml` present (test runner config)

### Pass Criteria
All 5 items checked.

---

## TC-PY-01-05 — API-only scaffold excludes all UI files

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Negative |
| Model | Haiku |

### Objective
Verify that choosing API-only produces zero UI-related files in the preview.

### Steps
```
{paste run-a-python-api.md block} --test
```
Search the entire Scaffold Preview for UI-related file names.

### Expected Results
- [ ] No `browser_session.py` in file tree
- [ ] No `driver_manager.py` in file tree
- [ ] No `layer_1_models/ui/` directory
- [ ] No `layer_3_pages/` directory
- [ ] No `layer_4_tests/ui/` directory
- [ ] No Playwright import visible in any code snippet

### Pass Criteria
All 6 items checked.

---

## TC-PY-01-06 — OAuth2 auth generates auth_manager.py

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify the Singleton Auth pattern generates `auth_manager.py` when OAuth2 is selected.
Contrasted with a no-auth config to confirm absence when auth=none.

### Steps — Part A (OAuth2 selected, run-a)
```
{paste run-a-python-api.md block} --test
```

### Steps — Part B (no-auth, run-e)
```
{paste run-e-python-api-no-mock.md block — but change auth to None} --test
```

### Expected Results — Part A
- [ ] `config/auth_manager.py` present in file tree
- [ ] Singleton Auth pattern shown as `[+]` in pattern list

### Expected Results — Part B
- [ ] `config/auth_manager.py` ABSENT from file tree
- [ ] Singleton Auth pattern NOT shown as `[+]`

### Pass Criteria
All 4 items checked (both parts).

### Debug Tips
- auth_manager.py present when auth=none → activation condition too broad in `pattern-registry.md`
