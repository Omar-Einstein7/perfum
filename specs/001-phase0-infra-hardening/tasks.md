---
description: "Task list for Phase 0 — Infrastructure Hardening"
---

# Tasks: Phase 0 — Infrastructure Hardening

**Input**: Design documents from `specs/001-phase0-infra-hardening/`

**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/ ✅ | quickstart.md ✅

**Tests**: Not requested — no test tasks generated.

**Organization**: Tasks are grouped by user story to enable independent implementation
and testing of each story.

**LLM note**: Every task below is self-contained. Each task tells you EXACTLY which
file to touch, what to add/change, and what the result must look like. Do NOT jump
ahead. Complete tasks in order within each phase.

---

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no shared state)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Exact file paths are included in every task description

---

## Phase 1: Setup

**Purpose**: Install the one missing dependency and create the single new file skeleton.

- [X] T001 Add `go_router` refresh helper dependency — open `pubspec.yaml` and confirm `go_router: ^17.1.0` is already present (it is); no new package needed. Document this as confirmed.

- [X] T002 Create empty file `lib/src/services/service_locator.dart` with this exact skeleton:
  ```dart
  import 'package:get_it/get_it.dart';

  final GetIt sl = GetIt.instance;
  const String kJwtTokenKey = 'jwt_token';

  Future<void> setupServiceLocator() async {
    // Phase 0 registrations added in T010–T016
  }
  ```
  No other content. Save the file.

- [X] T003 Create empty file `lib/src/routing/go_router_refresh_stream.dart` with this exact content:
  ```dart
  import 'dart:async';
  import 'package:flutter/foundation.dart';

  /// Converts a [Stream] into a [ChangeNotifier] so GoRouter can
  /// re-evaluate its redirect() whenever the stream emits.
  class GoRouterRefreshStream extends ChangeNotifier {
    GoRouterRefreshStream(Stream<dynamic> stream) {
      notifyListeners();
      _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
    }
    late final StreamSubscription<dynamic> _subscription;

    @override
    void dispose() {
      _subscription.cancel();
      super.dispose();
    }
  }
  ```
  Save the file.

**Checkpoint Phase 1**: `flutter analyze` reports zero new errors from these two files.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure changes that US1, US2, and US3 all depend on.
Complete ALL of these before touching any user-story phase.

**⚠️ CRITICAL**: Do not start Phase 3, 4, or 5 until this phase is 100% complete.

- [X] T004 Add `PermissionFailure` to `lib/src/utils/failure.dart`.
  Open the file. After the last existing subclass (`UnknownFailure`), add exactly:
  ```dart
  class PermissionFailure extends Failure {
    const PermissionFailure(super.message, {super.error});
  }
  ```
  Do not change any other line in the file.

- [X] T005 [P] Update `lib/src/features/auth/domain/entities/user.dart` — replace the entire file content with:
  ```dart
  import 'package:equatable/equatable.dart';

  class AppUser extends Equatable {
    final String id;
    final String email;
    final String? name;
    final String? photoUrl;
    final int permissions;

    const AppUser({
      required this.id,
      required this.email,
      this.name,
      this.photoUrl,
      this.permissions = 0,
    });

    // --- Permission flag constants (bitmask) ---
    static const int canViewSales     = 1;   // bit 0
    static const int canEditSales     = 2;   // bit 1
    static const int canViewPurchases = 4;   // bit 2
    static const int canEditPurchases = 8;   // bit 3
    static const int canViewStock     = 16;  // bit 4
    static const int canEditMasters   = 32;  // bit 5
    static const int isAdmin          = 64;  // bit 6

    /// Returns true if this user holds the given permission flag.
    bool can(int flag) => (permissions & flag) != 0;

    factory AppUser.empty() => const AppUser(id: '', email: '');

    bool get isEmpty    => id.isEmpty;
    bool get isNotEmpty => id.isNotEmpty;

    @override
    List<Object?> get props => [id, email, name, photoUrl, permissions];
  }
  ```
  Save the file.

