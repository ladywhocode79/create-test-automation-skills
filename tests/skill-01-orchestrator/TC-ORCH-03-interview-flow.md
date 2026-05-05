# TC-ORCH-03 — Interview Flow

**Skill**: automation-architect (Orchestrator)  
**Total TCs**: 8  
**Level**: L2  
**Model**: Haiku  
**Pre-req**: PRD intake passing (TC-ORCH-02 suite green)

---

## Setup

For each TC, use a fresh session activated with a trigger phrase, then proceed
through PRD intake with `[C]` (deferred) to reach the interview rounds quickly.

```bash
cd /tmp && claude
/model claude-haiku-4-5-20251001
"I need a test automation framework"
# At PRD intake:
C
```

---

## TC-ORCH-03-01 — Q0 asks test type before any language question

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Round 0 (test type: API / UI / Full-Stack) is always the first question
after PRD intake — language selection never comes first.

### Steps
After PRD intake `[C]`, observe the next question presented.

### Expected Results
- [ ] First question after PRD intake asks test type (API / UI / Full-Stack / NFR)
- [ ] Language options (Python / Java) are NOT presented yet
- [ ] Question clearly lists the options [A] API, [B] UI, [C] Full-Stack

### Pass Criteria
All 3 items checked.

### Debug Tips
- Language asked first → Round -1/0 order is swapped in `SKILL.md` Phase 1

---

## TC-ORCH-03-02 — API-only flow skips UI browser and locator questions

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify that selecting API-only suppresses all UI-specific questions.

### Steps
```
A          # API test type at Round 0
A          # Python at Round 1
A          # REST/JSON at Round 2
B          # OAuth2 at Round 3
```
Continue through remaining questions and note which questions appear.

### Expected Results
- [ ] No question about browsers (Chrome / Firefox)
- [ ] No question about execution mode (headless / headed)
- [ ] No question about locator strategy (data-testid / CSS / XPath)
- [ ] No question about UI auth (login form / token injection)
- [ ] Questions DO include: environments, mock mode, reporting, CI, data strategy

### Pass Criteria
All 5 items checked.

---

## TC-ORCH-03-03 — UI-only flow skips API protocol and auth questions

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify that selecting UI-only suppresses all API-specific questions.

### Steps
```
B          # UI test type at Round 0
A          # Python at Round 1
```
Continue through remaining questions and note which questions appear.

### Expected Results
- [ ] No question about API protocol (REST / GraphQL / gRPC)
- [ ] No question about API auth (Bearer / OAuth2 / API Key)
- [ ] Questions DO include: browsers, execution mode, locator strategy, UI auth
- [ ] Questions DO include: environments, mock mode, reporting, CI, data strategy

### Pass Criteria
All 4 items checked.

---

## TC-ORCH-03-04 — Full-Stack flow asks both API and UI question sets

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify Full-Stack asks all questions from both API and UI paths.

### Steps
```
C          # Full-Stack at Round 0
A          # Python at Round 1
```
Go through the entire interview and record every question asked.

### Expected Results
- [ ] API protocol question asked
- [ ] API auth question asked
- [ ] Browser selection question asked
- [ ] Execution mode question asked
- [ ] Locator strategy question asked
- [ ] UI auth question asked
- [ ] Environments, mock, reporting, CI, data strategy all asked

### Pass Criteria
All 7 items checked.

---

## TC-ORCH-03-05 — Invalid answer at Q0 triggers re-ask

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L2 |
| Type | Negative |
| Model | Haiku |

### Objective
Verify the skill handles an unrecognised answer gracefully without crashing or skipping.

### Steps
After PRD intake, when Q0 is shown:
```
X
```
(a letter not in the option list)

### Expected Results
- [ ] Skill does NOT crash or produce an error message
- [ ] Skill re-asks Q0 with a gentle prompt (e.g., "Please choose A, B, C, or D")
- [ ] Interview can continue normally after a valid answer is given

### Pass Criteria
All 3 items checked.

---

## TC-ORCH-03-06 — All interview answers are stored correctly across rounds

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |
| Config | `test-configs/run-a-python-api.md` |

### Objective
Verify that all 9 answers from the interview are accurately reflected in the
Config Summary — no answer lost, no answer swapped.

### Steps
1. Paste the Run A config block (skip interview)
2. Review the Config Summary output

### Expected Results
- [ ] `test_type: API` shown
- [ ] `language: Python` shown
- [ ] `protocol: REST/JSON` shown
- [ ] `auth: OAuth2 Client Credentials` shown
- [ ] `environments: dev, staging` shown
- [ ] `mock: both (real + WireMock)` shown
- [ ] `reporting: Allure` shown
- [ ] `ci: GitHub Actions` shown
- [ ] `data_strategy: mixed` shown

### Pass Criteria
All 9 items checked — any missing answer is a fail.

---

## TC-ORCH-03-07 — Python answer routes to automation-architect-python

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify that selecting Python at Round 1 causes the orchestrator to load and
execute the `automation-architect-python` skill for file generation.

### Steps
```
"I need a test automation framework"
C            # deferred PRD
A            # API test type
A            # Python language
```
Continue through all rounds and observe the scaffold output.

### Expected Results
- [ ] Scaffold Preview shows Python file names (`.py` extension, not `.java`)
- [ ] `requirements.txt` present (not `pom.xml`)
- [ ] Code snippets use Pydantic models, not Jackson
- [ ] Pytest fixtures shown, not TestNG annotations
- [ ] `conftest.py` present in file tree

### Pass Criteria
All 5 items checked.

---

## TC-ORCH-03-08 — Java answer routes to automation-architect-java

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |
| Config | `test-configs/run-d-java-api.md` |

### Objective
Verify that selecting Java at Round 1 causes the orchestrator to load and
execute the `automation-architect-java` skill for file generation.

### Steps
Paste the Run D config block (Java API).

### Expected Results
- [ ] Scaffold Preview shows Java file names (`.java` extension, not `.py`)
- [ ] `pom.xml` present (not `requirements.txt`)
- [ ] Code snippets use Jackson annotations (`@JsonProperty`), not Pydantic
- [ ] TestNG `@Test` annotations shown, not `def test_` functions
- [ ] `testng.xml` present in file tree

### Pass Criteria
All 5 items checked.
