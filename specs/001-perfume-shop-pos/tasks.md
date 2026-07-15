# Tasks: Perfume Shop POS & Management System

**Input**: specs/001-perfume-shop-pos/spec.md + plan.md + data-model.md + constitution.md

**Prerequisites**: plan.md, spec.md, constitution.md, research.md

**Organization**: Each checkbox from plan.md is an individual task, grouped by the plan's phase structure. Backend tasks before Flutter tasks within each phase.

---

## Phase 1 — Foundation: Auth + Core Setup [US1]

**DoD**: Can log in from mobile/desktop and land on `/dashboard` (empty), close and reopen with session intact, any protected endpoint returns 401 without a token.

**US1 acceptance**: spec.md US1 scenarios 1-5 (login, branch-scoped data, open/close shift, single-shift enforcement).

### Backend

- [ ] **T-001** Init backend repo, ORM (Sequelize or Prisma), env config (`.env` for DB creds + JWT secret)
  - **Files**: `backend/package.json`, `backend/.env.example`, `backend/src/config/database.js`, `backend/src/config/env.js`
  - **Acceptance**: `npm install` completes, DB connection succeeds with env vars, JWT secret loaded
  - **Depends on**: None

- [ ] **T-002** Migrations for all Phase 1 tables: `categories, units, branches, employees, materials, material_branch_stock, customers, suppliers, shifts`
  - **Files**: `backend/src/db/migrations/`, `backend/src/models/`
  - **Acceptance**: `npx sequelize-cli db:migrate` creates all 9 tables, `branch_transfers` is permanently absent (constitution II)
  - **Depends on**: T-001

- [ ] **T-003** Seed script: one main branch, one admin employee with all permissions `true`, base categories/units
  - **Files**: `backend/src/db/seeders/001-init.js`
  - **Acceptance**: `npx sequelize-cli db:seed:all` creates seed data, admin can log in
  - **Depends on**: T-002

- [ ] **T-004** `POST /auth/login` (username+password → access token + refresh token), `POST /auth/refresh`
  - **Files**: `backend/src/routes/auth.js`, `backend/src/controllers/authController.js`, `backend/src/services/authService.js`
  - **Acceptance**: Valid credentials return `{ accessToken, refreshToken, employee: { id, fullName, branchId, permissions } }` per plan.md §3 contract; invalid returns 401 `INVALID_CREDENTIALS`; refresh endpoint returns new access token
  - **Depends on**: T-002, T-003

- [ ] **T-005** `authMiddleware` (JWT check) + `permissionMiddleware(flagName)` (reusable factory for any endpoint)
  - **Files**: `backend/src/middleware/auth.js`, `backend/src/middleware/permission.js`
  - **Acceptance**: Requests without valid token → 401; requests with token but missing permission flag → 403; valid token + correct permission → next()
  - **Depends on**: T-004

- [ ] **T-006** Unified global error handler returning fixed shape `{ error: { code, message } }`
  - **Files**: `backend/src/middleware/errorHandler.js`
  - **Acceptance**: All unhandled errors, validation errors, and known application errors return consistent JSON shape with appropriate HTTP status code
  - **Depends on**: T-001

- [ ] **T-007** Request validation layer (Joi or Zod) on every endpoint from day one
  - **Files**: `backend/src/middleware/validate.js`, `backend/src/validators/`
  - **Acceptance**: Every POST/PATCH/PUT endpoint has a schema; invalid payloads return 400 with structured error messages before reaching controller logic
  - **Depends on**: T-001

### Flutter

- [ ] **T-008** `core/di` (GetIt setup), `core/network` (DioClient + interceptor injecting JWT + auto-refresh on 401)
  - **Files**: `lib/src/config/di.dart`, `lib/src/services/dio_service.dart` (extends existing `DioService`)
  - **Acceptance**: Dio interceptor reads token from secure storage, attaches to every request; on 401 calls refresh endpoint and retries; failure → `AuthFailure`
  - **Depends on**: T-004 (backend login endpoint contract)

- [ ] **T-009** `core/router` (go_router skeleton + redirect guard: no session → `/login`)
  - **Files**: `lib/src/routing/app_router.dart`, `lib/src/routing/app_routes.dart`
  - **Acceptance**: Unauthenticated user redirected to `/login`; authenticated user can navigate to `/dashboard`; route table extensible for future feature routes
  - **Depends on**: T-008

- [ ] **T-010** `core/theme` (full RTL + suitable Arabic font)
  - **Files**: `lib/src/theme/theme.dart`, `lib/src/theme/text_theme.dart`
  - **Acceptance**: Theme supports RTL layout; Arabic text renders correctly with proper font; numbers displayed LTR within RTL text per plan.md §5 item 4
  - **Depends on**: None

