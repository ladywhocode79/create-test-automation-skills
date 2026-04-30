# Edge-Case Tests — Python / pytest Patterns

## Overview

This guide provides Python/pytest patterns for generating edge-case tests from PRDs. Tests use `pytest.mark.parametrize` for data-driven testing and expose PRD ambiguities through failing assertions.

---

## Pattern 1: Parametrized Input Validation

### Problem

The PRD says "email must be valid" but doesn't define the validation rules. We need parametrized tests to expose this ambiguity.

### Solution

```python
import pytest
from pydantic import ValidationError

class TestEmailValidationEdgeCases:
    """Email validation edge cases expose PRD ambiguity: what is 'valid email'?"""
    
    @pytest.mark.parametrize(
        "email,should_be_valid,scenario",
        [
            # Happy path (PRD clearly specifies these)
            ("user@example.com", True, "standard email"),
            ("user.name@example.com", True, "dot in local part"),
            
            # Ambiguous cases (PRD silent — tests may fail)
            ("user+tag@example.com", True, "plus addressing (ambiguous: allowed?)"),
            ("user@example.co.uk", True, "multi-part TLD (ambiguous: allowed?)"),
            ("user_name@example.com", True, "underscore in local (ambiguous: allowed?)"),
            ("UPPERCASE@EXAMPLE.COM", True, "uppercase (ambiguous: case-insensitive?)"),
            
            # Clear negatives (PRD should reject)
            ("@example.com", False, "missing local part"),
            ("user@", False, "missing domain"),
            ("user", False, "no @ symbol"),
            ("user@@example.com", False, "double @ symbol"),
            ("user @example.com", False, "space in local part"),
        ],
        ids=lambda email, valid, scenario: f"{scenario}",
    )
    @pytest.mark.edge_case
    @pytest.mark.api
    def test_email_validation_edge_cases(self, api_client, email, should_be_valid, scenario):
        """Expose ambiguities in email validation rules."""
        payload = {"username": "testuser", "email": email, "role": "viewer", "password": "SecurePass123!"}
        response = api_client.post("/api/v1/users", payload)
        
        expected_status = 201 if should_be_valid else 400
        assert response.status_code == expected_status, (
            f"Email: {email} | Scenario: {scenario} | "
            f"Expected: {expected_status}, Got: {response.status_code}"
        )
```

**Key points:**
- Use `@pytest.mark.parametrize` for data-driven tests
- Use `ids` parameter for readable test names
- Ambiguous cases have `True` expectation but may fail (exposing the gap)
- `@pytest.mark.edge_case` allows running edge-case tests separately

---

## Pattern 2: Boundary Value Testing

### Problem

PRD says "username must be unique" but doesn't specify min/max length.

### Solution

```python
class TestUsernameLengthBoundaries:
    """Username length boundaries — PRD doesn't specify min/max."""
    
    @pytest.mark.parametrize(
        "username,expected_status,description",
        [
            # Minimum boundary
            ("", 400, "empty string (clearly invalid)"),
            ("a", 400, "1 char (min length ambiguous)"),
            ("ab", 400, "2 chars (min length ambiguous)"),
            ("abc", 201, "3 chars (assumed minimum)"),
            
            # Happy path
            ("testuser", 201, "canonical 8 chars"),
            
            # Maximum boundary
            ("user" * 5, 201, "20 chars (assumed maximum)"),
            ("user" * 5 + "a", 400, "21 chars (max length ambiguous)"),
            ("a" * 256, 400, "256 chars (way over max)"),
            
            # Special cases
            (" username", 400, "leading space"),
            ("username ", 400, "trailing space"),
        ],
    )
    @pytest.mark.edge_case
    @pytest.mark.boundaries
    def test_username_length_boundaries(self, api_client, username, expected_status, description):
        """Test username length boundaries."""
        payload = {
            "username": username,
            "email": f"{username or 'test'}@example.com",
            "role": "viewer",
            "password": "SecurePass123!",
        }
        response = api_client.post("/api/v1/users", payload)
        
        assert response.status_code == expected_status, (
            f"Username length: {len(username)} | {description} | "
            f"Expected: {expected_status}, Got: {response.status_code}"
        )
```

**Key points:**
- Test just below, at, and just above each boundary
- Use reasonable assumptions but mark them as ambiguous
- Parametrize makes it easy to adjust when PRD clarifies

---

