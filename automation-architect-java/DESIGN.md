# automation-architect-java — Design Document

**Version:** 2.1.0
**Last Updated:** 2026-05-04
**Skill:** automation-architect-java
**Invoked by:** automation-architect orchestrator (after user selects Java)

---

## Overview

This document captures every design decision, pattern, and architectural rationale in the
Java automation track. It is the canonical reference for reviewing, extending, or debugging
the generated scaffold.

The Java track generates a 4-layer test automation framework using:
- **TestNG** — test runner, groups, DataProviders, parallel execution
- **RestAssured** — DSL-style HTTP client for API testing
- **Jackson** — JSON serialization/deserialization via Java 21 records
- **Selenium WebDriver + WebDriverManager** — browser automation (UI profile)
- **AssertJ** — fluent assertion library
- **Owner (aeonbits)** — type-safe environment config from `.properties` files
- **Allure-TestNG** — HTML reporting
- **ArchUnit** — compile-time layer dependency enforcement

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  automation-architect-java  (invoked by orchestrator after Java selected)   │
│                                                                             │
│  Profile Loading:                                                           │
│    test_type=API        → references/api/* + references/shared/*            │
│    test_type=UI         → references/ui/* + references/shared/*             │
│    test_type=Full-Stack → references/api/* + references/ui/* + shared/*     │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                     ┌──────────────▼──────────────┐
                     │        Phase 2: Scaffold      │
                     │  Generate files in order      │
                     │  (see Block 14 — File Order)  │
                     └──────────────┬──────────────┘
                                    │
     ┌──────────────────────────────┼──────────────────────────────┐
     │                             │                              │
     ▼                             ▼                              ▼
┌─────────────┐             ┌─────────────┐              ┌─────────────┐
│  API Profile│             │  UI Profile │              │  Shared     │
│             │             │             │              │             │
│  Layer 1    │             │  Layer 1    │              │  EnvConfig  │
│  (Jackson   │             │  (Locators, │              │  Logger     │
│   Records)  │             │   FormData) │              │  AuthManager│
│             │             │             │              │  ClientFact.│
│  Layer 2    │             │  Layer 2    │              │             │
│  (RestAssur.│             │  (Browser   │              └─────────────┘
│   BaseClient│             │   Session,  │
│   MockClient│             │   DriverMgr)│
│   ClientFact│             │             │
│             │             │  Layer 3    │
│  Layer 3    │             │  (PageObjts,│
│  (UserSvc)  │             │   Components│
│             │             │   Fluent)   │
│  Layer 4    │             │             │
│  (TestUserA │             │  Layer 4    │
│   BaseTest) │             │  (TestLogin │
│             │             │   BaseUiTest│
└─────────────┘             └─────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  4-Layer Dependency Chain (enforced by ArchUnit)                            │
│                                                                             │
│  Layer 4 (Tests)          ←  depends on  →  Layer 3, Layer 1, Config       │
│  Layer 3 (Services/Pages) ←  depends on  →  Layer 2, Layer 1, Config       │
│  Layer 2 (Client/Browser) ←  depends on  →  Layer 1, Config                │
│  Layer 1 (Models/Locators) ← depends on →  Config only                     │
│                                                                             │
│  Rule: No layer may import from a higher layer.                             │
│  ArchUnit test: LayerDependencyTest.java (runs every build)                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Logic Blocks

---

### Block 1 — Profile Loading Rules

**Purpose:** Determine which reference files to load based on `test_type` from the orchestrator.

**Decision table:**

| test_type  | Reference files loaded                                     |
|------------|------------------------------------------------------------|
| API        | references/api/* + references/shared/*                     |
| UI         | references/ui/* + references/shared/*                      |
| Full-Stack | references/api/* + references/ui/* + references/shared/*   |

**Rules:**
- Shared config is always loaded — it contains `EnvConfig`, `Logger`, `AuthManager`
- UI profile includes `layer1/locators/*` and `layer1/formdata/*` even though Layer 1 is shared
- Mock stubs are injected by `automation-architect-mock` separately; this skill adds `ClientFactory` bridge

**Files loaded per profile:**

```
API profile:
  references/api/layer1-jackson-models.md
  references/api/layer2-restassured-client.md
  references/api/layer3-services.md
  references/api/layer4-testng-api-tests.md
  references/api/patterns/singleton-auth.md
  references/shared/env-typesafe-config.md

UI profile:
  references/ui/layer2-webdriver-session.md
  references/ui/layer3-page-objects.md
  references/ui/layer4-testng-ui-tests.md
  references/shared/env-typesafe-config.md

Full-Stack = API + UI
```

---

### Block 2 — Layer 1: Jackson Models (API Profile)

**Purpose:** Typed request/response models using Java 21 records with Jackson annotations.
No plain POJOs, no Lombok — records provide immutability and compact syntax natively.

**Generated files:**
- `src/main/java/{pkg}/layer1/CreateUserRequest.java`
- `src/main/java/{pkg}/layer1/UserResponse.java`
- `src/main/java/{pkg}/layer1/ApiErrorResponse.java`
- `src/main/java/{pkg}/layer1/factories/UserFactory.java`

**Key design:**

```java
// Request model — Java 21 record with Jackson + Jakarta Validation annotations
@JsonInclude(JsonInclude.Include.NON_NULL)   // null fields excluded from JSON body
public record CreateUserRequest(
    @NotBlank @Size(min = 3, max = 50) @JsonProperty("username") String username,
    @NotBlank @Email                   @JsonProperty("email")    String email,
    @NotBlank                          @JsonProperty("role")     String role,
    @JsonProperty("first_name")        String firstName,   // null → omitted from JSON
    @JsonProperty("last_name")         String lastName
) {
    // Convenience constructor for required-fields-only creation
    public CreateUserRequest(String username, String email, String role) {
        this(username, email, role, null, null);
    }
}

// Response model — tolerant to new API fields (ignoreUnknown = true)
@JsonIgnoreProperties(ignoreUnknown = true)
public record UserResponse(
    @JsonProperty("id")         Long id,
    @JsonProperty("username")   String username,
    @JsonProperty("email")      String email,
    @JsonProperty("role")       String role,
    @JsonProperty("created_at") String createdAt
) {}
```

**Why `@JsonIgnoreProperties(ignoreUnknown = true)` on response models:**
APIs evolve. Without this, adding a new field to the API response breaks all tests that
deserialize that response. With it, tests are resilient to API evolution.

**Why Jakarta Validation annotations on request models:**
Documentation-as-code — the constraint is expressed at the type level. The annotations
also serve as documentation for what the API accepts, independent of runtime validation.

**UserFactory — test data generation:**

```java
public class UserFactory {
    private static final Faker faker = new Faker();

    public static CreateUserRequest build()             { return build("viewer"); }
    public static CreateUserRequest build(String role) { /* randomized with role */ }
    public static CreateUserRequest buildAdmin()        { return build("admin"); }
    public static CreateUserRequest buildWithInvalidEmail() { /* "not-a-valid-email" */ }
    public static CreateUserRequest buildWithInvalidRole()  { /* "superuser" */ }
}
```

**Naming conventions:**

| Concept        | Convention              | Example                |
|----------------|-------------------------|------------------------|
| Request model  | `Create{Resource}Request` | `CreateUserRequest`  |
| Response model | `{Resource}Response`    | `UserResponse`         |
| Error response | `ApiErrorResponse`      | shared across resources|
| Factory class  | `{Resource}Factory`     | `UserFactory`          |

---

### Block 3 — Layer 2: RestAssured HTTP Client (API Profile)

**Purpose:** Wraps RestAssured's `RequestSpecification` to provide consistent headers,
base URI, auth injection, and logging. Layer 3 never touches RestAssured directly.

**Generated files:**
- `src/main/java/{pkg}/layer2/BaseApiClient.java`
- `src/main/java/{pkg}/layer2/MockApiClient.java` (when mock selected)
- `src/main/java/{pkg}/config/ClientFactory.java` (always — even for real-only)

**BaseApiClient — key patterns:**

```java
public class BaseApiClient {
    private final RequestSpecification spec;

