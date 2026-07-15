import 'package:go_router/go_router.dart';
import 'package:perfum_ahmed_gaper/src/routing/global_navigator.dart';
import 'package:perfum_ahmed_gaper/src/routing/app_routes.dart';
import 'package:perfum_ahmed_gaper/src/services/di_container.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/providers/auth_bloc.dart';

import 'package:perfum_ahmed_gaper/src/features/auth/presentation/screens/login_screen.dart';

import 'package:perfum_ahmed_gaper/src/features/home/presentation/screens/home_page.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.login,
  redirect: (context, state) {
    final authBloc = sl<AuthBloc>();
    final authState = authBloc.state;
    final isAuthenticated = authState.isAuthenticated;
    final location = state.uri.toString();

    final publicRoutes = [AppRoutes.login];
    final isPublicRoute = publicRoutes.any((r) => location.startsWith(r));

    if (!isAuthenticated && !isPublicRoute) {
      return AppRoutes.login;
    }

    if (isAuthenticated && isPublicRoute) {
      return AppRoutes.dashboard;
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      name: 'dashboard',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
  ],
);