## Pattern 3: Concurrency & Race Conditions

### Problem

PRD doesn't specify: if two concurrent requests arrive with the same email, what happens?

### Solution

```python
import asyncio
import concurrent.futures

class TestConcurrencyEdgeCases:
    """Concurrent request handling — race condition behavior undefined."""
    
    @pytest.mark.edge_case
    @pytest.mark.concurrency
    @pytest.mark.asyncio
    async def test_concurrent_user_creation_duplicate_email(self, api_client):
        """Two concurrent POSTs with same email — what's the expected outcome?"""
        payload = {
            "username": "testuser",
            "email": "unique@example.com",
            "role": "viewer",
            "password": "SecurePass123!",
        }
        
        # Fire two concurrent requests
        async def make_request():
            return await api_client.post_async("/api/v1/users", payload)
        
        results = await asyncio.gather(
            make_request(),
            make_request(),
            return_exceptions=True,
        )
        
        statuses = [r.status_code for r in results if not isinstance(r, Exception)]
        
        # One should succeed (201), the other should fail (409)
        # OR both could fail, OR both could succeed (bad!)
        # PRD doesn't specify which is correct
        assert 201 in statuses, "At least one POST should succeed"
        
        # Verify we don't have BOTH succeeding (violates unique constraint)
        assert not (statuses[0] == 201 and statuses[1] == 201), (
            "CORRUPTION: Both concurrent POSTs succeeded! Email is not unique."
        )

    @pytest.mark.edge_case
    @pytest.mark.concurrency
    def test_concurrent_updates_same_user(self, api_client, created_user):
        """Two concurrent PATCH requests on same user — last write wins or conflict?"""
        
        def update_role(role):
            return api_client.patch(
                f"/api/v1/users/{created_user['id']}",
                {"role": role},
            )
        
        # Use ThreadPoolExecutor for concurrent updates
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
            future1 = executor.submit(update_role, "editor")
            future2 = executor.submit(update_role, "admin")
            
            response1 = future1.result()
            response2 = future2.result()
        
        # PRD doesn't specify:
        # Option A: Both succeed, last write wins (last role is admin or editor)
        # Option B: First succeeds, second fails (pessimistic locking)
        # Option C: Both fail (optimistic locking conflict)
        
        assert response1.status_code in (200, 409), f"Unexpected status: {response1.status_code}"
        assert response2.status_code in (200, 409), f"Unexpected status: {response2.status_code}"
```

**Key points:**
- Use `asyncio.gather()` for concurrent async requests
- Use `concurrent.futures.ThreadPoolExecutor` for concurrent sync requests
- Document the ambiguous concurrency behavior

---

## Pattern 4: State Transition Validation

### Problem

PRD says users have roles, but doesn't specify which transitions are valid.

### Solution

```python
class TestRoleTransitionEdgeCases:
    """Role transition rules — PRD doesn't specify which transitions are allowed."""
    
    @pytest.mark.parametrize(
        "initial_role,target_role,expected_status,scenario",
        [
            # Valid transitions (assumed)
            ("viewer", "editor", 200, "viewer → editor (ambiguous: allowed?)"),
            ("editor", "viewer", 200, "editor → viewer (ambiguous: allowed?)"),
            ("admin", "editor", 200, "admin → editor (ambiguous: allowed?)"),
            
            # Self-transition
            ("viewer", "viewer", 200, "viewer → viewer (idempotent)"),
            
            # Invalid roles
            ("viewer", "superuser", 400, "invalid target role"),
            ("viewer", "", 400, "empty role"),
        ],
    )
    @pytest.mark.edge_case
    @pytest.mark.regression
    def test_role_transition_edge_cases(
        self, api_client, initial_role, target_role, expected_status, scenario
    ):
        """Test role transitions."""
        # Create user with initial role
        payload = {
            "username": "testuser",
            "email": "test@example.com",
            "role": initial_role,
            "password": "SecurePass123!",
        }
        create_response = api_client.post("/api/v1/users", payload)
        user_id = create_response.json()["id"]
        
        # Attempt role transition
        patch_response = api_client.patch(
            f"/api/v1/users/{user_id}",
            {"role": target_role},
        )
        
        assert patch_response.status_code == expected_status, (
            f"Transition {initial_role} → {target_role} ({scenario}) | "
            f"Expected: {expected_status}, Got: {patch_response.status_code}"
        )
```

