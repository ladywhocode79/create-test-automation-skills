# TC-JAVA-02 — Java UI Scaffold

**Skill**: automation-architect-java  
**Total TCs**: 5  
**Level**: L2  
**Model**: Haiku  
**Pre-req**: TC-JAVA-01 passing

### Reference Config — Java UI Only
```
Use the automation-architect skill with these answers — skip the interview and go straight to the Config Summary and Scaffold Preview:

test_type: UI
language: Java
browsers: Chrome only
execution: headless
locator_strategy: data-testid
ui_auth: login via form
environments: dev
secret_management: .env files
mock: real service only
reporting: Allure
ci: GitHub Actions
project_name: my-java-ui-framework --test
```

---

## TC-JAVA-02-01 — UI scaffold includes BrowserSession with Selenium WebDriver

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Layer 2 for Java UI contains a Selenium WebDriver browser session class.

### Steps
Paste the Java UI reference config above.

### Expected Results
- [ ] `layer_2_clients/ui/BrowserSession.java` present (or equivalent)
- [ ] `layer_2_clients/api/` ABSENT (UI-only)
- [ ] Annotation or snippet references Selenium WebDriver (not Playwright)
- [ ] WebDriverManager referenced (for driver binary management)

### Pass Criteria
All 4 items checked.

### Debug Tips
- Playwright referenced instead of Selenium → Java track loaded Python UI reference
- Check `automation-architect-java/references/ui/layer2-webdriver-session.md`

---

## TC-JAVA-02-02 — UI scaffold includes Page Object in Layer 3

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Layer 3 contains Java Page Object classes using the Page Object pattern.

### Steps
Paste the Java UI reference config.

### Expected Results
- [ ] `layer_3_pages/` directory present
- [ ] At least one page class (e.g., `LoginPage.java`, `HomePage.java`)
- [ ] `layer_3_services/` ABSENT (UI-only)
- [ ] Annotation mentions "no assertions in page objects"

### Pass Criteria
All 4 items checked.

---

## TC-JAVA-02-03 — UI scaffold includes DriverManager.java

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Singleton Driver pattern generates DriverManager.java for UI types.

### Steps
Paste the Java UI reference config.

### Expected Results
- [ ] `config/DriverManager.java` present
- [ ] Singleton Driver pattern `[+]` active in pattern list

### Pass Criteria
Both items checked.

---

## TC-JAVA-02-04 — UI-only scaffold excludes API client and service files

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Negative |
| Model | Haiku |

### Objective
Verify zero API-related Java files in a UI-only scaffold.

### Steps
Paste the Java UI reference config.

### Expected Results
- [ ] No `BaseApiClient.java` in file tree
- [ ] No `layer_3_services/` directory
- [ ] No `layer_1_models/api/` directory
- [ ] No `layer_4_tests/api/` directory
- [ ] No RestAssured import visible in any snippet

### Pass Criteria
All 5 items checked.

---

## TC-JAVA-02-05 — Chrome-only: Browser Factory NOT activated

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L2 |
| Type | Negative |
| Model | Haiku |

### Objective
Verify Browser Factory is deferred for single-browser (Chrome only) Java configs
and activated for multi-browser (Chrome + Firefox).

### Steps — Part A (Chrome only — Java UI config above)
Paste Java UI reference config (Chrome only).

### Steps — Part B (Chrome + Firefox — run-c)
```
{paste run-c-java-fullstack.md block} --test
```
(run-c specifies Chrome + Firefox)

### Expected Results — Part A
- [ ] Browser Factory `[~]` deferred
- [ ] No `BrowserFactory.java` in file tree

### Expected Results — Part B
- [ ] Browser Factory `[+]` active
- [ ] `layer_2_clients/ui/BrowserFactory.java` present

### Pass Criteria
All 4 items checked.
