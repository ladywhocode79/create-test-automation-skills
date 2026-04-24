# Layer 2 — Browser Session (Java / Selenium WebDriver + WebDriverManager)

---

## src/main/java/{pkg}/layer2/BrowserSession.java

```java
package com.automation.framework.layer2;

import com.automation.framework.config.EnvConfig;
import io.github.bonigarcia.wdm.WebDriverManager;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.firefox.FirefoxDriver;
import org.openqa.selenium.firefox.FirefoxOptions;
import org.openqa.selenium.safari.SafariDriver;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;

/**
 * Browser factory: creates the correct WebDriver instance based on
 * BROWSER environment variable. Used by DriverManager (Singleton/ThreadLocal).
 *
 * Never instantiated by tests directly — accessed via DriverManager.
 */
public class BrowserSession {

    private static final Logger log = LoggerFactory.getLogger(BrowserSession.class);

    public static WebDriver create() {
        String browser = EnvConfig.get().browser().toLowerCase();
        boolean headless = EnvConfig.get().headless();
        log.info("Creating {} driver (headless={})", browser, headless);

        return switch (browser) {
            case "chrome", "chromium" -> createChrome(headless);
            case "firefox" -> createFirefox(headless);
            case "safari" -> createSafari();
            default -> throw new IllegalArgumentException(
                "Unsupported BROWSER: '" + browser + "'. Expected: chrome, firefox, safari."
            );
        };
    }

    private static WebDriver createChrome(boolean headless) {
        WebDriverManager.chromedriver().setup();
        ChromeOptions options = new ChromeOptions();
        if (headless) {
            options.addArguments("--headless=new");
        }
        options.addArguments(
            "--no-sandbox",
            "--disable-dev-shm-usage",
            "--disable-gpu",
            "--window-size=1920,1080"
        );
        WebDriver driver = new ChromeDriver(options);
        driver.manage().timeouts()
            .implicitlyWait(Duration.ofMillis(0))         // explicit waits only
            .pageLoadTimeout(Duration.ofSeconds(30))
            .scriptTimeout(Duration.ofSeconds(10));
        return driver;
    }

    private static WebDriver createFirefox(boolean headless) {
        WebDriverManager.firefoxdriver().setup();
        FirefoxOptions options = new FirefoxOptions();
        if (headless) {
            options.addArguments("-headless");
        }
        return new FirefoxDriver(options);
    }

    private static WebDriver createSafari() {
        // Safari driver pre-installed on macOS — no WebDriverManager needed
        // Requires: safaridriver --enable (run once)
        return new SafariDriver();
    }
}
```

---

## src/main/java/{pkg}/config/DriverManager.java

```java
package com.automation.framework.config;

import com.automation.framework.layer2.BrowserSession;
import org.openqa.selenium.WebDriver;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * ThreadLocal WebDriver manager.
 *
 * ThreadLocal ensures each test thread gets its own driver instance,
 * enabling parallel test execution via TestNG parallel="methods".
 *
 * For sequential execution, ThreadLocal still works correctly —
 * the single thread gets one driver, reused across tests.
 */
public class DriverManager {

    private static final Logger log = LoggerFactory.getLogger(DriverManager.class);
    private static final ThreadLocal<WebDriver> driverPool = new ThreadLocal<>();

    private DriverManager() {}

    public static WebDriver getDriver() {
        if (driverPool.get() == null) {
            driverPool.set(BrowserSession.create());
            log.info("WebDriver created for thread: {}", Thread.currentThread().getName());
        }
        return driverPool.get();
    }

    public static void quit() {
        WebDriver driver = driverPool.get();
        if (driver != null) {
            driver.quit();
            driverPool.remove();
            log.info("WebDriver closed for thread: {}", Thread.currentThread().getName());
        }
    }
}
```

---

## src/test/java/{pkg}/layer4/BaseUiTest.java

```java
package com.automation.framework.layer4;

import com.automation.framework.config.DriverManager;
import com.automation.framework.config.EnvConfig;
import io.qameta.allure.Attachment;
import org.openqa.selenium.OutputType;
import org.openqa.selenium.TakesScreenshot;
import org.openqa.selenium.WebDriver;
import org.testng.ITestResult;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;

/**
 * Base class for all UI test classes.
 * Manages WebDriver lifecycle and screenshot on failure.
 */
public abstract class BaseUiTest {

    protected WebDriver driver;
    protected String baseUrl;

    @BeforeMethod(alwaysRun = true)
    public void setUpDriver() {
        driver = DriverManager.getDriver();
        baseUrl = EnvConfig.get().autBaseUrl();
        driver.get(baseUrl);
    }

    @AfterMethod(alwaysRun = true)
    public void tearDown(ITestResult result) {
        if (result.getStatus() == ITestResult.FAILURE) {
            captureScreenshot(result.getName());
        }
        DriverManager.quit();
    }

    @Attachment(value = "{testName} - failure screenshot", type = "image/png")
    private byte[] captureScreenshot(String testName) {
        return ((TakesScreenshot) driver).getScreenshotAs(OutputType.BYTES);
    }
}
```

---

## pom.xml dependencies for UI

```xml
<!-- Selenium WebDriver -->
<dependency>
    <groupId>org.seleniumhq.selenium</groupId>
    <artifactId>selenium-java</artifactId>
    <version>4.21.0</version>
</dependency>

<!-- WebDriverManager (auto-downloads browser drivers) -->
<dependency>
    <groupId>io.github.bonigarcia</groupId>
    <artifactId>webdrivermanager</artifactId>
    <version>5.8.0</version>
</dependency>
```

---

## Key Design Decisions

1. **`implicitlyWait(Duration.ofMillis(0))`**: Implicit waits are disabled.
   All waits are explicit (`WebDriverWait`). Mixing implicit + explicit waits
   causes unpredictable timeouts.

2. **ThreadLocal vs Singleton**:
   - Sequential (`parallel="false"` in testng.xml): ThreadLocal works as Singleton
   - Parallel (`parallel="methods"`): each thread gets its own driver automatically
   - No code changes needed to switch — only testng.xml attribute changes

3. **`@AfterMethod(alwaysRun = true)`**: Screenshot is captured and `quit()`
   is called even if `@BeforeMethod` fails. Prevents driver leak on setup failure.

4. **WebDriverManager**: Automatically downloads and configures the correct
   driver binary for the installed browser version. No manual chromedriver setup.
