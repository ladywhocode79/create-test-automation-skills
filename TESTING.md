# Testing Guide — automation-architect Skill Suite

There are 4 levels of testing, each catching different failure modes.
Run them in order — each level depends on the previous one passing.

---

## Token Optimisation

Full test runs are expensive because the skill loads many reference files and
outputs a verbose preview with code snippets. Use these strategies to cut
token usage significantly during development and iteration.

### Strategy 1 — Compact Mode (`--test` flag)

Append `--test` to any prompt. The skill switches to a compact output:
- Phase A shows only 5 key fields + pattern list (not all 15 fields)
- Phase B shows a flat file list with no tree art, no annotations
- Code snippets are completely suppressed
- Respond `[T]` to exit without writing files

```
# Normal run (high tokens):
"help me set up a Python API framework"

# Compact test run (low tokens):
"help me set up a Python API framework --test"
```

Savings: ~60% fewer output tokens per test run.

### Strategy 2 — Pre-scripted Answer Configs

Skip the 9-question interview by pasting a config block directly.
Config files are in `test-configs/`. Copy the block and paste as your first message.

| File | What it tests |
|---|---|
| `test-configs/run-a-python-api.md` | Python + API + WireMock + OAuth2 |
| `test-configs/run-b-python-ui.md` | Python + UI + Playwright + WireMock |
| `test-configs/run-c-java-fullstack.md` | Java + Full-Stack + No mock + GitLab CI |
| `test-configs/run-d-java-api.md` | Java + API + WireMock + Bearer auth |

Combine with `--test`:
```
{paste config block here} --test
```
This gets you straight to the compact preview in one exchange instead of 9+.

Savings: ~70% fewer input tokens by eliminating the interview rounds.

### Strategy 3 — Scope Tests to What Changed

Don't run the full matrix on every change. Match test scope to the change:

| What you changed | Minimum test to run |
|---|---|
| `automation-architect/SKILL.md` | All 3 interview runs (A, B, C) — routing logic changed |
| `references/pattern-registry.md` | Run A + Run C — check pattern activation |
| `references/preview-format.md` | Run A `--test` — check output format only |
| `automation-architect-python/SKILL.md` | Run A + Run B only |
| `automation-architect-python/references/api/*` | Run A only |
| `automation-architect-python/references/ui/*` | Run B only |
| `automation-architect-java/references/*` | Run C + Run D only |
| `automation-architect-mock/references/*` | Run A `[T]` — check mock files in preview |
| `references/ci-templates.md` | Run C only (GitLab CI selected) |

### Strategy 4 — Use Haiku for Flow Testing

Use Claude Haiku when testing interview routing and preview structure.
Switch to Sonnet only for Level 3 (generated code quality) checks.

```bash
# In Claude Code, switch model for a session:
/model claude-haiku-4-5-20251001
/model claude-sonnet-4-6
```

Haiku is ~10x cheaper per token. It can validate:
- Whether the skill activates from trigger phrases
- Whether Q0–Q9 are asked in the right order
- Whether the Config Summary reflects the right answers
- Whether the file list in the preview is correct

Use Sonnet for:
- Validating generated code is idiomatic and correct
- Checking that code snippets compile / parse correctly
- Level 3 and Level 4 testing

### Combined Approach for a Typical Fix

```
1. Edit the skill file in this repo
2. ./sync.sh to-global
3. Open Claude Code with Haiku:
   /model claude-haiku-4-5-20251001
4. Paste the relevant test-config + --test flag
5. Respond [T] — validates preview, zero files written
6. If correct → run Level 3 once with Sonnet to verify code quality
7. Commit + ./sync.sh (already done in step 2)
```

---

---

## Level 1 — Skill Activation

Verify the trigger description routes correctly.
Open Claude Code in **any directory** and type each phrase without mentioning the skill by name.

```bash
cd /tmp && claude
```

Test phrases (one at a time, fresh session each):

```
"help me design an api automation framework"
"I want to scaffold a test automation framework"
"set up a ui automation framework with playwright"
"how should I structure my api-tests?"
"I need a pytest framework for REST API testing"
```

**Pass:** Claude responds as a Lead SDET and asks Q0 (test type selection).
**Fail:** Claude gives a generic answer with no structured interview.

