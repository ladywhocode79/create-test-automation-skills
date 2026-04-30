# Edge-Case Test Checklist

## How to Identify Edge Cases from a PRD

Use this checklist when analyzing a PRD to identify gaps and ambiguities that lead to production bugs.

---

## 1. Input Validation Edge Cases

- [ ] **Empty/Null/Blank**
  - Empty string: `""`
  - Null value: `null` (JSON) / `None` (Python) / `nil` (Go)
  - Whitespace only: `"   "`
  - Empty array/list: `[]`
  - Empty object: `{}`

- [ ] **Type Mismatches**
  - String instead of number: `{"age": "25"}` instead of `{"age": 25}`
  - Number instead of boolean: `{"active": 1}` instead of `{"active": true}`
  - Array instead of string: `{"email": ["user@example.com"]}`

- [ ] **Boundary Values**
  - Minimum value: `-1`, `0`, `1`
  - Maximum value: `2^31-1`, `2^63-1`, `999`, etc.
  - Just below minimum: `-1` (if min is 0)
  - Just above maximum: `1001` (if max is 1000)

- [ ] **Whitespace & Special Characters**
  - Leading whitespace: `"  username"`
  - Trailing whitespace: `"username  "`
  - Unicode characters: `"用户"`, `"юзер"`, emoji: `"👤"`
  - Control characters: newline `\n`, tab `\t`, null byte `\0`
  - Symbols: `"user@domain"`, `"pass#word"`, `"$pecial"`

- [ ] **String Length Edge Cases**
  - Minimum length (if specified in PRD)
  - Just below minimum (if min is 3, test 2)
  - Just above minimum (if min is 3, test 4)
  - Maximum length (if specified)
  - Just below maximum (if max is 100, test 99)
  - Just above maximum (if max is 100, test 101)
  - Very long strings: 10MB, 1GB

- [ ] **Format/Pattern Mismatches**
  - Email: `invalid`, `user@`, `@domain`, `user@@domain`, `user@domain`
  - URL: `not-a-url`, `http://`, `htp://example.com` (typo)
  - IP address: `256.0.0.1` (invalid octet), `192.168.1` (incomplete)
  - Phone: letters `"555-CALL"`, missing digits
  - Date: `2024-13-01` (invalid month), `2024-02-30` (invalid day for Feb)

- [ ] **Encoding Issues**
  - Non-ASCII characters
  - UTF-8 vs UTF-16 encoding
  - HTML entities: `"<script>alert('xss')</script>"`
  - SQL injection: `"' OR '1'='1"`
  - Command injection: `"; rm -rf /"`

---

## 2. Business Logic Edge Cases

- [ ] **Duplicate/Uniqueness Constraints**
  - Create user with existing email (should fail)
  - Update user A's email to user B's email (conflict?)
  - Create two users simultaneously with same email (race condition)
  - Soft delete then recreate with same email (allowed?)

- [ ] **State Transitions**
  - Invalid state changes: `draft` → `archived` (should allow only `draft` → `published` → `archived`)
  - Reverse transitions: `archived` → `draft` (allowed?)
  - Skipped states: `draft` → `archived` (skipping `published`)
  - Cyclic transitions: `approved` → `rejected` → `approved` (allowed?)

