# Edge-Case Tests — Java / TestNG Patterns

## Overview

This guide provides Java/TestNG patterns for generating edge-case tests that expose PRD ambiguities. Tests are parametrized (data-driven) and designed to fail when the PRD is unclear, then pass when requirements are clarified.

---

## Pattern 1: Parametrized Input Validation

### Problem

The PRD says "email must be valid" but doesn't define what "valid" means. We need to test multiple email formats and expose the ambiguity.

### Solution

```java
@Test(
    dataProvider = "emailEdgeCases",
    groups = {"edge-cases", "api"}
)
@Description("Email validation edge cases expose PRD ambiguity: what is 'valid email'?")
public void testEmailValidationEdgeCases(
    String email, 
    boolean shouldBeValid, 
    String scenario) {
    
    CreateUserRequest payload = UserFactory.buildWithEmail(email);
    Response response = userService.createUser(payload);
    
    // Test assertion reflects the ambiguity — both outcomes are possible
    // until PRD clarifies email validation rules
    int expectedStatus = shouldBeValid ? 201 : 400;
    assertThat(response.statusCode())
        .as("Email: %s | Scenario: %s", email, scenario)
        .isEqualTo(expectedStatus);
}

@DataProvider(name = "emailEdgeCases")
public Object[][] emailEdgeCases() {
    return new Object[][] {
        // Happy path (PRD clearly specifies these as valid)
        {"user@example.com", true, "standard email"},
        {"user.name@example.com", true, "dot in local part"},
        
        // Ambiguous cases (PRD silent on these — tests may fail)
        {"user+tag@example.com", true, "plus addressing (ambiguous: allowed?)"},
        {"user@example.co.uk", true, "multi-part TLD (ambiguous: allowed?)"},
        {"user_name@example.com", true, "underscore in local (ambiguous: allowed?)"},
        {"UPPERCASE@EXAMPLE.COM", true, "uppercase (ambiguous: case-insensitive?)"},
        
        // Clear negatives (PRD should reject these)
        {"@example.com", false, "missing local part"},
        {"user@", false, "missing domain"},
        {"user", false, "no @ symbol"},
        {"user@@example.com", false, "double @ symbol"},
        {"user @example.com", false, "space in local part"},
    };
}
```

**Key points:**
- **Ambiguous cases** have `true` expectation but may fail if code rejects them (exposing the gap)
- **Clear negatives** have `false` expectation (PRD unambiguous on these)
- **Test failure = PRD gap found** — use failure to create clarification ticket

---

## Pattern 2: Boundary Value Testing

### Problem

PRD says "username must be unique" but doesn't specify min/max length. We need to test the boundaries.

### Solution

```java
@Test(
    dataProvider = "usernameLength",
    groups = {"edge-cases", "api", "regression"}
)
@Description("Username length boundaries — PRD doesn't specify min/max")
public void testUsernameLengthBoundaries(
    String username, 
    int expectedStatus, 
    String description) {
    
    CreateUserRequest payload = UserFactory.buildWithUsername(username);
    Response response = userService.createUser(payload);
    
    assertThat(response.statusCode())
        .as("Username: '%s' (%d chars) | %s", 
            username.length() > 20 ? username.substring(0, 20) + "..." : username,
            username.length(),
            description)
        .isEqualTo(expectedStatus);
}

@DataProvider(name = "usernameLength")
public Object[][] usernameLength() {
    return new Object[][] {
        // Minimum boundary testing
        {"", 400, "empty string (clearly invalid)"},
        {"a", 400, "1 char (min length ambiguous)"},
        {"ab", 400, "2 chars (min length ambiguous)"},
        {"abc", 201, "3 chars (assumed minimum)"},
        
        // Happy path
        {"testuser", 201, "canonical 8 chars"},
        
        // Maximum boundary testing
        {"user".repeat(5), 201, "20 chars (assumed maximum)"},
        {"user".repeat(5) + "a", 400, "21 chars (max length ambiguous)"},
        {"a".repeat(256), 400, "256 chars (way over max)"},
        
        // Special cases
        {" username", 400, "leading space"},
        {"username ", 400, "trailing space"},
    };
}
```

