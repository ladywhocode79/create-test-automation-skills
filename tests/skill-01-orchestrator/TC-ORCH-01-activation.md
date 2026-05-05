# TC-ORCH-01 — Skill Activation

**Skill**: automation-architect (Orchestrator)  
**Total TCs**: 9  
**Level**: L1  
**Model**: Haiku (all)  
**Pre-req**: `./sync.sh to-global` run so skills are in `~/.claude/skills/`

---

## Setup (run once before all TCs in this file)

```bash
cd /tmp && claude
# Switch to Haiku to keep cost low
/model claude-haiku-4-5-20251001
```

Start a **fresh session** for each TC — trigger phrases only fire once per session context.

---

## TC-ORCH-01-01 — "test automation framework" activates skill

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L1 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify the primary trigger phrase routes to the automation-architect skill.

### Steps
```
help me design a test automation framework
```

### Expected Results
- [ ] Response opens with "Welcome. I'm your Lead SDET for this session." (or equivalent)
- [ ] Next question is PRD intake (Round -1), NOT a generic coding answer
- [ ] Response does NOT contain "I can help you with that" generic opener

### Pass Criteria
All 3 items checked.

### Debug Tips
- Fail → check `description` field in `automation-architect/SKILL.md` for the phrase
- After fixing: `./sync.sh to-global`, then re-run

---

## TC-ORCH-01-02 — "api automation" activates skill

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L1 |
| Type | Functional |
| Model | Haiku |

### Steps
```
I need to set up api automation for my project
```

### Expected Results
- [ ] Skill activates — Lead SDET persona adopted
- [ ] PRD intake round presented as first question

### Pass Criteria
Both items checked.

---

## TC-ORCH-01-03 — "scaffold tests" activates skill

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L1 |
| Type | Functional |
| Model | Haiku |

### Steps
```
can you scaffold tests for a REST API
```

### Expected Results
- [ ] Skill activates — Lead SDET persona adopted
- [ ] PRD intake round presented as first question

### Pass Criteria
Both items checked.

---

## TC-ORCH-01-04 — "pytest framework" activates skill

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L1 |
| Type | Functional |
| Model | Haiku |

### Steps
```
I need a pytest framework for REST API testing
```

### Expected Results
- [ ] Skill activates — Lead SDET persona adopted
- [ ] PRD intake round presented as first question

### Pass Criteria
Both items checked.

---

## TC-ORCH-01-05 — "playwright framework" activates skill

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L1 |
| Type | Functional |
| Model | Haiku |

### Steps
```
set up a ui automation framework with playwright
```

### Expected Results
- [ ] Skill activates — Lead SDET persona adopted
- [ ] PRD intake round presented as first question

### Pass Criteria
Both items checked.

---

## TC-ORCH-01-06 — "restassured framework" activates skill

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L1 |
| Type | Functional |
| Model | Haiku |

### Steps
```
help me build a restassured framework in Java
```

### Expected Results
- [ ] Skill activates — Lead SDET persona adopted
- [ ] PRD intake round presented as first question

### Pass Criteria
Both items checked.

---

## TC-ORCH-01-07 — Non-trigger phrase does NOT activate skill

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L1 |
| Type | Negative |
| Model | Haiku |

### Objective
Verify that a generic phrase that is NOT in the trigger list does not fire the skill.

### Steps
```
can you help me write a Python function to sort a list
```

### Expected Results
- [ ] Response is a generic coding answer — NOT the Lead SDET persona
- [ ] NO PRD intake question presented
- [ ] NO reference to automation frameworks

### Pass Criteria
All 3 items checked.

### Debug Tips
- Fail (skill activates on generic phrase) → trigger description is too broad
- Narrow the `description` field in `automation-architect/SKILL.md`

---

## TC-ORCH-01-08 — Trigger phrase with `--test` flag gives compact output

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L1 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify `--test` suffix switches the skill to compact mode from the very first response.

### Steps
```
help me set up a Python API framework --test
```
Then answer the interview questions quickly (or paste a config block).  
At the preview, verify compact mode is active.

### Expected Results
- [ ] Skill activates with Lead SDET persona
- [ ] Config Summary shows only 5 key fields (not all 15)
- [ ] Scaffold Preview shows flat file list — no tree art, no annotations
- [ ] No code snippets in preview
- [ ] Confirmation shows `[T]` as an exit option alongside `[Y / P / E / N]`

### Pass Criteria
All 5 items checked.

---

## TC-ORCH-01-09 — Pre-scripted config block skips interview entirely

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L1 |
| Type | Functional |
| Model | Haiku |
| Config | `test-configs/run-a-python-api.md` |

### Objective
Verify that pasting a full config block with `--test` goes directly to the
Config Summary + Scaffold Preview without asking any interview questions.

### Steps
Paste the full contents of `test-configs/run-a-python-api.md` (the code block only) then append `--test`:
```
Use the automation-architect skill with these answers — skip the interview and go straight to the Config Summary and Scaffold Preview:

test_type: API
language: Python
...
project_name: my-api-framework --test
```

### Expected Results
- [ ] NO interview questions asked (Q0 through Q9 skipped)
- [ ] Response jumps directly to Config Summary
- [ ] Config Summary reflects all values from the pasted block
- [ ] Scaffold Preview follows immediately
- [ ] Confirmation prompt present at end

### Pass Criteria
All 5 items checked.

### Debug Tips
- If interview is still asked → skill is not reading the config block correctly
- Check Phase 1 logic in `automation-architect/SKILL.md` for pre-scripted config detection