- [ ] **T-011** `core/errors` — `ServerFailure, NetworkFailure, ValidationFailure, AuthFailure`
  - **Files**: `lib/src/utils/failure.dart` (extend existing Failure classes)
  - **Acceptance**: Failure types match plan.md §2 Phase 1 Flutter item; each has `code` and `message`; integrates with `runTask()` / `FutureEither` pattern
  - **Depends on**: None

- [ ] **T-012** Full `auth` feature (data/domain/presentation) + `flutter_secure_storage` for tokens and employee data (name, branch, permissions)
  - **Files**: 
    - `lib/src/features/auth/domain/entities/employee.dart`
    - `lib/src/features/auth/domain/repositories/auth_repository.dart`
    - `lib/src/features/auth/data/models/employee_model.dart`
    - `lib/src/features/auth/data/models/auth_response_model.dart`
    - `lib/src/features/auth/data/repositories/auth_repository_impl.dart`
    - `lib/src/features/auth/presentation/providers/auth_bloc.dart`
    - `lib/src/features/auth/presentation/screens/login_screen.dart`
    - `lib/src/features/auth/presentation/screens/dashboard_screen.dart`
  - **Acceptance**: Login flow works end-to-end; tokens stored in secure storage; session restored on app restart; logout clears storage and redirects to login; employee name, branch, permissions accessible from app state
  - **Depends on**: T-009, T-011, T-004 (API)

---

## Phase 2 — Master Data [US2] [US6]

**DoD**: Client can create branch, employee with different permissions, full new material (prices+category) with no help, then open simplified stock-count screen, fill quantities for branch, save all at once — quantity shows only in that branch.

**US2 acceptance**: spec.md US2 scenarios 1-6 (CRUD materials, branches, employees, categories, units; branch-scoped employee access).

**US6 acceptance**: spec.md US6 scenarios 1-3 (opening stock count screen, save quantities, re-open with pre-filled values).

### Backend

- [ ] **T-013** Full CRUD: `/branches`, `/employees`, `/categories`, `/units`, `/materials`, `/customers`, `/suppliers`
  - **Files**: `backend/src/routes/`, `backend/src/controllers/`, `backend/src/services/` for each resource
  - **Acceptance**: All standard CRUD operations work; PATCH for deactivation; GET supports pagination + filtering; employees include permission flags; materials include all 3 price tiers + `isBottle` + `emptyBottlePrice`
  - **Depends on**: T-005 (authMiddleware), T-006, T-007

- [ ] **T-014** `GET /materials/:id/stock` — returns quantity across all branches as `[{branch_id, branch_name, current_quantity}]`
  - **Files**: `backend/src/controllers/materialController.js`, `backend/src/services/materialService.js`
  - **Acceptance**: Returns stock levels per branch for given material; empty array if material has no stock in any branch
  - **Depends on**: T-013

- [ ] **T-015** Validation: `username` unique, `category_id`/`unit_id` must exist (FK check before DB for clear error message)
  - **Files**: `backend/src/validators/`
  - **Acceptance**: Duplicate `username` returns clear 409; non-existent FK returns clear 400 pointing to which reference is invalid
  - **Depends on**: T-007 (validation layer), T-013

- [ ] **T-016** Single endpoint for creating material + opening stock: `POST /materials` accepts `materialData + openingStock: { branchId, quantity }`, inserts `materials` + `material_branch_stock` in one transaction
  - **Files**: `backend/src/controllers/materialController.js`, `backend/src/services/materialService.js`
  - **Acceptance**: Both INSERTs succeed or both roll back; stock appears in `material_branch_stock` for specified branch only; conforms to plan.md §3 `POST /materials` contract
  - **Depends on**: T-013, T-007

### Flutter

- [ ] **T-017** Features `branches`, `employees`, `categories_units` (simple CRUD screens)
  - **Files**: 
    - `lib/src/features/branches/` (data/domain/presentation)
    - `lib/src/features/employees/` (data/domain/presentation)
    - `lib/src/features/categories_units/` (data/domain/presentation)
  - **Acceptance**: Client can add/edit/deactivate branches; add/edit/deactivate employees with permissions; add/edit/deactivate categories and units; all screens in Arabic with clear validation messages
  - **Depends on**: T-012 (auth), T-009 (router registration), T-013 (API)

