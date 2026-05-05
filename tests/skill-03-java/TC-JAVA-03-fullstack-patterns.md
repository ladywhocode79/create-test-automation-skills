# TC-JAVA-03 — Java Full-Stack & Design Pattern Activation

**Skill**: automation-architect-java  
**Total TCs**: 7  
**Level**: L2  
**Model**: Haiku  
**Config**: `test-configs/run-c-java-fullstack.md`  
**Pre-req**: TC-JAVA-01 and TC-JAVA-02 passing

All TCs use `--test`.

---

## TC-JAVA-03-01 — Full-Stack includes both service and page layers

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Full-Stack config generates both `layer_3_services/` and `layer_3_pages/`.

### Steps
```
{paste run-c-java-fullstack.md block} --test
```

### Expected Results
- [ ] `layer_3_services/` directory present with at least one `.java` service class
- [ ] `layer_3_pages/` directory present with at least one `.java` page class
- [ ] Both directories are non-empty

### Pass Criteria
All 3 items checked.

---

## TC-JAVA-03-02 — Full-Stack includes valid pom.xml with correct dependency versions

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify pom.xml is generated with the required dependencies at the correct pinned versions.

### Steps
```
{paste run-c-java-fullstack.md block} --test
```
Inspect the pom.xml snippet in the preview (or use full mode without --test to see it).

### Expected Results
- [ ] `pom.xml` present in file tree root
- [ ] TestNG dependency present (version 7.10.x)
- [ ] RestAssured dependency present (version 5.4.x)
- [ ] Jackson databind dependency present (version 2.17.x)
- [ ] Selenium WebDriver dependency present (version 4.21.x)
- [ ] WebDriverManager dependency present (version 5.8.x)
- [ ] Allure-TestNG dependency present (Allure selected in run-c)
- [ ] ArchUnit dependency present (layer enforcement)

### Pass Criteria
All 8 items checked.

### Debug Tips
- Wrong version → update `automation-architect-java/references/api/layer2-restassured-client.md` or `pom.xml` template
- Missing dependency → check which config option triggers inclusion

---

## TC-JAVA-03-03 — testng.xml lists all test classes

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify testng.xml is generated and references all Layer 4 test classes.

### Steps
```
{paste run-c-java-fullstack.md block} --test
```
Inspect testng.xml snippet if available, or check it's listed in the file tree.

### Expected Results
- [ ] `testng.xml` present at project root
- [ ] At least one API test class referenced in testng.xml (e.g., `UserApiTest`)
- [ ] At least one UI test class referenced in testng.xml (Full-Stack)
- [ ] Suite name defined (not blank)

### Pass Criteria
All 4 items checked.

---

## TC-JAVA-03-04 — config.properties generated with correct env keys

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify the type-safe config file has keys for all resolved config values.

### Steps
```
{paste run-c-java-fullstack.md block} --test
```

### Expected Results
- [ ] `src/test/resources/config.properties` present (or `config/` equivalent)
- [ ] `base.url` key present
- [ ] `env` key present (staging, prod from run-c)
- [ ] `browser` key present (Chrome + Firefox)
- [ ] `execution.mode` key present (headless / headed)

### Pass Criteria
All 5 items checked.

---

## TC-JAVA-03-05 — ArchUnit layer test file present for dependency enforcement

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify an ArchUnit test class is included to enforce the 4-layer import rules at compile time.

### Steps
```
{paste run-c-java-fullstack.md block} --test
```

### Expected Results
- [ ] `LayerArchitectureTest.java` (or equivalent) present in `layer_4_tests/`
- [ ] ArchUnit dependency present in `pom.xml`
- [ ] File annotation references "enforces layer dependency rules"

### Pass Criteria
All 3 items checked.

---

## TC-JAVA-03-06 — GitLab CI template generated when GitLab selected

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify the correct CI template is generated based on the `ci` config value.
run-c selects GitLab CI, so `.gitlab-ci.yml` should appear — not `.github/workflows/`.

### Steps
```
{paste run-c-java-fullstack.md block} --test
```

### Expected Results
- [ ] `.gitlab-ci.yml` present in file tree
- [ ] `.github/workflows/` ABSENT (GitHub Actions not selected)
- [ ] GitLab CI snippet uses `stages:` and `script:` keys (not GitHub Actions `on:` / `jobs:`)

### Pass Criteria
All 3 items checked.

### Debug Tips
- GitHub Actions generated instead → CI selection routing bug in Java SKILL.md
- Check CI template selection logic in `automation-architect/references/ci-templates.md`

---

## TC-JAVA-03-07 — Browser Factory activated when Chrome+Firefox selected

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Browser Factory pattern `[+]` for multi-browser Java Full-Stack config.
run-c specifies `browsers: Chrome + Firefox`.

### Steps
```
{paste run-c-java-fullstack.md block} --test
```

### Expected Results
- [ ] Browser Factory `[+]` active in pattern list
- [ ] `layer_2_clients/ui/BrowserFactory.java` present in file tree
- [ ] Factory accepts browser type as parameter (visible in snippet or annotation)

### Pass Criteria
All 3 items checked.
