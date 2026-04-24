# Reporting Options

Configuration details and generated code for each supported reporting tool.
The orchestrator selects the correct reporting integration based on the
user's Q8 answer and injects it into the track scaffold.

---

## Tool Comparison

```
Tool           Type              Server Needed?   Best For
───────────────────────────────────────────────────────────────────────
Allure         Rich HTML report  No (static HTML) Beautiful reports with
               + history trends               trends, attachments, steps.
                                              Default recommendation.
ReportPortal   Centralised       Yes (Docker)     Team dashboards, AI
               dashboard                         defect triage, history
                                                 across multiple runs.
pytest-html    Simple HTML       No               Quick local reports, no
/ ExtentReport (single file)                     setup required.
JUnit XML      XML format        No               CI-native integration
                                                 (GitHub, Jenkins, etc.)
                                                 Minimal, no extra tooling.
```

---

## Allure (Recommended Default)

### Python — allure-pytest

```bash
# requirements.txt entries
allure-pytest==2.13.5
```

```ini
# pytest.ini
[pytest]
addopts = --alluredir=allure-results
```

```python
# Example test with Allure annotations
import allure
import pytest

@allure.feature("User Management")
@allure.story("Create User")
class TestUserCreation:

    @allure.title("Create user with valid payload returns 201")
    @allure.severity(allure.severity_level.CRITICAL)
    def test_create_user_success(self, user_service, user_factory):
        with allure.step("Build valid user payload"):
            payload = user_factory.build()

        with allure.step("Call create user endpoint"):
            user = user_service.create_user(payload)

        with allure.step("Assert response schema"):
            assert user.id is not None
            assert user.email == payload.email

    @allure.title("Create user with invalid email returns 400")
    @allure.severity(allure.severity_level.NORMAL)
    def test_create_user_invalid_email(self, user_service, user_factory):
        payload = user_factory.build(email="not-an-email")
        with pytest.raises(Exception) as exc:
            user_service.create_user(payload)
        assert "400" in str(exc.value)
```

```python
# UI test: attach screenshot on failure (conftest.py)
import allure
import pytest

@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    rep = outcome.get_result()
    if rep.when == "call" and rep.failed:
        driver = item.funcargs.get("browser_page") or item.funcargs.get("driver")
        if driver:
            allure.attach(
                driver.screenshot(),
                name="screenshot",
                attachment_type=allure.attachment_type.PNG,
            )
```

```bash
# View report locally
allure serve allure-results/

# Generate static HTML (for artifact upload)
allure generate allure-results/ -o allure-report/ --clean
```

### Java — allure-testng

```xml
<!-- pom.xml -->
<dependency>
    <groupId>io.qameta.allure</groupId>
    <artifactId>allure-testng</artifactId>
    <version>2.25.0</version>
</dependency>
```

```java
// Example test with Allure annotations
@Epic("User Management")
@Feature("Create User")
public class TestUserCreation {

    @Test
    @Story("Valid payload")
    @Severity(SeverityLevel.CRITICAL)
    @Description("POST /users with valid payload returns 201 and valid schema")
    public void testCreateUserSuccess() {
        CreateUserRequest payload = UserFactory.build();

        try (Step step = Allure.step("Call create user endpoint")) {
            UserResponse user = userService.createUser(payload);
            assertThat(user.id()).isNotNull();
            assertThat(user.email()).isEqualTo(payload.email());
        }
    }
}
```

```xml
<!-- testng.xml -->
<suite name="API Tests">
    <listeners>
        <listener class-name="io.qameta.allure.testng.AllureTestNg"/>
    </listeners>
    ...
</suite>
```

---

## ReportPortal

Best for teams who want historical trend analysis across multiple runs
and AI-assisted defect triaging.

### Python — pytest-reportportal

```bash
# requirements.txt
pytest-reportportal==5.4.1
```

```ini
# pytest.ini
[pytest]
rp_uuid = ${RP_UUID}
rp_endpoint = ${RP_ENDPOINT}
rp_project = ${RP_PROJECT}
rp_launch = API Automation Suite
rp_launch_attributes = 'environment:${ENV} branch:${CI_BRANCH}'
```

```bash
# Run with RP enabled
pytest --reportportal layer_4_tests/
```

```bash
# .env.example additions
RP_ENDPOINT=http://localhost:8080
RP_UUID=your-rp-api-key
RP_PROJECT=your-project-name
```

### Java — agent-java-testng

```xml
<dependency>
    <groupId>com.epam.reportportal</groupId>
    <artifactId>agent-java-testng</artifactId>
    <version>5.4.0</version>
</dependency>
```

```properties
# reportportal.properties (src/test/resources/)
rp.endpoint=http://localhost:8080
rp.uuid=${RP_UUID}
rp.launch=API Automation Suite
rp.project=${RP_PROJECT}
```

---

## HTML Report (Simple)

No server needed. Single HTML file artifact.

### Python — pytest-html

```bash
# requirements.txt
pytest-html==4.1.1
```

```ini
# pytest.ini
[pytest]
addopts = --html=reports/report.html --self-contained-html
```

### Java — ExtentReports

```xml
<dependency>
    <groupId>com.aventstack</groupId>
    <artifactId>extentreports</artifactId>
    <version>5.1.1</version>
</dependency>
```

---

## JUnit XML (CI Native)

Minimal. No extra dependencies. Native to GitHub Actions, Jenkins, GitLab CI.

### Python

```ini
# pytest.ini
[pytest]
addopts = --junitxml=reports/junit.xml
```

### Java (TestNG)

TestNG generates JUnit-compatible XML natively.

```xml
<!-- testng.xml -->
<suite name="API Tests" verbose="1">
    <!-- TestNG generates test-output/testng-results.xml by default -->
    ...
</suite>
```

---

## CI Artifact Upload (All Reporters)

All reporting tools produce file artifacts that must be uploaded.
The CI template always includes `if: always()` to capture artifacts
even when tests fail.

```yaml
# GitHub Actions pattern (generated for all reporter choices)
- uses: actions/upload-artifact@v4
  if: always()
  with:
    name: test-results-${{ github.run_number }}
    path: |
      allure-results/        # if reporter = allure
      allure-report/         # if reporter = allure (static HTML)
      reports/               # if reporter = html or junit
      screenshots/           # always included for UI tests
    retention-days: 30
```