**Fix:** Check the `description` field in `automation-architect/SKILL.md` — the trigger phrase must appear there or be semantically close to what is listed.

---

## Level 2 — Interview Flow

Run through the full interview. Cover at least the 3 combinations below.

---

### Run A — Python + API + WireMock

| Question | Answer |
|---|---|
| Q0 Test Type | `[A]` API |
| Q1 Language | `[A]` Python |
| Q2 Protocol | `[A]` REST / JSON |
| Q3 Auth | `[B]` OAuth2 Client Credentials |
| Q4 Environments | dev, staging — `.env` files |
| Q5 Mock | `[C]` Both (real + mock) |
| Q6 Reporting | `[A]` Allure |
| Q7 CI | `[A]` GitHub Actions |
| Q8 Data strategy | `[D]` Mix (fixtures + factory) |

**Config Summary checks:**
- [ ] All answers reflected correctly
- [ ] Patterns: Singleton `[+]`, Factory `[+]`, Strategy `[+]`, Builder `[~]` deferred
- [ ] File count: 18–24 files

**Scaffold Preview checks:**
- [ ] `layer_1_models/api/` present, `layer_1_models/ui/` absent
- [ ] `config/auth_manager.py` present (OAuth2 selected)
- [ ] `mocks/` directory present (mock selected)
- [ ] Code snippets shown: Pydantic model, service method, pytest test, AuthManager
- [ ] Confirmation prompt `[Y / P / E / N]` shown

---

### Run B — Python + UI Only

| Question | Answer |
|---|---|
| Q0 Test Type | `[B]` UI |
| Q1 Language | `[A]` Python |
| Q2 Browsers | `[A]` Chrome only |
| Q3 Execution | `[C]` Both (headless + headed) |
| Q4 Locators | `[A]` data-testid |
| Q5 UI Auth | `[C]` Both (inject + login) |
| Q6 Environments | dev only |
| Q7 Mock | `[B]` WireMock |
| Q8 Reporting | `[A]` Allure |
| Q9 CI | `[A]` GitHub Actions |

**Scaffold Preview checks:**
- [ ] `layer_3_pages/` present, `layer_3_services/` absent
- [ ] `layer_2_clients/ui/` present, `layer_2_clients/api/` absent
- [ ] `config/driver_manager.py` present, `config/auth_manager.py` absent
- [ ] Browser Factory pattern **not** activated (Chrome only = single browser)
- [ ] Stack shows Playwright, not requests/Pydantic

---

### Run C — Java + Full-Stack

| Question | Answer |
|---|---|
| Q0 Test Type | `[C]` Full-Stack |
| Q1 Language | `[B]` Java |
| Q2 API Protocol | `[A]` REST |
| Q3 API Auth | `[F]` None / Public |
| Q2 UI Browsers | `[B]` Chrome + Firefox |
| Q3 UI Execution | `[C]` Both |
| Q4 Locators | `[A]` data-testid |
| Q5 UI Auth | `[A]` Login via form |
| Q6 Environments | staging, prod — CI secrets |
| Q7 Mock | `[A]` Real service only |
| Q8 Reporting | `[A]` Allure |
| Q9 CI | `[B]` GitLab CI |

**Scaffold Preview checks:**
- [ ] Both `layer_3_services/` and `layer_3_pages/` present
- [ ] Both `layer_4_tests/api/` and `layer_4_tests/ui/` present
- [ ] `mocks/` absent (real service selected)
- [ ] `config/auth_manager.java` absent (no auth selected)
- [ ] Browser Factory activated (2 browsers selected)
- [ ] GitLab CI template shown, not GitHub Actions
- [ ] `pom.xml` shown, not `requirements.txt`

---

## Level 3 — Generated Code Quality

For **Run A**, respond `[Y]` and let the skill write files. Then run these checks.

```bash
mkdir /tmp/test-scaffold && cd /tmp/test-scaffold
claude   # run through interview Run A, then confirm [Y]
```

### Python syntax

