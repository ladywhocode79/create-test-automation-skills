# TC-MOCK-03 — Strategy Pattern (Real / Mock Switching)

**Skill**: automation-architect-mock  
**Total TCs**: 4  
**Level**: L2  
**Model**: Haiku  
**Pre-req**: TC-MOCK-01 and TC-MOCK-02 passing

---

## TC-MOCK-03-01 — Strategy pattern present in Layer 2 client

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku (full mode for snippets) |
| Config | `test-configs/run-a-python-api.md` |

### Objective
Verify the Layer 2 HTTP client contains the Strategy pattern implementation
for switching between real and mock clients at runtime.

### Steps
```
{paste run-a-python-api.md block}
```
(no --test — need code snippets to verify pattern structure)

Inspect the Layer 2 client snippet.

### Expected Results
- [ ] A client factory or factory function present that reads `TEST_MODE` env var
- [ ] Two distinct client classes/implementations visible: one for real, one for mock
- [ ] Both clients implement the same interface or inherit from the same base class
- [ ] Strategy switching code shown (e.g., `if TEST_MODE == "mock": return MockClient()`)
- [ ] Reference to `automation-architect-mock/references/strategy-pattern-switch.md` pattern in annotation

### Pass Criteria
All 5 items checked.

### Debug Tips
- Only one client class → Strategy pattern not delegated to mock skill
- Both classes present but no shared interface → pattern violates the contract in `strategy-pattern-switch.md`

---

## TC-MOCK-03-02 — TEST_MODE=mock routes to WireMock client

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku (full mode) |
| Config | `test-configs/run-a-python-api.md` |

### Objective
Verify the generated code shows that `TEST_MODE=mock` routes all requests
through the WireMock-targeting client (pointing to localhost:8080).

### Steps
```
{paste run-a-python-api.md block}
```
Inspect Layer 2 client code snippet and `.env.example` snippet.

### Expected Results
- [ ] When `TEST_MODE=mock`, client uses `http://localhost:8080` as base URL
- [ ] `.env.example` contains `TEST_MODE=mock` as an example value
- [ ] WireMock client class does NOT make real external calls

### Pass Criteria
All 3 items checked.

---

## TC-MOCK-03-03 — TEST_MODE=real routes to real HTTP client

| Field | Value |
|---|---|
| Priority | P0 |
| Level | L2 |
| Type | Functional |
| Model | Haiku (full mode) |
| Config | `test-configs/run-a-python-api.md` |

### Objective
Verify that `TEST_MODE=real` routes through the standard HTTP client using
the `BASE_URL` from environment config (not localhost:8080).

### Steps
```
{paste run-a-python-api.md block}
```
Inspect Layer 2 client and `.env.example`.

### Expected Results
- [ ] When `TEST_MODE=real`, client uses `BASE_URL` from env config (not hardcoded)
- [ ] `.env.example` contains `TEST_MODE=real` as an option
- [ ] Real client class does NOT reference `localhost:8080`
- [ ] `BASE_URL` value in `.env.example` is a placeholder (e.g., `https://api.example.com`)

### Pass Criteria
All 4 items checked.

---

## TC-MOCK-03-04 — Real and mock clients share the same base class or interface

| Field | Value |
|---|---|
| Priority | P1 |
| Level | L2 |
| Type | Functional |
| Model | Haiku (full mode) |
| Config | `test-configs/run-a-python-api.md` |

### Objective
Verify the Strategy pattern is correctly implemented — both clients are
interchangeable because they implement the same contract.

### Steps
```
{paste run-a-python-api.md block}
```
Inspect the Layer 2 client snippet carefully.

### Expected Results

**Python track:**
- [ ] Both `RealApiClient` and `MockApiClient` (or equivalent names) inherit from `BaseApiClient`
- [ ] Both implement the same public methods (e.g., `get`, `post`, `put`, `delete`)

**Java track (run-d):**
- [ ] Both client implementations implement a shared Java interface (e.g., `ApiClient`)
- [ ] Interface defines all public request methods

### Pass Criteria
Both language-appropriate items checked for the config being tested.

### Debug Tips
- No shared base → Strategy pattern is incomplete; test will fail with `AttributeError` or `AbstractMethodError` at runtime when switching modes
- Fix in `automation-architect-mock/references/strategy-pattern-switch.md`
