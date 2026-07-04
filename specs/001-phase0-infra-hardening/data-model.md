# Data Model: Phase 0 — Infrastructure Hardening

**Generated**: 2026-07-04
**Feature**: [spec.md](spec.md) | **Research**: [research.md](research.md)

---

> Phase 0 introduces no new database entities — all data is either transient in-memory
> state or a single persisted string (the JWT token). This document covers the in-app
> data structures, state machines, and constants that Phase 0 establishes as the
> contract every future module depends on.

---

## 1. Constants

### `kJwtTokenKey`

```
Name:    kJwtTokenKey
Value:   'jwt_token'
Type:    String (compile-time constant)
File:    lib/src/services/service_locator.dart
Scope:   Global — imported by every component that reads/writes/deletes the JWT
```

**Used by**:
- `AppConfig.init()` → JWT interceptor (read on request, delete on 401)
- `AuthRepositoryImpl` → save token on login, delete on logout
- `CheckSessionUseCase` → read token to determine if session exists

**Rule**: No other file may use the string `'jwt_token'` as a literal. Always import
and reference `kJwtTokenKey`.

---

## 2. Entities & State Objects

### 2.1 `AppUser` (extended from existing)

**File**: `lib/src/features/auth/domain/entities/user.dart`
**Change**: Add `permissions` field and `can()` helper.

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | yes | MongoDB ObjectId hex string — NEVER an integer |
| `email` | `String` | yes | User's login email |
| `name` | `String?` | no | Display name |
| `photoUrl` | `String?` | no | Avatar URL |
| `permissions` | `int` | yes | Bitmask of 7 permission flags (default `0`) |

**Permission flag constants** (defined on `AppUser`):

| Constant | Bit | Value | Grants access to |
|---|---|---|---|
| `canViewSales` | 0 | 1 | Sales list, sale detail screens |
| `canEditSales` | 1 | 2 | New sale form, submit sale |
| `canViewPurchases` | 2 | 4 | Purchases list, purchase detail |
| `canEditPurchases` | 3 | 8 | New purchase form, submit purchase, vouchers, transfers |
| `canViewStock` | 4 | 16 | Stock screen, ledger screen |
| `canEditMasters` | 5 | 32 | Units, categories, materials, suppliers, customers, branches |
| `isAdmin` | 6 | 64 | All of the above + user management |

**Helper method**:
```
bool can(int flag) => (permissions & flag) != 0;
```

**Empty/anonymous state**:
```
AppUser.empty() → id: '', email: '', permissions: 0
bool get isEmpty  => id.isEmpty
bool get isNotEmpty => id.isNotEmpty
```

**Identity rule**: `id` is ALWAYS a MongoDB ObjectId hex string. The `AppUser.empty()`
factory exists solely as a null-object — it must never be stored or sent to the backend.

---

### 2.2 `SessionState` (existing — no structural change)

**File**: `lib/src/features/auth/presentation/providers/session_bloc.dart`

| State variant | Meaning | `user` field |
|---|---|---|
| `SessionState.unknown()` | App just launched; session check in progress | `null` |
| `SessionState.authenticated(user)` | Valid JWT found; user loaded | `AppUser` |
| `SessionState.unauthenticated()` | No JWT, expired, or 401 received | `null` |

**State machine transitions**:

```
unknown ──(SessionCheckRequested)──► authenticated   (token found + /auth/me success)
unknown ──(SessionCheckRequested)──► unauthenticated (no token or /auth/me fails)
authenticated ──(401 received)─────► unauthenticated (via AuthService stream)
authenticated ──(logout)───────────► unauthenticated
unauthenticated ──(login success)──► authenticated   (via AuthService stream)
```

**Router reads**: `sl<SessionBloc>().state` (synchronous, no await).
**Router refreshes**: on every `SessionBloc` state emission via `GoRouterRefreshStream`.

---

### 2.3 `Failure` hierarchy (extended)

**File**: `lib/src/utils/failure.dart`

| Class | When used |
|---|---|
| `ServerFailure` | Backend returned 4xx/5xx other than 401/403 |
| `NetworkFailure` | No connectivity; request never reached server |
| `CacheFailure` | Local storage read/write error |
| `PermissionFailure` | *(NEW)* User lacks permission flag; backend 403 |
| `UnknownFailure` | Catch-all for unexpected errors |

**`PermissionFailure` fields**:

| Field | Type | Description |
|---|---|---|
| `message` | `String` | Human-readable reason, e.g., "You do not have permission to edit materials" |
| `error` | `dynamic?` | Raw error value for logging (optional) |

