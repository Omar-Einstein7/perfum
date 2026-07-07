---
description: "Task list for Phase 1 — Auth Module"
---

# Tasks: Auth Module

**Input**: Design documents from `specs/002-auth-module/`

**Prerequisites**: plan.md ✅ | spec.md ✅ | constitution.md ✅

**Tests**: Included per constitution requirement (every UseCase and Cubit MUST have at least one test).

**Organization**: Tasks are grouped by user story to enable independent implementation
and testing of each story.

**LLM note**: Every task below is self-contained. Each task tells you EXACTLY which
file to touch, what to add/change, and what the result must look like. Do NOT jump
ahead. Complete tasks in order within each phase.

---

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no shared state)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, US5)
- Exact file paths are included in every task description

---

## Phase 1: Setup

**Purpose**: Project is already initialized. No setup tasks needed.

No tasks — Flutter project exists, dependencies are installed, build_runner is configured.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented.

**⚠️ CRITICAL**: Do not start Phase 3, 4, 5, 6, or 7 until this phase is 100% complete.

- [x] T001 [P] Create `AuthRemoteDataSource` abstract interface in `lib/src/features/auth/data/datasources/auth_remote_datasource.dart` with methods: `login({required String email, required String password})` returning `FutureEither<Map<String, dynamic>>`, `signUp({required String name, required String email, required String password})` returning `FutureEither<Map<String, dynamic>>`, `forgotPassword({required String email})` returning `FutureEither<void>`, `checkAuthState()` returning `FutureEither<Map<String, dynamic>?>`, `logout()` returning `FutureEither<void>`

- [x] T002 [P] Implement `AuthRemoteDataSourceImpl` in `lib/src/features/auth/data/datasources/auth_remote_datasource_impl.dart` — inject `DioService` via constructor (from `sl()`), implement each method by calling the appropriate `DioService` endpoints (`POST /auth/login`, `POST /auth/register`, `POST /auth/forgot-password`, `GET /auth/me`, `POST /auth/logout`), extract response data maps from the Dio `Response`

- [x] T003 [P] Rewrite `lib/src/features/auth/data/models/user_model.dart` — switch to `@freezed` with `fromJson`/`toJson`, add `permissions` field with `@Default(0)`, rename class from `AppUser` to `UserModel` (avoid name collision with domain `AppUser`), add `toEntity()` method that maps `UserModel → AppUser`

- [x] T004 Run `dart run build_runner build --delete-conflicting-outputs` to generate freezed/json_serializable code for the new UserModel

- [x] T005 [P] Create `LoginUseCase` in `lib/src/features/auth/domain/usecases/login_usecase.dart` — single `call({required String email, required String password})` returning `FutureEither<AppUser>`, implements the abstract `UseCase` pattern, injects `AuthRepository` via constructor

- [x] T006 [P] Create `CheckSessionUseCase` in `lib/src/features/auth/domain/usecases/check_session_usecase.dart` — single `call()` returning `FutureEither<AppUser?>`, injects `AuthRepository` via constructor

- [x] T007 [P] Create `LogoutUseCase` in `lib/src/features/auth/domain/usecases/logout_usecase.dart` — single `call()` returning `FutureEither<void>`, injects `AuthRepository` via constructor

- [x] T008 [P] Create `SignUpUseCase` in `lib/src/features/auth/domain/usecases/sign_up_usecase.dart` — single `call({required String name, required String email, required String password})` returning `FutureEither<AppUser>`, injects `AuthRepository` via constructor

- [x] T009 [P] Create `ForgotPasswordUseCase` in `lib/src/features/auth/domain/usecases/forgot_password_usecase.dart` — single `call({required String email})` returning `FutureEither<void>`, injects `AuthRepository` via constructor

- [x] T010 Update `lib/src/services/service_locator.dart` — register `AuthRemoteDataSourceImpl` as `AuthRemoteDataSource` (lazySingleton), register all 5 use-cases (lazySingleton), update `AuthRepositoryImpl` registration to inject `AuthRemoteDataSource`

- [x] T011 Refactor `lib/src/features/auth/data/repositories/auth_repository_impl.dart` — inject `AuthRemoteDataSource` (not `AuthService.instance`), use `UserModel.fromJson()` for response parsing and `toEntity()` for domain mapping, keep JWT token persistence via `SecureStorageService` (injected via `sl()`, not `.instance`)

- [x] T012 Run `flutter analyze lib/` — fix ALL errors before continuing. Expected: zero issues.

**Checkpoint Phase 2**: `flutter analyze` reports zero errors. All use-cases compile. DI registrations resolve.

