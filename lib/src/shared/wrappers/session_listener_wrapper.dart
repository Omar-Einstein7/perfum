import 'package:perfum_ahmed_gaper/src/imports/core_imports.dart';
import 'package:perfum_ahmed_gaper/src/imports/packages_imports.dart';

import 'package:perfum_ahmed_gaper/src/features/auth/presentation/providers/session_bloc.dart';

class SessionListenerWrapper extends StatelessWidget {
  final Widget child;
  const SessionListenerWrapper({super.key, required this.child});

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
}
