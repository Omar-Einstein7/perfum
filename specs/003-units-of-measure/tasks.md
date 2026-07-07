---
description: "Task list for Phase 2 — Units of Measure"
---

# Tasks: Units of Measure

**Input**: Design documents from `specs/003-units-of-measure/`

**Prerequisites**: plan.md ✅ | spec.md ✅ | constitution.md ✅

**Tests**: Included per constitution requirement (every use-case and Cubit MUST have at least one test).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

**LLM note**: Every task below is self-contained. Each task tells you EXACTLY which file to touch, what to add/change, and what the result must look like. Do NOT jump ahead. Complete tasks in order within each phase.

---

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no shared state)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Exact file paths are included in every task description

---

## Phase 1: Setup

**Purpose**: Project is already initialized. No setup tasks needed.

No tasks — Flutter project exists, dependencies are installed, build_runner is configured.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented.

**⚠️ CRITICAL**: Do not start Phase 3, 4, 5, or 6 until this phase is 100% complete.

- [ ] T001 [P] Create `Unit` entity in `lib/src/features/units/domain/entities/unit.dart` — add fields: `id`, `name`, `abbreviation`, `type` (as `UnitType` enum), `description` (nullable), `active` (bool, default true), `createdAt`, `updatedAt`; extend `Equatable`; add `can(permission)` method matching existing `AppUser` pattern; add `static const` permission flags for `canEditMasters`

- [ ] T002 [P] Create `UnitType` enum in `lib/src/features/units/domain/entities/unit.dart` — values: `weight`, `volume`, `count`, `length`, `area`, `time`, `other`; add `String toJson()` and `factory UnitType.fromJson(String)` methods

- [ ] T003 [P] Create `UnitRepository` abstract interface in `lib/src/features/units/domain/repositories/unit_repository.dart` — methods: `listUnits({int page, int limit, String? search})` returning `FutureEither<PaginatedResponse<Unit>>`, `getUnit(String id)` returning `FutureEither<Unit>`, `createUnit({required String name, required String abbreviation, required UnitType type, String? description})` returning `FutureEither<Unit>`, `updateUnit({required String id, String? name, String? abbreviation, UnitType? type, String? description})` returning `FutureEither<Unit>`, `deleteUnit(String id)` returning `FutureEither<void>`

- [ ] T004 [P] Create `PaginatedResponse<T>` generic class in `lib/src/features/units/domain/entities/paginated_response.dart` (domain layer) — fields: `List<T> data`, `int page`, `int limit`, `int total`, `int pages`; extend `Equatable`

- [ ] T005 [P] Create `UnitModel` in `lib/src/features/units/data/models/unit_model.dart` — use `@freezed` with `fromJson`/`toJson`; map fields: `_id` → `id`, `name`, `abbreviation`, `type` (string mapped to `UnitType` via `fromJson`/`toJson`), `description` (nullable), `active`, `createdAt`, `updatedAt`; add `toEntity()` method that maps `UnitModel → Unit`

- [ ] T006 [P] Create `UnitListResponse` in `lib/src/features/units/data/models/unit_list_response.dart` — use `@freezed` with `fromJson`/`toJson`; map `data` as `List<UnitModel>`, `pagination.page`, `pagination.limit`, `pagination.total`, `pagination.pages`; add `toEntity()` method that maps `UnitListResponse → PaginatedResponse<Unit>`

- [ ] T007 [P] Create `UnitRemoteDataSource` abstract interface in `lib/src/features/units/data/datasources/unit_remote_data_source.dart` — methods matching repository but returning raw `FutureEither` of response data maps instead of domain entities

- [ ] T008 [P] Implement `UnitRemoteDataSourceImpl` in `lib/src/features/units/data/datasources/unit_remote_data_source.dart` (same file, private class or separate) — inject `DioService` via constructor (from `sl()`), implement list/get/create/update/delete by calling appropriate Dio endpoints (`GET /units`, `GET /units/:id`, `POST /units`, `PUT /units/:id`, `DELETE /units/:id`), extract response data maps