- [X] T006 [P] Replace the entire content of `lib/src/routing/app_routes.dart` with:
  ```dart
  /// Centralized route path constants for GoRouter.
  /// All paths are UI routes (browser URL). API paths are NOT stored here.
  /// API base URL (including /api/v1) comes from .env → AppConfig.
  abstract final class AppRoutes {
    AppRoutes._();

    // --- Public (no auth required) ---
    static const String login          = '/login';
    static const String forgotPassword = '/forgot-password';
    static const String onboarding     = '/onboarding';

    // --- Core (any authenticated user) ---
    static const String dashboard      = '/';

    // --- Lookups (canEditMasters = 32) ---
    static const String units          = '/units';
    static const String categories     = '/categories';

    // --- Inventory (canEditMasters = 32) ---
    static const String materials      = '/materials';
    static const String materialDetail = '/materials/:id';

    // --- Parties (canEditMasters = 32) ---
    static const String suppliers      = '/suppliers';
    static const String supplierDetail = '/suppliers/:id';
    static const String customers      = '/customers';
    static const String customerDetail = '/customers/:id';

    // --- Branches (canEditMasters = 32) ---
    static const String branches       = '/branches';

    // --- Purchases (canViewPurchases=4, canEditPurchases=8) ---
    static const String purchases      = '/purchases';
    static const String purchaseNew    = '/purchases/new';
    static const String purchaseDetail = '/purchases/:id';

    // --- Sales (canViewSales=1, canEditSales=2) ---
    static const String sales          = '/sales';
    static const String saleNew        = '/sales/new';
    static const String saleDetail     = '/sales/:id';

    // --- Vouchers ---
    static const String paymentVouchers    = '/payment-vouchers';
    static const String paymentVoucherNew  = '/payment-vouchers/new';
    static const String receiptVouchers    = '/receipt-vouchers';
    static const String receiptVoucherNew  = '/receipt-vouchers/new';

    // --- Transfers (canEditPurchases = 8) ---
    static const String transfers      = '/transfers';
    static const String transferNew    = '/transfers/new';

    // --- Reports (canViewStock = 16) ---
    static const String stock          = '/stock';
    static const String ledger         = '/ledger';
    static const String reports        = '/reports';

    // --- Helpers for parametric routes ---
    static String materialDetailPath(String id)  => '/materials/$id';
    static String supplierDetailPath(String id)  => '/suppliers/$id';
    static String customerDetailPath(String id)  => '/customers/$id';
    static String purchaseDetailPath(String id)  => '/purchases/$id';
    static String saleDetailPath(String id)      => '/sales/$id';
  }
  ```
  Save the file.

- [X] T007 [P] Run `flutter analyze lib/src/utils/failure.dart lib/src/features/auth/domain/entities/user.dart lib/src/routing/app_routes.dart` and fix any analysis errors before continuing. Expected result: zero issues.

**Checkpoint Phase 2**: `flutter analyze` on the three files above reports zero errors.

---

## Phase 3: User Story 1 — Unauthenticated Redirect Guard (Priority: P1)

**Goal**: Any unauthenticated navigation to a protected route lands on `/login`.
No protected content renders before the auth gate.

**Independent Test**: Open the app with no stored session → navigate to `/materials` in browser address bar → browser must land on `/login`. See quickstart.md Scenario 1.

### Implementation for User Story 1

- [X] T008 [US1] Add the JWT interceptor to `lib/src/config/app_config.dart`.
  Open the file. At the TOP, add this import after the existing imports:
  ```dart
  import 'package:perfum_ahmed_gaper/src/services/service_locator.dart';
  import 'package:perfum_ahmed_gaper/src/services/secure_storage_service.dart';
  import 'package:perfum_ahmed_gaper/src/services/auth_service.dart';
  ```
  Inside `AppConfig.init()`, AFTER the existing `dio.interceptors.add(InterceptorsWrapper(...))` block (the logging interceptor), add a SECOND interceptor:
  ```dart
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final tokenResult = await SecureStorageService.instance.read(kJwtTokenKey);
          tokenResult.fold(
            (_) => null, // storage error → send request without token
            (token) {
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            },
          );
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await SecureStorageService.instance.deleteAll();
            AuthService.instance.signalUnauthenticated();
          }
          return handler.next(e);
        },
      ),
    );
  ```
  IMPORTANT: This interceptor must be the LAST interceptor added (after the logging one), so errors flow through logging first.
  Save the file.

