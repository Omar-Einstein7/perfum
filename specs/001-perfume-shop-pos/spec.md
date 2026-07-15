# Feature Specification: Perfume Shop POS & Management System

**Feature Branch**: `001-perfume-shop-pos`

**Created**: 2026-07-15

**Status**: Draft

**Input**: User description: "Build a perfume shop management system with employee login with per-branch permissions; master data management; simplified opening-stock count screen; shift open/close tied to sales invoices; retail sales invoice with automatic empty-bottle line item logic; fully separate wholesale sales invoice; purchase invoices and purchase returns; payment and receipt vouchers with a credit ledger; full offline operation with background sync; reports for stock, sales, and customer/supplier statements."

## Clarifications

### Session 2026-07-15

- Q: Session timeout & re-auth behavior when offline → A: Session persists indefinitely while shift is open; no expiry. Logout only on explicit shift close or app exit.
- Q: Sync trigger mechanism → A: Automatic — sync on connectivity change (connectivity listener) plus periodic polling every 60 seconds while online.
- Q: Tax/VAT rate and inclusion → A: 14% VAT, tax-inclusive pricing; VAT shown as separate line on invoice for information only.
- Q: Multi-device concurrency per branch → A: Single device per branch; no concurrent offline writes possible.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Employee Login & Branch Session (Priority: P1)

An employee with assigned branch permissions logs in, sees only data relevant
to their branch, and opens a work shift to start transacting.

**Why this priority**: Every other operation depends on authentication and
branch-scoped access. No transaction can proceed without an active shift.

**Independent Test**: Can be tested by logging in as an employee for a specific
branch, verifying the dashboard only shows that branch's data, and opening a
shift.

**Acceptance Scenarios**:

1. **Given** an employee account assigned to Branch A with role "cashier",
   **When** the employee logs in with correct credentials,
   **Then** the system loads the dashboard for Branch A only and the
   employee's name and role are displayed.
2. **Given** an employee logged into Branch A,
   **When** the employee opens a new shift,
   **Then** a shift record is created with start time, starting employee, and
   opening cash balance, and the system enters transaction mode.
3. **Given** an employee logged into Branch A with an active shift,
   **When** the employee closes the shift,
   **Then** the shift record is finalized with end time, closing cash balance,
   and a summary of all transactions during the shift.
4. **Given** an employee has an active shift,
   **When** another shift is attempted to be opened,
   **Then** the system rejects it with a clear message that a shift is already
   open.
5. **Given** an employee from Branch A tries to view Branch B data,
   **When** any data access is attempted,
   **Then** the system enforces branch-scoped permissions and returns only
   Branch A data.

---

### User Story 2 - Master Data Management (Priority: P1)

A manager can create and manage branches, employees, categories, units, and
materials (each with purchase price, retail price, and wholesale price).

**Why this priority**: All transactions (sales, purchases, stock) reference
master data. Without materials, units, and pricing, no invoice can be created.

**Independent Test**: A manager can log in, add a material with three price
tiers, assign it to a category, and verify it appears in the product catalog.

**Acceptance Scenarios**:

1. **Given** a manager logged in,
   **When** they add a new material "Oud Royal" in category "Oriental" with
   unit "ml", purchase price 50 EGP, retail price 150 EGP, wholesale price
   100 EGP,
   **Then** the material is saved and immediately available in the product
   catalog for all branches.
2. **Given** a manager edits an existing material's retail price,
   **When** the change is saved,
   **Then** all new retail invoices use the updated price; historical
   invoices remain unchanged.
3. **Given** a manager deactivates a material,
   **When** a cashier attempts to select it in a new invoice,
   **Then** the material does not appear in the active product list.
4. **Given** a manager manages branches,
   **When** they add a new branch,
   **Then** the branch appears in the branch selection list for employee
   assignment.
5. **Given** a manager assigns an employee to a branch with role "cashier",
   **When** that employee logs in,
   **Then** they can only transact for their assigned branch.
6. **Given** an employee is assigned to a branch,
   **When** the manager changes the employee's branch or deactivates them,
   **Then** the change takes effect on the employee's next login.

---

### User Story 3 - Retail Sales Invoice with Empty Bottle Logic (Priority: P1)