- [ ] **T-018** Feature `materials`: Add/Edit Material screen (fast, easy, logical tab order, clear validation, "Save and add another" option)
  - **Files**: 
    - `lib/src/features/materials/domain/entities/material.dart`
    - `lib/src/features/materials/domain/repositories/material_repository.dart`
    - `lib/src/features/materials/data/models/material_model.dart`
    - `lib/src/features/materials/data/repositories/material_repository_impl.dart`
    - `lib/src/features/materials/presentation/providers/material_form_bloc.dart`
    - `lib/src/features/materials/presentation/screens/material_form_screen.dart`
    - `lib/src/features/materials/presentation/screens/material_list_screen.dart`
  - **Acceptance**: All 3 price fields (purchase, retail, wholesale); `isBottle` toggle + `emptyBottlePrice` field; category/unit dropdowns; opening stock branch + quantity fields; "Save & Add Another" button; Arabic validation messages per plan.md §1.1
  - **Depends on**: T-017 (categories/units), T-016 (API)

- [ ] **T-019** "Materials Search" screen with live filtering + 300ms debounce
  - **Files**: 
    - `lib/src/features/materials/presentation/providers/material_search_bloc.dart`
    - `lib/src/features/materials/presentation/screens/material_search_screen.dart`
  - **Acceptance**: Search input with 300ms debounce; live results as user types; displays material name, category, prices; empty state; loading indicator
  - **Depends on**: T-018

- [ ] **T-020** "Bulk Opening Stock Entry" screen — list of all ready materials with quantity field each, "Save Count" button, gated until all materials entered
  - **Files**: 
    - `lib/src/features/opening_stock/presentation/screens/opening_stock_screen.dart`
    - `lib/src/features/opening_stock/presentation/providers/opening_stock_bloc.dart`
  - **Acceptance**: Lists all active materials with quantity fields; precondition check prevents opening if materials incomplete; save sends all quantities as single batch; per plan.md §1.2: "this screen must not open at all until all materials are fully entered"
  - **Depends on**: T-018 (materials created), T-016 (API)

---

## Phase 3 — Shifts + Retail Sales Invoice [US1] [US3]

**DoD**: Full sale completes correctly — invoice recorded, `material_branch_stock` decreases by right amount, shift closes with matching numbers, overselling rejected with clear message.

**US1 acceptance**: spec.md US1 scenarios 3-4 (open/close shift, single-shift enforcement).

**US3 acceptance**: spec.md US3 scenarios 1-5 (retail invoice with empty-bottle logic, offline save, sync, stock warning).

### Backend

- [ ] **T-021** `stockService.js`: `decrementStock(materialId, branchId, qty, dbClient)` and `incrementStock(...)` using `SELECT ... FOR UPDATE` inside same transaction as invoice, throws `INSUFFICIENT_STOCK` if insufficient
  - **Files**: `backend/src/services/stockService.js`
  - **Acceptance**: `decrementStock` reduces quantity atomically; throws `INSUFFICIENT_STOCK` with `{ available }` if quantity < requested; `incrementStock` increases quantity; both lock row with `FOR UPDATE`
  - **Depends on**: T-013 (materials, material_branch_stock CRUD)

- [ ] **T-022** `/shifts/open`, `/shifts/close`, `GET /shifts/current?branchId=` — shift close computes `closing_balance` from sum of shift's cash invoices + `opening_balance`
  - **Files**: `backend/src/routes/shifts.js`, `backend/src/controllers/shiftController.js`, `backend/src/services/shiftService.js`
  - **Acceptance**: Open shift fails 409 if another is open for same branch/employee; close shift computes closing balance as `opening_balance + sum(cash_invoice_totals)`; current returns open shift or null
  - **Depends on**: T-005 (auth + permission middleware), T-007 (validation)

- [ ] **T-023** `POST /sales-invoices` — single transaction: confirm open shift, create invoice + line items, `decrementStock` per item, auto-add empty-bottle line if `isBottle=true`, compute totals server-side, auto-insert `credit_ledger` if `payment_method=credit`
  - **Files**: `backend/src/routes/sales.js`, `backend/src/controllers/salesController.js`, `backend/src/services/salesService.js`
  - **Acceptance**: Per plan.md §3 `POST /sales-invoices` contract: 201 response with computed totals; 409 `NO_OPEN_SHIFT` if no shift; 409 `INSUFFICIENT_STOCK` if stock insufficient; empty-bottle line added when `isBottle=true`; `credit_ledger` entry created for credit sales; `employee_id` from JWT not body
  - **Depends on**: T-021 (stockService), T-022 (shift check), T-007 (validation)

