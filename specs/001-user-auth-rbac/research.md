# Research: User Authentication & RBAC

**Date**: 2026-07-03 | **Phase**: 0 — Research & Unknown Resolution

## Overview

All technology choices were explicitly provided by the user and confirmed against the project constitution. No unresolved unknowns remain.

## Decisions

### 1. Password Hashing Algorithm

- **Decision**: bcrypt with 10 salt rounds
- **Rationale**: Industry standard for password hashing; concurrency-safe for <500 users; built-in salt generation. Aligns with user-provided stack (bcryptjs).
- **Alternatives considered**: argon2 (stronger but higher compute cost), scrypt (memory-hard but less ecosystem support in Node.js)

### 2. Token Refresh Strategy

- **Decision**: Refresh token rotation with reuse detection
- **Rationale**: If a stolen refresh token is used after the legitimate user already rotated it, both tokens are invalidated immediately, limiting the theft window.
- **Alternatives considered**: Static refresh token (simpler but vulnerable to theft), sliding session (simpler but no reuse detection)

### 3. Rate-Limiting Approach

- **Decision**: express-rate-limit middleware on `/api/auth/login` — 5 attempts per 15 min per IP + per account
- **Rationale**: Prevents brute-force at both network and user-account level. express-rate-limit is the standard middleware for Express.
- **Alternatives considered**: Single IP-only limiting (bypasses distributed attacks), account-only limiting (doesn't prevent IP-level DDoS)

### 4. State Management for Auth Flow

- **Decision**: Bloc (not Cubit) with typed events
- **Rationale**: Login involves sequenced events (submit, token refresh, logout, session expiry) making it a multi-step flow — Bloc with typed events is constitution-mandated for this pattern.
- **Alternatives considered**: Cubit (too simple for sequenced flows), Riverpod (not in constitution-approved stack)

### 5. Token Storage on Client

- **Decision**: In-memory (AuthBloc state) + refresh token in localStorage
- **Rationale**: Access token in memory prevents XSS exfiltration; refresh token in localStorage survives page reload. Constitution's Dio interceptor handles automatic refresh.
- **Alternatives considered**: httpOnly cookies (not available in Flutter Web without additional infrastructure), flutter_secure_storage (overkill for internal web app)

## Best Practices Confirmed

| Area | Practice |
|------|----------|
| JWT | 15min access + 7d refresh with rotation; no sensitive data in payload |
| Password | bcrypt, min 8 chars, mixed case + digits |
| API contract | Uniform envelope `{ success, data, message }` per constitution |
| Error handling | Frontend: ServerFailure/NetworkFailure hierarchy; Backend: try/catch + structured error response |
| DI | GetIt lazySingleton for datasource/repo, factory for usecases/blocs |