    public BaseApiClient(String token) {
        RequestSpecBuilder builder = new RequestSpecBuilder()
            .setBaseUri(EnvConfig.get().baseUrl())
            .setContentType(ContentType.JSON)
            .setAccept(ContentType.JSON)
            .log(LogDetail.URI)
            .log(LogDetail.STATUS);

        if (token != null && !token.isBlank()) {
            builder.addHeader("Authorization", "Bearer " + token);
        }
        this.spec = builder.build();
    }

    // All HTTP verbs delegate through given(spec) — never inline spec construction
    public Response get(String endpoint) { ... }
    public Response post(String endpoint, Object body) { ... }
    public Response put(String endpoint, Object body) { ... }
    public Response delete(String endpoint) { ... }
}
```

**Key rules:**

1. **Token injected at construction** — `BaseApiClient` never fetches tokens.
   `AuthManager` provides the token; `BaseTest.@BeforeSuite` passes it in.

2. **`.extract().response()`** — Always extract raw `Response` from `ValidatableResponse`.
   Keeps Layer 2 returning raw responses; Layer 3 performs status validation.

3. **`given(spec)`** — Pre-built spec is always reused. Never call `given()` with inline
   configuration in service methods — that bypasses the base client entirely.

4. **No deserialization here** — Layer 2 returns `Response`. Layer 3 calls
   `response.as(UserResponse.class)` to deserialize.

**Strategy pattern — ClientFactory:**

```java
public class ClientFactory {
    public static BaseApiClient build(String token) {
        String mode = EnvConfig.get().testMode();
        return switch (mode.toLowerCase()) {   // Java 21 switch expression
            case "mock" -> new MockApiClient(token);
            case "real" -> new BaseApiClient(token);
            default -> throw new IllegalArgumentException(
                "Unsupported TEST_MODE: " + mode + ". Expected 'real' or 'mock'."
            );
        };
    }
}
```

**Logging — `LogDetail.URI` and `LogDetail.STATUS` only:**
Full request body logging is avoided by default because it may contain credentials or PII.
Enable `LogDetail.ALL` only in debug sessions, never committed.

---

### Block 4 — Layer 3: Service Layer (API Profile)

**Purpose:** Typed service methods per resource domain. Accepts typed models as input,
returns typed models as output. Performs HTTP status validation on success paths.

**Generated files:**
- `src/main/java/{pkg}/layer3/UserService.java`

**Key pattern:**

```java
public class UserService {
    private static final String ENDPOINT = "/api/v1/users";
    private final BaseApiClient client;

    public UserService(BaseApiClient client) { this.client = client; }

    // Happy-path method: validates status, deserializes, returns typed model
    public UserResponse createUser(CreateUserRequest payload) {
        Response response = client.post(ENDPOINT, payload);
        response.then().statusCode(201);            // status validated in Layer 3
        return response.as(UserResponse.class);     // deserialization in Layer 3
    }

    // Escape hatch: returns raw Response for negative tests
    public Response getUserRawResponse(long userId) {
        return client.get(ENDPOINT + "/{id}", userId);
    }
}
```

**Why `.statusCode()` lives in Layer 3, not Layer 2 (same rule as Python):**
Negative tests need to inspect non-2xx responses without triggering failures.
If Layer 2 validated status codes, `getUserRawResponse()` would be impossible.
The escape hatch method bypasses validation intentionally — Layer 4 asserts on
the raw status code in negative test scenarios.

**Contract rules:**
- Typed in, typed out — no `Map<String, Object>`, no raw `JsonPath` returned
- Zero test assertions — `.statusCode()` is a RestAssured contract validation, not a test assertion
- One class per resource domain (`UserService`, `OrderService`, etc.)
- `response.as(Model.class)` — Jackson deserializes; any JSON schema mismatch surfaces as
  `JsonMappingException` in Layer 4, with a clear error message

---

### Block 5 — Layer 1: Locators and Form Data (UI Profile)

**Purpose:** All CSS/XPath/By selectors live in Layer 1 as static final fields.
Page objects (Layer 3) import locators from here — never define selectors inline.

**Generated files:**
- `src/main/java/{pkg}/layer1/locators/LoginLocators.java`
- `src/main/java/{pkg}/layer1/locators/DashboardLocators.java`
- `src/main/java/{pkg}/layer1/formdata/LoginFormData.java`

**LoginLocators pattern:**

```java
public final class LoginLocators {
    private LoginLocators() {}   // utility class — no instantiation

    // Default strategy: data-testid attributes (most stable, decoupled from styling)
    public static final By USERNAME_INPUT  = By.cssSelector("[data-testid='login-username']");
    public static final By PASSWORD_INPUT  = By.cssSelector("[data-testid='login-password']");
    public static final By SUBMIT_BUTTON   = By.cssSelector("[data-testid='login-submit']");
    public static final By ERROR_MESSAGE   = By.cssSelector("[data-testid='login-error']");

    // XPath variant (if user selected XPath at Q7):
    // public static final By USERNAME_INPUT = By.xpath("//input[@name='username']");
}
```

**Locator strategy selection (from orchestrator Q7):**

| Strategy    | Example                                      | When to use                       |
|-------------|----------------------------------------------|-----------------------------------|
| data-testid | `By.cssSelector("[data-testid='x']")`        | Default — stable, test-explicit   |
| CSS         | `By.cssSelector(".btn-primary")`             | When data-testid not available    |
| XPath       | `By.xpath("//button[text()='Submit']")`      | Complex traversal required        |
| Role-based  | Not native in Selenium (use CSS/XPath)       | Accessibility testing via axe     |

**LoginFormData — typed form data:**

```java
public record LoginFormData(String username, String password) {
    private static final Faker faker = new Faker();

