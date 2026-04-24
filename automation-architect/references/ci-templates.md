# CI/CD Pipeline Templates

Complete pipeline templates for each supported CI platform.
The orchestrator selects and parameterizes the correct template based on
the user's resolved config (test_type, mock, reporting, language).

All templates follow these non-negotiable rules:
- Secrets always come from the CI platform's secret store, never inline YAML
- API and UI jobs are always separate jobs within the same workflow
- WireMock starts as a service/step before any test runs (if mock selected)
- Browser install step included in UI jobs (never assumed pre-installed)
- Artifact upload uses `if: always()` (reports captured even on failure)
- Dependency layer enforcement lint step included

---

## GitHub Actions

### API Tests Only

```yaml
# .github/workflows/api-tests.yml
name: API Automation Tests

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  api-test:
    name: API Test Suite
    runs-on: ubuntu-latest

    env:
      BASE_URL:      ${{ secrets.API_BASE_URL }}
      TOKEN_URL:     ${{ secrets.TOKEN_URL }}
      CLIENT_ID:     ${{ secrets.CLIENT_ID }}
      CLIENT_SECRET: ${{ secrets.CLIENT_SECRET }}
      TEST_MODE:     ${{ vars.TEST_MODE || 'mock' }}
      LOG_LEVEL:     INFO

    # WireMock service (included if mock selected)
    services:
      wiremock:
        image: wiremock/wiremock:3.3.1
        ports:
          - 8080:8080
        options: >-
          --health-cmd "curl -f http://localhost:8080/__admin/health"
          --health-interval 5s
          --health-timeout 3s
          --health-retries 10

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      # --- Python track ---
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: pip

      - name: Install dependencies
        run: pip install -r requirements.txt

      # --- Java track (replace above two steps) ---
      # - name: Set up Java
      #   uses: actions/setup-java@v4
      #   with:
      #     java-version: "21"
      #     distribution: temurin
      #     cache: maven
      #
      # - name: Install dependencies
      #   run: mvn dependency:resolve -q

      - name: Lint layer dependencies
        # Python: import-linter enforces no cross-layer imports
        run: lint-imports --config .importlinter
        # Java: ArchUnit tests run as part of test suite (no separate step needed)

      - name: Run API tests
        run: |
          # Python
          pytest layer_4_tests/api/ -v -m "api" --alluredir=allure-results
          # Java
          # mvn test -Dgroups=api -Dsurefire.rerunFailingTestsCount=1

      - name: Upload Allure results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: allure-results-api-${{ github.run_number }}
          path: allure-results/
          retention-days: 30

      - name: Publish Allure report
        uses: simple-elf/allure-report-action@master
        if: always()
        with:
          allure_results: allure-results
          allure_history: allure-history
```

### UI Tests Only

```yaml
# .github/workflows/ui-tests.yml
name: UI Automation Tests

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  ui-test:
    name: UI Test Suite — ${{ matrix.browser }}
    runs-on: ubuntu-latest

    strategy:
      fail-fast: false
      matrix:
        browser: [chromium]          # expand to [chromium, firefox] for cross-browser

    env:
      AUT_BASE_URL:  ${{ secrets.AUT_BASE_URL }}
      BACKEND_URL:   http://localhost:8080
      BROWSER:       ${{ matrix.browser }}
      HEADLESS:      true
      TEST_MODE:     mock
      LOG_LEVEL:     INFO

    services:
      wiremock:
        image: wiremock/wiremock:3.3.1
        ports:
          - 8080:8080
        options: >-
          --health-cmd "curl -f http://localhost:8080/__admin/health"
          --health-interval 5s
          --health-timeout 3s
          --health-retries 10

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      # --- Python + Playwright ---
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: pip

      - name: Install Python dependencies
        run: pip install -r requirements.txt

      - name: Install Playwright browsers
        run: playwright install ${{ matrix.browser }} --with-deps

      # --- Java + Selenium (replace above) ---
      # - name: Set up Java
      #   uses: actions/setup-java@v4
      #   with:
      #     java-version: "21"
      #     distribution: temurin
      # - name: Install WebDriverManager (auto-downloads drivers)
      #   run: echo "WebDriverManager handles browser drivers automatically"

      - name: Run UI tests
        run: |
          # Python
          pytest layer_4_tests/ui/ -v -m "ui" --alluredir=allure-results
          # Java
          # mvn test -Dgroups=ui -Dbrowser=${{ matrix.browser }}

      - name: Upload screenshots (on failure)
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: screenshots-${{ matrix.browser }}-${{ github.run_number }}
          path: screenshots/
          retention-days: 7

      - name: Upload Allure results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: allure-results-ui-${{ matrix.browser }}-${{ github.run_number }}
          path: allure-results/
          retention-days: 30
```

