# TC-MOCK-01 — WireMock Docker Configuration

**Skill**: automation-architect-mock  
**Total TCs**: 4  
**Level**: L2 (preview checks) + L3 (runtime checks)  
**Model**: Haiku (L2); shell only (L3)  
**Pre-req**: Orchestrator routing passing; Docker Desktop running for L3 TCs

---

## TC-MOCK-01-01 — docker-compose.yml includes WireMock service on port 8080

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku |
| Config | `test-configs/run-a-python-api.md` (mock=both) |

### Objective
Verify that selecting any mock mode (both or mock-only) generates a
`docker-compose.yml` with WireMock configured on the standard port.

### Steps
```
{paste run-a-python-api.md block} --test
```
Inspect the Scaffold Preview for the docker-compose.yml entry.

### Expected Results
- [ ] `docker-compose.yml` present in file tree root
- [ ] WireMock service defined (annotation or snippet shows `wiremock` service name)
- [ ] Port 8080 mapped (visible in annotation: `8080:8080`)
- [ ] WireMock image specified (`wiremock/wiremock` or equivalent)
- [ ] Volume mount for stubs directory shown (`./mocks/stubs:/home/wiremock/mappings`)

### Pass Criteria
All 5 items checked.

### Debug Tips
- docker-compose.yml missing → mock mode not being forwarded to automation-architect-mock
- Port wrong → check `automation-architect-mock/references/wiremock-docker-setup.md`

---

## TC-MOCK-01-02 — WireMock health endpoint returns Running status

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L3 |
| Type | Functional |
| Model | N/A (shell) |

### Preconditions
- Files written to disk (TC-PY-04 or TC-JAVA-04 setup step complete)
- Docker Desktop running
- Port 8080 available

### Steps
```bash
cd /tmp/test-py-quality    # or /tmp/test-java-quality
docker-compose up -d wiremock
sleep 3
curl -s http://localhost:8080/__admin/health
```

### Expected Results
- [ ] Response is valid JSON
- [ ] `"status":"Running"` present in response
- [ ] No connection refused error
- [ ] Response time under 2 seconds

### Pass Criteria
All 4 items checked.

### Cleanup
```bash
docker-compose down
```

---

## TC-MOCK-01-03 — docker-compose up -d starts WireMock without errors

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L3 |
| Type | Functional |
| Model | N/A (shell) |

### Objective
Verify docker-compose.yml syntax is valid and WireMock container starts cleanly.

### Steps
```bash
cd /tmp/test-py-quality
docker-compose up -d wiremock 2>&1
echo "Exit code: $?"
docker-compose ps
docker-compose logs wiremock | head -30
```

### Expected Results
- [ ] `docker-compose up` exits with code 0
- [ ] `docker-compose ps` shows wiremock container with `Up` status
- [ ] No `Error` or `failed` in docker-compose logs
- [ ] WireMock log shows "WireMock standalone started" or equivalent startup message

### Pass Criteria
All 4 items checked.

### Debug Tips
- Exit code non-zero → YAML syntax error in docker-compose.yml; check `wiremock-docker-setup.md` template
- Container exits immediately → WireMock image version incompatibility or missing stubs volume path

### Cleanup
```bash
docker-compose down
```

---

## TC-MOCK-01-04 — No-mock mode: docker-compose.yml NOT generated

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L2 |
| Type | Negative |
| Model | Haiku |
| Config | `test-configs/run-e-python-api-no-mock.md` |

### Objective
Verify that choosing "real service only" produces zero mock infrastructure files.

### Steps
```
{paste run-e-python-api-no-mock.md block} --test
```
Inspect the entire Scaffold Preview.

### Expected Results
- [ ] `docker-compose.yml` ABSENT from file tree
- [ ] `mocks/` directory ABSENT from file tree
- [ ] No WireMock stub files listed
- [ ] Strategy Mock pattern shown as `[~]` deferred or absent
- [ ] `config/env_config.py` shows real `BASE_URL` (not `localhost:8080`)

### Pass Criteria
All 5 items checked.
