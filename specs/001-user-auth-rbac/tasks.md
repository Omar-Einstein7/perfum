---
description: "Task list for User Authentication & RBAC feature implementation"
---

# Tasks: User Authentication & RBAC

**Input**: Design documents from `/specs/001-user-auth-rbac/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/auth-api.md

**Tests**: Test tasks are included per the constitution's Test Discipline (Principle V: every UseCase and Cubit/Bloc MUST have at least one test).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Frontend**: `lib/` at repository root (Flutter Web)
- **Backend**: `server/` at repository root (Node.js + Express)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create Flutter frontend project structure under `lib/` with Clean Architecture folders: `lib/core/{di,network,router}/`, `lib/features/auth/{data,domain,presentation}/`
- [x] T002 Create backend server project: `server/package.json` with express, mongoose, bcryptjs, jsonwebtoken, express-rate-limit, cors, dotenv dependencies
- [x] T003 Create server `.env` file with `PORT`, `MONGODB_URI`, `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `ACCESS_TOKEN_EXPIRY=15m`, `REFRESH_TOKEN_EXPIRY=7d`
- [x] T004 [P] Configure freezed + json_serializable in `pubspec.yaml` for the Flutter project

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Create User Mongoose model in `server/src/models/User.js` following the schema from data-model.md (email, passwordHash with select:false, role, status, permissions object with 7 booleans, lastLoginAt, timestamps)
- [x] T006 Setup MongoDB connection in `server/src/config/db.js` reading `MONGODB_URI` from env
- [x] T007 Implement JWT auth middleware in `server/src/middleware/auth.js` — validates access token, attaches user to `req.user`
- [x] T008 [P] Implement permission middleware in `server/src/middleware/permission.js` — factory function `requirePermission(flag)` that checks `req.user.permissions[flag]`
- [x] T009 [P] Create Dio client wrapper in `lib/core/network/dio_client.dart` with base URL from config and retry-on-401 interceptor
- [x] T010 [P] Create domain entities: `User` in `lib/features/auth/domain/entities/user.dart` and `Session` in `lib/features/auth/domain/entities/session.dart` (pure Dart + equatable, no serialization)
- [x] T011 Create base DI injection container in `lib/core/di/injection_container.dart` with GetIt instance

**Checkpoint**: Foundation ready — user story implementation can now begin in parallel on frontend and backend

---

## Phase 3: User Story 1 - User Login and Session-Based Navigation (Priority: P1) 🎯 MVP

**Goal**: A registered user can log in with email/password, receive JWT tokens, see a navigation sidebar filtered to their granted permissions, and benefit from silent token refresh.

**Independent Test**: Login with valid credentials for each role, verify dashboard loads with correct permission-filtered navigation, test expired token auto-refresh, test invalid credentials show error.

### Backend Implementation for User Story 1

- [x] T012 Implement `AuthService` in `server/src/services/authService.js` — login (verify bcrypt, check status, update lastLoginAt, generate tokens), refresh (validate refresh token, rotate with reuse detection), logout (invalidate refresh token)
- [x] T013 Implement `AuthController` in `server/src/controllers/authController.js` — `login`, `refresh`, `logout`, `getMe` handlers mapping service results to `{ success, data, message }` envelope
- [x] T014 Implement auth routes in `server/src/routes/auth.js` — POST `/api/auth/login`, POST `/api/auth/refresh`, POST `/api/auth/logout`, GET `/api/auth/me` (protected with auth middleware)
- [x] T015 Create Express app entry point in `server/src/app.js` — cors, json parser, route mounting, error handler, DB connection, server start

### Frontend Implementation for User Story 1

