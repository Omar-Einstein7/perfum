# Full Execution Plan — "Ahmed Gaber Perfumes" System

> **Important note:** This document does **not** redefine any architectural decision. The architecture is fixed as you already specified it in `master-plan-perfume-shop.md` (Flutter Desktop + Bloc/Cubit + GetIt + Dio + go_router | Node.js/Express Layered | PostgreSQL | JWT+bcrypt). What's here is the **missing execution layer**: breaking each phase into small testable tasks, detailed API contracts, the full Bloc events/states list per feature, the offline-first design, the permission matrix, and a full test plan.

---

## Table of Contents

0. Assumptions that need your confirmation
1. Phase 0 — No data migration (Fresh Start)
2. Detailed execution plan (Backend + Flutter) — 6 phases, each with a clear Definition of Done
3. Detailed API contracts (Request/Response) for critical endpoints
4. Permission Matrix
5. Cross-cutting concerns
6. Full list of Bloc Events/States per feature
7. Full test matrix
8. Final consolidated checklist
9. Suggested timeline (Sprints)

---

## 0. Assumptions that need your confirmation

I built the plan on these assumptions — tell me if any is wrong and I'll adjust it:

| # | Assumption | If different |
|---|---|---|
| 1 | ✅ **Settled:** There is no legacy system to migrate at all. The system starts empty and the client enters everything himself (details in section 1) | — |
| 2 | Invoices need printing/PDF from the first release, not something deferred | If deferred: move it from Phase 3 to Phase 6 |
| 3 | ✅ **Settled:** The API will be hosted on a cloud/external host, each branch's stock is fully independent (no transfer between branches at all), and each branch has **only one device/POS** selling on it. This means the system is **fully offline-first and mathematically safe** — design details in the new section 5.5 | If the number of devices per branch grows beyond one, or the idea of inter-branch transfers comes back, we'll need to reopen the conflict-resolution topic |
| 4 | The actual number of branches right now is 2-3 (for seed-data purposes only) | Specify the real number |
| 5 | Reports (Excel export) aren't needed from Phase 1, can be deferred to Phase 6 | If needed earlier: we'll move part of it to Phase 3 |

I'll continue the plan based on the left-hand column (the default assumption); any correction from you will change one item only, not the whole plan.

---

## 1. Phase 0 — No Data Migration (Fresh Start)

> ✅ **Settled:** There is no data import from a legacy system at all. The system starts completely empty, and the client himself will enter everything (materials, customers, suppliers, branches, employees) directly through the new system's screens. No Excel, no migration script, no legacy Access system to deal with whatsoever.

### 1.0 Division of responsibility (who enters what, and when)

| Data | Who enters it | When | Note |
|---|---|---|---|
| **Branches and employees** | The client, directly from the system's screens | Phase 2 (as soon as the screens are ready) | Usually a small number, just minutes |
| **Categories and units** | The client, from the system's screens | Phase 2 | Simple initial setup |
| **Materials (with the three prices)** | The client, from the "Add/Edit Material" screen | Phase 2 | The client types the material name himself at that moment, so there's no messy legacy-data name-similarity problem to review |
| **Customers and suppliers** | The client, from the system's screens | Phase 2, or whenever they're actually needed (can be added "on the fly" during the first invoice/voucher for them) | No need to enter them all upfront if the count is large — the screen allows adding a new customer/supplier directly from within the invoice form itself if not found |
| **Opening stock quantity** | The client/staff in the shop, after an actual physical stock count | **The very last step before official go-live**, after all materials are fully entered | As agreed, the quantity changes daily, so it can't be entered long before actual go-live |

### 1.1 Impact on the rest of the plan
- **Top priority now shifts to the quality of the screens themselves**, not to a migration script. The "Add/Edit Material" and "Add Customer/Supplier" screens need to be **easy and fast enough that the client can enter a lot of data himself without fatigue or needing ongoing technical support from you**.
- The **"Bulk Opening Stock Entry"** screen (details in 1.2) is still very important even without migration, because it saves the client real time when doing the first stock count (instead of opening the full material screen for every single item just to enter a quantity).
- All form validation must produce **clear, direct Arabic messages** (not technical English messages), since the client is the one directly interacting with these screens without you.

