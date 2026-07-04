# Research: Phase 0 — Infrastructure Hardening

**Generated**: 2026-07-04
**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

---

## 1. Dio Interceptor for JWT Injection

### Decision
Use a single `InterceptorsWrapper` added to `AppConfig.dio` during `AppConfig.init()`.
The interceptor reads the token from `SecureStorageService` synchronously-via-async
on `onRequest`, and handles 401 via `onError`.

### Rationale
- Dio's `InterceptorsWrapper` is the idiomatic single point for cross-cutting HTTP concerns.
- Reading from `SecureStorageService` inside `onRequest` requires calling an async method
  from within the synchronous interceptor callback — this is handled by calling
  `handler.next()` only after the `await`, which Dio supports via `RequestInterceptorHandler`.
- Placing the interceptor in `AppConfig.init()` (not in `DioService`) ensures it is
  attached before any request can be made, even before `get_it` is populated.

### Pattern: Async token injection

```
onRequest: async (options, handler) {
  final token = await SecureStorageService.instance.read(kJwtTokenKey);
  if (token is Right(value)) {
    options.headers['Authorization'] = 'Bearer $value';
  }
  handler.next(options);
}
```

### Pattern: Hard logout on 401

```
onError: async (DioException e, handler) {
  if (e.response?.statusCode == 401) {
    await SecureStorageService.instance.delete(kJwtTokenKey);
    AuthService.instance._authStateController.add(null);
  }
  handler.next(e);   // propagate; do NOT call handler.resolve()
}
```

**Navigation is NOT triggered inside the interceptor.** The `AuthService` stream
emission causes `SessionBloc` to emit `SessionState.unauthenticated()`, which
`GoRouter.redirect()` picks up on the next navigation event, and
`SessionListenerWrapper`'s `BlocListener` handles immediate push to `/login`.

### Alternatives considered
- **Refresh token interceptor (retry on 401)**: Rejected — hard logout is the
  specified behaviour (Q3 clarification). Adds retry complexity for no Phase 0 benefit.
- **Dio `QueuedInterceptorsWrapper`**: Rejected — only needed when concurrent requests
  must be queued during a refresh. Not applicable without refresh.
- **Token reading in `DioService` methods**: Rejected — violates DRY; every method
  would need the same read logic.

---

## 2. get_it Service Locator Pattern

### Decision
Use `get_it` singleton (`GetIt.instance`, exposed as `sl`) with a top-level
`setupServiceLocator()` async function in `lib/src/services/service_locator.dart`.
Registration uses `registerLazySingleton` for pure services and `registerSingleton`
(eager) for blocs that must start immediately (e.g., `SessionBloc` triggers
`SessionCheckRequested` on construction).

### Registration order

```
1. SecureStorageService   (registerLazySingleton — no deps)
2. StorageService         (registerLazySingleton — no deps)
3. DioService             (registerLazySingleton — no deps; Dio configured in AppConfig)
4. AuthService            (registerLazySingleton — uses AppConfig.dio directly)
5. AuthRepositoryImpl     → registered as AuthRepository
                          (registerLazySingleton — depends on AuthService)
6. SessionBloc            (registerSingleton EAGER — starts SessionCheckRequested immediately;
                           depends on AuthRepository)
7. AuthBloc               (registerLazySingleton — depends on AuthRepository)
```

### `kJwtTokenKey` placement
Defined as a top-level constant in `service_locator.dart`:
```dart
const String kJwtTokenKey = 'jwt_token';
```
Imported by `app_config.dart` (interceptor), `auth_repository_impl.dart` (token save/clear),
and any future use-case that reads the token. Single source; no raw literals elsewhere.

### Boot failure handling
`setupServiceLocator()` is NOT wrapped in `try/catch` at the call site in `main()`.
Any exception thrown during registration propagates up, terminates `main()`, and triggers
Flutter's default uncaught-exception handler — showing the red error screen in debug,
and crashing in release (as per FR-013). The exception is logged via `AppLogger.error()`
inside `setupServiceLocator()` before rethrowing.

### Rationale
- `registerLazySingleton` avoids instantiating unused services on boot.
- `SessionBloc` is eager because it must fire `SessionCheckRequested` at startup to
  determine auth state before the router evaluates its first `redirect()`.
