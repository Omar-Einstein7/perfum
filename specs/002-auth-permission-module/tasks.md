# Tasks: Auth & Permission Module

**Input**: Design documents from `/specs/002-auth-permission-module/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Included per constitution mandate (Test Discipline) — every UseCase and Bloc must have at least one test. Existing test scaffold at `test/features/auth/` defines expected interfaces.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Frontend**: `lib/features/auth/`, `lib/core/`, `lib/src/routing/`, `lib/src/services/`
- **Backend**: `server/src/models/`, `server/src/routes/`, `server/src/middleware/`
- **Tests**: `test/features/auth/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, dependency setup, and basic structure

- [x] T001 Install get_it package and create DI container at `lib/core/di/injection_container.dart` with registration skeleton for auth module
- [x] T002 [P] Add freezed + json_serializable dev dependencies to pubspec.yaml for sealed state generation (deferred — hand-written states used instead)
- [x] T003 [P] Add mocktail and bloc_test dev dependencies to pubspec.yaml (needed by existing tests)
- [x] T004 [P] Add bcryptjs and jsonwebtoken npm packages to `server/package.json` for backend auth
- [x] T005 Create `server/src/models/User.js` Mongoose schema with fields: email, password (hashed), role (enum: superadmin/admin/staff), permissions (embedded object with 7 booleans), status (active/deactivated), timestamps
- [x] T006 [P] Create `server/src/middleware/auth.js` — JWT verification middleware that decodes token, attaches user to req, and a `requirePermission(flag)` middleware factory that checks req.user.permissions
- [x] T007 Create `lib/features/auth/` directory structure: `domain/entities/`, `domain/repositories/`, `domain/usecases/`, `data/datasources/`, `data/models/`, `data/repositories/`, `presentation/bloc/`, `presentation/pages/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core domain entities, abstract interfaces, and shared base classes that MUST be complete before any user story

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T008 Create `lib/features/auth/domain/entities/user.dart` — pure Dart entity with id (String), email (String), role (String), permissions (Map<String, bool>), status (String). No Flutter/Dio imports.
- [x] T009 [P] Create `lib/features/auth/domain/entities/session.dart` — pure Dart entity with accessToken (String), expiresIn (int), user (User)
- [x] T010 Create `lib/features/auth/domain/repositories/auth_repository.dart` — abstract class defining login(), logout(), getMe(), listUsers(), createUser(), updateUser(), deleteUser() methods
- [x] T011 [P] Create `lib/features/auth/domain/usecases/login_usecase.dart` — LoginUseCase with single call(email, password) returning Future<Session>
- [x] T012 [P] Create `lib/features/auth/data/models/user_model.dart` — UserModel extends User with fromJson/toJson, using dart:convert only (no Dio dependency)
- [x] T013 [P] Create `lib/features/auth/data/models/token_response_model.dart` — TokenResponseModel with fromJson/toJson for backend login response (accessToken, expiresIn, user)
- [x] T014 Create `lib/features/auth/data/datasources/auth_remote_data_source.dart` — abstract class + AuthRemoteDataSourceImpl(dio) with login(), logout(), getMe(), listUsers(), createUser(), updateUser(), deleteUser() methods
- [x] T015 Create `lib/features/auth/data/repositories/auth_repository_impl.dart` — AuthRepositoryImpl implements AuthRepository, delegates to AuthRemoteDataSourceImpl, maps ServerException to Failure

**Checkpoint**: Foundation ready — user story implementation can now begin

---

## Phase 3: User Story 1 — User Login with Email & Password (Priority: P1) 🎯 MVP

**Goal**: Users can log in with email/password, receive a JWT session token, and be redirected to an authenticated landing page. Failed attempts show generic errors. Existing sessions auto-authenticate on revisit.

**Independent Test**: Visit the login page at `/login`, submit valid credentials, confirm redirect to dashboard with a valid session token stored in secure storage. Then refresh the page — user should remain authenticated.

### Tests for User Story 1 ⚠️

- [ ] T016 [P] [US1] Implement LoginUseCase test in `test/features/auth/domain/usecases/login_usecase_test.dart` (existing scaffold) — mock repository, verify call() returns Session on success, Failure on invalid credentials
- [ ] T017 [P] [US1] Implement AuthRemoteDataSource test in `test/features/auth/data/datasources/auth_remote_data_source_test.dart` (existing scaffold) — mock Dio, verify login calls POST /auth/login and parses TokenResponseModel
- [ ] T018 [P] [US1] Implement AuthBloc test in `test/features/auth/presentation/bloc/auth_bloc_test.dart` (existing scaffold) — verify Loading→Authenticated on success, Loading→AuthError on failure

### Backend Implementation for User Story 1

- [x] T019 [US1] Implement `POST /auth/login` in `server/src/routes/auth.js` — validate email/password, find user by email, compare bcrypt hash, generate JWT with user id/role/permissions, return TokenResponse
- [x] T020 [P] [US1] Implement `POST /auth/logout` in `server/src/routes/auth.js` — add token to blocklist (in-memory Set), return success
- [x] T021 [P] [US1] Implement `GET /auth/me` in `server/src/routes/auth.js` — return current user profile from JWT payload (or DB lookup if needed)

### Frontend Implementation for User Story 1

- [x] T022 [US1] Register auth module dependencies in `lib/core/di/injection_container.dart` — Dio (lazySingleton), AuthRemoteDataSourceImpl (lazySingleton), AuthRepositoryImpl (lazySingleton), LoginUseCase (factory), AuthBloc (factory), SessionBloc (factory)
- [x] T023 [P] [US1] Update Dio setup in DI container with JWT interceptor — read token from flutter_secure_storage, attach Authorization header, handle 401 by clearing stored token
- [x] T024 [US1] Create `lib/features/auth/presentation/bloc/auth_bloc.dart` with AuthEvent (LoginSubmitted) and AuthState union (AuthInitial, AuthLoading, Authenticated, AuthError) using hand-written sealed classes
- [x] T025 [P] [US1] Create `lib/features/auth/presentation/bloc/session_bloc.dart` with SessionState (unknown/authenticated/unauthenticated) and checkSession/logout methods
- [x] T026 [US1] Create login page at `lib/features/auth/presentation/pages/login_page.dart` — email + password fields, submit button, form validation (8+ chars, 1 upper, 1 lower, 1 digit per FR-015), loading state, error display
- [x] T027 [P] [US1] Update `lib/src/routing/app_router.dart` with login route (`/login`) and go_router redirect guard that checks SessionBloc state — redirects to `/login` if unauthenticated, allows access if authenticated
- [x] T028 [US1] Update `lib/src/shared/wrappers/session_listener_wrapper.dart` to use new SessionBloc — listen for status changes, navigate accordingly
- [x] T029 [US1] Call `configureDependencies()` from `lib/core/di/injection_container.dart` in `lib/main.dart` before `runApp()`

**Checkpoint**: At this point, User Story 1 should be fully functional — users can log in, receive JWT, auto-authenticate on revisit, and log out

---

## Phase 4: User Story 2 — Superadmin User Management (Priority: P1)

**Goal**: Superadmins can view, create, edit, deactivate/reactivate, and delete users. All actions are audit-logged. The last superadmin cannot be deleted or downgraded.

**Independent Test**: Log in as superadmin, navigate to `/users`, create a new user with specific role/permissions, verify the user appears in the list, then log in as the new user to confirm their access matches the assigned permissions.

### Tests for User Story 2 ⚠️

- [ ] T030 [P] [US2] Implement UserManagementBloc test in `test/features/auth/presentation/bloc/user_management_bloc_test.dart` (existing scaffold) — verify LoadUsers emits UsersLoaded, CreateUser adds to list, DeleteUser removes from list
- [ ] T031 [P] [US2] Implement ProfilePage test in `test/features/auth/presentation/pages/profile_page_test.dart` (existing scaffold — placeholder, may be deferred)

### Backend Implementation for User Story 2

- [x] T032 [US2] Implement `GET /users` in `server/src/routes/users.js` — list users with pagination, requires `p_user` permission middleware
- [x] T033 [P] [US2] Implement `POST /users` in `server/src/routes/users.js` — create user with email, password (bcrypt hashed), role, permissions. Validate password complexity. Requires `p_user` permission.
- [x] T034 [P] [US2] Implement `PUT /users/:id` in `server/src/routes/users.js` — update role, permissions, status. Prevent last-superadmin downgrade/deletion. Requires `p_user`.
- [x] T035 [P] [US2] Implement `DELETE /users/:id` in `server/src/routes/users.js` — delete user. Prevent self-deletion and last-superadmin deletion. Requires `p_user`.
- [x] T036 [US2] Create `server/src/models/AuditLog.js` — Mongoose schema for audit entries: actorId, action (enum: user_created/permission_changed/role_changed/user_deactivated/user_reactivated/user_deleted), targetUserId, before/after (Mixed), timestamp
- [x] T037 [US2] Add audit logging middleware in user routes — on every user mutation, create an AuditLog entry recording the acting superadmin's id, the action type, target user id, and before/after snapshots of changed fields

### Frontend Implementation for User Story 2

- [x] T038 [US2] Create `lib/features/auth/presentation/bloc/user_management_bloc.dart` with UserManagementEvent (LoadUsers, CreateUser, UpdateUser, DeleteUser) and sealed UserManagementState (UserManagementInitial, UserManagementLoading, UsersLoaded, UserManagementError) using hand-written classes
- [x] T039 [US2] Create user management page in `lib/features/auth/presentation/pages/user_management_page.dart` — list of all users with role/permissions display, create/edit/delete dialog
- [x] T040 [P] [US2] Create user create/edit form (inline dialog in user_management_page.dart) — email, password (create only), role dropdown, 7 permission toggles, save/cancel buttons
- [x] T041 [US2] Add `/users` route to `lib/src/routing/app_router.dart` — gated by `p_user` permission in redirect guard
- [ ] T042 [US2] Add audit log display (optional) — consider showing recent audit log entries on user management page or a dedicated `/audit-log` tab

**Checkpoint**: At this point, User Stories 1 AND 2 should work — superadmins can fully manage users and permissions

---

## Phase 5: User Story 3 — Role-Based Route Access Control (Priority: P2)

**Goal**: Logged-in users see only the navigation items and routes matching their assigned permission flags. Direct URL access to unauthorized routes redirects to `/403`.

**Independent Test**: Create a user with only `p_info: true`, log in as that user, verify that only info-related routes (materials, categories, units) are visible in navigation and accessible. Verify `/users` URL redirects to `/403`.

### Tests for User Story 3 ⚠️

- [ ] T043 [P] [US3] Add widget test for navigation filtering — render navigation with different permission sets, verify only permitted items are rendered

### Frontend Implementation for User Story 3

- [ ] T044 [US3] Create permission-aware navigation widget in `lib/src/shared/widgets/permission_nav.dart` — reads current user's permissions from AuthCubit/SessionBloc, renders only permitted nav items using the route-permission map from constitution
- [ ] T045 [P] [US3] Update `lib/src/routing/app_router.dart` redirect guard — add permission check: after auth check passes, verify the target route's required permission flag (from route-permission map) is present in user's permissions; redirect to `/403` if missing
- [ ] T046 [P] [US3] Create `/403` page in `lib/src/shared/widgets/forbidden_page.dart` — "Access denied" message with a "Go to dashboard" button
- [ ] T047 [US3] Integrate permission nav into existing app shell — replace existing navigation with permission-filtered version, ensuring all existing routes respect the permission map

### Backend Implementation for User Story 3

- [ ] T048 [US3] Apply `requirePermission('p_info')` middleware to materials/categories/units routes in server
- [ ] T049 [P] [US3] Apply `requirePermission('p_res')` middleware to suppliers/purchase-invoices routes in server
- [ ] T050 [P] [US3] Apply `requirePermission('p_sell')` middleware to customers/sales-invoices routes in server
- [ ] T051 [P] [US3] Apply `requirePermission('p_snadat')` middleware to vouchers routes in server
- [ ] T052 [P] [US3] Apply `requirePermission('p_user')` middleware to users routes in server
- [ ] T053 [P] [US3] Apply `requirePermission('p_report')` or `requirePermission('p_report2')` middleware to reports routes in server (either flag grants access)
- [ ] T053b [US3] Add JWT expiry detection in Dio interceptor at `lib/src/services/dio_service.dart` — on 401 response, emit session expired event and redirect to login with toast

**Checkpoint**: All user stories should now be independently functional with full permission gating on both frontend and backend

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Seed data, edge case handling, validation consistency

- [ ] T054 [P] Create `server/src/seed.js` — seed script that creates a default superadmin user (admin@example.com / Admin123!) with all permissions
- [ ] T055 [P] Add password validation consistency — ensure both frontend (login form) and backend (POST /users) enforce the same FR-015 rules (8+ chars, 1 upper, 1 lower, 1 digit)
- [ ] T056 Handle edge cases — expired JWT mid-form redirects to login with session-expired toast; deactivated user login prevented at both frontend and backend; max login retries not enforced per assumptions
- [ ] T057 [P] Add `use_launch_url.dart` / logout integration — on logout, clear secure storage (JWT), reset get_it state (pop scopes if used), navigate to login
- [ ] T058 Run full validation per quickstart.md scenarios — login flow, permission filtering, user CRUD, logout, password validation
- [ ] T059 Run existing test suite: `flutter test test/features/auth/` — ensure all existing and new tests pass
- [ ] T060 [P] Add login timing measurement — verify SC-001 (<3s) using browser DevTools or a timer wrapper in `test/features/auth/presentation/bloc/auth_bloc_test.dart`
- [ ] T061 [P] Add redirect timing measurement — verify SC-004 (<1s) for `/users` redirect to `/403` for unauthorized user
- [ ] T062 [P] Add user edit timing measurement — verify SC-005 (<30s) for superadmin editing user permissions end-to-end

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational completion
- **User Story 2 (Phase 4)**: Depends on Foundational completion; backend can parallel US1 backend, frontend needs US1 login working first
- **User Story 3 (Phase 5)**: Depends on US1 + US2 completion (needs users with different permissions to test)
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies on other stories — fully independent MVP
- **User Story 2 (P1)**: Backend can parallel US1; frontend needs working login to manage users
- **User Story 3 (P2)**: Depends on US2 to create users with varied permissions for testing

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Models before services (data layer before domain layer before presentation)
- Backend endpoints before frontend integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Phase 1 [P] tasks can run in parallel
- All Phase 2 [P] tasks can run in parallel
- US1 and US2 backend tasks can run in parallel (both are CRUD endpoints on different resources)
- Tests within a story marked [P] can run in parallel
- Models/entities within a story marked [P] can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: T016 [P] [US1] Implement LoginUseCase test
Task: T017 [P] [US1] Implement AuthRemoteDataSource test
Task: T018 [P] [US1] Implement AuthBloc test

# Launch all backend endpoints for User Story 1 together:
Task: T019 [US1] POST /auth/login
Task: T020 [P] [US1] POST /auth/logout
Task: T021 [P] [US1] GET /auth/me

# Launch all frontend components for User Story 1 together:
Task: T022 [US1] Register get_it dependencies
Task: T023 [P] [US1] Dio JWT interceptor
Task: T024 [US1] AuthBloc
Task: T025 [P] [US1] SessionBloc
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1 (Login)
4. **STOP and VALIDATE**: Test User Story 1 independently — login, JWT storage, auto-auth, logout
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 (Login) → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 (User Management) → Test independently → Deploy/Demo
4. Add User Story 3 (Route Access Control) → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Login — frontend + backend)
   - Developer B: User Story 2 (User Management — backend first, then frontend)
3. After US1 + US2: Developer(s) work on User Story 3 (Route Access Control)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