---

## Phase 3: User Story 1 — Login with Email & Password (Priority: P1) 🎯 MVP

**Goal**: A registered user can log in with email + password and reach the dashboard. Invalid credentials show a clear error message on the login page.

**Independent Test**: Open the app with no stored session → fill in valid email + password → tap Login → land on dashboard. Enter invalid credentials → see error message on login page, no navigation.

### Tests for User Story 1

> Tests should be written first and verified to fail before implementation.

- [x] T013 [P] [US1] Write `test/src/features/auth/domain/usecases/login_usecase_test.dart` — mock AuthRepository, verify `call()` returns `Right<AppUser>` on success and `Left<Failure>` on failure, verify repository.login is called with correct args

- [x] T014 [P] [US1] Write `test/src/features/auth/domain/usecases/check_session_usecase_test.dart` — mock AuthRepository, verify `call()` returns `Right<AppUser>` when token is valid and `Right(null)` when no token exists

- [x] T015 [P] [US1] Write `test/src/features/auth/data/datasources/auth_remote_datasource_test.dart` — mock DioService using mocktail, verify `login()` returns response data map on success, verify `login()` throws on DioException, verify `checkAuthState()` returns null on 401

### Implementation for User Story 1

- [x] T016 [US1] Refactor `lib/src/features/auth/presentation/providers/auth_bloc.dart` — remove `BuildContext` from all event classes; define navigation-request states (`NavigateToDashboard`, `NavigateToLogin`) instead of calling `context.go()` inside the bloc; inject `LoginUseCase` and use it in the login event handler; inject `CheckSessionUseCase` if needed; keep `SignUpUseCase` and `ForgotPasswordUseCase` injections for later phases

- [x] T017 [P] [US1] Refactor `lib/src/features/auth/presentation/providers/session_bloc.dart` — inject `CheckSessionUseCase` and `LogoutUseCase` instead of calling repository directly; keep existing state emission pattern (unknown → authenticated/unauthenticated); ensure `signalUnauthenticated()` flow works via the use-case

- [x] T018 [P] [US1] Write `test/src/features/auth/presentation/providers/bloc/auth_bloc_test.dart` — test login success emits loading then navigate-to-dashboard state, test login failure emits loading then error state

- [x] T019 [P] [US1] Write `test/src/features/auth/presentation/providers/bloc/session_bloc_test.dart` — test session check on startup emits authenticated when token valid, test session check emits unauthenticated when no token, test logout emits unauthenticated

**Checkpoint US1**: Login works end-to-end. Invalid credentials show error. Session check runs on startup. All US1 tests pass.

---

## Phase 4: User Story 2 — Session Persistence Across Restarts (Priority: P1)

**Goal**: A logged-in user can close and reopen the app (or hot-restart) and land on the dashboard without re-entering credentials.

**Independent Test**: Log in → hot-restart the app (`R` in terminal) → land on dashboard (not login). Clear browser storage → restart → land on login page.

**Note**: This story reuses `CheckSessionUseCase` from US1. No new use-cases needed.

### Implementation for User Story 2

- [x] T020 [P] [US2] Write `test/src/features/auth/domain/usecases/logout_usecase_test.dart` — mock AuthRepository, verify `call()` calls repository.logout() and returns `Right(void)` on success

- [x] T021 [US2] Verify `lib/src/shared/wrappers/session_listener_wrapper.dart` listens to `SessionBloc` and navigates to login when `unauthenticated` state is emitted — ensure import paths are correct and the `context.go(AppRoutes.login)` call works

- [x] T022 [P] [US2] Write `test/src/features/auth/presentation/providers/bloc/session_bloc_test.dart` — add test for session persistence: mock `CheckSessionUseCase` to return a valid user, verify bloc emits `authenticated` state

**Checkpoint US2**: Session survives hot-restart. Expired/malformed token → login page.

---

## Phase 5: User Story 3 — Automatic Logout on Session Expiry (Priority: P2)

**Goal**: When the backend returns a 401 response on any API call, the app automatically logs out, clears the token, and navigates to the login page — without crashing or showing an error screen.

**Independent Test**: Log in → use browser DevTools to force a 401 on the next API response → app navigates to `/login` within 2 seconds, token cleared from storage.

**Note**: This story relies on the JWT interceptor already built in Phase 0 (T008 in infra-hardening). Verification tasks only.

### Implementation for User Story 3

- [x] T023 [US3] Verify `lib/src/config/app_config.dart` — confirm the JWT interceptor's `onError` correctly checks `statusCode == 401`, calls `SecureStorageService.instance.deleteAll()`, and calls `AuthService.instance.signalUnauthenticated()`. Fix any issues found.

