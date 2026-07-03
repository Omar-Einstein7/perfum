# Auth API Contracts

**Date**: 2026-07-03 | **Spec**: [spec.md](../spec.md) | **Data Model**: [data-model.md](../data-model.md)

All endpoints follow the standard REST envelope: `{ "success": bool, "data": ..., "message": ... }`. Paginated responses include `meta: { total, page, pages }`.

---

## POST /auth/login

Authenticate user with email and password. Returns JWT token.

**Request**:
```json
{
  "email": "user@example.com",
  "password": "P@ssword1"
}
```

**Success (200)**:
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "expiresIn": 86400,
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

**Error (401)**:
```json
{
  "success": false,
  "data": null,
  "message": "Invalid email or password"
}
```

**Error (403 — deactivated)**:
```json
{
  "success": false,
  "data": null,
  "message": "Account disabled"
}
```

---

## POST /auth/logout

Invalidate the current JWT token (add to server-side blocklist).

**Headers**: `Authorization: Bearer <token>`

**Success (200)**:
```json
{
  "success": true,
  "data": null,
  "message": "Logged out successfully"
}
```

---

## GET /auth/me

Return the currently authenticated user's profile and permissions.

**Headers**: `Authorization: Bearer <token>`

**Success (200)**:
```json
{
  "success": true,
  "data": {
    "id": "507f1f77bcf86cd799439011",
    "email": "user@example.com",
    "role": "staff",
    "permissions": { "p_info": true, "p_res": false, "p_sell": false, "p_snadat": false, "p_user": false, "p_report": false, "p_report2": false },
    "status": "active"
  },
  "message": null
}
```

**Error (401)**:
```json
{
  "success": false,
  "data": null,
  "message": "Invalid or expired token"
}
```

---

## GET /users

List all users (superadmin only). Requires `p_user` permission.

**Headers**: `Authorization: Bearer <token>`

**Query Params**: `?page=1&limit=20&status=active`

**Success (200)**:
```json
{
  "success": true,
  "data": [
    {
      "id": "507f1f77bcf86cd799439011",
      "email": "user@example.com",
      "role": "staff",
      "permissions": { "p_info": true, "p_res": false, "p_sell": false, "p_snadat": false, "p_user": false, "p_report": false, "p_report2": false },
      "status": "active",
      "createdAt": "2026-01-15T10:30:00Z"
    }
  ],
  "meta": { "total": 15, "page": 1, "pages": 1 },
  "message": null
}
```

---

## POST /users

Create a new user (superadmin only).

**Headers**: `Authorization: Bearer <token>`

**Request**:
```json
{
  "email": "newuser@example.com",
  "password": "NewP@ss1",
  "role": "staff",
  "permissions": { "p_info": true, "p_res": false, "p_sell": false, "p_snadat": false, "p_user": false, "p_report": false, "p_report2": false }
}
```

**Success (201)**:
```json
{
  "success": true,
  "data": {
    "id": "507f1f77bcf86cd799439012",
    "email": "newuser@example.com",
    "role": "staff",
    "permissions": { "p_info": true, "p_res": false, "p_sell": false, "p_snadat": false, "p_user": false, "p_report": false, "p_report2": false },
    "status": "active",
    "createdAt": "2026-07-03T12:00:00Z"
  },
  "message": "User created successfully"
}
```

**Error (400 — validation)**:
```json
{
  "success": false,
  "data": null,
  "message": "Password must be at least 8 characters with 1 uppercase, 1 lowercase, and 1 digit"
}
```

---

## PUT /users/:id

Update user role, permissions, or status (superadmin only).

**Headers**: `Authorization: Bearer <token>`

**Request**:
```json
{
  "role": "admin",
  "permissions": { "p_info": true, "p_res": true, "p_sell": true, "p_snadat": false, "p_user": false, "p_report": false, "p_report2": false },
  "status": "active"
}
```

**Success (200)**:
```json
{
  "success": true,
  "data": {
    "id": "507f1f77bcf86cd799439011",
    "email": "user@example.com",
    "role": "admin",
    "permissions": { "p_info": true, "p_res": true, "p_sell": true, "p_snadat": false, "p_user": false, "p_report": false, "p_report2": false },
    "status": "active"
  },
  "message": "User updated successfully"
}
```

**Error (403 — last superadmin)**:
```json
{
  "success": false,
  "data": null,
  "message": "Cannot modify the last superadmin account"
}
```

---

## DELETE /users/:id

Delete a user (superadmin only, cannot self-delete).

**Headers**: `Authorization: Bearer <token>`

**Success (200)**:
```json
{
  "success": true,
  "data": null,
  "message": "User deleted successfully"
}
```

---

## Route-Permission Middleware Contract

Each backend route applies a middleware that extracts the required permission from a route-permission map and rejects with 403 if the user's JWT lacks that flag:

| Method | Route | Required Permission |
|--------|-------|-------------------|
| GET | `/auth/*` | None (public or self) |
| POST | `/auth/login` | None (public) |
| POST | `/auth/logout` | None (authenticated) |
| GET | `/auth/me` | None (authenticated) |
| GET | `/materials`, `/categories`, `/units` | `p_info` |
| GET/POST/PUT | `/materials/*`, `/categories/*`, `/units/*` | `p_info` |
| GET | `/suppliers`, `/purchase-invoices` | `p_res` |
| GET/POST/PUT | `/suppliers/*`, `/purchase-invoices/*` | `p_res` |
| GET | `/customers`, `/sales-invoices` | `p_sell` |
| GET/POST/PUT | `/customers/*`, `/sales-invoices/*` | `p_sell` |
| GET | `/vouchers/*` | `p_snadat` |
| GET/POST/PUT | `/users`, `/users/*` | `p_user` |
| GET | `/reports/*` | `p_report` or `p_report2` |

**Error (403)**:
```json
{
  "success": false,
  "data": null,
  "message": "Access denied"
}
```