- `get_it` lookup (`sl<T>()`) is synchronous and O(1) — no performance concern.

### Alternatives considered
- **Injectable + build_runner code generation**: Evaluated. Adds `@injectable` annotations
  and a generated `configureDependencies()` file. Rejected for Phase 0 — manual
  registration is simpler, more readable, and avoids another code-gen dependency for
  a small registry. Can be migrated later if registry grows beyond ~50 entries.
- **Provider/Riverpod for DI**: Rejected — constitution Principle VII forbids it.
- **Lazy registration for SessionBloc**: Rejected — lazy would delay the session check
  until the first `sl<SessionBloc>()` call, which could be after the first `redirect()`
  evaluation, causing a `unknown` state flash.

---

## 3. GoRouter Redirect Guard

### Decision
Add a `redirect` callback to the `GoRouter` constructor. The callback is synchronous
(returns `String?`). It reads `SessionBloc.state` from `get_it` (already a singleton)
without any `BuildContext` dependency.

### Guard logic (final)

```
String? redirect(BuildContext context, GoRouterState state) {
  final session = sl<SessionBloc>().state;
  final location = state.matchedLocation;

  // Public routes — never redirect
  const publicRoutes = [AppRoutes.login, AppRoutes.forgotPassword, AppRoutes.onboarding];
  if (publicRoutes.contains(location)) {
    if (session.status == SessionStatus.authenticated) {
      return AppRoutes.dashboard;   // kick authenticated user off login page
    }
    return null;
  }

  // Unknown — session check in progress; hold position
  if (session.status == SessionStatus.unknown) return null;

  // Unauthenticated — send to login
  if (session.status == SessionStatus.unauthenticated) return AppRoutes.login;

  // Authenticated — check permission for this route
  final required = _permissionForRoute(location);
  if (required != null && !session.user!.can(required)) {
    return AppRoutes.dashboard;
  }

  return null; // allow
}
```

### `refreshListenable` integration
`GoRouter` needs to re-evaluate `redirect` whenever `SessionBloc` emits a new state.
This is achieved by wrapping `SessionBloc.stream` in a `GoRouterRefreshStream` (a
`Listenable` adapter over a `Stream`). This is the go_router-recommended pattern.

```dart
GoRouter(
  redirect: redirect,
  refreshListenable: GoRouterRefreshStream(sl<SessionBloc>().stream),
  ...
)
```

### Permission map
A private `_permissionForRoute(String location)` function maps each protected route
to its required permission flag integer. Returns `null` for routes that any authenticated
user may access (e.g., `/dashboard`). Defined in `app_router.dart` alongside the guard.

### Rationale
- Synchronous `redirect` is required by `go_router`; async is not supported directly.
- `GoRouterRefreshStream` is the canonical pattern to trigger redirect re-evaluation
  on bloc state changes without a `BlocListener` in the route layer.
- Reading from `sl<SessionBloc>()` (not `context.read`) avoids `BuildContext` dependency
  in the router, consistent with constitution Principle VII.

### Alternatives considered
- **`redirect` reading from `context.read<SessionBloc>()`**: Rejected — requires
  `SessionBloc` to be in the widget tree above the router, creates circular dependency
  with `MaterialApp.router`.
- **`ShellRoute` with guards**: Evaluated. Useful for nested navigation with shell UI.
  Deferred to Phase 2 (ERPShell widget) — not needed for redirect logic alone.
- **`NavigatorObserver`**: Rejected — imperative, not declarative; harder to test.

---

## 4. AppRoutes Constants — Complete Set

### Decision
All 25 route paths defined as `static const String` fields on `abstract final class AppRoutes`.
Parametric routes (with `:id`) use both a path template constant and a named-parameter
helper function for safe URL construction.

### Full constant list

