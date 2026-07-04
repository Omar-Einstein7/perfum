# PHASES.md — Inventory/POS ERP Build Phases

Reference this file alongside `PLAN.md` (module order) and `.specify/memory/constitution.md` (rules).
Each phase ends with a **checkpoint** — do not start the next phase until the checkpoint passes.

---

## Current State Audit

| Layer | What exists | Gaps |
|---|---|---|
| Infra | `AppConfig` (Dio + `.env`), `DioService`, `AuthService`, `SecureStorageService` | JWT interceptor missing; no token persistence |
| Auth domain | `AppUser` entity, `AuthRepository` interface, `SessionBloc`, `AuthBloc` | `AppUser` has no `permissions` field; no use-cases |
| Auth data | `AuthRepositoryImpl`, `user_model.dart` (no `fromJson`/`toJson`) | Model not `@freezed`; id uses `.toString()` not ObjectId string |
| Auth presentation | `LoginScreen`, `SignupScreen`, `ForgotPasswordScreen` scaffolds | Not connected to real UI; screens are empty shells |
| Routing | `go_router` flat table, `AppRoutes` constants | No redirect guard; all routes unprotected |
| Shared | Full widget library, helpers, theme, services | Already solid — no ERP-specific work needed |

---

## Phase 0 — Infrastructure Hardening
**Goal**: Solid foundation before any module code is written.
**Touches**: `AppConfig`, `DioService`, `SecureStorageService`, `AppRoutes`, `app_router.dart`

### Tasks

- [ ] **P0-T01** Add JWT auth interceptor to `AppConfig.dio`
  - On every request: read token from `SecureStorageService`, inject `Authorization: Bearer <token>` header
  - On 401 response: emit unauthenticated event to `AuthService` stream, clear token, redirect to login

- [ ] **P0-T02** Add `PermissionFailure` to `lib/src/utils/failure.dart`
  ```dart
  class PermissionFailure extends Failure {
    const PermissionFailure(super.message, {super.error});
  }
  ```

- [ ] **P0-T03** Add ERP route constants to `AppRoutes`
  - `/dashboard`, `/units`, `/categories`, `/materials`, `/suppliers`,
    `/customers`, `/branches`, `/purchases`, `/purchases/new`, `/purchases/:id`,
    `/sales`, `/sales/new`, `/sales/:id`, `/payment-vouchers`, `/payment-vouchers/new`,
    `/receipt-vouchers`, `/receipt-vouchers/new`, `/transfers`, `/transfers/new`,
    `/stock`, `/ledger`, `/reports`

- [ ] **P0-T04** Add `redirect` guard to `app_router.dart`
  - Reads `SessionBloc` state from `get_it`
  - If `unauthenticated` and route is not `/login`: redirect to `/login`
  - If `authenticated` and route is `/login`: redirect to `/dashboard`
  - Permission check helper: given a required permission flag, return `/dashboard` if user lacks it

- [ ] **P0-T05** Register all singletons in `get_it`
  - `AuthRepositoryImpl` → `AuthRepository`
  - `SessionBloc`, `AuthBloc`
  - One registration file: `lib/src/services/service_locator.dart`

- [ ] **P0-T06** Call `setupServiceLocator()` in `main.dart` before `runApp`

**Checkpoint P0**: App boots, redirects unauthenticated users to `/login`, JWT token is injected automatically on every request.

---

## Phase 1 — Auth Module (Complete)
**Goal**: Full working login flow; JWT stored; session persists across hot restart.
**Touches**: `features/auth/` — all three layers

### Domain fixes

- [ ] **P1-T01** Update `AppUser` entity (`domain/entities/user.dart`)
  - Add `permissions` field: `final int permissions;` (bitmask of 7 flags)
  - Add permission helpers: `bool can(int flag) => permissions & flag != 0;`
  - Keep `id` as `String` (ObjectId hex)

- [ ] **P1-T02** Add use-cases under `domain/usecases/`
  - `LoginUseCase` — calls `AuthRepository.login`, stores JWT via `SecureStorageService`
  - `LogoutUseCase` — calls `AuthRepository.logout`, clears JWT
  - `CheckSessionUseCase` — reads stored JWT, calls `AuthRepository.checkAuthState`

