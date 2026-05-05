# Test Config — Run E: Python + API + No Mock

Covers: TC-MOCK-01-04 — verifies no `docker-compose.yml` or `mocks/` directory
is generated when mock mode is set to "real service only".

---

```
Use the automation-architect skill with these answers — skip the interview and go straight to the Config Summary and Scaffold Preview:

test_type: API
language: Python
protocol: REST/JSON
auth: Bearer/JWT
environments: dev, staging
secret_management: .env files
mock: real service only
reporting: Allure
ci: GitHub Actions
data_strategy: factory-generated
project_name: my-api-framework-no-mock
```

## Verification Checklist

After seeing the Scaffold Preview, confirm ALL of the following before responding [T] or [N]:

- [ ] `mocks/` directory is ABSENT from the file tree
- [ ] `docker-compose.yml` is ABSENT from the file tree
- [ ] No WireMock reference in Layer 2 client code snippet
- [ ] `config/env_config.py` has `BASE_URL` pointing to real service (not localhost:8080)
- [ ] Strategy pattern NOT listed in active patterns [+]
- [ ] Config Summary shows `mock: real service only`
