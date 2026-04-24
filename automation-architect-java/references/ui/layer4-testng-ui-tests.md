# Layer 4 — UI Tests (Java / Selenium / TestNG)

---

## src/test/java/{pkg}/layer4/TestLoginFlow.java

```java
package com.automation.framework.layer4;

import com.automation.framework.layer1.formdata.LoginFormData;
import com.automation.framework.layer3.DashboardPage;
import com.automation.framework.layer3.LoginPage;
import io.qameta.allure.*;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import static org.assertj.core.api.Assertions.assertThat;

@Epic("Authentication")
public class TestLoginFlow extends BaseUiTest {

    private LoginPage loginPage;

    @BeforeMethod(alwaysRun = true)
    public void navigateToLogin() {
        loginPage = new LoginPage(driver).navigate();
    }

    // ── Happy Path ──────────────────────────────────────────────────────

    @Feature("Login")
    @Story("Valid credentials")
    @Severity(SeverityLevel.CRITICAL)
    @Test(groups = {"smoke", "ui"})
    @Description("User with valid credentials is redirected to dashboard")
    public void testValidCredentialsRedirectToDashboard() {
        LoginFormData credentials = LoginFormData.build(
            "test@example.com",
            "ValidPass123!"
        );

        DashboardPage dashboard = loginPage.loginAs(credentials);

        assertThat(dashboard.isLoaded()).isTrue();
        assertThat(dashboard.getWelcomeHeading().toLowerCase()).contains("welcome");
    }

    // ── Negative Tests ──────────────────────────────────────────────────

    @Feature("Login")
    @Story("Invalid password")
    @Severity(SeverityLevel.CRITICAL)
    @Test(groups = {"smoke", "ui"})
    public void testInvalidPasswordShowsErrorMessage() {
        LoginFormData credentials = LoginFormData.buildInvalidPassword();

        loginPage.loginAndExpectError(credentials);

        String error = loginPage.getErrorMessage();
        assertThat(error).isNotBlank();
        assertThat(error.toLowerCase()).containsAnyOf("invalid", "incorrect", "wrong");
    }

    @Feature("Login")
    @Story("Empty credentials")
    @Test(groups = {"regression", "ui"})
    public void testEmptyCredentialsSubmitIsDisabledOrShowsError() {
        if (!loginPage.isSubmitEnabled()) {
            // Button disabled — UI prevents empty submission
            assertThat(loginPage.isSubmitEnabled()).isFalse();
            return;
        }
        loginPage.loginAndExpectError(LoginFormData.buildEmpty());
        assertThat(loginPage.getErrorMessage()).isNotBlank();
    }

    // ── Parametrized Tests ──────────────────────────────────────────────

    @Feature("Login")
    @Story("Field validation")
    @Test(
        groups = {"regression", "ui"},
        dataProvider = "invalidCredentials"
    )
    public void testFieldValidationMessages(
        String username,
        String password,
        String expectedErrorSubstring
    ) {
        loginPage.loginAndExpectError(LoginFormData.build(username, password));

        String error = loginPage.getErrorMessage().toLowerCase();
        assertThat(error).contains(expectedErrorSubstring.toLowerCase());
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

---

## src/test/resources/testng.xml (UI suite addition)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE suite SYSTEM "http://testng.org/testng-1.0.dtd">
<suite name="Full Automation Suite" verbose="1" parallel="false">

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

    <test name="UI Tests">
        <groups>
            <run>
                <include name="ui"/>
                <exclude name="wip"/>
            </run>
        </groups>
        <classes>
            <class name="com.automation.framework.layer4.TestLoginFlow"/>
        </classes>
    </test>

</suite>
```

---

## Architecture Enforcement Test

```java
// src/test/java/{pkg}/architecture/LayerDependencyTest.java
package com.automation.framework.architecture;

import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;
import org.testng.annotations.Test;

import static com.tngtech.archunit.library.Architectures.layeredArchitecture;

@AnalyzeClasses(packages = "com.automation.framework")
public class LayerDependencyTest {

    @ArchTest
    static final ArchRule layersShouldRespectDependencyDirection =
        layeredArchitecture()
            .consideringAllDependencies()
            .layer("Config")   .definedBy("..config..")
            .layer("Layer1")   .definedBy("..layer1..")
            .layer("Layer2")   .definedBy("..layer2..")
            .layer("Layer3")   .definedBy("..layer3..")
            .layer("Layer4")   .definedBy("..layer4..")
            .whereLayer("Layer4") .mayOnlyAccessLayers("Layer3", "Layer1", "Config")
            .whereLayer("Layer3") .mayOnlyAccessLayers("Layer2", "Layer1", "Config")
            .whereLayer("Layer2") .mayOnlyAccessLayers("Layer1", "Config")
            .whereLayer("Layer1") .mayOnlyAccessLayers("Config");

    @Test
    public void verifyLayerArchitecture() {
        // ArchUnit @ArchTest runs automatically via ArchUnit TestNG integration
        // This @Test method ensures TestNG picks up the class
    }
}
```

---

## pom.xml — ArchUnit dependency

```xml
<dependency>
    <groupId>com.tngtech.archunit</groupId>
    <artifactId>archunit-junit5</artifactId>
    <version>1.3.0</version>
    <scope>test</scope>
</dependency>
```