### Full-Stack (API + UI combined workflow)

```yaml
# .github/workflows/full-stack-tests.yml
name: Full-Stack Automation Tests

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  api-test:
    name: API Test Suite
    uses: ./.github/workflows/api-tests.yml
    secrets: inherit

  ui-test:
    name: UI Test Suite
    uses: ./.github/workflows/ui-tests.yml
    secrets: inherit
    needs: api-test          # run UI only after API passes (optional, remove for parallel)
```

---

## GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - test

variables:
  TEST_MODE: mock
  HEADLESS: "true"
  LOG_LEVEL: INFO

.wiremock_service: &wiremock_service
  services:
    - name: wiremock/wiremock:3.3.1
      alias: wiremock
  variables:
    BASE_URL: http://wiremock:8080   # internal service DNS in GitLab CI

api-tests:
  stage: test
  image: python:3.12-slim            # or maven:3.9-eclipse-temurin-21 for Java
  <<: *wiremock_service
  variables:
    TOKEN_URL:     $TOKEN_URL        # from GitLab CI/CD variables
    CLIENT_ID:     $CLIENT_ID
    CLIENT_SECRET: $CLIENT_SECRET
  script:
    - pip install -r requirements.txt
    - pytest layer_4_tests/api/ -v --alluredir=allure-results
  artifacts:
    when: always
    paths:
      - allure-results/
    expire_in: 30 days

ui-tests:
  stage: test
  image: mcr.microsoft.com/playwright/python:v1.44.0-jammy
  <<: *wiremock_service
  variables:
    AUT_BASE_URL:  $AUT_BASE_URL
    BROWSER:       chromium
  script:
    - pip install -r requirements.txt
    - pytest layer_4_tests/ui/ -v --alluredir=allure-results
  artifacts:
    when: always
    paths:
      - allure-results/
      - screenshots/
    expire_in: 7 days