    public static LoginFormData build()                          { /* randomized */ }
    public static LoginFormData build(String u, String p)       { return new LoginFormData(u, p); }
    public static LoginFormData buildInvalidPassword()          { /* known bad password */ }
    public static LoginFormData buildEmpty()                    { return new LoginFormData("", ""); }
}
```

**Why locators in Layer 1 (not in page objects):**
Locators are *data* — a mapping from semantic name to DOM selector. Page objects are
*logic* — a mapping from user action to browser interaction. Keeping them separate
means a selector change touches one file (Layer 1), never ripples through page methods.
This mirrors the Python track where `LoginLocators` is a frozen dataclass.

---

### Block 6 — Layer 2: Browser Session and DriverManager (UI Profile)

**Purpose:** `BrowserSession` creates the correct `WebDriver` instance.
`DriverManager` wraps it in a `ThreadLocal` for parallel-safe access.

**Generated files:**
- `src/main/java/{pkg}/layer2/BrowserSession.java`
- `src/main/java/{pkg}/config/DriverManager.java`
- `src/test/java/{pkg}/layer4/BaseUiTest.java`

**BrowserSession — factory, not singleton:**

```java
public class BrowserSession {
    public static WebDriver create() {
        String browser = EnvConfig.get().browser().toLowerCase();
        boolean headless = EnvConfig.get().headless();

        return switch (browser) {
            case "chrome", "chromium" -> createChrome(headless);
            case "firefox"            -> createFirefox(headless);
            case "safari"             -> createSafari();
            default -> throw new IllegalArgumentException(
                "Unsupported BROWSER: '" + browser + "'"
            );
        };
    }

    private static WebDriver createChrome(boolean headless) {
        WebDriverManager.chromedriver().setup();
        ChromeOptions options = new ChromeOptions();
        if (headless) options.addArguments("--headless=new");
        options.addArguments("--no-sandbox", "--disable-dev-shm-usage",
                             "--disable-gpu", "--window-size=1920,1080");
        WebDriver driver = new ChromeDriver(options);
        driver.manage().timeouts()
            .implicitlyWait(Duration.ofMillis(0))   // DISABLED — explicit waits only
            .pageLoadTimeout(Duration.ofSeconds(30));
        return driver;
    }
}
```

**DriverManager — ThreadLocal Singleton:**

```java
public class DriverManager {
    private static final ThreadLocal<WebDriver> driverPool = new ThreadLocal<>();

    public static WebDriver getDriver() {
        if (driverPool.get() == null) {
            driverPool.set(BrowserSession.create());
        }
        return driverPool.get();
    }

    public static void quit() {
        WebDriver driver = driverPool.get();
        if (driver != null) {
            driver.quit();
            driverPool.remove();   // prevent memory leak in thread pools
        }
    }
}
```

**Why `implicitlyWait(0)`:**
Mixing implicit and explicit waits causes unpredictable behavior. When both are set,
Selenium applies them in a non-deterministic order. Setting implicit to 0 forces all
waits to be explicit `WebDriverWait` calls — predictable and debuggable.

**BaseUiTest — lifecycle and screenshot on failure:**

```java
public abstract class BaseUiTest {
    protected WebDriver driver;

    @BeforeMethod(alwaysRun = true)
    public void setUpDriver() {
        driver = DriverManager.getDriver();
        driver.get(EnvConfig.get().autBaseUrl());
    }

    @AfterMethod(alwaysRun = true)
    public void tearDown(ITestResult result) {
        if (result.getStatus() == ITestResult.FAILURE) {
            captureScreenshot(result.getName());
        }
        DriverManager.quit();   // always quit — prevent driver leak
    }

    @Attachment(value = "{testName} - failure screenshot", type = "image/png")
    private byte[] captureScreenshot(String testName) {
        return ((TakesScreenshot) driver).getScreenshotAs(OutputType.BYTES);
    }
}
```

**Why `@AfterMethod(alwaysRun = true)`:**
Without `alwaysRun = true`, `@AfterMethod` is skipped when `@BeforeMethod` fails.
A failed setup that left a driver open would leak — `alwaysRun` ensures `quit()` always runs.
The same pattern applies to screenshot capture.

**`@Attachment` for Allure screenshots:**
Allure's `@Attachment` annotation captures the return value as a test artifact.
No `AllureSelenide` dependency required — works with any `TakesScreenshot` driver.
Equivalent to the pytest hook `pytest_runtest_makereport` in the Python track.

---

### Block 7 — Layer 3: Page Objects (UI Profile)

**Purpose:** One class per page/component, encapsulates all interactions with that page.
Returns the next page object on navigation (fluent chain). No assertions anywhere.

**Generated files:**
- `src/main/java/{pkg}/layer3/LoginPage.java`
- `src/main/java/{pkg}/layer3/DashboardPage.java`
- `src/main/java/{pkg}/layer3/components/HeaderComponent.java`

**LoginPage — core patterns:**

```java
public class LoginPage {
    private final WebDriver driver;
    private final WebDriverWait wait;

    public LoginPage(WebDriver driver) {
        this.driver = driver;
        this.wait = new WebDriverWait(driver, Duration.ofSeconds(10));
    }

    // Navigation returns self (stays on same page type)
    public LoginPage navigate() {
        driver.get(driver.getCurrentUrl().split("/login")[0] + "/login");
        wait.until(ExpectedConditions.visibilityOfElementLocated(LoginLocators.USERNAME_INPUT));
        return this;
    }

    // Happy-path login → returns DashboardPage (URL changes after success)
    public DashboardPage loginAs(LoginFormData formData) {
        driver.findElement(LoginLocators.USERNAME_INPUT).sendKeys(formData.username());
        driver.findElement(LoginLocators.PASSWORD_INPUT).sendKeys(formData.password());
        driver.findElement(LoginLocators.SUBMIT_BUTTON).click();
        wait.until(driver -> !driver.getCurrentUrl().contains("/login"));
        return new DashboardPage(driver);
    }

    // Negative-path login → returns self (stays on login page)
    public LoginPage loginAndExpectError(LoginFormData formData) {
        driver.findElement(LoginLocators.USERNAME_INPUT).sendKeys(formData.username());
        driver.findElement(LoginLocators.PASSWORD_INPUT).sendKeys(formData.password());
        driver.findElement(LoginLocators.SUBMIT_BUTTON).click();
        wait.until(ExpectedConditions.visibilityOfElementLocated(LoginLocators.ERROR_MESSAGE));
        return this;
    }

