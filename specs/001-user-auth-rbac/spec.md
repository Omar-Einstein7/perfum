# Feature Specification: User Authentication & RBAC

**Feature Branch**: `001-user-auth-rbac`

**Created**: 2026-07-03

**Status**: Draft

**Input**: User description: "Auth module: user login with email/password, JWT session, role field (superadmin/admin/staff) plus 7 boolean permissions (p_info, p_res, p_sell, p_snadat, p_user, p_report, p_report2). Superadmin can create/edit/delete users and assign permissions. Logged-in user sees only routes matching their permissions."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - User Login and Session-Based Navigation (Priority: P1)

A registered staff/admin/superadmin user logs into the system using their email and password. Upon successful authentication, they receive a JWT session and are redirected to the dashboard. The navigation sidebar displays only the routes corresponding to their granted boolean permissions.

**Why this priority**: This is the entry point for all system users. Without login, no user can access any feature of the system. This story delivers the core authentication flow and permission-based UI.

**Independent Test**: Can be fully tested by attempting login with valid credentials for each role, verifying JWT issuance, and confirming the navigation shows only permitted routes.

**Acceptance Scenarios**:

1. **Given** a registered user with valid email and password, **When** they submit their credentials on the login page, **Then** the system authenticates them and returns a JWT session token
2. **Given** an authenticated user with only `p_info` = true and all other permissions = false, **When** the dashboard loads, **Then** only routes for `/materials`, `/categories`, and `/units` are visible in navigation
3. **Given** an unauthenticated user, **When** they attempt to access any protected route, **Then** they are redirected to the login page
4. **Given** an authenticated user, **When** they navigate to a route not matching their permissions, **Then** they see a 403 error page
5. **Given** a user with an expired access token but valid refresh token, **When** they make a request, **Then** the system automatically refreshes the access token and retries
6. **Given** a user with an expired refresh token, **When** they make a request, **Then** the system rejects it and redirects to login

---

### User Story 2 - Superadmin User Management (Priority: P1)

A superadmin manages all user accounts: creates new users with assigned role and permissions, edits existing user profiles, and deactivates/deletes accounts. This is the administrative interface for the entire RBAC system.

**Why this priority**: Only superadmin can create and manage users. Without this story, no new staff or admin accounts can be added to the system. This is tied with login as P1 because bootstrapping the system requires at least one superadmin to manage other users.

**Independent Test**: Can be fully tested by logging in as superadmin, creating a new user with specific role and permissions, then logging in as that user to verify the permissions take effect.

**Acceptance Scenarios**:

1. **Given** a superadmin, **When** they create a new user with role "staff" and permissions `{p_info: true}`, **Then** the user is saved and immediately available for login
2. **Given** a superadmin, **When** they modify a user's permissions from `{p_res: true}` to `{p_sell: true}`, **Then** the user's next request reflects the updated permissions
3. **Given** a superadmin, **When** they set a user account to Inactive, **Then** that user cannot log in but their data is preserved
4. **Given** a superadmin, **When** they reset a user's password to a temporary value, **Then** the user can log in with the new temporary password
5. **Given** a superadmin, **When** they delete a user account, **Then** the user is permanently removed

---

### User Story 3 - Admin/Staff Profile View (Priority: P3)

An admin or staff user views their own profile information including their role and assigned permissions. They cannot modify their own role or permissions.

**Why this priority**: This is read-only self-service that reduces support requests but is not critical for system operation.

**Independent Test**: Can be tested by any non-superadmin user navigating to their profile page and verifying they see their role/permissions but no edit controls for those fields.

**Acceptance Scenarios**:

1. **Given** an admin user, **When** they view their profile, **Then** they see their email, role ("admin"), and list of granted permissions
2. **Given** a staff user, **When** they attempt to edit or escalate their own role, **Then** the system rejects the change

---

### Edge Cases

- What happens when the last superadmin tries to demote themselves or remove their own superadmin role? The system should prevent removing the last superadmin.
- How does the system handle concurrent login attempts? Standard rate-limiting after 5 failed attempts within a window.
- What happens when a user's session is revoked by a superadmin while they are actively using the system? The next API request should reject the token and log them out.
- How does the system handle duplicate email registration? Email uniqueness must be enforced at account creation.
- What happens when an Inactive user attempts to log in? The system rejects the login with a clear message that the account is inactive.
- Can a superadmin reactivate an Inactive account? Yes, superadmin can move an account from Inactive back to Active.
- What happens to an Inactive user's active sessions? All existing sessions for the user should be invalidated immediately upon deactivation.

## Clarifications

### Session 2026-07-03