**Presentation rule**: `PermissionFailure` MUST be surfaced as a non-blocking toast
or snackbar. It MUST NOT navigate the user to an error screen.

---

## 3. Dependency Registry Map

**File**: `lib/src/services/service_locator.dart`

| Symbol registered | Interface | Scope | Init eagerness |
|---|---|---|---|
| `SecureStorageService` | (concrete) | Singleton | Lazy |
| `StorageService` | (concrete) | Singleton | Lazy |
| `DioService` | (concrete) | Singleton | Lazy |
| `AuthService` | (concrete) | Singleton | Lazy |
| `AuthRepositoryImpl` | `AuthRepository` | Singleton | Lazy |
| `SessionBloc` | (concrete) | Singleton | **Eager** |
| `AuthBloc` | (concrete) | Singleton | Lazy |

**Eager vs lazy**:
- `SessionBloc` is **eager** — it dispatches `SessionCheckRequested` in its constructor.
  This check must complete before the router evaluates its first `redirect()` call,
  so it cannot wait for first access.
- All others are **lazy** — they are not instantiated until first requested via `sl<T>()`.

**Registration order constraint**:
Infrastructure → Data → Presentation. Each registration may only depend on previously
registered entries.

```
SecureStorageService (no deps)
StorageService       (no deps)
DioService           (no deps — uses AppConfig.dio, configured before registry runs)
AuthService          (no deps — uses AppConfig.dio directly)
AuthRepositoryImpl   (depends on: AuthService)
SessionBloc          (depends on: AuthRepository)   ← eager, starts check immediately
AuthBloc             (depends on: AuthRepository)
```

---

## 4. Route Registry

**File**: `lib/src/routing/app_routes.dart`

### Public routes (no auth required)

| Constant | Path | Notes |
|---|---|---|
| `login` | `/login` | |
| `forgotPassword` | `/forgot-password` | |
| `onboarding` | `/onboarding` | Will be removed/repurposed in Phase 1 |

### Authenticated routes — no specific permission

| Constant | Path |
|---|---|
| `dashboard` | `/` |

### Authenticated routes — `canEditMasters` (flag 32)

| Constant | Path |
|---|---|
| `units` | `/units` |
| `categories` | `/categories` |
| `materials` | `/materials` |
| `materialDetail` | `/materials/:id` |
| `suppliers` | `/suppliers` |
| `supplierDetail` | `/suppliers/:id` |
| `customers` | `/customers` |
| `customerDetail` | `/customers/:id` |
| `branches` | `/branches` |

### Authenticated routes — `canViewPurchases` (flag 4) / `canEditPurchases` (flag 8)

| Constant | Path | Required flag |
|---|---|---|
| `purchases` | `/purchases` | `canViewPurchases` |
| `purchaseNew` | `/purchases/new` | `canEditPurchases` |
| `purchaseDetail` | `/purchases/:id` | `canViewPurchases` |
| `paymentVouchers` | `/payment-vouchers` | `canEditPurchases` |
| `paymentVoucherNew` | `/payment-vouchers/new` | `canEditPurchases` |
| `transfers` | `/transfers` | `canEditPurchases` |
| `transferNew` | `/transfers/new` | `canEditPurchases` |

### Authenticated routes — `canViewSales` (flag 1) / `canEditSales` (flag 2)

| Constant | Path | Required flag |
|---|---|---|
| `sales` | `/sales` | `canViewSales` |
| `saleNew` | `/sales/new` | `canEditSales` |
| `saleDetail` | `/sales/:id` | `canViewSales` |
| `receiptVouchers` | `/receipt-vouchers` | `canEditSales` |
| `receiptVoucherNew` | `/receipt-vouchers/new` | `canEditSales` |

### Authenticated routes — `canViewStock` (flag 16)

| Constant | Path |
|---|---|
| `stock` | `/stock` |
| `ledger` | `/ledger` |
| `reports` | `/reports` |

---

## 5. Storage Schema

### SecureStorage (flutter_secure_storage)

| Key | Constant | Value type | Written by | Read by | Deleted by |
|---|---|---|---|---|---|
| `'jwt_token'` | `kJwtTokenKey` | `String` (bearer token) | `AuthRepositoryImpl.login()` | JWT interceptor (`onRequest`) | JWT interceptor (`onError 401`), `AuthRepositoryImpl.logout()` |

No other keys are written to secure storage in Phase 0.

### SharedPreferences (StorageService)

No Phase 0 keys. Reserved for future non-sensitive settings (e.g., locale preference,
active branch selection).