- [ ] T009 [P] Create 5 use-case files in `lib/src/features/units/domain/usecases/`:
  - `list_units_usecase.dart` — `call({int page = 1, int limit = 20, String? search})` returning `FutureEither<PaginatedResponse<Unit>>`
  - `get_unit_usecase.dart` — `call(String id)` returning `FutureEither<Unit>`
  - `create_unit_usecase.dart` — `call({required String name, required String abbreviation, required UnitType type, String? description})` returning `FutureEither<Unit>`
  - `update_unit_usecase.dart` — `call({required String id, String? name, String? abbreviation, UnitType? type, String? description})` returning `FutureEither<Unit>`
  - `delete_unit_usecase.dart` — `call(String id)` returning `FutureEither<void>`
  Each injects `UnitRepository` via constructor, delegates to repository.

- [ ] T010 Implement `UnitRepositoryImpl` in `lib/src/features/units/data/repositories/unit_repository_impl.dart` — inject `UnitRemoteDataSource` via constructor (from `sl()`); implement each method by calling data source and mapping `UnitModel` responses to `Unit` entities via `toEntity()`

- [ ] T011 Update `lib/src/routing/app_routes.dart` — add unit route constants: `static const String units = '/units';`, `static const String unitNew = '/units/new';`, `static const String unitDetail = '/units/:id';`, `static const String unitEdit = '/units/:id/edit';`

- [ ] T012 Update `lib/src/routing/app_router.dart` — add unit `GoRoute`s in the routes list; add `units` to `_permissionForRoute` under `canEditMasters` (line 34); add `units` as a protected route in `redirectGuard`

- [ ] T013 Update `lib/src/services/service_locator.dart` — register `UnitRemoteDataSourceImpl` as `UnitRemoteDataSource` (lazySingleton), register all 5 use-cases (lazySingleton), register `UnitRepositoryImpl` as `UnitRepository` (lazySingleton), register `UnitCubit` (factory)

- [ ] T014 Run `dart run build_runner build --delete-conflicting-outputs` to generate freezed/json_serializable code for `UnitModel` and `UnitListResponse`

- [ ] T015 Run `flutter analyze lib/src/features/units/` — fix ALL errors before continuing. Expected: zero issues.

**Checkpoint Phase 2**: `flutter analyze` reports zero errors. All use-cases compile. DI registrations resolve.

---

## Phase 3: User Story 1 — List and View Units (Priority: P1)

**Goal**: A user with `canEditMasters` permission can see a paginated, searchable list of active units.

**Independent Test**: Navigate to `/units` → see paginated table with name, abbreviation, type, status → type search query → list filters in real time.

### Tests for User Story 1

- [ ] T016 [P] [US1] Write `test/src/features/units/domain/usecases/list_units_usecase_test.dart` — mock `UnitRepository`, verify `call()` returns `Right<PaginatedResponse<Unit>>` on success, verify `call()` passes `page`, `limit`, `search` args correctly

- [ ] T017 [P] [US1] Write `test/src/features/units/domain/usecases/get_unit_usecase_test.dart` — mock `UnitRepository`, verify `call(id)` returns `Right<Unit>` on success and `Left<Failure>` when not found

- [ ] T018 [P] [US1] Write `test/src/features/units/data/datasources/unit_remote_data_source_test.dart` — mock `DioService`, verify `listUnits()` returns paginated data on success, verify error handling on `DioException`

### Implementation for User Story 1

- [ ] T019 [US1] Create `UnitCubit` in `lib/src/features/units/presentation/bloc/unit_cubit.dart` — inject `ListUnitsUseCase`, `GetUnitUseCase`; methods: `loadUnits({int page = 1, String? search})`, `loadUnit(String id)`; emit `UnitState` with loading/success/error states

- [ ] T020 [US1] Create `UnitState` in `lib/src/features/units/presentation/bloc/unit_state.dart` — fields: `List<Unit> units`, `Unit? selectedUnit`, `bool isLoading`, `String? errorMessage`, pagination fields (`int page`, `int limit`, `int total`, `int pages`); extend `Equatable`

- [ ] T021 [US1] Create `UnitsListPage` in `lib/src/features/units/presentation/pages/units_list_page.dart` — uses `UnitCubit` via `BlocProvider`/`BlocBuilder`; shows paginated list with name, abbreviation, type, status columns; includes search text field; shows loading indicator, empty state, error state; "Add Unit" FAB; list tile taps navigate to detail page

- [ ] T022 [US1] Create `UnitDetailPage` in `lib/src/features/units/presentation/pages/unit_detail_page.dart` — uses `UnitCubit` via `BlocProvider`/`BlocBuilder`; loads unit by ID on init; displays all unit fields read-only; "Edit" and "Deactivate" action buttons

