# Test Config — Run A: Python + API + WireMock

Use this to skip the interview. Paste the block below into Claude Code as your first message.

---

```
Use the automation-architect skill with these answers — skip the interview and go straight to the Config Summary and Scaffold Preview:

test_type: API
language: Python
protocol: REST/JSON
auth: OAuth2 Client Credentials
environments: dev, staging
secret_management: .env files
mock: both (real + WireMock)
reporting: Allure
ci: GitHub Actions
data_strategy: mixed (fixtures + factory)
project_name: my-api-framework
```
