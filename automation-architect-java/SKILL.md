---
name: automation-architect-java
description: >
  Java/TestNG automation track for the automation-architect skill suite.
  Invoked by the automation-architect orchestrator when the user selects
  Java as their language track. Provides 4-layer scaffold using TestNG,
  RestAssured, Jackson (API), Selenium WebDriver + WebDriverManager (UI),
  and Allure/ReportPortal. Not user-invocable directly.
user-invocable: false
version: 2.0.0
tools: Read, Write
---

# Java Track — automation-architect

This skill is invoked by the automation-architect orchestrator after the user
selects Java. It reads the appropriate profile references based on the
resolved `test_type` and generates all scaffold files.

## Profile Loading Rules

| test_type  | Load                                          |
|------------|-----------------------------------------------|
| API        | references/api/* + references/shared/*        |
| UI         | references/ui/* + references/shared/*         |
| Full-Stack | references/api/* + references/ui/* + references/shared/* |

## Java Stack Decisions

| Concern            | Library                   | Version  | Reason                        |
|--------------------|---------------------------|----------|-------------------------------|
| HTTP/API testing   | RestAssured               | 5.4.x    | DSL-style, spec reuse         |
| JSON/model binding | Jackson                   | 2.17.x   | Industry standard             |
| Bean validation    | Jakarta Validation API    | 3.0.x    | Standard validation           |
| Environment config | Owner (aeonbits)          | 1.0.x    | Type-safe, .properties files  |
| Test runner        | TestNG                    | 7.10.x   | Groups, DataProviders, parallel|
| UI automation      | Selenium WebDriver        | 4.21.x   | Enterprise standard           |
| Browser mgmt       | WebDriverManager          | 5.8.x    | Auto-downloads browser drivers|
| Test data (Faker)  | JavaFaker                 | 1.0.2    | Locale-aware, rich providers  |
| Assertions         | AssertJ                   | 3.25.x   | Fluent, readable assertions   |
| Reporting          | Allure-TestNG             | 2.25.x   | (if allure selected)          |
| Layer architecture | ArchUnit                  | 1.3.x    | Compile-time layer enforcement|
| Build tool         | Maven (default) or Gradle | 3.9.x    | Industry standard             |

## File Generation Responsibilities

### Always
1. `pom.xml`
2. `src/test/resources/testng.xml`
3. `src/test/resources/config.properties`
4. `.env.example` (for documentation — Java reads from properties/env vars)
5. `docker-compose.yml` (if mock selected)
6. `src/main/java/{base_package}/config/EnvConfig.java`
7. `src/main/java/{base_package}/config/Logger.java`
8. `src/test/java/{base_package}/architecture/LayerDependencyTest.java`

### API profile
9.  `src/main/java/{base_package}/layer1/UserModel.java`
10. `src/main/java/{base_package}/layer1/UserResponseModel.java`
11. `src/main/java/{base_package}/layer1/factories/UserFactory.java`
12. `src/main/java/{base_package}/layer2/BaseApiClient.java`
13. `src/main/java/{base_package}/layer3/UserService.java`
14. `src/test/java/{base_package}/layer4/TestUserApi.java`
15. `src/main/java/{base_package}/config/AuthManager.java` (if auth != none)

### UI profile
16. `src/main/java/{base_package}/layer1/locators/LoginLocators.java`
17. `src/main/java/{base_package}/layer1/formdata/LoginFormData.java`
18. `src/main/java/{base_package}/layer2/BrowserSession.java`
19. `src/main/java/{base_package}/layer3/LoginPage.java`
20. `src/main/java/{base_package}/layer3/DashboardPage.java`
21. `src/main/java/{base_package}/layer3/components/HeaderComponent.java`
22. `src/test/java/{base_package}/layer4/TestLoginFlow.java`
23. `src/main/java/{base_package}/config/DriverManager.java`

### CI files
24. `.github/workflows/api-tests.yml` (or equivalent CI)
25. `.github/workflows/ui-tests.yml` (if test_type includes UI)

## Base Package Convention

Default base package: `com.automation.framework`
The orchestrator may ask the user for their preferred package name.

## Java Code Style Rules

- Java 21+ syntax (records for immutable models, var where appropriate)
- Lombok avoided — explicit code is clearer for framework scaffolds
- All fields private, accessed via getters (or record accessor methods)
- Method names: camelCase. Class names: PascalCase. Constants: UPPER_SNAKE
- No System.out.println() — use the SLF4J logger
- AssertJ assertions preferred over TestNG built-ins (more readable)
- @BeforeClass / @AfterClass at suite scope; @BeforeMethod at test scope
- All test methods: public void, no return type

## Resource Naming

The scaffold uses "User" as the example resource domain throughout.
After generating, always tell the user:

"The scaffold uses 'User' as the example resource. To add a new resource
(e.g., 'Order'), duplicate the model, factory, service, and test files and
replace 'User' with your resource name. The structure is identical for
every resource domain."
