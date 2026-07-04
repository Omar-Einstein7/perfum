<!--
SYNC IMPACT REPORT
==================
Version change: [UNVERSIONED] → 1.0.0
Modified principles: N/A (initial ratification)
Added sections:
  - Core Principles (I–VII)
  - Technology Stack & Module Registry
  - Development Workflow
  - Governance
Templates reviewed:
  - .specify/templates/plan-template.md ✅ (compatible — no ERP-specific references needed)
  - .specify/templates/spec-template.md ✅ (compatible — user stories/FR/SC format applies unchanged)
  - .specify/templates/tasks-template.md ✅ (compatible — phase structure aligns with build order)
  - .specify/templates/constitution-template.md ✅ (source template, no update required)
Follow-up TODOs:
  - TODO(RATIFICATION_DATE): Treat 2026-07-04 as initial ratification date (today).
  - Backend Node.js/Express is a separate project not yet scaffolded; backend architecture
    constitution should be written when that repo is created.
-->

# Inventory/POS ERP Constitution

## Core Principles

### I. Clean Architecture (NON-NEGOTIABLE)

The Flutter frontend MUST follow Clean Architecture with three strict layers:

- **Domain** — pure Dart only. Entities, abstract repository interfaces, and use-case
  classes live here. This layer MUST NOT import Flutter, Dio, json_serializable,
  or any infrastructure package.
- **Data** — implements domain repository interfaces. Contains models (with `fromJson`/
  `toJson` via `freezed` + `json_serializable`), remote data sources (Dio), and local
  data sources (SharedPreferences / FlutterSecureStorage).
- **Presentation** — Flutter widgets + `flutter_bloc` (Cubit or Bloc). MUST NOT
  call Dio or access storage directly; all side effects flow through injected
  use-cases or repositories.

Each feature (`lib/src/features/<feature>/`) MUST contain exactly these three
subdirectories. Skipping a layer or merging layers is a constitution violation.

**Rationale**: Enforces testability, replaceability of infrastructure, and
long-term maintainability across 15 modules built over an extended timeline.

### II. MongoDB ObjectId Strings as Identifiers

All entity identifiers MUST be represented as Dart `String` (MongoDB ObjectId
hex strings). Integer primary keys are NEVER used anywhere in the system —
not in entities, models, API contracts, or UI state.

**Rationale**: The backend uses MongoDB. Using strings end-to-end eliminates
impedance mismatch and prevents accidental int/string confusion bugs.

### III. Derived-Only Financial State

Stock quantities, customer balances, and supplier balances MUST NOT be stored
as persistent fields on any entity. They are ALWAYS computed at query time from
the canonical transaction records (invoices, vouchers, transfers).

- The `Stock` and `Credit Ledger` modules are READ-ONLY aggregation views.
- No write path may update a "balance" or "quantity" field directly.

**Rationale**: Derived state is the single source of truth pattern from the
original Access database. Storing it redundantly creates consistency hazards
in a multi-branch, multi-user environment.

### IV. Atomic Money-Affecting Writes

Any operation that changes financial position — invoice submission, voucher
submission, or stock transfer — MUST be executed as an atomic backend
transaction. Partial writes that leave the database in an inconsistent state
are unacceptable.

- Backend (Node.js + Mongoose) MUST use MongoDB sessions/transactions for
  these operations.
- Frontend MUST treat these as single, non-retryable operations: on failure,
  roll back the UI state and surface a clear error; never silently retry a
  financial write.

**Rationale**: Financial integrity is the primary non-functional requirement
of an ERP. Partial writes cause un-auditable ledger discrepancies.

### V. Permission-Gated Routes

Every screen and API route MUST map to exactly one of the 7 permission flags
defined in the `Auth & Users` module. No screen is accessible without a
verified JWT that carries the required permission bit.

- The router (`go_router`) MUST implement a redirect guard that checks
  `SessionBloc` state before rendering any protected route.
- The backend MUST validate the JWT and permission flag on every protected
  endpoint; client-side permission checks are defense-in-depth only, never
  the sole gate.

**Rationale**: Multi-user, multi-branch ERP systems require role-based access
at both UI and API layers to protect sensitive financial data.

### VI. Build Order Discipline

Modules MUST be built in the prescribed dependency order:

```
Auth → Units → Categories → Materials → Suppliers → Customers → Branches
→ Purchase Invoices → Sales Invoices → Payment Vouchers → Receipt Vouchers
→ Transfers → Stock → Credit Ledger → Reports & Dashboard
```

A later module MUST NOT be started until all modules it depends on are
functionally complete (entities, repository, at least one happy-path screen).
Skipping ahead to create stubs for convenience is permitted only in the shared
`domain/entities` layer; no skip-ahead is permitted in data or presentation.

**Rationale**: Lookup tables (units, categories) are referenced by every
invoice line. Building out of order creates placeholder data and coupling debt.

### VII. State Management via flutter_bloc Only

All application state MUST be managed through `flutter_bloc` (Cubit or Bloc).
Direct `setState`, `ChangeNotifier`, `Provider`, `Riverpod`, or `ValueNotifier`
(outside of strictly local, ephemeral widget state) are not permitted.

