# Feature Specification: Auth & Permission Module

**Feature Branch**: `002-auth-permission-module`

**Created**: 2026-07-03

**Status**: Draft

**Input**: User description: "Auth module: user login with email/password, JWT session, role field (superadmin/admin/staff) plus 7 boolean permissions (p_info, p_res, p_sell, p_snadat, p_user, p_report, p_report2). Superadmin can create/edit/delete users and assign permissions. Logged-in user sees only routes matching their permissions."

## Clarifications

### Session 2026-07-03

- Q: Should user creation, permission changes, role changes, and deactivation/deletion events be logged with the acting superadmin's identity and a timestamp? → A: Yes — log all user management actions (create, edit permissions, deactivate, delete) with actor, timestamp, and before/after values.
- Q: Should users be able to explicitly log out, and should that invalidate the JWT? → A: Yes — logout button that invalidates the JWT server-side (adds token to a server-side blocklist until natural expiry).
- Q: What minimum password complexity should be enforced? → A: Minimum 8 characters, at least 1 uppercase, 1 lowercase, 1 digit.
- Q: Can a superadmin reactivate a previously deactivated user? → A: Yes — reactivation restores the user's original permissions and allows login.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - User Login with Email & Password (Priority: P1)

A user navigates to the login page, enters their email and password, and upon successful authentication receives a JWT session token. They are then redirected to a personalized dashboard that displays only the routes and actions their account is permitted to access.

**Why this priority**: Login is the foundational gate — no other feature works without authentication. Every user-facing flow depends on this step.

**Independent Test**: Can be fully tested by visiting the login page, submitting valid credentials, and confirming the user is redirected to an authorized landing page with a valid session token.

**Acceptance Scenarios**:

1. **Given** a registered user exists with email `user@example.com` and a valid password, **When** they submit those credentials on the login page, **Then** they receive a JWT session token and are redirected to the dashboard showing only routes matching their permissions.
2. **Given** a user submits an unregistered email, **When** they click the login button, **Then** they see a clear error message ("Invalid email or password") and are not issued a session token.
3. **Given** a user submits a correct email but wrong password, **When** they click the login button, **Then** they see the same generic error message with no indication of which field was incorrect (preventing user enumeration).
4. **Given** a user has an active JWT session and revisits the app, **When** the token is still valid, **Then** they are automatically authenticated and skip the login page.

---

### User Story 2 - Superadmin User Management (Priority: P1)

A superadmin navigates to the user management section, views all registered users, creates new users with specific roles and permission flags, edits existing user permissions, and deactivates or deletes users as needed.

**Why this priority**: Without user management, only hard-coded accounts exist. The permission system has no value unless a superadmin can assign granular access to staff and admins.

**Independent Test**: Can be fully tested by logging in as a superadmin, creating a new user with a specific role and permission set, then logging in as that new user to verify they see only the permitted routes.

**Acceptance Scenarios**:

1. **Given** a superadmin is logged in, **When** they navigate to the users section, **Then** they see a list of all registered users with their roles and permission flags.
2. **Given** a superadmin creates a new user with email, password, role (staff), and specific permissions (e.g., `p_info: true`, all others `false`), **When** the form is submitted, **Then** the new user is saved and can immediately log in with the provided credentials.
3. **Given** a superadmin edits an existing user's permissions (e.g., grants `p_sell` to a staff user), **When** the changes are saved, **Then** the affected user sees the new route (sales invoices) on their next page load or after re-login.
4. **Given** a superadmin deactivates a user, **When** that user attempts to log in, **Then** they are rejected with an "Account disabled" message and cannot obtain a session token.
5. **Given** a superadmin attempts to delete their own account, **When** they try to save the deletion, **Then** the system prevents self-deletion with an appropriate message.

---

### User Story 3 - Role-Based Route Access Control (Priority: P2)

A logged-in staff user with limited permissions navigates the application. They see only the menu items and routes that their permission flags allow. Attempting to access a restricted route directly (e.g., by URL) redirects them to an unauthorized page.

**Why this priority**: Route filtering is the core user-facing value of the permission system — it ensures users work only within their authorized scope.

**Independent Test**: Can be tested by creating a user with a single permission (e.g., `p_info`) and verifying that only the info-related routes (materials, categories, units) are accessible while all others return a 403 redirect.

**Acceptance Scenarios**:

1. **Given** a logged-in user with only `p_info: true`, **When** they view the navigation menu, **Then** only materials, categories, and units links are visible.
2. **Given** a logged-in user with only `p_info: true`, **When** they manually type a URL for `/users` (requires `p_user`), **Then** they are redirected to `/403` with an "Access denied" message.
3. **Given** a superadmin has all permissions, **When** they view the navigation menu, **Then** all route links are visible and accessible.

---

### Edge Cases