- [x] T016 [P] Create `UserModel` in `lib/features/auth/data/models/user_model.dart` and `TokenResponseModel` in `lib/features/auth/data/models/token_response_model.dart` with fromJson/toJson (freezed)
- [x] T017 [P] Create `AuthRemoteDataSource` in `lib/features/auth/data/datasources/auth_remote_data_source.dart` — login, refresh, logout, getMe methods using Dio client
- [x] T018 Create `AuthRepository` abstract interface in `lib/features/auth/domain/repositories/auth_repository.dart`
- [x] T019 Create `AuthRepositoryImpl` in `lib/features/auth/data/repositories/auth_repository_impl.dart` mapping data source responses to domain entities
- [x] T020 Create `LoginUseCase` in `lib/features/auth/domain/usecases/login_usecase.dart` with single `call()` method
- [x] T021 Create `AuthBloc` in `lib/features/auth/presentation/bloc/` — `auth_event.dart` (LoginSubmitted, TokenRefreshed, LoggedOut, SessionExpired), `auth_state.dart` (Initial, Loading, Authenticated, Unauthenticated, Error via freezed), `auth_bloc.dart` handling login/logout/token refresh
- [x] T022 Create `LoginPage` in `lib/features/auth/presentation/pages/login_page.dart` and `LoginForm` widget in `lib/features/auth/presentation/widgets/login_form.dart`
- [x] T023 [P] Create `AuthInterceptor` in `lib/core/network/auth_interceptor.dart` — attaches Bearer token from AuthBloc state, intercepts 401 to attempt token refresh via `/api/auth/refresh`, retries original request
- [x] T024 [P] Create `AuthGuard` in `lib/core/router/auth_guard.dart` — redirect guard checking AuthBloc state: redirects to `/login` if Unauthenticated, to `/403` if route permission not in user's permissions
- [x] T025 Create `AppRouter` in `lib/core/router/app_router.dart` with go_router routes for `/login`, `/`, `/403`, and protected routes gated by AuthGuard
- [x] T026 Wire up `main.dart` — register all DI (AuthRemoteDataSource → AuthRepository → LoginUseCase → AuthBloc as factory), wrap MaterialApp.router with router, BlocProvider for AuthBloc

### Tests for User Story 1 (Constitution Required)

- [x] T027 [P] [US1] Unit test for `LoginUseCase` in `test/features/auth/domain/usecases/login_usecase_test.dart` — mock AuthRepository, verify call delegates correctly, Loading → Authenticated and Loading → Error transitions
- [x] T028 [P] [US1] Data layer test for `AuthRemoteDataSource` in `test/features/auth/data/datasources/auth_remote_data_source_test.dart` — mock Dio, verify JSON request/response mapping
- [x] T029 [P] [US1] Bloc test for `AuthBloc` in `test/features/auth/presentation/bloc/auth_bloc_test.dart` — verify Initial → Loading → Authenticated and Initial → Loading → Error transitions
- [x] T030 [P] [US1] Backend integration test for auth endpoints in `server/tests/auth.test.js` — jest + supertest, verify login success/failure, token refresh, logout

**Checkpoint**: At this point, User Story 1 should be fully functional — login flow, token refresh, permission-based navigation, and 403 guard all work independently

---

## Phase 4: User Story 2 - Superadmin User Management (Priority: P1)

**Goal**: Superadmin can create, read, update, and delete user accounts, assign roles and permissions, and reset passwords.

**Independent Test**: Login as superadmin, create a new user with specific permissions, log out, log in as new user and verify permissions take effect. Verify non-superadmin cannot access any user management feature.

### Backend Implementation for User Story 2

- [x] T031 [US2] Add user CRUD methods to `AuthService` in `server/src/services/authService.js` — createUser, updateUser, deleteUser, listUsers (with last-superadmin guard, email uniqueness validation, bcrypt for new passwords)
- [x] T032 [US2] Add user management controller methods to `AuthController` in `server/src/controllers/authController.js` — create, update, delete, list handlers
- [x] T033 [US2] Add user management routes in `server/src/routes/auth.js` — POST `/api/auth/users`, PUT `/api/auth/users/:id`, DELETE `/api/auth/users/:id`, GET `/api/auth/users` (all protected with auth + permission(`p_user`) + superadmin check middleware)

### Frontend Implementation for User Story 2

- [x] T034 [P] [US2] Create `UserManagementBloc` in `lib/features/auth/presentation/bloc/user_management_bloc.dart` — events for CreateUser, UpdateUser, DeleteUser, LoadUsers; freezed sealed states
- [x] T035 [US2] Create `UserListPage` in `lib/features/auth/presentation/pages/user_list_page.dart` — paginated user table with role/permissions/status columns, create/edit/delete buttons
- [x] T036 [US2] Create `UserFormPage` in `lib/features/auth/presentation/pages/user_form_page.dart` — form with email, password, role dropdown, 7 permission toggles, status selector, submit button
- [x] T037 [US2] Add user management routes to `AppRouter` in `lib/core/router/app_router.dart` — `/users` (requires `p_user`), `/users/new`, `/users/:id/edit`

