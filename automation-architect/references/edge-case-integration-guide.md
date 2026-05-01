# Edge-Case Integration Guide

## Purpose

This guide explains how edge-case tests are **integrated into the scaffold** for each language track (Python, Java) and how they relate to PRD analysis.

---

## Overview

When you generate a scaffold using automation-architect:

1. **Round -1 (PRD Intake)** → Extract PRD, identify ambiguities
2. **Round 0 (PRD Analysis)** → Identify edge cases, recommend test type
3. **Rounds 1-3 (Language, Config, Common)** → Standard interview
4. **Phase 2 (Scaffold Generation)** → Generate files including edge-case tests
5. **Phase 3 (Output)** → Write files to disk

The key: **Phase 2 generates edge-case test templates based on the PRD ambiguities found in Round 0.**

---

## Scaffold File Structure (with Edge Cases)

### Standard Scaffold + Edge Cases

```
my-test-suite/
├── README.md                          # Tech stack, setup, edge-case test group
├── EDGE_CASES.md                      # [NEW] PRD ambiguities → test mapping
├── PRD_CLARIFICATION_CHECKLIST.md     # [NEW] P0 ambiguities requiring PRD updates
├── src/
│   ├── conftest.py                    # (Python) or pom.xml (Java)
│   ├── layers/
│   │   ├── layer1_models/
│   │   │   ├── user_model.py
│   │   │   └── user_edge_case_models.py   # [NEW] Models for edge-case data
│   │   ├── layer2_client/
│   │   ├── layer3_services/
│   │   │   └── user_service.py
│   │   └── layer4_tests/
│   │       ├── api/
│   │       │   ├── test_user_create_happy_path.py
│   │       │   └── test_user_email_validation_edge_cases.py   # [NEW]
│   │       │   └── test_user_role_validation_edge_cases.py    # [NEW]
│   │       │   └── test_user_delete_cascading_edge_cases.py   # [NEW]
│   │       └── ui/
│   │           └── test_login_flow_edge_cases.py              # [NEW]
│   └── fixtures/
│       └── edge_case_data.py           # [NEW] Centralized edge-case data providers
├── .env.sample
├── docker-compose.yml                 # (if mock selected)
└── prd_reference.md                   # Link to original PRD (if provided)
```

---

## Edge-Case Test Files: What's Generated

### 1. EDGE_CASES.md

This file documents the mapping from PRD ambiguities → test cases.

**Example:**

```markdown
# Edge Cases from PRD Analysis

## Summary
PRD: User Management API v1.0
Ambiguities Identified: 12
Edge-Case Tests Generated: 15

---

## P0 (Critical) — Must Clarify Before Development

### 1. Email Validation Rules
**Ambiguity:** PRD says "valid email" but no RFC definition or regex provided

**PRD Gap:**
- Does "user+tag@example.com" pass? (plus addressing)
- Is "USER@EXAMPLE.COM" == "user@example.com"? (case sensitivity)
- Is "user@localhost" allowed? (localhost without TLD)

**Edge-Case Tests Generated:**
```python
@pytest.mark.edge_case
@pytest.mark.email_validation
@pytest.mark.parametrize("email,expected_status,scenario", [
    ("user@example.com", 201, "valid canonical"),
    ("user+tag@example.com", ???, "plus addressing — AMBIGUOUS"),
    ("USER@EXAMPLE.COM", ???, "case sensitivity — AMBIGUOUS"),
    ("user@localhost", ???, "localhost without TLD — AMBIGUOUS"),
    ("@example.com", 400, "missing local part"),
    ("user@domain..com", 400, "double dot"),
])
def test_email_validation_edge_cases(api_client, email, expected_status, scenario):
    """Exposes email validation gaps."""
    response = api_client.post("/users", {"email": email, ...})
    assert response.status_code == expected_status, f"Failed: {scenario}"
```

**Test Outcome:**
If code rejects "user+tag@example.com", the test fails and the scenario is exposed.
**Action:** PRD must clarify email validation rules.

---

### 2. Duplicate Email Handling
**Ambiguity:** What happens when user tries to create account with existing email?

**PRD Gap:**
- 409 Conflict? (user already exists)
- 201 Created? (idempotent — unusual for POST)
- 400 Bad Request? (validation failure)

**Edge-Case Tests Generated:**
```python
@pytest.mark.edge_case
@pytest.mark.concurrency
def test_duplicate_email_conflict(api_client):
    """Exposes behavior for duplicate email in conflict scenario."""
    # Create first user
    response1 = api_client.post("/users", {"email": "dup@example.com", ...})
    assert response1.status_code == 201
    
    # Try creating second user with same email
    response2 = api_client.post("/users", {"email": "dup@example.com", ...})
    # Test expects 409, but what does code do?
    assert response2.status_code in [409, 400, 201]  # ambiguous
