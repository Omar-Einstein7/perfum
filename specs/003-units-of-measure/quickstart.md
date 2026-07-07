# Quickstart: Units of Measure

**Validation guide** — run these scenarios to confirm the Units module is correctly implemented. Requires the backend running locally on port 3000.

**Prerequisites**:
- Backend running on `http://localhost:3000/api/v1`
- `.env` with `API_BASE_URL=http://localhost:3000/api/v1`
- A logged-in user with `canEditMasters` permission
- App running: `flutter run -d chrome`

---

## Scenario 1 — Permission Guard

**Goal**: Verify that users without `canEditMasters` cannot access units pages.

**Steps**:
1. Log in as a user without `canEditMasters` permission.
2. Navigate to `/units` in the browser address bar.

**Expected**:
- App redirects to `/` (dashboard).
- No units content visible.

---

## Scenario 2 — List Units

**Goal**: Verify the units list loads and displays correctly.

**Steps**:
1. Log in as a user with `canEditMasters`.
2. Navigate to the Units page via the app navigation.

**Expected**:
- Page shows a list of units with name, abbreviation, type, and status columns.
- If no units exist, an empty-state message and "Add Unit" button appear.
- List loads within 3 seconds.

---

## Scenario 3 — Search Units

**Goal**: Verify search filtering works.

**Steps**:
1. Ensure at least 3 units exist with varied names (e.g., "Kilogram", "Liter", "Piece").
2. Type "kg" in the search box.

**Expected**:
- List filters to only "Kilogram" (or any unit matching "kg").
- Search results update within 1 second of finishing typing.
- Clearing the search restores the full list.

---

## Scenario 4 — Create Unit

**Goal**: Verify unit creation works end-to-end.

**Steps**:
1. Navigate to the Units page → tap "Add Unit".
2. Fill in: Name = "TestUnit", Abbreviation = "tu", Type = "count".
3. Tap Save.

**Expected**:
- Redirected to the units list.
- "TestUnit" appears in the list with abbreviation "tu" and type "count".

---

## Scenario 5 — Duplicate Name Validation

**Goal**: Verify duplicate detection on create.

**Steps**:
1. Create a unit with name "Kilogram" (assuming it already exists).
2. Observe the result.

**Expected**:
- Error message displayed: unit name already exists.
- Not redirected. Form data preserved.

---

## Scenario 6 — Edit Unit

**Goal**: Verify editing works.

**Steps**:
1. Navigate to the units list → tap an existing unit.
2. Change its name from "Kilogram" to "Kilogram (metric)".
3. Tap Save.

**Expected**:
- Redirected to the list showing the updated name.

---

## Scenario 7 — Deactivate Unit

**Goal**: Verify soft-delete works for unused units.

**Steps**:
1. Create a unit that is NOT used by any material.
2. Tap Deactivate → confirm.

**Expected**:
- Unit disappears from the default active list.
- Refreshing the page confirms it's gone.

---

## Scenario 8 — Block Deactivation of Referenced Unit

**Goal**: Verify a unit in use cannot be deactivated.

**Steps**:
1. Ensure a unit is referenced by at least one material.
2. Try to deactivate that unit.

**Expected**:
- Error message: unit is in use and cannot be deactivated.
- Unit remains active in the list.

---

## Scenario 9 — Network Error Handling

**Goal**: Verify graceful error on network failure.

**Steps**:
1. Open DevTools → Network tab → check "Offline".
2. Try to create, edit, or deactivate a unit.

**Expected**:
- Friendly error message shown.
- App does not crash.
- Form data preserved (not navigated away).

---

## Validation Checklist

- [ ] S1: Permission guard blocks unauthorized access
- [ ] S2: List loads with pagination and empty state
- [ ] S3: Search filters in real time
- [ ] S4: Create unit works end-to-end
- [ ] S5: Duplicate name shows error
- [ ] S6: Edit unit persists changes
- [ ] S7: Deactivate hides unit from active list
- [ ] S8: Deactivation blocked for referenced units
- [ ] S9: Network error handled gracefully
