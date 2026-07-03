# Quickstart: User Authentication & RBAC

**Date**: 2026-07-03 | **Phase**: 1 — Design & Contracts

## Prerequisites

- Node.js 18+ with npm
- MongoDB instance (local or remote)
- Flutter SDK 3.x with Chrome browser
- Project already initialized with Flutter Web + Node/Express backend

## Backend Setup

```bash
# Navigate to server directory
cd server

# Install dependencies
npm install express mongoose bcryptjs jsonwebtoken express-rate-limit cors dotenv

# Create .env file
echo "PORT=3000
MONGODB_URI=mongodb://localhost:27017/perfum_ahmed_gaper
JWT_ACCESS_SECRET=your-access-secret-key
JWT_REFRESH_SECRET=your-refresh-secret-key
ACCESS_TOKEN_EXPIRY=15m
REFRESH_TOKEN_EXPIRY=7d" > .env

# Seed a superadmin user (run once)
npm run seed:superadmin

# Start server
npm run dev
```

## Frontend Setup

```bash
# From project root
# Add dependencies
flutter pub add flutter_bloc get_it dio go_router equatable freezed json_serializable
flutter pub add dev:bloc_test dev:mocktail dev:build_runner

# Run code generation (freezed)
flutter pub run build_runner build --delete-conflicting-outputs

# Start Flutter Web
flutter run -d chrome
```

## Validation Scenarios

### Scenario 1: Superadmin Seeding & Login

```bash
# Verify seed script creates initial superadmin
# Expected: console output "Superadmin seeded: admin@example.com / Admin@123"

# Open browser at http://localhost:3000 (or Flutter dev server)
# Login with: admin@example.com / Admin@123
# Expected: Redirected to dashboard, full navigation visible (all permissions)
```

### Scenario 2: Permission-Based Navigation

```bash
# As superadmin, create a staff user with only p_info = true
# Log out, log in as new staff user
# Expected: Only /materials, /categories, /units routes visible in sidebar
# Navigating to /users or /reports shows 403 page
```

### Scenario 3: Token Refresh Flow

```bash
# After login, inspect network tab
# Wait 15 minutes or clear access token from memory
# Make any API request
# Expected: Single silent 401 → auto-refresh (POST /api/auth/refresh) → retry original request
# No user-visible interruption
```

### Scenario 4: Inactive User

```bash
# As superadmin, set a user to Inactive status
# Attempt to log in as that user
# Expected: Error message "Account is inactive. Contact your superadmin."
```

### Scenario 5: Rate Limiting

```bash
# Attempt login with wrong password 6 times
# Expected: 6th attempt returns 429 "Too many login attempts. Try again in 15 minutes."
```

## Verification Checklist

- [ ] Login succeeds with valid credentials, returns access + refresh tokens
- [ ] Login fails with clear error for: wrong password, nonexistent email, inactive account
- [ ] Rate limiting activates after 5 failed attempts
- [ ] Auto token refresh succeeds on 401 (no user interruption)
- [ ] Token reuse detection invalidates both old and new tokens
- [ ] Superadmin can create, edit, deactivate, delete users
- [ ] Non-superadmin cannot access any user management feature
- [ ] Navigation sidebar shows only permitted routes per user's permissions
- [ ] 403 page shown for unauthorized route access
- [ ] Last superadmin cannot be demoted or deleted
- [ ] Logout invalidates refresh token
- [ ] Profile page shows own role and permissions (read-only for non-superadmins)

## API Contract Reference

See [contracts/auth-api.md](contracts/auth-api.md) for full endpoint documentation.

## Data Model Reference

See [data-model.md](data-model.md) for schema details.
