# Feature Specification: Phase 0 — Infrastructure Hardening

**Feature Branch**: `001-phase0-infra-hardening`

**Created**: 2026-07-04

**Status**: Draft

**Input**: User description: "read PLAN.md and create specification for the Phase 0: page and architecture only"

---

## Overview

Phase 0 establishes the foundational infrastructure that every subsequent ERP module depends on.
It does not add any business feature visible to end users; its output is a correctly wired
application skeleton: secure credential transport, dependency injection, route protection,
and a clear folder contract that all 15 modules will follow.

This specification covers **screens/pages** and **architecture** only, as requested.
It does not prescribe implementation code — that is handled by the planning and task phases.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Unauthenticated User Is Always Redirected to Login (Priority: P1)

An unauthenticated visitor who opens any protected URL in the ERP app is automatically
redirected to the login screen. They cannot access any module screen by typing a URL directly.
After a successful login, the app routes them to the dashboard.

**Why this priority**: Without this gate, every other module is insecure. This is the
single condition that makes the rest of the application safe to build.

**Independent Test**: Open the app with no stored session. Attempt to navigate to any
protected route (e.g., `/dashboard`, `/units`, `/materials`). Verify the browser lands
on `/login` regardless of the attempted path.

**Acceptance Scenarios**:

1. **Given** the app is opened for the first time (no stored session), **When** the app
   loads, **Then** the user sees the Login screen and no other content is rendered.
2. **Given** the app is open on `/login`, **When** the user provides valid credentials,
   **Then** they are redirected to `/dashboard` and the Login screen is no longer shown.
3. **Given** the user is on `/dashboard` (authenticated), **When** they copy that URL
   and open a new tab without a session, **Then** they land on `/login`, not `/dashboard`.
4. **Given** the user is authenticated, **When** their session token expires or is
   invalidated, **Then** any next navigation or API call redirects them to `/login`
   and they do not see a partial/broken screen.

---

### User Story 2 — JWT Token Is Automatically Carried on Every API Request (Priority: P2)

When a logged-in user triggers any action that requires data from the backend (loading a list,
submitting a form, etc.), the app automatically includes their identity credential in the
request. The user never manually manages tokens, and no module needs to know about the
token storage mechanism.

**Why this priority**: All 15 business modules make API calls. Without automatic token
injection, every data source would need its own credential-handling logic — causing
duplication and security holes.

**Independent Test**: Log in, then perform any API action (e.g., navigate to a screen that
loads a list). Inspect the outgoing network requests in browser dev tools. Every request to
the backend must carry the `Authorization` header with a valid bearer token.

**Acceptance Scenarios**:

1. **Given** the user is logged in, **When** any screen loads data from the backend,
   **Then** the outgoing HTTP request contains the `Authorization: Bearer <token>` header
   without the screen's code explicitly adding it.
2. **Given** the backend returns a 401 Unauthorized response, **When** this happens
   on any request, **Then** the app clears the stored token, emits an unauthenticated
   event, and redirects the user to the Login screen.
3. **Given** the user logs out, **When** they attempt any subsequent action, **Then**
   no token is present in outgoing requests.

---

### User Story 3 — All App Dependencies Are Resolved from a Single Registry (Priority: P3)

Any screen or logic class in the app can obtain the service or repository it needs without
importing concrete implementations. Adding a new module does not require changing how
existing modules locate their dependencies.

**Why this priority**: Without a centralized dependency registry, module code becomes
tightly coupled to concrete classes, making testing and future swapping of implementations
impractical.

**Independent Test**: Open the app. Verify it boots without errors. The `SessionBloc`
and `AuthBloc` are available to any widget in the tree. Adding a second registration
for a new module (e.g., `UnitsRepository`) requires touching only the registry file,
not any existing screen.

**Acceptance Scenarios**:

1. **Given** the app starts, **When** `main()` runs, **Then** all services, repositories,
   and blocs are registered before the first widget is rendered.
2. **Given** a screen requires `SessionBloc`, **When** the screen initializes,
   **Then** it receives the pre-registered singleton without instantiating it directly.
3. **Given** a new module repository is registered in the registry, **When** the app
   restarts, **Then** no existing module's code needs to change.

---

### Edge Cases

- What happens when the device has no network connectivity when the app first opens?
  The app MUST show the Login screen (not crash), and the login form MUST show a
  meaningful offline error when the user submits.
- What happens when the stored token is malformed (corrupted storage)?
  The app MUST treat a malformed token as no token — redirect to Login and clear storage.