```

---

## Jenkins (Declarative Pipeline)

```groovy
// Jenkinsfile
pipeline {
    agent any

    environment {
        TEST_MODE     = 'mock'
        LOG_LEVEL     = 'INFO'
        BASE_URL      = credentials('api-base-url')
        CLIENT_ID     = credentials('oauth-client-id')
        CLIENT_SECRET = credentials('oauth-client-secret')
    }

    stages {
        stage('Start WireMock') {
            steps {
                sh 'docker-compose up -d wiremock'
                sh 'timeout 30 bash -c "until curl -sf http://localhost:8080/__admin/health; do sleep 2; done"'
            }
        }

        stage('API Tests') {
            steps {
                sh 'pip install -r requirements.txt'
                sh 'pytest layer_4_tests/api/ -v --alluredir=allure-results/api'
            }
            post {
                always {
                    allure includeProperties: false,
                           jdk: '',
                           results: [[path: 'allure-results/api']]
                }
            }
        }

        stage('UI Tests') {
            steps {
                sh 'playwright install chromium --with-deps'
                sh 'pytest layer_4_tests/ui/ -v --alluredir=allure-results/ui'
            }
            post {
                always {
                    allure includeProperties: false,
                           jdk: '',
                           results: [[path: 'allure-results/ui']]
                    archiveArtifacts artifacts: 'screenshots/**', allowEmptyArchive: true
                }
            }
        }
    }

    post {
        always {
            sh 'docker-compose down'
        }
    }
}
```

---

## Azure DevOps

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
      - develop

pool:
  vmImage: ubuntu-latest

variables:
  TEST_MODE: mock
  HEADLESS: true
  LOG_LEVEL: INFO

stages:
  - stage: APITests
    displayName: API Test Suite
    jobs:
      - job: RunAPITests
        steps:
          - task: UsePythonVersion@0
            inputs:
              versionSpec: "3.12"

          - script: docker-compose up -d wiremock
            displayName: Start WireMock

          - script: pip install -r requirements.txt
            displayName: Install dependencies

          - script: pytest layer_4_tests/api/ -v --alluredir=$(Build.ArtifactStagingDirectory)/allure-results
            displayName: Run API tests
            env:
              BASE_URL: $(API_BASE_URL)
              CLIENT_ID: $(CLIENT_ID)
              CLIENT_SECRET: $(CLIENT_SECRET)

          - task: PublishTestResults@2
            condition: always()
            inputs:
              testResultsFormat: JUnit
              testResultsFiles: "**/junit.xml"

          - task: PublishBuildArtifacts@1
            condition: always()
            inputs:
              pathToPublish: $(Build.ArtifactStagingDirectory)/allure-results
              artifactName: allure-results-api

  - stage: UITests
    displayName: UI Test Suite
    dependsOn: APITests
    jobs:
      - job: RunUITests
        steps:
          - task: UsePythonVersion@0
            inputs:
              versionSpec: "3.12"

          - script: |
              pip install -r requirements.txt
              playwright install chromium --with-deps
            displayName: Install dependencies + browser

          - script: pytest layer_4_tests/ui/ -v --alluredir=$(Build.ArtifactStagingDirectory)/allure-results
            displayName: Run UI tests
            env:
              AUT_BASE_URL: $(AUT_BASE_URL)
              BROWSER: chromium

          - task: PublishBuildArtifacts@1
            condition: always()
            inputs:
              pathToPublish: $(Build.ArtifactStagingDirectory)/allure-results
              artifactName: allure-results-ui
```

---

## Layer Dependency Enforcement in CI

Every pipeline includes a lint step to enforce the 4-layer import contract.

### Python — import-linter

```ini
# .importlinter
[importlinter]
root_packages =
    layer_1_models
    layer_2_clients
    layer_3_services
    layer_3_pages
    layer_4_tests
    config

[importlinter:contract:layers]
name = Enforce 4-layer dependency direction
type = layers
layers =
    layer_4_tests
    layer_3_services : layer_3_pages
    layer_2_clients
    layer_1_models
```

```bash
# In CI pipeline:
pip install import-linter
lint-imports --config .importlinter
```

### Java — ArchUnit (runs as test)

```java
// src/test/java/architecture/LayerDependencyTest.java
@AnalyzeClasses(packages = "com.yourcompany.automation")
public class LayerDependencyTest {

    @ArchTest
    static final ArchRule layersShouldRespectDependencyDirection =
        layeredArchitecture()
            .consideringAllDependencies()
            .layer("Models")   .definedBy("..layer1..")
            .layer("Clients")  .definedBy("..layer2..")
            .layer("Services") .definedBy("..layer3..")
            .layer("Tests")    .definedBy("..layer4..")
            .whereLayer("Tests")    .mayOnlyAccessLayers("Services", "Models")
            .whereLayer("Services") .mayOnlyAccessLayers("Clients", "Models")
            .whereLayer("Clients")  .mayOnlyAccessLayers("Models");
}
```

ArchUnit tests run as part of the normal `mvn test` execution.
No separate CI step needed for Java.
