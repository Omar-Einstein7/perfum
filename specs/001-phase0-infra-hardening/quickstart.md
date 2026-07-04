# Quickstart: Phase 0 — Infrastructure Hardening

**Validation guide** — run these scenarios to confirm Phase 0 is correctly implemented.
No backend is required for scenarios 1–3 (they use mocked/stub responses).
Scenarios 4–7 require the backend running locally.

**Prerequisites**:
- Flutter SDK installed and `flutter doctor` reports no errors.
- `.env` file at project root with `API_BASE_URL=http://localhost:3000/api/v1`.
- Backend running on port 3000 (for scenarios 4–7).
- App built and running: `flutter run -d chrome` (or `flutter run -d <device>`).

---

## Scenario 1 — Unauthenticated Redirect (FR-001)

**Goal**: Verify no protected content is reachable without a session.

**Steps**:
1. Clear browser storage / app data so no JWT is present.
2. Start the app (`flutter run -d chrome`).
3. In the browser address bar, navigate directly to `http://localhost:PORT/materials`.

**Expected**:
- Browser URL changes to `http://localhost:PORT/login`.
- Login screen renders. No materials content visible.
- DevTools → Application → Storage → no `jwt_token` key present.

**Also verify**:
- Repeat with `/purchases`, `/stock`, `/ledger`, `/reports` — all redirect to `/login`.
- `/forgot-password` and `/onboarding` do NOT redirect (they are public routes).

---

## Scenario 2 — JWT Injection on Every Request (FR-003, SC-002)

**Goal**: Verify the `Authorization` header is present on all API calls without any screen-level code adding it.

**Steps**:
1. Log in with valid credentials → reach the dashboard.
2. Open browser DevTools → Network tab → filter by `XHR / Fetch`.
3. Navigate to any data screen (e.g., Units list) to trigger an API call.

**Expected**:
- Every outgoing request to `localhost:3000/api/v1/*` shows:
  `Authorization: Bearer <token>` in its Request Headers.
- The request is made by the data source — no `Authorization` header set anywhere in the screen or cubit code.

---

## Scenario 3 — Hard Logout on 401 (FR-004, SC-003)

**Goal**: Verify a 401 response from any endpoint triggers immediate logout.

**Setup** (two options):
- **Option A (recommended)**: Use a browser extension (e.g., ModHeader) or a local
  proxy to intercept any API response and force a 401 status code.
- **Option B**: Manually expire/invalidate the token on the backend and then trigger
  any API call from the logged-in app.

**Steps**:
1. Log in → reach dashboard.
2. Trigger a 401 response on any API call (see setup above).
3. Observe the app.

**Expected** (within 2 seconds — SC-003):
- App navigates to `/login`.
- DevTools → Application → Storage → `jwt_token` key is GONE.
- No error screen; no crash; no partial content visible.

---

## Scenario 4 — Session Persistence Across Restart (FR-006, SC-007)

**Goal**: Verify a logged-in user stays logged in after hot restart.

**Steps**:
1. Log in with valid credentials → reach dashboard.
2. In the terminal, press `R` (hot restart — not hot reload).
3. Observe the app.

**Expected**:
- App goes through the splash screen.
- Lands back on the **dashboard** (not `/login`).
- No login prompt shown.

---

## Scenario 5 — Permission Redirect (FR-008, SC-006)

**Goal**: Verify a user without a specific permission is redirected to dashboard.

**Setup**: Create or use a test user with `permissions = 1` (canViewSales only — no
canEditMasters, no canViewPurchases, etc.).

**Steps**:
1. Log in as the restricted user.
2. In the address bar, navigate to `/materials`.

**Expected**:
- App redirects to `/` (dashboard).
- No error screen; no crash.
- The URL does NOT stay on `/materials`.

**Also verify**:
- Navigating to `/sales` (canViewSales = 1) is **allowed** for this user.

---

## Scenario 6 — Dependency Registry Boot (FR-005, SC-004)

**Goal**: Verify all singletons are registered before the first frame.

**Steps**:
1. Run the app in debug mode with verbose logging.
2. Observe the console output during startup.

**Expected**:
- `[INFO] setupServiceLocator: complete` (or equivalent) appears **before** any
  widget build log lines.
- `sl<SessionBloc>()` resolves immediately in the `app_router.dart` redirect callback
  (no `LateInitializationError` or `get_it not registered` exception).

---

## Scenario 7 — Boot Failure Handling (FR-013, SC-008)

**Goal**: Verify that a registry failure crashes visibly and does not partially boot.

**Setup**: Temporarily introduce a failing registration in `setupServiceLocator()`
(e.g., throw an `Exception('test boot failure')` as the first line of the function).

**Steps**:
1. Run the app in debug mode.
2. Observe the result.

**Expected**:
- Flutter red error screen is shown (debug mode).
- Console shows the exception with a stack trace logged by `AppLogger.error()`.
- The app does NOT reach `runApp()` or render any widget content.
- No silent failure, no blank screen.

**Cleanup**: Remove the artificial throw after verification.

---

## Scenario 8 — Malformed Token Handling (Edge Case)

**Goal**: Verify a corrupted stored token is treated as no token.

**Setup**: Using DevTools or a platform-specific tool, write an invalid value to
the `jwt_token` key in secure storage (e.g., `"not-a-valid-jwt"`).

**Steps**:
1. With the malformed token in storage, start the app.
2. Observe the landing screen.

**Expected**:
- The `/auth/me` (or equivalent session check) call returns 401 (backend rejects invalid token).
- App clears storage and lands on `/login`.
- No crash; no partial content.

---

## Validation Checklist

Run through each scenario and tick off:

- [ ] S1: All protected routes redirect to `/login` when unauthenticated
- [ ] S2: `Authorization: Bearer <token>` present on every API request header
- [ ] S3: 401 response → `/login` within 2s; `jwt_token` cleared from storage
- [ ] S4: Hot restart with valid token → lands on dashboard (not login)
- [ ] S5: Restricted user navigating to forbidden route → redirected to dashboard
- [ ] S6: All singletons registered before first widget build log
- [ ] S7: Injected boot failure → Flutter error screen shown; app does not partially boot
- [ ] S8: Malformed token in storage → app clears it and shows login

All 8 scenarios passing = Phase 0 complete. Proceed to Phase 1 (Auth — complete).