### Tests for User Story 2 (Constitution Required)

- [x] T038 [P] [US2] Bloc test for `UserManagementBloc` in `test/features/auth/presentation/bloc/user_management_bloc_test.dart`
- [x] T039 [P] [US2] Backend integration test for user management endpoints in `server/tests/permission.test.js`

**Checkpoint**: Superadmin can fully manage users. User creation, permission assignment, deactivation, and deletion all work.

---

## Phase 5: User Story 3 - Admin/Staff Profile View (Priority: P3)

**Goal**: Non-superadmin users can view their own profile with role and permissions (read-only).

**Independent Test**: Log in as staff user, navigate to profile page, verify email, role, and permissions are displayed. Verify no edit controls exist.

### Implementation for User Story 3

- [x] T040 [US3] Create `ProfilePage` in `lib/features/auth/presentation/pages/profile_page.dart` — displays user email, role, status, and permissions list (read-only). Accessible to all authenticated users.
- [x] T041 [US3] Add profile route to `AppRouter` in `lib/core/router/app_router.dart` — `/profile` (requires any authenticated user)

### Tests for User Story 3 (Constitution Required)

- [x] T042 [P] [US3] Widget test for `ProfilePage` in `test/features/auth/presentation/pages/profile_page_test.dart`

**Checkpoint**: All authenticated users can view their profile information.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T043 [P] Add rate limiting middleware to login endpoint in `server/src/app.js` — 5 attempts per 15 min per IP + per account using express-rate-limit
- [x] T044 [P] Add seed script: `server/scripts/seed.js` — creates initial superadmin (`admin@example.com` / `Admin@123`) with all permissions
- [x] T045 Add `server/package.json` scripts: `"dev": "node src/app.js"`, `"seed": "node scripts/seed.js"`, `"test": "jest --coverage"`
- [x] T046 Run `quickstart.md` validation scenarios end-to-end

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - US1 (Phase 3) and US2 (Phase 4) can proceed in parallel once Foundational is complete
  - US3 (Phase 5) depends on US1 (needs AuthBloc for authenticated state)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational — No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational — independently testable (uses its own UserManagementBloc)
- **User Story 3 (P3)**: Depends on US1 (AuthBloc for authentication state)

### Within Each User Story

- Models before services
- Services before endpoints/UI
- Implementation before tests
- Story complete before moving to next priority

### Parallel Opportunities

- All Phase 1 Setup tasks marked [P] can run in parallel
- All Phase 2 Foundational tasks marked [P] can run in parallel
- Once Foundational done: US1 (Phase 3) and US2 (Phase 4) can proceed in parallel
- Within US1: backend (T012-T015) and frontend (T016-T026) can run in parallel
- Within US2: backend (T031-T033) and frontend (T034-T037) can run in parallel
- All test tasks marked [P] can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch backend and frontend for US1 in parallel:
# Backend:
Task: "Implement AuthService in server/src/services/authService.js"
Task: "Implement AuthController in server/src/controllers/authController.js"
Task: "Implement auth routes in server/src/routes/auth.js"

# Frontend:
Task: "Create UserModel + TokenResponseModel in lib/features/auth/data/models/"
Task: "Create AuthRemoteDataSource in lib/features/auth/data/datasources/"
Task: "Create AuthRepository interface + impl in lib/features/auth/"
Task: "Create LoginUseCase in lib/features/auth/domain/usecases/"
Task: "Create AuthBloc in lib/features/auth/presentation/bloc/"
Task: "Create LoginPage + LoginForm in lib/features/auth/presentation/"
Task: "Create AuthInterceptor in lib/core/network/"
Task: "Create AuthGuard in lib/core/router/"
Task: "Create AppRouter in lib/core/router/"
Task: "Wire up main.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1 (login, token refresh, permission navigation)
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy (MVP!)
3. Add User Story 2 → Test independently → Deploy (admins can manage users)
4. Add User Story 3 → Test independently → Deploy (user self-service profile)

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A (Frontend): US1 frontend (T016-T026)
   - Developer B (Backend): US1 backend (T012-T015)
   - Developer C (Backend): US2 backend (T031-T033)
3. After US1 frontend + backend done → Developer A picks up US2 frontend (T034-T037)
4. US3 (T040-T042) is low priority, handled by any available developer after US1+US2

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Write tests first (fail) then implement (red-green)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