### Data fixes

- [ ] **P1-T03** Replace `user_model.dart` with `@freezed` model
  ```dart
  @freezed
  class UserModel with _$UserModel {
    const factory UserModel({
      required String id,
      required String email,
      String? name,
      String? photoUrl,
      @Default(0) int permissions,
    }) = _UserModel;
    factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  }
  ```
  - `toEntity()` method: maps `UserModel` → `AppUser`

- [ ] **P1-T04** Run code generation: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **P1-T05** Update `AuthRepositoryImpl`
  - Use `UserModel.fromJson()` instead of manual field mapping
  - Store JWT token via `SecureStorageService` on successful login
  - Clear token on logout
  - Fix `id` mapping: use `data['_id']` (MongoDB ObjectId field name)

### Presentation fixes

- [ ] **P1-T06** Update `AuthBloc` to use `LoginUseCase` / `LogoutUseCase`
  - Remove direct `_repository` calls; inject use-cases instead
  - Remove `BuildContext` from events (violates Clean Architecture)
  - Navigation handled in screen via `BlocListener`, not inside Bloc

- [ ] **P1-T07** Build `LoginScreen` UI
  - Email + Password fields using `AppTextField`
  - Submit button using `AppButton`
  - `BlocListener` for state changes → navigate to `/dashboard` on success, show toast on error
  - "Forgot password?" link → `/forgot-password`

- [ ] **P1-T08** Build `ForgotPasswordScreen` UI
  - Email field, submit button
  - Success: show toast, navigate back to `/login`

- [ ] **P1-T09** Build `SignupScreen` UI (if user registration is enabled for ERP)
  - Name, email, password fields
  - Submit → navigate to `/dashboard`

- [ ] **P1-T10** Update `SessionListenerWrapper`
  - Listen to `SessionBloc`; on `unauthenticated` state → `context.go(AppRoutes.login)`

**Checkpoint P1**: Login → JWT stored → redirect to `/dashboard` (stub) → hot restart → still on `/dashboard` → logout → back to `/login`.

---

## Phase 2 — Shared ERP Infrastructure
**Goal**: Reusable ERP-level components used by every subsequent module.
**Touches**: `shared/`, `theme/`, new `shared/widgets/erp/`

- [ ] **P2-T01** ERP layout shell — `ERPShell` widget
  - Sidebar navigation (collapsible on small screens)
  - Top bar with user name, branch selector, logout button
  - Content area slot
  - Permission-aware nav items (hide items the user lacks permission for)

- [ ] **P2-T02** `DataTable` widget — `AppDataTable<T>`
  - Column definitions, sortable headers, pagination, loading skeleton
  - Used by: Materials, Suppliers, Customers, Purchases, Sales, etc.

- [ ] **P2-T03** `AppSearchBar` — debounced search input (reuse `Debouncer` from `utils/`)

- [ ] **P2-T04** `AppDropdown<T>` — generic searchable dropdown
  - Used for: selecting unit, category, supplier, customer, branch, material

- [ ] **P2-T05** `MoneyField` widget — numeric text field with currency formatting
  - Uses `input_formatters.dart` and `format_number.dart`

- [ ] **P2-T06** `InvoiceLineRow` widget — quantity + unit + price row for invoice screens

- [ ] **P2-T07** `StatusBadge` widget — colored badge for invoice/voucher status
  - States: `draft`, `submitted`, `cancelled`

- [ ] **P2-T08** `ConfirmDeleteDialog` — reusable delete confirmation dialog

- [ ] **P2-T09** `DashboardCard` widget — KPI card for dashboard (label + value + optional trend)

- [ ] **P2-T10** ERP color tokens in `color_schemes.dart`
  - Add semantic colors: `erp_positive` (green), `erp_negative` (red), `erp_neutral` (amber)

**Checkpoint P2**: `ERPShell` renders with sidebar; `AppDataTable` renders with dummy data and pagination.

---

## Phase 3 — Units of Measure
**Goal**: CRUD for units (كيلو, لتر, قطعة, etc.).
**Follows**: Auth done, shared widgets done.

