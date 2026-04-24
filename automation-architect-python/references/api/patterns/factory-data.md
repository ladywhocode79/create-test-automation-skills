# Pattern: Factory — Test Data (Python / API)

Generate `layer_1_models/api/factories/user_factory.py` always.

---

## layer_1_models/api/factories/user_factory.py

```python
from __future__ import annotations

from faker import Faker

from layer_1_models.api.user_model import CreateUserRequest

fake = Faker()
Faker.seed(0)   # Reproducible by default. Remove for fully random per-run.


class UserFactory:
    """
    Factory for generating valid CreateUserRequest objects.

    Design:
    - All methods are @staticmethod — no instance needed
    - .build(**overrides) is the primary API
    - Named variants cover common scenarios without polluting test methods
    """

    @staticmethod
    def build(**overrides: object) -> CreateUserRequest:
        """
        Build a valid CreateUserRequest with randomized data.
        Pass keyword arguments to override specific fields.

        Examples:
            UserFactory.build()
            UserFactory.build(role="admin")
            UserFactory.build(email="specific@example.com", role="editor")
        """
        defaults = {
            "username": fake.user_name()[:20],        # cap at field max length
            "email":    fake.email(),
            "role":     "viewer",
            "first_name": fake.first_name(),
            "last_name":  fake.last_name(),
        }
        return CreateUserRequest(**{**defaults, **overrides})

    @staticmethod
    def build_admin(**overrides: object) -> CreateUserRequest:
        """Build a user with admin role."""
        return UserFactory.build(role="admin", **overrides)

    @staticmethod
    def build_editor(**overrides: object) -> CreateUserRequest:
        """Build a user with editor role."""
        return UserFactory.build(role="editor", **overrides)

    @staticmethod
    def build_minimal(**overrides: object) -> CreateUserRequest:
        """
        Build a user with only required fields.
        Useful for testing API behavior with minimal payloads.
        """
        return CreateUserRequest(
            username=overrides.get("username", fake.user_name()[:20]),
            email=overrides.get("email", fake.email()),
            role=overrides.get("role", "viewer"),
        )

    @staticmethod
    def build_invalid_email(**overrides: object) -> CreateUserRequest:
        """Build a user with a deliberately invalid email for negative tests."""
        return UserFactory.build(email="not-a-valid-email", **overrides)

    @staticmethod
    def build_invalid_role(**overrides: object) -> CreateUserRequest:
        """Build a user with a deliberately invalid role for negative tests."""
        return UserFactory.build(role="superuser", **overrides)

    @staticmethod
    def build_batch(count: int, **overrides: object) -> list[CreateUserRequest]:
        """Build N users with the same overrides. Useful for list endpoint tests."""
        return [UserFactory.build(**overrides) for _ in range(count)]
```

---

## Usage in Tests

```python
# Basic usage
payload = UserFactory.build()

# Override one field
payload = UserFactory.build(role="admin")

# Override multiple fields
payload = UserFactory.build(email="test@mycompany.com", role="editor")

# Named scenario variant
payload = UserFactory.build_admin()

# Negative test data
payload = UserFactory.build_invalid_email()

# Multiple payloads
payloads = UserFactory.build_batch(count=3)

# In parametrized tests
@pytest.mark.parametrize("payload", [
    UserFactory.build(role="viewer"),
    UserFactory.build(role="editor"),
    UserFactory.build(role="admin"),
])
def test_all_roles_accepted(user_service, payload):
    user = user_service.create_user(payload)
    assert user.role == payload.role
```

---

## requirements.txt entries for Factory

```
faker>=24.0.0
```

---

## Faker Seed Strategy

```python
Faker.seed(0)   # Use for reproducible test data (same data every run)
                # Good for: debugging, stable snapshots

# Remove seed for fully random data every run:
# Good for: catching more edge cases over time, fuzzing-like behavior

# Per-test seed (advanced):
@pytest.fixture(autouse=True)
def faker_seed(request):
    """Seed Faker with the test's line number for unique-but-reproducible data."""
    Faker.seed(request.node.fspath.lineno)
```

---

## Extending to New Resources

Adding an `OrderFactory` requires zero changes to existing files:

```python
# layer_1_models/api/factories/order_factory.py
from faker import Faker
from layer_1_models.api.order_model import CreateOrderRequest

fake = Faker()


class OrderFactory:
    @staticmethod
    def build(**overrides: object) -> CreateOrderRequest:
        defaults = {
            "user_id": fake.random_int(min=1, max=10000),
            "items": [{"sku": "SKU-001", "quantity": 1}],
            "shipping_address": fake.address(),
            "payment_token": f"tok_{fake.lexify('???????????????????')}",
        }
        return CreateOrderRequest(**{**defaults, **overrides})
```