**Key points:**
- Test all valid state transitions
- Test invalid transitions (should return 400 or 403)
- Document ambiguous transitions

---

## Pattern 5: Authorization & Permission Boundaries

### Problem

PRD says "authenticated users can create users" but doesn't specify role-based restrictions.

### Solution

```python
class TestAuthorizationEdgeCases:
    """Authorization boundaries — PRD doesn't specify role-based permissions."""
    
    @pytest.mark.parametrize(
        "caller_role,expected_status,scenario",
        [
            ("viewer", 403, "viewer cannot create users (ambiguous: or can they?)"),
            ("editor", 201, "editor can create users (ambiguous: or admin-only?)"),
            ("admin", 201, "admin can create users (assumed)"),
            (None, 401, "unauthenticated request"),
        ],
    )
    @pytest.mark.edge_case
    @pytest.mark.security
    def test_create_user_permission_by_role(
        self, api_client_factory, caller_role, expected_status, scenario
    ):
        """Test CREATE user permission by role."""
        # Get a client authenticated as a specific role (or None for unauthenticated)
        client = api_client_factory(role=caller_role)
        
        payload = {
            "username": "newuser",
            "email": "new@example.com",
            "role": "viewer",
            "password": "SecurePass123!",
        }
        response = client.post("/api/v1/users", payload)
        
        assert response.status_code == expected_status, (
            f"Create user as {caller_role} ({scenario}) | "
            f"Expected: {expected_status}, Got: {response.status_code}"
        )
```

**Key points:**
- Test each role's ability to perform operations
- Include unauthenticated request (should always return 401)
- Document which permissions are ambiguous

---

## Pattern 6: Error Scenario Coverage

### Problem

PRD doesn't enumerate error codes or specify error response format.

### Solution

```python
class TestErrorScenarios:
    """Error response consistency — PRD doesn't define error codes."""
    
    @pytest.mark.parametrize(
        "payload,expected_status,error_code_hint,scenario",
        [
            (
                {"username": "test", "email": None, "role": "viewer", "password": "pass"},
                400,
                "MISSING_EMAIL",
                "missing email",
            ),
            (
                {"username": "", "email": "test@example.com", "role": "viewer", "password": "pass"},
                400,
                "MISSING_USERNAME",
                "empty username",
            ),
            (
                {"username": "test", "email": "test@example.com", "role": "invalid", "password": "pass"},
                400,
                "INVALID_ROLE",
                "invalid role",
            ),
            (
                {"username": "test", "email": "not-an-email", "role": "viewer", "password": "pass"},
                400,
                "INVALID_EMAIL_FORMAT",
                "malformed email",
            ),
        ],
    )
    @pytest.mark.edge_case
    @pytest.mark.error_handling
    def test_error_response_format(
        self, api_client, payload, expected_status, error_code_hint, scenario
    ):
        """Verify error response format is consistent."""
        response = api_client.post("/api/v1/users", payload)
        
        assert response.status_code == expected_status, f"Scenario: {scenario}"
        
        # All error responses should have a consistent format
        error_json = response.json()
        assert "error" in error_json, f"Missing error code: {scenario}"
        assert error_json["error"], f"Error code is empty: {scenario}"
        
        assert "error_description" in error_json, f"Missing error description: {scenario}"
        assert error_json["error_description"], f"Error description is empty: {scenario}"
        
        assert "request_id" in error_json, f"Missing request ID (for tracing): {scenario}"
        assert error_json["request_id"], f"Request ID is empty: {scenario}"
```

**Key points:**
- Verify error response format is consistent across all errors
- Verify error codes are present (PRD should enumerate them)
- Verify request ID is included for tracing

---

## Pattern 7: Idempotence Testing

### Problem

PRD doesn't specify: is POST idempotent? Can you POST the same request twice?

### Solution