A cashier can create a retail sales invoice, adding line items with quantities
(including fractional quantities like 0.5). When a perfume is sold as a refill
bottle, the system automatically adds an empty-bottle line item. The invoice
prints with all amounts in Arabic.

**Why this priority**: Retail sales are the core revenue-generating
transaction. Offline-first ensures sales never stop when internet is down.

**Independent Test**: A cashier with an open shift can add a customer, select
a material, enter a quantity, see the empty-bottle line auto-added, and
finalize the invoice — all while the device is in airplane mode.

**Acceptance Scenarios**:

1. **Given** an active shift for the branch,
   **When** a cashier creates a new retail invoice, selects a material,
   enters quantity "1.5",
   **Then** the line item shows material name, quantity 1.5, unit price
   (retail price from master data), subtotal calculated server-authoritatively
   on sync, and a separate empty-bottle line item is auto-added with a
   nominal charge of 5 EGP.
2. **Given** a retail invoice with 3 line items,
   **When** the cashier reviews the invoice before finalizing,
   **Then** the system displays the before-discount total, any discount
   amount, after-discount total, and final total — all in EGP.
3. **Given** a cashier finalizes a retail invoice while offline,
   **When** the invoice is saved,
   **Then** it is stored locally with a `client_generated_uuid`, and the
   inventory for each material sold is deducted from the local stock count.
4. **Given** the device reconnects to the internet,
   **When** the background sync runs,
   **Then** the offline invoice is uploaded to the server using its
   `client_generated_uuid` for idempotency; totals are computed
   server-side; stock is confirmed server-side.
5. **Given** a cashier tries to sell a deactivated or out-of-stock material,
   **When** the quantity is entered,
   **Then** the system warns the cashier with a clear Arabic message that
   the item is unavailable or low in stock (based on local stock data).

---

### User Story 4 - Wholesale Sales Invoice (Priority: P2)

A cashier or wholesale operator can create a wholly separate wholesale sales
invoice with different pricing (wholesale price tier) and a different invoice
layout.

**Why this priority**: Wholesale customers have different pricing, often buy
in larger quantities, and need a distinct invoice format per constitutional
requirement.

**Independent Test**: A wholesale operator can create a wholesale invoice with
a customer selected, add line items at wholesale prices, apply a bulk
discount, and finalize it — visible only in the wholesale route.

**Acceptance Scenarios**:

1. **Given** a wholesale operator with an active shift,
   **When** they navigate to the wholesale invoice screen (separate route
   from retail),
   **Then** the system displays materials with wholesale prices, not retail
   prices.
2. **Given** a wholesale invoice with a customer selected,
   **When** items are added at wholesale prices,
   **Then** the before-discount total, discount, after-discount total, and
   final total are displayed.
3. **Given** a wholesale invoice is saved offline,
   **When** it syncs to the server,
   **Then** the server validates all totals and updates wholesale-specific
   stock and customer credit ledger.

---

### User Story 5 - Purchase Invoice & Purchase Returns (Priority: P2)

A manager or purchasing employee can create purchase invoices to record
incoming stock from suppliers and process purchase returns.

**Why this priority**: Purchasing is the supply-side counterpart to sales.
Without it, stock cannot be replenished and inventory will be inaccurate.

**Independent Test**: A manager can create a purchase invoice for 10 units of
"Oud Royal" at cost, verify stock increases by 10, then create a purchase
return for 2 units and verify stock decreases by 2.

**Acceptance Scenarios**:

1. **Given** a logged-in employee with purchasing permissions,
   **When** they create a purchase invoice selecting a supplier, adding line
   items with quantity and purchase price,
   **Then** the invoice is saved locally and the branch stock for each
   material increases by the purchased quantity.
2. **Given** a purchase invoice exists,
   **When** the user creates a purchase return referencing the original
   invoice,
   **Then** the return is recorded and the branch stock decreases by the
   returned quantity.
3. **Given** a purchase invoice is created offline,
   **When** it syncs,
   **Then** the server validates the supplier account, prices, and updates
   the supplier's ledger.

---

### User Story 6 - Opening Stock Count (Priority: P2)

A manager can perform a simplified opening stock count to set initial
inventory levels for a branch.

**Why this priority**: Without initial stock levels, the system cannot track
inventory or enforce stock availability checks.

