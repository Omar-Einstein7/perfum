# Implementation Plan: User Authentication & RBAC

**Branch**: `001-user-auth-rbac` | **Date**: 2026-07-03 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-user-auth-rbac/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Implement email/password authentication with JWT (access + refresh token) for a Flutter Web frontend and Node/Express + MongoDB backend. Supports role-based access control with superadmin/admin/staff roles and 7 boolean permission flags. Superadmin manages user accounts; navigation and API routes are gated by permissions.

## Technical Context

**Language/Version**: Dart 3.x (Flutter Web), Node.js 18+ (Express backend)

**Primary Dependencies**:
- Frontend: `flutter_bloc`, `get_it`, `dio`, `go_router`, `freezed` + `json_serializable`, `equatable`
- Backend: `express`, `mongoose`, `bcryptjs`, `jsonwebtoken`, `express-rate-limit`

**Storage**: MongoDB via Mongoose (users collection)

**Testing**:
- Frontend: `flutter_test`, `bloc_test`, `mocktail`
- Backend: `jest`, `supertest`

**Target Platform**: Web (Flutter Web) + Node.js API server

**Project Type**: Web application (frontend + backend)

**Performance Goals**: Login flow <5s end-to-end; token validation <200ms per request; user list load <2s

**Constraints**: Access token 15min expiry; refresh token 7 days with rotation; rate-limit 5 attempts per 15min per account

**Scale/Scope**: Internal business system, <500 user accounts, single-server deployment

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Gate 1: Clean Architecture (presentation -> domain <- data)
- **Status**: PASS
- **Rationale**: Auth feature will be structured as:
  - `presentation/` — LoginPage, AuthCubit/Bloc, widgets
  - `domain/` — AuthRepository interface, LoginUseCase, entities (User, Session)
  - `data/` — AuthRepositoryImpl, AuthRemoteDataSource (Dio), models with fromJson/toJson
- Domain layer has zero Flutter or Dio imports. Pure Dart + equatable.

### Gate 2: State Management Discipline (Bloc for auth flow)
- **Status**: PASS
- **Rationale**: Login is a multi-step sequenced flow (SubmitCredentials -> TokenReceived/Error). Bloc with typed events (`LoginSubmitted`, `RefreshTokenExpired`) is appropriate per constitution guidance. State is sealed union via freezed: `Initial / Loading / Authenticated(user) / Unauthenticated / Error(failure)`.

### Gate 3: Dependency Injection (GetIt)
- **Status**: PASS
- **Rationale**: Registration order: AuthRemoteDataSource (lazySingleton) -> AuthRepository (lazySingleton) -> LoginUseCase (factory) -> AuthBloc (factory). All wired in `core/di/injection_container.dart`.

### Gate 4: Networking & Data Contract
- **Status**: PASS
- **Rationale**: Dio interceptor attaches `Authorization: Bearer <access_token>` header. Token refresh handled transparently via interceptor (retry with new token on 401). Backend uses REST envelope `{ success, data, message }`. Dates as ISO-8601. ID fields as String (MongoDB ObjectId hex).

### Gate 5: Test Discipline
- **Status**: PASS
- **Rationale**: 
  - Domain: pure unit tests for LoginUseCase (mock AuthRepository interface)
  - Data: mocktail for Dio mocks; verify JSON mapping in both directions
  - Presentation: bloc_test for AuthBloc covering Initial -> Loading -> Authenticated and Initial -> Loading -> Error transitions

### Gate 6: Routing & Access Control (RBAC)
- **Status**: PASS
- **Rationale**: go_router redirect guard reads AuthBloc state and checks user permissions. Route-permission mapping per constitution:
  - `/materials`, `/categories`, `/units` → `p_info`
  - `/suppliers`, `/purchase-invoices` → `p_res`
  - `/customers`, `/sales-invoices` → `p_sell`
  - `/vouchers/*` → `p_snadat`
  - `/users` → `p_user`
  - `/reports/*` → `p_report`, `p_report2`

**Conclusion**: All gates pass. No violations requiring deviation justification.

## Project Structure

### Documentation (this feature)

```text
specs/001-user-auth-rbac/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── di/
│   │   └── injection_container.dart
│   ├── network/
│   │   ├── dio_client.dart
│   │   └── auth_interceptor.dart
│   └── router/
│       ├── app_router.dart
│       └── auth_guard.dart
├── features/
│   └── auth/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── auth_remote_data_source.dart
│       │   ├── models/
│       │   │   ├── user_model.dart
│       │   │   └── token_response_model.dart
│       │   └── repositories/
│       │       └── auth_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── user.dart
│       │   │   └── session.dart
│       │   ├── repositories/
│       │   │   └── auth_repository.dart
│       │   └── usecases/
│       │       └── login_usecase.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── auth_bloc.dart
│           │   ├── auth_event.dart
│           │   └── auth_state.dart
│           ├── pages/
│           │   ├── login_page.dart
│           │   └── profile_page.dart
│           └── widgets/
│               ├── login_form.dart
│               └── permission_guard.dart
└── main.dart

server/
├── src/
│   ├── config/
│   │   └── db.js
│   ├── middleware/
│   │   ├── auth.js
│   │   └── permission.js
│   ├── models/
│   │   └── User.js
│   ├── routes/
│   │   └── auth.js
│   ├── controllers/
│   │   └── authController.js
│   ├── services/
│   │   └── authService.js
│   └── app.js
└── tests/
    ├── auth.test.js
    └── permission.test.js
```

**Structure Decision**: Option 2 — Web application with separate `lib/` (Flutter frontend) and `server/` (Node.js backend) directories, following Clean Architecture within `lib/features/auth/`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations detected. Complexity tracking is N/A.
