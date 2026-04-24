# automation-architect — Claude Code Skill Suite

A multi-skill Claude Code suite that acts as a **Lead SDET**, interviewing
users and scaffolding a production-grade, layered test automation framework.

## Skills

| Skill | Purpose |
|---|---|
| `automation-architect` | Orchestrator — discovery interview, routing, preview-first output |
| `automation-architect-python` | Python track — Pytest, Pydantic v2, requests, Playwright |
| `automation-architect-java` | Java track — TestNG, RestAssured, Jackson, Selenium WebDriver |
| `automation-architect-mock` | Cross-cutting — WireMock Docker, stubs, Strategy pattern |
| `automation-architect-nfr` | Phase 2 stub — gated NFR skill (perf / security / chaos) |

## Architecture

The framework enforces a **4-layer architecture** across all language tracks:

```
Layer 4 — Test Layer        (assertions, test scenarios)
Layer 3 — Service/Page      (API service classes, UI page objects)
Layer 2 — Client Layer      (HTTP session, browser session)
Layer 1 — Data/Model Layer  (schemas, validators, factories, locators)
```

Supports **API**, **UI**, and **Full-Stack (API + UI)** test types.

## Trigger Phrases

The skill activates when you mention any of:
`test automation`, `automation framework`, `api automation`, `ui automation`,
`scaffold tests`, `test architecture`, `pytest framework`, `playwright framework`,
`restassured framework`, `SDET framework`, `choose test stack`

## Installation (Global)

```bash
# Copy skills to Claude Code global skills directory:
cp -r automation-architect* ~/.claude/skills/
```

## Usage

In any Claude Code session:
```
"help me design an api automation framework"
"scaffold a UI automation framework in Python"
"set up a full-stack test framework"
```

The skill will:
1. Interview you across 3 rounds (test type, language, stack config)
2. Show a full scaffold preview with annotated file tree + key code snippets
3. Wait for your confirmation `[Y / P / E / N]`
4. Write all files to your project directory

## Syncing Changes

This repo is a mirror of `~/.claude/skills/automation-architect*`.
Use the sync script to keep both copies in step:

```bash
# Push local changes to global Claude skills:
./sync.sh to-global

# Pull global Claude skills to this repo:
./sync.sh to-repo
```

## Phase Roadmap

| Phase | Scope | Status |
|---|---|---|
| 1 | Functional API + UI automation (Python + Java) | Complete |
| 2 | Non-Functional: load, security, chaos testing | Gated (see `automation-architect-nfr/`) |

### Phase 2 Gate Conditions

Phase 2 activates when ALL of these are true:
1. API test suite covers >= 80% of planned endpoints
2. CI pipeline is green for 5+ consecutive runs
3. User explicitly triggers `/automation-architect-nfr`

## Extending with a New Language Track

1. Create `automation-architect-{language}/SKILL.md`
2. Set `user-invocable: false` in frontmatter
3. Follow the Track Contract: `automation-architect/references/track-contract.md`
4. Copy to `~/.claude/skills/` — the orchestrator discovers it automatically
