---
name: automation-architect-python
description: >
  Python/Pytest automation track for the automation-architect skill suite.
  Invoked by the automation-architect orchestrator when the user selects
  Python as their language track. Provides 4-layer scaffold using Pytest,
  Pydantic v2, requests (API), Playwright (UI), and Allure/ReportPortal.
  Not user-invocable directly.
user-invocable: false
version: 2.0.0
tools: Read, Write
---

# Python Track — automation-architect

This skill is invoked by the automation-architect orchestrator after the user
selects Python. It reads the appropriate profile references based on the
resolved `test_type` and generates all scaffold files.

## Profile Loading Rules

Load references based on resolved test_type:

| test_type  | Load                                          |
|------------|-----------------------------------------------|
| API        | references/api/* + references/shared/*        |
| UI         | references/ui/* + references/shared/*         |
| Full-Stack | references/api/* + references/ui/* + references/shared/* |

Always load references/shared/* regardless of test_type.

## Python Stack Decisions

| Concern            | Library               | Version  | Reason                          |
|--------------------|-----------------------|----------|---------------------------------|
| HTTP client        | requests              | >=2.31   | Universal, well-understood      |
| API models         | pydantic              | >=2.0    | v2 is ~2x faster, field_validator |
| Environment config | pydantic-settings     | >=2.0    | Same ecosystem as models        |
| UI automation      | playwright            | >=1.44   | Built-in waits, trace viewer    |
| Test runner        | pytest                | >=8.0    | Industry standard, rich plugins |
| Test data (Faker)  | faker                 | >=24.0   | Locale-aware, extensive providers |
| Reporting          | allure-pytest         | >=2.13   | (if allure selected)            |
| Reporting          | pytest-reportportal   | >=5.4    | (if ReportPortal selected)      |
| Reporting          | pytest-html           | >=4.1    | (if HTML selected)              |
| HTTP retry         | urllib3               | >=2.0    | Bundled with requests           |
| Import linting     | import-linter         | >=2.0    | Enforces layer boundaries in CI |
| Parallel exec      | pytest-xdist          | >=3.5    | Optional, offer if user asks    |

## File Generation Responsibilities

When invoked, generate these files in order:

### Always (all test_types)
1. `requirements.txt`
2. `pytest.ini`
3. `.importlinter`
4. `.env.example`
5. `docker-compose.yml` (if mock selected)
6. `config/env_config.py`
7. `config/logger.py`
8. `conftest.py`

### API profile
9.  `layer_1_models/api/user_model.py`
10. `layer_1_models/api/factories/user_factory.py`
11. `layer_2_clients/api/base_api_client.py`
12. `layer_3_services/user_service.py`
13. `layer_4_tests/api/test_user_api.py`
14. `config/auth_manager.py` (if auth != none)
15. `mocks/wiremock_lifecycle.py` (if mock selected)
16. `mocks/stubs/user_stubs.json` (if mock selected)
17. `mocks/stubs/auth_stubs.json` (if auth + mock selected)

### UI profile
18. `layer_1_models/ui/locators/login_locators.py`
19. `layer_1_models/ui/form_data/login_form_data.py`
20. `layer_2_clients/ui/browser_session.py`
21. `layer_3_pages/login_page.py`
22. `layer_3_pages/dashboard_page.py`
23. `layer_3_pages/components/header_component.py`
24. `layer_4_tests/ui/test_login_flow.py`
25. `config/driver_manager.py`

### CI files
26. `.github/workflows/api-tests.yml` (if test_type includes API)
27. `.github/workflows/ui-tests.yml` (if test_type includes UI)
(Replace with GitLab/Jenkins/Azure equivalents based on resolved ci_platform)

## Code Style Rules for All Generated Python Files

- Type hints on all function signatures (parameters + return types)
- Pydantic v2 syntax: `model_dump()` not `dict()`, `field_validator` not `validator`
- f-strings only (no % formatting or .format())
- No `print()` statements — use the structured logger
- Class names: PascalCase. Method names: snake_case. Constants: UPPER_SNAKE
- Import order: stdlib → third-party → local (isort convention)
- All test methods start with `test_`
- All test classes start with `Test`
- No bare `except:` clauses — always catch specific exceptions

## Resource Naming

The scaffold uses "user" as the example resource domain throughout.
After generating, always tell the user:

"The scaffold uses 'user' as the example resource. To add a new resource
(e.g., 'order'), duplicate the model, factory, service, and test files and
replace 'user' with your resource name. The structure is identical for
every resource domain."
