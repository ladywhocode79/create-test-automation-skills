# Layer 3 — Service Layer (Java / RestAssured)

---

## src/main/java/{pkg}/layer3/UserService.java

```java
package com.automation.framework.layer3;

import com.automation.framework.layer1.CreateUserRequest;
import com.automation.framework.layer1.UserResponse;
import com.automation.framework.layer2.BaseApiClient;
import io.restassured.response.Response;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

/**
 * Service class for User resource domain operations.
 *
 * Rules:
 * - Accepts typed model objects as input
 * - Returns typed model objects as output (never raw Response)
 * - Validates HTTP status on success paths — throws AssertionError on unexpected status
 * - Contains zero test assertions (no assertEquals, no assertThat here)
 * - One service class per resource domain
 */
public class UserService {

    private static final Logger log = LoggerFactory.getLogger(UserService.class);
    private static final String ENDPOINT = "/api/v1/users";

    private final BaseApiClient client;

    public UserService(BaseApiClient client) {
        this.client = client;
    }

    /**
     * POST /api/v1/users — create a new user.
     * @throws AssertionError if response status != 201
     */
    public UserResponse createUser(CreateUserRequest payload) {
        Response response = client.post(ENDPOINT, payload);
        response.then().statusCode(201);
        return response.as(UserResponse.class);
    }

    /**
     * GET /api/v1/users/{id} — retrieve user by ID.
     * @throws AssertionError if response status != 200
     */
    public UserResponse getUser(long userId) {
        Response response = client.get(ENDPOINT + "/{id}", userId);
        response.then().statusCode(200);
        return response.as(UserResponse.class);
    }

    /**
     * GET /api/v1/users — list users.
     */
    public List<UserResponse> listUsers() {
        Response response = client.get(ENDPOINT);
        response.then().statusCode(200);
        return response.jsonPath().getList("items", UserResponse.class);
    }

    /**
     * PUT /api/v1/users/{id} — full update.
     */
    public UserResponse updateUser(long userId, CreateUserRequest payload) {
        Response response = client.put(ENDPOINT + "/{id}", payload);
        response.then().statusCode(200);
        return response.as(UserResponse.class);
    }

    /**
     * DELETE /api/v1/users/{id}.
     */
    public void deleteUser(long userId) {
        client.delete(ENDPOINT + "/{id}", userId)
              .then().statusCode(204);
    }

    /**
     * Returns the raw Response for tests that need to assert on
     * error status codes or response headers directly.
     */
    public Response getUserRawResponse(long userId) {
        return client.get(ENDPOINT + "/{id}", userId);
    }
}
```

---

## Design Rules (same contract as Python track)

1. **Typed in, typed out** — `CreateUserRequest` in, `UserResponse` out.
   Never accept `Map<String, Object>` or return `JsonPath` in service methods.

2. **`response.as(Model.class)`** — Jackson deserializes and validates schema.
   If the API returns unexpected JSON, Jackson throws `JsonMappingException`
   which surfaces in Layer 4 as a test failure with a clear message.

3. **`.then().statusCode(N)`** in service methods — fails fast on unexpected
   status codes with RestAssured's built-in error message (includes response body).
   Use `getUserRawResponse()` escape hatch for negative test scenarios.

4. **No test assertions** — `.statusCode()` is a RestAssured validation, not
   a test assertion. It lives in the service method because it is part of the
   "contract of a successful operation", not a test scenario assertion.
