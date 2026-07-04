# Contract: Router Guard

**File**: `lib/src/routing/app_router.dart`
**Phase**: 0 — Infrastructure Hardening
**Related**: [research.md](../research.md#3-gorouter-redirect-guard), [data-model.md](../data-model.md#4-route-registry)

---

## Purpose

A `redirect` callback on the `GoRouter` instance that enforces two gates on every
navigation event:
1. **Authentication gate** — unauthenticated users are redirected to `/login`.
2. **Permission gate** — authenticated users without the required permission flag
   are redirected to `/` (dashboard).

The guard is stateless and synchronous. It reads live state from `sl<SessionBloc>()`.

---

## `redirect` Function Signature

```
String? redirect(BuildContext context, GoRouterState routerState)
```

Returns:
- `null` — allow navigation to proceed.
- A route path string — redirect to that path instead.

Must be synchronous. Must not `await`. Must not call `context.go()`.

---

## Decision Table

| Session status | Target route | User has permission? | Returns |
|---|---|---|---|
| `unknown` | any | — | `null` (hold; session check in progress) |
| `unauthenticated` | public route | — | `null` (allow public access) |
| `unauthenticated` | protected route | — | `/login` |
| `authenticated` | `/login` or `/forgot-password` | — | `/` (dashboard) |
| `authenticated` | protected route | yes | `null` (allow) |
| `authenticated` | protected route | no | `/` (dashboard) |
| `authenticated` | dashboard `/` | — | `null` (allow) |

**Public routes** (no auth required): `/login`, `/forgot-password`, `/onboarding`

---

## Permission Map Contract

A private helper function `_permissionForRoute(String location)` returns the required
permission flag integer for a given path, or `null` if any authenticated user may access it.

| Route group | Required flag constant | Flag value |
|---|---|---|
| `/` (dashboard) | `null` (any authenticated user) | — |
| `/units`, `/categories`, `/materials*`, `/suppliers*`, `/customers*`, `/branches` | `AppUser.canEditMasters` | 32 |
| `/purchases*`, `/payment-vouchers*`, `/transfers*` | `AppUser.canViewPurchases` or `canEditPurchases` | 4 or 8 |
| `/sales*`, `/receipt-vouchers*` | `AppUser.canViewSales` or `canEditSales` | 1 or 2 |
| `/stock`, `/ledger`, `/reports` | `AppUser.canViewStock` | 16 |

Note: For write routes (e.g., `/purchases/new`), the required flag is `canEditPurchases`.
For read routes (e.g., `/purchases`), the required flag is `canViewPurchases`. The
permission map distinguishes between the two.

---

## `GoRouterRefreshStream` Contract

```dart
refreshListenable: GoRouterRefreshStream(sl<SessionBloc>().stream)
```

- `GoRouterRefreshStream` wraps `SessionBloc.stream` as a `ChangeNotifier`.
- Every time `SessionBloc` emits a new state, `GoRouter` re-evaluates `redirect`.
- This is what causes the router to react to mid-session invalidation (e.g., 401
  received while the user is on the dashboard — no navigation event triggered it,
  but the stream emission triggers `redirect` re-evaluation).

**Precondition**: `sl<SessionBloc>()` must be registered before `appRouter` is constructed.
`appRouter` is constructed at field-initialisation time (top-level `final appRouter = GoRouter(...)`).
Therefore `setupServiceLocator()` MUST complete before `app.dart` is evaluated.
This is guaranteed by calling `setupServiceLocator()` before `runApp()` in `main()`.

---

## Invariants

| Invariant | Description |
|---|---|
| No `BuildContext` for state | Guard reads `sl<SessionBloc>().state` — no `context.read()` |
| No navigation inside guard | Guard returns a string path or null; never calls `context.go()` |
| Unknown state → no redirect | App must not redirect while session check is in progress |
| Authenticated + login route → dashboard | Prevents authenticated user from staying on login page |
| Redirect to dashboard on no permission | Never error screen; never crash |
| Public routes always reachable when unauthenticated | `/login`, `/forgot-password`, `/onboarding` always return null for unauthenticated state |
