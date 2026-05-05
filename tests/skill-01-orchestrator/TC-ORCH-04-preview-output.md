# TC-ORCH-04 — Config Summary & Scaffold Preview Output

**Skill**: automation-architect (Orchestrator)  
**Total TCs**: 7  
**Level**: L2  
**Model**: Haiku  
**Pre-req**: Interview flow passing (TC-ORCH-03 suite green)

All TCs in this file use the `--test` flag so nothing is written to disk.
Use pre-scripted config blocks for speed.

---

## TC-ORCH-04-01 — Config Summary shows all 9 resolved answers

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |
| Config | `test-configs/run-a-python-api.md` |

### Objective
Verify the Config Summary section is complete — every resolved answer appears.

### Steps
```
{paste run-a-python-api.md block} --test
```
Inspect the "Config Summary" section of the output.

### Expected Results
- [ ] Section heading "Config Summary" (or equivalent) is present
- [ ] `test_type` value displayed
- [ ] `language` value displayed
- [ ] `protocol` value displayed
- [ ] `auth` value displayed
- [ ] `environments` value displayed
- [ ] `mock` value displayed
- [ ] `reporting` value displayed
- [ ] `ci` value displayed
- [ ] `data_strategy` value displayed

### Pass Criteria
All 10 items checked.

### Debug Tips
- Missing fields → check Phase 3 output logic in `automation-architect/SKILL.md`
- Wrong values → interview answer storage bug in Phase 1

---

## TC-ORCH-04-02 — Pattern list shows [+] active and [~] deferred correctly

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |
| Config | `test-configs/run-a-python-api.md` |

### Objective
Verify the design pattern activation table in the Config Summary matches the
activation conditions defined in `references/pattern-registry.md`.

### Steps
```
{paste run-a-python-api.md block} --test
```
Inspect the pattern list in the Config Summary.

Run A config activates:
- Singleton Auth `[+]` (because auth = OAuth2, not none)
- Factory Data `[+]` (always on)
- Strategy Mock `[+]` (because mock = both)
- Builder Payload `[~]` (always deferred)

### Expected Results
- [ ] Singleton Auth shown as `[+]` active
- [ ] Factory Data shown as `[+]` active
- [ ] Strategy Mock shown as `[+]` active
- [ ] Builder Payload shown as `[~]` deferred (NOT `[+]`)
- [ ] Singleton Driver NOT listed (API-only, no UI)
- [ ] Browser Factory NOT listed (API-only, no UI)

### Pass Criteria
All 6 items checked.

### Debug Tips
- Wrong activation → check condition in `references/pattern-registry.md`
- Pattern missing entirely → skill not reading the pattern registry

---

## TC-ORCH-04-03 — Scaffold Preview shows an annotated file tree

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |
| Config | `test-configs/run-a-python-api.md` |

### Objective
Verify the Scaffold Preview renders a properly formatted, annotated file tree
matching the format in `references/preview-format.md`.

### Steps
```
{paste run-a-python-api.md block} --test
```
Inspect the file tree section.

### Expected Results
- [ ] File tree is rendered (indented hierarchy visible)
- [ ] Layer 1 through Layer 4 directories are present
- [ ] Each file has a short annotation (comment after the filename)
- [ ] Directory names follow the 4-layer naming convention
- [ ] Config files section (`config/`) separate from layer directories

### Pass Criteria
All 5 items checked.

---

## TC-ORCH-04-04 — Preview file count is within expected range

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |
| Config | `test-configs/run-a-python-api.md` |

### Objective
Verify the total number of generated files matches the expected range for
each scaffold type. Python API with mock should be 18–24 files.

### Steps
```
{paste run-a-python-api.md block} --test
```
Count every file listed in the Scaffold Preview tree.

### Expected Results
- [ ] File count is between 18 and 24 (Python API + WireMock)
- [ ] No duplicate file names in the tree
- [ ] No placeholder files (e.g., `TODO.py`, `placeholder.java`)

### Pass Criteria
All 3 items checked.

### Reference — Expected Ranges by Config

| Config | Expected File Count |
|---|---|
| Python API + mock | 18–24 |
| Python UI + mock | 18–22 |
| Java Full-Stack, no mock | 22–27 |
| Java API + mock | 18–24 |

---

## TC-ORCH-04-05 — Code snippets shown for the correct layers

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L2 |
| Type | Functional |
| Model | Haiku (normal mode — no --test flag for this TC) |
| Config | `test-configs/run-a-python-api.md` |

### Objective
Verify code snippets appear for the key files — Pydantic model (L1),
base client (L2), service (L3), test (L4) — and are syntactically coherent.

### Steps
```
{paste run-a-python-api.md block}
```
(omit `--test` so full preview with snippets is shown)

### Expected Results
- [ ] At least one Layer 1 snippet (Pydantic model class definition)
- [ ] At least one Layer 2 snippet (BaseApiClient class or method)
- [ ] At least one Layer 3 snippet (Service method returning typed object)
- [ ] At least one Layer 4 snippet (pytest test function with assertion)
- [ ] All snippets are fenced code blocks with language tags (```python)
- [ ] No snippet contains placeholder text like `# TODO` or `pass` alone

### Pass Criteria
All 6 items checked.

---

## TC-ORCH-04-06 — Confirmation prompt [Y / P / E / N] present at end

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |
| Config | `test-configs/run-a-python-api.md` |

### Objective
Verify the skill always ends the preview with the write confirmation prompt
and never writes files without explicit user input.

### Steps
```
{paste run-a-python-api.md block} --test
```
Inspect the very end of the response.

### Expected Results
- [ ] Confirmation prompt is present at the end of the response
- [ ] Options `[Y]es`, `[P]artial`, `[E]dit`, `[N]o` are all listed
- [ ] Each option has a brief description of what it does
- [ ] No files are written to disk before user responds

### Pass Criteria
All 4 items checked.

### Debug Tips
- Missing confirmation → check Phase 3 → Phase 4 handoff in `SKILL.md`
- Files written without confirmation → critical S1 defect, check write instructions

---

## TC-ORCH-04-07 — `--test` flag suppresses code snippets in preview

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |
| Config | `test-configs/run-a-python-api.md` |

### Objective
Verify `--test` mode produces a compact preview with no code snippets,
saving ~60% of output tokens.

### Steps
Run the same config twice — once with and once without `--test`:
```
# Run 1 (full)
{paste run-a-python-api.md block}

# Run 2 (compact)
{paste run-a-python-api.md block} --test
```

### Expected Results
- [ ] Run 1 (full): code snippets present in preview
- [ ] Run 2 (compact): NO code snippets in preview
- [ ] Run 2 (compact): file list is flat (no tree art, no annotations)
- [ ] Run 2 (compact): Config Summary shows only the 5 key fields
- [ ] `[T]` exit option visible in Run 2 confirmation prompt

### Pass Criteria
All 5 items checked.
