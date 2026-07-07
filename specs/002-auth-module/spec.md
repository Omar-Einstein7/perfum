# Feature Specification: Auth Module

**Feature Branch**: `002-auth-module`

**Created**: 2026-07-07

**Status**: Draft

**Input**: User description: "Phase 1 — Auth Module: Login flow, JWT persistence, session persistence across restart"

## User Scenarios & Testing

### User Story 1 — Login with Email & Password (Priority: P1)

As a registered user, I want to log in with my email and password so that I can access the system's protected features.

**Why this priority**: Login is the single gate to every other feature. Nothing else works without it.

**Independent Test**: Open the app with no stored session → fill in email + password → tap "Login" → land on the dashboard. An invalid email/password combination shows a clear error message and stays on the login page.

**Acceptance Scenarios**:

1. **Given** I am on the login page, **When** I enter a valid email and password and tap Login, **Then** I am taken to the dashboard and my session persists if I restart the app.
2. **Given** I am on the login page, **When** I enter an incorrect email or password, **Then** I remain on the login page and see a clear error message.
3. **Given** I am already logged in, **When** I open the app or navigate to the login page, **Then** I am automatically redirected to the dashboard without re-entering credentials.

---

### User Story 2 — Session Persistence Across Restarts (Priority: P1)

As a logged-in user, I want my session to survive app restarts so that I don't have to log in every time I open the app.

**Why this priority**: Identical priority to login — without persistence, the app is unusable for daily workflows.

**Independent Test**: Log in → close and reopen the app (or hot-restart) → land on the dashboard without seeing the login screen.

**Acceptance Scenarios**:

1. **Given** I am logged in, **When** I close and reopen the app (or hot-restart), **Then** I am still logged in and land on the dashboard.
2. **Given** my stored token has expired or is malformed, **When** the app starts, **Then** I am redirected to the login page and the invalid token is cleared.

---

### User Story 3 — Automatic Logout on Session Expiry (Priority: P2)

As a user, I want to be automatically logged out when my session expires so that unauthorized users cannot access the system with a stale token.

**Why this priority**: Important for security but the app functions without it. The 401 interceptor from Phase 0 already provides basic protection.

**Independent Test**: Log in → wait for token to expire (or force a 401 via DevTools) → the next API call triggers a redirect to the login page with no error screen.

**Acceptance Scenarios**:

1. **Given** I am logged in, **When** the backend returns a 401 on any API call, **Then** the app navigates to the login page, clears the stored token, and shows no error screen.
2. **Given** my token expires while I am idle on a page, **When** I trigger any action that makes an API call, **Then** I am redirected to the login page.

---

### User Story 4 — Account Registration (Priority: P3)

As a new user, I want to create an account so that I can access the system.

**Why this priority**: Registration is needed long-term but Phase 1 can be validated with pre-seeded accounts. Admins can create users manually.

**Independent Test**: Navigate to the registration page → fill in name, email, password → submit → land on the dashboard as a logged-in user.

**Acceptance Scenarios**:

1. **Given** I am on the registration page, **When** I fill in all required fields and submit, **Then** I am logged in automatically and taken to the dashboard.
2. **Given** I am on the registration page, **When** I enter an email that is already registered, **Then** I see a clear error message.
3. **Given** I am on the registration page, **When** I leave required fields empty, **Then** I see validation errors and cannot submit.

---

### User Story 5 — Password Reset (Priority: P4)

As a user who forgot my password, I want to request a password reset link so that I can regain access to my account.

**Why this priority**: Important for user self-service but the system can launch with admin-managed password resets.

**Independent Test**: Navigate to the forgot-password page → enter registered email → see a confirmation message that a reset link was sent.

**Acceptance Scenarios**:

1. **Given** I am on the forgot-password page, **When** I enter a registered email and submit, **Then** I see a confirmation message.
2. **Given** I am on the forgot-password page, **When** I enter an unregistered email, **Then** I see the same confirmation message (to avoid revealing which emails are registered).

---

### Edge Cases

- What happens when a user tries to access a protected route while the session check is still in progress? They should see a loading/splash state, not a flash of the login page.
- What happens when both a valid and expired token are present? The session check call should resolve this — the backend validates the token.
- What happens when the network is unreachable during login? A clear error message should appear, and the app should not crash.
- What happens when a user logs out and then presses the browser's back button? They should stay on the login page, not see cached protected content.

## Requirements

### Functional Requirements

- **FR-001**: System MUST allow users to log in using their email address and password.
- **FR-002**: System MUST validate credentials against the backend and return a session token on success.
- **FR-003**: System MUST persist the session token locally so it survives app restarts.
- **FR-004**: System MUST validate the stored session token on app startup by making a single verification call to the backend.
- **FR-005**: System MUST redirect authenticated users away from the login page to the dashboard.
- **FR-006**: System MUST redirect unauthenticated users to the login page when they attempt to access any protected route.
- **FR-007**: System MUST automatically log the user out when the backend returns a token-expired or unauthorized response.
- **FR-008**: System MUST clear the stored session token on logout or token expiry.
- **FR-009**: System MUST allow users to register a new account with name, email, and password.
- **FR-010**: System MUST validate that passwords meet minimum complexity requirements (length only — at least 6 characters).
- **FR-011**: System MUST allow users to request a password reset by entering their registered email.
- **FR-012**: System MUST display clear, user-friendly error messages for login failures — not technical error codes.
- **FR-013**: System MUST show a loading indicator during login, registration, and session-check operations so the user knows the system is working.
- **FR-014**: System MUST prevent logged-in users from accessing the login, registration, or forgot-password pages (redirect to dashboard).
- **FR-015**: System MUST allow users to log out explicitly, which clears the local session and returns them to the login page.

### Key Entities

- **User**: A person who can access the system. Has a unique email address, a name, a set of permission flags determining which features they can access, and a password (stored only on the backend, never on the client).
- **Session**: A temporary authenticated state tied to a user. Identified by a token issued by the backend upon successful login. The token has an expiry time.
- **Permission**: A bitmask flag that controls access to a specific feature area (e.g., view sales, edit masters). Seven distinct permissions exist. A user's permissions are set by an administrator on the backend and cannot be changed by the user.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A user with valid credentials can complete login and reach the dashboard in under 3 seconds on a typical internet connection.
- **SC-002**: A logged-in user who hot-restarts or fully reopens the app lands on the dashboard without seeing the login screen.
- **SC-003**: An invalid login attempt shows an error message within 2 seconds of tapping the login button.
- **SC-004**: When a stored session token expires, the next user action that triggers an API call results in navigation to the login page within 2 seconds — no error screen, no crash.
- **SC-005**: All public routes (login, registration, forgot-password) redirect authenticated users to the dashboard.
- **SC-006**: All protected routes redirect unauthenticated users to the login page.
- **SC-007**: An explicit logout clears the session and returns the user to the login page, and pressing the browser back button does not restore the previous protected page.

## Assumptions

- The backend already supports the required endpoints (`POST /auth/login`, `POST /auth/register`, `POST /auth/forgot-password`, `GET /auth/me`, `POST /auth/logout`).
- Pre-seeded user accounts exist on the backend for testing (admin-created accounts for initial validation).
- Email delivery for password reset is handled by the backend — the frontend only sends the request.
- The system will be used on desktop web browsers primarily (Chrome, Edge) — mobile responsive but not the primary target.
- Session tokens expire after a reasonable period (e.g., 24 hours) as configured on the backend.
