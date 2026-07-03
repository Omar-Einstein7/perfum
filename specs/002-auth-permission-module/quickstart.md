# Quickstart: Auth & Permission Module Validation Guide

**Date**: 2026-07-03 | **Spec**: [spec.md](./spec.md) | **Data Model**: [data-model.md](./data-model.md) | **Contracts**: [contracts/auth-api.md](./contracts/auth-api.md)

---

## Prerequisites

| Component | Requirement |
|-----------|-------------|
| Flutter | 3.x, Chrome browser |
| Node.js | 18+ |
| MongoDB | 6+ running locally or remotely |
| Dart | 3.x |

---

## Setup

### 1. Backend

```bash
cd server
npm install
# Ensure MongoDB is running
cp .env.example .env    # Configure MONGO_URI, JWT_SECRET, JWT_EXPIRY
npm run dev             # Starts on http://localhost:3000
```

Seed a superadmin user:
```bash
npm run seed:admin      # Creates default superadmin: admin@example.com / Admin123!
```

### 2. Frontend

```bash
cd perfum_ahmed_gaper
flutter pub get
# Configure .env with API base URL
echo "API_BASE_URL=http://localhost:3000" > .env
flutter run -d chrome   # Starts on http://localhost:5000
```

---

## Validation Scenarios

### Scenario 1: Login Flow

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to `http://localhost:5000/login` | Login page renders with email and password fields |
| 2 | Enter `admin@example.com` / `Admin123!` and submit | JWT stored in secure storage; redirected to dashboard |
| 3 | Refresh the page | Auto-authenticated (no login prompt) |

### Scenario 2: Permission-Based Route Filtering

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Log in as a user with only `p_info: true` | Only Materials, Categories, Units visible in nav |
| 2 | Navigate to `/users` directly | Redirected to `/403` with "Access denied" |
| 3 | Navigate to `/materials` | Page loads normally |

### Scenario 3: Superadmin User Management

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Log in as superadmin | Users link visible in nav |
| 2 | Navigate to `/users` | List of all users with roles and permissions shown |
| 3 | Click "Create User", fill email/password/role/permissions | User created; appears in list |
| 4 | Click "Edit" on a user, change role to `admin`, grant `p_sell` | Changes saved; user updated in list |
| 5 | Log in as the created user | Only permitted routes visible |
| 6 | Return to superadmin, click "Deactivate" on the user | User status shows "deactivated" |
| 7 | Log in as the deactivated user | "Account disabled" error; no session issued |
| 8 | Reactivate the user | User can log in again with original permissions |

### Scenario 4: Logout

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | While logged in, click "Logout" | JWT invalidated server-side; redirected to login |
| 2 | Try to access a protected route via URL | Redirected to login |
| 3 | Log in again | Works normally (new session) |

### Scenario 5: Password Validation

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Create a user with password `short` | Rejected: password too short |
| 2 | Create a user with password `nouppercase1` | Rejected: missing uppercase |
| 3 | Create a user with password `ValidP@ss1` | Accepted: meets all requirements |

---

## Running Tests

### Backend

```bash
cd server
npm test                    # Jest + supertest
npm run test:coverage       # With coverage report
```

**Key test files**:
- `server/tests/auth.test.js` — login, logout, token validation
- `server/tests/permissions.test.js` — per-route middleware checks
- `server/tests/users.test.js` — CRUD, last-superadmin guard

### Frontend

```bash
cd perfum_ahmed_gaper
flutter test                        # All tests
flutter test test/features/auth/    # Auth module tests only
```

**Key test files**:
- `test/features/auth/domain/usecases/login_usecase_test.dart`
- `test/features/auth/data/datasources/auth_remote_data_source_test.dart`
- `test/features/auth/presentation/bloc/auth_bloc_test.dart`
- `test/features/auth/presentation/bloc/user_management_bloc_test.dart`

---

## Validation Commands (API Health Check)

```bash
# Login
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"Admin123!"}'

# Use the returned token for subsequent requests
TOKEN="eyJhbGciOiJIUzI1NiIs..."

# Get current user
curl http://localhost:3000/auth/me -H "Authorization: Bearer $TOKEN"

# List users
curl http://localhost:3000/users -H "Authorization: Bearer $TOKEN"

# Create user
curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"email":"staff@example.com","password":"Staff123!","role":"staff","permissions":{"p_info":true,"p_res":false,"p_sell":false,"p_snadat":false,"p_user":false,"p_report":false,"p_report2":false}}'

# Logout
curl -X POST http://localhost:3000/auth/logout -H "Authorization: Bearer $TOKEN"
```
