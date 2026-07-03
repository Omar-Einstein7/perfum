import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/bloc/auth_state.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockAuthRepository extends Mock implements AuthRepository {}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          final user = state.user;
          return Scaffold(
            body: Column(
              children: [
                Text(user?.email ?? ''),
                Text(user?.role ?? ''),
                Text(user?.status ?? ''),
                if (user?.permissions['p_info'] == true) const Text('p_info'),
              ],
            ),
          );
        }
        return const Scaffold(body: Text('Not authenticated'));
      },
    );
  }
}

Widget createTestWidget(AuthBloc authBloc) {
  return MaterialApp(
    home: BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: const ProfilePage(),
    ),
  );
}

void main() {
  late MockLoginUseCase loginUseCase;
  late MockAuthRepository repository;

  setUp(() {
    loginUseCase = MockLoginUseCase();
    repository = MockAuthRepository();
  });

  testWidgets('should display user info when authenticated', (tester) async {
    final authBloc = AuthBloc(
      loginUseCase: loginUseCase,
      repository: repository,
    );
    final user = User(
      id: '1',
      email: 'staff@example.com',
      role: 'staff',
      status: 'active',
      permissions: {
        'p_info': true,
        'p_res': false,
        'p_sell': false,
        'p_snadat': false,
        'p_user': false,
        'p_report': false,
        'p_report2': false,
      },
    );
    authBloc.emit(Authenticated(user: user));

    await tester.pumpWidget(createTestWidget(authBloc));
    await tester.pumpAndSettle();

    expect(find.text('staff@example.com'), findsOneWidget);
    expect(find.text('staff'), findsOneWidget);
    expect(find.text('active'), findsOneWidget);
    expect(find.text('p_info'), findsOneWidget);

    authBloc.close();
  });

  testWidgets('should show not authenticated when unauthenticated', (
    tester,
  ) async {
    final authBloc = AuthBloc(
      loginUseCase: loginUseCase,
      repository: repository,
    );
    authBloc.emit(AuthInitial());

    await tester.pumpWidget(createTestWidget(authBloc));
    await tester.pumpAndSettle();

    expect(find.text('Not authenticated'), findsOneWidget);

    authBloc.close();
  });
}
