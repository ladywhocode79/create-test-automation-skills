# Layer 3 — Page Objects (Java / Selenium WebDriver)

---

## src/main/java/{pkg}/layer1/locators/LoginLocators.java

```java
package com.automation.framework.layer1.locators;

import org.openqa.selenium.By;

/**
 * Locator registry for the Login page.
 * All selectors live here — never inline in page object methods.
 */
public final class LoginLocators {

    private LoginLocators() {}   // utility class — no instantiation

    // data-testid strategy (default)
    public static final By USERNAME_INPUT    = By.cssSelector("[data-testid='login-username']");
    public static final By PASSWORD_INPUT    = By.cssSelector("[data-testid='login-password']");
    public static final By SUBMIT_BUTTON     = By.cssSelector("[data-testid='login-submit']");
    public static final By ERROR_MESSAGE     = By.cssSelector("[data-testid='login-error']");
    public static final By FORGOT_PASSWORD   = By.cssSelector("[data-testid='forgot-password']");
    public static final By LOADING_SPINNER   = By.cssSelector("[data-testid='login-spinner']");

    // XPath variant (if user selected XPath):
    // public static final By USERNAME_INPUT = By.xpath("//input[@name='username']");
}
```

---

## src/main/java/{pkg}/layer3/LoginPage.java

```java
package com.automation.framework.layer3;

import com.automation.framework.layer1.formdata.LoginFormData;
import com.automation.framework.layer1.locators.LoginLocators;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;

/**
 * Page Object for the Login page.
 *
 * Rules:
 * - All locators from LoginLocators (Layer 1), never inline
 * - No assertions in any method
 * - Navigation methods return the next page object (fluent)
 * - All waits are explicit (WebDriverWait) — no Thread.sleep()
 */
public class LoginPage {

    private final WebDriver driver;
    private final WebDriverWait wait;
    private static final String URL = "/login";

    public LoginPage(WebDriver driver) {
        this.driver = driver;
        this.wait = new WebDriverWait(driver, Duration.ofSeconds(10));
    }

    public LoginPage navigate() {
        driver.get(driver.getCurrentUrl().split("/login")[0] + URL);
        wait.until(ExpectedConditions.visibilityOfElementLocated(
            LoginLocators.USERNAME_INPUT
        ));
        return this;
    }

    /**
     * Perform full login. Returns DashboardPage on success.
     */
    public DashboardPage loginAs(LoginFormData formData) {
        driver.findElement(LoginLocators.USERNAME_INPUT).sendKeys(formData.username());
        driver.findElement(LoginLocators.PASSWORD_INPUT).sendKeys(formData.password());
        driver.findElement(LoginLocators.SUBMIT_BUTTON).click();

        // Wait for URL change away from login page
        wait.until(driver -> !driver.getCurrentUrl().contains("/login"));

        return new DashboardPage(driver);
    }

    /**
     * Attempt login expecting failure. Returns self (stays on login page).
     */
    public LoginPage loginAndExpectError(LoginFormData formData) {
        driver.findElement(LoginLocators.USERNAME_INPUT).sendKeys(formData.username());
        driver.findElement(LoginLocators.PASSWORD_INPUT).sendKeys(formData.password());
        driver.findElement(LoginLocators.SUBMIT_BUTTON).click();

        wait.until(ExpectedConditions.visibilityOfElementLocated(
            LoginLocators.ERROR_MESSAGE
        ));
        return this;
    }

    public String getErrorMessage() {
        return driver.findElement(LoginLocators.ERROR_MESSAGE).getText();
    }

    public boolean isSubmitEnabled() {
        return driver.findElement(LoginLocators.SUBMIT_BUTTON).isEnabled();
    }
}
```

---

## src/main/java/{pkg}/layer3/DashboardPage.java

```java
package com.automation.framework.layer3;

import com.automation.framework.layer1.locators.DashboardLocators;
import com.automation.framework.layer3.components.HeaderComponent;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;

public class DashboardPage {

    private final WebDriver driver;
    private final WebDriverWait wait;

    public DashboardPage(WebDriver driver) {
        this.driver = driver;
        this.wait = new WebDriverWait(driver, Duration.ofSeconds(15));
    }

    public DashboardPage waitUntilReady() {
        wait.until(ExpectedConditions.urlContains("/dashboard"));
        wait.until(ExpectedConditions.visibilityOfElementLocated(
            DashboardLocators.WELCOME_HEADING
        ));
        return this;
    }

    public String getWelcomeHeading() {
        return driver.findElement(DashboardLocators.WELCOME_HEADING).getText();
    }

    public boolean isLoaded() {
        return driver.findElement(DashboardLocators.WELCOME_HEADING).isDisplayed();
    }

    public HeaderComponent getHeader() {
        return new HeaderComponent(driver);
    }
}
```

---

## src/main/java/{pkg}/layer3/components/HeaderComponent.java

```java
package com.automation.framework.layer3.components;

import com.automation.framework.layer1.locators.DashboardLocators;
import com.automation.framework.layer3.LoginPage;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;

public class HeaderComponent {

    private final WebDriver driver;
    private final WebDriverWait wait;

    public HeaderComponent(WebDriver driver) {
        this.driver = driver;
        this.wait = new WebDriverWait(driver, Duration.ofSeconds(5));
    }

    public LoginPage logout() {
        driver.findElement(DashboardLocators.NAV_PROFILE).click();
        driver.findElement(DashboardLocators.NAV_LOGOUT).click();
        wait.until(ExpectedConditions.urlContains("/login"));
        return new LoginPage(driver);
    }

    public boolean isVisible() {
        return driver.findElement(DashboardLocators.NAV_MENU).isDisplayed();
    }
}
```

---

## src/main/java/{pkg}/layer1/formdata/LoginFormData.java

```java
package com.automation.framework.layer1.formdata;

import com.github.javafaker.Faker;

/**
 * Typed form data for the Login form.
 * Record ensures immutability — created once, passed to page object methods.
 */
public record LoginFormData(String username, String password) {

    private static final Faker faker = new Faker();

    public static LoginFormData build() {
        return new LoginFormData(
            faker.internet().emailAddress(),
            faker.internet().password(12, 20, true, true)
        );
    }

    public static LoginFormData build(String username, String password) {
        return new LoginFormData(username, password);
    }

    public static LoginFormData buildInvalidPassword() {
        return new LoginFormData(faker.internet().emailAddress(), "wrongpassword");
    }

    public static LoginFormData buildEmpty() {
        return new LoginFormData("", "");
    }
}
```
