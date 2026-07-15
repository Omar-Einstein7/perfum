<!--
  Sync Impact Report
  ==================
  Version change: 1.0.0 → 1.1.0
  Modified principles: None (titles unchanged)
  Added sections: None
  Expanded sections:
    - Architecture & Stack: materially expanded with project-mapped directory
      tree, actual import system, feature layout, screen pattern, theme setup,
      app entry-point flow, and development conventions drawn from real code.
    - Development Workflow & Quality Gates: added conventions observed in code
      (HookWidget→_View pattern, providers directory naming, no usercases yet,
      service→repository→bloc chain).
  Removed sections: None
  Templates requiring updates:
    - .specify/templates/plan-template.md ✅ still compatible
    - .specify/templates/spec-template.md ✅ no changes needed
    - .specify/templates/tasks-template.md ✅ no changes needed
  Follow-up TODOs: None.
-->

# Ahmed Gaber Perfume Constitution

## Core Principles

### I. Server-Authoritative Security

All financial totals (before/after discount/final) MUST be computed
server-side only. No code path SHALL accept a pre-computed total from
the client. Every sensitive endpoint MUST check a real server-side
permission (middleware) — hiding a button in the UI is never an
acceptable substitute. The `employee_id` and `branch_id` values MUST
always come from the JWT/session; they SHALL NOT be manually entered in
any form.

**Rationale**: Trusting client-submitted totals or relying on UI gating
creates exploitable gaps. Session-authoritative identity prevents
impersonation and data-access violations.

### II. Branch Autonomy

Every branch MUST be 100% independent, financially and in stock. No
table or logic for inter-branch stock transfer exists
(`branch_transfers` is permanently removed, even as a future idea,
without reopening the discussion).

**Rationale**: Branch independence simplifies accounting, eliminates
reconciliation complexity, and ensures each branch's P&L is a true
reflection of its own operations.

### III. Offline-First

Every operation — without exception — MUST work offline-first. Every
write MUST be saved locally first (via `sync_queue`) and uploaded later.
A `client_generated_uuid` per operation MUST serve as the idempotency
key to prevent duplicate processing on sync.

**Rationale**: POS and inventory operations cannot depend on continuous
connectivity. Offline-first guarantees availability and data integrity
regardless of network state.

### IV. Feature Separation (Retail/Wholesale)

Retail and Wholesale MUST be fully separate features in code — different
Bloc, different route. Merging them via a toggle/flag is NOT allowed.

**Rationale**: Distinct pricing, discount, inventory, and reporting
rules for each channel make a unified code path fragile and
unmaintainable. Separate Blocs and routes keep each flow testable and
evolvable independently.

### V. Data & UX Standards

All quantities MUST be numeric (double/decimal), not integer.
User-facing messages MUST be in clear Arabic, not raw technical English.

**Rationale**: Fractional quantities (e.g., 0.5 kg, 1.75 L) are
required for perfumery inventory. Arabic messages ensure the primary
user base can operate the system without ambiguity.

## Architecture & Stack

The project uses Clean Architecture under `lib/src/`:

```text
lib/
├── main.dart                           # Entry: splash → i18n → dotenv → dio → hive
└── src/
    ├── app.dart                        # CupertinoApp.router wrapping Material Theme
    ├── flavours.dart
    ├── config/
    │   └── app_config.dart             # Dio singleton init, baseUrl from .env
    ├── extensions/
    │   ├── context_extension.dart      # Theme/size/routing overlays shortcuts
    │   ├── string_extension.dart
    │   ├── num_extension.dart
    │   ├── collection_extension.dart
    │   ├── date_time_extension.dart
    │   └── widget_extension.dart
    ├── features/
    │   └── <feature>/
    │       ├── data/
    │       │   ├── models/             # fromJson/toJson (data shape)
    │       │   └── repositories/       # Impl -> calls services
    │       ├── domain/
    │       │   ├── entities/           # Pure Dart, no fromJson
    │       │   └── repositories/       # Interface contract
    │       └── presentation/
    │           ├── providers/          # BLoC files live here
    │           └── screens/            # HookWidget → _View pattern
    ├── imports/
    │   ├── imports.dart                # Re-exports both below
    │   ├── core_imports.dart           # SDK + project core (config, routing, services, shared)
    │   └── packages_imports.dart       # Third-party (fpdart, dio, bloc, hive, etc.)
    ├── routing/
    │   ├── app_router.dart             # GoRouter with all routes
    │   ├── app_routes.dart             # Path constants (AppRoutes.login, etc.)
    │   └── global_navigator.dart       # rootNavigatorKey, rootContext
    ├── services/
    │   ├── auth_service.dart
    │   ├── dio_service.dart
    │   ├── hive_service.dart
    │   ├── storage_service.dart
    │   ├── secure_storage_service.dart
    │   ├── internet_connection_service.dart
    │   ├── location_service.dart
    │   ├── media_service.dart
    │   ├── path_service.dart
    │   ├── permission_service.dart
    │   ├── copy_service.dart
    │   ├── device_info_service.dart
    │   ├── url_launcher_service.dart
    │   └── version_update_service.dart
    ├── shared/
    │   ├── app_assets.dart
    │   ├── enums/                      # AppStatus, ButtonSize, SnackBarType
    │   ├── helpers/                    # showToast, showAppDialog, showAppSheet
    │   ├── hooks/                      # useCopy, useLaunchUrl, usePermission, useTimer
    │   ├── widgets/                    # AppButton, AppTextField, AppCard, AppTopBar, etc.
    │   └── wrappers/                   # LocalizationWrapper, StateWrapper, ScreenUtilWrapper,
    │                                   # SkeletonWrapper, SessionListenerWrapper
    ├── theme/
    │   ├── theme.dart                  # buildLightTheme/buildDarkTheme/buildCupertinoTheme
    │   ├── color_schemes.dart          # AppColorsExtension + AppPalettes (light/dark)
    │   ├── text_theme.dart
    │   ├── theme_constants.dart        # Barrel for AppSpacing, AppBorders, etc.
    │   ├── app_spacing.dart
    │   ├── app_borders.dart
    │   ├── app_shadows.dart
    │   ├── app_durations.dart
    │   └── app_curves.dart
    └── utils/
        ├── app_utils.dart
        ├── debouncer.dart
        ├── error_handler.dart         # AppErrorHandler
        ├── failure.dart               # Failure, ServerFailure, CacheFailure, NetworkFailure
        ├── input_formatters.dart
        ├── logger.dart                # AppLogger
        ├── platform_info.dart
        ├── task_runner.dart           # runTask() -> FutureEither<T>
        └── typedefs.dart             # FutureEither<T>, FutureEitherVoid, StreamEither<T>
```

