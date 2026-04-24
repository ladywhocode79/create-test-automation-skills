# Shared — Environment Config (Java / Owner Library)

---

## src/main/java/{pkg}/config/EnvConfig.java

```java
package com.automation.framework.config;

import org.aeonbits.owner.Config;
import org.aeonbits.owner.ConfigFactory;

/**
 * Type-safe environment configuration using the Owner library.
 *
 * Owner maps @Key annotations to environment variables / properties files.
 * Priority: System env vars > config.properties > @DefaultValue.
 *
 * Usage: EnvConfig.get().baseUrl()
 */
@Config.Sources({
    "system:env",                              // 1st priority: CI / environment vars
    "classpath:config.properties"              // 2nd priority: local .properties file
})
public interface EnvConfig extends Config {

    EnvConfig INSTANCE = ConfigFactory.create(EnvConfig.class, System.getenv());

    static EnvConfig get() {
        return INSTANCE;
    }

    // ── API Configuration ──────────────────────────────────────────────────
    @Key("BASE_URL")
    String baseUrl();

    @Key("TEST_MODE")
    @DefaultValue("mock")
    String testMode();

    // ── Auth Configuration ─────────────────────────────────────────────────
    @Key("TOKEN_URL")
    @DefaultValue("")
    String tokenUrl();

    @Key("CLIENT_ID")
    @DefaultValue("")
    String clientId();

    @Key("CLIENT_SECRET")
    @DefaultValue("")
    String clientSecret();

    @Key("API_TOKEN")
    @DefaultValue("")
    String apiToken();

    // ── HTTP Client ────────────────────────────────────────────────────────
    @Key("MAX_RETRIES")
    @DefaultValue("3")
    int maxRetries();

    @Key("REQUEST_TIMEOUT")
    @DefaultValue("30")
    int requestTimeoutSeconds();

    // ── UI Configuration ───────────────────────────────────────────────────
    @Key("AUT_BASE_URL")
    @DefaultValue("http://localhost:3000")
    String autBaseUrl();

    @Key("BROWSER")
    @DefaultValue("chrome")
    String browser();

    @Key("HEADLESS")
    @DefaultValue("true")
    boolean headless();

    @Key("DEFAULT_TIMEOUT_MS")
    @DefaultValue("10000")
    int defaultTimeoutMs();

    @Key("TEST_USERNAME")
    @DefaultValue("")
    String testUsername();

    @Key("TEST_PASSWORD")
    @DefaultValue("")
    String testPassword();

    // ── WireMock ───────────────────────────────────────────────────────────
    @Key("WIREMOCK_BASE_URL")
    @DefaultValue("http://localhost:8080")
    String wireMockBaseUrl();

    // ── Reporting ──────────────────────────────────────────────────────────
    @Key("LOG_LEVEL")
    @DefaultValue("INFO")
    String logLevel();
}
```

---

## src/test/resources/config.properties

```properties
# ── API Configuration ──────────────────────────────────────────────────────
BASE_URL=https://api.staging.yourcompany.com
TEST_MODE=mock

# ── Auth (fill in for your environment) ───────────────────────────────────
TOKEN_URL=https://auth.yourcompany.com/oauth/token
CLIENT_ID=your-client-id
CLIENT_SECRET=your-client-secret

# ── HTTP Client ────────────────────────────────────────────────────────────
MAX_RETRIES=3
REQUEST_TIMEOUT=30

# ── UI Configuration ───────────────────────────────────────────────────────
AUT_BASE_URL=http://localhost:3000
BROWSER=chrome
HEADLESS=true
DEFAULT_TIMEOUT_MS=10000
TEST_USERNAME=test@example.com
TEST_PASSWORD=

# ── WireMock ───────────────────────────────────────────────────────────────
WIREMOCK_BASE_URL=http://localhost:8080

# ── Reporting ──────────────────────────────────────────────────────────────
LOG_LEVEL=INFO
```

**Important:** Add `config.properties` to `.gitignore` if it contains real credentials.
Commit `config.properties.example` (with placeholder values) instead.

---

## pom.xml dependency

```xml
<!-- Owner — type-safe config -->
<dependency>
    <groupId>org.aeonbits.owner</groupId>
    <artifactId>owner</artifactId>
    <version>1.0.12</version>
</dependency>
```

---

## src/main/java/{pkg}/config/Logger.java

```java
package com.automation.framework.config;

import org.slf4j.LoggerFactory;

/**
 * Logger factory wrapper.
 * Usage: private static final Logger log = Logger.get(MyClass.class);
 */
public final class Logger {

    private Logger() {}

    public static org.slf4j.Logger get(Class<?> clazz) {
        return LoggerFactory.getLogger(clazz);
    }
}
```

```xml
<!-- SLF4J + Logback for Java logging -->
<dependency>
    <groupId>ch.qos.logback</groupId>
    <artifactId>logback-classic</artifactId>
    <version>1.5.6</version>
</dependency>
```

```xml
<!-- src/test/resources/logback-test.xml -->
<configuration>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{HH:mm:ss.SSS} | %-5level | %logger{30} | %msg%n</pattern>
        </encoder>
    </appender>
    <root level="INFO">
        <appender-ref ref="STDOUT"/>
    </root>
</configuration>
```
