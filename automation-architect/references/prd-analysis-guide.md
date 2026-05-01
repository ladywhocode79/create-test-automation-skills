# PRD Analysis Guide

## Purpose

This guide shows how to **analyze a Product Requirements Document (PRD)** to:
1. Identify what needs automation coverage (endpoints, pages, workflows)
2. Detect ambiguities and edge cases (missing specs, vague requirements)
3. **Recommend the automation type** (API, UI, Full-Stack, Non-Functional)
4. Confirm the recommendation with the user

---

## Phase 1: Extract Scope from PRD

Read through the PRD and extract:

### 1.1 Endpoints / Pages / Workflows

**What to look for:**
- REST endpoints: `POST /api/v1/users`, `GET /api/v1/users/{id}`, etc.
- UI pages: login page, user dashboard, settings page, etc.
- Workflows: user registration flow, payment checkout, approval process, etc.

**Document as:**
```
Endpoints/Pages Identified:
  [API] POST /api/v1/users — Create user
  [API] GET /api/v1/users — List users
  [UI] Login page — User authentication
  [UI] Dashboard — Display user stats
```

### 1.2 Use Cases & Business Logic

**What to look for:**
- Happy path: "User creates account with valid email"
- Error handling: "If email exists, return 409 Conflict"
- State transitions: "User moves from draft to approved"
- Permissions: "Only admins can delete users"

**Document as:**
```
Use Cases:
  • User creates account with valid email → 201 Created
  • User tries to create with existing email → 409 Conflict
  • Unauthenticated user lists users → 401 Unauthorized
```

### 1.3 Authentication & Authorization

**What to look for:**
- Auth mechanism: Bearer token, OAuth, API Key, etc.
- Permission model: role-based (viewer/editor/admin), scope-based, etc.
- Access control: "viewers can only read", "admins can delete", etc.

**Document as:**
```
Auth Pattern:
  Type: OAuth 2.0 Bearer token
  Roles: viewer, editor, admin
  Rules:
    • Viewers can only GET endpoints
    • Editors can GET + PATCH
    • Admins can GET + PATCH + DELETE
```

### 1.4 Performance & Scalability Requirements

**What to look for:**
- SLAs: "Must respond in < 500ms"
- Rate limits: "100 requests/minute per user"
- Pagination: "Max page size: 1000"
- Concurrency: "Must handle 1000 simultaneous users"

**Document as:**
```
Performance Requirements:
  • Response time SLA: < 500ms for GET, < 1s for POST
  • Rate limit: 100 req/min per user
  • Max page size: 1000
```

---

## Phase 2: Identify Ambiguities & Edge Cases

Use the **edge-case checklist** (`references/templates/edge-case-checklist.md`) to identify gaps:

### 2.1 Critical Ambiguities

Go through each category in the checklist and flag ambiguities:

**Example 1: Email Validation**
```
PRD says: "Email must be valid"
Ambiguity: No regex or RFC definition
  • Does "user+tag@example.com" pass? (plus addressing)
  • Is "user@localhost" allowed? (no TLD)
  • Is "USER@EXAMPLE.COM" == "user@example.com"? (case sensitivity)
```

**Example 2: Username Length**
```
PRD says: "Username is required and unique"
Ambiguity: No min/max length specified
  • Is "a" valid? (1 character)
  • Is "username" valid? (8 characters)
  • Is "verylongusername..." valid? (256+ characters)
```

**Example 3: Delete Behavior**
```
PRD says: "Delete user"
Ambiguity: No mention of cascading deletes or soft delete
  • Hard delete or soft delete?
  • What happens to user's posts/comments?
  • Can deleted user be restored?
```

### 2.2 Count Ambiguities

As you find gaps, tally them:
```
Total Ambiguities Found: 12
  • Input Validation: 4 (email, username, password, role)
  • Business Logic: 3 (delete behavior, concurrent updates, permissions)
  • Error Handling: 2 (error codes not enumerated)
  • Performance: 2 (rate limits, timeout rules)
  • Data Retention: 1 (soft vs hard delete)
```

---

## Phase 3: Recommend Automation Type

Based on PRD scope, choose the automation type:

### 3.1 Decision Matrix

| PRD Focus | Automation Type | Reason |
|-----------|---|---|
| REST/GraphQL endpoints, data validation, error codes | **API** | No UI involved; focus is on contract + data integrity |
| User workflows, browser interaction, UI validation | **UI** | Focus is on user-facing behavior, locators, page flows |
| Both API contracts + user workflows in same project | **Full-Stack** | Need both API + UI tests; shared test data; same CI pipeline |
| Response times, load, concurrency, security | **Non-Functional** | Focus is on perf/security/chaos, not functional correctness |

### 3.2 Heuristics

**Choose API if PRD mentions:**
- ✓ REST, GraphQL, gRPC, endpoint
- ✓ Response codes (200, 400, 409)
- ✓ JSON validation, data models
- ✓ Authentication tokens, OAuth
- ✓ NO mention of "user clicks", "page loads", "button"

**Choose UI if PRD mentions:**
- ✓ User login, signup flow
- ✓ Dashboard, navigation, forms
- ✓ "User clicks", "User enters", "User sees"
- ✓ Responsive design, browser compatibility
- ✓ NO mention of "endpoint", "REST", "response code"

**Choose Full-Stack if PRD mentions:**
- ✓ User workflow + API validation (e.g., "User signs up and receives email")
- ✓ Both UI pages and endpoints
- ✓ Backend + frontend in same project
- ✓ Shared database, state validation