- [X] T009 [US1] Add `signalUnauthenticated()` method to `lib/src/services/auth_service.dart`.
  Open the file. Inside the `AuthService` class body, add this public method (place it after the existing `getCurrentUser()` method and before `dispose()`):
  ```dart
  /// Called by the JWT interceptor when a 401 is received.
  /// Emits null to the auth state stream, triggering SessionBloc to go unauthenticated.
  void signalUnauthenticated() {
    _authStateController.add(null);
  }
  ```
  Do NOT change any other method. Save the file.

- [X] T010 [US1] Register Phase 0 services in `lib/src/services/service_locator.dart`.
  Replace the `// Phase 0 registrations added in T010–T016` comment with:
  ```dart
    // --- Infrastructure layer (no dependencies) ---
    sl.registerLazySingleton<SecureStorageService>(
      () => SecureStorageService.instance,
    );
    sl.registerLazySingleton<StorageService>(
      () => StorageService.instance,
    );
    sl.registerLazySingleton<DioService>(
      () => DioService.instance,
    );
    sl.registerLazySingleton<AuthService>(
      () => AuthService.instance,
    );
  ```
  Add the required imports at the top of the file (after the `get_it` import):
  ```dart
  import 'package:perfum_ahmed_gaper/src/services/secure_storage_service.dart';
  import 'package:perfum_ahmed_gaper/src/services/storage_service.dart';
  import 'package:perfum_ahmed_gaper/src/services/dio_service.dart';
  import 'package:perfum_ahmed_gaper/src/services/auth_service.dart';
  ```
  Save the file.

- [X] T011 [US1] Register Auth repository and blocs in `lib/src/services/service_locator.dart`.
  After the infrastructure registrations added in T010, add:
  ```dart
    // --- Data layer ---
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(),
    );

    // --- Presentation layer ---
    // SessionBloc: EAGER — starts SessionCheckRequested immediately on construction.
    // Must be registered before appRouter is built.
    sl.registerSingleton<SessionBloc>(
      SessionBloc(repository: sl<AuthRepository>()),
    );

    sl.registerLazySingleton<AuthBloc>(
      () => AuthBloc(repository: sl<AuthRepository>()),
    );
  ```
  Add these imports at the top of `service_locator.dart`:
  ```dart
  import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';
  import 'package:perfum_ahmed_gaper/src/features/auth/data/repositories/auth_repository_impl.dart';
  import 'package:perfum_ahmed_gaper/src/features/auth/presentation/providers/session_bloc.dart';
  import 'package:perfum_ahmed_gaper/src/features/auth/presentation/providers/auth_bloc.dart';
  ```
  Save the file.

- [X] T012 [US1] Add boot-failure logging to `lib/src/services/service_locator.dart`.
  Wrap the entire body of `setupServiceLocator()` in a try/catch:
  ```dart
  Future<void> setupServiceLocator() async {
    try {
      // ... all registrations from T010 and T011 go here ...
    } catch (e, stackTrace) {
      // Log then rethrow — main() will propagate to Flutter error screen (FR-013)
      // ignore: avoid_print
      print('[FATAL] setupServiceLocator failed: $e\n$stackTrace');
      rethrow;
    }
  }
  ```
  If you have a logger available (`AppLogger`), replace `print(...)` with
  `AppLogger.error('[FATAL] setupServiceLocator failed', error: e, stackTrace: stackTrace);`
  Save the file.

