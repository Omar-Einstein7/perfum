import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/bloc/session_bloc.dart';
import 'package:perfum_ahmed_gaper/src/routing/app_routes.dart';

class SessionListenerWrapper extends StatelessWidget {
  final Widget child;
  const SessionListenerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (prev, next) => prev.status != next.status,
      listener: (context, state) {
        if (state.status != SessionStatus.unknown) {
          FlutterNativeSplash.remove();
          if (state.status == SessionStatus.authenticated) {
            context.go(AppRoutes.home);
          } else if (state.status == SessionStatus.unauthenticated) {
            context.go(AppRoutes.login);
          }
        }
      },
      child: child,
    );
  }
}