```
lib/src/features/units/
├── data/
│   ├── models/unit_model.dart          (@freezed)
│   ├── datasources/unit_remote_ds.dart
│   └── repositories/unit_repo_impl.dart
├── domain/
│   ├── entities/unit.dart
│   ├── repositories/unit_repository.dart
│   └── usecases/
│       ├── get_units_usecase.dart
│       ├── create_unit_usecase.dart
│       ├── update_unit_usecase.dart
│       └── delete_unit_usecase.dart
└── presentation/
    ├── providers/units_cubit.dart
    ├── screens/units_screen.dart
    └── widgets/unit_form_dialog.dart
```

- [ ] **P3-T01** `Unit` entity: `id` (String), `name` (String), `abbreviation` (String)
- [ ] **P3-T02** `UnitModel` — `@freezed` + `fromJson`/`toJson`; `toEntity()`
- [ ] **P3-T03** `UnitRemoteDataSource` — GET `/units`, POST `/units`, PUT `/units/:id`, DELETE `/units/:id`
- [ ] **P3-T04** `UnitRepository` interface + `UnitRepositoryImpl`
- [ ] **P3-T05** Use-cases (get all, create, update, delete)
- [ ] **P3-T06** `UnitsCubit` — states: loading, loaded(List<Unit>), error
- [ ] **P3-T07** `UnitsScreen` — `AppDataTable` + "Add Unit" FAB
- [ ] **P3-T08** `UnitFormDialog` — name + abbreviation fields; create/edit mode
- [ ] **P3-T09** Register in `get_it`, add route `/units` to router with permission guard
- [ ] **P3-T10** Run `build_runner`

**Checkpoint P3**: List units from API, create a unit, edit it, delete it (with confirm dialog).

---

## Phase 4 — Categories
**Goal**: CRUD for product categories.
**Pattern**: Identical to Phase 3. Replace "unit" with "category".

```
lib/src/features/categories/
├── data/models/category_model.dart
├── data/datasources/category_remote_ds.dart
├── data/repositories/category_repo_impl.dart
├── domain/entities/category.dart
├── domain/repositories/category_repository.dart
├── domain/usecases/  (get, create, update, delete)
└── presentation/
    ├── providers/categories_cubit.dart
    ├── screens/categories_screen.dart
    └── widgets/category_form_dialog.dart
```

- [ ] **P4-T01** `Category` entity: `id`, `name`, `description` (nullable)
- [ ] **P4-T02–T09** Same pattern as Phase 3 tasks P3-T02 through P3-T09

**Checkpoint P4**: Full CRUD for categories.

---

## Phase 5 — Materials (Items)
**Goal**: CRUD for inventory items. First module that references lookups (unit + category).

```
lib/src/features/materials/
├── data/models/material_model.dart
├── data/datasources/material_remote_ds.dart
├── data/repositories/material_repo_impl.dart
├── domain/entities/material_item.dart
├── domain/repositories/material_repository.dart
├── domain/usecases/  (get all, get by id, create, update, delete, search)
└── presentation/
    ├── providers/materials_cubit.dart
    ├── screens/materials_screen.dart
    ├── screens/material_detail_screen.dart
    └── widgets/material_form.dart
```

- [ ] **P5-T01** `MaterialItem` entity
  - `id` (String), `name` (String), `code` (String), `unitId` (String), `categoryId` (String),
    `unitName` (String — denormalized for display), `categoryName` (String), `description` (String?)

- [ ] **P5-T02** `MaterialModel` — `@freezed` + `fromJson`

- [ ] **P5-T03** `MaterialRemoteDataSource`
  - GET `/materials` (with pagination + search query params)
  - GET `/materials/:id`
  - POST `/materials`
  - PUT `/materials/:id`
  - DELETE `/materials/:id`

- [ ] **P5-T04** Repository + use-cases

- [ ] **P5-T05** `MaterialsCubit` — paginated list state, search state

- [ ] **P5-T06** `MaterialsScreen`
  - `AppDataTable` (code, name, unit, category, actions)
  - `AppSearchBar` with debounce
  - "Add Material" button