- [ ] **T-024** `GET /sales-invoices?branchId=&from=&to=` — list invoices with filters
  - **Files**: `backend/src/controllers/salesController.js`, `backend/src/services/salesService.js`
  - **Acceptance**: Returns sales invoices filtered by branch, date range; paginated; includes line items; permissions-checked
  - **Depends on**: T-023

### Flutter

- [ ] **T-025** Feature `shifts`: open/close shift, router guard preventing `/sales/retail/new` without open shift
  - **Files**: 
    - `lib/src/features/shifts/domain/entities/shift.dart`
    - `lib/src/features/shifts/domain/repositories/shift_repository.dart`
    - `lib/src/features/shifts/data/models/shift_model.dart`
    - `lib/src/features/shifts/data/repositories/shift_repository_impl.dart`
    - `lib/src/features/shifts/presentation/providers/shift_bloc.dart`
    - `lib/src/features/shifts/presentation/screens/shift_screen.dart`
    - `lib/src/routing/app_router.dart` (shift guard)
  - **Acceptance**: Open shift creates shift record; close shift shows summary; guard redirects to shift screen if no open shift; matches spec.md US1 scenarios 3, 4
  - **Depends on**: T-012 (auth), T-009 (router), T-022 (API)

- [ ] **T-026** Feature `sales_retail` — complete retail invoice screen (header, discounts, shift section, line items, three buttons)
  - **Files**:
    - `lib/src/features/sales_retail/domain/`
    - `lib/src/features/sales_retail/data/`
    - `lib/src/features/sales_retail/presentation/providers/sales_retail_bloc.dart`
    - `lib/src/features/sales_retail/presentation/screens/sales_retail_screen.dart`
  - **Events/States per plan.md §6**: `SalesInvoiceStarted`, `SalesInvoiceItemAdded`, `SalesInvoiceItemRemoved`, `SalesInvoiceItemQuantityChanged`, `SalesInvoiceItemPriceOverridden`, `SalesInvoiceDiscountChanged`, `SalesInvoiceCreditToggled`, `SalesInvoiceSubmitted`; states: Loading, ItemsUpdated with computedTotals, Submitting, Success, Failure
  - **Acceptance**: Add line items with fractional quantities; auto-add empty-bottle line for `isBottle=true`; remove/adjust empty-bottle line per FR-018; before/after discount totals; show computed totals provisionally (server-authoritative on sync); payment method toggle (cash/credit); offline save with `client_generated_uuid`; matches spec.md US3 and FR-015 through FR-018
  - **Depends on**: T-025 (shift guard), T-019 (material search), T-023 (API)

- [ ] **T-027** Handle `INSUFFICIENT_STOCK` error in UI — clear Arabic message at save time (not before)
  - **Files**: `lib/src/features/sales_retail/presentation/screens/sales_retail_screen.dart`
  - **Acceptance**: When sync fails with `INSUFFICIENT_STOCK`, show Arabic message with available quantity; allow user to adjust quantity and retry; per plan.md §2 Phase 3 Flutter item 3
  - **Depends on**: T-026

---

## Phase 4 — Wholesale + Purchases [US4] [US5]

**DoD**: Purchase correctly increases stock; wholesale invoice is completely separate in code and UI from retail, correctly uses wholesale price.

**US4 acceptance**: spec.md US4 scenarios 1-3 (separate route, wholesale prices, totals).

**US5 acceptance**: spec.md US5 scenarios 1-3 (purchase invoice, purchase return, offline sync).

### Backend

- [ ] **T-028** `/wholesale-invoices` — same logic as retail but without shift check, without empty-bottle logic, `unit_price` defaults from `wholesale_price`
  - **Files**: `backend/src/routes/wholesale.js`, `backend/src/controllers/wholesaleController.js`, `backend/src/services/wholesaleService.js`
  - **Acceptance**: Wholesale invoice created without shift validation; no empty-bottle lines generated; unit price defaults to material's `wholesale_price`; totals computed server-side; `decrementStock` called
  - **Depends on**: T-021 (stockService), T-005 (permission: `can_sell`), T-007

- [ ] **T-029** `/purchase-invoices` (+ `purchase_return`) — same transaction pattern but `incrementStock` instead of `decrementStock`
  - **Files**: `backend/src/routes/purchases.js`, `backend/src/controllers/purchaseController.js`, `backend/src/services/purchaseService.js`
  - **Acceptance**: Purchase invoice inserts line items + calls `incrementStock` per item; purchase return references original invoice + calls `decrementStock`; totals computed server-side; permission: `can_manage_suppliers`
  - **Depends on**: T-021 (stockService), T-013 (suppliers CRUD), T-007

### Flutter

