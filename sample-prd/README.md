# Sample PRD & Edge-Case Testing Documentation

This directory contains templates and examples for the **automation-architect-edge-cases** skill.

## Files

### 1. `sample-prd-user-management.md`
**Sample Product Requirements Document** with intentional ambiguities marked with ⚠️.

**Use this to:**
- Understand what a PRD looks like with gaps and unclear requirements
- See 19 documented ambiguities that edge-case tests will expose
- Replace with your actual PRD and analyze it with the skill

**Key sections:**
- API endpoints (POST, GET, LIST, PATCH, DELETE)
- Field validation rules (email, username, role, password)
- Authorization rules (undefined)
- Concurrency behavior (undefined)
- Pagination edge cases (undefined)
- Error handling (error codes not enumerated)
- Data retention & cascading deletes (unclear)

### 2. `edge-case-checklist.md`
**Comprehensive checklist for identifying edge cases** when reading a PRD.

**Use this to:**
- Systematically find gaps and ambiguities in your PRD
- Understand all 10 categories of edge cases (input validation, boundaries, concurrency, state transitions, etc.)
- Plan test coverage before writing code

**Categories covered:**
1. Input Validation Edge Cases
2. Business Logic Edge Cases
3. Data Integrity Edge Cases
4. Resource Limits & Pagination
5. Error Handling Edge Cases
6. Performance & Scalability
7. Security Edge Cases
8. Backwards Compatibility
9. Time-Based Edge Cases
10. Platform-Specific Edge Cases

### 3. `edge-case-tests-testng.md`
**Reusable test patterns for Java/TestNG** frameworks.

**Use this to:**
- Copy-paste patterns for your Java/TestNG edge-case tests
- See 10 patterns with complete examples:
  - Parametrized input validation
  - Boundary value testing
  - Concurrency & race conditions
  - State transition validation
  - Authorization & permission boundaries
  - Error scenario coverage
  - Idempotence testing
  - Pagination edge cases
  - Timestamp & timezone handling
  - Test organization & documentation

**Example:** Run edge-case tests separately:
```bash
mvn test -Dgroups=edge-cases
```

### 4. `edge-case-tests-pytest.md`
**Reusable test patterns for Python/pytest** frameworks.

**Use this to:**
- Copy-paste patterns for your Python/pytest edge-case tests
- See 10 patterns with complete examples
- Use pytest markers for test organization
- Work with fixtures and parametrize

**Example:** Run edge-case tests:
```bash
pytest -m edge_case
```

---

## How to Use These Files

### Step 1: Review the Sample PRD
```bash
cat sample-prd-user-management.md
```
Look for ⚠️ markers showing ambiguities.

### Step 2: Use the Checklist
Go through `edge-case-checklist.md` for your actual PRD to identify gaps.

### Step 3: Generate Edge-Case Tests
Pick your language (Java/TestNG or Python/pytest) and use the patterns:
- `edge-case-tests-testng.md` for Java
- `edge-case-tests-pytest.md` for Python

### Step 4: Run Tests
Tests will **FAIL by design** until PRD is clarified.

---

## Example: From PRD to Tests

**PRD says:** "Email must be valid"

**Ambiguity:** What is "valid"? No regex or RFC defined.

**Checklist prompts:** Test plus addressing, multi-part TLDs, case sensitivity

**Generated test:**
```java
@Test(dataProvider = "emailEdgeCases")
public void testEmailValidationEdgeCases(String email, boolean shouldBeValid, String scenario) {
    Response response = api.post("/users", {"email": email});
    assertThat(response.statusCode()).isEqualTo(shouldBeValid ? 201 : 400);
}

// Ambiguous cases that will FAIL:
// {"user+tag@example.com", true, "plus addressing (ambiguous)"}
// {"user@example.co.uk", true, "multi-part TLD (ambiguous)"}
```

**Test outcome:** If code rejects `user+tag@example.com`, test fails → PRD needs clarification → once clarified, update test and code → test passes.

---

## Next Steps

1. **Copy your PRD** to this directory or replace `sample-prd-user-management.md`
2. **Use the skill:** Invoke `/automation-architect-edge-cases` with your PRD
3. **Generate edge-case tests** from the patterns in this directory
4. **Run tests** — expect failures (that's the point!)
5. **Clarify PRD** based on test failures
6. **Update tests** once PRD is clarified
7. **Tests pass** → Ready to build code with clear requirements

---

## Verified With

- Java/TestNG framework at `/Applications/my apps/api-automation-java`
- Happy-path tests: ✅ 8/8 passing
- Edge-case tests: 20 designed to expose PRD gaps
- Demonstration that requirements clarification happens BEFORE code, not after

---

## Questions?

See the skill documentation:
```
~/.claude/skills/automation-architect-edge-cases/SKILL.md
```