- What happens if two tabs are open and the user logs out in one?
  The other tab MUST detect the invalidated session on its next API call and redirect to Login.
- What happens when a user with a valid token navigates to a route that requires a
  permission flag they do not hold?
  The app MUST redirect them to `/dashboard` (not show an error screen or crash).

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST redirect any unauthenticated request for a protected route to
  the Login screen before any protected content is rendered.
- **FR-002**: The app MUST redirect an authenticated user away from the Login screen to
  the Dashboard when they attempt to access `/login`.
- **FR-003**: The app MUST automatically attach the stored authentication credential to
  every outgoing API request without requiring any action from the calling screen or module.
- **FR-004**: The app MUST intercept HTTP 401 responses from any endpoint and respond by
  immediately clearing the stored credential and navigating the user to the Login screen.
  The app MUST NOT attempt a silent token refresh; every 401 is a hard logout regardless
  of cause (expiry, revocation, or server-side invalidation).
- **FR-005**: The app MUST register all services, repositories, and state-management
  objects in a single, centralized dependency registry before the widget tree is built.
- **FR-006**: The app MUST persist the authentication credential securely across app
  restarts so that a previously authenticated user does not need to log in again on
  next launch (until the token expires or they explicitly log out).
- **FR-007**: The app MUST define route path constants for all 15 ERP modules as part
  of this phase, even though those module screens are not yet implemented.
- **FR-008**: Any route that requires a specific permission flag MUST redirect to
  `/dashboard` when the authenticated user's permission set does not include that flag.
- **FR-009**: The router MUST read session state from the centralized dependency registry
  — it MUST NOT instantiate its own state or make direct storage calls.
- **FR-010**: A `PermissionFailure` error type MUST exist and be usable by any module
  to express access-denied conditions in the functional error pipeline.
- **FR-011**: All backend API calls MUST use paths relative to `API_BASE_URL`, which
  MUST include the `/api/v1` version prefix — no individual data source may hard-code
  the version segment in its own path strings.
- **FR-012**: The JWT storage key MUST be defined as a single named constant (`kJwtTokenKey`)
  used consistently by every component that reads, writes, or deletes the stored token —
  no component may use a raw string literal for this key.
- **FR-013**: If `setupServiceLocator()` fails during app startup, the app MUST crash
  visibly — the exception MUST be logged and the Flutter error screen MUST be shown.
  The app MUST NOT partially boot with missing registrations; boot failure is treated
  as unrecoverable.

### Key Entities

- **Session**: Represents whether a user is currently authenticated. Has three states:
  unknown (app just launched, not yet determined), authenticated (valid credential present),
  unauthenticated (no credential or expired). Consumed by the router to make redirect decisions.

- **AppUser (extended)**: The authenticated user identity. Carries an identifier (string),
  email, display name, and a permission set (bitmask of 7 flags). Used by the router and
  sidebar to decide what the user may access.

- **Route Registry**: The complete, exhaustive list of named URL paths for all current
  and future ERP screens. Defined as constants so every module references the same values.

- **Dependency Registry**: The single source of truth for all instantiated services,
  repositories, and state objects. Populated at startup; consumed everywhere else.
  Defines the named storage constant `kJwtTokenKey = 'jwt_token'` used by every
  component that touches the stored credential — interceptor, repository impl,
  and session check use-case all reference this single constant.

---

## Architecture Specification

> This section is the primary output for the "architecture only" requirement.
> It describes the structural contracts Phase 0 must establish — not code, but the
> shape and responsibility of each component.

### Directory Structure (Phase 0 additions)

```
lib/
└── src/
    ├── services/
    │   └── service_locator.dart        ← NEW: single registration function
    │                                     called once in main(); registers all
    │                                     singletons (services, repos, blocs)
    │
    ├── config/
    │   └── app_config.dart             ← MODIFIED: add JWT interceptor to Dio
    │                                     (read token from SecureStorage on each
    │                                     request; handle 401 globally)
    │
    ├── routing/
    │   ├── app_routes.dart             ← MODIFIED: add all ERP route constants
    │   └── app_router.dart             ← MODIFIED: add redirect() guard that
    │                                     reads SessionBloc from get_it
    │
    └── utils/
        └── failure.dart                ← MODIFIED: add PermissionFailure type
```

### Component Responsibilities

#### `service_locator.dart` — Dependency Registry

**Single responsibility**: Register every injectable object in `get_it` before `runApp`.