```bash
python -m py_compile config/env_config.py
python -m py_compile config/auth_manager.py
python -m py_compile layer_1_models/api/user_model.py
python -m py_compile layer_2_clients/api/base_api_client.py
python -m py_compile layer_3_services/user_service.py
python -m py_compile layer_4_tests/api/test_user_api.py
echo "All files parse correctly"
```

### Layer dependency enforcement

```bash
pip install import-linter
lint-imports --config .importlinter
# Expected: zero violations
```

### Pytest collection (no tests run — verifies imports resolve)

```bash
pip install -r requirements.txt
pytest layer_4_tests/ --collect-only
# Expected: tests collected, zero import errors
```

### WireMock stubs load correctly

```bash
docker-compose up -d wiremock
sleep 3
curl -s http://localhost:8080/__admin/health
# Expected: {"status":"Running",...}

curl -s http://localhost:8080/__admin/mappings | python -m json.tool | grep '"name"'
# Expected: stub names listed — post-user-success, get-user-by-id-success, etc.

docker-compose down
```

### Run tests against WireMock

```bash
cp .env.example .env
# Edit .env: BASE_URL=http://localhost:8080  TEST_MODE=mock

docker-compose up -d wiremock
pytest layer_4_tests/api/ -v --tb=short
# Expected: all tests pass

docker-compose down
```

### View Allure report

```bash
allure serve allure-results/
# Expected: report opens in browser showing test results with steps
```

---

## Level 4 — Edge Case Flows

### `[E]` Edit config

At the confirmation prompt, type `E`.
- [ ] Skill asks which answer to change — does not restart the full interview
- [ ] Preview regenerates correctly with the updated value only

### `[P]` Partial write

At the confirmation prompt, type `P`.
- [ ] Skill asks which layers/files to write first
- [ ] Writes only the requested subset
- [ ] Offers to write remaining files afterwards

### `[N]` No write

At the confirmation prompt, type `N`.
- [ ] All file contents output as fenced code blocks
- [ ] Zero files written to disk
- [ ] Each block has the file path as a header comment

### `[Z]` Other language

At Q1, type `Z` or describe a language not in the list (e.g. "Go" or "C#").
- [ ] Skill acknowledges the language and applies the abstract Track Contract
- [ ] Generates pseudocode for all 4 layers in the chosen language
- [ ] Produces a `TRACK-STUB.md` explaining how to contribute the full track

---

## Full Test Matrix

| Run | Type | Language | Mock | Key things to verify |
|---|---|---|---|---|
| A | API | Python | WireMock | Pydantic models, requests client, pytest, AuthManager, WireMock stubs |
| B | UI | Python | WireMock | Playwright session, Page Objects, no API service files present |
| C | Full-Stack | Java | None | Both services + pages, pom.xml, GitLab CI, no mocks/ directory |
| D | API | Java | WireMock | RestAssured, TestNG, Jackson models, WireMock stubs |
| E | API | Python | None | No mocks/ directory, no docker-compose.yml |

Run A is the most important — it covers the most patterns. Run B verifies the UI profile is properly isolated. Run C verifies Full-Stack composition and Java track.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Skill does not activate | Trigger phrase missing from `description` field | Add phrase to `automation-architect/SKILL.md` frontmatter, then `./sync.sh to-global` |
| Wrong files in preview | Profile loading logic in track SKILL.md | Check `test_type` → profile routing table in track `SKILL.md` |
| Pattern appears when it should not | Activation condition too broad | Tighten condition in `automation-architect/references/pattern-registry.md` |
| Python syntax error in generated file | Typo in reference template code block | Fix in relevant `references/**/*.md` file, then `./sync.sh to-global` |
| WireMock stubs not loading | JSON syntax error in stub file | Run `docker-compose logs wiremock` to see the parse error |
| Pytest import error after scaffold | Wrong layer importing from wrong layer | Check `.importlinter` config and fix the import in the generated file |
| Allure report not generated | `--alluredir` flag missing from pytest.ini | Check `addopts` in generated `pytest.ini` |

---

## Updating Both Copies After a Fix

```bash
# 1. Edit the skill file in this repo
# 2. Sync to the global Claude skills directory
./sync.sh to-global

# 3. Re-run the relevant test level to confirm the fix
# 4. Commit
git add -A && git commit -m "fix: <description of what was fixed>"
```