- [ ] T023 [US1] Create `UnitListTile` in `lib/src/features/units/presentation/widgets/unit_list_tile.dart` — reusable tile widget showing unit name, abbreviation, type badge, and active/inactive status indicator

- [ ] T024 [US1] Create barrel export `lib/src/features/units/units.dart` — export all public classes from the units feature

**Checkpoint US1**: Units list loads with pagination and search. Detail page shows unit info. All US1 tests pass.

---

## Phase 4: User Story 2 — Create a Unit (Priority: P1)

**Goal**: A user with `canEditMasters` permission can create a new unit and see it in the list.

**Independent Test**: Navigate to `/units/new` → fill in name, abbreviation, type → submit → redirected to list → new unit appears.

### Tests for User Story 2

- [ ] T025 [P] [US2] Write `test/src/features/units/domain/usecases/create_unit_usecase_test.dart` — mock `UnitRepository`, verify `call()` returns `Right<Unit>` on success, verify duplicate name returns `Left<Failure>`

### Implementation for User Story 2

- [ ] T026 [US2] Create `UnitFormPage` in `lib/src/features/units/presentation/pages/unit_form_page.dart` — supports both create and edit modes via optional `unitId` route param; uses `UnitCubit`; form fields: name (required), abbreviation (required), type (dropdown from enum), description (optional text area); validates before submit

- [ ] T027 [US2] Create `UnitForm` widget in `lib/src/features/units/presentation/widgets/unit_form.dart` — reusable form widget with text fields for name, abbreviation, description, and dropdown for unit type; accepts `onSubmit` callback; shows validation errors inline

- [ ] T028 [US2] Add `createUnit` method to `UnitCubit` in `lib/src/features/units/presentation/bloc/unit_cubit.dart` — inject `CreateUnitUseCase`; calls use-case, on success navigates to list, on failure sets error state

**Checkpoint US2**: Create unit form works end-to-end. Duplicate detection shows error. Form validation prevents empty submission.

---

## Phase 5: User Story 3 — Edit a Unit (Priority: P2)

**Goal**: A user with `canEditMasters` permission can update an existing unit's details.

**Independent Test**: Navigate to unit detail → tap Edit → change name → save → see updated name in list.

### Tests for User Story 3

- [ ] T029 [P] [US3] Write `test/src/features/units/domain/usecases/update_unit_usecase_test.dart` — mock `UnitRepository`, verify `call()` returns `Right<Unit>` on success, verify duplicate name returns `Left<Failure>`

### Implementation for User Story 3

- [ ] T030 [US3] Add `updateUnit` method to `UnitCubit` in `lib/src/features/units/presentation/bloc/unit_cubit.dart` — inject `UpdateUnitUseCase`; calls use-case, on success navigates to detail/list, on failure sets error state

- [ ] T031 [US3] Wire edit flow in `UnitFormPage` — when `unitId` is provided (edit mode), load existing unit via `getUnit` and pre-populate form; on submit call `updateUnit` instead of `createUnit`

**Checkpoint US3**: Edit form pre-populates with existing data. Changes are persisted. Duplicate name shows error.

---

## Phase 6: User Story 4 — Deactivate a Unit (Priority: P3)

**Goal**: A user with `canEditMasters` permission can deactivate a unit that is not in use by materials.

**Independent Test**: Navigate to unit detail → tap Deactivate → confirm → unit disappears from active list.

### Tests for User Story 4

- [ ] T032 [P] [US4] Write `test/src/features/units/domain/usecases/delete_unit_usecase_test.dart` — mock `UnitRepository`, verify `call()` returns `Right(void)` on success, verify `call()` returns `Left<Failure>` when unit is referenced by materials

### Implementation for User Story 4

- [ ] T033 [US4] Add `deleteUnit` method to `UnitCubit` in `lib/src/features/units/presentation/bloc/unit_cubit.dart` — inject `DeleteUnitUseCase`; shows confirmation dialog; on success reloads list, on failure sets error state with explanation

- [ ] T034 [US4] Wire deactivate flow in `UnitDetailPage` — "Deactivate" button triggers `UnitCubit.deleteUnit()` with confirmation dialog