**Key points:**
- Test **just below, at, and just above** each boundary
- Use reasonable assumptions (e.g., min 3, max 20) but mark them as ambiguous
- Parametrized provider makes it easy to adjust when PRD clarifies

---

## Pattern 3: Concurrency & Race Conditions

### Problem

PRD doesn't specify: if two requests arrive simultaneously with the same email, what should happen?

### Solution

```java
@Test(
    groups = {"edge-cases", "concurrency"},
    timeOut = 10000
)
@Description("Concurrent POST with duplicate email — race condition behavior undefined")
public void testConcurrentUserCreationWithDuplicateEmail() throws Exception {
    CreateUserRequest payload = UserFactory.build();
    
    // Fire two concurrent requests with the same email
    ExecutorService executor = Executors.newFixedThreadPool(2);
    Future<Response> request1 = executor.submit(() -> userService.createUser(payload));
    Future<Response> request2 = executor.submit(() -> userService.createUser(payload));
    
    Response resp1 = request1.get();
    Response resp2 = request2.get();
    
    executor.shutdown();
    
    // One should succeed (201), the other should fail (409)
    // OR both could fail, OR both could succeed (bad!)
    // PRD doesn't specify which is correct
    List<Integer> statuses = Arrays.asList(resp1.statusCode(), resp2.statusCode());
    
    // Test expects one success, one failure (optimistic locking/uniqueness)
    assertThat(statuses)
        .as("Race condition: two concurrent POSTs with same email")
        .contains(201, 409);
    
    // Verify that we don't have BOTH succeeding (would violate unique constraint)
    assertThat(statuses)
        .as("FAILURE: Both requests succeeded! Email is not unique (corruption).")
        .doesNotEqual(Arrays.asList(201, 201));
}
```

**Key points:**
- Use `ExecutorService` to fire concurrent requests
- Test both expected behavior AND failure scenarios
- Document the expected concurrency behavior

---

## Pattern 4: State Transition Validation

### Problem

PRD says users have roles, but doesn't specify which role transitions are valid.

### Solution

```java
@Test(
    dataProvider = "roleTransitions",
    groups = {"edge-cases", "regression"}
)
@Description("Role transition rules — PRD doesn't specify which transitions are allowed")
public void testRoleTransitionEdgeCases(
    String initialRole,
    String targetRole,
    int expectedStatus,
    String scenario) {
    
    // Create user with initial role
    CreateUserRequest createPayload = UserFactory.build(initialRole);
    UserResponse user = userService.createUser(createPayload);
    
    // Attempt role transition via PATCH
    Response patchResponse = userService.updateUserRole(user.id(), targetRole);
    
    assertThat(patchResponse.statusCode())
        .as("Transition %s → %s (%s)", initialRole, targetRole, scenario)
        .isEqualTo(expectedStatus);
}

@DataProvider(name = "roleTransitions")
public Object[][] roleTransitions() {
    return new Object[][] {
        // Valid transitions (assumed)
        {"viewer", "editor", 200, "viewer → editor (ambiguous: allowed?)"},
        {"editor", "viewer", 200, "editor → viewer (ambiguous: allowed?)"},
        {"admin", "editor", 200, "admin → editor (ambiguous: allowed?)"},
        
        // Self-transition
        {"viewer", "viewer", 200, "viewer → viewer (idempotent)"},
        
        // Invalid roles
        {"viewer", "superuser", 400, "invalid target role"},
        
        // Invalid target role (empty string, null if possible)
        {"viewer", "", 400, "empty role"},
    };
}
```

**Key points:**
- Test all valid state transitions
- Test invalid transitions (should fail with 400 or 403)
- Document which transitions are ambiguous

---

## Pattern 5: Authorization & Permission Boundaries

### Problem

PRD says "authenticated users can create users" but doesn't specify role-based restrictions.

### Solution