- [ ] **T-030** Feature `sales_wholesale` — completely separate Bloc/Feature from `sales_retail`
  - **Files**:
    - `lib/src/features/sales_wholesale/domain/`
    - `lib/src/features/sales_wholesale/data/`
    - `lib/src/features/sales_wholesale/presentation/providers/wholesale_invoice_bloc.dart`
    - `lib/src/features/sales_wholesale/presentation/screens/sales_wholesale_screen.dart`
  - **Events/States per plan.md §6**: Same structure as `SalesRetailBloc` but without shift/empty-bottle events; completely separate Bloc (constitution IV)
  - **Acceptance**: Separate route from retail; wholesale prices displayed; no shift guard; no empty-bottle logic; customer selection; matches spec.md US4
  - **Depends on**: T-019 (material search), T-028 (API)

- [ ] **T-031** Feature `purchases` — purchase invoice + purchase return screens
  - **Files**:
    - `lib/src/features/purchases/domain/`
    - `lib/src/features/purchases/data/`
    - `lib/src/features/purchases/presentation/providers/purchase_bloc.dart`
    - `lib/src/features/purchases/presentation/screens/purchase_invoice_screen.dart`
    - `lib/src/features/purchases/presentation/screens/purchase_return_screen.dart`
  - **Acceptance**: Create purchase invoice with supplier, line items, quantities, purchase prices; create purchase return referencing original invoice; both save offline with `client_generated_uuid`; matches spec.md US5
  - **Depends on**: T-019 (material search), T-029 (API)

---

## Phase 5 — Vouchers + Credit Ledger [US7]

**DoD**: Payment/receipt vouchers recorded, correctly linked to employee/branch, work offline-first.

**US7 acceptance**: spec.md US7 scenarios 1-3 (receipt voucher decreases customer credit, payment voucher decreases supplier balance, offline sync).

### Backend

- [ ] **T-032** `/payment-vouchers`, `/receipt-vouchers`
  - **Files**: `backend/src/routes/vouchers.js`, `backend/src/controllers/voucherController.js`, `backend/src/services/voucherService.js`
  - **Acceptance**: Payment voucher records amount to supplier; receipt voucher records amount from customer; both update credit_ledger; permissions: `can_manage_vouchers`
  - **Depends on**: T-013 (customers/suppliers CRUD), T-005 (permission middleware), T-007

- [ ] **T-033** `GET/POST /credit-ledger` with search by name/person/invoice number
  - **Files**: `backend/src/routes/creditLedger.js`, `backend/src/controllers/creditLedgerController.js`
  - **Acceptance**: GET returns ledger entries with filters (customer, supplier, invoice number); POST creates manual credit entry; supports pagination; per plan.md §3 `POST /credit-ledger` contract
  - **Depends on**: T-013, T-007

### Flutter

- [ ] **T-034** Features `payment_vouchers`, `receipt_vouchers`
  - **Files**:
    - `lib/src/features/payment_vouchers/`
    - `lib/src/features/receipt_vouchers/`
  - **Acceptance**: Payment voucher screen (supplier, amount, reference, link to invoices); receipt voucher screen (customer, amount, reference, link to invoices); both save offline with `client_generated_uuid`; matches spec.md US7
  - **Depends on**: T-017 (customer/supplier CRUD), T-032 (API)

- [ ] **T-035** "Credit Search" screen with live-filtering logic (same pattern as Materials Search)
  - **Files**: `lib/src/features/credit/presentation/providers/credit_search_bloc.dart`, `lib/src/features/credit/presentation/screens/credit_search_screen.dart`
  - **Acceptance**: Search by customer name, supplier name, invoice number; 300ms debounce; displays running balance; matches plan.md §2 Phase 5 Flutter item 2
  - **Depends on**: T-033 (API)

---

## Phase 5.5 — Offline-First Design [NO_STORY] (Cross-Cutting)

**DoD**: Disconnect device for a full day, perform several sales locally, reconnect, confirm all operations uploaded in correct order with no duplication and none lost.

### Flutter

- [ ] **T-036** Local database (Hive CE) acting as local cache + write buffer for all tables written from branch (invoices, line items, vouchers, credit)
  - **Files**: `lib/src/services/hive_service.dart` (extend existing), `lib/src/features/*/data/models/` (add Hive adapters via @HiveType)
  - **Acceptance**: All transactional entities stored in Hive boxes; local CRUD operations work without server; per plan.md §5.5 Flutter item 1 (substitute drift/sqflite → Hive per Implementation Notes)
  - **Depends on**: T-012 (auth), T-017 (master data), T-026 (sales retail)

