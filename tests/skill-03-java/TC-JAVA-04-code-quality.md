# TC-JAVA-04 — Java Code Quality

**Skill**: automation-architect-java  
**Total TCs**: 6  
**Level**: L3  
**Model**: Sonnet  
**Config**: `test-configs/run-d-java-api.md` (respond [Y] to write files)  
**Pre-req**: TC-JAVA-01 through TC-JAVA-03 passing; Java 17+, Maven 3.9+ installed

---

## Setup (run once before all TCs in this file)

```bash
mkdir /tmp/test-java-quality && cd /tmp/test-java-quality
claude
/model claude-sonnet-4-6
```
Paste `run-d-java-api.md` and respond `Y`.

```bash
# Verify files written
ls /tmp/test-java-quality
# Expected: pom.xml, src/, testng.xml, config/, mocks/, etc.
```

---

## TC-JAVA-04-01 — pom.xml is valid XML and mvn validate passes

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L3 |
| Type | Code Quality |
| Model | N/A (shell) |

### Steps
```bash
cd /tmp/test-java-quality
mvn validate -q
echo "Exit code: $?"
```

### Expected Results
- [ ] `mvn validate` exits with code 0
- [ ] No `[ERROR]` lines in output
- [ ] No XML parse errors

### Pass Criteria
Exit code 0 with zero errors.

### Debug Tips
- XML parse error → malformed tag in `pom.xml` template in Java references
- Dependency not found → version typo or wrong artifactId; check `references/api/layer2-restassured-client.md`

---

## TC-JAVA-04-02 — mvn compile succeeds with zero errors

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L3 |
| Type | Code Quality |
| Model | N/A (shell) |

### Steps
```bash
cd /tmp/test-java-quality
mvn compile -q 2>&1 | grep -E "ERROR|error:" | head -20
echo "Exit code: $?"
```

### Expected Results
- [ ] `mvn compile` exits with code 0
- [ ] Zero `error:` lines in output
- [ ] No `cannot find symbol` errors
- [ ] No `package does not exist` errors

### Pass Criteria
Exit code 0 with zero error lines.

### Debug Tips
- `cannot find symbol` → missing import in a generated `.java` file; trace back to which reference template has the bad code
- `package does not exist` → wrong package declaration in a model or service class

---

## TC-JAVA-04-03 — mvn test-compile succeeds

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L3 |
| Type | Code Quality |
| Model | N/A (shell) |

### Objective
Verify Layer 4 test classes compile — separate from source compile (TC-JAVA-04-02).

### Steps
```bash
cd /tmp/test-java-quality
mvn test-compile -q 2>&1 | grep -E "ERROR|error:" | head -20
echo "Exit code: $?"
```

### Expected Results
- [ ] `mvn test-compile` exits with code 0
- [ ] Zero `error:` lines in output
- [ ] TestNG `@Test` annotations resolve (not "cannot find symbol")
- [ ] RestAssured static imports resolve in test classes

### Pass Criteria
Exit code 0 with zero error lines.

---

## TC-JAVA-04-04 — TestNG XML discovers all test classes

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L3 |
| Type | Code Quality |
| Model | N/A (shell) |

### Objective
Verify testng.xml is valid and references test classes that exist in the compiled output.

### Steps
```bash
cd /tmp/test-java-quality
mvn test-compile -q

# List class names in testng.xml
grep "class name" testng.xml

# Verify each referenced class file exists
find target/test-classes -name "*.class" | grep -i "test"
```

### Expected Results
- [ ] Each `<class name="...">` in testng.xml has a corresponding `.class` file in `target/test-classes/`
- [ ] At least one API test class discovered
- [ ] No `<class name="">` empty entries

### Pass Criteria
All 3 items checked.

---

## TC-JAVA-04-05 — WireMock stubs load without JSON parse errors

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L3 |
| Type | Code Quality |
| Model | N/A (shell) |

### Preconditions
- Docker Desktop running
- Port 8080 available

### Steps
```bash
cd /tmp/test-java-quality
docker-compose up -d wiremock
sleep 3

# Health check
curl -s http://localhost:8080/__admin/health

# List mappings
curl -s http://localhost:8080/__admin/mappings | python -m json.tool | grep '"name"'

# Check for errors
docker-compose logs wiremock | grep -i "error\|invalid\|fail"
```

### Expected Results
- [ ] Health returns `{"status":"Running",...}`
- [ ] At least 2 stub names listed
- [ ] Stub names follow `verb-resource-scenario` pattern
- [ ] Zero error lines in WireMock logs

### Pass Criteria
All 4 items checked.

### Cleanup
```bash
docker-compose down
```

---

## TC-JAVA-04-06 — Allure report generated after test run

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L3 |
| Type | Code Quality |
| Model | N/A (shell) |

### Preconditions
- TC-JAVA-04-05 passing
- Allure CLI installed: `brew install allure`

### Steps
```bash
cd /tmp/test-java-quality

# Run tests against WireMock
docker-compose up -d wiremock
mvn test -Denv=mock 2>&1 | tail -10

# Generate and serve report
allure serve target/allure-results/
```

### Expected Results
- [ ] `target/allure-results/` directory exists with at least one result file
- [ ] Allure report opens in browser
- [ ] Test cases visible with PASS / FAIL status
- [ ] Test steps visible within each test case
- [ ] No "No data" dashboard

### Pass Criteria
All 5 items checked.

### Cleanup
```bash
docker-compose down
rm -rf /tmp/test-java-quality
```