```java
@Test(
    dataProvider = "rolePermissions",
    groups = {"edge-cases", "security"}
)
@Description("CREATE user permission by role — PRD doesn't specify who can create users")
public void testCreateUserPermissionByRole(
    String callerRole,
    int expectedStatus,
    String scenario) {
    
    // Create a client authenticated as a specific role
    BaseApiClient clientAsRole = ClientFactory.buildWithRole(callerRole);
    CreateUserRequest payload = UserFactory.build();
    
    Response response = clientAsRole.post("/api/v1/users", payload);
    
    assertThat(response.statusCode())
        .as("Create user as %s (%s)", callerRole, scenario)
        .isEqualTo(expectedStatus);
}

@DataProvider(name = "rolePermissions")
public Object[][] rolePermissions() {
    return new Object[][] {
        {"viewer", 403, "viewer cannot create users (ambiguous: or can they?)"},
        {"editor", 201, "editor can create users (ambiguous: or admin-only?)"},
        {"admin", 201, "admin can create users (assumed)"},
        {null, 401, "unauthenticated request"},
    };
}
```

**Key points:**
- Test each role's ability to perform the operation
- Include unauthenticated request (should always return 401)
- Document which permissions are ambiguous

---

## Pattern 6: Error Scenario Coverage

### Problem

PRD doesn't enumerate error codes or specify error response format precisely.

### Solution

```java
@Test(
    dataProvider = "errorScenarios",
    groups = {"edge-cases", "error-handling"}
)
@Description("Error response consistency — PRD doesn't define error codes")
public void testErrorResponseFormat(
    CreateUserRequest payload,
    int expectedStatus,
    String errorCodeHint,
    String scenario) {
    
    Response response = userService.createUser(payload);
    
    assertThat(response.statusCode())
        .as("Scenario: %s", scenario)
        .isEqualTo(expectedStatus);
    
    // All error responses should have a consistent format
    if (expectedStatus >= 400) {
        assertThat(response.jsonPath().getString("error"))
            .as("Error code for: %s", scenario)
            .isNotBlank();
        
        assertThat(response.jsonPath().getString("error_description"))
            .as("Error description for: %s", scenario)
            .isNotBlank();
        
        assertThat(response.jsonPath().getString("request_id"))
            .as("Request ID for tracing: %s", scenario)
            .isNotBlank();
    }
}

@DataProvider(name = "errorScenarios")
public Object[][] errorScenarios() {
    return new Object[][] {
        {
            UserFactory.buildWithEmail(null),
            400,
            "MISSING_EMAIL",
            "missing email"
        },
        {
            UserFactory.buildWithUsername(""),
            400,
            "MISSING_USERNAME",
            "empty username"
        },
        {
            UserFactory.buildWithRole("invalid"),
            400,
            "INVALID_ROLE",
            "invalid role"
        },
        {
            UserFactory.buildWithEmail("not-an-email"),
            400,
            "INVALID_EMAIL_FORMAT",
            "malformed email"
        },
    };
}
```

**Key points:**
- Verify error response format is consistent
- Verify error codes are present (PRD should enumerate them)
- Verify request ID is included for tracing

---

## Pattern 7: Idempotence Testing

### Problem

PRD doesn't specify: is POST idempotent? Can you POST the same request twice?

### Solution

```java
@Test(
    groups = {"edge-cases", "idempotence"}
)
@Description("POST idempotence — can you create the same user twice?")
public void testPostIdempotence() {
    CreateUserRequest payload = UserFactory.build();
    
    // First request
    Response response1 = userService.createUser(payload);
    assertThat(response1.statusCode()).isEqualTo(201);
    UserResponse user1 = response1.as(UserResponse.class);
    
    // Second request with identical payload
    Response response2 = userService.createUser(payload);
    
    // PRD doesn't specify expected behavior:
    // Option A: 409 Conflict (email already exists)
    // Option B: 201 Created (create another user — but email is unique! contradiction)
    // Option C: Return existing user (idempotent)
    
    // Test documents the ambiguity
    assertThat(response2.statusCode())
        .as("Is POST /users idempotent? (ambiguous)")
        .isIn(409, 201);  // Both are possible depending on interpretation
    
    if (response2.statusCode() == 201) {
        UserResponse user2 = response2.as(UserResponse.class);
        assertThat(user2.id())
            .as("IDs should match if idempotent")
            .isEqualTo(user1.id());
    }
}

@Test(
    groups = {"edge-cases", "idempotence"}
)
@Description("DELETE idempotence — delete a user, then delete again")
public void testDeleteIdempotence() {
    UserResponse user = userService.createUser(UserFactory.build());
    
    // First delete
    Response response1 = userService.deleteUser(user.id());
    assertThat(response1.statusCode()).isEqualTo(204);
    
    // Second delete (user already deleted)
    Response response2 = userService.deleteUser(user.id());
    
    // PRD doesn't specify:
    // Option A: 404 Not Found (resource doesn't exist)
    // Option B: 204 No Content (idempotent delete)
    
    assertThat(response2.statusCode())
        .as("Is DELETE idempotent? (ambiguous)")
        .isIn(404, 204);
}
```