- [ ] **Permission & Authorization**
  - User reads own data (allowed)
  - User reads other user's data (allowed? depends on role)
  - User deletes own account (allowed? or admin-only?)
  - User changes own role from `editor` to `admin` (allowed?)
  - User downgrades own role (allowed?)
  - Unauthenticated request (missing token)
  - Invalid token format: `"Bearer invalid"`, `"InvalidScheme abc123"`
  - Expired token (if applicable)
  - Insufficient permissions (token exists, but doesn't grant required scope)

- [ ] **Cascading Operations**
  - Delete user → what happens to user's posts, comments, sessions?
  - Soft delete vs hard delete (behavior differences?)
  - Restore from soft delete → associated records restored too?
  - Update parent record → child records updated/orphaned?

- [ ] **Concurrency Issues**
  - Two simultaneous POST requests with same email
  - Two simultaneous PATCH requests on same user (last write wins? Conflict?)
  - DELETE while GET is in progress
  - CREATE while LIST is being streamed
  - Read-modify-write race condition (increment counter, lost update)

- [ ] **Idempotence**
  - POST same request twice → 201 Created first time, 409 Conflict or 201 again?
  - PATCH idempotent? (can retry without side effects)
  - DELETE idempotent? (DELETE deleted resource → 404 or 204?)
  - Retry with same request ID (if supported by API)

---

## 3. Data Integrity Edge Cases

- [ ] **Constraint Violations**
  - NOT NULL constraint: `{"name": null}`
  - UNIQUE constraint: duplicate email
  - FOREIGN KEY constraint: reference non-existent user
  - CHECK constraint: age < 0, discount > 100%

- [ ] **Invariants**
  - Total amount must equal sum of line items
  - User count in dashboard != actual users in DB
  - Parent created before children (time invariant)

- [ ] **Dangling References**
  - Delete user, but session still references user ID
  - Delete post, but comments still exist
  - Orphaned records after cascading delete

---

## 4. Resource Limits & Pagination

- [ ] **Pagination Edge Cases**
  - `page=1, page_size=20` (first page)
  - `page=0` (invalid, should 400 or default to 1?)
  - `page=-1` (invalid)
  - `page=999` (beyond total pages: 3 pages exist, request page 100)
  - `page_size=0` (invalid)
  - `page_size=-1` (invalid)
  - `page_size=1000000` (unlimited? 500 max?)
  - Empty result set: `page=1, page_size=20, total=0`
  - Single-page result: `page=1, total=5, page_size=20` (all on one page)

- [ ] **Large Data**
  - List 1M users (timeout? streaming?)
  - Create 10KB payload
  - Update with very large string (text field)
  - Bulk import 100K records

- [ ] **Rate Limiting**
  - 10 requests/second (if limit is enforced)
  - Burst 100 requests in 1 second (should rate limit kick in?)
  - Request after rate limit exceeded (429 Too Many Requests?)

---

## 5. Error Handling Edge Cases

- [ ] **Expected Errors**
  - 400 Bad Request (malformed JSON, validation failure)
  - 401 Unauthorized (missing/invalid token)
  - 403 Forbidden (insufficient permissions)
  - 404 Not Found (user doesn't exist)
  - 409 Conflict (email already exists)

- [ ] **Unexpected Errors**
  - 500 Internal Server Error (unhandled exception)
  - 503 Service Unavailable (dependency down)
  - 504 Gateway Timeout (slow response)
  - Timeout after 30s (if specified)
  - Connection reset by peer

- [ ] **Error Recovery**
  - Retry after transient failure (should succeed)
  - Timeout then retry (should succeed)
  - Partial payment processed then connection dropped (refund? rollback?)

- [ ] **Error Response Format**
  - Is error format consistent?
  - Are error codes enumerated?
  - Is error message human-readable?
  - Is request ID included for tracing?

---

## 6. Performance & Scalability

- [ ] **Response Time**
  - Single user lookup: < 100ms
  - List 100 users: < 1s
  - Create user: < 500ms

- [ ] **Concurrency**
  - 10 simultaneous users (no errors)
  - 100 simultaneous users (degraded performance? errors?)
  - 1000 simultaneous users (capacity exceeded)

- [ ] **Database Locks & Deadlocks**
  - Two transactions updating same user (lock wait)
  - Circular transaction dependencies (deadlock)

---

## 7. Security Edge Cases

- [ ] **Authentication/Authorization**
  - Missing token: should return 401
  - Invalid token: should return 401
  - Expired token: should return 401
  - Token with insufficient scope: should return 403

- [ ] **Data Exposure**
  - GET user response should NOT include password hash
  - GET user response should NOT include API keys
  - LIST endpoint should NOT leak other users' emails

- [ ] **Input Injection**
  - SQL injection: `"' OR '1'='1"`
  - XSS injection: `"<script>alert('xss')</script>"`
  - Command injection: `"; rm -rf /"`
  - LDAP injection: `"*)(uid=*"`

- [ ] **Password Security**
  - Password transmitted over HTTPS (not HTTP)
  - Password not logged or exposed in error messages
  - Password not returned in GET responses
  - Old passwords not reusable (if enforced)

---

## 8. Backwards Compatibility

- [ ] **API Versioning**
  - Old client calling v1 endpoint (should work)
  - New client calling old API (should work or graceful degradation)
  - Deprecated field in response (should still parse)

- [ ] **Schema Changes**
  - New optional field added to response (old clients ignore it)
  - New required field added (old clients break?)
  - Field renamed (old field still works for compatibility?)

---

## 9. Time-Based Edge Cases

- [ ] **Timestamps**
  - `created_at` in past (valid)
  - `created_at` in future (invalid?)
  - `updated_at` before `created_at` (invalid)
  - Timezone handling (UTC vs local time)
  - Daylight saving time (DST) transitions
  - Leap second (June 30, 2024, 23:59:60 UTC)

- [ ] **Expiration**
  - Token expires at exact boundary (is it still valid at expiration moment?)
  - Record expires and is soft-deleted
  - Recurring event on leap year Feb 29 (what happens in non-leap year?)

---

## 10. Platform-Specific Edge Cases

- [ ] **Character Encoding**
  - macOS file system (NFKD normalization): `"café"` vs `"cafe\u0301"`
  - Windows vs Unix line endings (`\r\n` vs `\n`)
  - BOM (Byte Order Mark) in file uploads

- [ ] **Floating Point Arithmetic**
  - `0.1 + 0.2 !== 0.3` (IEEE 754 precision)
  - Rounding errors in price calculations
  - Very large numbers (loss of precision)

- [ ] **File System**
  - File path with spaces: `/Applications/my apps/...`
  - File path with special characters: `/tmp/file (1).txt`
  - Symlinks and circular references
  - Case-sensitive vs case-insensitive file systems

---

## Template: Identifying an Ambiguity

When you find an ambiguity in the PRD, create a test like this:

```
PRD says: "Email must be valid"
Problem: "Valid" is undefined (no regex, no RFC reference)

Test the ambiguous behavior:
  - user@example.com → should succeed (201)
  - user+tag@example.com → ambiguous, test expects ??? (expose the gap)
  - user@localhost → ambiguous, test expects ??? (expose the gap)

Test outcome:
  - If code rejects user+tag@example.com, test fails (ambiguity found)
  - PRD now must clarify: allow plus addressing or not?
  - Once clarified, update test expectation and code
```

---

## Using This Checklist

1. **Read the PRD** and note all requirements
2. **Go through each section** of this checklist
3. **For each item marked [ ]**, ask: "Does the PRD specify this?"
4. **If unchecked/ambiguous**, plan a test to expose the gap
5. **Generate parametrized tests** with edge-case data providers
6. **Run tests** — many will fail (expected, exposing gaps)
7. **Use failures** as PRD clarification tickets
8. **Once PRD is clarified**, tests will pass

---

## Example: From Checklist to Tests

**Checklist item:** "Boundary Values → Minimum/Maximum"

**PRD says:** "Username is required" (no min/max length)

**Checklist triggers:** What if username is 1 character? 256 characters? 1MB?

**Generated test:**
```java
@DataProvider(name = "usernameLength")
public Object[][] usernameLength() {
    return new Object[][] {
        {"a", "too short?" },
        {"ab", "too short?" },
        {"valid", "canonical"},
        {"".repeat(256), "too long?" },
    };
}

@Test(dataProvider = "usernameLength")
public void testUsernameLengthEdgeCases(String username, String scenario) {
    // Test FAILS until PRD specifies min/max length
    assertThat(scenario).isNotEqualTo("too short?"); // ambiguous
}
```

Once PRD says "3-20 characters", update test to assert specific error codes.
