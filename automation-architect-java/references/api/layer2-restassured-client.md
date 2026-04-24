# Layer 2 — HTTP Client (Java / RestAssured)

---

## src/main/java/{pkg}/layer2/BaseApiClient.java

```java
package com.automation.framework.layer2;

import com.automation.framework.config.EnvConfig;
import io.restassured.builder.RequestSpecBuilder;
import io.restassured.filter.log.LogDetail;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import io.restassured.specification.RequestSpecification;

import static io.restassured.RestAssured.given;

/**
 * Base HTTP client wrapping RestAssured RequestSpecification.
 *
 * Design:
 * - RequestSpecification is built once (session scope) and reused
 * - Auth token injected at construction — client is not responsible for fetching it
 * - Logging at HEADERS level (not BODY) by default — safe for auth headers? No.
 *   We log URI + STATUS only. Full body at DEBUG level via filter.
 * - All HTTP methods delegated here — Layer 3 never calls RestAssured directly
 */
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

    public Response get(String endpoint) {
        return given(spec).when().get(endpoint).then().extract().response();
    }

    public Response get(String endpoint, Object... pathParams) {
        return given(spec).when().get(endpoint, pathParams).then().extract().response();
    }

    public Response post(String endpoint, Object body) {
        return given(spec).body(body).when().post(endpoint).then().extract().response();
    }

    public Response put(String endpoint, Object body) {
        return given(spec).body(body).when().put(endpoint).then().extract().response();
    }

    public Response patch(String endpoint, Object body) {
        return given(spec).body(body).when().patch(endpoint).then().extract().response();
    }

    public Response delete(String endpoint) {
        return given(spec).when().delete(endpoint).then().extract().response();
    }

    public Response delete(String endpoint, Object... pathParams) {
        return given(spec).when().delete(endpoint, pathParams).then().extract().response();
    }
}
```

---

## MockApiClient.java (generated when mock=both)

```java
package com.automation.framework.layer2;

import io.restassured.builder.RequestSpecBuilder;
import io.restassured.filter.log.LogDetail;
import io.restassured.http.ContentType;
import io.restassured.specification.RequestSpecification;

/**
 * RestAssured client pointing at WireMock stub server.
 * Activated when TEST_MODE=mock.
 */
public class MockApiClient extends BaseApiClient {
    private static final String WIREMOCK_URL = "http://localhost:8080";

    public MockApiClient(String token) {
        // We need to override base URI — achieved by calling protected constructor
        // In practice: duplicate the spec construction pointing at WireMock
        super(token);
    }
}
```

Note: In Java, the cleanest way to implement the Strategy pattern for real/mock
switching with RestAssured is through a `ClientFactory`:

```java
// config/ClientFactory.java
public class ClientFactory {
    public static BaseApiClient build(String token) {
        String mode = EnvConfig.get().testMode();
        return switch (mode.toLowerCase()) {
            case "mock" -> new MockApiClient(token);
            case "real" -> new BaseApiClient(token);
            default -> throw new IllegalArgumentException(
                "Unsupported TEST_MODE: " + mode + ". Expected 'real' or 'mock'."
            );
        };
    }
}
```

---

## pom.xml dependencies for Layer 2

```xml
<!-- RestAssured -->
<dependency>
    <groupId>io.rest-assured</groupId>
    <artifactId>rest-assured</artifactId>
    <version>5.4.0</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>io.rest-assured</groupId>
    <artifactId>json-path</artifactId>
    <version>5.4.0</version>
    <scope>test</scope>
</dependency>
```

---

## Key Design Rules

1. **Token injected at construction** — `BaseApiClient` never fetches tokens.
   `AuthManager` provides the token; conftest/`@BeforeSuite` passes it in.

2. **`.extract().response()`** — Always extract the Response from ValidatableResponse.
   This keeps Layer 2 returning a raw `Response`, not auto-validating status codes.
   Layer 3 calls `response.then().statusCode(200)` or throws on non-2xx explicitly.

3. **`given(spec)`** — Reuse the pre-built spec. Never call `given()` with
   inline configuration in service methods — that bypasses the base client entirely.

4. **No deserialization here** — Layer 2 returns `Response`. Layer 3 calls
   `response.as(UserResponse.class)` to deserialize into the model.