```

**Test Outcome:**
Once PRD clarifies the behavior, update test assertion to be specific.

---

### 3. Authorization Rules
**Ambiguity:** Who can create users? Only admin? Any authenticated user?

**PRD Gap:**
- Can viewers create users?
- Can editors create users?
- Can only admins create users?
- Can user create other users, or only themselves?

**Edge-Case Tests Generated:**
```python
@pytest.mark.edge_case
@pytest.mark.authorization
@pytest.mark.parametrize("role,should_succeed", [
    ("admin", True),
    ("editor", ???),     # ambiguous
    ("viewer", ???),     # ambiguous
])
def test_create_user_authorization(api_client, role, should_succeed):
    """Exposes authorization rules."""
    token = auth.generate_token(role=role)
    response = api_client.post("/users", {...}, headers={"Authorization": f"Bearer {token}"})
    expected = 201 if should_succeed else 403
    assert response.status_code == expected
```

**Test Outcome:**
Failures expose the authorization gap. PRD must define permission model.

---

## P1 (High) — Affects Coverage, Nice to Clarify Early

### 4. Username Length Boundaries
**Ambiguity:** No min/max length specified

**Edge-Case Tests Generated:**
```python
@pytest.mark.edge_case
@pytest.mark.input_validation
@pytest.mark.parametrize("username,expected_status", [
    ("a", 400),              # too short (min unknown)
    ("ab", 400),             # too short (min unknown)
    ("valid_user", 201),     # canonical
    ("a" * 256, 400),        # too long (max unknown)
])
def test_username_length_edge_cases(api_client, username, expected_status):
    """Exposes username length constraints."""
    response = api_client.post("/users", {"username": username, ...})
    assert response.status_code == expected_status
```

**Test Outcome:**
Once PRD specifies "3-20 characters", update test expectations.

---

## P2 (Medium) — Nice to Have, Lower Priority

### 5. Pagination Edge Cases
**Ambiguity:** What if page > total pages? What if page_size=0?

**Edge-Case Tests Generated:**
```python
@pytest.mark.edge_case
@pytest.mark.pagination
@pytest.mark.parametrize("page,page_size,expected_status", [
    (0, 20, 400),           # invalid page
    (999, 20, 200),         # beyond max pages (returns empty? error?)
    (1, 0, 400),            # invalid page size
    (1, 1000000, 400),      # max page size exceeded
])
def test_pagination_edge_cases(api_client, page, page_size, expected_status):
    """Exposes pagination behavior."""
    response = api_client.get(f"/users?page={page}&page_size={page_size}")
    assert response.status_code == expected_status
```

---

## Test Execution

### Run All Tests
```bash
pytest
```

### Run Only Edge-Case Tests
```bash
pytest -m edge_case
```

### Run Only P0 (Critical) Edge Cases
```bash
pytest -m "edge_case and p0"
```

### Run Only Email Validation Edge Cases
```bash
pytest -m "edge_case and email_validation"
```

---

## Workflow: Using Edge-Case Tests to Clarify PRD

1. **Generate scaffold** with edge-case tests from PRD analysis
2. **Run edge-case tests** → Many fail (expected, exposing gaps)
3. **Review failures** → Read the `EDGE_CASES.md` to understand the ambiguity
4. **Update PRD** with clarifications (e.g., "email must be valid RFC 5322 + support plus addressing")
5. **Update test expectations** based on new PRD
6. **Re-run tests** → More pass as PRD is clarified
7. **Repeat** until all P0 tests pass (PRD is no longer ambiguous)
8. **Begin development** with high confidence (tests are aligned with PRD)

---

## Template: Edge-Case Test Structure

All edge-case tests follow this structure:

### Python/pytest

```python
# tests/api/test_resource_edge_cases.py

import pytest
from src.layers.layer1_models import ResourceModel, ResourceEdgeCaseModels
from src.layers.layer2_client import APIClient
from src.layers.layer3_services import ResourceService

class TestResourceEdgeCases:
    """Edge-case tests exposing PRD ambiguities."""
    
    @pytest.mark.edge_case
    @pytest.mark.p0_critical
    @pytest.mark.resource_validation
    @pytest.mark.parametrize("invalid_field,expected_error", [
        ("empty_name", "name is required"),
        ("special_chars_in_name", "name contains invalid characters"),  # ambiguous
        ("null_role", "role is required"),
    ])
    def test_create_resource_validation_edge_cases(
        self, api_client: APIClient, invalid_field, expected_error
    ):
        """Exposes validation rule gaps."""
        payload = ResourceEdgeCaseModels.build_invalid(**{invalid_field: True})
        response = api_client.post("/resources", payload)
        
        # Test expects 400 Bad Request, but implementation might differ
        assert response.status_code == 400, f"Failed: {expected_error}"
        assert expected_error in response.json()["message"]
    
    @pytest.mark.edge_case
    @pytest.mark.p1_high
    @pytest.mark.concurrency
    def test_concurrent_create_same_resource(self, api_client: APIClient):
        """Exposes concurrency behavior (race condition)."""
        from concurrent.futures import ThreadPoolExecutor
        
        payload = {"name": "duplicate", ...}
        
        with ThreadPoolExecutor(max_workers=2) as executor:
            results = list(executor.map(
                lambda _: api_client.post("/resources", payload),
                range(2)
            ))
        
        # Both might succeed? One might fail? Ambiguous behavior.
        status_codes = [r.status_code for r in results]
        # Assert some behavior (currently ambiguous)
        assert any(status == 409 for status in status_codes) or \
               all(status == 201 for status in status_codes)
