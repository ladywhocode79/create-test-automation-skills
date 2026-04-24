# Layer 1 — API Models (Java / Jackson + Bean Validation)

---

## src/main/java/{pkg}/layer1/CreateUserRequest.java

```java
package com.automation.framework.layer1;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Request model for POST /api/v1/users.
 *
 * Uses Java 21 record for immutability.
 * Jackson annotations control JSON serialization.
 * Jakarta Validation annotations document field constraints.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)   // exclude null fields from JSON output
public record CreateUserRequest(
    @NotBlank
    @Size(min = 3, max = 50)
    @Pattern(regexp = "^[a-zA-Z0-9_]+$", message = "username must be alphanumeric")
    @JsonProperty("username")
    String username,

    @NotBlank
    @Email
    @JsonProperty("email")
    String email,

    @NotBlank
    @Pattern(regexp = "^(viewer|editor|admin)$", message = "role must be viewer, editor, or admin")
    @JsonProperty("role")
    String role,

    @JsonProperty("first_name")
    String firstName,    // null = omitted from JSON (NON_NULL)

    @JsonProperty("last_name")
    String lastName
) {
    /** Convenience constructor with required fields only. */
    public CreateUserRequest(String username, String email, String role) {
        this(username, email, role, null, null);
    }
}
```

---

## src/main/java/{pkg}/layer1/UserResponse.java

```java
package com.automation.framework.layer1;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Response model for User API endpoints.
 * @JsonIgnoreProperties(ignoreUnknown = true) tolerates API adding new fields
 * without breaking tests — resilient to API evolution.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record UserResponse(
    @JsonProperty("id")         Long id,
    @JsonProperty("username")   String username,
    @JsonProperty("email")      String email,
    @JsonProperty("role")       String role,
    @JsonProperty("first_name") String firstName,
    @JsonProperty("last_name")  String lastName,
    @JsonProperty("created_at") String createdAt,
    @JsonProperty("updated_at") String updatedAt
) {}
```

---

## src/main/java/{pkg}/layer1/ApiErrorResponse.java

```java
package com.automation.framework.layer1;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public record ApiErrorResponse(
    @JsonProperty("error")      String error,
    @JsonProperty("code")       String code,
    @JsonProperty("request_id") String requestId
) {}
```

---

## pom.xml dependencies for Layer 1

```xml
<!-- Jackson -->
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.17.1</version>
</dependency>
<dependency>
    <groupId>com.fasterxml.jackson.datatype</groupId>
    <artifactId>jackson-datatype-jsr310</artifactId>
    <version>2.17.1</version>
</dependency>

<!-- Jakarta Bean Validation (annotations only — for documentation) -->
<dependency>
    <groupId>jakarta.validation</groupId>
    <artifactId>jakarta.validation-api</artifactId>
    <version>3.0.2</version>
</dependency>
```

---

## Naming Conventions

| Concept | Convention | Example |
|---|---|---|
| Request model | `Create{Resource}Request` | `CreateUserRequest` |
| Response model | `{Resource}Response` | `UserResponse` |
| Error response | `ApiErrorResponse` | shared across resources |
| File | `{Model}.java` | `CreateUserRequest.java` |