**Checkpoint US4**: Unused units can be deactivated. Referenced units show block message. Deactivated units hidden from default list.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup, analysis pass, quality gates.

- [ ] T035 Run `dart run build_runner build --delete-conflicting-outputs` — regenerate any stale freezed/json_serializable files

- [ ] T036 Run `flutter analyze lib/src/features/units/` — fix ALL errors and warnings. Project MUST pass analysis cleanly.

- [ ] T037 Run `flutter test test/src/features/units/` — all tests MUST pass. Add any missing test imports or mocks.

- [ ] T038 Verify constitution quality gates:
  - [ ] `lib/src/features/units/domain/` has zero imports of `package:flutter`, `package:dio`, or `package:json_annotation`
  - [ ] `UnitRepositoryImpl` returns `Either<Failure, T>` (fpdart)
  - [ ] All unit routes guarded by `canEditMasters` permission in redirect guard
  - [ ] `service_locator.dart` registers all unit dependencies
  - [ ] `unit_model.dart` uses `@freezed` with `fromJson`/`toJson`

- [ ] T039 Update `PLAN.md` (project root) Section 7 — change Units status from `Not started` to `Phase 2 ✅ Done`:
  ```markdown
  | Units | Phase 2 ✅ Done — CRUD, search, pagination, soft-delete |
  ```

- [ ] T040 Run quickstart scenarios 1–9 in order. All must pass. Phase 2 complete.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — already satisfied.
- **Phase 2 (Foundational)**: Depends on nothing. BLOCKS all user stories.
- **Phase 3 (US1 — List/View P1)**: Depends on Phase 2. MVP story.
- **Phase 4 (US2 — Create P1)**: Depends on Phase 2 + US1 (shares list page).
- **Phase 5 (US3 — Edit P2)**: Depends on Phase 2 + US1 (shares detail page) + US2 (shares form page).
- **Phase 6 (US4 — Deactivate P3)**: Depends on Phase 2 + US1 (shares detail page).
- **Phase 7 (Polish)**: Depends on Phases 3–6 all complete.

### User Story Dependencies

- **US1 (P1)**: Can start after Phase 2. No dependency on other stories.
- **US2 (P1)**: Can start after Phase 2. Shares list and Cubit with US1.
- **US3 (P2)**: Can start after Phase 2. Shares detail page with US1, form with US2.
- **US4 (P3)**: Can start after Phase 2. Shares detail page with US1, Cubit delete with US3.

### Parallel Opportunities

```
Phase 2: T001, T002, T003, T004, T005, T006, T007, T008, T009 — all parallel
Phase 3: T016, T017, T018 — parallel (test files)
Phase 4: T025 — parallel with T026, T027
Phase 5: T029 — parallel with T030
Phase 6: T032 — parallel with T033
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 2: Foundational (T001–T015)
2. Complete Phase 3: US1 — List/View (T016–T024)
3. **STOP and VALIDATE**: Run US1 independent test (list loads, search works, detail viewable)
4. Deploy/demo if ready

### Incremental Delivery

1. Phase 2 done → Foundation ready (use-cases, data source, model, DI, routing)
2. Add US1 (List/View) → Test independently → Deploy (MVP!)
3. Add US2 (Create) → Test independently → Deploy
4. Add US3 (Edit) → Test independently → Deploy
5. Add US4 (Deactivate) → Test independently → Deploy
6. Phase 7 (Polish) → All quickstart scenarios green ✅

### Common Mistakes to Avoid

1. **Do NOT** use `context.go()` inside the Cubit — emit navigation state or navigate from UI layer after success.
2. **Do NOT** register `UnitRepositoryImpl` directly — register as `UnitRepository` (interface).
3. **Do NOT** use `.instance` singletons — always inject via `sl()`.
4. **Do NOT** forget `build_runner` after editing `@freezed` models.
5. **Do NOT** skip `flutter analyze` between phases — errors compound.

---

## Notes

- `[P]` tasks = different files, no blocking dependencies
- `[US1]`–`[US4]` labels map tasks to their user story for traceability
- Each user story checkpoint is independently testable
- Tests should be written before implementation (TDD recommended but not enforced)
- The existing `UnitsListPage`, `UnitCubit`, etc. already exist from prior sessions — verify they match the spec before re-implementing
- Phase 3 (US1) is the MVP — stop and validate before continuing