- [X] T013 [US1] Update `lib/main.dart` to call `setupServiceLocator()`.
  Open `lib/main.dart`. Add this import at the top:
  ```dart
  import 'src/services/service_locator.dart';
  ```
  Inside `main()`, add the call AFTER `await AppConfig.init();` and BEFORE `runApp(...)`:
  ```dart
    await AppConfig.init();
    await setupServiceLocator();   // ← ADD THIS LINE

    runApp(
  ```
  Do not change any other line. Save the file.

- [X] T014 [US1] Add redirect guard to `lib/src/routing/app_router.dart`.
  Open the file. Add these imports at the top:
  ```dart
  import 'package:perfum_ahmed_gaper/src/services/service_locator.dart';
  import 'package:perfum_ahmed_gaper/src/features/auth/presentation/providers/session_bloc.dart';
  import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
  import 'package:perfum_ahmed_gaper/src/routing/go_router_refresh_stream.dart';
  ```
  Replace the `final GoRouter appRouter = GoRouter(` block entirely with:
  ```dart
  // Maps a UI route path to its required permission flag.
  // Returns null if any authenticated user may access the route.
  int? _permissionForRoute(String location) {
    // Write routes (require edit permission)
    const editPurchaseRoutes = [
      AppRoutes.purchaseNew,
      AppRoutes.paymentVouchers,
      AppRoutes.paymentVoucherNew,
      AppRoutes.transfers,
      AppRoutes.transferNew,
    ];
    const editSalesRoutes = [
      AppRoutes.saleNew,
      AppRoutes.receiptVouchers,
      AppRoutes.receiptVoucherNew,
    ];
    const masterRoutes = [
      AppRoutes.units,
      AppRoutes.categories,
      AppRoutes.materials,
      AppRoutes.suppliers,
      AppRoutes.customers,
      AppRoutes.branches,
    ];
    const viewPurchaseRoutes = [AppRoutes.purchases];
    const viewSalesRoutes    = [AppRoutes.sales];
    const stockRoutes        = [AppRoutes.stock, AppRoutes.ledger, AppRoutes.reports];

    // Strip :id segments for matching
    final base = location.replaceAll(RegExp(r'/[^/]+$'), '');
    final check = (location.endsWith('/new') || !location.contains('/new'))
        ? location
        : base;

    if (editPurchaseRoutes.any((r) => location.startsWith(r.replaceAll(':id', '')))) {
      return AppUser.canEditPurchases;
    }
    if (editSalesRoutes.any((r) => location.startsWith(r.replaceAll(':id', '')))) {
      return AppUser.canEditSales;
    }
    if (masterRoutes.any((r) => location.startsWith(r.replaceAll(':id', '')))) {
      return AppUser.canEditMasters;
    }
    if (viewPurchaseRoutes.contains(location)) return AppUser.canViewPurchases;
    if (viewSalesRoutes.contains(location))    return AppUser.canViewSales;
    if (stockRoutes.contains(location))        return AppUser.canViewStock;
    return null; // dashboard or unrecognised → any authenticated user OK
  }

  final List<String> _publicRoutes = [
    AppRoutes.login,
    AppRoutes.forgotPassword,
    AppRoutes.onboarding,
  ];

  String? _redirectGuard(BuildContext context, GoRouterState state) {
    final session = sl<SessionBloc>().state;
    final location = state.matchedLocation;

    // Public routes: kick authenticated user to dashboard; allow unauthenticated
    if (_publicRoutes.contains(location)) {
      if (session.status == SessionStatus.authenticated) {
        return AppRoutes.dashboard;
      }
      return null;
    }

    // Session unknown: hold position (check in progress)
    if (session.status == SessionStatus.unknown) return null;

    // Unauthenticated: redirect to login
    if (session.status == SessionStatus.unauthenticated) return AppRoutes.login;

    // Authenticated: check permission
    final required = _permissionForRoute(location);
    if (required != null && !(session.user?.can(required) ?? false)) {
      return AppRoutes.dashboard;
    }

    return null; // allow
  }

  final GoRouter appRouter = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.onboarding,
    redirect: _redirectGuard,
    refreshListenable: GoRouterRefreshStream(sl<SessionBloc>().stream),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const HomePage(),
      ),
      // --- Stub routes for future modules (screens not yet built) ---
      // These exist so AppRoutes constants resolve and the permission map works.
      // Replace builder with real screen when each module is implemented.
      GoRoute(path: AppRoutes.units,          builder: (c, s) => _stub('Units')),
      GoRoute(path: AppRoutes.categories,     builder: (c, s) => _stub('Categories')),
      GoRoute(path: AppRoutes.materials,      builder: (c, s) => _stub('Materials')),
      GoRoute(path: AppRoutes.suppliers,      builder: (c, s) => _stub('Suppliers')),
      GoRoute(path: AppRoutes.customers,      builder: (c, s) => _stub('Customers')),
      GoRoute(path: AppRoutes.branches,       builder: (c, s) => _stub('Branches')),
      GoRoute(path: AppRoutes.purchases,      builder: (c, s) => _stub('Purchases')),
      GoRoute(path: AppRoutes.purchaseNew,    builder: (c, s) => _stub('New Purchase')),
      GoRoute(path: AppRoutes.sales,          builder: (c, s) => _stub('Sales')),
      GoRoute(path: AppRoutes.saleNew,        builder: (c, s) => _stub('New Sale')),
      GoRoute(path: AppRoutes.paymentVouchers,   builder: (c, s) => _stub('Payment Vouchers')),
      GoRoute(path: AppRoutes.paymentVoucherNew, builder: (c, s) => _stub('New Payment Voucher')),
      GoRoute(path: AppRoutes.receiptVouchers,   builder: (c, s) => _stub('Receipt Vouchers')),
      GoRoute(path: AppRoutes.receiptVoucherNew, builder: (c, s) => _stub('New Receipt Voucher')),
      GoRoute(path: AppRoutes.transfers,      builder: (c, s) => _stub('Transfers')),
      GoRoute(path: AppRoutes.transferNew,    builder: (c, s) => _stub('New Transfer')),
      GoRoute(path: AppRoutes.stock,          builder: (c, s) => _stub('Stock')),
      GoRoute(path: AppRoutes.ledger,         builder: (c, s) => _stub('Credit Ledger')),
      GoRoute(path: AppRoutes.reports,        builder: (c, s) => _stub('Reports')),
    ],
  );

  /// Temporary stub screen shown for routes not yet implemented.
  Widget _stub(String name) => Scaffold(
        appBar: AppBar(title: Text(name)),
        body: Center(child: Text('$name — not yet implemented')),
      );
  ```
  Add `import 'package:flutter/material.dart';` if not already present.
  Save the file.

