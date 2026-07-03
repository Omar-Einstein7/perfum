import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:perfum_ahmed_gaper/src/config/di/injection_container.dart'
    as di;
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/bloc/session_bloc.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/bloc/user_management_bloc.dart';

class StateWrapper extends StatelessWidget {
  final Widget child;

  const StateWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.getIt<SessionBloc>()),
        BlocProvider(create: (_) => di.getIt<AuthBloc>()),
        BlocProvider(create: (_) => di.getIt<UserManagementBloc>()),
      ],
      child: child,
    );
  }
}
