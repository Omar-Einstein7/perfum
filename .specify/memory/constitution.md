<!--
Sync Impact Report
==================
Version change: (uninitialized template) -> 1.0.0

Modified principles: N/A - initial ratification. All placeholder tokens were
  filled from the user-supplied constitution for the Inventory/POS Management
  System (Flutter Web, migrated from Access ERP).

Added sections:
  - Core Principles I-V (Clean Architecture, State Management Discipline,
    Dependency Injection Convention, Networking & Data Contract, Test Discipline)
  - Tech Stack, Domain & Naming Conventions
  - Error Handling, Routing & Access Control (RBAC)
  - Governance (amendment procedure, versioning policy, compliance review,
    excluded/deferred tracking, runtime UI guidance)

Removed sections: none

Templates requiring updates:
  - .specify/templates/plan-template.md      -- OK no changes needed
    (Constitution Check gate is generic: "[Gates determined based on
    constitution file]")
  - .specify/templates/spec-template.md      -- OK no changes needed
    (generic; no constitution-specific mandatory sections introduced)
  - .specify/templates/tasks-template.md     -- OK no changes needed
    (phase/test structure already aligns with the Test Discipline principle)
  - .specify/templates/commands/             -- N/A (directory does not exist)

Runtime guidance:
  - README.md      -- default Flutter boilerplate; no constitution references
  - cal/DESIGN.md  -- design-system reference; cited in Governance as UI guidance

Follow-up TODOs: none
-->

# Inventory/POS Management System Constitution

## Core Principles

### I. Clean Architecture (NON-NEGOTIABLE)

Each feature MUST be structured as three layers with strictly one-way
dependency: `presentation -> domain <- data`.

- The domain layer MUST have zero Flutter, Dio, or `dart:convert` json imports.
  Entities are pure Dart + `equatable`; no serialization code lives here.
- `Model extends Entity`: data models add `fromJson`/`toJson` on top of pure
  entities. Entities never import models.
- A UseCase exposes a single `call()` method with one responsibility.
- The repository interface lives in `domain/repositories`; its implementation
  lives in `data/repositories`. Presentation and data layers depend on the
  domain interface, never the concrete implementation.

**Rationale:** Isolating business logic from Flutter and I/O makes features
independently testable and allows the datasource (Dio/Node backend) to be
swapped without touching domain or presentation code.

### II. State Management Discipline

- Use **Cubit** for list/detail/CRUD screens with no branching logic
  (categories, units, customers, suppliers, branches).
- Use **Bloc** with typed events for screens with sequenced or multi-step flows
  (sales-invoice builder: `AddLineItem`/`RemoveLineItem`/`ApplyDiscount`/
  `SubmitInvoice`; stock-transfer wizard).
- State MUST be a sealed union via freezed: `Initial / Loading / Loaded(data) /
  Error(failure)`. Boolean flag soup (`isLoading` + `isError` + `data`) is
  forbidden.
- One Cubit/Bloc per page, registered in GetIt as `factory` (not singleton) so
  each navigation yields a fresh instance.

**Rationale:** Sealed states make illegal states unrepresentable; factory
registration prevents stale state leaking across navigations.

### III. Dependency Injection Convention (GetIt)

Registration order per feature MUST be: datasource (`lazySingleton`) ->
repository (`lazySingleton`) -> usecases (`factory`) -> cubit/bloc (`factory`).

- External and core services (`Dio`, `DioClient`, `NetworkInfo`) are
  `lazySingleton`.
- Cubits and Blocs MUST be `factory` -- never `singleton` -- to avoid carrying
  stale state between screens.
- All wiring lives in `core/di/injection_container.dart`; features register
  through it, not through ad-hoc `GetIt.instance` calls scattered in widgets.

**Rationale:** A single registration contract guarantees consistent object
lifetimes and makes substitution in tests predictable.

### IV. Networking & Data Contract

- The Dio client wraps interceptors: JWT bearer header, debug-only request/
  response logging, and unified error-to-`ServerException` mapping.
- All entity `id` fields are `String` (MongoDB `ObjectId` hex, 24-char) --
  never `int`. The legacy Access `Long Integer` PKs are not carried over.
- Dates are transmitted as ISO-8601 strings in both directions.
- Currency is stored and transmitted as `num` and formatted client-side with
  `intl`. This convention is decided once and applied everywhere.
- The REST envelope is uniform:
  `{ "success": bool, "data": ..., "message": ... }`.
  Pagination uses `?page=&limit=` returning
  `{ data: [...], meta: { total, page, pages } }`.

**Rationale:** A fixed wire contract with the Node/Express + MongoDB backend
keeps serialization type-safe and prevents per-feature format drift.

### V. Test Discipline (NON-NEGOTIABLE)

- **domain:** pure unit tests; no mocks beyond the repository interface.
- **data:** `mocktail` for datasource/Dio mocks; verify JSON mapping in both
  directions.
- **presentation:** `bloc_test` for every Cubit/Bloc covering at minimum the
  `Loading -> Loaded` and `Loading -> Error` transitions.
- Every UseCase and every Cubit/Bloc MUST have at least one test before merge;
  this is enforced in CI.

**Rationale:** This system is migrated from an Access ERP whose VBA business
rules were not extractable. Tests are the only safeguard against silently
re-introducing or omitting migrated logic.