**Key points:**
- Test POST idempotence (usually should be 409, not 201)
- Test DELETE idempotence (usually should be 204, not 404)
- Document the expected behavior

---

## Pattern 8: Pagination Edge Cases

### Problem

PRD says the endpoint supports pagination but doesn't specify edge case behavior.

### Solution

```java
@Test(
    dataProvider = "paginationEdgeCases",
    groups = {"edge-cases", "pagination"}
)
@Description("Pagination edge cases — PRD undefined for boundary scenarios")
public void testPaginationEdgeCases(
    int page,
    int pageSize,
    int expectedStatus,
    String scenario) {
    
    Response response = userService.listUsers(page, pageSize);
    
    assertThat(response.statusCode())
        .as("page=%d, page_size=%d (%s)", page, pageSize, scenario)
        .isEqualTo(expectedStatus);
    
    // If successful, verify response structure
    if (expectedStatus == 200) {
        assertThat(response.jsonPath().getList("items")).isNotNull();
        assertThat(response.jsonPath().getInt("total")).isGreaterThanOrEqualTo(0);
        assertThat(response.jsonPath().getInt("page")).isEqualTo(page);
        assertThat(response.jsonPath().getInt("page_size")).isEqualTo(pageSize);
    }
}

@DataProvider(name = "paginationEdgeCases")
public Object[][] paginationEdgeCases() {
    return new Object[][] {
        {1, 20, 200, "first page, default size"},
        {0, 20, 400, "page 0 (invalid; should start at 1)"},
        {-1, 20, 400, "negative page"},
        {1, 0, 400, "page_size 0 (invalid)"},
        {1, -1, 400, "negative page_size"},
        {1, 1000000, 400, "page_size too large (ambiguous: max?)"},
        {100, 20, 200, "page beyond total pages (empty result or 404?)"},
        {1, 1, 200, "page_size 1 (should work)"},
    };
}
```

**Key points:**
- Test invalid page/page_size values (should return 400)
- Test pages beyond total (behavior undefined)
- Test very large page_size values (should have a maximum)

---

## Pattern 9: Timestamp & Time Zone Handling

### Problem

PRD specifies timestamps but doesn't mention time zones, DST, or leap seconds.

### Solution

```java
@Test(
    dataProvider = "timestampEdgeCases",
    groups = {"edge-cases", "timestamp"}
)
@Description("Timestamp handling — timezone and DST behavior undefined")
public void testTimestampEdgeCases(
    ZonedDateTime timestamp,
    String scenario) {
    
    // Create user with a specific created_at (if mocked)
    CreateUserRequest payload = UserFactory.buildWithTimestamp(timestamp);
    Response response = userService.createUser(payload);
    
    // Verify timestamp is stored correctly
    UserResponse user = response.as(UserResponse.class);
    
    // Check if timestamp is preserved or normalized to UTC
    assertThat(user.createdAt())
        .as("Timestamp handling: %s", scenario)
        .isNotNull();
}

@DataProvider(name = "timestampEdgeCases")
public Object[][] timestampEdgeCases() {
    return new Object[][] {
        {
            ZonedDateTime.of(2024, 1, 1, 0, 0, 0, 0, ZoneId.of("UTC")),
            "UTC midnight"
        },
        {
            ZonedDateTime.of(2024, 6, 30, 23, 59, 60, 0, ZoneId.of("UTC")),
            "leap second (ambiguous: supported?)"
        },
        {
            ZonedDateTime.of(2024, 3, 10, 2, 0, 0, 0, ZoneId.of("America/New_York")),
            "DST transition (spring forward)"
        },
        {
            ZonedDateTime.of(2024, 11, 3, 2, 0, 0, 0, ZoneId.of("America/New_York")),
            "DST transition (fall back)"
        },
    };
}
```