- [ ] **T-037** Local `sync_queue` table — every new operation recorded with `pending` status at save time, regardless of internet
  - **Files**: `lib/src/services/sync_queue_service.dart`, `lib/src/data/models/sync_queue_item.dart`
  - **Acceptance**: Every write operation (sale, purchase, voucher) enqueued with `client_generated_uuid`, operation type, JSON payload, timestamp, status=`pending`; queue persists across app restarts
  - **Depends on**: T-036

- [ ] **T-038** Every operation has `client_generated_uuid` generated on device (not server) — idempotency key
  - **Files**: `lib/src/utils/uuid_helper.dart`
  - **Acceptance**: UUID generated via `Uuid().v4()` or similar before any write; included in API request payload; server uses it to deduplicate; per FR-021, FR-023
  - **Depends on**: T-037

- [ ] **T-039** Background sync worker — watches connectivity, uploads `pending` items in order, updates status to `synced` / `failed_retry`
  - **Files**: `lib/src/services/sync_worker.dart`, `lib/src/services/internet_connection_service.dart` (extend existing)
  - **Acceptance**: Sync triggers on connectivity change + polling every 60s while online; processes queue FIFO; marks synced on success; retries with backoff on failure; per clarification (FR-023)
  - **Depends on**: T-038, T-037, all feature API endpoints

- [ ] **T-040** Sync status indicator — icon/color showing "all synced" / "some operations pending" without blocking cashier
  - **Files**: `lib/src/shared/widgets/sync_status_indicator.dart`
  - **Acceptance**: Green icon when all synced; yellow/red with count when pending; non-blocking (no modal); updates reactively from sync worker state
  - **Depends on**: T-039

- [ ] **T-041** Local quantity calculation — quantity shown at sale time = local quantity after applying all local operations (even pending ones)
  - **Files**: `lib/src/services/local_stock_service.dart`
  - **Acceptance**: Stock display reflects local DB state (including un-synced operations); no need to wait for server; per plan.md §5.5 Flutter item 6
  - **Depends on**: T-036, T-021 (stock logic)

### Backend

- [ ] **T-042** Every endpoint checks `client_generated_uuid` first — if exists, ignore request and return success (idempotency)
  - **Files**: `backend/src/middleware/idempotency.js`, apply to all write routes
  - **Acceptance**: Duplicate `client_generated_uuid` returns 200/201 without re-processing; first write proceeds normally; per plan.md §5.5 Backend item 1
  - **Depends on**: T-023, T-028, T-029, T-032 (all write endpoints)

- [ ] **T-043** `SELECT ... FOR UPDATE` transaction pattern remains as defense-in-depth on all stock-modifying endpoints
  - **Files**: `backend/src/services/stockService.js` (already in T-021, verify coverage)
  - **Acceptance**: All stock mutations use `FOR UPDATE` within transaction; per plan.md §5.5 Backend item 2
  - **Depends on**: T-021 (already implemented)

---

## Phase 6 — Reports + Final Hardening [US8]

**DoD**: Full integration scenario (sale → return → report, including offline) produces 100% matching numbers across all screens.

**US8 acceptance**: spec.md US8 scenarios 1-4 (stock report with low-stock indicator, sales report with date range, customer/supplier statements).

### Backend

- [ ] **T-044** `/reports/stock?branchId=`, `/reports/sales?branchId=&from=&to=`, `/reports/statement?customerId=|supplierId=`
  - **Files**: `backend/src/routes/reports.js`, `backend/src/controllers/reportController.js`, `backend/src/services/reportService.js`
  - **Acceptance**: Stock report returns material name, current qty, unit, low-stock indicator; Sales report returns total sales, count, top materials, retail/wholesale breakdown; Statement shows chronological transactions with running balance; permissions: `can_view_reports`
  - **Depends on**: T-005 (permission), T-013, T-023, T-028, T-029, T-032 (all data sources)

- [ ] **T-045** Rate limiting on `/auth/login` — 5 attempts/minute per IP
  - **Files**: `backend/src/middleware/rateLimiter.js`
  - **Acceptance**: 6th failed login within 1 minute from same IP returns 429; per plan.md §8 checklist item 12 and spec.md test matrix
  - **Depends on**: T-004

- [ ] **T-046** Full permission review — every endpoint checks a real permission server-side
  - **Files**: Audit all route files in `backend/src/routes/`
  - **Acceptance**: Every route handler has `permissionMiddleware(flag)` applied matching plan.md §4 permission matrix; no endpoint relies on UI hiding alone
  - **Depends on**: T-005 (permissionMiddleware), all endpoint tasks

