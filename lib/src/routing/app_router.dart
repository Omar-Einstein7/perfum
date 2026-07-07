import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:perfum_ahmed_gaper/src/routing/global_navigator.dart';
import 'package:perfum_ahmed_gaper/src/routing/app_routes.dart';
import 'package:perfum_ahmed_gaper/src/services/service_locator.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/providers/session_bloc.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/routing/go_router_refresh_stream.dart';

import 'package:perfum_ahmed_gaper/src/features/auth/presentation/screens/login_screen.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/screens/signup_screen.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/screens/forgot_password_screen.dart';

import 'package:perfum_ahmed_gaper/src/features/home/presentation/screens/home_page.dart';
import 'package:perfum_ahmed_gaper/src/features/onboarding/presentation/screens/onboarding_page.dart';
import 'package:perfum_ahmed_gaper/src/features/units/presentation/bloc/unit_cubit.dart';
import 'package:perfum_ahmed_gaper/src/features/units/presentation/pages/units_list_page.dart';

/// Maps a UI route path to its required permission flag.
/// Returns null if any authenticated user may access the route.
int? _permissionForRoute(String location) {
  // Write routes (require edit permission)
  if (location.startsWith(AppRoutes.purchaseNew)) return AppUser.canEditPurchases;
  if (location.startsWith(AppRoutes.paymentVouchers)) return AppUser.canEditPurchases;
  if (location.startsWith(AppRoutes.paymentVoucherNew)) return AppUser.canEditPurchases;
  if (location.startsWith(AppRoutes.transfers)) return AppUser.canEditPurchases;
  if (location.startsWith(AppRoutes.transferNew)) return AppUser.canEditPurchases;
  if (location.startsWith(AppRoutes.saleNew)) return AppUser.canEditSales;
  if (location.startsWith(AppRoutes.receiptVouchers)) return AppUser.canEditSales;
  if (location.startsWith(AppRoutes.receiptVoucherNew)) return AppUser.canEditSales;

  // Master data routes
  if (location.startsWith(AppRoutes.units)) return AppUser.canEditMasters;
  if (location.startsWith(AppRoutes.categories)) return AppUser.canEditMasters;
  if (location.startsWith(AppRoutes.materials)) return AppUser.canEditMasters;
  if (location.startsWith(AppRoutes.suppliers)) return AppUser.canEditMasters;
  if (location.startsWith(AppRoutes.customers)) return AppUser.canEditMasters;
  if (location.startsWith(AppRoutes.branches)) return AppUser.canEditMasters;

  // View-only routes
  if (location == AppRoutes.purchases) return AppUser.canViewPurchases;
  if (location.startsWith(AppRoutes.purchaseDetail.replaceAll(':id', ''))) return AppUser.canViewPurchases;
  if (location == AppRoutes.sales) return AppUser.canViewSales;
  if (location.startsWith(AppRoutes.saleDetail.replaceAll(':id', ''))) return AppUser.canViewSales;

  // Stock / reports
  if (location == AppRoutes.stock || location == AppRoutes.ledger || location == AppRoutes.reports) {
    return AppUser.canViewStock;
  }

  return null; // dashboard or unrecognised -> any authenticated user OK
}

final List<String> _publicRoutes = [
  AppRoutes.login,
  AppRoutes.signUp,
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
      path: AppRoutes.signUp,
      name: 'signUp',
      builder: (context, state) => const SignupScreen(),
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
    GoRoute(path: AppRoutes.units,          builder: (c, s) => BlocProvider(create: (_) => sl<UnitCubit>(), child: const UnitsListPage())),
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
      body: Center(child: Text('$name \u2014 not yet implemented')),
    );