```

### Java/TestNG

```java
// src/test/java/com/sdet/api/ResourceEdgeCasesTest.java

import org.testng.annotations.*;
import static org.assertj.core.api.Assertions.*;

public class ResourceEdgeCasesTest {
    private ResourceService resourceService;
    private AuthClient authClient;
    
    @BeforeClass
    public void setUp() {
        resourceService = new ResourceService();
        authClient = new AuthClient();
    }
    
    @Test(groups = {"edge-cases", "p0-critical"}, 
          dataProvider = "invalidNameEdgeCases")
    public void testCreateResourceNameValidationEdgeCases(
            String name, int expectedStatus, String scenario) {
        /**
         * Edge case: PRD says "name is required" but no length/format rules
         * This test exposes the gap.
         */
        CreateResourceRequest request = ResourceFactory.buildWithName(name);
        Response response = resourceService.createResource(request);
        
        assertThat(response.statusCode())
            .as("Scenario: %s", scenario)
            .isEqualTo(expectedStatus);
    }
    
    @DataProvider(name = "invalidNameEdgeCases")
    public Object[][] invalidNameEdgeCases() {
        return new Object[][] {
            {"", 400, "empty name"},
            {"a", 400, "single character (min ambiguous)"},
            {"valid-name", 201, "canonical"},
            {"".repeat(256), 400, "very long (max ambiguous)"},
        };
    }
}
```

---

## Files Generated for Edge Cases

| File | Purpose | Language |
|------|---------|----------|
| `EDGE_CASES.md` | Maps PRD ambiguities → edge-case tests | N/A |
| `PRD_CLARIFICATION_CHECKLIST.md` | P0 ambiguities requiring PRD updates | N/A |
| `src/layers/layer1_models/resource_edge_case_models.py` | Edge-case data builders | Python |
| `src/fixtures/edge_case_data.py` | Parametrized data providers | Python |
| `tests/api/test_resource_validation_edge_cases.py` | Validation edge-case tests | Python |
| `tests/api/test_resource_concurrency_edge_cases.py` | Concurrency/race condition tests | Python |
| `tests/api/test_resource_error_handling_edge_cases.py` | Error path edge-case tests | Python |
| `src/main/java/.../EdgeCaseDataProviders.java` | @DataProvider methods | Java |
| `src/test/java/.../ResourceEdgeCasesTest.java` | Parametrized TestNG tests | Java |
| `src/test/java/.../ConcurrencyEdgeCasesTest.java` | Race condition tests | Java |

---

## Checklist: Edge-Case Integration

- [ ] PRD analyzed in Round -1 (PRD Intake)
- [ ] Ambiguities identified using edge-case-checklist.md
- [ ] Ambiguities prioritized (P0/P1/P2)
- [ ] Test type confirmed in Round 0
- [ ] Edge-case test files generated for each priority level
- [ ] EDGE_CASES.md documents all ambiguities and test mappings
- [ ] PRD_CLARIFICATION_CHECKLIST.md lists P0 items
- [ ] Edge-case tests are parametrized with data providers
- [ ] Tests include comments explaining the ambiguity being exposed
- [ ] README.md mentions edge-case test group and how to run them
- [ ] Team can run `pytest -m edge_case` to isolate edge-case tests
- [ ] Failures are actionable (clearly show what PRD clarification is needed)

---

## Next Steps

1. **Generate scaffold** → Includes edge-case tests
2. **Run edge-case tests** → Failures expose PRD gaps
3. **Use failures** as input for PRD clarification discussions
4. **Update PRD** → Add missing specifications
5. **Update test expectations** → Now that PRD is clarified
6. **Re-run tests** → Should pass (or identify new edge cases)
7. **Iterate** → PRD becomes precise, tests become comprehensive
8. **Begin development** → With high-confidence requirements

---

## References

- `prd-analysis-guide.md` — How to analyze PRD and identify ambiguities
- `edge-case-checklist.md` — 10 categories for identifying gaps
- `sample-prd-user-management.md` — Example PRD with 19 ambiguities