    // Getter methods return text/state — Layer 4 asserts on these values
    public String getErrorMessage()  { return driver.findElement(LoginLocators.ERROR_MESSAGE).getText(); }
    public boolean isSubmitEnabled() { return driver.findElement(LoginLocators.SUBMIT_BUTTON).isEnabled(); }
}
```

**Page object contract rules:**
1. All locators from Layer 1 constants — never inline `By.cssSelector("...")` in page methods
2. No assertions — no `assertThat`, no `assertEquals` anywhere in Layer 3
3. Navigation methods return the page object of the destination page
4. Negative navigation methods return `this` (caller is still on same page)
5. All waits are explicit `WebDriverWait` — no `Thread.sleep()`
6. `WebDriverWait` is scoped per page object, duration matches that page's load behavior

**HeaderComponent — reusable component pattern:**

```java
public class HeaderComponent {
    private final WebDriver driver;

    // Components accept driver and share it — no separate driver lifecycle
    public HeaderComponent(WebDriver driver) { this.driver = driver; }

    public LoginPage logout() {
        driver.findElement(DashboardLocators.NAV_PROFILE).click();
        driver.findElement(DashboardLocators.NAV_LOGOUT).click();
        new WebDriverWait(driver, Duration.ofSeconds(5))
            .until(ExpectedConditions.urlContains("/login"));
        return new LoginPage(driver);   // navigated to login — return LoginPage
    }
}
```

---

### Block 8 — Layer 4: API Tests (TestNG)

**Purpose:** Test classes for the User API using TestNG + AssertJ.
Happy-path, negative, and parametrized tests using `@DataProvider`.

**Generated files:**
- `src/test/java/{pkg}/layer4/TestUserApi.java`
- `src/test/java/{pkg}/layer4/BaseTest.java`
- `src/test/resources/testng.xml`

**BaseTest — session-scoped client setup:**

```java
public abstract class BaseTest {
    private static BaseApiClient client;

    @BeforeSuite(alwaysRun = true)
    public synchronized void suiteSetup() {
        if (client == null) {
            String token = AuthManager.getInstance().getToken();
            client = ClientFactory.build(token);
        }
    }

    protected BaseApiClient getClient() { return client; }
}
```

**TestUserApi — test structure:**

```java
@Epic("User Management")
public class TestUserApi extends BaseTest {
    private UserService userService;

    @BeforeMethod
    public void setUp() {
        userService = new UserService(getClient());
    }

    // ── Happy Path ──────────────────────────────────────────────────
    @Feature("Create User") @Story("Valid payload")
    @Severity(SeverityLevel.CRITICAL)
    @Test(groups = {"smoke", "api"})
    @Description("POST /api/v1/users with valid payload returns 201 and valid schema")
    public void testCreateUserReturnsValidSchema() {
        CreateUserRequest payload = UserFactory.build();
        UserResponse user = userService.createUser(payload);
        assertThat(user.id()).isNotNull();
        assertThat(user.username()).isEqualTo(payload.username());
        assertThat(user.createdAt()).isNotBlank();
    }

    // ── Negative Tests ───────────────────────────────────────────────
    @Test(groups = {"api", "regression"})
    public void testGetNonExistentUserReturns404() {
        Response response = userService.getUserRawResponse(999999L);  // escape hatch
        assertThat(response.statusCode()).isEqualTo(404);
    }

    // ── Parametrized Tests ───────────────────────────────────────────
    @Test(groups = {"api", "regression"}, dataProvider = "validRoles")
    public void testCreateUserWithValidRoles(String role) {
        UserResponse user = userService.createUser(UserFactory.build(role));
        assertThat(user.role()).isEqualTo(role);
    }

    @DataProvider(name = "validRoles")
    public Object[][] validRoles() {
        return new Object[][] { {"viewer"}, {"editor"}, {"admin"} };
    }
}
```

**TestNG group taxonomy:**

| Group       | Purpose                                          | Runs in CI?       |
|-------------|--------------------------------------------------|-------------------|
| smoke       | Critical happy-path, fast (<2 min)               | Every commit      |
| api         | All API tests                                    | Every commit      |
| ui          | All UI tests                                     | Every commit      |
| regression  | Full regression suite                            | Pre-release       |
| edge_case   | PRD-ambiguity tests (may fail intentionally)     | Every commit      |
| wip         | Work in progress — excluded from CI              | Never in CI       |

**testng.xml — suite configuration:**

```xml
<suite name="Automation Suite" verbose="1" parallel="false">
    <listeners>
        <listener class-name="io.qameta.allure.testng.AllureTestNg"/>
    </listeners>
    <test name="API Tests">
        <groups><run><include name="api"/><exclude name="wip"/></run></groups>
        <classes>
            <class name="com.automation.framework.layer4.TestUserApi"/>
        </classes>
    </test>
</suite>
```

**Parallel execution:** Switch `parallel="methods"` and `thread-count="4"` in testng.xml.
`DriverManager`'s `ThreadLocal` handles thread isolation automatically — no code changes needed.

---

### Block 9 — Layer 4: UI Tests (TestNG)

**Purpose:** Browser-based login flow tests using Selenium, asserting via AssertJ.

**Generated files:**
- `src/test/java/{pkg}/layer4/TestLoginFlow.java`

**TestLoginFlow pattern:**

```java
@Epic("Authentication")
public class TestLoginFlow extends BaseUiTest {
    private LoginPage loginPage;

    @BeforeMethod(alwaysRun = true)
    public void navigateToLogin() {
        loginPage = new LoginPage(driver).navigate();
    }

    @Feature("Login") @Story("Valid credentials")
    @Severity(SeverityLevel.CRITICAL)
    @Test(groups = {"smoke", "ui"})
    public void testValidCredentialsRedirectToDashboard() {
        DashboardPage dashboard = loginPage.loginAs(
            LoginFormData.build("test@example.com", "ValidPass123!")
        );
        assertThat(dashboard.isLoaded()).isTrue();
        assertThat(dashboard.getWelcomeHeading().toLowerCase()).contains("welcome");
    }

    @Test(groups = {"smoke", "ui"})
    public void testInvalidPasswordShowsErrorMessage() {
        loginPage.loginAndExpectError(LoginFormData.buildInvalidPassword());
        assertThat(loginPage.getErrorMessage()).containsAnyOf("invalid", "incorrect", "wrong");
    }

    @Test(groups = {"regression", "ui"}, dataProvider = "invalidCredentials")
    public void testFieldValidationMessages(String u, String p, String expectedError) {
        loginPage.loginAndExpectError(LoginFormData.build(u, p));
        assertThat(loginPage.getErrorMessage().toLowerCase()).contains(expectedError.toLowerCase());
    }

