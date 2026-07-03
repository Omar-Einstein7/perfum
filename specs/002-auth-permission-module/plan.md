# Implementation Plan: Auth & Permission Module

**Branch**: `002-auth-permission-module` | **Date**: 2026-07-03 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-auth-permission-module/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Implement authentication (email/password login, JWT sessions) and permission-based access control (3 roles, 7 boolean permission flags) for a Flutter Web + Node/Express inventory POS system. Users log in via a Bloc-driven login flow, receive a JWT, and navigate through go_router routes gated by their assigned permissions (p_info, p_res, p_sell, p_snadat, p_user, p_report, p_report2). Superadmins can create, edit, deactivate/reactivate, and delete users. All user management actions are audit-logged. The backend enforces per-route permission checks via Express middleware.

## Technical Context

**Language/Version**: Dart 3.x (Flutter Web), Node.js + Express (server/)

**Primary Dependencies**: flutter_bloc (login flow + auth state), get_it (DI container), dio + dio interceptor (JWT bearer header), go_router + redirect guard (route gating by permissions), equatable, fpdart, freezed (sealed states). Server: mongoose, bcryptjs, jsonwebtoken.

**Storage**: MongoDB (Mongoose) via server/ backend. Client-side: flutter_secure_storage for JWT, shared_preferences for non-sensitive config.

**Testing**: flutter_test + mocktail + bloc_test (unit/bloc tests on client), Jest + supertest (integration on server). Existing test scaffold at test/features/auth/.

**Target Platform**: Flutter Web (Chrome, Edge), Node.js server (any OS).

**Project Type**: Web application (Flutter frontend + Node/Express backend)

**Performance Goals**: Login under 3s (SC-001), 403 redirect under 1s (SC-004), user CRUD under 30s (SC-005).

**Constraints**: Clean Architecture (presentation → domain ← data), one-way dependency, entities must be pure Dart with zero Flutter/Dio imports, freezed for sealed states, get_it for DI (factory for blocs, lazySingleton for services), all entity ids are String (MongoDB ObjectId).

**Scale/Scope**: Single-business inventory/POS system, dozens of users, ~10 screens.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Gate 1: Clean Architecture Compliance
- **Requirement**: `presentation → domain ← data` with one-way dependencies
- **Assessment**: Auth module will follow existing test expectations at `test/features/auth/` — domain entities in `domain/`, repository interface in `domain/repositories/`, data layer in `data/`. ✅ PASS

### Gate 2: State Management — Bloc with freezed sealed states
- **Requirement**: AuthBloc + SessionBloc with typed events and sealed union states (freezed)
- **Assessment**: Login flow uses AuthBloc; SessionBloc manages auth lifecycle. Both use freezed. ✅ PASS

### Gate 3: Dependency Injection — get_it
- **Requirement**: get_it with `lazySingleton` for data sources & repositories, `factory` for use cases & blocs
- **Assessment**: This feature introduces get_it to the project, replacing manual singleton pattern. Registration order: datasource → repository → usecases → blocs. ✅ PASS

### Gate 4: Networking & Data Contract
- **Requirement**: Dio with JWT interceptor, REST envelope `{ success, data, message }`, String ids (ObjectId hex)
- **Assessment**: Auth module adds JWT interceptor to existing Dio setup. Backend middleware validates tokens per route. ✅ PASS

### Gate 5: Test Discipline
- **Requirement**: Every UseCase and every Bloc must have at least one test
- **Assessment**: Existing test files at `test/features/auth/` cover LoginUseCase, AuthBloc, UserManagementBloc, and AuthRemoteDataSource. New code must satisfy these tests. ✅ PASS

## Project Structure

### Documentation (this feature)

```text
specs/002-auth-permission-module/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Frontend (Flutter Web) - existing + new auth module
lib/
├── features/auth/              # NEW - Clean Architecture auth module
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── session.dart
│   │   │   └── user.dart
│   │   ├── repositories/
│   │   │   └── auth_repository.dart
│   │   └── usecases/
│   │       └── login_usecase.dart
│   ├── data/
│   │   ├── datasources/
│   │   │   └── auth_remote_data_source.dart
│   │   ├── models/
│   │   │   ├── token_response_model.dart
│   │   │   └── user_model.dart
│   │   └── repositories/
│   │       └── auth_repository_impl.dart
│   └── presentation/
│       ├── bloc/
│       │   ├── auth_bloc.dart
│       │   ├── auth_event.dart
│       │   ├── auth_state.dart
│       │   ├── session_bloc.dart
│       │   ├── session_event.dart
│       │   ├── session_state.dart
│       │   ├── user_management_bloc.dart
│       │   ├── user_management_event.dart
│       │   └── user_management_state.dart
│       └── pages/
│           ├── login_page.dart
│           └── profile_page.dart
├── core/
│   └── di/
│       └── injection_container.dart   # NEW - get_it registration
├── src/
│   ├── routing/
│   │   └── app_router.dart            # MODIFIED - add redirect guard
│   ├── services/
│   │   ├── auth_service.dart          # MODIFIED - use new auth bloc
│   │   └── dio_service.dart           # MODIFIED - add JWT interceptor
│   └── shared/wrappers/
│       └── session_listener_wrapper.dart  # MODIFIED - use SessionBloc

test/
├── features/auth/                    # EXISTING - tests for auth module
│   ├── data/datasources/
│   │   └── auth_remote_data_source_test.dart
│   ├── domain/usecases/
│   │   └── login_usecase_test.dart
│   └── presentation/
│       ├── bloc/
│       │   ├── auth_bloc_test.dart
│       │   └── user_management_bloc_test.dart
│       └── pages/
│           └── profile_page_test.dart

# Backend (Node/Express) - existing + new auth endpoints
server/
├── src/
│   ├── models/
│   │   └── User.js                   # NEW/MODIFIED - user schema with role + permissions
│   ├── routes/
│   │   └── auth.js                   # NEW - login, me, etc.
│   ├── middleware/
│   │   └── auth.js                   # NEW - JWT verification + permission guard
│   └── ...
└── tests/
```

**Structure Decision**: Option 2 (Web application) — Flutter frontend + Node/Express backend. Auth module follows Clean Architecture within `lib/features/auth/` matching existing test expectations. Backend adds auth-related models, routes, and middleware under `server/src/`.

## Complexity Tracking

> **No constitution violations.** All patterns are aligned with existing project conventions.

## Phase 0: Research & Unknowns

All technical decisions are provided in the user input. No NEEDS CLARIFICATION markers remain — the spec and user input cover:

- **Frontend architecture**: Flutter Web, flutter_bloc, get_it, dio + JWT interceptor, go_router redirect guard
- **Backend architecture**: Node/Express, Mongoose, bcrypt, JWT, per-route permission middleware
- **DI pattern**: get_it (new — migration from manual singletons)
- **Sealed states**: freezed for AuthBloc, SessionBloc, UserManagementBloc
- **Testing**: Existing test scaffold defines interfaces and expected behavior

See [research.md](./research.md) for consolidated findings.

## Phase 1: Design & Contracts

### Domain Design

See [data-model.md](./data-model.md) for entity definitions, field mappings, and validation rules.

### Interface Contracts

See [contracts/](./contracts/) for API endpoint definitions (request/response shapes) and the route-permission mapping table.

### Validation Guide

See [quickstart.md](./quickstart.md) for setup steps, run commands, and end-to-end validation scenarios.
