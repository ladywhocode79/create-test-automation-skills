# Test Config — Run F: Python + UI + Multi-Browser (Chrome + Firefox)

Covers: TC-PY-03-05 — verifies Browser Factory pattern is activated only
when browser_targets > 1. Companion to run-b which uses Chrome-only
(Browser Factory should NOT activate there).

---

```
Use the automation-architect skill with these answers — skip the interview and go straight to the Config Summary and Scaffold Preview:

test_type: UI
language: Python
browsers: Chrome + Firefox
execution: both (headless + headed via env var)
locator_strategy: data-testid
ui_auth: login via form
environments: dev, staging
secret_management: .env files
mock: real service only
reporting: Allure
ci: GitHub Actions
project_name: my-ui-framework-multi-browser
```

## Verification Checklist

After seeing the Scaffold Preview, confirm ALL of the following before responding [T] or [N]:

- [ ] Browser Factory pattern shown as [+] active (because 2 browsers selected)
- [ ] `layer_2_clients/ui/browser_factory.py` present in file tree
- [ ] Config Summary shows `browsers: Chrome + Firefox`
- [ ] Singleton Driver pattern also [+] active
- [ ] `config/driver_manager.py` present in file tree

## Contrast With run-b (Chrome Only)

Run this config immediately after run-b in the same session to confirm:
- run-b → Browser Factory [~] deferred (Chrome only)
- run-f → Browser Factory [+] active (Chrome + Firefox)