**Independent Test**: A manager can enter opening stock counts for 3
materials, save them, and verify the branch stock report reflects those
counts.

**Acceptance Scenarios**:

1. **Given** a branch with no stock data,
   **When** a manager opens the opening stock count screen,
   **Then** the system displays a list of all active materials with a field
   to enter the opening quantity for each.
2. **Given** the manager enters quantities "10 ml", "5.5 ml", "0" for three
   materials,
   **When** they save the opening stock,
   **Then** each material's branch stock is set to the entered quantity.
3. **Given** opening stock has already been entered for a branch,
   **When** a manager opens the screen again,
   **Then** existing quantities are pre-filled and can be adjusted with an
   audit trail.

---

### User Story 7 - Payment & Receipt Vouchers with Credit Ledger (Priority: P3)

A cashier can record payment vouchers (money going out to suppliers) and
receipt vouchers (money coming in from customers). Each customer and supplier
has a running credit ledger.

**Why this priority**: Credit tracking is essential for wholesale customers
who buy on credit and suppliers who are paid on terms.

**Independent Test**: A cashier can create a receipt voucher for a customer
payment, verify the customer's credit balance decreases, and the payment
appears in the customer statement.

**Acceptance Scenarios**:

1. **Given** a customer has an outstanding credit balance,
   **When** a receipt voucher is created for that customer,
   **Then** the voucher records the payment amount, and the customer's
   credit balance decreases by that amount.
2. **Given** a supplier is owed money,
   **When** a payment voucher is created for that supplier,
   **Then** the voucher records the payment, and the supplier's balance
   decreases.
3. **Given** a receipt or payment voucher is created offline,
   **When** it syncs,
   **Then** the server validates and updates the corresponding ledger.

---

### User Story 8 - Reports (Priority: P3)

Managers can view reports for current stock levels by branch, sales summaries
(per shift, per day, per material), and customer/supplier statements.

**Why this priority**: Reports provide the business intelligence needed to
make operational decisions.

**Independent Test**: A manager can open the stock report, see current stock
levels for all materials, then open a sales summary for today and see
yesterday's comparison.

**Acceptance Scenarios**:

1. **Given** a manager logged in,
   **When** they open the stock report,
   **Then** the report shows each material with current branch stock, unit,
   and a "low stock" indicator when stock falls below a configurable
   threshold.
2. **Given** a manager views the sales report,
   **When** they select a date range,
   **Then** the report shows total sales count, total revenue, top-selling
   materials, and a breakdown by retail vs wholesale — all in Arabic.
3. **Given** a manager opens a customer statement,
   **When** they select a customer,
   **Then** the statement shows all invoices, credit sales, payments, and
   the current balance chronologically.
4. **Given** a manager opens a supplier statement,
   **When** they select a supplier,
   **Then** the statement shows all purchase invoices, returns, payments,
   and the current balance.

---

### Edge Cases

- What happens when a shift is closed but an offline invoice from that shift
  syncs later? The invoice is accepted and attributed to the closed shift
  with a timestamp note.
- How does the system handle a material that is deleted after being used in a
  transaction? Historical invoices retain the material name and price at time
  of transaction; the material is soft-deactivated, not hard-deleted.
- What happens if the same material is sold offline and stock runs out before
  the invoice syncs? Local stock can go to zero but not negative; the cashier
  sees a low-stock warning before finalizing. The server validates final stock
  on sync.
- How are empty bottles tracked if a customer brings their own bottle? The
  empty-bottle line is optional — cashier can remove or adjust it per line
  item.
- What happens if a payment voucher exceeds the outstanding credit? The system
  warns but allows it (overpayment becomes a credit on the supplier's
  account).
- How does the system handle a device that has been offline for a week? The
  sync queue retries with exponential backoff; the server rejects invoices
  for materials that are now deactivated or out of stock server-side.
- What happens if a purchase return references an invoice that hasn't synced
  yet? The return is queued locally and processed on sync when both records
  are available.
- What if a cashier closes a shift without syncing pending invoices? The shift
  closes locally; pending invoices are flagged as "un-synced" and sync when
  connectivity returns.
- What happens if the app is closed and reopened mid-shift while offline? The
  shift resumes automatically; session state is restored from local storage.
  No re-login required.