- [ ] **P5-T07** `MaterialDetailScreen` — full detail + edit form
  - `AppDropdown` for unit (loads from `UnitsCubit`)
  - `AppDropdown` for category (loads from `CategoriesCubit`)

- [ ] **P5-T08** Register, route, permission guard

**Checkpoint P5**: Create a material, assign unit + category, search by name/code.

---

## Phase 6 — Suppliers
**Goal**: CRUD for suppliers. First contact/party module.

```
lib/src/features/suppliers/
├── data/models/supplier_model.dart
├── data/datasources/supplier_remote_ds.dart
├── data/repositories/supplier_repo_impl.dart
├── domain/entities/supplier.dart
├── domain/repositories/supplier_repository.dart
├── domain/usecases/  (get all, get by id, create, update, delete)
└── presentation/
    ├── providers/suppliers_cubit.dart
    ├── screens/suppliers_screen.dart
    └── widgets/supplier_form.dart
```

- [ ] **P6-T01** `Supplier` entity
  - `id`, `name`, `phone` (nullable), `address` (nullable), `notes` (nullable)
  - `balance` is NOT stored — computed from purchase/payment records

- [ ] **P6-T02–T07** Standard CRUD pattern (same as Phase 3)

**Checkpoint P6**: Full CRUD for suppliers.

---

## Phase 7 — Customers
**Goal**: CRUD for customers. Same pattern as Suppliers.

```
lib/src/features/customers/
└── ... (mirror of suppliers)
```

- [ ] **P7-T01** `Customer` entity: `id`, `name`, `phone`, `address`, `notes`
  - Balance computed from sales/receipt records — never stored
- [ ] **P7-T02–T07** Standard CRUD pattern

**Checkpoint P7**: Full CRUD for customers.

---

## Phase 8 — Branches
**Goal**: CRUD for branches. Referenced by all invoice + transfer modules.

```
lib/src/features/branches/
└── ... (standard pattern)
```

- [ ] **P8-T01** `Branch` entity: `id`, `name`, `location` (nullable), `isMain` (bool)
- [ ] **P8-T02–T07** Standard CRUD pattern
- [ ] **P8-T08** Branch selector in `ERPShell` top bar — stores active branch in `SessionBloc`

**Checkpoint P8**: Branches listed in sidebar dropdown; active branch persists across navigation.

---

## Phase 9 — Purchase Invoices
**Goal**: Create/view/submit purchase invoices with line items.
**Depends on**: Materials (P5), Suppliers (P6), Branches (P8), Auth (P1)

```
lib/src/features/purchases/
├── data/models/
│   ├── purchase_invoice_model.dart
│   └── purchase_line_model.dart
├── data/datasources/purchase_remote_ds.dart
├── data/repositories/purchase_repo_impl.dart
├── domain/entities/
│   ├── purchase_invoice.dart
│   └── purchase_line.dart
├── domain/repositories/purchase_repository.dart
├── domain/usecases/
│   ├── get_purchases_usecase.dart
│   ├── get_purchase_by_id_usecase.dart
│   ├── create_purchase_usecase.dart
│   └── submit_purchase_usecase.dart
└── presentation/
    ├── providers/purchases_cubit.dart
    ├── providers/purchase_form_cubit.dart
    ├── screens/purchases_screen.dart
    ├── screens/purchase_form_screen.dart
    └── screens/purchase_detail_screen.dart
```

- [ ] **P9-T01** `PurchaseLine` entity: `materialId`, `materialName`, `qty` (double), `unitPrice` (double), `total` (double, computed)
- [ ] **P9-T02** `PurchaseInvoice` entity
  - `id`, `number` (String), `date` (DateTime), `supplierId`, `supplierName`,
    `branchId`, `branchName`, `lines` (List<PurchaseLine>), `total` (double, computed),
    `status` (enum: draft/submitted/cancelled), `notes` (nullable)

- [ ] **P9-T03** `@freezed` models for both entities