### 1.2 "Bulk Opening Stock Entry" screen (client-facing)
A very simplified screen (separate from the full "Add/Edit Material" screen) whose only purpose is the initial stock count:
- A list of all materials already created (which the client entered himself beforehand), with an empty quantity field next to each one
- The client/employee goes through the list and fills in the actual quantity he has in that branch
- A "Save Count" button at the end sends all quantities at once as a single transaction on `material_branch_stock`
- **Key precondition:** this screen must not open at all until all materials are fully entered in the system (prices + categories), otherwise the client will find an empty or incomplete list.

---

## 2. Detailed Execution Plan

Each Phase here matches the same numbering as section 9 of `master-plan-perfume-shop.md`, but split into separate Backend/Flutter tasks + a clear Definition of Done (DoD) for each phase, so you can close a phase and move to the next one with confidence.

### Phase 1 — Foundation (Auth + Core Setup)

**Backend:**
- [ ] Init repo, ORM (Sequelize or Prisma — pick one before actually starting), env config (`.env` for DB creds + JWT secret)
- [ ] Migrations for all tables: `categories, units, branches, employees, materials, material_branch_stock, customers, suppliers, shifts` (the rest of the tables come in their related later phase)
- [ ] **Note:** the `branch_transfers` table has been **permanently removed** from the schema — each branch is fully independent, there is no stock transfer between branches at all (see assumption #3)
- [ ] Seed script: one main branch, one admin employee with all permissions set to `true`, base categories/units
- [ ] `POST /auth/login` (username+password → access token + refresh token), `POST /auth/refresh`
- [ ] `authMiddleware` (JWT check) + `permissionMiddleware(flagName)` (a reusable factory function for any endpoint)
- [ ] Unified global error handler (returns a fixed shape: `{ error: { code, message } }`)
- [ ] Request validation layer (Joi or Zod) on every endpoint from day one, not a later addition

**Flutter:**
- [ ] `core/di` (GetIt setup), `core/network` (DioClient + interceptor that injects the JWT + auto-refresh on 401)
- [ ] `core/router` (go_router skeleton + redirect guard: no session → `/login`)
- [ ] `core/theme` (full RTL + a suitable Arabic font)
- [ ] `core/errors` (`ServerFailure, NetworkFailure, ValidationFailure, AuthFailure`)
- [ ] Full `auth` feature (data/domain/presentation) + `flutter_secure_storage` for storing tokens and employee data (name, branch, permissions)

**DoD:** You can log in from mobile/desktop and land on `/dashboard` (empty), close the app and reopen it with the session still intact, and any protected endpoint returns 401 without a token.

---

### Phase 2 — Master Data

**Backend:**
- [ ] Full CRUD: `/branches`, `/employees`, `/categories`, `/units`, `/materials`, `/customers`, `/suppliers`
- [ ] `GET /materials/:id/stock` → returns the quantity across all branches (list of `{branch_id, branch_name, current_quantity}`)
- [ ] Validation: `username` unique, `category_id`/`unit_id` must actually exist (FK check before it hits the database, for a clear error message)
- [ ] When creating a new material: a single endpoint that takes the material data + `branch_id` + `opening_quantity` together, and performs an `INSERT` into both `materials` and `material_branch_stock` inside one transaction

**Flutter:**
- [ ] Features: `branches`, `employees`, `categories_units` (simple CRUD) — **the client enters these himself** (small numbers)
- [ ] Feature `materials`: the "Add/Edit Material" screen **exactly** as in section 1 of `forms-ui-plan.md` — **the client enters these himself, material by material**, so it needs to be fast and easy to use (logical tab order between fields, clear validation, a "Save and add another" option without returning to the list every time)
- [ ] "Materials Search" screen (section 4 in forms-ui-plan) with live filtering + 300ms debounce
- [ ] **"Bulk Opening Stock Entry"** screen (see details in 1.2) — a list of all ready materials with a quantity field for each, **filled in by the client/staff themselves after the physical stock count**, and it only opens as the last step before official go-live, not before

**DoD:** The client can, on his own, create a branch, an employee with different permissions, and a full new material (prices+category) with no technical help, then open the simplified stock-count screen, fill in each material's quantity for his branch, and save it all at once — and the quantity shows up only in that branch, not in others.

---

### Phase 3 — The Backbone: Shifts + Retail Sales Invoice

**Backend:**
- [ ] `stockService.js`: two functions `decrementStock(materialId, branchId, qty, dbClient)` and `incrementStock(...)` — using `SELECT ... FOR UPDATE` on the `material_branch_stock` row **inside the same transaction** as the invoice, throwing a clear `INSUFFICIENT_STOCK` error if the quantity isn't enough
- [ ] `/shifts/open`, `/shifts/close`, `GET /shifts/current?branchId=` — closing a shift computes `closing_balance` from the sum of the shift's cash invoices + `opening_balance`
- [ ] `POST /sales-invoices`:
  1. Confirm there's an open shift for that same employee/branch (otherwise return 409)
  2. Single transaction: create the invoice, create the line items, `decrementStock` for each item (and if `materials.is_bottle = true`, automatically add a second line for `empty_bottle_price`)
  3. **Totals (before discount/after discount/final) are computed on the server, never taken from the client** — this is the single most important safety rule in the whole invoice
  4. If `payment_method = credit` → automatically insert a `credit_ledger` entry linked to the same invoice
- [ ] `GET /sales-invoices?branchId=&from=&to=`

**Flutter:**
- [ ] Feature `shifts`: open/close a shift, and a router guard: `/sales/retail/new` cannot be opened without an open shift for that branch
- [ ] Feature `sales_retail` **complete, exactly** as in section 2 of `forms-ui-plan.md` (header, discounts, the shift section, line items, the three buttons)
- [ ] Handle the `INSUFFICIENT_STOCK` error in the UI with a clear message at save time, not before (since the quantity can change from another cashier at the same moment)

**DoD:** A full sale closes correctly: the invoice is recorded, `material_branch_stock` decreases by the right amount for the right branch, the shift closes with matching numbers, and attempting to sell more than available is rejected with a clear message. **A race-condition test is mandatory here** (see section 7).

---

### Phase 4 — Wholesale + Purchases

**Backend:**
- [ ] `/wholesale-invoices` — same logic as retail but without a shift check and without the empty-bottle logic, `unit_price` defaults from `wholesale_price`
- [ ] `/purchase-invoices` (+ `purchase_return`) — same transaction pattern but `incrementStock` instead of `decrementStock`

**Flutter:**
- [ ] Feature `sales_wholesale` — a **completely separate Bloc/Feature** from `sales_retail` (as agreed, not a toggle)
- [ ] Feature `purchases`

**DoD:** A purchase correctly increases stock; the wholesale invoice is completely separate in both code and UI from retail, and correctly uses the wholesale price.

---

### Phase 5 — Vouchers + Credit Ledger
> Note: inter-branch transfers have been fully removed from the plan (no stock transfer between branches at all, each branch is fully independent — see assumption #3).

**Backend:**
- [ ] `/payment-vouchers`, `/receipt-vouchers`
- [ ] `GET/POST /credit-ledger` with search by name/person/invoice number

**Flutter:**
- [ ] Features `payment_vouchers`, `receipt_vouchers`
- [ ] "Credit Search" screen (section 5 in forms-ui-plan) with the same live-filtering logic

**DoD:** Payment/receipt vouchers are recorded and correctly linked to the employee/branch, and work offline-first like all other operations.

---

### 5.5 — Technical Design for Offline-First (applies to every operation without exception)

Since each branch is fully independent and has only one device selling on it, any operation (sale, purchase, voucher, etc.) touches **only one row** of stock, and no conflict is mathematically possible. So the entire system can run offline-first with complete safety:

**Flutter (every device):**
- [ ] A local database (`drift` or `sqflite`) acting as a Local cache + write buffer for all tables written from that branch (invoices, line items, vouchers, credit)
- [ ] A local `sync_queue` table: every new operation is recorded in it with a `pending` status right at save time, regardless of internet availability
- [ ] Every operation has a `client_generated_uuid` generated on the device itself (not by the server) — this is the **idempotency key** that prevents duplication if an upload happens twice by mistake (e.g. the connection dropped mid-upload)
- [ ] A background sync worker: watches connectivity status, and whenever it finds a connection, uploads everything in `pending` in order, and updates the status to `synced` or `failed_retry`
- [ ] The screen shows a simple indicator (icon/color) of sync status: "all synced" / "some operations still pending" — without ever blocking the cashier from working
- [ ] The quantity shown at sale time = the local quantity after applying all local operations (even pending ones); there's no need to wait for a server response to display the quantity, since no other device is changing it

**Backend:**
- [ ] Every endpoint receiving a new operation must check the `client_generated_uuid` first (if it already exists, ignore the request and return success, instead of duplicating the entry)
- [ ] The `SELECT ... FOR UPDATE` transaction pattern is still in place as an extra layer of protection (defense in depth), but it's now a final confirmation rather than an actually expected conflict point

**DoD:** Disconnect a branch device from the internet for a full day, perform several sales locally, reconnect, and confirm that all operations were uploaded in the correct order with no duplication and none lost.

---

### Phase 6 — Reports + Final Hardening

**Backend:**
- [ ] `/reports/stock?branchId=`, `/reports/sales?branchId=&from=&to=`, `/reports/statement?customerId=|supplierId=`
- [ ] Rate limiting on `/auth/login` (e.g. 5 attempts/minute per IP)
- [ ] Full review: every endpoint checks a real permission on the server (not just hiding a button in the UI)
- [ ] Backup: a daily scheduled `pg_dump` + an actual restore test (not just running the command — you need to confirm the restore actually works)

**Flutter:**
- [ ] Feature `reports_dashboard`: full stock per branch, sales/purchases over a period, customer/supplier statement, branch comparison

**DoD:** The full integration scenario (sale → return → report, including a full offline scenario) produces 100% matching numbers across all screens.

---

## 3. Detailed API Contracts (Request/Response)

### `POST /auth/login`
```json
// Request
{ "username": "ahmed_gaber", "password": "••••••" }

// Response 200
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "employee": {
    "id": 3, "fullName": "Ahmed Gaber", "branchId": 1,
    "permissions": { "canSell": true, "canManageVouchers": false, "canViewReports": true }
  }
}

// Response 401
{ "error": { "code": "INVALID_CREDENTIALS", "message": "Invalid login credentials" } }
```

### `POST /materials` (with opening stock)
```json
// Request
{
  "materialName": "White Musk Perfume",
  "categoryId": 2, "unitId": 1,
  "purchasePrice": 45.0, "retailPrice": 90.0, "wholesalePrice": 70.0,
  "isBottle": true, "emptyBottlePrice": 5.0,
  "openingStock": { "branchId": 1, "quantity": 500 }
}

// Response 201
{ "id": 118, "materialName": "White Musk Perfume", "...": "..." }
```

### `POST /sales-invoices` (the heart of the system)
```json
// Request — note: neither employeeId nor branchId are ever sent as free text by the client;
// employeeId comes from the JWT, not the body, and branchId comes from the user's selection in the form
{
  "branchId": 1,
  "shiftId": 44,
  "opType": "sale",
  "paymentMethod": "cash",
  "customerPersonName": "Walk-in customer",
  "customerPhone": "01000000000",
  "giftDiscount": 10, "specialDiscount": 0,
  "items": [
    { "materialId": 118, "quantity": 50, "unitPrice": 90.0, "cardDiscount": 0, "giftDiscount": 0, "sellDiscountPct": 0, "notes": null }
  ]
}

// Response 201
{
  "id": 5001, "invNumber": 5001,
  "beforeDiscount": 4500.0, "afterGiftDiscount": 4490.0, "finalTotal": 4490.0,
  "items": [ { "id": 9001, "materialId": 118, "quantity": 50 }, { "id": 9002, "materialId": 118, "isEmptyBottleLine": true, "quantity": 50, "unitPrice": 5.0 } ]
}

// Response 409 (insufficient stock)
{ "error": { "code": "INSUFFICIENT_STOCK", "message": "Available branch quantity is less than requested", "available": 20 } }

// Response 409 (no open shift)
{ "error": { "code": "NO_OPEN_SHIFT", "message": "You must open a shift first" } }
```

### `POST /credit-ledger` (manual entry from the Credit screen)
```json
// Request
{ "companyOrPersonName": "Al-Noor Distribution Co.", "amount": 1500.0, "notes": "First installment", "relatedInvoiceNumber": 5001 }

// Response 201
{ "id": 220, "companyOrPersonName": "Al-Noor Distribution Co.", "amount": 1500.0 }
```

---

## 4. Permission Matrix

| Endpoint | Required permission |
|---|---|
| `POST /sales-invoices`, `/wholesale-invoices` | `can_sell` |
| `POST /purchase-invoices` | `can_manage_suppliers` |
| `POST /payment-vouchers`, `/receipt-vouchers` | `can_manage_vouchers` |
| `POST/PATCH /employees` | `can_manage_users` |
| `GET /reports/*` | `can_view_reports` or `can_view_reports2` (depending on the report type) |
| `GET /customers`, `/suppliers` (full data) | `can_view_info` |

> Golden rule: **every one of these permissions is checked in the server-side middleware, not just by hiding the button in Flutter.**

---

## 5. Cross-cutting Concerns

1. **Idempotency protection**: since the system is offline-first and every operation is saved locally and uploaded later, any endpoint receiving a new operation must check the `client_generated_uuid` first and ignore any duplicate — this replaces the old race-condition handling now that each branch is confirmed to run on a single device.
2. **Computed totals**: any `total`/`finalTotal` is computed on the server from the invoice's line items + discounts; it **must never** accept a ready-made number from the client (to prevent tampering from a modified UI).
3. **Printing**: if invoices need PDF printing (see assumption #2), consider a library like `pdfkit` on the server (an endpoint that returns a ready PDF) instead of generating it in Flutter, to guarantee the same layout regardless of the device.
4. **RTL and number formatting**: make sure numbers (quantity/price) are displayed LTR within an RTL line (a common issue in Flutter RTL themes).
5. **Audit trail**: if the shop needs to know "who changed this price and when," consider adding a simple `audit_log` table (`table_name, record_id, action, employee_id, changed_at, old_value, new_value`) — not mandatory, but saves a lot of time if a dispute happens later.
6. **Backups**: a daily `pg_dump` + an actual restore test once a month, not just running the command and assuming it works.

---

## 6. Full List of Bloc Events/States per Feature

### `AuthBloc`
- Events: `LoginSubmitted`, `LogoutRequested`, `SessionRestoreRequested`
- States: `AuthInitial`, `AuthLoading`, `AuthAuthenticated(employee)`, `AuthFailure(message)`

### `MaterialFormBloc`
- Events: `MaterialFormSubmitted`, `MaterialCategoryChanged`, `MaterialUnitChanged`, `MaterialIsBottleToggled`, `MaterialBranchSelectedForOpeningStock`
- States: `MaterialFormInitial`, `MaterialFormValid/Invalid`, `MaterialFormSubmitting`, `MaterialFormSuccess`, `MaterialFormFailure`

### `SalesRetailBloc` (the most complex)
- Events: `SalesInvoiceStarted`, `SalesInvoiceBranchChanged` (reloads the available quantity for every item currently in the cart), `SalesInvoiceItemAdded`, `SalesInvoiceItemRemoved`, `SalesInvoiceItemQuantityChanged`, `SalesInvoiceItemPriceOverridden`, `SalesInvoiceDiscountChanged`, `SalesInvoiceCreditToggled` (opens a nested `credit_ledger` form), `SalesInvoiceSubmitted`
- States: `SalesInvoiceLoading`, `SalesInvoiceItemsUpdated(items, computedTotals)`, `SalesInvoiceSubmitting`, `SalesInvoiceSuccess(invoiceId)`, `SalesInvoiceFailure(code, message)` — the UI must distinguish between `INSUFFICIENT_STOCK`, `NO_OPEN_SHIFT`, and any generic error

### `WholesaleInvoiceBloc`
- Same structure as `SalesRetailBloc` but without the shift/empty-bottle events (a completely separate Bloc, as agreed)

### `ShiftBloc`
- Events: `ShiftOpenRequested(openingBalance)`, `ShiftCloseRequested`, `ShiftCurrentRequested`
- States: `ShiftNone` (no open shift → blocks entry into a sales invoice), `ShiftOpen(shift)`, `ShiftClosing`, `ShiftClosed(summary)`

### `MaterialsSearchBloc` / `CreditSearchBloc`
- Events: `SearchQueryChanged` (with a 300ms debounce inside the Bloc, or via `rxdart`'s debounceTime on the Stream)
- States: `SearchLoading`, `SearchResultsLoaded(list)`, `SearchEmpty`

---

## 7. Full Test Matrix

| Module | Scenarios to cover |
|---|---|
| Sync (Offline Sync) | Disconnect the device, perform several sales locally, reconnect, confirm all operations upload in the correct order with no duplication / attempt to upload the same `client_generated_uuid` twice (idempotency) — the server must ignore it rather than duplicate the entry |
| Shift | Opening a shift while a previous one for the same branch/employee isn't closed (rejected) / closing a shift and the numbers matching the actual sum of invoices |
| Retail invoice | The empty bottle line is added automatically when `is_bottle=true` and not added when false / the server-computed total ignores any tampered number sent by the client / selling more than the locally available quantity is rejected in the UI even before it's sent to the server |
| Wholesale invoice | The price comes from `wholesale_price` not `retail_price` / no shift check applies to it |
| Credit | An invoice with `payment_method=credit` automatically creates a `credit_ledger` record correctly linked to the invoice number |
| Permissions | An employee without `can_sell` attempting `POST /sales-invoices` → 403 even if the button is hidden in the UI |
| Security | 6 consecutive failed login attempts → rate limiting blocks the 7th attempt |
| End-to-End | Sale → sales return → stock report → final numbers match across all screens, even if part of the operations happened offline and synced later |

---

## 8. Final Consolidated Checklist (Master Plan + additions)

- [ ] Every table in the schema has an actual migration (not just ready SQL) — **without** `branch_transfers` (permanently removed)
- [ ] `materials` and their prices are **centralized and shared** across all branches, and `material_branch_stock` is the only thing that differs per branch
- [ ] `material_branch_stock` is only ever updated **inside a transaction**; no code path modifies it directly from the UI
- [ ] `employee_id` and `branch_id` always come from the session/JWT, never manual input in any form
- [ ] Retail and wholesale are completely separate features (code, Bloc, routes)
- [ ] The empty-bottle logic is active in the material screen and in the retail invoice line items only
- [ ] Opening a new sales invoice is impossible without an open shift for that same branch
- [ ] All financial totals are computed server-side, with zero trust in numbers coming from the client
- [ ] Every endpoint checks a real `permissions` flag server-side
- [ ] All passwords are bcrypt-hashed
- [ ] All quantities are `numeric`, not `integer`
- [ ] Rate limiting on `/auth/login`
- [ ] Local DB + Sync Queue running on every device, and every operation has a `client_generated_uuid` for idempotency
- [ ] An actual offline test (disconnect for a full day, sell locally, reconnect, confirm everything uploads without duplication) has actually been done, not just theorized
- [ ] Daily backups + an actual restore test

---

## 9. Suggested Timeline (Sprints)

> Assumption: one full-time full-stack developer. If the team is larger, phases can run in parallel (e.g. Backend and Flutter for the same phase at the same time instead of sequentially).

| Sprint | Approx. duration | Content |
|---|---|---|
| 0 | 1-2 days | Environment setup only (no data migration) |
| 1 | 1 week | Phase 1 — Auth + Core |
| 2 | 1 week | Phase 2 — Master Data |
| 3 | 2 weeks | Phase 3 — Shifts + Retail Invoice (the most complex, allocate extra testing time) |
| 4 | 1 week | Phase 4 — Wholesale + Purchases |
| 5 | 1 week | Phase 5 — Vouchers + Credit + the full Offline Sync design |
| 6 | 1 week | Phase 6 — Reports + Hardening + full E2E testing |

**Total estimate: 6-7 weeks** for one dedicated developer (no Phase 0, since it's been fully eliminated).