- [x] T024 [US3] Verify `lib/src/features/auth/presentation/providers/session_bloc.dart` — confirm that when `signalUnauthenticated()` fires (emits null to auth stream), the bloc's subscription handler emits `unauthenticated` state and triggers navigation to login via `SessionListenerWrapper`. Fix any issues found.

- [x] T025 [US3] Write integration-style test using mocked Dio: simulate a 401 response on an API call, verify that `signalUnauthenticated()` is called and that `SessionBloc` transitions to `unauthenticated`

**Checkpoint US3**: 401 response → login page within 2 seconds. No crash, no error screen.

---

## Phase 6: User Story 4 — Account Registration (Priority: P3)

**Goal**: A new user can create an account with name, email, and password, and be automatically logged in upon successful registration.

**Independent Test**: Navigate to `/signup` → fill in name, email, password → submit → land on dashboard as a logged-in user. Try registering with an already-used email → see error message.

### Tests for User Story 4

- [x] T026 [P] [US4] Write `test/src/features/auth/domain/usecases/sign_up_usecase_test.dart` — mock AuthRepository, verify `call()` returns `Right<AppUser>` on success and `Left<Failure>` on duplicate-email failure

### Implementation for User Story 4

- [x] T027 [US4] Add `static const String signUp = '/signup';` to `lib/src/routing/app_routes.dart` — add after `login` constant

- [x] T028 [US4] Add `/signup` route to `lib/src/routing/app_router.dart` — add `GoRoute(path: AppRoutes.signUp, name: 'signUp', builder: (c, s) => const SignupScreen())` inside the routes list; add to the public routes list so it redirects authenticated users

- [x] T029 [US4] Update `lib/src/features/auth/presentation/screens/login_screen.dart` — find the stubbed-out sign-up navigation (marked "out of scope for Phase 0") and wire it to `context.go(AppRoutes.signUp)`

- [x] T030 [US4] Wire `SignUpUseCase` into `AuthBloc` — handle the signUp event by calling the use-case, on success emit `NavigateToDashboard`, on failure emit error state

- [x] T031 [P] [US4] Add signup tests to `test/src/features/auth/presentation/providers/bloc/auth_bloc_test.dart` — test sign-up success emits loading then navigate-to-dashboard, test duplicate-email failure emits loading then error

**Checkpoint US4**: Registration works end-to-end. Duplicate email shows error. Signup route is reachable from login page.

---

## Phase 7: User Story 5 — Password Reset (Priority: P4)

**Goal**: A user who forgot their password can enter their registered email address and receive a confirmation that a reset link has been sent.

**Independent Test**: Navigate to `/forgot-password` → enter a registered email → see a confirmation message. The screen shows the same message for unregistered emails (no email enumeration).

### Tests for User Story 5

- [x] T032 [P] [US5] Write `test/src/features/auth/domain/usecases/forgot_password_usecase_test.dart` — mock AuthRepository, verify `call()` returns `Right(void)` on success and `Left<Failure>` on network error

### Implementation for User Story 5

- [x] T033 [US5] Wire `ForgotPasswordUseCase` into `AuthBloc` — handle the forgotPassword event by calling the use-case, on success emit a confirmation state (e.g., `PasswordResetEmailSent`), on failure emit error state

- [x] T034 [P] [US5] Update `test/src/features/auth/presentation/providers/bloc/auth_bloc_test.dart` — add forgot-password success and failure tests

**Checkpoint US5**: Forgot-password flow works. Same message for registered and unregistered emails.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup, analysis pass, quality gates.

- [x] T035 Run `dart run build_runner build --delete-conflicting-outputs` — regenerate any stale freezed/json_serializable files

- [x] T036 Run `flutter analyze lib/` — fix ALL errors and warnings. Project MUST pass analysis cleanly.

- [x] T037 Run `flutter test test/src/features/auth/` — all tests MUST pass. Add any missing test imports or mocks.

- [x] T038 Verify constitution quality gates:
  - [x] `lib/src/features/auth/domain/` has zero imports of `package:flutter`, `package:dio`, or `package:json_annotation`
  - [x] All RepositoryImpl classes return `Either<Failure, T>` (fpdart)
  - [x] All auth routes guarded by permission redirect or in public routes list
  - [x] `app_router.dart` reads `sl<SessionBloc>()` — no `context.read<SessionBloc>()`
  - [x] No raw `'jwt_token'` strings outside `service_locator.dart` (use `kJwtTokenKey`)
  - [x] `user_model.dart` uses `@freezed` with `fromJson`/`toJson`

