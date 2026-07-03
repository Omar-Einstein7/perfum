import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/session.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/bloc/auth_state.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockLoginUseCase loginUseCase;
  late MockAuthRepository repository;
  late AuthBloc authBloc;

  setUp(() {
    loginUseCase = MockLoginUseCase();
    repository = MockAuthRepository();
    authBloc = AuthBloc(loginUseCase: loginUseCase, repository: repository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('LoginSubmitted', () {
    const email = 'test@example.com';
    const password = 'Test@123';
    final session = Session(
      accessToken: 'token',
      refreshToken: 'refresh',
      expiresIn: 900,
    );
    final user = User(
      id: '1',
      email: email,
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

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] when login succeeds',
      setUp: () {
        when(
          () => loginUseCase(email, password),
        ).thenAnswer((_) async => session);
        when(() => repository.getMe()).thenAnswer((_) async => user);
      },
      build: () => authBloc,
      act: (bloc) =>
          bloc.add(const LoginSubmitted(email: email, password: password)),
      expect: () => [isA<AuthLoading>(), isA<Authenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] when login fails',
      setUp: () {
        when(
          () => loginUseCase(email, password),
        ).thenThrow(Exception('Invalid credentials'));
      },
      build: () => authBloc,
      act: (bloc) =>
          bloc.add(const LoginSubmitted(email: email, password: password)),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
    );
  });
}