## Tech Stack, Domain & Naming Conventions

**Stack (client):** Flutter Web, Dart 3.x, null-safety strict. Packages:
`flutter_bloc`, `get_it` (`injectable` optional), `dio`, `go_router`, `freezed`
+ `json_serializable`, `dartz`, `intl`.

**Stack (backend):** Node.js + Express + MongoDB (Mongoose), JWT auth. The
backend lives outside this repository, but its contract is binding (see
Principle IV).

**Feature modules** (mapped from the Access ERP, renamed to English):

- `materials` -- items/products with stock qty (CQ/NEWQ); links category + unit.
- `categories`, `units` -- material classification and unit of measure.
- `stock` -- derived/read-only stock ledger view (not a stored collection).
- `customers`, `suppliers`, `branches` ("sellers" with `branchname`) -- parties.
- `sales_invoices`, `purchase_invoices` -- header + embedded line items.
- `receipt_vouchers` (cash-in), `payment_vouchers` (cash-out).
- `credit_ledger` -- deferred/credit balances; derived report, GET-only.
- `transfers` -- inter-branch stock transfer.
- `users` -- RBAC via 7 boolean permission flags + a `role` field.
- `auth`, `dashboard`, `reports` -- supporting modules.

**MongoDB schema rules:**

- **Embed** invoice line items inside the invoice document
  (`items: [{ materialId, qty, price, discount }]`) -- always read/written
  together; replaces the separate Access detail tables.
- **Reference** (ObjectId) for `materials.category`, `materials.unit`, invoice
  `customerId`/`supplierId`/`branchId`, and voucher `customerId`/`supplierId`.
- `stock` and `credit_ledger` are NOT stored collections -- compute via
  aggregation pipeline. Cache only if performance requires it; never as source
  of truth.
- `users.permissions` is an embedded object
  `{ info, res, sell, snadat, user, report, report2 }` of booleans matching the
  Access flags 1:1.

**Naming & files:**

- Files: `snake_case.dart`. Classes: `PascalCase`. Bloc events/states are
  suffixed `Event`/`State`.
- One class per file; file name = class name in snake_case.
- Barrel files (`feature.dart`) per feature module for clean imports.
- No business logic in widgets -- widgets read state and dispatch events/calls,
  nothing else.

## Error Handling, Routing & Access Control (RBAC)

**Error pipeline:** DataSource throws `Exception` subtypes -> Repository
catches and maps to `Either<Failure, T>` -> Cubit/Bloc emits `Error(failure)`
-> UI shows `failure.message`. Raw exceptions MUST NOT reach the UI.

Failure hierarchy:

- `ServerFailure` (carries `message`)
- `NetworkFailure`
- `ValidationFailure` (carries `message`)

**Routing (go_router):** Route guards read auth state and `permissions` from
the injected auth cubit. Each top-level route maps to one `p_*` permission
flag:

| Route | Required permission |
|---|---|
| `/materials`, `/categories`, `/units` | `p_info` |
| `/suppliers`, `/purchase-invoices` | `p_res` |
| `/customers`, `/sales-invoices` | `p_sell` |
| `/vouchers/*` | `p_snadat` |
| `/users` | `p_user` |
| `/reports/*` | `p_report`, `p_report2` |

Unauthorized access MUST redirect to `/403` -- never silently hide routes
(hidden routes cause confusing empty screens).

**Access control model:** A `role: 'superadmin' | 'admin' | 'staff'` field on
the `users` collection replaces the legacy `المبرمج` dev-backdoor table. The
seven boolean permission flags remain the granular gate for route-level access.

## Governance

This constitution supersedes all other practices for the Inventory/POS
Management System. Any deviation MUST be justified in a Complexity Tracking
entry (see `plan-template.md`) and approved before implementation.

**Amendment procedure:**

1. Propose the change with rationale and affected layers/features.
2. Update this document; bump the version per the policy below.
3. Record the amendment in the Sync Impact Report (HTML comment at the top of
   this file).
4. Propagate updates to dependent specs/plans/tasks.

**Versioning policy:** Semantic versioning -- `MAJOR.MINOR.PATCH`.

- MAJOR: backward-incompatible principle removal/redefinition or governance
  restructuring.
- MINOR: new principle or materially expanded guidance added.
- PATCH: clarifications, wording, typo fixes, non-semantic refinements.

**Compliance review:** Every plan (`/speckit.plan`) MUST pass a Constitution
Check gate before Phase 0 research and re-check after Phase 1 design. Every
PR/review MUST verify compliance with the Core Principles.

**Excluded / deferred tracking:** Items excluded or deferred from the Access
migration MUST be flagged explicitly here -- never silently dropped:

- `المبرمج` (dev backdoor table) -> excluded; replaced by
  `role: 'superadmin'` on the `users` collection. Not ported as a parallel
  hidden account.
- Access macros/VBA business logic (validation rules, auto-numbering, print
  layouts) were not extractable via mdb-tools and MUST be manually
  reverse-engineered from the original Access forms/reports when its UI is
  available, since they are not visible in the raw schema.

**Runtime UI guidance:** Use `cal/DESIGN.md` as the design-system reference
before writing any UI, and customize it as the project evolves.

**Version**: 1.0.0 | **Ratified**: 2026-07-03 | **Last Amended**: 2026-07-03
