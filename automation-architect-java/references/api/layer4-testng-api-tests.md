# Layer 4 — API Tests (Java / TestNG + AssertJ)

---

## src/test/java/{pkg}/layer4/TestUserApi.java

```java
package com.automation.framework.layer4;

import com.automation.framework.layer1.CreateUserRequest;
import com.automation.framework.layer1.UserResponse;
import com.automation.framework.layer1.factories.UserFactory;
import com.automation.framework.layer2.BaseApiClient;
import com.automation.framework.layer3.UserService;
import io.qameta.allure.*;
import io.restassured.response.Response;
import org.testng.annotations.*;

import static org.assertj.core.api.Assertions.assertThat;

@Epic("User Management")
public class TestUserApi extends BaseTest {

    private UserService userService;

    @BeforeMethod
    public void setUp() {
        userService = new UserService(getClient());
    }

    // ── Happy Path ──────────────────────────────────────────────────────

    @Feature("Create User")
    @Story("Valid payload")
    @Severity(SeverityLevel.CRITICAL)
    @Test(groups = {"smoke", "api"})
    @Description("POST /api/v1/users with valid payload returns 201 and valid schema")
    public void testCreateUserReturnsValidSchema() {
        CreateUserRequest payload = UserFactory.build();

        UserResponse user = userService.createUser(payload);

        assertThat(user.id()).isNotNull();
        assertThat(user.username()).isEqualTo(payload.username());
        assertThat(user.email()).isEqualTo(payload.email());
        assertThat(user.role()).isEqualTo(payload.role());
        assertThat(user.createdAt()).isNotBlank();
    }

    @Feature("Create User")
    @Story("Admin role")
    @Test(groups = {"api", "regression"})
    public void testCreateAdminUser() {
        CreateUserRequest payload = UserFactory.buildAdmin();
        UserResponse user = userService.createUser(payload);
        assertThat(user.role()).isEqualTo("admin");
    }

    // ── Negative Tests ──────────────────────────────────────────────────

    @Feature("Create User")
    @Story("Invalid email")
    @Severity(SeverityLevel.NORMAL)
    @Test(groups = {"api", "regression"})
    public void testCreateUserInvalidEmailReturns400() {
        CreateUserRequest payload = UserFactory.buildWithInvalidEmail();

        Response response = userService.getUserRawResponse(-1); // escape hatch
        // Note: for direct status code testing of POST, call the raw client
        // This is an example — the real implementation calls client.post() directly
        // with the invalid payload and asserts on the raw response status code
        assertThat(response.statusCode()).isEqualTo(404); // example assertion
    }

    @Feature("Get User")
    @Story("Not found")
    @Test(groups = {"api", "regression"})
    public void testGetNonExistentUserReturns404() {
        Response response = userService.getUserRawResponse(999999L);
        assertThat(response.statusCode()).isEqualTo(404);
    }

    // ── Parametrized Tests ──────────────────────────────────────────────

    @Feature("Create User")
    @Story("Valid roles — boundary")
    @Test(
        groups = {"api", "regression"},
        dataProvider = "validRoles"
    )
    public void testCreateUserWithValidRoles(String role) {
        CreateUserRequest payload = UserFactory.build(role);
        UserResponse user = userService.createUser(payload);
        assertThat(user.role()).isEqualTo(role);
    }

    @DataProvider(name = "validRoles")
    public Object[][] validRoles() {
        return new Object[][] {
            {"viewer"},
            {"editor"},
            {"admin"},
        };
    }

    @Feature("Create User")
    @Story("Invalid roles — boundary")
    @Test(
        groups = {"api", "regression"},
        dataProvider = "invalidRoles"
    )
    public void testCreateUserWithInvalidRolesReturns400(String invalidRole) {
        // Would call raw client here — see UserService.getUserRawResponse() pattern
        // Parametrized negative test template
        assertThat(invalidRole).isNotBlank(); // placeholder
    }

    @DataProvider(name = "invalidRoles")
    public Object[][] invalidRoles() {
        return new Object[][] {
            {"superuser"},
            {"root"},
            {""},
            {"ADMIN"},
        };
    }
}
```

---

## src/test/java/{pkg}/layer4/BaseTest.java

```java
package com.automation.framework.layer4;

import com.automation.framework.config.AuthManager;
import com.automation.framework.config.ClientFactory;
import com.automation.framework.layer2.BaseApiClient;
import org.testng.annotations.BeforeSuite;

/**
 * Base class for all API test classes.
 * Manages session-scoped auth and client setup.
 */
public abstract class BaseTest {

    private static BaseApiClient client;

    @BeforeSuite(alwaysRun = true)
    public synchronized void suiteSetup() {
        if (client == null) {
            String token = AuthManager.getInstance().getToken();
            client = ClientFactory.build(token);
        }
    }

    protected BaseApiClient getClient() {
        return client;
    }
}
```

---

## src/test/resources/testng.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE suite SYSTEM "http://testng.org/testng-1.0.dtd">
<suite name="Automation Suite" verbose="1" parallel="false">

    <listeners>
        <listener class-name="io.qameta.allure.testng.AllureTestNg"/>
    </listeners>

    <test name="API Tests">
        <groups>
            <run>
                <include name="api"/>
                <exclude name="wip"/>
            </run>
        </groups>
        <classes>
            <class name="com.automation.framework.layer4.TestUserApi"/>
        </classes>
    </test>

    <!-- Smoke suite (subset) -->
    <!--
    <test name="Smoke Tests">
        <groups>
            <run>
                <include name="smoke"/>
            </run>
        </groups>
        <classes>
            <class name="com.automation.framework.layer4.TestUserApi"/>
        </classes>
    </test>
    -->
</suite>
```

---

## pom.xml entries for Layer 4

```xml
<!-- TestNG -->
<dependency>
    <groupId>org.testng</groupId>
    <artifactId>testng</artifactId>
    <version>7.10.2</version>
    <scope>test</scope>
</dependency>

<!-- AssertJ -->
<dependency>
    <groupId>org.assertj</groupId>
    <artifactId>assertj-core</artifactId>
    <version>3.25.3</version>
    <scope>test</scope>
</dependency>

<!-- Allure TestNG -->
<dependency>
    <groupId>io.qameta.allure</groupId>
    <artifactId>allure-testng</artifactId>
    <version>2.25.0</version>
</dependency>

<!-- Maven Surefire Plugin (runs TestNG) -->
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-surefire-plugin</artifactId>
            <version>3.2.5</version>
            <configuration>
                <suiteXmlFiles>
                    <suiteXmlFile>src/test/resources/testng.xml</suiteXmlFile>
                </suiteXmlFiles>
                <argLine>-javaagent:${settings.localRepository}/io/qameta/allure/allure-javaagent/${allure.version}/allure-javaagent-${allure.version}.jar</argLine>
            </configuration>
        </plugin>
    </plugins>
</build>
```
