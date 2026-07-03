# Auth API Contracts

**Base URL**: `/api/auth`

**Authentication**: Public endpoints require no auth. Protected endpoints require `Authorization: Bearer <access_token>` header.

**Response Envelope** (all endpoints):
```json
{
  "success": true|false,
  "data": { ... } | null,
  "message": "string"
}
```

**Error Codes**:
| HTTP Status | Meaning |
|-------------|---------|
| 200 | Success |
| 400 | Validation error (invalid input) |
| 401 | Unauthenticated (missing/expired token) |
| 403 | Forbidden (valid token but insufficient permissions) |
| 429 | Rate limited (too many requests) |
| 500 | Server error |

---

## POST /api/auth/login

Authenticate user with email and password. Returns access + refresh tokens.

**Rate-limited**: 5 attempts per 15 minutes per account + per IP.

**Request**:
```json
{
  "email": "user@example.com",
  "password": "P@ssw0rd123"
}
```

**Success Response** (200):
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "expiresIn": 900,
    "user": {
      "id": "507f1f77bcf86cd799439011",
      "email": "user@example.com",
      "role": "staff",
      "permissions": { "p_info": true, "p_res": false, "p_sell": false, "p_snadat": false, "p_user": false, "p_report": false, "p_report2": false },
      "status": "active"
    }
  },
  "message": "Login successful"
}
```

**Error Responses**:
- 400: `{ "success": false, "data": null, "message": "Email and password are required" }`
- 401: `{ "success": false, "data": null, "message": "Invalid email or password" }`
- 403: `{ "success": false, "data": null, "message": "Account is inactive. Contact your superadmin." }`
- 429: `{ "success": false, "data": null, "message": "Too many login attempts. Try again in 15 minutes." }`

---

## POST /api/auth/refresh

Exchange a valid refresh token for a new access token + rotated refresh token.

**Not rate-limited** (uses token validation instead).

**Request**:
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Success Response** (200):
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "expiresIn": 900
  },
  "message": "Token refreshed"
}
```

**Error Responses**:
- 401: `{ "success": false, "data": null, "message": "Invalid refresh token" }`
- 401 (reuse detected): `{ "success": false, "data": null, "message": "Token reuse detected. Session invalidated. Please log in again." }`
- 401: `{ "success": false, "data": null, "message": "Refresh token expired. Please log in again." }`

---

## POST /api/auth/logout

Invalidate the current refresh token.

**Request**:
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Success Response** (200):
```json
{
  "success": true,
  "data": null,
  "message": "Logged out successfully"
}
```

---

## GET /api/auth/me

Get the currently authenticated user's profile. Requires valid access token.

**Headers**: `Authorization: Bearer <access_token>`

**Success Response** (200):
```json
{
  "success": true,
  "data": {
    "id": "507f1f77bcf86cd799439011",
    "email": "user@example.com",
    "role": "staff",
    "permissions": { "p_info": true, "p_res": false, "p_sell": false, "p_snadat": false, "p_user": false, "p_report": false, "p_report2": false },
    "status": "active",
    "createdAt": "2026-01-15T10:30:00.000Z",
    "lastLoginAt": "2026-07-03T08:00:00.000Z"
  },
  "message": "User profile retrieved"
}
```

---

## POST /api/auth/users (Superadmin only)

Create a new user account.

**Headers**: `Authorization: Bearer <access_token>`

**Request**:
```json
{
  "email": "newstaff@example.com",
  "password": "TempP@ss123",
  "role": "staff",
  "permissions": {
    "p_info": true,
    "p_res": false,
    "p_sell": false,
    "p_snadat": false,
    "p_user": false,
    "p_report": false,
    "p_report2": false
  }
}
```

**Success Response** (201):
```json
{
  "success": true,
  "data": {
    "id": "507f1f77bcf86cd799439012",
    "email": "newstaff@example.com",
    "role": "staff",
    "permissions": { "p_info": true, "p_res": false, "p_sell": false, "p_snadat": false, "p_user": false, "p_report": false, "p_report2": false },
    "status": "active"
  },
  "message": "User created successfully"
}
```

---

## PUT /api/auth/users/:id (Superadmin only)

Update user role, status, permissions, or reset password.

**Headers**: `Authorization: Bearer <access_token>`

**Request** (partial update — only send changed fields):
```json
{
  "role": "admin",
  "permissions": { "p_user": true },
  "status": "inactive",
  "password": "NewTempP@ss456"
}
```

**Success Response** (200):
```json
{
  "success": true,
  "data": {
    "id": "507f1f77bcf86cd799439011",
    "email": "user@example.com",
    "role": "admin",
    "permissions": { "p_info": true, "p_res": false, "p_sell": false, "p_snadat": false, "p_user": true, "p_report": false, "p_report2": false },
    "status": "inactive"
  },
  "message": "User updated successfully"
}
```

**Error Responses**:
- 400: `{ "success": false, "data": null, "message": "Cannot modify a deleted account" }`
- 400: `{ "success": false, "data": null, "message": "Cannot remove the last superadmin account" }`

---

## GET /api/auth/users (Superadmin only)

List all users with pagination.

**Query params**: `?page=1&limit=20`

**Success Response** (200):
```json
{
  "success": true,
  "data": [
    { "id": "...", "email": "...", "role": "staff", "permissions": {...}, "status": "active", "createdAt": "..." }
  ],
  "meta": { "total": 15, "page": 1, "pages": 1 },
  "message": "Users retrieved"
}
```

---

## DELETE /api/auth/users/:id (Superadmin only)

Permanently delete a user account. Cannot delete the last superadmin.

**Headers**: `Authorization: Bearer <access_token>`

**Success Response** (200):
```json
{
  "success": true,
  "data": null,
  "message": "User deleted successfully"
}
```

---

## Access Token Payload (JWT Claims)

```json
{
  "sub": "507f1f77bcf86cd799439011",
  "email": "user@example.com",
  "role": "staff",
  "permissions": { "p_info": true, "p_res": false, "p_sell": false, "p_snadat": false, "p_user": false, "p_report": false, "p_report2": false },
  "iat": 1688313600,
  "exp": 1688314500
}
```

## Refresh Token Payload (JWT Claims)

```json
{
  "sub": "507f1f77bcf86cd799439011",
  "tokenVersion": 3,
  "iat": 1688313600,
  "exp": 1688918400
}
```

## Permission Middleware Route Mapping

| HTTP Method | Route | Required Permission | Notes |
|-------------|-------|---------------------|-------|
| Any | `/api/materials/*` | `p_info` | |
| Any | `/api/categories/*` | `p_info` | |
| Any | `/api/units/*` | `p_info` | |
| Any | `/api/suppliers/*` | `p_res` | |
| Any | `/api/purchase-invoices/*` | `p_res` | |
| Any | `/api/customers/*` | `p_sell` | |
| Any | `/api/sales-invoices/*` | `p_sell` | |
| Any | `/api/vouchers/*` | `p_snadat` | |
| Any | `/api/users/*` | `p_user` | Except superadmin self-management |
| Any | `/api/reports/*` | `p_report` or `p_report2` | Either flag grants access |
| Any | `/api/auth/*` | None (public or self-service) | Login/refresh/logout are public; user mgmt routes gated by `p_user` |