- [x] T039 Update `PLAN.md` (project root) Section 7 — change Auth status from `Not started` to `Phase 1 ✅ Done`:
  ```markdown
  | Auth | Phase 1 ✅ Done — login, registration, session persistence, auto-logout |
  ```

- [x] T040 Run quickstart.md Scenarios 1–7 in order. All must pass. Phase 1 complete.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — already satisfied.
- **Phase 2 (Foundational)**: Depends on nothing. BLOCKS all user stories.
- **Phase 3 (US1 — Login P1)**: Depends on Phase 2. MVP story.
- **Phase 4 (US2 — Session Persistence P1)**: Depends on Phase 2. Reuses CheckSessionUseCase from US1.
- **Phase 5 (US3 — Auto-Logout P2)**: Depends on Phase 2. Verification-only (relies on Phase 0 interceptor).
- **Phase 6 (US4 — Registration P3)**: Depends on Phase 2. Independent of US1–US3.
- **Phase 7 (US5 — Password Reset P4)**: Depends on Phase 2. Independent of US1–US4.
- **Phase 8 (Polish)**: Depends on Phases 3–7 all complete.

### User Story Dependencies

- **US1 (P1)**: Can start after Phase 2. No dependency on other stories.
- **US2 (P1)**: Can start after Phase 2. Shares CheckSessionUseCase with US1.
- **US3 (P2)**: Can start after Phase 2. Independent of US1/US2/US4/US5.
- **US4 (P3)**: Can start after Phase 2. Independent of all other stories.
- **US5 (P4)**: Can start after Phase 2. Independent of all other stories.

### Within Each Phase

- Tasks marked `[P]` in the same phase can be done in any order (different files).
- Tasks WITHOUT `[P]` must be done in the listed order (same file or sequential dependency).
- Never start a task if the previous non-parallel task in the same file is incomplete.

### Parallel Opportunities

```
Phase 2: T001, T002, T003, T005, T006, T007, T008, T009 — all parallel
Phase 3: T013, T014, T015, T017, T018, T019 — parallel
Phase 4: T020, T022 — parallel
Phase 6: T026 — parallel with T027, T028, T029
Phase 7: T032 — parallel with T033
```

---

## Parallel Example: User Story 1

```bash
# Launch all test tasks for US1 together:
Task: "T013 LoginUseCase test in test/src/features/auth/domain/usecases/login_usecase_test.dart"
Task: "T014 CheckSessionUseCase test in test/src/features/auth/domain/usecases/check_session_usecase_test.dart"
Task: "T015 AuthRemoteDataSource test in test/src/features/auth/data/datasources/auth_remote_datasource_test.dart"
Task: "T018 AuthBloc test in test/src/features/auth/presentation/providers/bloc/auth_bloc_test.dart"
Task: "T019 SessionBloc test in test/src/features/auth/presentation/providers/bloc/session_bloc_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 2: Foundational (T001–T012)
2. Complete Phase 3: US1 — Login (T013–T019)
3. **STOP and VALIDATE**: Run US1 independent test (login flow works end-to-end)
4. Deploy/demo if ready

### Incremental Delivery

1. Phase 2 done → Foundation ready (use-cases, data source, model, DI)
2. Add US1 (Login) → Test independently → Deploy (MVP!)
3. Add US2 (Session Persistence) → Test independently → Deploy
4. Add US3 (Auto-Logout) → Test independently → Deploy
5. Add US4 (Registration) → Test independently → Deploy
6. Add US5 (Password Reset) → Test independently → Deploy
7. Phase 8 (Polish) → All quickstart scenarios green ✅

### Common Mistakes to Avoid

1. **Do NOT** use `context.go()` inside the bloc — emit navigation state and let the UI layer handle routing.
2. **Do NOT** register `AuthRepositoryImpl` directly — register as `AuthRepository` (interface).
3. **Do NOT** use `AuthService.instance` or `SecureStorageService.instance` — always inject via `sl()`.
4. **Do NOT** forget `build_runner` after editing `@freezed` models.
5. **Do NOT** skip `flutter analyze` between phases — errors compound.

---

## Notes

- `[P]` tasks = different files, no blocking dependencies
- `[US1]`–`[US5]` labels map tasks to their user story for traceability
- Each user story checkpoint is independently testable
- Tests should be written before implementation (TDD recommended but not enforced)
- The existing `SignupScreen` already exists — only routing and bloc wiring are needed
- The existing `ForgotPasswordScreen` already exists — only bloc wiring is needed
- Phase 3 (US1) is the MVP — stop and validate before continuing