- [X] T015 [US1] Update `lib/src/shared/wrappers/state_wrapper.dart` to provide `SessionBloc` from `get_it` instead of constructing it inline.
  Open `lib/src/shared/wrappers/state_wrapper.dart`. Find where `SessionBloc` is provided (likely inside a `BlocProvider` or `MultiBlocProvider`). Replace the construction `SessionBloc(repository: ...)` with `sl<SessionBloc>()` and change the provider type to `BlocProvider.value`:
  ```dart
  BlocProvider<SessionBloc>.value(value: sl<SessionBloc>()),
  ```
  Add this import at the top of the file:
  ```dart
  import 'package:perfum_ahmed_gaper/src/services/service_locator.dart';
  ```
  Save the file.

- [X] T016 [US1] Run `flutter analyze` on all files modified in Phase 3:
  ```
  lib/src/config/app_config.dart
  lib/src/services/auth_service.dart
  lib/src/services/service_locator.dart
  lib/main.dart
  lib/src/routing/app_router.dart
  lib/src/routing/go_router_refresh_stream.dart
  lib/src/shared/wrappers/state_wrapper.dart
  ```
  Fix ALL reported errors and warnings before continuing.
  Expected result: zero issues.

**Checkpoint US1**: Run the app (`flutter run -d chrome`). Open browser → navigate to `http://localhost:<port>/materials`. Verify browser URL becomes `/login`. No materials content visible. Quickstart Scenario 1 passes.

---

