# Contract: Service Locator

**File**: `lib/src/services/service_locator.dart`
**Phase**: 0 — Infrastructure Hardening
**Related**: [data-model.md](../data-model.md#3-dependency-registry-map)

---

## Public API Surface

### Exported constant

```
kJwtTokenKey : String = 'jwt_token'
```

Single canonical key for JWT token storage. All components that read, write, or delete
the stored token MUST import and use this constant. No raw string `'jwt_token'` may
appear anywhere else in the codebase.

---

### Exported function

```
Future<void> setupServiceLocator()
```

**Preconditions**:
- `AppConfig.init()` MUST have completed before this function is called.
  (Dio is configured with the JWT interceptor before the locator runs.)
- Called once, before `runApp()`, inside `main()`.

**Postconditions** (on success):
- `sl<SecureStorageService>()` resolves without error.
- `sl<StorageService>()` resolves without error.
- `sl<DioService>()` resolves without error.
- `sl<AuthService>()` resolves without error.
- `sl<AuthRepository>()` resolves to an `AuthRepositoryImpl` instance.
- `sl<SessionBloc>()` resolves to an already-started `SessionBloc` that has
  dispatched `SessionCheckRequested` in its constructor.
- `sl<AuthBloc>()` resolves without error.

**On failure**:
- The function MUST log the exception via `AppLogger.error()` before rethrowing.
- The exception propagates to `main()` uncaught → Flutter error screen shown.
- The app MUST NOT reach `runApp()` with a partially populated registry.

**Idempotency**: NOT idempotent. Calling `setupServiceLocator()` twice in the same
process will throw a `get_it` already-registered assertion. Only call once.

---

### Exported accessor (re-exported from get_it)

```
sl : GetIt   (alias for GetIt.instance)
```

Used everywhere in the codebase to resolve registered types:
```
sl<SessionBloc>()   → the singleton SessionBloc instance
sl<AuthRepository>() → the singleton AuthRepositoryImpl instance
```

---

## Registration Order Contract

Registrations MUST be made in this exact order. Any deviation that attempts to resolve
a type before it is registered will throw at runtime.

```
1. SecureStorageService  — lazy singleton, no dependencies
2. StorageService        — lazy singleton, no dependencies
3. DioService            — lazy singleton, no dependencies
4. AuthService           — lazy singleton, no dependencies
5. AuthRepository        — lazy singleton, depends on: AuthService
6. SessionBloc           — EAGER singleton, depends on: AuthRepository
7. AuthBloc              — lazy singleton, depends on: AuthRepository
```

---

## Extension Contract (for future modules)

When adding a new module (e.g., Phase 3 — Units):
1. Add registrations at the END of `setupServiceLocator()`, after the Phase 0 block.
2. Follow the same order: data sources → repository impl → cubit/bloc.
3. No existing registration line may be modified or reordered.
4. New registrations MUST be lazy singletons unless there is an explicit reason for eager init (document the reason inline).