- [ ] **T-047** Backup: daily scheduled `pg_dump` + actual restore test documented
  - **Files**: `backend/scripts/backup.sh`, `backend/scripts/restore-test.sh`, `backend/cron/backup.cron`
  - **Acceptance**: `pg_dump` runs daily; restore test script confirms backup is valid; per plan.md §8 checklist item 15
  - **Depends on**: T-001

### Flutter

- [ ] **T-048** Feature `reports_dashboard` — stock per branch, sales/purchases over period, customer/supplier statement, branch comparison
  - **Files**: `lib/src/features/reports_dashboard/presentation/screens/`, `lib/src/features/reports_dashboard/presentation/providers/`
  - **Acceptance**: Stock report with low-stock indicator per FR-030; sales report with date range, top materials, retail/wholesale breakdown per FR-031; customer statement per FR-032; supplier statement per FR-033; all Arabic UI per FR-034; matches spec.md US8
  - **Depends on**: T-044 (API)

---

## Final Consolidated Checklist — Verification & Hardening [NO_STORY]

**Purpose**: Final verification of all constitutional principles and plan-level requirements. These are review/audit tasks spanning all phases.

- [ ] **T-049** Verify every table in schema has an actual migration — without `branch_transfers`
  - **Files**: All migration files in `backend/src/db/migrations/`
  - **Acceptance**: Every table in data-model.md has a corresponding migration file; `branch_transfers` table does not exist (constitution II)
  - **Depends on**: All migration tasks (T-002 + later phase migrations)

- [ ] **T-050** Verify `materials` and prices are centralized/shared, `material_branch_stock` is only per-branch difference
  - **Files**: `backend/src/models/`, migration files
  - **Acceptance**: `materials` table has single source of truth for prices; `material_branch_stock` has `(material_id, branch_id)` as composite key with only `current_quantity` as branch-specific field
  - **Depends on**: T-013, T-016

- [ ] **T-051** Verify `material_branch_stock` is only updated inside a transaction — no direct UI path
  - **Files**: `backend/src/services/stockService.js`, all controller files
  - **Acceptance**: No code path modifies `material_branch_stock` outside of `stockService` transaction; grep for direct UPDATE/INSERT on the table
  - **Depends on**: T-021, T-043

- [ ] **T-052** Verify `employee_id` and `branch_id` always come from session/JWT, never manual form input
  - **Files**: All API request handlers, all Flutter form models
  - **Acceptance**: All backend endpoints extract `employee_id` and `branch_id` from JWT (req.user); Flutter forms do not include these fields in request payload (constitution I)
  - **Depends on**: T-005, all endpoint tasks

- [ ] **T-053** Verify retail and wholesale are completely separate features (code, Bloc, routes)
  - **Files**: `lib/src/features/sales_retail/`, `lib/src/features/sales_wholesale/`, `lib/src/routing/app_router.dart`
  - **Acceptance**: `sales_retail` and `sales_wholesale` are different directories, different Blocs, different routes; no shared toggle/flag; no shared Bloc (constitution IV)
  - **Depends on**: T-026, T-030

- [ ] **T-054** Verify empty-bottle logic active only in material screen and retail invoice line items
  - **Files**: `lib/src/features/materials/presentation/screens/material_form_screen.dart`, `lib/src/features/sales_retail/`
  - **Acceptance**: `isBottle` flag only in material form; empty-bottle line auto-added only in retail invoice; not present in wholesale or purchase flows
  - **Depends on**: T-018, T-026

- [ ] **T-055** Verify opening new sales invoice impossible without open shift for that branch
  - **Files**: `lib/src/routing/app_router.dart`, `lib/src/features/shifts/presentation/providers/shift_bloc.dart`
  - **Acceptance**: Router guard prevents navigation to `/sales/retail/new` if no open shift; guard checks branch of logged-in employee
  - **Depends on**: T-025

- [ ] **T-056** Verify all financial totals computed server-side, zero trust in client numbers
  - **Files**: `backend/src/services/salesService.js`, `backend/src/services/wholesaleService.js`
  - **Acceptance**: Server recalculates totals from line items + discounts; ignores any `total` or `finalTotal` from request body; constitution I
  - **Depends on**: T-023, T-028

- [ ] **T-057** Verify every endpoint checks a real `permissions` flag server-side
  - **Files**: All route files in `backend/src/routes/`
  - **Acceptance**: Matches plan.md §4 permission matrix; no endpoint accessible without correct permission middleware
  - **Depends on**: T-046

- [ ] **T-058** Verify all passwords bcrypt-hashed
  - **Files**: `backend/src/services/authService.js`
  - **Acceptance**: Password stored as bcrypt hash; login compares against hash; no plain-text passwords ever stored
  - **Depends on**: T-004