## Phase 4: User Story 2 — JWT Auto-Injection on Every Request (Priority: P2)

**Goal**: Every outgoing API call carries `Authorization: Bearer <token>` automatically.
No screen or cubit code adds the header manually.

**Independent Test**: Log in → open DevTools Network tab → navigate to any stub route that makes an API call → every request to the backend has `Authorization: Bearer <token>` in headers. See quickstart.md Scenario 2.

**Depends on**: Phase 3 complete (interceptor added in T008, token read logic in place).

### Implementation for User Story 2

- [X] T017 [US2] Verify the JWT interceptor wired in T008 is correct by reading `lib/src/config/app_config.dart` and confirming:
  1. The JWT interceptor is the SECOND interceptor (after logging).
  2. `onRequest` calls `SecureStorageService.instance.read(kJwtTokenKey)` and sets the `Authorization` header when a token is present.
  3. `onError` only acts on `statusCode == 401`.
  4. Both handlers end with `return handler.next(...)`.
  If any of these are wrong, fix them now. If all correct, mark task complete.

- [X] T018 [US2] Update `lib/src/features/auth/data/repositories/auth_repository_impl.dart` to save the JWT token after a successful login.
  Open the file. In the `login()` method, after the `AppUser` is constructed and before `return right(user)`, add:
  ```dart
  // Save token to secure storage so the interceptor can read it
  final token = userData['token'] as String? ?? userData['accessToken'] as String? ?? '';
  if (token.isNotEmpty) {
    await SecureStorageService.instance.write(kJwtTokenKey, token);
  }
  ```
  Add this import at the top of the file:
  ```dart
  import 'package:perfum_ahmed_gaper/src/services/service_locator.dart';
  ```
  (`SecureStorageService` import should already be present via the services barrel; if not, add it.)
  Save the file.

- [X] T019 [US2] Update `lib/src/features/auth/data/repositories/auth_repository_impl.dart` to clear the JWT token on logout.
  In the `logout()` method, before calling `_authService.logout()`, add:
  ```dart
  await SecureStorageService.instance.delete(kJwtTokenKey);
  ```
  Save the file.

- [X] T020 [US2] Update `lib/src/features/auth/data/repositories/auth_repository_impl.dart` — fix the `id` field mapping.
  In both `login()` and `signUp()`, change the line:
  ```dart
  id: data['id'].toString(),
  ```
  to:
  ```dart
  id: (data['_id'] ?? data['id'] ?? '').toString(),
  ```
  This handles MongoDB's `_id` field name as well as `id`. Save the file.

- [X] T021 [US2] Update `lib/src/features/auth/data/repositories/auth_repository_impl.dart` — map the `permissions` field from the login response onto `AppUser`.
  In the `login()` and `signUp()` `AppUser(...)` constructors, add:
  ```dart
  permissions: (data['permissions'] as int?) ?? 0,
  ```
  The complete `AppUser(...)` call should now look like:
  ```dart
  final user = AppUser(
    id: (data['_id'] ?? data['id'] ?? '').toString(),
    email: data['email'] ?? email,
    name: data['name'],
    permissions: (data['permissions'] as int?) ?? 0,
  );
  ```
  Save the file.

- [X] T022 [US2] Run `flutter analyze lib/src/features/auth/data/repositories/auth_repository_impl.dart` and fix any errors.
  Expected result: zero issues.

**Checkpoint US2**: Log in with valid credentials → open DevTools Network tab → navigate to any route → confirm `Authorization: Bearer <token>` header present on every request. Quickstart Scenario 2 passes.

---

## Phase 5: User Story 3 — Centralized Dependency Registry (Priority: P3)

**Goal**: All singletons are resolvable via `sl<T>()` before the first widget is built.
Adding a new module's repository requires touching only `service_locator.dart`.

**Independent Test**: App boots without errors. `sl<SessionBloc>()` resolves immediately (no LateInitializationError). Quickstart Scenario 6 passes.

**Depends on**: Phase 3 and 4 complete (T010–T011 registered the singletons).

### Implementation for User Story 3