| Registration | Type | Scope |
|---|---|---|
| `SecureStorageService` | Singleton | App lifetime |
| `StorageService` | Singleton | App lifetime |
| `DioService` | Singleton | App lifetime |
| `AuthService` | Singleton | App lifetime |
| `AuthRepositoryImpl` as `AuthRepository` | Singleton | App lifetime |
| `SessionBloc` | Singleton | App lifetime |
| `AuthBloc` | Singleton | App lifetime |

Rules:
- Registrations MUST be ordered: infrastructure services first, then data layer, then blocs.
- No bloc may be registered before the repository it depends on.
- `main.dart` calls `setupServiceLocator()` before `runApp()`.

#### `app_config.dart` — JWT Interceptor

**Addition**: A Dio interceptor that runs on every request and every error response.

```
On Request:
  1. Read token from SecureStorageService
  2. If token exists → inject "Authorization: Bearer <token>" header
  3. If no token → pass request through unmodified (login endpoint needs no header)

On Error (401):
  1. Clear token from SecureStorageService
  2. Notify AuthService stream (emit null user)
  3. Let the error propagate so the caller receives a proper Failure
```

The interceptor MUST NOT navigate directly (no `context.go` inside the interceptor).
Navigation is the router's responsibility via the session redirect guard.

#### `app_routes.dart` — Route Constants

**All ERP route paths defined as string constants.** Grouped by module for readability.
All paths are relative to the `API_BASE_URL` (which already contains `/api/v1`); no
data source repeats the version prefix.

```
Auth group:      /login, /forgot-password
Core group:      / (dashboard)
Lookup group:    /units, /categories
Inventory group: /materials, /materials/:id
Party group:     /suppliers, /suppliers/:id, /customers, /customers/:id
Branch group:    /branches
Purchase group:  /purchases, /purchases/new, /purchases/:id
Sales group:     /sales, /sales/new, /sales/:id
Voucher group:   /payment-vouchers, /payment-vouchers/new,
                 /receipt-vouchers, /receipt-vouchers/new
Transfer group:  /transfers, /transfers/new
Reports group:   /stock, /ledger, /reports
```

#### `app_router.dart` — Redirect Guard

**Addition**: A `redirect` function on the `GoRouter` instance.

```
redirect logic (evaluated on every navigation):
  1. Read SessionBloc.state from get_it (NO context dependency)
  2. If state == unknown → return null (wait; do not redirect while determining session)
  3. If state == unauthenticated AND route is not /login AND not /forgot-password
       → return /login
  4. If state == authenticated AND route IS /login
       → return / (dashboard)
  5. If state == authenticated AND route requires permission flag X
       AND user.permissions does not include flag X
       → return / (dashboard)
  6. Otherwise → return null (allow navigation)
```

The guard reads `SessionBloc` from `get_it` — it has no dependency on `BuildContext`.

#### `failure.dart` — PermissionFailure Type

**Addition**: One new subclass alongside the existing `ServerFailure`, `CacheFailure`,
`NetworkFailure`, and `UnknownFailure`.

```
PermissionFailure — used when the user's permission set does not allow an action.
  message: human-readable reason (e.g., "You do not have permission to edit materials")
  error: optional raw value for logging
```

All existing `Failure` subclasses remain unchanged.

---

### Data Flow: Startup Sequence

```
main()
  │
  ├─ WidgetsFlutterBinding.ensureInitialized()
  ├─ FlutterNativeSplash.preserve()
  ├─ EasyLocalization.ensureInitialized()
  ├─ dotenv.load('.env')
  ├─ AppConfig.init()          ← Dio configured + JWT interceptor attached
  ├─ setupServiceLocator()     ← get_it populated
  │     └─ on failure → log exception + rethrow (Flutter error screen shown;
  │                            app does NOT partially boot)
  │
  └─ runApp(
       LocalizationWrapper(
         StateWrapper(          ← provides SessionBloc (from get_it) to widget tree
           App()
         )
       )
     )
```

### Data Flow: Protected Route Access

```
User navigates to /materials
  │
  └─ GoRouter.redirect()
       │
       ├─ get_it<SessionBloc>().state == unknown?
       │     → return null (wait for session check to complete)
       │
       ├─ state == unauthenticated?
       │     → return '/login'
       │
       ├─ state == authenticated, user.can(canViewMaterials)?
       │     → return null (allow)
       │
       └─ state == authenticated, no permission?
             → return '/' (dashboard)
```

