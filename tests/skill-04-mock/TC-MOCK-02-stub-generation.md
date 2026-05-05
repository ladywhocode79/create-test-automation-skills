# TC-MOCK-02 — WireMock Stub Generation

**Skill**: automation-architect-mock  
**Total TCs**: 5  
**Level**: L2 (preview) + L3 (runtime)  
**Model**: Haiku (L2); shell only (L3)  
**Config**: `test-configs/run-a-python-api.md`  
**Pre-req**: TC-MOCK-01 passing

---

## TC-MOCK-02-01 — Stub file names follow verb-resource-scenario convention

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify stub JSON files are named using the `verb-resource-scenario.json` pattern.

### Steps
```
{paste run-a-python-api.md block} --test
```
Inspect the `mocks/stubs/` section of the Scaffold Preview.

### Expected Results
- [ ] All stub files listed under `mocks/stubs/`
- [ ] Each file name follows `verb-resource-scenario.json` (e.g., `post-users-success.json`)
- [ ] No generic names like `stub1.json`, `mock.json`, or `test.json`
- [ ] At least 4 stub files present (covering the main CRUD operations)

### Pass Criteria
All 4 items checked.

### Debug Tips
- Generic names → naming convention not applied; check `automation-architect-mock/SKILL.md` stub naming section
- Wrong prefix → verb should be HTTP method lowercase (get, post, put, delete, patch)

---

## TC-MOCK-02-02 — POST stub returns correct response body and 201 status

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku (full mode — no --test to see snippet) |

### Objective
Verify the POST stub JSON includes the correct HTTP status (201) and a
response body that matches the resource schema.

### Steps
```
{paste run-a-python-api.md block}
```
(full mode, no --test, so code snippets are visible)  
Find the `post-users-success.json` snippet in the preview.

### Expected Results
- [ ] `"status": 201` in the stub response
- [ ] Response body is a valid JSON object (not empty `{}`)
- [ ] Response body includes an `id` field (resource was created)
- [ ] `"method": "POST"` in the request matcher
- [ ] URL pattern matches the POST endpoint path (e.g., `/users` or `/api/users`)

### Pass Criteria
All 5 items checked.

### Debug Tips
- Status 200 instead of 201 → stub template uses wrong default; fix in `wiremock-docker-setup.md`
- Empty body → stub template missing response body generation

---

## TC-MOCK-02-03 — GET stub uses URL pattern matching, not exact match

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku (full mode) |

### Objective
Verify GET-by-ID stubs use `urlPathPattern` with a regex, not a hard-coded ID.
Hard-coded IDs make stubs brittle — they only match `GET /users/123` not `GET /users/456`.

### Steps
```
{paste run-a-python-api.md block}
```
Find the `get-user-by-id-success.json` snippet.

### Expected Results
- [ ] Stub uses `"urlPathPattern"` (not `"url"` or `"urlPath"`)
- [ ] Pattern contains a regex for the ID segment (e.g., `/users/[0-9a-f-]+`)
- [ ] `"method": "GET"` in the request matcher

### Pass Criteria
All 3 items checked.

### Debug Tips
- Hard-coded URL → stub template uses `"url"` instead of `"urlPathPattern"`
- Fix in `automation-architect-mock/references/wiremock-docker-setup.md`

---

## TC-MOCK-02-04 — Error stubs generated alongside each happy-path stub

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |

### Objective
Verify that for each happy-path stub, corresponding error-path stubs are also generated
(404, 422, 500 as appropriate).

### Steps
```
{paste run-a-python-api.md block} --test
```
List all files in `mocks/stubs/` from the Scaffold Preview.

### Expected Results
- [ ] `post-users-success.json` present
- [ ] At least one POST error stub present (e.g., `post-users-validation-error.json` — 422)
- [ ] `get-user-by-id-success.json` present
- [ ] `get-user-by-id-not-found.json` present — 404
- [ ] At least one 500-level error stub present (server error scenario)
- [ ] Total stub count ≥ happy-path count × 2 (at least as many error stubs as success stubs)

### Pass Criteria
All 6 items checked.

### Debug Tips
- Only happy-path stubs → error stub generation missing from `automation-architect-mock/SKILL.md`
- Check the edge-case stub generation instructions in the mock skill

---

## TC-MOCK-02-05 — All stubs load into running WireMock without mapping errors

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L3 |
| Type | Functional |
| Model | N/A (shell) |

### Preconditions
- Files written to disk (`/tmp/test-py-quality` or `/tmp/test-java-quality`)
- Docker Desktop running

### Steps
```bash
cd /tmp/test-py-quality
docker-compose up -d wiremock
sleep 3

# Check all mappings loaded
MAPPING_COUNT=$(curl -s http://localhost:8080/__admin/mappings | python -m json.tool | grep '"id"' | wc -l)
echo "Stubs loaded: $MAPPING_COUNT"

# Check for any stub load errors
docker-compose logs wiremock | grep -i "error\|invalid\|warn"

# List all stub names
curl -s http://localhost:8080/__admin/mappings | python -m json.tool | grep '"name"'
```

### Expected Results
- [ ] Mapping count ≥ 6 (at least 3 success + 3 error stubs)
- [ ] Zero `error` or `invalid` lines in WireMock logs
- [ ] All stub names visible in the mappings list
- [ ] No stub listed with empty name `"name": ""`

### Pass Criteria
All 4 items checked.

### Cleanup
```bash
docker-compose down
```