```python
class TestIdempotenceEdgeCases:
    """Idempotence behavior — PRD doesn't specify POST/DELETE outcomes."""
    
    @pytest.mark.edge_case
    @pytest.mark.idempotence
    def test_post_idempotence(self, api_client):
        """Can you create the same user twice?"""
        payload = {
            "username": "testuser",
            "email": "test@example.com",
            "role": "viewer",
            "password": "SecurePass123!",
        }
        
        # First request
        response1 = api_client.post("/api/v1/users", payload)
        assert response1.status_code == 201
        user1 = response1.json()
        user_id_1 = user1["id"]
        
        # Second request with identical payload
        response2 = api_client.post("/api/v1/users", payload)
        
        # PRD doesn't specify expected behavior:
        # Option A: 409 Conflict (email already exists)
        # Option B: 201 Created (create another user — but email is unique! contradiction)
        # Option C: Return existing user (idempotent)
        
        assert response2.status_code in (409, 201), (
            f"Is POST /users idempotent? (ambiguous) | Status: {response2.status_code}"
        )
        
        # If idempotent, IDs should match
        if response2.status_code == 201:
            user2 = response2.json()
            assert user2["id"] == user_id_1, "IDs should match if idempotent"

    @pytest.mark.edge_case
    @pytest.mark.idempotence
    def test_delete_idempotence(self, api_client, created_user):
        """Delete a user, then delete again — what happens?"""
        user_id = created_user["id"]
        
        # First delete
        response1 = api_client.delete(f"/api/v1/users/{user_id}")
        assert response1.status_code == 204
        
        # Second delete (user already deleted)
        response2 = api_client.delete(f"/api/v1/users/{user_id}")
        
        # PRD doesn't specify:
        # Option A: 404 Not Found (resource doesn't exist)
        # Option B: 204 No Content (idempotent delete)
        
        assert response2.status_code in (404, 204), (
            f"Is DELETE idempotent? (ambiguous) | Status: {response2.status_code}"
        )
```

**Key points:**
- Test POST idempotence (usually should return 409, not 201 on duplicate)
- Test DELETE idempotence (usually should return 204, not 404 on re-delete)
- Document the expected behavior

---

## Pattern 8: Pagination Edge Cases

### Problem

PRD says the endpoint supports pagination but doesn't specify edge case behavior.

### Solution

```python
class TestPaginationEdgeCases:
    """Pagination edge cases — PRD undefined for boundary scenarios."""
    
    @pytest.mark.parametrize(
        "page,page_size,expected_status,scenario",
        [
            (1, 20, 200, "first page, default size"),
            (0, 20, 400, "page 0 (invalid; should start at 1)"),
            (-1, 20, 400, "negative page"),
            (1, 0, 400, "page_size 0 (invalid)"),
            (1, -1, 400, "negative page_size"),
            (1, 1000000, 400, "page_size too large (ambiguous: max?)"),
            (100, 20, 200, "page beyond total pages (empty result or 404?)"),
            (1, 1, 200, "page_size 1 (should work)"),
        ],
    )
    @pytest.mark.edge_case
    @pytest.mark.pagination
    def test_pagination_edge_cases(
        self, api_client, page, page_size, expected_status, scenario
    ):
        """Test pagination edge cases."""
        response = api_client.get("/api/v1/users", params={"page": page, "page_size": page_size})
        
        assert response.status_code == expected_status, (
            f"page={page}, page_size={page_size} ({scenario}) | "
            f"Expected: {expected_status}, Got: {response.status_code}"
        )
        
        # If successful, verify response structure
        if expected_status == 200:
            json_data = response.json()
            assert "items" in json_data, "Missing 'items' in response"
            assert isinstance(json_data["items"], list), "'items' should be a list"
            assert "total" in json_data, "Missing 'total' in response"
            assert json_data["total"] >= 0, "'total' should be non-negative"
            assert json_data.get("page") == page, f"'page' should be {page}"
            assert json_data.get("page_size") == page_size, f"'page_size' should be {page_size}"
```

**Key points:**
- Test invalid page/page_size values (should return 400)
- Test pages beyond total (behavior undefined)
- Test very large page_size values (should have a maximum)

---

## Pattern 9: Using pytest Fixtures for Edge Cases

### Problem

How do we set up reusable test data and fixtures for edge-case testing?

### Solution