**Choose Non-Functional if PRD mentions:**
- ✓ Performance SLAs, load testing requirements
- ✓ Security testing, penetration testing
- ✓ Rate limiting, concurrency, stress testing
- ✓ Chaos engineering scenarios

### 3.3 Recommendation Format

```
Based on your PRD, I recommend: API + Full-Stack

Why:
  • 4 REST endpoints need coverage (POST /users, GET /users/{id}, PATCH, DELETE)
  • User signup flow needs end-to-end validation (UI + API)
  • No performance SLAs mentioned (NFR not needed now)
  • 12 ambiguities identified (edge-case tests will expose gaps)

Does this match your testing goals?
  [A] Yes, API + Full-Stack
  [B] No, I actually need API only
  [C] No, I actually need UI only
  [D] No, I actually need Non-Functional testing
```

**Wait for user confirmation.**

---

## Phase 4: Edge-Case Coverage Planning

Once automation type is confirmed, plan edge-case coverage:

### 4.1 Critical Edge Cases from PRD Ambiguities

Map ambiguities → test cases:

```
Ambiguity #1: Email validation rules not specified
Edge Case Tests:
  • user@example.com (valid)
  • user+tag@example.com (plus addressing — ambiguous)
  • user@localhost (no TLD — ambiguous)
  • @example.com (missing local — invalid)
  • user@domain..com (double dot — invalid)

Test Outcome:
  If code rejects user+tag@example.com, test fails and exposes the gap.
  PRD must clarify: allow plus addressing or not?
```

### 4.2 Priority

Mark edge cases by impact:
- **P0 (Critical):** Block release (e.g., email conflict handling)
- **P1 (High):** Production bugs (e.g., validation bypass)
- **P2 (Medium):** Nice to catch early (e.g., unicode handling)

```
Priority Breakdown:
  P0 (Critical): 3 edge cases
    • Duplicate email handling (409 or 201?)
    • Password validation (weak passwords allowed?)
    • Authorization rules (who can create users?)
  
  P1 (High): 5 edge cases
    • Email format edge cases (plus addressing, case sensitivity)
    • Username length boundaries
    • Role validation
  
  P2 (Medium): 4 edge cases
    • Unicode username support
    • Pagination edge cases
    • Error code enumeration
```

---

## Example: Complete PRD Analysis

### PRD Summary
```
User Management API v1.0
  • 5 endpoints: POST/GET/PATCH/DELETE /users, GET /users?pagination
  • OAuth 2.0 Bearer token auth
  • Roles: viewer, editor, admin
  • No performance SLAs mentioned
```

### Step 1: Extract Scope
```
Endpoints:
  POST /api/v1/users (create)
  GET /api/v1/users (list with pagination)
  GET /api/v1/users/{id} (get by id)
  PATCH /api/v1/users/{id} (update)
  DELETE /api/v1/users/{id} (delete)

Auth: OAuth 2.0 Bearer token
```

### Step 2: Identify Ambiguities
```
Using edge-case checklist:
  1. Email validation: No regex, no RFC ref — ambiguous
  2. Username length: No min/max — ambiguous
  3. Password rules: No strength rules — ambiguous
  4. Role validation: No list of valid roles — ambiguous
  5. Delete behavior: Hard vs soft delete — ambiguous
  6. Concurrent updates: Last write wins? — ambiguous
  7. Pagination: Max page size? Behavior if page > max? — ambiguous
  8. Authorization: Who can create users? — ambiguous
  9. Error codes: Not enumerated — ambiguous
  10. Rate limits: Not specified — ambiguous

Total: 10 ambiguities (P0: 3, P1: 4, P2: 3)
```

### Step 3: Recommend Type
```
✓ API (REST endpoints, no UI)
✓ Full-Stack candidate? No, no UI mentioned in PRD
✓ Non-Functional? No SLAs, so not now

Recommendation: API + Edge-Case Suite
  • 5 API endpoints to cover
  • 10 ambiguities to expose through failing tests
  • Tests will guide PRD clarification
```

### Step 4: Edge-Case Priority
```
P0 (Critical — must clarify before dev):
  • Email conflict: What if email already exists during CREATE?
  • Authorization: Can user create other users?
  • Role validation: What are valid roles?

P1 (High — affects test coverage):
  • Email format edge cases
  • Username length boundaries
  • Password strength rules

P2 (Medium — nice to have):
  • Pagination edge cases
  • Error code consistency
  • Rate limiting behavior
```

---

## Checklist: PRD Analysis

- [ ] Extracted all endpoints/pages
- [ ] Identified all use cases (happy path + error paths)
- [ ] Documented auth & authorization rules
- [ ] Listed performance/scalability requirements
- [ ] Used edge-case checklist to identify ambiguities
- [ ] Counted and prioritized ambiguities
- [ ] Recommended automation type (API/UI/Full-Stack/NFR)
- [ ] Confirmed recommendation with user
- [ ] Planned edge-case coverage for P0 ambiguities
- [ ] Ready to scaffold framework

---

## Next Steps

1. **User confirms automation type**
2. **Proceed to Round 1** (Language selection)
3. **Scaffold includes edge-case test templates** based on PRD analysis
4. **Test suite highlights ambiguities** so PRD can be clarified
5. **Once PRD is clarified**, edge-case tests transition from failing → passing

---

## Files Referenced

- `edge-case-checklist.md` — 10-category checklist for identifying gaps
- `sample-prd-user-management.md` — Sample PRD with 19 intentional ambiguities