- [X] T023 [US3] Update `lib/src/shared/wrappers/session_listener_wrapper.dart` to handle the `unauthenticated` state navigation (defense-in-depth).
  Open `lib/src/shared/wrappers/session_listener_wrapper.dart`. Replace its `build()` method with:
  ```dart
  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == SessionStatus.unauthenticated) {
          context.go(AppRoutes.login);
        }
      },
      child: child,
    );
  }
  ```
  Ensure these imports are present at the top of the file:
  ```dart
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:go_router/go_router.dart';
  import 'package:perfum_ahmed_gaper/src/features/auth/presentation/providers/session_bloc.dart';
  import 'package:perfum_ahmed_gaper/src/routing/app_routes.dart';
  ```
  Save the file.

- [X] T024 [US3] Verify `lib/src/shared/wrappers/state_wrapper.dart` provides BOTH `SessionBloc` and `AuthBloc` from `get_it`.
  Open the file. Confirm that `AuthBloc` is also provided using `BlocProvider.value`:
  ```dart
  BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
  ```
  If `AuthBloc` is constructed inline (not from `sl`), replace it. Add the import:
  ```dart
  import 'package:perfum_ahmed_gaper/src/features/auth/presentation/providers/auth_bloc.dart';
  ```
  Save the file.

- [X] T025 [US3] Run `flutter analyze` on all wrappers and the locator:
  ```
  lib/src/shared/wrappers/state_wrapper.dart
  lib/src/shared/wrappers/session_listener_wrapper.dart
  lib/src/services/service_locator.dart
  ```
  Fix ALL errors. Expected result: zero issues.

- [X] T026 [US3] Run the full app in debug mode (`flutter run -d chrome`) and confirm:
  1. Console shows no `LateInitializationError` or `Object/factory not registered` errors.
  2. App starts and shows the `/onboarding` or `/login` screen (depending on stored session).
  3. Navigating to `/login` when unauthenticated works.
  Mark complete only after confirming all three. Quickstart Scenarios 4 and 6 pass.

**Checkpoint US3**: All singletons registered, app boots cleanly, session listener active.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final analysis pass, remove any remaining raw string paths, confirm all
constitution quality gates.

- [X] T027 Run `grep -r "'/login'" lib/src/` (or search in IDE) to find any raw string route literals outside `AppRoutes`. Replace each with the appropriate `AppRoutes.xxx` constant. Expected: zero raw route strings outside `app_routes.dart` and `go_router_refresh_stream.dart`.

- [X] T028 Run `grep -r "'jwt_token'" lib/src/` to find any raw token key strings outside `service_locator.dart`. Replace each with `kJwtTokenKey`. Expected: zero raw `'jwt_token'` strings outside `service_locator.dart`.

- [X] T029 [P] Verify constitution quality gates — check each item manually:
  - [X] `lib/src/features/auth/domain/` has zero imports of `package:flutter`, `package:dio`, or `package:json_annotation`
  - [X] `AppUser.id` is `String` — not `int`
  - [X] `service_locator.dart` registers `AuthRepository` (interface), not `AuthRepositoryImpl` directly
  - [X] `app_router.dart` reads `sl<SessionBloc>()` — no `context.read<SessionBloc>()`
  - [X] `app_config.dart` interceptor does NOT call `context.go()` — navigation is zero inside the interceptor
  Fix any violations found.

- [X] T030 Run `flutter analyze` on the entire `lib/` directory:
  ```
  flutter analyze lib/
  ```
  Fix ALL errors and warnings. The project MUST pass analysis cleanly before Phase 0 is considered complete.

- [X] T031 [P] Update `PLAN.md` (project root) — change the Auth module status in Section 7 from `Not started` to `Phase 0 ✅ Done`:
  ```markdown
  | Auth | Phase 0 ✅ Done — infrastructure wired |
  ```
  Save the file.