    @DataProvider(name = "invalidCredentials")
    public Object[][] invalidCredentials() {
        return new Object[][] {
            {"",              "password123", "required"},
            {"user@x.com",   "",            "required"},
            {"not-an-email", "password123", "valid email"},
        };
    }
}
```

**Key difference from Python track — `@BeforeMethod` with `navigateToLogin()`:**
In TestNG, `@BeforeMethod` in the subclass runs *after* `@BeforeMethod` in `BaseUiTest`.
This means `driver` is already set when `navigateToLogin()` runs — the ordering is guaranteed.
Equivalent to `authed_page` fixture ordering in pytest.

---

### Block 10 — EnvConfig (Owner Library)

**Purpose:** Type-safe, validated environment configuration.
Owner maps `@Key` annotations to environment variables or `.properties` files.
Priority: system env vars > `config.properties` > `@DefaultValue`.

**Generated files:**
- `src/main/java/{pkg}/config/EnvConfig.java`
- `src/test/resources/config.properties`

**Pattern:**

```java
@Config.Sources({
    "system:env",                   // 1st: CI environment variables
    "classpath:config.properties"   // 2nd: local properties file
})
public interface EnvConfig extends Config {

    EnvConfig INSTANCE = ConfigFactory.create(EnvConfig.class, System.getenv());

    static EnvConfig get() { return INSTANCE; }

    @Key("BASE_URL")                         String baseUrl();
    @Key("TEST_MODE") @DefaultValue("mock")  String testMode();
    @Key("CLIENT_ID") @DefaultValue("")      String clientId();
    @Key("BROWSER")   @DefaultValue("chrome") String browser();
    @Key("HEADLESS")  @DefaultValue("true")  boolean headless();
    // ... all config keys
}
```

**Critical configs — no `@DefaultValue` (must be set explicitly):**

| Key         | Reason                                           |
|-------------|--------------------------------------------------|
| `BASE_URL`  | Wrong URL → all tests fail in silence            |

All auth keys have `@DefaultValue("")` so the framework starts without crashing;
`AuthManager` will fail with a clear error at token fetch time if auth is needed but not set.

**`config.properties` vs Python's `.env`:**
Owner reads `.properties` format — `KEY=value` (same as `.env` but parsed differently).
Commit `config.properties.example` with placeholder values. Add real `config.properties`
to `.gitignore` to prevent credential leaks.

---

### Block 11 — Logger

**Purpose:** SLF4J + Logback wrapper. All logging goes through SLF4J — never `System.out.println()`.

**Generated files:**
- `src/main/java/{pkg}/config/Logger.java`
- `src/test/resources/logback-test.xml`

**Pattern:**

```java
public final class Logger {
    private Logger() {}
    public static org.slf4j.Logger get(Class<?> clazz) {
        return LoggerFactory.getLogger(clazz);
    }
}

// Usage in any class:
private static final org.slf4j.Logger log = Logger.get(UserService.class);
log.info("Creating user: username={}", payload.username());
```

**What to log and where:**

| Layer   | What to log                                       | Level |
|---------|---------------------------------------------------|-------|
| Layer 2 | Request URI, response status (via RestAssured)    | INFO  |
| Layer 3 | Method entry + key identifiers (user ID, etc.)    | INFO  |
| Layer 3 | Full response body on unexpected error            | DEBUG |
| Config  | Token fetch events (never the token itself)       | INFO  |
| Layer 4 | Nothing — test output handled by TestNG + Allure  | —     |

**Never log:**
- Auth tokens, passwords, API keys
- Full request body (may contain PII)
- User PII (email, phone, DOB)

**`logback-test.xml`** — placed in `src/test/resources/` so it only applies during tests:
```xml
<configuration>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{HH:mm:ss.SSS} | %-5level | %logger{30} | %msg%n</pattern>
        </encoder>
    </appender>
    <root level="INFO"><appender-ref ref="STDOUT"/></root>
</configuration>
```

---

### Block 12 — AuthManager (OAuth2 Client Credentials)

**Purpose:** Thread-safe Singleton auth manager. One token fetch per test session,
with TTL-aware refresh. Uses `ReentrantLock` for thread safety in parallel runs.

**Generated file:**
- `src/main/java/{pkg}/config/AuthManager.java`

**Double-checked locking with ReentrantLock:**

```java
public class AuthManager {
    private static final ReentrantLock lock = new ReentrantLock();
    private static volatile AuthManager instance;
    private String token;
    private Instant expiresAt = Instant.EPOCH;

    // Singleton instance — lazy init, thread-safe
    public static AuthManager getInstance() {
        if (instance == null) {
            lock.lock();
            try {
                if (instance == null) { instance = new AuthManager(); }
            } finally { lock.unlock(); }
        }
        return instance;
    }

    // Token retrieval — refresh only if expired
    public String getToken() {
        lock.lock();
        try {
            if (isExpired()) refresh();
            return token;
        } finally { lock.unlock(); }
    }

    private boolean isExpired() {
        return Instant.now().isAfter(expiresAt.minusSeconds(30));  // 30s buffer
    }

    private void refresh() {
        // POST to TOKEN_URL with client_credentials grant
        // Parse access_token + expires_in from JSON response
        // Update this.token and this.expiresAt
    }
}
```

**Why `ReentrantLock` over `synchronized`:**
`ReentrantLock` allows `try/finally` for guaranteed unlock even on exception.
`synchronized` has no `finally` semantics — an exception before the implicit unlock
never releases the monitor in some edge cases. `ReentrantLock` is always explicit.

**Three auth variants supported:**

| Auth type         | Config keys required               | Generated class behavior       |
|-------------------|------------------------------------|--------------------------------|
| OAuth2 CC (default)| TOKEN_URL, CLIENT_ID, CLIENT_SECRET | Full token refresh with TTL   |
| Bearer/JWT static | API_TOKEN                          | Returns `API_TOKEN` directly  |
| None              | —                                  | Returns `null` (no auth header)|

The orchestrator selects the variant at Q5 (auth type). The skill generates only the
variant needed — no unused code in the scaffold.

---

### Block 13 — Allure Reporting

**Purpose:** Rich HTML reports with test hierarchy, severity labels, steps, and screenshots.

**Annotation hierarchy:**

```java
@Epic("User Management")           // top-level business domain → Allure "Epic"
@Feature("Create User")            // feature within the domain → Allure "Feature"
@Story("Valid payload")            // specific user story → Allure "Story"
@Severity(SeverityLevel.CRITICAL)  // test severity
@Description("POST /api/v1/users with valid payload returns 201 and valid schema")
@Test(groups = {"smoke", "api"})
public void testCreateUserReturnsValidSchema() { ... }
```

**Severity guide:**

| Level    | Use when                                               |
|----------|--------------------------------------------------------|
| BLOCKER  | Test failure blocks the release immediately            |
| CRITICAL | Core business function — P0 flow                       |
| NORMAL   | Standard regression — important but not release-blocking|
| MINOR    | Edge case, cosmetic, low-business-impact               |
| TRIVIAL  | Documentation / informational only                     |

**Run and view reports:**

```bash
# Run tests with Allure results
mvn test

# Generate and open report
allure serve allure-results/

# Generate static report only
allure generate allure-results/ --clean -o allure-report/
```

**CI artifact upload (GitHub Actions):**

```yaml
- name: Run tests
  run: mvn test

