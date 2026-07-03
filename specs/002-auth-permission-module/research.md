# Research: Auth & Permission Module

**Phase**: 0 — Outline & Research | **Date**: 2026-07-03

## Overview

All technical decisions were provided by the user. No NEEDS CLARIFICATION markers remain from the spec or plan. This document consolidates the chosen approaches, rationale, and alternatives considered.

---

## Frontend Architecture

### State Management: flutter_bloc

| Decision | flutter_bloc (Bloc pattern) |
|----------|---------------------------|
| Rationale | Already a project dependency (`flutter_bloc: ^9.1.1`), aligns with existing state management choices in the project. Login flow uses AuthBloc with typed events and freezed sealed states. Session lifecycle managed by SessionBloc. |
| Alternatives | Cubit (simpler but less suitable for multi-step login flow with branching logic); Provider (no event-driven debugging); Riverpod (not in project). |

### Dependency Injection: get_it

| Decision | get_it with scope-based registration |
|----------|--------------------------------------|
| Rationale | get-it-expert skill recommends registerSingleton/lazySingleton for datasources & repositories, factory for use cases & blocs. Registration order: datasource → repository → usecases → blocs. All wiring lives in `core/di/injection_container.dart`. |
| Alternatives | Manual singleton pattern (current approach — does not support scopes, harder to test); Injectable (code generation, adds complexity). |

### Networking: dio + JWT Interceptor

| Decision | Custom dio interceptor that reads JWT from secure storage and attaches `Authorization: Bearer <token>` header |
|----------|--------------------------------------------------------------------------------------------------------------|
| Rationale | dio already in project (`dio: ^5.9.2`) with existing `DioService`. JWT interceptor wraps existing setup, forwarding 401 responses to trigger session expiry. |
| Alternatives | http package (no interceptor support); graphql (not needed). |

### Routing: go_router + Redirect Guard

| Decision | go_router `redirect` callback reads AuthCubit state and permission flags, redirects to `/login` if unauthenticated or `/403` if unauthorized |
|----------|---------------------------------------------------------------------------------------------------------------------------------------------|
| Rationale | go_router already in project (`go_router: ^17.1.0`). Route-permission mapping follows the constitution. |
| Alternatives | Imperative Navigator.push (no redirect guards). |

### Sealed States: freezed

| Decision | freezed for AuthBloc, SessionBloc, UserManagementBloc sealed states |
|----------|---------------------------------------------------------------------|
| Rationale | Constitution mandates sealed union states: `Initial / Loading / Loaded(data) / Error(failure)`. freezed is the standard approach. |
| Alternatives | Manual sealed classes (more boilerplate). |

---

## Backend Architecture

### Auth Strategy: JWT + bcrypt

| Decision | JWT access tokens (24h expiry, configurable) with bcrypt password hashing |
|----------|--------------------------------------------------------------------------|
| Rationale | Industry standard. bcrypt provides adaptive salt + cost factor. JWT allows stateless session validation. Server-side blocklist for explicit logout. |
| Alternatives | Session cookies (stateful, needs Redis); OAuth2 (overkill for internal POS). |

### Permission Enforcement: Express Middleware

| Decision | Per-route middleware that decodes JWT, loads user permissions, and checks against required flag for the route |
|----------|-------------------------------------------------------------------------------------------------------------|
| Rationale | Keeps permission logic centralized and testable. Middleware map: route pattern → required permission flag. |
| Alternatives | Inline checks in each route handler (duplication risk); decorator pattern (not native to JS). |

### Data Storage: MongoDB + Mongoose

| Decision | Mongoose schema with embedded permissions object and role field |
|----------|---------------------------------------------------------------|
| Rationale | Matches existing backend conventions. Permissions stored as embedded object matching the Access legacy flags 1:1. |
| Alternatives | PostgreSQL (not in project); flat permission collection (over-normalized for 7 booleans). |

---

## Testing Strategy

| Decision | flutter_test + mocktail + bloc_test (client), Jest + supertest (server) |
|----------|-------------------------------------------------------------------------|
| Rationale | Existing test scaffold at `test/features/auth/` defines expected interfaces. New code must satisfy these tests. mocktail for mockito-style mocks without code generation. |
| Coverage | Every UseCase and every Bloc must have at least one test (constitution mandate). |
