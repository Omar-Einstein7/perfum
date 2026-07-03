# Data Model: Auth & Permission Module

**Date**: 2026-07-03 | **Spec**: [spec.md](./spec.md)

---

## Entities

### User

| Field | Type | Required | Unique | Notes |
|-------|------|----------|--------|-------|
| id | String | ✓ | ✓ | MongoDB ObjectId hex (24-char) |
| email | String | ✓ | ✓ | Login identifier |
| password | String | ✓ | | bcrypt hash, never returned in API responses |
| role | Enum: `superadmin` / `admin` / `staff` | ✓ | | Role label (no inherent permissions beyond flag-based gates) |
| permissions | Object | ✓ | | Embedded object with 7 boolean flags (see below) |
| status | Enum: `active` / `deactivated` | ✓ | | Deactivated users cannot log in |
| createdAt | DateTime (ISO-8601) | ✓ | | Set on creation |
| updatedAt | DateTime (ISO-8601) | ✓ | | Updated on any field change |

**Permissions Object**:

```json
{
  "p_info":    false,
  "p_res":     false,
  "p_sell":    false,
  "p_snadat":  false,
  "p_user":    false,
  "p_report":  false,
  "p_report2": false
}
```

**Validation Rules**:
- `email`: Valid email format, max 255 chars
- `password`: Min 8 chars, at least 1 uppercase, 1 lowercase, 1 digit (FR-015)
- `role`: Must be one of `superadmin`, `admin`, `staff`
- `status`: Must be `active` or `deactivated`
- At least one superadmin must always exist (FR-009 — prevent deletion/downgrade of last superadmin)

**State Transitions**:
- `active` ↔ `deactivated` (superadmin toggles)
- `active` → (deleted) (superadmin deletes, permanent)
- Password changes preserve status

---

### Session (JWT)

| Claim | Type | Source | Notes |
|-------|------|--------|-------|
| sub | String | User.id | Subject = user ID |
| email | String | User.email | For quick reference without DB lookup |
| role | String | User.role | For role-based checks |
| permissions | Object | User.permissions | 7 boolean flags for route gating |
| iat | Number (epoch) | System | Issued at |
| exp | Number (epoch) | System | Expiration (default 24h, configurable) |

**Not included in JWT**: password hash, internal metadata.

---

### Audit Log Entry (new entity from Q1 clarification)

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | String | ✓ | MongoDB ObjectId hex |
| actorId | String | ✓ | User.id of the acting superadmin |
| action | Enum | ✓ | `user_created` / `permission_changed` / `role_changed` / `user_deactivated` / `user_reactivated` / `user_deleted` |
| targetUserId | String | ✓ | User.id of the affected user |
| before | Object | | Snapshot of changed fields before modification |
| after | Object | | Snapshot of changed fields after modification |
| timestamp | DateTime (ISO-8601) | ✓ | When the action occurred |

---

## Route-Permission Mapping

| Route(s) | Required Permission | Notes |
|----------|-------------------|-------|
| `/materials`, `/categories`, `/units` | `p_info` | Info/read access |
| `/suppliers`, `/purchase-invoices` | `p_res` | Resources/supply |
| `/customers`, `/sales-invoices` | `p_sell` | Sales |
| `/vouchers/*` | `p_snadat` | Financial vouchers |
| `/users` | `p_user` | User management (superadmin only by convention) |
| `/reports/*` | `p_report` or `p_report2` | Reports |

---

## Relationships

- **User** references no other entity directly. Users are referenced as `actorId` in audit logs and as `createdBy`/`updatedBy` in business documents (invoices, vouchers).
- **AuditLog** has a `ref` to `User.id` (actorId, targetUserId) — no cascade delete; logs are immutable.