- name: Upload Allure results
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: allure-results
    path: allure-results/

- name: Generate Allure report
  if: always()
  run: allure generate allure-results/ --clean -o allure-report/

- name: Upload Allure report
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: allure-report
    path: allure-report/
```

**Maven Surefire plugin — required for Allure Java agent:**

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-surefire-plugin</artifactId>
    <version>3.2.5</version>
    <configuration>
        <suiteXmlFiles>
            <suiteXmlFile>src/test/resources/testng.xml</suiteXmlFile>
        </suiteXmlFiles>
        <argLine>
            -javaagent:${settings.localRepository}/io/qameta/allure/allure-javaagent/
            ${allure.version}/allure-javaagent-${allure.version}.jar
        </argLine>
    </configuration>
</plugin>
```

---

### Block 14 — ArchUnit Layer Enforcement

**Purpose:** Automated compile-time enforcement of the 4-layer dependency rule.
Fails the build if any class violates the dependency direction.

**Generated file:**
- `src/test/java/{pkg}/architecture/LayerDependencyTest.java`

**Pattern:**

```java
@AnalyzeClasses(packages = "com.automation.framework")
public class LayerDependencyTest {

    @ArchTest
    static final ArchRule layersShouldRespectDependencyDirection =
        layeredArchitecture()
            .consideringAllDependencies()
            .layer("Config") .definedBy("..config..")
            .layer("Layer1") .definedBy("..layer1..")
            .layer("Layer2") .definedBy("..layer2..")
            .layer("Layer3") .definedBy("..layer3..")
            .layer("Layer4") .definedBy("..layer4..")
            .whereLayer("Layer4").mayOnlyAccessLayers("Layer3", "Layer1", "Config")
            .whereLayer("Layer3").mayOnlyAccessLayers("Layer2", "Layer1", "Config")
            .whereLayer("Layer2").mayOnlyAccessLayers("Layer1", "Config")
            .whereLayer("Layer1").mayOnlyAccessLayers("Config");
}
```

**What this prevents:**
- A service (`Layer3`) importing a test class (`Layer4`) — backwards dependency
- A model (`Layer1`) importing a client (`Layer2`) — upwards dependency
- A test (`Layer4`) importing `RestAssured` directly — bypassing the client layer

**Why ArchUnit instead of code review:**
Architecture violations are introduced gradually and often go unnoticed in review.
ArchUnit fails the build on every pull request, making violations impossible to merge.
This is unique to Java — Python has no equivalent enforcement mechanism at compile time.

---

### Block 15 — File Generation Order

The scaffold is generated in this sequence to ensure imports always resolve:

```
Sequence  File
───────── ────────────────────────────────────────────────────────────
  1       pom.xml
  2       src/test/resources/testng.xml
  3       src/test/resources/config.properties
  4       src/test/resources/logback-test.xml
  5       .env.example
  6       .gitignore

── Shared Config ──────────────────────────────────────────────────────
  7       src/main/java/{pkg}/config/EnvConfig.java
  8       src/main/java/{pkg}/config/Logger.java

── API Profile — Layer 1 ──────────────────────────────────────────────
  9       src/main/java/{pkg}/layer1/CreateUserRequest.java
 10       src/main/java/{pkg}/layer1/UserResponse.java
 11       src/main/java/{pkg}/layer1/ApiErrorResponse.java
 12       src/main/java/{pkg}/layer1/factories/UserFactory.java

── API Profile — Layer 2 ──────────────────────────────────────────────
 13       src/main/java/{pkg}/layer2/BaseApiClient.java
 14       src/main/java/{pkg}/layer2/MockApiClient.java       (if mock selected)
 15       src/main/java/{pkg}/config/ClientFactory.java

── API Profile — Auth ─────────────────────────────────────────────────
 16       src/main/java/{pkg}/config/AuthManager.java         (if auth != none)

── API Profile — Layer 3 ──────────────────────────────────────────────
 17       src/main/java/{pkg}/layer3/UserService.java

── API Profile — Layer 4 ──────────────────────────────────────────────
 18       src/test/java/{pkg}/layer4/BaseTest.java
 19       src/test/java/{pkg}/layer4/TestUserApi.java

── UI Profile — Layer 1 ───────────────────────────────────────────────
 20       src/main/java/{pkg}/layer1/locators/LoginLocators.java
 21       src/main/java/{pkg}/layer1/locators/DashboardLocators.java
 22       src/main/java/{pkg}/layer1/formdata/LoginFormData.java

── UI Profile — Layer 2 ───────────────────────────────────────────────
 23       src/main/java/{pkg}/layer2/BrowserSession.java
 24       src/main/java/{pkg}/config/DriverManager.java

── UI Profile — Layer 3 ───────────────────────────────────────────────
 25       src/main/java/{pkg}/layer3/LoginPage.java
 26       src/main/java/{pkg}/layer3/DashboardPage.java
 27       src/main/java/{pkg}/layer3/components/HeaderComponent.java

── UI Profile — Layer 4 ───────────────────────────────────────────────
 28       src/test/java/{pkg}/layer4/BaseUiTest.java
 29       src/test/java/{pkg}/layer4/TestLoginFlow.java

── ArchUnit ───────────────────────────────────────────────────────────
 30       src/test/java/{pkg}/architecture/LayerDependencyTest.java

── CI ─────────────────────────────────────────────────────────────────
 31       .github/workflows/api-tests.yml
 32       .github/workflows/ui-tests.yml                      (if UI profile)
```

---

## Java Code Style Rules

- Java 21+ syntax — records for immutable models, switch expressions, `var` where appropriate
- No Lombok — explicit code is clearer for framework scaffolds; records provide the same conciseness
- All fields `private`, accessed via record accessor methods or explicit getters
- Method names: `camelCase`. Class names: `PascalCase`. Constants: `UPPER_SNAKE_CASE`
- No `System.out.println()` — use SLF4J logger (`log.info(...)`)
- AssertJ assertions preferred over TestNG built-ins — more readable failure messages
- `@BeforeSuite` at suite scope (one-time setup); `@BeforeMethod` at test scope (per-test)
- All test methods: `public void`, no return type
- `@AfterMethod(alwaysRun = true)` for teardown — runs even when `@BeforeMethod` fails

---

## Design Decisions

---

### D1 — Java 21 Records for Models (not POJOs + Lombok)

**Options considered:**

| Option | Approach | Trade-offs |
|--------|----------|------------|
| A | Java 21 records | Immutable, compact, no boilerplate. Requires Java 21. |
| B | POJO + Lombok `@Data` | Works on Java 11+. Adds Lombok compile-time dependency. |
| C | POJO + manual getters | Verbose, ~80 lines per model. Clearest for beginners. |

**Chosen:** Option A — Java 21 records.

