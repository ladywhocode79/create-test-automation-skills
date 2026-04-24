# WireMock Docker Setup

Complete Docker configuration and stub files generated for all tracks.

---

## docker-compose.yml

```yaml
# docker-compose.yml (project root)
services:
  wiremock:
    image: wiremock/wiremock:3.3.1
    container_name: wiremock
    ports:
      - "8080:8080"
    volumes:
      - ./mocks/stubs:/home/wiremock/mappings   # stubs loaded at startup
      - ./mocks/files:/home/wiremock/__files     # static response files (optional)
    command: >
      --global-response-templating
      --verbose
      --port 8080
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/__admin/health"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 5s
```

Local commands:
```bash
docker-compose up -d wiremock        # start in background
docker-compose logs -f wiremock      # tail logs
docker-compose down                  # stop + remove container
curl http://localhost:8080/__admin/health   # verify running
```

---

## mocks/stubs/auth_stubs.json

```json
{
  "mappings": [
    {
      "name": "post-token-client-credentials-success",
      "request": {
        "method": "POST",
        "url": "/oauth/token",
        "bodyPatterns": [
          {
            "contains": "grant_type=client_credentials"
          }
        ]
      },
      "response": {
        "status": 200,
        "headers": {
          "Content-Type": "application/json"
        },
        "jsonBody": {
          "access_token": "mock-access-token-abc123xyz",
          "token_type": "Bearer",
          "expires_in": 3600,
          "scope": "read write"
        }
      }
    },
    {
      "name": "post-token-invalid-credentials",
      "priority": 1,
      "request": {
        "method": "POST",
        "url": "/oauth/token",
        "bodyPatterns": [
          {
            "contains": "client_id=invalid"
          }
        ]
      },
      "response": {
        "status": 401,
        "headers": {
          "Content-Type": "application/json"
        },
        "jsonBody": {
          "error": "invalid_client",
          "error_description": "Client authentication failed"
        }
      }
    }
  ]
}
```

---

## mocks/stubs/user_stubs.json

```json
{
  "mappings": [
    {
      "name": "post-user-success",
      "request": {
        "method": "POST",
        "url": "/api/v1/users",
        "headers": {
          "Content-Type": { "equalTo": "application/json" },
          "Authorization": { "matches": "Bearer .+" }
        }
      },
      "response": {
        "status": 201,
        "headers": {
          "Content-Type": "application/json"
        },
        "jsonBody": {
          "id": 1001,
          "username": "{{jsonPath request.body '$.username'}}",
          "email": "{{jsonPath request.body '$.email'}}",
          "role": "{{jsonPath request.body '$.role'}}",
          "created_at": "{{now format='yyyy-MM-dd\\'T\\'HH:mm:ss\\'Z\\''}}"
        }
      }
    },
    {
      "name": "get-user-by-id-success",
      "request": {
        "method": "GET",
        "urlPattern": "/api/v1/users/([1-9][0-9]*)"
      },
      "response": {
        "status": 200,
        "headers": {
          "Content-Type": "application/json"
        },
        "jsonBody": {
          "id": 1001,
          "username": "testuser",
          "email": "test@example.com",
          "role": "viewer",
          "created_at": "2024-01-15T10:00:00Z",
          "updated_at": null
        }
      }
    },
    {
      "name": "get-user-not-found",
      "priority": 1,
      "request": {
        "method": "GET",
        "urlPattern": "/api/v1/users/9{4,}"
      },
      "response": {
        "status": 404,
        "headers": {
          "Content-Type": "application/json"
        },
        "jsonBody": {
          "error": "User not found",
          "code": "USER_NOT_FOUND",
          "request_id": "{{randomValue length=8 type='ALPHANUMERIC'}}"
        }
      }
    },
    {
      "name": "get-user-list-success",
      "request": {
        "method": "GET",
        "url": "/api/v1/users"
      },
      "response": {
        "status": 200,
        "headers": {
          "Content-Type": "application/json"
        },
        "jsonBody": {
          "items": [
            {
              "id": 1001,
              "username": "testuser1",
              "email": "user1@example.com",
              "role": "viewer",
              "created_at": "2024-01-15T10:00:00Z"
            },
            {
              "id": 1002,
              "username": "testuser2",
              "email": "user2@example.com",
              "role": "admin",
              "created_at": "2024-01-16T10:00:00Z"
            }
          ],
          "total": 2,
          "page": 1,
          "page_size": 20
        }
      }
    },
    {
      "name": "delete-user-success",
      "request": {
        "method": "DELETE",
        "urlPattern": "/api/v1/users/([1-9][0-9]*)"
      },
      "response": {
        "status": 204
      }
    }
  ]
}
```

---

## Response Templating Reference

WireMock's `--global-response-templating` flag enables these helpers in stubs:

```
{{jsonPath request.body '$.fieldName'}}    Extract from request JSON body
{{request.headers.Authorization}}          Access request header
{{randomValue length=8 type='ALPHANUMERIC'}} Random string
{{now format='yyyy-MM-dd'}}                Current timestamp
{{now offset='3 days' format='yyyy-MM-dd'}} Offset timestamp
{{request.pathSegments.[2]}}               URL path segment (0-indexed)
```