- [ ] **P9-T04** `PurchaseRemoteDataSource`
  - GET `/purchases` (paginated, filterable by branch/supplier/date)
  - GET `/purchases/:id`
  - POST `/purchases` (create draft)
  - PUT `/purchases/:id/submit` (atomic submit — changes stock)
  - PUT `/purchases/:id/cancel`

- [ ] **P9-T05** Repository + use-cases

- [ ] **P9-T06** `PurchasesCubit` — list state with filters

- [ ] **P9-T07** `PurchasesScreen`
  - `AppDataTable` (number, date, supplier, branch, total, status)
  - Filter bar: branch, supplier, date range
  - "New Purchase" button

- [ ] **P9-T08** `PurchaseFormCubit` — manages dynamic line items list, running total
  - Add line, remove line, update qty/price, recompute total

- [ ] **P9-T09** `PurchaseFormScreen`
  - Header: supplier dropdown, branch dropdown, date picker, notes
  - Lines section: `InvoiceLineRow` per line, add/remove buttons
  - Footer: total display, "Save Draft" + "Submit" buttons

- [ ] **P9-T10** `PurchaseDetailScreen` — read-only view of submitted invoice

- [ ] **P9-T11** Route + permission guard

**Checkpoint P9**: Create purchase draft → add lines → submit → stock increases (verify via backend).

---

## Phase 10 — Sales Invoices
**Goal**: Create/submit sales invoices. Mirror of Phase 9 but references customers.
**Depends on**: Phase 9 pattern, Materials, Customers, Branches

```
lib/src/features/sales/
└── ... (mirror of purchases, customer instead of supplier)
```

- [ ] **P10-T01** `SaleLine` entity (same shape as `PurchaseLine`)
- [ ] **P10-T02** `SaleInvoice` entity — same as `PurchaseInvoice` but `customerId/customerName`
- [ ] **P10-T03–T11** Mirror Phase 9 tasks replacing "purchase/supplier" with "sale/customer"
- [ ] **P10-T12** Validate stock sufficiency before allowing submit (backend enforces; frontend shows error from `Either`)

**Checkpoint P10**: Create sale → submit → stock decreases; insufficient stock → clear error message.

---

## Phase 11 — Payment Vouchers
**Goal**: Record cash payments to suppliers.
**Depends on**: Suppliers (P6), Branches (P8)

```
lib/src/features/payment_vouchers/
├── data/models/payment_voucher_model.dart
├── data/datasources/payment_voucher_remote_ds.dart
├── data/repositories/payment_voucher_repo_impl.dart
├── domain/entities/payment_voucher.dart
├── domain/repositories/payment_voucher_repository.dart
├── domain/usecases/  (get all, get by id, create, submit)
└── presentation/
    ├── providers/payment_vouchers_cubit.dart
    ├── screens/payment_vouchers_screen.dart
    └── screens/payment_voucher_form_screen.dart
```

- [ ] **P11-T01** `PaymentVoucher` entity
  - `id`, `number`, `date`, `supplierId`, `supplierName`, `branchId`, `amount` (double),
    `notes` (nullable), `status` (draft/submitted)

- [ ] **P11-T02** `@freezed` model
- [ ] **P11-T03** Remote data source: GET (paginated), GET by id, POST, PUT `:id/submit`
- [ ] **P11-T04** Repository + use-cases
- [ ] **P11-T05** `PaymentVouchersCubit`
- [ ] **P11-T06** `PaymentVouchersScreen` — data table with filters
- [ ] **P11-T07** `PaymentVoucherFormScreen` — supplier, amount, date, notes, submit
- [ ] **P11-T08** Route + permission guard

**Checkpoint P11**: Create and submit a payment voucher; supplier balance decreases (verify via backend).

---

## Phase 12 — Receipt Vouchers
**Goal**: Record cash receipts from customers. Mirror of Phase 11.

```
lib/src/features/receipt_vouchers/
└── ... (mirror of payment_vouchers, customer instead of supplier)
```

- [ ] **P12-T01–T08** Mirror Phase 11 replacing "payment/supplier" with "receipt/customer"

**Checkpoint P12**: Create and submit a receipt voucher; customer balance decreases.

---