```dart
// Auth (public)
static const login          = '/login';
static const forgotPassword = '/forgot-password';
static const onboarding     = '/onboarding';

// Core (authenticated, no specific permission)
static const dashboard      = '/';

// Lookups (canEditMasters)
static const units          = '/units';
static const categories     = '/categories';

// Inventory (canEditMasters / canViewMaterials)
static const materials      = '/materials';
static const materialDetail = '/materials/:id';

// Parties (canEditMasters)
static const suppliers      = '/suppliers';
static const supplierDetail = '/suppliers/:id';
static const customers      = '/customers';
static const customerDetail = '/customers/:id';

// Branches (canEditMasters)
static const branches       = '/branches';

// Purchases (canViewPurchases / canEditPurchases)
static const purchases      = '/purchases';
static const purchaseNew    = '/purchases/new';
static const purchaseDetail = '/purchases/:id';

// Sales (canViewSales / canEditSales)
static const sales          = '/sales';
static const saleNew        = '/sales/new';
static const saleDetail     = '/sales/:id';

// Vouchers (canEditPurchases / canEditSales)
static const paymentVouchers    = '/payment-vouchers';
static const paymentVoucherNew  = '/payment-vouchers/new';
static const receiptVouchers    = '/receipt-vouchers';
static const receiptVoucherNew  = '/receipt-vouchers/new';

// Transfers (canEditPurchases)
static const transfers      = '/transfers';
static const transferNew    = '/transfers/new';

// Reports (canViewStock / canViewSales)
static const stock          = '/stock';
static const ledger         = '/ledger';
static const reports        = '/reports';
```

### Rationale
- Parametric paths (`:id`) are kept as path templates — `GoRoute` uses them for
  matching. Callers use `context.go('/materials/${id}')` or a helper
  `AppRoutes.materialDetailPath(id)`.
- Grouping by module makes the permission map in `app_router.dart` easy to audit.

---

## 5. SessionListenerWrapper — Defense-in-Depth Navigation

### Decision
Update `SessionListenerWrapper` to wrap a `BlocListener<SessionBloc, SessionState>`.
When `status == SessionStatus.unauthenticated`, call `context.go(AppRoutes.login)`.
This is the **widget-tree fallback** complementing the router redirect guard.

### Rationale
- The router guard fires on navigation events. If the user is already on a screen and
  the session is invalidated mid-session (via a 401 from a background poll, for example),
  the router guard alone does not trigger — no navigation event occurred.
- `BlocListener` fires on every state change regardless of navigation, providing the
  push to `/login` proactively.
- Two gates on the same condition is intentional defense-in-depth (spec Assumption 6).

### Alternatives considered
- **Only the router guard**: Rejected — does not handle mid-session invalidation without
  a navigation event.
- **Only `BlocListener`**: Rejected — does not protect against direct URL typing in the
  browser address bar (which bypasses the widget tree).

---

## 6. PermissionFailure — Error Type

### Decision
Add `PermissionFailure` as a direct subclass of `Failure` in `failure.dart`, identical
in structure to existing subclasses (`ServerFailure`, `CacheFailure`, etc.).

### Usage pattern
Use-cases that check permissions before executing return `left(PermissionFailure('...'))`
instead of throwing. Presentation layer receives this via `Either.fold` and surfaces it
as a toast or snackbar — never a full error screen.

### Rationale
- Consistent with the existing `Failure` hierarchy; no new patterns introduced.
- `PermissionFailure` is distinct from `ServerFailure` — the backend may return 403
  (permission denied) which should be mapped to `PermissionFailure`, not `ServerFailure`.

---

## Summary Table

| Topic | Decision | Key Constraint |
|---|---|---|
| JWT injection | `InterceptorsWrapper` in `AppConfig.init()` | Async token read; no navigation in interceptor |
| 401 handling | Hard logout: clear token + emit null to stream | NO silent refresh (Phase 0) |
| Token key | `kJwtTokenKey = 'jwt_token'` in `service_locator.dart` | Single constant; no raw literals |
| DI registry | `get_it` with manual `setupServiceLocator()` | Eager `SessionBloc`; lazy everything else |
| Boot failure | Log + rethrow in `setupServiceLocator()` | Flutter error screen; no partial boot |
| Router guard | Synchronous `redirect` + `GoRouterRefreshStream` | No `BuildContext` in guard |
| Route constants | 25 constants in `abstract final class AppRoutes` | Grouped by module + permission tier |
| Session listener | `BlocListener` in `SessionListenerWrapper` | Defense-in-depth; fires on mid-session invalidation |
| Permission error | `PermissionFailure extends Failure` | Maps 403 responses; surfaced as toast, not error screen |