```python
# conftest.py
import pytest
from api_client import ApiClient

@pytest.fixture
def api_client():
    """API client with authentication."""
    client = ApiClient(base_url="http://localhost:9000")
    client.authenticate()
    return client

@pytest.fixture
def created_user(api_client):
    """Create a user for testing."""
    payload = {
        "username": "testuser",
        "email": f"test-{id(pytest)}@example.com",
        "role": "viewer",
        "password": "SecurePass123!",
    }
    response = api_client.post("/api/v1/users", payload)
    yield response.json()
    # Cleanup (optional)
    api_client.delete(f"/api/v1/users/{response.json()['id']}")

@pytest.fixture(params=["viewer", "editor", "admin"])
def user_with_role(api_client, request):
    """Create a user with each role."""
    role = request.param
    payload = {
        "username": f"user-{role}",
        "email": f"user-{role}@example.com",
        "role": role,
        "password": "SecurePass123!",
    }
    response = api_client.post("/api/v1/users", payload)
    yield response.json()
    api_client.delete(f"/api/v1/users/{response.json()['id']}")

@pytest.fixture
def api_client_factory():
    """Factory to create API clients with different authentication."""
    def _create_client(role=None):
        client = ApiClient(base_url="http://localhost:9000")
        if role:
            client.authenticate_as_role(role)
        return client
    return _create_client


# Test file
class TestEdgeCasesWithFixtures:
    
    @pytest.mark.edge_case
    def test_user_creation_with_fixture(self, api_client, created_user):
        """Use created_user fixture in a test."""
        # created_user is already created
        assert created_user["id"]
        assert created_user["username"]
    
    @pytest.mark.edge_case
    @pytest.mark.parametrize_indirect(["user_with_role"])
    def test_role_permissions(self, user_with_role):
        """Parametrized fixture provides user with each role."""
        assert user_with_role["role"] in ("viewer", "editor", "admin")
```

**Key points:**
- Use fixtures for reusable test setup
- Use `request.param` for parametrized fixtures
- Use cleanup (yield) for teardown
- Use `api_client_factory` for dynamic client creation

---

## Pattern 10: Pytest Markers for Edge-Case Organization

### Problem

How do we organize and run edge-case tests separately?

### Solution

```python
# pytest.ini
[pytest]
markers =
    edge_case: mark test as an edge-case test (deselect with '-m "not edge_case"')
    validation: input validation edge cases
    boundaries: boundary value testing
    concurrency: concurrency and race condition tests
    security: authorization and security edge cases
    error_handling: error scenario coverage
    idempotence: idempotence testing
    pagination: pagination edge cases
    api: API tests
    regression: regression tests
    wip: work in progress

# test_*.py
class TestValidationEdgeCases:
    @pytest.mark.edge_case
    @pytest.mark.validation
    def test_email_validation(...): ...
    
    @pytest.mark.edge_case
    @pytest.mark.validation
    def test_username_validation(...): ...


class TestConcurrencyEdgeCases:
    @pytest.mark.edge_case
    @pytest.mark.concurrency
    def test_concurrent_creation(...): ...
```

### Running tests:

```bash
# Run all edge-case tests
pytest -m edge_case

# Run only validation edge cases
pytest -m "edge_case and validation"

# Run all tests except edge cases
pytest -m "not edge_case"

# Run edge cases + regression (exclude WIP)
pytest -m "edge_case or regression" -m "not wip"

# Verbose output with test collection
pytest -m edge_case -v --collect-only
```

---

## Template: Creating a New Edge-Case Test

```python
import pytest

class TestFeatureEdgeCases:
    """[ Feature Name ] — [ Ambiguity or Edge Case ]."""
    
    @pytest.mark.parametrize(
        "param1,param2,expected_status,scenario",
        [
            (value1, value2, 201, "happy path"),
            (value1, value2, 400, "edge case (ambiguous: ?)"),
        ],
    )
    @pytest.mark.edge_case
    @pytest.mark.[ category ]
    def test_[ feature_name ]_[ edge_case ](
        self, api_client, param1, param2, expected_status, scenario
    ):
        """[ What is ambiguous or edge-casey? ]"""
        # Setup
        payload = {...}
        
        # Exercise
        response = api_client.post("/api/v1/...", payload)
        
        # Assert
        assert response.status_code == expected_status, (
            f"Scenario: {scenario} | Expected: {expected_status}, Got: {response.status_code}"
        )
```

---

## Key Takeaway

**Edge-case tests FAIL by design.** They expose gaps in the PRD. Once the PRD is clarified, update test expectations and code, and tests will pass. This is the purpose: use test failures to drive PRD clarification *before* building the code.

---

## Pytest Configuration Tips

```bash
# Run with verbose output
pytest -v

# Show print statements
pytest -s

# Stop on first failure
pytest -x

# Show slowest tests
pytest --durations=10

# Generate HTML report
pytest --html=report.html

# Run with coverage
pytest --cov=src --cov-report=html
```