**Checkpoint Phase 6 (Final)**: Run quickstart.md Scenarios 1–7 in order. All must pass.
Phase 0 is complete when all 8 quickstart scenarios are green.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1 completion. BLOCKS all user stories.
- **Phase 3 (US1)**: Depends on Phase 2. Implements the redirect guard (P1 story).
- **Phase 4 (US2)**: Depends on Phase 3 (interceptor skeleton created in T008). Completes token persistence logic.
- **Phase 5 (US3)**: Depends on Phase 3 and 4 (registry populated in T010–T011). Completes DI wiring.
- **Phase 6 (Polish)**: Depends on all prior phases.

### Within Each Phase

- Tasks marked `[P]` in the same phase can be done in any order (different files).
- Tasks WITHOUT `[P]` must be done in the listed order (they modify the same file or depend on the previous task's output).
- Never start a task if the previous non-parallel task in the same file is incomplete.

### User Story Dependencies

- **US1 (P1)**: Can start immediately after Phase 2. No dependency on US2 or US3.
- **US2 (P2)**: Depends on US1 (interceptor skeleton from T008 must exist).
- **US3 (P3)**: Depends on US1 (registry populated in T010–T011 must exist).

---

## Parallel Opportunities

### Phase 2 (Foundational)

```
T004 (failure.dart)    ← can run in parallel with →    T005 (user.dart)
T006 (app_routes.dart) ← can run in parallel with →    T004 and T005
Run T007 AFTER all three complete.
```

### Phase 3 (US1)

```
T008 (app_config.dart)    — sequential
T009 (auth_service.dart)  — can run in parallel with T008 (different file)
T010 (service_locator.dart registrations) — after T009 (auth_service used)
T011 (service_locator.dart blocs)         — after T010 (sequential, same file)
T012 (boot failure wrap)                  — after T011 (sequential, same file)
T013 (main.dart)                          — after T012 (locator must be complete)
T014 (app_router.dart)                    — after T013 (sl<SessionBloc>() must be registered)
T015 (state_wrapper.dart)                 — can run in parallel with T014 (different file)
T016 (analyze)                            — after T014 and T015 both complete
```

---

## Implementation Strategy

### MVP: Complete User Story 1 First (Phases 1–3)

1. Phase 1: Setup (T001–T003) — ~10 min
2. Phase 2: Foundational (T004–T007) — ~15 min
3. Phase 3: US1 (T008–T016) — ~30 min
4. **STOP**: Run quickstart Scenario 1. Confirm redirect works.
5. Continue to Phase 4 (US2) only after Scenario 1 passes.

### Incremental Delivery

```
Phase 1 + 2 → Foundation ready (no visible change to app)
Phase 3     → US1 complete → Redirect guard working ✅
Phase 4     → US2 complete → Token injection working ✅
Phase 5     → US3 complete → Full DI wiring ✅
Phase 6     → Polish → All quickstart scenarios green ✅
```

### Common Mistakes to Avoid

1. **Do NOT** use `context.go()` inside `app_config.dart` (the interceptor). Navigation must only happen via the router guard or `SessionListenerWrapper`.
2. **Do NOT** use `'jwt_token'` as a raw string anywhere. Always use `kJwtTokenKey`.
3. **Do NOT** start `SessionBloc` as `registerLazySingleton` — it MUST be `registerSingleton` (eager) so it fires `SessionCheckRequested` before the router runs.
4. **Do NOT** use `context.read<SessionBloc>()` inside `app_router.dart`. Use `sl<SessionBloc>()`.
5. **Do NOT** skip `flutter analyze` between phases — errors compound and become harder to fix later.

---

## Notes

- `[P]` tasks = can run in any order relative to other `[P]` tasks in the same phase (different files, no blocking dependency)
- `[US1]`/`[US2]`/`[US3]` label maps each task to its user story for traceability
- Each user story checkpoint is independently testable via quickstart.md
- The stub routes in T014 are intentional — they ensure all `AppRoutes` constants resolve without requiring real screens to be built yet
- All parametric routes (`:id`) are defined in `AppRoutes` but their `GoRoute` entries are NOT added in Phase 0 (no stub builder for parametric routes — add when the module is built in Phase 3+)