### Data Flow: API Call with Token Injection

```
Screen triggers CubitAction
  │
  └─ UseCase.execute()
       │
       └─ RemoteDataSource.fetchSomething()
            │
            └─ DioService.get('/endpoint')
                 │
                 └─ Dio interceptor (onRequest)
                      │
                       ├─ SecureStorageService.read(kJwtTokenKey)
                      ├─ token exists → add Authorization header
                      └─ pass to handler

         On 401 response:
            └─ Dio interceptor (onError)
                 │
                 ├─ SecureStorageService.deleteAll()
                 ├─ AuthService._authStateController.add(null)
                 └─ propagate DioException as ServerFailure

         SessionBloc hears stream → emits SessionState.unauthenticated()
         GoRouter.redirect() fires → returns '/login'
```

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An unauthenticated user who navigates to any protected path lands on the
  Login screen within one navigation cycle — no protected content is ever rendered first.
- **SC-002**: Every outgoing API request from a logged-in session carries an
  `Authorization` header — verified across all module screens without any screen-level
  code adding the header explicitly.
- **SC-003**: After a 401 response from any endpoint, the user is on the Login screen
  within two seconds and the stored credential is cleared — verified by inspecting
  storage after the redirect.
- **SC-004**: The app boots without errors and all registered dependencies are available
  to widgets before the first frame is rendered.
- **SC-005**: Route constants for all 15 ERP modules exist and are referenced consistently
  — no raw string paths appear anywhere outside `AppRoutes`.
- **SC-006**: A user with permission flag A but not flag B, who navigates to a route
  requiring flag B, is redirected to the dashboard — not shown an error screen or crash.
- **SC-007**: Hot restart with a valid stored session takes the user directly to the
  dashboard — the Login screen is not shown.
- **SC-008**: If the dependency registry throws during startup, a logged error entry
  is observable in the application log and the Flutter error screen is displayed —
  no silent failure, no blank screen, no partial UI.

---

## Assumptions

- The `.env` file is present and contains a valid `API_BASE_URL` value before the app runs.
  `API_BASE_URL` includes the versioned prefix (e.g., `https://host/api/v1`) so all data
  source paths are relative (e.g., `/units`, `/materials`) without repeating the prefix.
- The backend issues JWT tokens on login; token format is a standard bearer string stored as-is.
- Token expiry is enforced by the backend via 401 responses — the frontend does NOT
  attempt a silent refresh. Any 401 from any endpoint is treated as a hard logout:
  the stored token is cleared immediately and the user is redirected to the Login screen.
  There is no refresh token mechanism in Phase 0; this may be revisited in a future phase.
- The 7 permission flags are represented as a single integer bitmask field on the user object
  returned by the login API response.
- `StateWrapper` (already exists) wraps `SessionBloc` as a `BlocProvider` so the tree
  has access to session state; this wrapper will be updated to read from `get_it`.
- `SessionListenerWrapper` (already exists) will be updated to handle the
  `unauthenticated` → `/login` navigation using `BlocListener` in the widget tree,
  complementing the router redirect (defense-in-depth).
- The signup screen is out of scope for Phase 0 route guarding; ERP user creation is
  an admin operation handled outside the app for now.
- Mobile-specific secure storage behavior (Keychain on iOS, Keystore on Android) is
  handled by the existing `SecureStorageService` wrapper — no additional platform code needed.
- The `onboarding` screen is treated as a public (unauthenticated) route for now; it will
  be removed or repurposed in Phase 1 (Auth complete).

---

## Clarifications

### Session 2026-07-04

- Q: Does the backend API use a versioned path prefix before all resource paths? → A: Yes — `/api/v1` prefix on all endpoints (e.g., `GET /api/v1/units`). `API_BASE_URL` in `.env` includes this prefix so data sources use relative paths only.
- Q: Should the JWT storage key name be a named constant defined in this spec? → A: Yes — `kJwtTokenKey = 'jwt_token'` defined as a named constant; all components (interceptor, repo impl, session use-case) MUST reference this constant, never a raw string literal.
- Q: When the stored JWT expires, should the app attempt a silent token refresh or always treat expiry as a hard logout? → A: Hard logout — any 401 clears the token and sends the user to login immediately; no refresh token mechanism in Phase 0.
- Q: If the dependency registry fails to initialize at startup, what should the app do? → A: Crash visibly — log the exception and show the Flutter error screen; boot failure is unrecoverable and the app must not partially start.