- What happens when a user's JWT token expires mid-session while filling a form? The system should redirect them to the login page without losing critical state (if feasible) or show a "Session expired, please log in again" message.
- What happens when a superadmin revokes all permissions from a user who is currently logged in? The user's next navigation action should trigger a permission re-check and redirect to `/403` if the requested route is no longer permitted.
- How does the system handle concurrent login from the same user on multiple devices? Both sessions remain valid unless the superadmin deactivates the account.
- What happens when the last superadmin's role is changed to admin? The system should prevent downgrading the last superadmin account.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST authenticate users via email and password and issue a JWT session token upon successful login.
- **FR-002**: System MUST validate credentials securely — failed login attempts MUST return a generic "Invalid email or password" message without distinguishing which field is incorrect.
- **FR-003**: System MUST define three roles: `superadmin`, `admin`, and `staff`, each with the ability to carry any combination of the seven boolean permission flags.
- **FR-004**: System MUST support seven independent boolean permission flags: `p_info`, `p_res`, `p_sell`, `p_snadat`, `p_user`, `p_report`, `p_report2`.
- **FR-005**: System MUST allow superadmin users to view a list of all registered users with their roles and current permissions.
- **FR-006**: System MUST allow superadmin users to create new users with email, password, role, and individual permission flags.
- **FR-007**: System MUST allow superadmin users to edit existing user profiles including role and permission flags.
- **FR-008**: System MUST allow superadmin users to deactivate, reactivate, or delete users (excluding self-deletion). Reactivation restores the user's original permissions and allows them to log in again.
- **FR-009**: System MUST prevent deletion or role-downgrade of the last remaining superadmin account.
- **FR-010**: System MUST log all user management actions (create, edit permissions, change role, deactivate, delete) with the acting superadmin's identity, a timestamp, and before/after values for changed fields.
- **FR-011**: System MUST filter navigation menus and route access based on the logged-in user's assigned permission flags.
- **FR-012**: System MUST redirect unauthorized route access to a dedicated `/403` error page with an "Access denied" message.
- **FR-013**: System MUST validate the JWT token on every authenticated request and reject expired or invalid tokens.
- **FR-014**: System MUST prevent deactivated users from obtaining a new JWT session token.
- **FR-015**: System MUST enforce a minimum password complexity of at least 8 characters, with at least 1 uppercase letter, 1 lowercase letter, and 1 digit.
- **FR-016**: System MUST hash passwords using a strong, industry-standard algorithm (e.g., bcrypt) before storing them.
- **FR-017**: System MUST provide a logout function that invalidates the current JWT token server-side and terminates the session.

### Key Entities *(include if feature involves data)*

- **User**: Represents a person who can log into the system. Key attributes: email (unique identifier for login), password (hashed), role (superadmin/admin/staff), status (active/deactivated), and seven boolean permission flags (p_info, p_res, p_sell, p_snadat, p_user, p_report, p_report2). A user belongs to no other entity but is referenced by invoices, vouchers, and other audit-trail records as the actor.
- **JWT Session**: A temporary authentication token issued upon successful login. Contains the user's identity, role, and permission flags. Has a configurable expiration time, can be explicitly invalidated on logout, and is validated on every request.
- **Route-Permission Map**: A logical mapping between application routes and the permission flags required to access them. Defines which permission is needed for each route group (e.g., `/materials` requires `p_info`; `/users` requires `p_user`; `/reports/*` requires `p_report` or `p_report2`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete login from credential entry to dashboard load in under 3 seconds on a standard broadband connection.
- **SC-002**: A superadmin can create a new user with specific role and permissions, and that user can immediately log in — total workflow under 2 minutes for an experienced user.
- **SC-003**: Users see only the navigation items matching their assigned permissions with zero false positives (no hidden routes accidentally visible) and zero false negatives (no permitted routes hidden).
- **SC-004**: Unauthorized route access consistently redirects to a `/403` page in under 1 second for all restricted routes.
- **SC-005**: A superadmin can locate, edit, and save permission changes for any existing user in under 30 seconds after navigation to the users section.
- **SC-006**: Expired or invalid JWT tokens are rejected on the first subsequent request; users are never served data from an invalid session.

## Assumptions

- Password reset / forgot-password flow is out of scope for this module and will be handled separately if needed.
- JWT session duration defaults to 24 hours; the backend supports configurable expiration via environment variable. Logout blocklist uses an in-memory Set (acceptable for single-server POS deployment; lost on restart, all active sessions remain valid until natural expiry).
- Email verification at registration is not required — the superadmin creates accounts directly and trusts the email provided.
- The system does not implement login rate limiting or account lockout in this iteration; this may be added later as a security enhancement.
- "Remember me" functionality (persistent sessions beyond the default expiry) is excluded from v1.
- The route-permission mapping follows the established convention documented in the project constitution.
- All entity `id` fields are strings (MongoDB ObjectId hex format) as per project conventions.
- The backend REST API uses the standard envelope format: `{ "success": bool, "data": ..., "message": ... }`.
