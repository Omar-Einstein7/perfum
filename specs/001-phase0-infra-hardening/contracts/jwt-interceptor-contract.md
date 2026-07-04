# Contract: JWT Interceptor

**File**: `lib/src/config/app_config.dart` (addition to `AppConfig.init()`)
**Phase**: 0 — Infrastructure Hardening
**Related**: [research.md](../research.md#1-dio-interceptor-for-jwt-injection)

---

## Purpose

A single Dio `InterceptorsWrapper` that:
1. Injects the stored JWT bearer token into every outgoing HTTP request.
2. Handles HTTP 401 responses with a hard logout (clear token + notify stream).

Attached once inside `AppConfig.init()`. Fires on every request made via
`AppConfig.dio`, which is shared by `DioService` and `AuthService`.

---

## `onRequest` Behaviour

**Trigger**: Every HTTP request before it is sent.

**Steps**:
1. Read `kJwtTokenKey` from `SecureStorageService.instance`.
2. If read returns a `Right(token)` and `token` is non-null and non-empty:
   - Set `options.headers['Authorization'] = 'Bearer $token'`.
3. If read returns `Left(failure)` or token is null/empty:
   - Pass request through **unmodified** (login endpoint has no token yet).
4. Call `handler.next(options)`.

**Must NOT**:
- Throw or call `handler.reject()` on a missing token (login would break).
- Navigate or call `context.go()`.
- Block the UI thread (storage read is async; `handler.next` called after await).

---

## `onError` Behaviour

**Trigger**: Any HTTP response with a non-2xx status code reaching the interceptor.

**Steps** (only on `statusCode == 401`):
1. Await `SecureStorageService.instance.deleteAll()` — clears all secure storage
   (including `kJwtTokenKey`).
2. Call `AuthService.instance._authStateController.add(null)` — emits null user
   to the auth state stream.
3. Call `handler.next(e)` — propagates the `DioException` to the caller as a
   `ServerFailure` via `runTask`.

**Steps** (on any other error status):
1. Call `handler.next(e)` — pass through unmodified; caller handles it.

**Must NOT**:
- Call `handler.resolve()` — this would swallow the error.
- Navigate directly (e.g., `context.go('/login')`).
- Retry the request (no silent refresh in Phase 0).

---

## Side Effects Downstream

The `AuthService` stream emission (step 2 in `onError`) triggers this chain:

```
AuthService._authStateController.add(null)
  └─► SessionBloc receives SessionUserChanged(null)
        └─► SessionBloc emits SessionState.unauthenticated()
              └─► GoRouterRefreshStream notifies GoRouter
                    └─► GoRouter.redirect() returns '/login'
              └─► SessionListenerWrapper BlocListener fires
                    └─► context.go('/login')  [defense-in-depth]
```

---

## Invariants

| Invariant | Description |
|---|---|
| Token key | Always use `kJwtTokenKey` — never the raw string `'jwt_token'` |
| No navigation | Interceptor MUST NOT call `context.go()` or any router method |
| No retry | Interceptor MUST NOT queue or retry a 401 request |
| Propagation | Every error MUST call `handler.next(e)` — never silently absorbed |
| Login exclusion | Login endpoint (`/auth/login`) gets no token header (no token exists yet) — this is correct behaviour, not a bug |
