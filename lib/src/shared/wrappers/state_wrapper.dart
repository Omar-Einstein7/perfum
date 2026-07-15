import '../../imports/imports.dart';
import '../../features/auth/presentation/providers/auth_bloc.dart';
import '../../features/auth/presentation/providers/session_bloc.dart';

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
        BlocProvider<SessionBloc>(create: (_) => sl<SessionBloc>()),
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
      ],
      child: child,
    );
  }
}
