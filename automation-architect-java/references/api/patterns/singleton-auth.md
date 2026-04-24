# Pattern: Singleton — Auth Manager (Java)

---

## src/main/java/{pkg}/config/AuthManager.java

```java
package com.automation.framework.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Instant;
import java.util.concurrent.locks.ReentrantLock;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Thread-safe Singleton auth manager for OAuth2 Client Credentials.
 *
 * Guarantees one token fetch per session with TTL-aware refresh.
 * Uses double-checked locking for thread safety in parallel test runs.
 */
public class AuthManager {

    private static final Logger log = LoggerFactory.getLogger(AuthManager.class);
    private static final ObjectMapper mapper = new ObjectMapper();
    private static final ReentrantLock lock = new ReentrantLock();
    private static final int BUFFER_SECONDS = 30;

    private static volatile AuthManager instance;
    private String token;
    private Instant expiresAt = Instant.EPOCH;

    private AuthManager() {}

    public static AuthManager getInstance() {
        if (instance == null) {
            lock.lock();
            try {
                if (instance == null) {
                    instance = new AuthManager();
                }
            } finally {
                lock.unlock();
            }
        }
        return instance;
    }

    public String getToken() {
        lock.lock();
        try {
            if (isExpired()) {
                refresh();
            }
            return token;
        } finally {
            lock.unlock();
        }
    }

    public void invalidate() {
        lock.lock();
        try {
            expiresAt = Instant.EPOCH;
        } finally {
            lock.unlock();
        }
    }

    private boolean isExpired() {
        return Instant.now().isAfter(expiresAt.minusSeconds(BUFFER_SECONDS));
    }

    private void refresh() {
        EnvConfig config = EnvConfig.get();
        log.info("Fetching new access token from {}", config.tokenUrl());

        String formBody = "grant_type=client_credentials"
            + "&client_id=" + config.clientId()
            + "&client_secret=" + config.clientSecret();

        try {
            HttpClient httpClient = HttpClient.newHttpClient();
            HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(config.tokenUrl()))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(formBody))
                .build();

            HttpResponse<String> response = httpClient.send(
                request, HttpResponse.BodyHandlers.ofString()
            );

            if (response.statusCode() != 200) {
                throw new RuntimeException(
                    "Token fetch failed with status: " + response.statusCode()
                );
            }

            JsonNode json = mapper.readTree(response.body());
            token = json.get("access_token").asText();
            long expiresIn = json.has("expires_in")
                ? json.get("expires_in").asLong()
                : 3600L;
            expiresAt = Instant.now().plusSeconds(expiresIn);

            log.info("Access token acquired. Expires in {} seconds.", expiresIn);

        } catch (IOException | InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Failed to fetch auth token", e);
        }
    }
}
```

---

## src/main/java/{pkg}/layer1/factories/UserFactory.java

```java
package com.automation.framework.layer1.factories;

import com.automation.framework.layer1.CreateUserRequest;
import com.github.javafaker.Faker;

/**
 * Factory for generating valid CreateUserRequest instances.
 * Uses JavaFaker for randomized, realistic test data.
 */
public class UserFactory {

    private static final Faker faker = new Faker();

    public static CreateUserRequest build() {
        return build("viewer");
    }

    public static CreateUserRequest build(String role) {
        return new CreateUserRequest(
            faker.name().username().replace(".", "_").substring(0, Math.min(20,
                faker.name().username().replace(".", "_").length())),
            faker.internet().emailAddress(),
            role
        );
    }

    public static CreateUserRequest buildAdmin() {
        return build("admin");
    }

    public static CreateUserRequest buildEditor() {
        return build("editor");
    }

    public static CreateUserRequest buildWithInvalidEmail() {
        return new CreateUserRequest(
            faker.name().username(),
            "not-a-valid-email",
            "viewer"
        );
    }

    public static CreateUserRequest buildWithInvalidRole() {
        return new CreateUserRequest(
            faker.name().username(),
            faker.internet().emailAddress(),
            "superuser"
        );
    }
}
```

---

## pom.xml dependencies

```xml
<!-- JavaFaker -->
<dependency>
    <groupId>com.github.javafaker</groupId>
    <artifactId>javafaker</artifactId>
    <version>1.0.2</version>
</dependency>
```
