# TC-ORCH-02 — PRD Intake

**Skill**: automation-architect (Orchestrator)  
**Total TCs**: 6  
**Level**: L2  
**Model**: Haiku  
**Pre-req**: Skill activation passing (TC-ORCH-01 suite green)

---

## Setup

```bash
cd /tmp && claude
/model claude-haiku-4-5-20251001
# Activate skill first
"I need a test automation framework"
```

---

## TC-ORCH-02-01 — PRD Intake [A]: user pastes PRD text

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify the skill accepts pasted PRD text, extracts scope, and proceeds to Round 0 analysis.

### Preconditions
- Skill has activated and shown the PRD intake question (Round -1)

### Steps
1. At the PRD intake prompt, type `A` or `[A]`
2. Paste the following minimal PRD:
```
## User Management API

### Endpoints
- POST /users — create a new user (name, email, password required)
- GET /users/{id} — retrieve user by ID
- DELETE /users/{id} — soft-delete a user (admin only)

### Business Rules
- Email must be unique
- Password minimum 8 characters
- Deleted users return 404 on GET
```

### Expected Results
- [ ] Skill acknowledges PRD received
- [ ] Skill extracts and lists the 3 endpoints: POST /users, GET /users/{id}, DELETE /users/{id}
- [ ] Skill identifies at least 2 edge cases (e.g., duplicate email, short password, deleted user GET)
- [ ] Skill recommends test type (API, UI, or Full-Stack) based on content
- [ ] Round 0 confirms automation type before moving to language selection

### Pass Criteria
All 5 items checked.

### Debug Tips
- Missing endpoint extraction → check `references/prd-analysis-guide.md` in orchestrator skill

---

## TC-ORCH-02-02 — PRD Intake [B]: sample PRD loaded and displayed

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify option [B] loads the sample PRD from `references/samples/sample-prd-user-management.md`
and displays it before analysis.

### Preconditions
- Skill has activated and shown the PRD intake question

### Steps
```
B
```

### Expected Results
- [ ] Skill reads and displays the sample PRD (User Management API content visible)
- [ ] Skill proceeds to Round 0 PRD analysis automatically
- [ ] Endpoints extracted from the sample PRD are listed
- [ ] Ambiguities flagged as P0/P1/P2 (at least one P0 ambiguity identified)
- [ ] Recommended automation type confirmed before moving on

### Pass Criteria
All 5 items checked.

### Debug Tips
- Sample PRD not showing → file path `references/samples/sample-prd-user-management.md` may be wrong
- Check Read instruction in `automation-architect/SKILL.md` Round -1 section

---

## TC-ORCH-02-03 — PRD Intake [C]: deferred PRD, scaffold continues

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify [C] defers PRD and continues to the interview without blocking.

### Steps
```
C
```

### Expected Results
- [ ] Skill acknowledges PRD will be provided later
- [ ] Skill proceeds directly to Round 0 (test type selection question)
- [ ] No error or blocking message
- [ ] Interview continues normally from Round 0 onwards

### Pass Criteria
All 4 items checked.

---

## TC-ORCH-02-04 — PRD analysis extracts correct endpoints

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify the PRD analysis step correctly maps PRD content to testable endpoints and workflows.

### Preconditions
- Use the sample PRD (option [B]) which has known, predictable content

### Steps
1. At PRD intake, select `B`
2. After analysis output, check extracted scope

### Expected Results
- [ ] All CRUD endpoints in the sample PRD are listed in the scope
- [ ] Auth-related endpoints identified (login, token refresh if present)
- [ ] Business rules translated to testable assertions (e.g., unique email = 409 conflict test)
- [ ] Page/workflow scope listed if PRD contains UI flows

### Pass Criteria
All applicable items checked (skip UI item if sample PRD is API-only).

---

## TC-ORCH-02-05 — PRD analysis flags ambiguities with P0/P1/P2 priority

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify ambiguities in the PRD are identified and triaged by priority level.

### Preconditions
- Use the sample PRD (option [B]) which contains intentional ambiguities

### Steps
1. Select `B` at PRD intake
2. Review the ambiguity section of the analysis output

### Expected Results
- [ ] At least one P0 ambiguity identified (e.g., unclear auth mechanism, missing error codes)
- [ ] At least one P1 ambiguity identified (e.g., pagination not specified, rate limits unclear)
- [ ] Each ambiguity labelled with priority (P0 / P1 / P2)
- [ ] Each ambiguity has a brief description of why it matters for test coverage

### Pass Criteria
All 4 items checked.

### Debug Tips
- No ambiguities found → check `references/prd-analysis-guide.md` ambiguity detection section
- Wrong priorities → review the P0/P1/P2 triage rules in the same file

---

## TC-ORCH-02-06 — PRD recommends correct automation type

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify the skill recommends API, UI, or Full-Stack based on what the PRD describes.

### Steps — Scenario A (API-only PRD)
Provide a PRD with only REST endpoints and no UI mention:
```
A
[paste API-only PRD content]
```
Expected recommendation: **API**

### Steps — Scenario B (UI + API PRD)
Provide a PRD mentioning both a web interface and backend:
```
A
[paste PRD mentioning login page, dashboard, REST endpoints]
```
Expected recommendation: **Full-Stack**

### Expected Results
- [ ] Scenario A → skill recommends API automation type
- [ ] Scenario B → skill recommends Full-Stack automation type
- [ ] Recommendation is presented as a suggestion, not an order (user can override)
- [ ] After recommendation, Round 0 asks user to confirm or change

### Pass Criteria
All 4 items checked.