- Cubits are preferred for simple request/response flows (CRUD, form submission).
- Blocs (with explicit Events) are preferred for flows with multiple input
  triggers (e.g., real-time search, pagination, multi-step wizards).
- `get_it` is the sole dependency-injection mechanism; no context-based DI
  (e.g., `Provider.of`, `context.read` for injecting services) is permitted
  outside of Bloc/Cubit constructors.

**Rationale**: A single state management approach across 15 modules maintains
consistency, makes BLoC states machine-readable, and simplifies onboarding.

## Technology Stack & Module Registry

### Approved Stack

| Layer | Package / Tool | Notes |
|---|---|---|
| Language | Dart (SDK ^3.11.5) | |
| UI framework | Flutter (web target) | |
| State management | flutter_bloc ^9.1.1 | Cubit default, Bloc for complex flows |
| DI | get_it ^9.2.1 | Singleton registration in `services/` |
| Routing | go_router ^17.1.0 | Declarative; redirect guards for auth |
| HTTP | dio ^5.9.2 | Wrapped in `DioService`; base URL from `.env` |
| Serialization | freezed ^3.2.5 + json_serializable ^6.14.0 | All models use `@freezed` |
| Functional | fpdart ^1.2.0 | `Either<Failure, T>` as repository return type |
| Equality | equatable ^2.0.7 | Domain entities |
| Secure storage | flutter_secure_storage ^10.0.0 | JWT token storage |
| Local prefs | shared_preferences ^2.5.4 | Non-sensitive settings |
| Localization | easy_localization ^3.0.8 | AR/EN minimum |
| Responsive | flutter_screenutil ^5.9.3 | Web + mobile breakpoints |
| Logging | logger ^2.6.2 | Dev builds only; strip in release |
| Auth | JWT + bcrypt (backend) | 7 permission flags per user |
| Backend | Node.js + Express + Mongoose | Separate repository |
| Database | MongoDB | ObjectId strings only |

No package outside this table may be added without a written rationale and
constitution amendment.

### Module Registry

| # | Module | Build Status |
|---|---|---|
| 1 | Auth & Users | Not started |
| 2 | Units of Measure | Not started |
| 3 | Categories | Not started |
| 4 | Materials (Items) | Not started |
| 5 | Suppliers | Not started |
| 6 | Customers | Not started |
| 7 | Branches | Not started |
| 8 | Purchase Invoices | Not started |
| 9 | Sales Invoices | Not started |
| 10 | Payment Vouchers | Not started |
| 11 | Receipt Vouchers | Not started |
| 12 | Transfers | Not started |
| 13 | Stock (read-only) | Not started |
| 14 | Credit Ledger (read-only) | Not started |
| 15 | Reports & Dashboard | Not started |

## Development Workflow

### Per-Module Sequence

For every module in the build order:

1. **Domain first** — define the entity, abstract repository interface, and
   use-case classes. No Flutter imports.
2. **Data layer** — implement the model (`@freezed`), remote data source
   (Dio), and repository implementation.
3. **Presentation layer** — implement the Cubit/Bloc, screens, and widgets.
4. **Route registration** — add the route to `app_router.dart` with the
   correct permission guard.
5. **Manual smoke test** — verify the module end-to-end before moving on.

### Directory Convention

```
lib/src/features/<module_name>/
├── data/
│   ├── models/          # @freezed models with fromJson/toJson
│   ├── datasources/     # remote_datasource.dart, local_datasource.dart
│   └── repositories/    # repository_impl.dart
├── domain/
│   ├── entities/        # pure Dart, Equatable
│   ├── repositories/    # abstract interface
│   └── usecases/        # single-responsibility use-case classes
└── presentation/
    ├── providers/        # cubit.dart or bloc.dart + state.dart
    ├── screens/          # one file per screen
    └── widgets/          # module-specific reusable widgets
```

Shared widgets belong in `lib/src/shared/widgets/`.
Shared services belong in `lib/src/services/`.

### Quality Gates (per module)

- [ ] Domain layer has zero Flutter/Dio/json imports
- [ ] Repository impl returns `Either<Failure, T>` (fpdart)
- [ ] All screens guarded by permission redirect in `app_router.dart`
- [ ] No financial write operates outside an atomic backend transaction
- [ ] No entity uses an integer as its primary identifier

## Governance

This constitution supersedes all other practices, conventions, and preferences
for this project. Any deviation requires:

1. A written rationale added to a PR or session note.
2. An amendment to this document with version bump.
3. A migration note if existing code violates the new rule.

**Amendment process**:
- PATCH bump: wording clarifications, module status updates, adding an
  approved package to the stack table.
- MINOR bump: adding a new principle or materially expanding guidance.
- MAJOR bump: removing or fundamentally redefining an existing principle.

All sessions working on this project MUST reference `PLAN.md` for module
sequence and this constitution for coding rules.

**Version**: 1.0.0 | **Ratified**: 2026-07-04 | **Last Amended**: 2026-07-04