- How are fractional quantities displayed? Quantities display with up to 3
  decimal places (e.g., "1.500 ml") in Arabic locale.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST authenticate employees using email/employee code and
  password, returning a secure session token that encodes the employee's
  identity, branch, and role.
- **FR-002**: System MUST enforce branch-scoped data access — every query and
  write is filtered by the authenticated employee's `branch_id`.
- **FR-003**: System MUST support roles with configurable permissions
  (manager, cashier, wholesale operator, viewer).
- **FR-004**: Employees MUST be able to open and close shifts; only one active
  shift per branch at a time.
- **FR-005**: Shift close MUST produce a summary of all transactions, opening
  cash, closing cash, and any discrepancies.
- **FR-006**: System MUST allow management of branches (add, edit, deactivate).
- **FR-007**: System MUST allow management of employees with assignment to a
  branch and a role.
- **FR-008**: System MUST allow management of categories (add, edit,
  deactivate).
- **FR-009**: System MUST allow management of units of measure (add, edit,
  deactivate).
- **FR-010**: System MUST allow management of materials, each with: name,
  category, unit, purchase price, retail price, wholesale price, and active
  status.
- **FR-011**: Prices MUST be stored as numeric values with up to 2 decimal
  places.
- **FR-012**: Quantities MUST be stored as numeric values (not integers)
  supporting up to 3 decimal places.
- **FR-013**: Opening stock count MUST allow entering initial quantities for
  each material per branch.
- **FR-014**: Once opening stock is saved, subsequent adjustments MUST
  maintain an audit trail.
- **FR-015**: Retail sales invoices MUST have a completely separate screen
  and data flow from wholesale sales invoices — they are never merged via a
  toggle or tab.
- **FR-016**: Retail invoice MUST display a before-discount total, discount
  field (percentage or fixed), after-discount total, and final total with
  tax if applicable.
- **FR-017**: Retail invoice MUST automatically add an empty-bottle line item
  (configurable fixed charge) for each perfumery material sold.
- **FR-018**: The empty-bottle line item MUST be removable or adjustable by the
  cashier per invoice line.
- **FR-019**: Wholesale sales invoices MUST use wholesale price tier from
  master data.
- **FR-020**: All invoice totals MUST be computed server-side on sync; client
  display totals are provisional.
- **FR-021**: Every write operation MUST generate a `client_generated_uuid`
  before saving locally.
- **FR-022**: Every write MUST be saved to a local `sync_queue` immediately;
  the UI MUST NOT wait for server confirmation.
- **FR-023**: A background sync service MUST process the `sync_queue` on
  connectivity change and poll every 60 seconds while online, using
  `client_generated_uuid` for idempotency.
- **FR-024**: Purchase invoices MUST record supplier, date, line items
  (material, quantity, purchase price), and total.
- **FR-025**: Purchase returns MUST reference the original purchase invoice and
  reduce branch stock accordingly.
- **FR-026**: Payment vouchers MUST record amount paid to a supplier, date,
  reference, and optionally link to specific invoices.
- **FR-027**: Receipt vouchers MUST record amount received from a customer,
  date, reference, and optionally link to specific invoices.
- **FR-028**: System MUST maintain a running credit ledger for each customer
  (balance = sum of credit invoices - sum of receipts).
- **FR-029**: System MUST maintain a running credit ledger for each supplier
  (balance = sum of purchases - sum of payments).
- **FR-030**: Stock report MUST show current quantity per material per branch
  with a configurable low-stock threshold indicator.
- **FR-031**: Sales report MUST show total sales, count, top materials, and
  retail/wholesale breakdown for a selected date range.
- **FR-032**: Customer statement MUST show all invoices, payments, and current
  balance chronologically.
- **FR-033**: Supplier statement MUST show all purchase invoices, returns,
  payments, and current balance chronologically.
- **FR-034**: All user-facing messages, labels, error messages, and report
  titles MUST be in clear Arabic.
- **FR-035**: The system MUST display error messages in Arabic when
  operations fail (offline queue full, sync conflict, stock insufficient
  on server, etc.).

### Key Entities

- **Employee**: Person who uses the system. Has id, name, email/code, password
  hash, assigned branch, role, active status.
- **Branch**: Physical shop location. Has id, name, address, active status.
  Each branch has its own independent stock and financial records.