**Why:** Records are immutable by default (no accidental field mutation), compact
(one line per field), and require zero dependencies. Lombok adds bytecode manipulation
that can conflict with build tools and IDEs — a framework scaffold should avoid build complexity.
The `@JsonProperty` annotation works identically on record components as on POJO fields.

**Trade-off:** Requires Java 21 minimum. Teams on Java 11 or 17 must use Option B or C.
The orchestrator should warn the user if their `java -version` output is below 21.

---

### D2 — Owner Library for Config (not dotenv-java or System.getenv())

**Options considered:**

| Option | Approach | Trade-offs |
|--------|----------|------------|
| A | Owner (aeonbits) | Type-safe, interface-based, multi-source priority. Minimal setup. |
| B | dotenv-java | Reads `.env` file. Consistent with Python track. No type coercion. |
| C | `System.getenv()` directly | Zero dependencies. Verbose, no type safety, no defaults. |

**Chosen:** Option A — Owner library.

**Why:** Owner converts string env vars to typed values (`boolean headless()`, `int maxRetries()`)
at access time — type errors are caught early. It reads from multiple sources in priority order
(env > properties) via `@Config.Sources`. This mirrors how `pydantic-settings` works in the
Python track. `dotenv-java` is string-only; `System.getenv()` requires manual parsing everywhere.

**Trade-off:** Owner is a third-party library (though mature and stable at v1.0.x).
Teams preferring zero external config dependencies can use Option C with a dedicated `Config.java`
wrapper class that handles parsing manually.

---

### D3 — AssertJ over TestNG Built-in Assertions

**Options considered:**

| Option | Approach | Trade-offs |
|--------|----------|------------|
| A | AssertJ | Fluent, readable. Error messages include actual + expected. Rich API. |
| B | TestNG `Assert.*` | Built-in, no extra dependency. Terse error messages. |
| C | Hamcrest | Matcher-based. Strong ecosystem. Verbose syntax. |

**Chosen:** Option A — AssertJ.

**Why:** AssertJ produces failure messages that include both the actual and expected values
with full context: `expected: "admin" but was: "viewer"`. TestNG's built-in assertions
produce `expected [admin] but found [viewer]` — same information but without field names or
surrounding context. AssertJ's fluent API (`assertThat(user).isNotNull()`) reads like natural
language and chains cleanly: `assertThat(list).hasSize(3).containsExactly("a", "b", "c")`.

**Trade-off:** One additional dependency. Teams already using Hamcrest can use Option C;
the APIs are similar enough that switching is a matter of syntax preference.

---

### D4 — WebDriverManager for Browser Driver Setup

**Options considered:**

| Option | Approach | Trade-offs |
|--------|----------|------------|
| A | WebDriverManager | Auto-downloads correct driver binary. Zero manual setup. |
| B | Manual chromedriver | User manages driver binary version. Breaks when Chrome updates. |
| C | Selenium Grid | Remote execution, scalable. Requires Grid infrastructure. |

**Chosen:** Option A — WebDriverManager.

**Why:** Manual driver management is the most common source of "works on my machine"
failures — the driver binary version must exactly match the installed browser version.
WebDriverManager downloads the correct version at runtime based on the installed browser.
In CI, Chrome is updated frequently; WebDriverManager handles this automatically.

**Trade-off:** Requires internet access at test startup (driver download). In air-gapped
environments, pre-download the driver and configure WebDriverManager's cache path.

---

### D5 — ReentrantLock for AuthManager Thread Safety

**Options considered:**

| Option | Approach | Trade-offs |
|--------|----------|------------|
| A | `ReentrantLock` with `try/finally` | Explicit, guaranteed unlock. `tryLock()` available. |
| B | `synchronized` on instance method | Simpler syntax. No `finally` guarantee on exception. |
| C | `AtomicReference` | Lock-free. Complex for token + expiry pair atomically. |

**Chosen:** Option A — `ReentrantLock`.

**Why:** `try/finally` guarantees the lock is always released, even if `refresh()` throws
an exception (e.g., network error). `synchronized` does not provide this guarantee in all
JVM edge cases. Additionally, `ReentrantLock.tryLock(timeout, unit)` would allow a timeout
if token fetch hangs — useful for CI pipelines with strict timeout budgets.

**Trade-off:** More verbose than `synchronized`. Requires the author to remember `try/finally`.
The Python equivalent uses `threading.Lock` with `with` statement — guaranteed release via
context manager. Java has no equivalent `with` for locks (though try-with-resources applies
to `Closeable` — `ReentrantLock` does not implement `Closeable`).

---

### D6 — status validation in Layer 3 (`.then().statusCode()` vs Layer 2)

**Same contract as Python D4 — documented here for completeness.**

**Chosen:** Status validation in Layer 3, not Layer 2.

**Why:** Negative tests need to examine non-2xx responses without triggering failures.
The `getUserRawResponse()` escape hatch bypasses Layer 3 validation and returns raw
`Response` for test-level assertion. If Layer 2 validated status codes, this pattern
would be impossible — all non-2xx responses would throw before Layer 4 could inspect them.

**Layer 3 rule:** `.statusCode(N)` in service methods is a contract validation
("this operation must succeed"), not a test assertion. It lives in Layer 3 because
it is part of the definition of a "successful create/read/update/delete".

---

### D7 — ArchUnit for Layer Dependency Enforcement

**Options considered:**

| Option | Approach | Trade-offs |
|--------|----------|------------|
| A | ArchUnit `@ArchTest` | Compile-time enforcement. Fails build on violation. |
| B | Code review convention | Manual, inconsistent, misses gradual drift. |
| C | Package-by-layer + visibility modifiers | `package-private` prevents cross-layer access. Complex. |

**Chosen:** Option A — ArchUnit.

**Why:** Architecture violations are introduced gradually — a test imports a service,
a service imports another service directly, a client calls a layer 4 helper.
Code review catches obvious violations but misses subtle ones over months of development.
ArchUnit runs on every `mvn test` invocation and fails the build on any violation,
making architecture drift impossible to merge. This is unique to Java; Python has no equivalent.

**Trade-off:** ArchUnit requires learning its DSL. The `@ArchTest` approach requires running
tests for enforcement — if `mvn test` is skipped, ArchUnit doesn't run. Use `maven-enforcer-plugin`
for build-time checks that run even without `mvn test`.

---

### D8 — `@BeforeSuite` in BaseTest for Session-Scoped Client

**Options considered:**

| Option | Approach | Trade-offs |
|--------|----------|------------|
| A | `@BeforeSuite` in `BaseTest` with null check | One client per suite. Simple. |
| B | `@BeforeClass` per test class | One client per class. Slightly more overhead. |
| C | TestNG `ITestListener` | Centralized. Decoupled from test hierarchy. Complex. |

**Chosen:** Option A — `@BeforeSuite` with null check in `BaseTest`.

