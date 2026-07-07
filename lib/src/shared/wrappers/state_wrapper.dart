import '../../imports/imports.dart';
import '../../services/service_locator.dart';
import '../../features/auth/presentation/providers/auth_bloc.dart';
import '../../features/auth/presentation/providers/session_bloc.dart';

/// A wrapper to initialize the chosen State Management library.
class StateWrapper extends StatelessWidget {
  final Widget child;

  const StateWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionBloc>.value(value: sl<SessionBloc>()),
        BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
      ],
      child: child,
    );
  }
}
