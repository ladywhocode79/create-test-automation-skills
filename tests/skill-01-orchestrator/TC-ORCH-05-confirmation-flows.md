# TC-ORCH-05 — Confirmation Flows [Y / P / E / N / Z]

**Skill**: automation-architect (Orchestrator)  
**Total TCs**: 5  
**Level**: L4  
**Model**: Haiku for flow checks; Sonnet for [Y] write verification  
**Pre-req**: Preview output passing (TC-ORCH-04 suite green)

---

## TC-ORCH-05-01 — [Y] writes all scaffold files to disk

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L4 |
| Type | Functional |
| Model | Sonnet |
| Config | `test-configs/run-a-python-api.md` |

### Objective
Verify confirming with `[Y]` writes every file shown in the Scaffold Preview
to the current working directory with correct paths.

### Preconditions
- Working directory is empty (`/tmp/test-orch-y/`)
- Skill has shown Config Summary and Scaffold Preview

### Steps
```bash
mkdir /tmp/test-orch-y && cd /tmp/test-orch-y
claude
```
```
{paste run-a-python-api.md block}
```
At the confirmation prompt:
```
Y
```

### Post-write verification
```bash
# Count files written
find /tmp/test-orch-y -type f | wc -l

# Spot-check key paths
ls /tmp/test-orch-y/layer_1_models/api/
ls /tmp/test-orch-y/layer_2_clients/api/
ls /tmp/test-orch-y/layer_3_services/
ls /tmp/test-orch-y/layer_4_tests/api/
ls /tmp/test-orch-y/config/
ls /tmp/test-orch-y/mocks/
```

### Expected Results
- [ ] File count on disk matches file count shown in preview (within ±1)
- [ ] `layer_1_models/api/` directory exists and contains at least one `.py` file
- [ ] `layer_2_clients/api/base_api_client.py` exists
- [ ] `layer_3_services/` directory exists and contains at least one `.py` file
- [ ] `layer_4_tests/api/` directory exists and contains at least one `test_*.py` file
- [ ] `config/env_config.py` exists
- [ ] `config/auth_manager.py` exists (OAuth2 selected)
- [ ] `mocks/` directory exists (mock=both selected)
- [ ] `requirements.txt` exists

### Pass Criteria
All 9 items checked.

### Cleanup
```bash
rm -rf /tmp/test-orch-y
```

---

## TC-ORCH-05-02 — [N] outputs all files as code blocks, writes nothing

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L4 |
| Type | Edge Case |
| Model | Haiku |
| Config | `test-configs/run-b-python-ui.md` |

### Objective
Verify [N] dumps all file contents inline as fenced code blocks with
path headers — and that zero files are written to disk.

### Preconditions
- Working directory is empty or irrelevant (nothing should be written)

### Steps
```bash
mkdir /tmp/test-orch-n && cd /tmp/test-orch-n
claude
```
```
{paste run-b-python-ui.md block}
```
At confirmation:
```
N
```

### Post-response verification
```bash
# Directory should be empty (no files written)
find /tmp/test-orch-n -type f | wc -l
# Expected: 0
```

### Expected Results
- [ ] Response contains fenced code blocks for every file in the preview
- [ ] Each code block is preceded by the file path as a header or comment
- [ ] `find /tmp/test-orch-n -type f` returns 0 files
- [ ] No `requirements.txt`, `conftest.py`, or any other file on disk

### Pass Criteria
All 4 items checked.

### Cleanup
```bash
rm -rf /tmp/test-orch-n
```

---

## TC-ORCH-05-03 — [E] edit single field without restarting interview

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L4 |
| Type | Edge Case |
| Model | Haiku |
| Config | `test-configs/run-a-python-api.md` |

### Objective
Verify [E] allows changing exactly one config answer and regenerates only
what changed — without re-asking all 9 questions.

### Steps
```
{paste run-a-python-api.md block} --test
```
At confirmation:
```
E
```
When skill asks what to change:
```
Change auth from OAuth2 to Bearer/JWT
```
After the skill acknowledges and regenerates:

### Expected Results
- [ ] Skill asks which field to change (does NOT restart the full interview)
- [ ] After specifying "auth → Bearer/JWT", Config Summary updates that field only
- [ ] All other config values remain unchanged from the original
- [ ] Preview regenerates — `auth_manager.py` still present (Bearer still requires it)
- [ ] Confirmation prompt re-presented after regeneration

### Pass Criteria
All 5 items checked.

### Debug Tips
- Full interview restarts → [E] handler in `SKILL.md` Phase 3 not implemented correctly
- Other fields change → state mutation bug in interview answer storage

---

## TC-ORCH-05-04 — [P] partial write by layer, offers remaining files

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L4 |
| Type | Edge Case |
| Model | Sonnet |
| Config | `test-configs/run-a-python-api.md` |

### Objective
Verify [P] writes a user-specified subset of layers/files and then offers
to write the rest separately.

### Steps
```bash
mkdir /tmp/test-orch-p && cd /tmp/test-orch-p
claude
```
```
{paste run-a-python-api.md block}
```
At confirmation:
```
P
```
When skill asks which part to write:
```
Write only Layer 1 and Layer 2 for now
```

### Post-write verification
```bash
ls /tmp/test-orch-p/layer_1_models/
ls /tmp/test-orch-p/layer_2_clients/
ls /tmp/test-orch-p/layer_3_services/ 2>/dev/null || echo "L3 absent — correct"
ls /tmp/test-orch-p/layer_4_tests/    2>/dev/null || echo "L4 absent — correct"
```

### Expected Results
- [ ] Skill asks which layers/files to write first
- [ ] `layer_1_models/` written to disk
- [ ] `layer_2_clients/` written to disk
- [ ] `layer_3_services/` NOT written (not requested)
- [ ] `layer_4_tests/` NOT written (not requested)
- [ ] After writing, skill offers to write the remaining layers

### Pass Criteria
All 6 items checked.

### Cleanup
```bash
rm -rf /tmp/test-orch-p
```

---

## TC-ORCH-05-05 — [Z] Other language generates pseudocode + TRACK-STUB.md

| Field | Value |
|---|---|
| Priority | P2 |
| Level | L4 |
| Type | Edge Case |
| Model | Haiku |

### Objective
Verify that typing `Z` or specifying an unlisted language (Go, C#, Ruby)
at the language selection question produces pseudocode for all 4 layers
and a TRACK-STUB.md contribution guide.

### Steps
```
"I need a test automation framework"
C          # deferred PRD
A          # API test type
```
At language selection (Round 1):
```
Z
```
When skill asks which language:
```
Go
```

### Expected Results
- [ ] Skill acknowledges Go is not a built-in track
- [ ] Skill applies the abstract Track Contract (`references/track-contract.md`)
- [ ] Pseudocode scaffold generated for all 4 layers in Go style
- [ ] `TRACK-STUB.md` file included in the output describing how to contribute a full Go track
- [ ] No `.py` or `.java` files generated

### Pass Criteria
All 5 items checked.

### Debug Tips
- Skill falls back to Python instead → [Z] handler in `SKILL.md` not catching the unknown language
- TRACK-STUB.md missing → check the track-contract reference in the orchestrator skill