**Why:** Auth token fetch is expensive (HTTP call). Suite scope means one fetch per test run,
regardless of how many test classes extend `BaseTest`. The `synchronized` + null-check pattern
is thread-safe when `parallel="classes"` is used in testng.xml. The client is stateless
after construction — safe to share across all test methods.

---

### D9 — Locators as Static Final Fields (not PageFactory `@FindBy`)

**Options considered:**

| Option | Approach | Trade-offs |
|--------|----------|------------|
| A | Static final `By` constants in Layer 1 | Explicit, inspectable, no reflection. |
| B | Selenium PageFactory `@FindBy` | Annotation-based. Reflection at runtime. |
| C | Inline `By.cssSelector("...")` in page methods | Zero setup. Locator spread everywhere. |

**Chosen:** Option A — static final `By` constants.

**Why:** PageFactory uses reflection and proxy objects — `@FindBy` fields are initialized
lazily via dynamic proxy, which makes debugging failures harder (null pointer exceptions
surface in unexpected places). Static final constants are direct references — readable
in stack traces and debuggable with standard tools. Centralizing in Layer 1 means a
selector change touches exactly one file, regardless of how many page methods use that selector.

**Trade-off:** More verbose than `@FindBy` — requires explicit `driver.findElement(Locator.FIELD)`.
Teams used to PageFactory can continue with Option B; the locator-in-Layer-1 principle still
applies (move `@FindBy` definitions to a dedicated `LoginLocators` class with `PageFactory.initElements`).

---

## Known Limitations

1. **WireMock stub authoring** — same limitation as orchestrator D3. WireMock has no
   built-in OpenAPI spec import; stubs must be hand-authored. Teams with a Swagger/OpenAPI
   spec should consider Prism (OpenAPI proxy mock) instead of WireMock.

2. **Selenium vs Playwright** — Java track uses Selenium. Java Playwright exists but is
   less mature than Python Playwright. Selenium is the enterprise Java standard.
   If the user prefers Java Playwright, they should select the Python track and note
   that the Python track uses Playwright natively.

3. **ArchUnit does not run if tests are skipped** — `mvn test -DskipTests` skips ArchUnit.
   Use `maven-enforcer-plugin` for build-time checks that run unconditionally.

4. **Java 21 records require Maven compiler plugin 3.11+ with `--enable-preview` for some
   features** — verify `maven.compiler.source` and `maven.compiler.target` are both set to `21`.

5. **TestNG `@BeforeSuite` runs once per suite, not once per JVM** — if multiple suites
   are configured in testng.xml, `suiteSetup()` runs multiple times. The `synchronized`
   null check handles this correctly (second call sees non-null client, skips init).

---

## Open Questions / Future Options

### O1 — Idempotent Re-Run (Round -2 Gate)
*Same as orchestrator O1 — pending v2.3 implementation.*

When a scaffold already exists, the Java track should detect `pom.xml` or `src/` and
offer to jump directly to Edit Config mode rather than regenerating the entire scaffold.

**Design:** Same Option C as orchestrator — detect `pom.xml` at invocation start,
branch into Edit Config flow instead of full scaffold generation.

### O2 — Multi-Service Monorepo
*Same as orchestrator O2 — pending v3.x implementation.*

Multi-service scaffold with `shared/` (auth, config, base client) + `services/{name}/`
per service. Maven multi-module project: parent `pom.xml` + one module per service.
CI runs all service test suites in parallel. See orchestrator O2 for full design.

---

*End of automation-architect-java DESIGN.md v2.0.0*

---

### Block 16 — Edge-Case Tests (PRD-Driven)

**Purpose:** Generate parametrized tests from PRD ambiguities. These tests are expected
to fail until the PRD is clarified — failures are signal, not bugs.

**Reference file:** `references/edge-case-tests-testng.md`
(merged from standalone automation-architect-edge-cases skill, 2026-05-04)

**Generated files (alongside standard scaffold):**

```
src/test/java/{pkg}/layer4/
└── TestUserApiEdgeCases.java          ← parametrized edge-case tests

src/main/java/{pkg}/layer1/
└── EdgeCaseDataProviders.java         ← @DataProvider methods for edge cases

EDGE_CASES.md                          ← PRD ambiguities mapped to test cases (P0/P1/P2)
PRD_CLARIFICATION_CHECKLIST.md         ← P0 items requiring PRD updates
```

**10 test patterns (full code in reference file):**

| Pattern | What it covers | TestNG groups |
|---------|---------------|---------------|
| 1 | Input validation — email format ambiguity | `edge-cases`, `validation` |
| 2 | Boundary values — min/max length undefined | `edge-cases`, `boundaries` |
| 3 | Concurrency — duplicate email race condition | `edge-cases`, `concurrency` |
| 4 | State transitions — which role changes are valid | `edge-cases`, `regression` |
| 5 | Authorization — role-based permission boundaries | `edge-cases`, `security` |
| 6 | Error response consistency — error code format | `edge-cases`, `error-handling` |
| 7 | Idempotence — POST/DELETE duplicate behavior | `edge-cases`, `idempotence` |
| 8 | Pagination — page 0, negative, oversized page | `edge-cases`, `pagination` |
| 9 | Timestamp/timezone — DST and leap second handling | `edge-cases`, `timestamp` |
| 10 | Organization — @Epic/@Feature with groups | (Allure + TestNG structure) |

**TestNG group additions to `testng.xml`:**

```xml
<!-- Edge-case suite — add alongside existing API/UI tests -->
<test name="Edge Case Tests">
    <groups>
        <run>
            <include name="edge-cases"/>
            <exclude name="wip"/>
        </run>
    </groups>
    <classes>
        <class name="com.automation.framework.layer4.TestUserApiEdgeCases"/>
    </classes>
</test>
```

**Run commands:**

```bash
# Run all edge-case tests
mvn test -Dgroups=edge-cases

# Run specific category
mvn test -Dgroups="edge-cases,validation"
mvn test -Dgroups="edge-cases,concurrency"

# Run with Allure reporting
mvn test -Dgroups=edge-cases
allure serve allure-results/

# Run happy-path + edge cases together (Phase 4 default)
mvn test -Dgroups="api,ui,edge-cases"
```

**Why edge-case tests are expected to fail:**
Tests are generated from PRD gaps — cases where the spec is silent or ambiguous.
A failing edge-case test is a valid finding: "this scenario is not covered by the PRD".
Use EDGE_CASES.md to map each failing test back to the ambiguity, then use the failures
as input for PRD clarification meetings. Once the PRD is updated, update the test
expectation to match and the test will pass.

**Ambiguity priority levels:**

| Level | Label    | Meaning                                       |
|-------|----------|-----------------------------------------------|
| P0    | Critical | Ambiguity could cause data loss or security issue |
| P1    | High     | Ambiguity causes inconsistent user experience |
| P2    | Medium   | Ambiguity is cosmetic or low-impact           |

Run P0 tests first: `mvn test -Dgroups="edge-cases,p0"` — these are the must-clarify items.
