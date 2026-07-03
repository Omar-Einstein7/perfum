# Data Model: User Authentication & RBAC

**Date**: 2026-07-03 | **Phase**: 1 — Design & Contracts

## Entities

### User

Core user account entity. Stored in MongoDB `users` collection.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `_id` | ObjectId (hex string) | Auto-generated, immutable | Unique identifier |
| `email` | String | Required, unique, lowercase, trimmed, valid email format | Login credential identifier |
| `passwordHash` | String | Required, bcrypt hash (10 rounds) | Never exposed in API responses |
| `role` | Enum: `superadmin` / `admin` / `staff` | Required | Informational label; superadmin governs user management, admin/staff have no behavioral difference |
| `status` | Enum: `active` / `inactive` / `deleted` | Required, default: `active` | Account lifecycle state |
| `permissions` | Object | Required, all 7 fields boolean, default all `false` | Granular access control flags |
| `createdAt` | Date | Auto-set on creation | Timestamp |
| `updatedAt` | Date | Auto-updated | Timestamp |
| `lastLoginAt` | Date | Nullable | Last successful login timestamp |

#### Permissions Object Structure

```json
{
  "p_info": false,
  "p_res": false,
  "p_sell": false,
  "p_snadat": false,
  "p_user": false,
  "p_report": false,
  "p_report2": false
}
```

#### State Transitions

```
active ──┬──→ inactive  (superadmin deactivates)
          └──→ deleted   (superadmin deletes permanently)
inactive ─┬──→ active    (superadmin reactivates)
           └──→ deleted  (superadmin deletes permanently)
deleted → [terminal state, cannot transition out]
```

### Session (Logical Entity — No DB Collection)

A logical pairing of two JWT tokens. No persistence in MongoDB; state tracked via token issuance and refresh rotation.

| Component | TTL | Stored In | Contains |
|-----------|-----|-----------|----------|
| Access token | 15 minutes | AuthBloc state (in-memory) | `userId`, `email`, `role`, `permissions`, `iat`, `exp` |
| Refresh token | 7 days | Client localStorage | `userId`, `tokenVersion` (for rotation + reuse detection), `iat`, `exp` |

#### Token Rotation Rules

1. Login: issue access token + refresh token (v1)
2. Refresh: validate refresh token → issue new access token + new refresh token (v2) → invalidate v1
3. Reuse detection: if v1 is used after v2 was issued → invalidate both v1 and v2 (theft detected → force re-login)

## MongoDB Schema (Mongoose)

```javascript
const userSchema = new Schema({
  email:       { type: String, required: true, unique: true, lowercase: true, trim: true },
  passwordHash:{ type: String, required: true, select: false },
  role:        { type: String, enum: ['superadmin', 'admin', 'staff'], required: true },
  status:      { type: String, enum: ['active', 'inactive', 'deleted'], default: 'active' },
  permissions: {
    p_info:    { type: Boolean, default: false },
    p_res:     { type: Boolean, default: false },
    p_sell:    { type: Boolean, default: false },
    p_snadat:  { type: Boolean, default: false },
    p_user:    { type: Boolean, default: false },
    p_report:  { type: Boolean, default: false },
    p_report2: { type: Boolean, default: false }
  },
  lastLoginAt: { type: Date, default: null }
}, { timestamps: true });

// Indexes
userSchema.index({ email: 1 }, { unique: true });
```

## Validation Rules

| Field | Rule | Error |
|-------|------|-------|
| `email` | Must match email regex | `Invalid email format` |
| `email` | Must be unique on create/update | `Email already registered` |
| `password` (input) | Min 8 chars, at least 1 letter + 1 digit | `Password must be at least 8 characters with 1 letter and 1 digit` |
| `role` | Must be one of `superadmin`, `admin`, `staff` | `Invalid role` |
| `status` | Cannot change `deleted` → anything | `Cannot modify a deleted account` |
| `permissions` | Each field must be boolean | `Permission value must be true or false` |
| Superadmin guard | Cannot delete/demote the last `superadmin` | `Cannot remove the last superadmin account` |