- Q: What account lifecycle states should a user support? → A: Three states — Active, Inactive (cannot login, temporary), Deleted (permanently removed)
- Q: What behavioral difference exists between admin and staff roles? → A: None — role is purely informational/display. All access decisions rely solely on the 7 boolean permission flags.
- Q: What JWT session mechanism should be used? → A: Refresh token — short-lived access token (15min) + long-lived refresh token (7 days), refresh token rotates on use.
- Q: How are forgotten passwords handled? → A: Superadmin-only reset — superadmin sets a temporary password from user management screen. No self-service forgot-password flow.
- Q: What is explicitly out of scope for this feature? → A: Social login, self-registration, 2FA, API tokens, LDAP/SSO — scope is email/password auth + superadmin-managed accounts only.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST authenticate users using email and password credentials
- **FR-002**: System MUST issue a short-lived access token (15 minutes) AND a long-lived refresh token (7 days) upon successful authentication. The access token MUST include the user's `role` and all 7 boolean permission flags (`p_info`, `p_res`, `p_sell`, `p_snadat`, `p_user`, `p_report`, `p_report2`)
- **FR-003**: System MUST validate the access token on every authenticated request and reject invalid or expired tokens
- **FR-003b**: System MUST accept a valid refresh token in exchange for a new access token + rotated refresh token, and MUST reject reused refresh tokens (rotation with reuse detection)
- **FR-004**: System MUST redirect unauthenticated users to the login page for any protected route
- **FR-005**: Only users with `role: superadmin` MAY create new user accounts
- **FR-006**: Only users with `role: superadmin` MAY edit user role, permissions, or account status
- **FR-007**: Only users with `role: superadmin` MAY change a user's account status (Active, Inactive, Deleted)
- **FR-008**: System MUST enforce that at least one superadmin account always exists (prevent removal of the last superadmin)
- **FR-009**: Navigation UI MUST display only routes corresponding to the user's granted boolean permissions
- **FR-010**: Accessing a route without the corresponding permission MUST display a 403 error page (not silently hide or redirect)
- **FR-011**: User account creation MUST require: email (unique), password, role selection, and permission toggles for each boolean flag
- **FR-012**: System MUST enforce email uniqueness across all user accounts
- **FR-013**: System MUST log all authentication events (login success, login failure, token expiry) for audit purposes
- **FR-014**: System MUST rate-limit login attempts to 5 failed attempts within a 15-minute window per account
- **FR-015**: Only users with `role: superadmin` MAY reset passwords for other users by setting a temporary password from the user management interface

### Key Entities *(include if feature involves data)*

- **User**: A system user account with email, password hash, role (superadmin/admin/staff — superadmin governs user management; admin/staff are informational labels with no behavioral difference), account status (active/inactive/deleted), and an embedded permissions object containing 7 boolean flags. A user is associated with audit events for authentication and account management actions.
- **Session**: A pair of JWT tokens issued upon login: a short-lived access token (15 minutes) containing the user's identity, role, and permissions, plus a long-lived refresh token (7 days) used to obtain new access tokens. The refresh token rotates on each use with reuse detection to prevent token theft.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete the login flow (enter credentials → receive JWT → see dashboard) in under 5 seconds on a standard internet connection
- **SC-002**: A superadmin can create a new user account in under 2 minutes from the user management interface
- **SC-003**: Navigation sidebar correctly displays only permitted routes for every combination of the 7 permission flags
- **SC-004**: Unauthenticated access to any protected route results in a redirect to login within 1 second
- **SC-005**: 100% of unauthorized route access attempts result in a 403 error page (no accidental data exposure)
- **SC-006**: The system prevents the last superadmin from being demoted or deleted, enforced at both UI and API level

## Out of Scope

The following are explicitly excluded from this feature:

- Social login / OAuth providers (Google, Facebook, etc.)
- User self-registration (all accounts created by superadmin)
- Two-factor authentication (2FA)
- API tokens for machine-to-machine access
- LDAP / SSO directory integration
- Self-service password reset / forgot-password email flow

## Assumptions

- The backend API (Node.js + Express + MongoDB) already supports JWT issuance and validation as defined in the system architecture
- The route-to-permission mapping defined in the constitution is already established:
  - `/materials`, `/categories`, `/units` → `p_info`
  - `/suppliers`, `/purchase-invoices` → `p_res`
  - `/customers`, `/sales-invoices` → `p_sell`
  - `/vouchers/*` → `p_snadat`
  - `/users` → `p_user`
  - `/reports/*` → `p_report`, `p_report2`
- At least one superadmin account will be seeded during initial deployment or setup
- The existing `go_router` configuration supports route guards that can read auth state and permissions from an injected auth cubit
- Password complexity follows standard practices (minimum 8 characters, mixed case/digits)
- Access token expires in 15 minutes; refresh token expires in 7 days. Refresh token rotates on each use with reuse detection.
- User accounts follow a three-state lifecycle: Active (can login), Inactive (cannot login, data preserved, reactivatable), Deleted (permanently removed). Inactive is preferred over hard deletion for audit trail purposes.