### Technology stack

- **State management**: flutter_bloc (BLoC files in `presentation/providers/`)
- **Navigation**: go_router via `CupertinoApp.router` with centralized route table
- **Networking**: Dio (shared singleton from AppConfig)
- **Local storage**: Hive CE, SharedPreferences, flutter_secure_storage
- **Localization**: easy_localization (en, ar)
- **Screen adaptation**: flutter_screenutil
- **Utilities**: flutter_hooks, flutter_dotenv, fpdart (Either), equatable, skeletonizer,
  cached_network_image, flutter_animate, smooth_page_indicator, logger

### Architecture rules

- `domain/` is pure Dart — no Flutter imports, no imports from `data/`.
- `data/` implements repository contracts from `domain/` — never the reverse.
- Entities have no `fromJson`/`toJson` — models in `data/models/` handle
  serialization and map to entities.
- `presentation/providers/` holds BLoC files (Bloc/Event/State in one file).
- Screen pattern: a `HookWidget` reads state and controllers, then delegates
  rendering to a private `StatelessWidget _View`.
- Services are singletons with `.instance`, returning `FutureEither<T>` via
  `runTask()`. No `BuildContext` is passed into services — use `rootContext`
  from `global_navigator.dart` when UI feedback is needed.
- No business logic in widget `build()` methods.
- No direct backend or network calls from presentation widgets — always go
  through service → repository → Bloc chain.
- Import via `package:perfume_ahmed_gaber/src/imports/imports.dart` barrel
  (or `core_imports.dart` / `packages_imports.dart` individually).

### App entry point flow

```
main()
├── WidgetsFlutterBinding.ensureInitialized()
├── FlutterNativeSplash.preserve()
├── EasyLocalization.ensureInitialized()
├── dotenv.load()
├── AppConfig.init()        → Dio singleton
├── HiveService.instance.init()
└── runApp(
      LocalizationWrapper →
        StateWrapper →
          App (ScreenUtilWrapper →
            CupertinoApp.router →
              SkeletonWrapper → SessionListenerWrapper →
                Theme(buildLightTheme/buildDarkTheme)))
```

## Development Workflow & Quality Gates

- Events and states MUST be immutable — prefer `const` constructors.
- BLoC event handlers delegate to repository use cases or services — no heavy
  logic inside handlers.
- One BLoC per feature flow — do not share Blocs across unrelated features.
- All routes defined in `lib/src/routing/app_router.dart` with path constants
  in `app_routes.dart` — no hard-coded path strings in widgets.
- Redirects and guards belong in the router configuration, not inside screens.
- Logging via `AppLogger` (info/success/warning/error); user feedback via
  `showGlobalToast()` or `showAppDialog()`.
- All transport errors mapped to `Failure` variants via `runTask()` —
  `DioException` never leaked to UI.
- Every feature follows: `domain/entities/` → `domain/repositories/` (contract)
  → `data/models/` → `data/repositories/` (impl) → `presentation/providers/`
  (Bloc) → `presentation/screens/` → route registration in `app_router.dart`.
- Verification: `flutter pub get` → `flutter analyze` → `flutter test`.

## Governance

This Constitution supersedes all other practices. Amendments require:

1. A documented proposal describing the change and its rationale.
2. Approval from the project maintainer(s).
3. A migration plan for any code or processes affected.
4. Version bump per semantic versioning rules:
   - **MAJOR**: Backward-incompatible governance/principle removals or
     redefinitions.
   - **MINOR**: New principle/section added or materially expanded
     guidance.
   - **PATCH**: Clarifications, wording, typo fixes, non-semantic
     refinements.
5. All PRs and reviews MUST verify compliance with this Constitution.
   Complexity MUST be justified when it conflicts with any principle.

**Version**: 1.1.0 | **Ratified**: 2026-07-15 | **Last Amended**: 2026-07-15
