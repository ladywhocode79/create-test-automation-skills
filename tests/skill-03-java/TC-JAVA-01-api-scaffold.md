# TC-JAVA-01 — Java API Scaffold

**Skill**: automation-architect-java  
**Total TCs**: 6  
**Level**: L2  
**Model**: Haiku  
**Config**: `test-configs/run-d-java-api.md`  
**Pre-req**: Orchestrator routing to Java passing (TC-ORCH-03-08 green)

All TCs in this file use `--test` (no files written).

---

## TC-JAVA-01-01 — API scaffold includes Jackson model POJOs

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Layer 1 contains Jackson-annotated POJO classes for request/response schemas.

### Steps
```
{paste run-d-java-api.md block} --test
```
Inspect Layer 1 in the Scaffold Preview.

### Expected Results
- [ ] `layer_1_models/api/` directory present in file tree
- [ ] At least one model POJO (e.g., `UserModel.java` or `User.java`)
- [ ] At least one factory class (e.g., `UserFactory.java`)
- [ ] `layer_1_models/ui/` ABSENT (API-only)
- [ ] Files use `.java` extension (not `.py`)

### Pass Criteria
All 5 items checked.

---

## TC-JAVA-01-02 — API scaffold includes BaseApiClient with RestAssured

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Layer 2 contains a RestAssured-based HTTP client with retry and logging.

### Steps
```
{paste run-d-java-api.md block} --test
```

### Expected Results
- [ ] `layer_2_clients/api/BaseApiClient.java` present (or equivalent name)
- [ ] Annotation references RestAssured (`given()`, `when()`, `then()`)
- [ ] Annotation references retry logic or request logging
- [ ] `layer_2_clients/ui/` ABSENT (API-only)

### Pass Criteria
All 4 items checked.

---

## TC-JAVA-01-03 — API scaffold includes UserService in Layer 3

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Layer 3 contains service classes returning deserialized Java objects.

### Steps
```
{paste run-d-java-api.md block} --test
```

### Expected Results
- [ ] `layer_3_services/` directory present
- [ ] At least one service class (e.g., `UserService.java`)
- [ ] `layer_3_pages/` ABSENT (API-only)
- [ ] Service annotation mentions "returns typed POJO" or "no assertions"

### Pass Criteria
All 4 items checked.

---

## TC-JAVA-01-04 — API scaffold includes TestNG test class in Layer 4

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Layer 4 contains TestNG test classes with `@Test` annotations.

### Steps
```
{paste run-d-java-api.md block} --test
```

### Expected Results
- [ ] `layer_4_tests/api/` directory present
- [ ] At least one test class (e.g., `UserApiTest.java`)
- [ ] `layer_4_tests/ui/` ABSENT (API-only)
- [ ] `testng.xml` present at project root
- [ ] Annotation or snippet shows `@Test` from TestNG

### Pass Criteria
All 5 items checked.

---

## TC-JAVA-01-05 — API-only scaffold excludes all UI files

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Negative |
| Model | Haiku |

### Objective
Verify zero UI-related Java files in an API-only scaffold.

### Steps
```
{paste run-d-java-api.md block} --test
```

### Expected Results
- [ ] No `BrowserSession.java` in file tree
- [ ] No `DriverManager.java` in file tree
- [ ] No `layer_1_models/ui/` directory
- [ ] No `layer_3_pages/` directory
- [ ] No `layer_4_tests/ui/` directory
- [ ] No Selenium WebDriver import in any snippet

### Pass Criteria
All 6 items checked.

---

## TC-JAVA-01-06 — Bearer auth generates AuthManager.java

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify AuthManager.java is generated when Bearer/JWT auth is selected,
and absent when auth is none.

### Steps — Part A (Bearer, run-d)
```
{paste run-d-java-api.md block} --test
```

### Steps — Part B (no auth — modify run-c which has auth=None)
```
{paste run-c-java-fullstack.md block — API portion only} --test
```

### Expected Results — Part A
- [ ] `config/AuthManager.java` present
- [ ] Singleton Auth `[+]` active in pattern list

### Expected Results — Part B
- [ ] `config/AuthManager.java` ABSENT
- [ ] Singleton Auth absent or `[~]` deferred

### Pass Criteria
All 4 items checked.