## Phase 13 — Transfers (Between Branches)
**Goal**: Move stock from one branch to another.
**Depends on**: Materials (P5), Branches (P8)

```
lib/src/features/transfers/
├── data/models/
│   ├── transfer_model.dart
│   └── transfer_line_model.dart
├── ...
└── presentation/
    ├── providers/transfers_cubit.dart
    ├── providers/transfer_form_cubit.dart
    ├── screens/transfers_screen.dart
    └── screens/transfer_form_screen.dart
```

- [ ] **P13-T01** `TransferLine` entity: `materialId`, `materialName`, `qty`
- [ ] **P13-T02** `Transfer` entity: `id`, `number`, `date`, `fromBranchId`, `fromBranchName`,
  `toBranchId`, `toBranchName`, `lines`, `status`, `notes`
- [ ] **P13-T03** Remote DS: GET, GET by id, POST, PUT `:id/submit` (atomic — decrements source, increments dest)
- [ ] **P13-T04** Repository + use-cases
- [ ] **P13-T05** `TransfersCubit` + `TransferFormCubit`
- [ ] **P13-T06** `TransfersScreen` + `TransferFormScreen`
- [ ] **P13-T07** Route + permission guard

**Checkpoint P13**: Transfer stock between branches; source branch stock decreases, destination increases.

---

## Phase 14 — Stock (Read-Only)
**Goal**: Display computed stock levels per material per branch.
**Depends on**: All invoice/transfer modules. Backend computes via aggregation.

```
lib/src/features/stock/
├── data/models/stock_entry_model.dart
├── data/datasources/stock_remote_ds.dart
├── data/repositories/stock_repo_impl.dart
├── domain/entities/stock_entry.dart
├── domain/repositories/stock_repository.dart
├── domain/usecases/get_stock_usecase.dart
└── presentation/
    ├── providers/stock_cubit.dart
    └── screens/stock_screen.dart
```

- [ ] **P14-T01** `StockEntry` entity: `materialId`, `materialName`, `branchId`, `branchName`, `qty` (double)
- [ ] **P14-T02** `StockModel` (`@freezed`)
- [ ] **P14-T03** Remote DS: GET `/stock` (filterable by branch, material, low-stock threshold)
- [ ] **P14-T04** Repository + use-case (read-only: no create/update/delete)
- [ ] **P14-T05** `StockCubit`
- [ ] **P14-T06** `StockScreen`
  - `AppDataTable` (material, branch, qty)
  - Filters: branch, category, low-stock toggle
  - Color-code low-stock rows with `erp_negative`

**Checkpoint P14**: Stock screen shows correct quantities reflecting all purchases, sales, and transfers entered so far.

---

## Phase 15 — Credit Ledger (Read-Only)
**Goal**: Display computed supplier/customer balances per party.

```
lib/src/features/ledger/
├── data/models/ledger_entry_model.dart
├── data/datasources/ledger_remote_ds.dart
├── data/repositories/ledger_repo_impl.dart
├── domain/entities/ledger_entry.dart
├── domain/repositories/ledger_repository.dart
├── domain/usecases/get_ledger_usecase.dart
└── presentation/
    ├── providers/ledger_cubit.dart
    └── screens/ledger_screen.dart
```

- [ ] **P15-T01** `LedgerEntry` entity: `partyId`, `partyName`, `partyType` (supplier/customer),
  `balance` (double), `lastTransactionDate` (DateTime?)
- [ ] **P15-T02** `LedgerModel` (`@freezed`)
- [ ] **P15-T03** Remote DS: GET `/ledger?type=supplier|customer` (computed by backend)
- [ ] **P15-T04** Repository + use-case (read-only)
- [ ] **P15-T05** `LedgerCubit`
- [ ] **P15-T06** `LedgerScreen`
  - Toggle: Suppliers / Customers
  - `AppDataTable` (name, balance, last transaction)
  - Click a party → drill-down to their transaction history

**Checkpoint P15**: Balances match the sum of invoices minus vouchers for each party.

---

## Phase 16 — Dashboard & Reports
**Goal**: KPI overview + printable/exportable reports.
**Depends on**: All modules complete.

