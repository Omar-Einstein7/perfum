# Quickstart Validation Guide: Perfume Shop POS

> End-to-end validation scenarios for the full feature.
> Data model: see `data-model.md` | API contracts: see `plan.md §3`

## Prerequisites

- Flutter app running on a tablet/POS device
- Backend server running with migrations applied
- Seed data: at least one branch and one admin employee

## Validation Scenarios

### 1. Auth + Session Persistence

1. Launch the app; verify redirect to `/login`
2. Log in with admin credentials (username + password)
3. Verify landing on dashboard with employee name, branch, and role displayed
4. Close the app and reopen it — verify session restores without re-login
5. **Expected**: Session persists; protected routes accessible

### 2. Master Data — Material Lifecycle

1. Navigate to Categories; add "Oriental", "Western"
2. Navigate to Units; add "ml", "gram"
3. Navigate to Materials; add "Oud Royal" with:
   - Category: Oriental, Unit: ml
   - Purchase: 50, Retail: 150, Wholesale: 100
   - isBottle: yes, Empty bottle price: 5
4. Verify material appears in search with correct prices
5. Edit retail price to 160; verify new invoices use updated price
6. Deactivate the material; verify it disappears from active product list
7. **Expected**: Full CRUD works; changes propagate without page reload

### 3. Opening Stock Count

1. Ensure at least 3 materials exist
2. Open "Bulk Opening Stock Entry" screen
3. Enter quantities: 100 ml for material A, 50.5 ml for material B, 0 for C
4. Save; open stock report — verify quantities match per branch
5. **Expected**: Stock report shows correct quantities for the logged-in branch only

### 4. Shift + Retail Sale (Core Flow)

1. Open a shift with opening balance 0
2. Create a retail invoice:
   - Customer: "Walk-in" (on-the-fly)
   - Line item: Material A, qty 2.5, retail price
   - Verify empty-bottle line auto-added (charge 5 × 2.5)
   - Apply gift discount 10 EGP
3. Finalize invoice; verify it saves locally (offline OK)
4. Close the shift — verify closing balance matches the invoice total
5. **Expected**: Invoice recorded, stock decremented, shift balances match

### 5. Wholesale Invoice (Separate Route)

1. Navigate to wholesale screen (different route from retail)
2. Create a wholesale invoice:
   - Customer: wholesale customer (on-the-fly)
   - Line item: Material A, qty 10, wholesale price
3. Finalize — verify no shift check, no empty-bottle line
4. **Expected**: Wholesale uses separate Bloc, wholesale pricing, no shift dependency

### 6. Purchase + Purchase Return

1. Create a supplier (on-the-fly)
2. Create a purchase invoice: Material A, qty 20, purchase price 45
3. Verify stock increased by 20
4. Create a purchase return referencing the invoice: return qty 5
5. Verify stock decreased by 5
6. **Expected**: Stock adjusts correctly; return linked to original invoice

### 7. Payment/Receipt Vouchers + Credit

1. Create a receipt voucher for a customer: amount 200
2. Verify customer's credit balance decreases by 200
3. Create a payment voucher for a supplier: amount 150
4. Verify supplier's balance decreases by 150
5. **Expected**: Vouchers recorded; credit ledger updated chronologically

### 8. Offline Sync (Critical)

1. Enable airplane mode on the device
2. Perform 3 retail sales, 1 purchase, 1 receipt voucher
3. Verify all operations saved locally (sync indicator shows "pending")
4. Reconnect to internet
5. Wait for sync (auto-trigger on connectivity + 60s polling)
6. Verify all operations uploaded with correct `client_generated_uuid`
7. Verify no duplicates on server (same UUID ignored)
8. Verify stock totals on server match local totals
9. **Expected**: Zero data loss, no duplicates, server-computed totals match

### 9. Reports

1. Open stock report — verify quantities, low-stock indicators
2. Open sales report for today — verify totals, top materials, retail/wholesale split
3. Open customer statement — verify invoices, payments, balance
4. Open supplier statement — verify purchases, payments, balance
5. **Expected**: All numbers match across reports; data is branch-scoped

## Verification Commands

```bash
# Flutter
flutter pub get
flutter analyze
flutter test

# Backend (if applicable)
npm test
npm run lint
```
