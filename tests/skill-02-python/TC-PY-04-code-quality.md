# TC-PY-04 — Python Code Quality

**Skill**: automation-architect-python  
**Total TCs**: 6  
**Level**: L3  
**Model**: Sonnet (code quality requires higher reasoning)  
**Config**: `test-configs/run-a-python-api.md` (respond [Y] to write files)  
**Pre-req**: TC-PY-01 through TC-PY-03 passing; Python 3.11+ installed

---

## Setup (run once before all TCs in this file)

```bash
mkdir /tmp/test-py-quality && cd /tmp/test-py-quality
claude
/model claude-sonnet-4-6
```
Paste `run-a-python-api.md` block and respond `Y` to write all files.

---

## TC-PY-04-01 — All Python files pass py_compile syntax check

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L3 |
| Type | Code Quality |
| Model | Sonnet |

### Objective
Verify every generated `.py` file is syntactically valid Python.

### Steps
```bash
find /tmp/test-py-quality -name "*.py" | while read f; do
  python -m py_compile "$f" && echo "OK: $f" || echo "FAIL: $f"
done
```

### Expected Results
- [ ] Every `.py` file outputs `OK: <path>` — zero failures
- [ ] No `SyntaxError` or `IndentationError` in output

### Pass Criteria
Zero `FAIL:` lines in output.

### Debug Tips
- `SyntaxError` in a model file → typo in `references/api/layer1-pydantic-models.md` code block
- `IndentationError` in client file → indentation in `references/api/layer2-requests-client.md` is broken
- Fix in the relevant reference file, then `./sync.sh to-global` and re-generate

---

## TC-PY-04-02 — Layer imports pass import-linter (no upward dependencies)

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L3 |
| Type | Code Quality |
| Model | Sonnet |

### Objective
Verify no layer imports from a higher layer. Allowed direction: Layer 4 → 3 → 2 → 1 only.

### Steps
```bash
cd /tmp/test-py-quality
pip install import-linter --quiet
lint-imports --config .importlinter
```

### Expected Results
- [ ] `lint-imports` exits with code 0
- [ ] Output: "All import contracts kept" (or zero violations)
- [ ] No line like "layer_1_models imports from layer_2_clients"

### Pass Criteria
Zero import violations.

### Debug Tips
- Violation found → a reference template is importing from the wrong layer
- Identify the file from the lint output, fix the import, re-sync, re-generate
- If `.importlinter` file is missing → check that it was generated in the scaffold (it should always be present)

---

## TC-PY-04-03 — pytest --collect-only finds all tests with zero import errors

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L3 |
| Type | Code Quality |
| Model | Sonnet |

### Objective
Verify pytest can collect (not run) all test files without import errors.
This validates that all imports resolve and test functions are discoverable.

### Steps
```bash
cd /tmp/test-py-quality
pip install -r requirements.txt --quiet
pytest layer_4_tests/ --collect-only -q 2>&1 | tail -20
```

### Expected Results
- [ ] Output shows collected test items (e.g., `<N> tests collected`)
- [ ] Zero `ImportError` or `ModuleNotFoundError` lines
- [ ] Zero `ERROR collecting` lines
- [ ] At least 3 test functions collected

### Pass Criteria
All 4 items checked.

### Debug Tips
- `ModuleNotFoundError: No module named 'layer_1_models'` → `conftest.py` or `pyproject.toml` is not setting up the Python path correctly
- `ImportError` in a service file → cross-layer import problem (run TC-PY-04-02 first)

---

## TC-PY-04-04 — WireMock stubs load into Docker without JSON parse errors

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L3 |
| Type | Code Quality |
| Model | N/A (shell commands only) |

### Preconditions
- Docker Desktop running
- Port 8080 available

### Steps
```bash
cd /tmp/test-py-quality
docker-compose up -d wiremock
sleep 3

# Check health
curl -s http://localhost:8080/__admin/health

# List loaded mappings
curl -s http://localhost:8080/__admin/mappings | python -m json.tool | grep '"name"'

# Check for errors in logs
docker-compose logs wiremock | grep -i "error\|fail\|invalid"
```

### Expected Results
- [ ] Health check returns `{"status":"Running",...}`
- [ ] Mappings list shows at least 2 stub names
- [ ] Stub names follow `verb-resource-scenario` convention (e.g., `post-users-success`)
- [ ] No `error` or `invalid` lines in WireMock logs
- [ ] docker-compose exit code is 0

### Pass Criteria
All 5 items checked.

### Cleanup
```bash
docker-compose down
```

---

## TC-PY-04-05 — Tests pass against WireMock in mock mode

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L3 |
| Type | Code Quality |
| Model | N/A (shell commands only) |

### Preconditions
- TC-PY-04-04 passing (WireMock running and stubs loaded)

### Steps
```bash
cd /tmp/test-py-quality
cp .env.example .env

# Set mock mode
sed -i '' 's/BASE_URL=.*/BASE_URL=http:\/\/localhost:8080/' .env
sed -i '' 's/TEST_MODE=.*/TEST_MODE=mock/' .env

docker-compose up -d wiremock
pytest layer_4_tests/api/ -v --tb=short 2>&1
```

### Expected Results
- [ ] Pytest runs without crashing
- [ ] All tests that target mock endpoints PASS
- [ ] No `AssertionError` caused by missing stub (all stubs cover the test scenarios)
- [ ] Exit code 0

### Pass Criteria
All 4 items checked.

### Debug Tips
- `ConnectionRefusedError` → WireMock not running; check docker-compose up
- `404 on stub` → stub name or URL pattern mismatch; check `mocks/stubs/` JSON files
- `ValidationError` → Pydantic model schema doesn't match stub response body

### Cleanup
```bash
docker-compose down
```

---

## TC-PY-04-06 — Allure report generated with test steps visible

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L3 |
| Type | Code Quality |
| Model | N/A (shell commands only) |

### Preconditions
- TC-PY-04-05 passing (tests ran successfully)
- Allure CLI installed: `brew install allure`

### Steps
```bash
cd /tmp/test-py-quality

# Run tests with Allure output
docker-compose up -d wiremock
pytest layer_4_tests/api/ -v --alluredir=allure-results
allure serve allure-results/
```

### Expected Results
- [ ] `allure-results/` directory created with at least one `.json` result file
- [ ] `allure serve` opens a browser report
- [ ] Test results visible with PASSED / FAILED status
- [ ] Test steps visible within each test case (not just test name)
- [ ] No "No data" message in the Allure dashboard

### Pass Criteria
All 5 items checked.

### Cleanup
```bash
docker-compose down
rm -rf /tmp/test-py-quality
```