```
lib/src/features/dashboard/
├── data/models/dashboard_summary_model.dart
├── data/datasources/dashboard_remote_ds.dart
├── data/repositories/dashboard_repo_impl.dart
├── domain/entities/dashboard_summary.dart
├── domain/repositories/dashboard_repository.dart
├── domain/usecases/get_dashboard_usecase.dart
└── presentation/
    ├── providers/dashboard_cubit.dart
    └── screens/dashboard_screen.dart

lib/src/features/reports/
└── presentation/
    ├── providers/reports_cubit.dart
    └── screens/reports_screen.dart
```

- [ ] **P16-T01** `DashboardSummary` entity
  - `totalSalesToday`, `totalPurchasesToday`, `lowStockCount`, `topMaterials` (List)

- [ ] **P16-T02** Dashboard remote DS: GET `/dashboard/summary?branchId=&from=&to=`

- [ ] **P16-T03** `DashboardScreen`
  - `DashboardCard` grid: Sales today, Purchases today, Low-stock items, Outstanding receivables, Outstanding payables
  - Date range picker
  - Branch filter

- [ ] **P16-T04** Reports screen — list of report types:
  - Stock report (by branch, by category, low-stock)
  - Sales report (by date, by customer, by material)
  - Purchase report (by date, by supplier, by material)
  - Credit ledger summary

- [ ] **P16-T05** Each report: fetch from API, render in `AppDataTable`, export to CSV (via browser download)

**Checkpoint P16**: Dashboard KPIs update in real-time with branch filter; at least one report exports to CSV.

---

## Phase 17 — Polish, Permissions & QA
**Goal**: Wire all 7 permission flags, handle edge cases, QA.

- [ ] **P17-T01** Define all 7 permission bit flags as constants in `AppUser`
  ```dart
  static const int canViewSales      = 1 << 0;  // 1
  static const int canEditSales      = 1 << 1;  // 2
  static const int canViewPurchases  = 1 << 2;  // 4
  static const int canEditPurchases  = 1 << 3;  // 8
  static const int canViewStock      = 1 << 4;  // 16
  static const int canEditMasters    = 1 << 5;  // 32  (units, categories, materials, suppliers, customers, branches)
  static const int isAdmin           = 1 << 6;  // 64
  ```

- [ ] **P17-T02** Apply permission guards to every route in `app_router.dart` using the constants above

- [ ] **P17-T03** Hide/disable sidebar nav items based on `user.permissions`

- [ ] **P17-T04** Add empty-state screens for: no data found, no permission, network error

- [ ] **P17-T05** Full manual QA walkthrough:
  - Login → navigate all modules → create purchase → submit → check stock → create sale → submit → check stock + ledger

- [ ] **P17-T06** Localization: add Arabic translation keys for all new screen titles, labels, error messages

- [ ] **P17-T07** Responsive audit: test all screens at 1024px, 768px, 375px

**Checkpoint P17**: All 15 modules functional, all permission flags enforced, Arabic/English working.

---

## Summary Table

| Phase | Module | Depends On | Status |
|---|---|---|---|
| 0 | Infrastructure Hardening | — | Not started |
| 1 | Auth (complete) | P0 | Not started |
| 2 | Shared ERP Widgets | P1 | Not started |
| 3 | Units of Measure | P2 | Not started |
| 4 | Categories | P2 | Not started |
| 5 | Materials | P3, P4 | Not started |
| 6 | Suppliers | P2 | Not started |
| 7 | Customers | P2 | Not started |
| 8 | Branches | P2 | Not started |
| 9 | Purchase Invoices | P5, P6, P8 | Not started |
| 10 | Sales Invoices | P5, P7, P8 | Not started |
| 11 | Payment Vouchers | P6, P8 | Not started |
| 12 | Receipt Vouchers | P7, P8 | Not started |
| 13 | Transfers | P5, P8 | Not started |
| 14 | Stock (read-only) | P9, P10, P13 | Not started |
| 15 | Credit Ledger (read-only) | P11, P12 | Not started |
| 16 | Dashboard & Reports | P14, P15 | Not started |
| 17 | Polish & QA | All | Not started |
