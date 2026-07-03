import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:perfum_ahmed_gaper/src/routing/global_navigator.dart';
import 'package:perfum_ahmed_gaper/src/routing/app_routes.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/auth.dart';
import 'package:perfum_ahmed_gaper/src/shared/widgets/forbidden_page.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.login,
  redirect: (context, state) {
    final sessionBloc = context.read<SessionBloc>();
    final sessionState = sessionBloc.state;
    final isAuthenticated = sessionState.status == SessionStatus.authenticated;
    final location = state.uri.toString();

    final publicRoutes = [
      AppRoutes.login,
      AppRoutes.onboarding,
      AppRoutes.signup,
      AppRoutes.forgotPassword,
    ];
    final isPublicRoute = publicRoutes.any(
      (r) => location == r || location.startsWith('$r?'),
    );

    if (!isAuthenticated && !isPublicRoute) {
      return AppRoutes.login;
    }

    if (isAuthenticated && isPublicRoute) {
      return AppRoutes.home;
    }

    if (isAuthenticated) {
      final user = sessionState.user;
      if (user != null && !_hasRequiredPermission(location, user.permissions)) {
        return '/403';
      }
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      pageBuilder: (context, state) =>
          NoTransitionPage(key: state.pageKey, child: const LoginScreen()),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const _HomePlaceholder(),
    ),
    GoRoute(
      path: '/users',
      name: 'users',
      builder: (context, state) => const UserManagementScreen(),
    ),
    GoRoute(
      path: '/403',
      name: 'forbidden',
      builder: (context, state) => const ForbiddenPage(),
    ),
  ],
);

final Map<String, List<String>> _routePermissionMap = {
  '/materials': ['p_info'],
  '/categories': ['p_info'],
  '/units': ['p_info'],
  '/suppliers': ['p_res'],
  '/purchase-invoices': ['p_res'],
  '/customers': ['p_sell'],
  '/sales-invoices': ['p_sell'],
  '/vouchers': ['p_snadat'],
  '/users': ['p_user'],
  '/reports': ['p_report', 'p_report2'],
};

bool _hasRequiredPermission(String location, Map<String, bool> permissions) {
  for (final entry in _routePermissionMap.entries) {
    if (location.startsWith(entry.key)) {
      return entry.value.any((flag) => permissions[flag] == true);
    }
  }
  return true;
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Home Page - Replace with actual home')),
    );
  }
}
