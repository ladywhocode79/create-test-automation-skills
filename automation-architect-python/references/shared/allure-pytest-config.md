# Shared — Allure Pytest Config (Python)

Generated when reporting = Allure. Integrated across both API and UI profiles.

---

## requirements.txt entry

```
allure-pytest>=2.13.5
```

---

## pytest.ini (with Allure)

```ini
[pytest]
testpaths = layer_4_tests
addopts =
    -v
    --tb=short
    --alluredir=allure-results
markers =
    smoke: Core happy path tests — run on every commit
    regression: Full regression suite — run on PRs and nightly
    api: API-layer tests only
    ui: UI-layer tests only
    slow: Tests exceeding 10 seconds
    wip: Work in progress — excluded from CI
filterwarnings =
    ignore::DeprecationWarning
```

---

## Allure Annotation Reference

Use these imports and decorators in Layer 4 test files:

```python
import allure

# Class-level: group tests in report
@allure.feature("User Management")   # top-level grouping
class TestUserCreation:

    # Method-level: sub-grouping + metadata
    @allure.story("Create user — happy path")
    @allure.severity(allure.severity_level.CRITICAL)  # BLOCKER|CRITICAL|NORMAL|MINOR|TRIVIAL
    @allure.title("POST /users with valid payload returns 201 and UserResponse")
    @allure.description("Validates schema, ID generation, and field persistence.")
    def test_create_user_returns_valid_schema(self, ...):

        # Step-level: visible in Allure report timeline
        with allure.step("Build valid user payload"):
            payload = user_factory.build()

        with allure.step("POST /api/v1/users"):
            user = user_service.create_user(payload)

        with allure.step("Assert response schema"):
            assert user.id is not None

    # Attach data to report (useful for debugging failed tests)
    def test_example_with_attachment(self, user_service, user_factory):
        payload = user_factory.build()
        user = user_service.create_user(payload)

        # Attach the response payload for inspection in the report
        allure.attach(
            str(user.model_dump()),
            name="API Response",
            attachment_type=allure.attachment_type.TEXT,
        )
        assert user.id is not None
```

---

## Allure Severity Guide

| Level | When to use |
|---|---|
| `BLOCKER` | Failure blocks the release. Core auth, critical data flows. |
| `CRITICAL` | Failure is a major bug. Core happy paths. Marked `@pytest.mark.smoke`. |
| `NORMAL` | Standard feature behavior. Default level. |
| `MINOR` | Edge case or cosmetic issue. |
| `TRIVIAL` | Lowest priority. Informational tests. |

---

## Running and Viewing Reports

```bash
# Run tests and generate raw results:
pytest layer_4_tests/ -v

# Serve interactive report locally:
allure serve allure-results/

# Generate static HTML (for artifact sharing):
allure generate allure-results/ -o allure-report/ --clean

# Open static report:
allure open allure-report/
```

---

## CI Artifact Upload (GitHub Actions)

```yaml
- name: Run tests
  run: pytest layer_4_tests/ -v --alluredir=allure-results

- name: Upload Allure results
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: allure-results-${{ github.run_number }}
    path: allure-results/
    retention-days: 30
```

For Allure history (trend charts across runs), use:
```yaml
- name: Publish Allure report with history
  uses: simple-elf/allure-report-action@master
  if: always()
  with:
    allure_results: allure-results
    allure_history: allure-history
    keep_reports: 20
```