**Key points:**
- Test DST transitions
- Test UTC vs local time handling
- Test leap seconds (rare, but edge case)

---

## Pattern 10: Test Organization & Documentation

### Problem

How do we organize and run edge-case tests separately from happy-path tests?

### Solution

```java
@Epic("User Management — Edge Cases")
public class TestUserApiEdgeCases extends BaseTest {

    private UserService userService;

    @BeforeMethod(alwaysRun = true)
    public void setUp() {
        userService = new UserService(getClient());
    }

    // ── Input Validation ──────────────────────────────────────────
    
    @Feature("Email Validation Edge Cases")
    @Test(
        dataProvider = "emailEdgeCases",
        groups = {"edge-cases", "validation"}
    )
    public void testEmailValidationEdgeCases(...) { ... }

    // ── Boundary Values ──────────────────────────────────────────
    
    @Feature("Username Length Boundaries")
    @Test(
        dataProvider = "usernameLength",
        groups = {"edge-cases", "boundaries"}
    )
    public void testUsernameLengthBoundaries(...) { ... }

    // ── Concurrency ──────────────────────────────────────────
    
    @Feature("Concurrent Requests")
    @Test(groups = {"edge-cases", "concurrency"})
    public void testConcurrentUserCreationWithDuplicateEmail(...) { ... }

    // ── Authorization ──────────────────────────────────────────
    
    @Feature("Permission Boundaries")
    @Test(
        dataProvider = "rolePermissions",
        groups = {"edge-cases", "security"}
    )
    public void testCreateUserPermissionByRole(...) { ... }
}
```

**Key points:**
- Organize by feature/category (validation, boundaries, concurrency, security)
- Use `groups = {"edge-cases", ...}` to run edge-case tests separately
- Use Allure annotations (@Epic, @Feature) for clear reporting
- Can run only edge-case tests: `mvn test -Dgroups=edge-cases`

---

## Running Edge-Case Tests

### Run all edge-case tests:
```bash
mvn test -Dgroups=edge-cases
```

### Run specific category:
```bash
mvn test -Dgroups=edge-cases,validation
mvn test -Dgroups=edge-cases,concurrency
```

### Run with Allure reporting:
```bash
mvn test -Dgroups=edge-cases
mvn allure:serve
```

---

## Template: Creating a New Edge-Case Test

```java
@Feature("[ Feature Name ]")
@Story("[ Ambiguity or Edge Case ]")
@Severity(SeverityLevel.CRITICAL)  // or NORMAL, MINOR
@Test(
    dataProvider = "[ dataProvider Name ]",
    groups = {"edge-cases", "[ category ]"}
)
@Description("[ What is ambiguous or edge-casey about this? ]")
public void test[ FeatureName ][ EdgeCase ](
    [ parameter1 Type ] parameter1,
    [ parameter2 Type ] parameter2,
    [ int expectedStatus ] expectedStatus,
    String scenario) {
    
    // Setup
    // Exercise
    // Assert
    
    assertThat([ actual ])
        .as("[ scenario ]: [ expectedStatus ]")
        .isEqualTo([ expectedStatus ]);
}

@DataProvider(name = "[ dataProvider Name ]")
public Object[][] [ dataProviderName ]() {
    return new Object[][] {
        { [ value1 ], [ value2 ], [ status ], "[ description ]" },
        { [ value1 ], [ value2 ], [ status ], "[ description ]" },
    };
}
```

---

## Key Takeaway

**Edge-case tests FAIL by design.** They expose gaps in the PRD. Once the PRD is clarified, update the test expectations and code, and tests will pass. This is the purpose: use test failures to drive PRD clarification *before* building the code.