- **Role**: Permission set (manager, cashier, wholesale operator, viewer).
  Defines which screens and actions are accessible.
- **Category**: Product grouping (e.g., Oriental, Western, Oud). Has id, name,
  active status.
- **Unit**: Unit of measure (e.g., ml, gram, piece). Has id, name, symbol.
- **Material**: Sellable product. Has id, name, category, unit, purchase price,
  retail price, wholesale price, active status, low-stock threshold.
- **Shift**: Work session at a branch. Has id, branch, employee, opened_at,
  closed_at, opening_cash, closing_cash, status (open/closed).
- **Sales Invoice (Retail)**: Customer-facing sale at retail prices. Has id,
  `client_generated_uuid`, branch, shift, items (material, qty, unit price,
  subtotal, empty-bottle flag), discount, totals, created_at, synced_at.
- **Sales Invoice (Wholesale)**: Customer-facing sale at wholesale prices.
  Same structure as retail but uses wholesale pricing and separate route.
- **Purchase Invoice**: Supplier supply record. Has id,
  `client_generated_uuid`, branch, supplier, items (material, qty, purchase
  price), total, created_at, synced_at.
- **Purchase Return**: Return of goods to supplier. Has id, original invoice
  reference, items, reason, created_at.
- **Payment Voucher**: Money paid to supplier. Has id, supplier, amount, date,
  reference, linked invoices.
- **Receipt Voucher**: Money received from customer. Has id, customer, amount,
  date, reference, linked invoices.
- **Customer**: Buyer (retail or wholesale). Has id, name, phone, address,
  type (retail/wholesale), opening balance, active status.
- **Supplier**: Vendor of materials. Has id, name, phone, address, opening
  balance, active status.
- **Customer/Supplier Ledger**: Running balance record. Has id, party
  (customer/supplier), transaction reference, debit, credit, balance after.
- **Sync Queue**: Offline-write buffer. Has id, `client_generated_uuid`,
  operation type, payload (JSON), created_at, status (pending/synced/failed),
  retry_count.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An employee can complete the full login-to-first-invoice flow in
  under 2 minutes without training.
- **SC-002**: A retail invoice with 5 line items is created and saved locally
  in under 10 seconds even without internet.
- **SC-003**: All offline invoices sync successfully when connectivity is
  restored, with zero data loss and no duplicates (verified by
  `client_generated_uuid` uniqueness).
- **SC-004**: A branch manager can add a new material and create a purchase
  invoice for it in under 3 minutes.
- **SC-005**: The stock report accurately reflects all transactions (sales,
  purchases, returns, opening stock) with a discrepancy rate below 0.1%.
- **SC-006**: A customer statement can be generated for any date range and
  matches the sum of all invoices and payments within 1 EGP accuracy.
- **SC-007**: All user-facing text in the application is in Arabic — no
  English error messages, technical jargon, or untranslated strings appear
  in production.
- **SC-008**: Retail and wholesale invoices are never displayed on the same
  screen or route — users navigate to separate dedicated screens.
- **SC-009**: A shift close report reconciles opening cash, all transactions,
  and closing cash to within 1 EGP.

## Assumptions

- The server backend is custom-built (as per project stack) and exposes a
  RESTful API that mirrors the local data model.
- All `client_generated_uuid` values are generated on the client device
  using a standard unique identifier scheme.
- The sync queue processes writes in FIFO order, backed by the device's
  local persistent storage.
- Single device per branch — no concurrent offline writes from the same
  branch. Stock deductions are serialized locally.
- Empty-bottle nominal charge is configurable globally (default: 5 EGP) and
  waivable per line item.
- VAT is 14%, tax-inclusive (displayed prices include VAT). VAT is shown as a
  separate informative line on the invoice; the final total equals the
  after-discount total (already VAT-inclusive).
- The system targets tablet-sized screens in landscape orientation as the
  primary POS form factor.
- Customer and supplier records are created on-the-fly during invoicing or
  pre-created in master data.
- A minimum of one branch must exist before any employee can be assigned.
- Shift opening cash balance defaults to 0 and is adjustable.
- The low-stock threshold defaults to 5 units and is configurable per
  material.
- All reports are view-only on-device; PDF export or printing is out of
  scope for v1.