- [ ] **T-059** Verify all quantities are `numeric`, not `integer`
  - **Files**: All migration files, all model definitions
  - **Acceptance**: Database columns for quantity use `DECIMAL`/`NUMERIC` type (not `INTEGER`); Flutter models use `double` (not `int`); constitution V
  - **Depends on**: T-002, all model tasks

- [ ] **T-060** Verify rate limiting on `/auth/login`
  - **Files**: `backend/src/middleware/rateLimiter.js`
  - **Acceptance**: 5 failed attempts per minute per IP → 429 on 6th; reset after 1 minute
  - **Depends on**: T-045

- [ ] **T-061** Verify local DB + Sync Queue + `client_generated_uuid` on every device
  - **Files**: `lib/src/services/sync_queue_service.dart`, `lib/src/services/sync_worker.dart`
  - **Acceptance**: All write operations pass through sync queue; each has `client_generated_uuid`; background worker processes queue; matches FR-021, FR-022, FR-023
  - **Depends on**: T-037, T-038, T-039

- [ ] **T-062** Actual offline test performed — disconnect for a day, sell locally, reconnect, confirm no duplication
  - **Files**: Test plan/script
  - **Acceptance**: Full-day offline test documented with results; all operations sync without duplicates; numbers match server-side after sync; per plan.md §5.5 DoD
  - **Depends on**: T-039, T-042, all write features

- [ ] **T-063** Daily backups + actual restore test
  - **Files**: `backend/scripts/restore-test.sh`
  - **Acceptance**: Backup runs daily via cron; restore test script executed and confirmed working; per plan.md §8 checklist item 15
  - **Depends on**: T-047

---

## Dependencies & Execution Order

### Phase Dependencies

| Phase | Depends On | Parallelizable? |
|-------|-----------|-----------------|
| **Phase 1** (Foundation) | Nothing | Backend (T-001–T-007) before Flutter (T-008–T-012) |
| **Phase 2** (Master Data) | Phase 1 | Backend (T-013–T-016) before Flutter (T-017–T-020) |
| **Phase 3** (Shifts + Retail) | Phase 1, Phase 2 | Backend (T-021–T-024) before Flutter (T-025–T-027) |
| **Phase 4** (Wholesale + Purchases) | Phase 1 (auth + stockService) | Backend (T-028–T-029) before Flutter (T-030–T-031) |
| **Phase 5** (Vouchers) | Phase 1 (auth), Phase 2 (customers/suppliers) | Backend (T-032–T-033) before Flutter (T-034–T-035) |
| **Phase 5.5** (Offline-First) | Phase 1, Phase 2, Phase 3 | Flutter (T-036–T-041) before Backend idempotency (T-042); T-043 is defense-in-depth on existing code |
| **Phase 6** (Reports) | All prior phases | Backend (T-044–T-047) before Flutter (T-048) |
| **Consolidated Checklist** | All phases | All verification items (T-049–T-063) run after all implementation |

### Within Each Phase
- Backend tasks before Flutter tasks (Flutter depends on API contracts)
- Where marked `[P]` in task description, tasks can run in parallel (different files, no interdependencies)

### Parallel Opportunities
- Within Phase 1 Backend: T-001, T-006, T-007 can start in parallel
- Within Phase 1 Flutter: T-010, T-011 can start in parallel
- Within Phase 2 Backend: T-013, T-015 can start simultaneously
- Within Phase 2 Flutter: T-017, T-018 can start in parallel (different features)
- T-021 (stockService) can be implemented as soon as material_branch_stock migration exists, even before full CRUD
- T-039 (sync worker) can be implemented once T-037 and any one write endpoint exist
- All consolidated checklist tasks (T-049–T-063) can run in parallel as pure verification

### MVP Scope (P1 Only)
To ship MVP, complete:
1. Phase 1 (T-001 through T-012) — Auth + Core
2. Phase 2 (T-013 through T-020) — Master Data
3. Phase 3 (T-021 through T-027) — Shifts + Retail Sales (core revenue flow)
4. Phase 5.5 critical path (T-036, T-037, T-038, T-039, T-042) — Offline-first for retail

### Full Scope (P2 + P3)
After MVP:
5. Phase 4 (T-028 through T-031) — Wholesale + Purchases
6. Phase 5 (T-032 through T-035) — Vouchers + Credit
7. Phase 5.5 remaining (T-040, T-041) — Sync indicator + local stock
8. Phase 6 (T-044 through T-048) — Reports + Hardening
9. Consolidated Checklist (T-049 through T-063)
