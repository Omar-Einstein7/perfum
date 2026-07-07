# Research: Units of Measure

## Overview

No open questions or NEEDS CLARIFICATION markers remain in the spec. All technical decisions follow established patterns from the Auth module.

## Decisions

### Architecture Pattern
- **Decision**: Clean Architecture (data/domain/presentation) per existing Auth module
- **Rationale**: Proven pattern; ensures consistency across modules; domain layer remains pure Dart
- **Alternatives considered**: None (mandated by constitution)

### State Management
- **Decision**: Cubit (flutter_bloc) — same as Auth's SessionBloc pattern
- **Rationale**: Simpler than full Bloc for standard CRUD; fewer boilerplate events; consistent with existing UnitCubit
- **Alternatives considered**: Bloc with separate events (overkill for CRUD)

### Data Source
- **Decision**: UnitRemoteDataSource wrapping DioService — same pattern as AuthRemoteDataSource
- **Rationale**: Consistent Dio injection via get_it; reuses existing error handling
- **Alternatives considered**: Direct Dio calls in repository (violates SRP)

### Soft-Delete
- **Decision**: `active` boolean field on Unit entity; deactivate sets `active=false`
- **Rationale**: Preserves referential integrity with Materials; supports reactivation if needed; matches backend contract
- **Alternatives considered**: Hard-delete (loses data), archive status (over-engineered for v1)

### Unit Type
- **Decision**: Fixed enum with 7 values (weight, volume, count, length, area, time, other)
- **Rationale**: Types are stable; enum prevents invalid values; easy to extend later if needed
- **Alternatives considered**: Reference table (over-engineered for v1)

### Pagination
- **Decision**: Backend-driven pagination via query params `?page=1&limit=20`; frontend sends `search` param for filtering
- **Rationale**: Standard REST pagination; matches expected backend contract; keeps list response size predictable
- **Alternatives considered**: Client-side pagination (untenable with backend search)

### Permission Guard
- **Decision**: Reuse existing `app_router.dart` redirectGuard — add unit routes under `canEditMasters` check
- **Rationale**: Already implemented; no new permission logic needed
- **Alternatives considered**: Per-page guard in Cubit (duplicates router logic)
