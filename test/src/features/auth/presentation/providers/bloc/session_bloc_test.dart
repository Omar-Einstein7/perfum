import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/check_session_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/logout_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/providers/session_bloc.dart';

class MockCheckSessionUseCase extends Mock implements CheckSessionUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockCheckSessionUseCase mockCheckSession;
  late MockLogoutUseCase mockLogout;
  late MockAuthRepository mockRepository;
  late StreamController<AppUser?> streamController;

  setUp(() {
    mockCheckSession = MockCheckSessionUseCase();
    mockLogout = MockLogoutUseCase();
    mockRepository = MockAuthRepository();
    streamController = StreamController<AppUser?>.broadcast();
    when(() => mockRepository.onAuthStateChanged).thenAnswer((_) => streamController.stream);
  });

  tearDown(() {
    streamController.close();
  });

  group('startup', () {
    blocTest<SessionBloc, SessionState>(
      'emits [unknown, authenticated] when token is valid on startup',
      build: () {
        final user = AppUser(id: '1', email: 'test@test.com', name: 'Test', permissions: 32);
        when(() => mockCheckSession()).thenAnswer((_) async => right(user));
        return SessionBloc(
          checkSessionUseCase: mockCheckSession,
          logoutUseCase: mockLogout,
          repository: mockRepository,
        );
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        SessionState.authenticated(AppUser(id: '1', email: 'test@test.com', name: 'Test', permissions: 32)),
      ],
    );

    blocTest<SessionBloc, SessionState>(
      'emits [unknown, unauthenticated] when no token on startup',
      build: () {
        when(() => mockCheckSession()).thenAnswer((_) async => right(null));
        return SessionBloc(
          checkSessionUseCase: mockCheckSession,
          logoutUseCase: mockLogout,
          repository: mockRepository,
        );
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const SessionState.unauthenticated(),
      ],
    );
  });

  group('logout', () {
    blocTest<SessionBloc, SessionState>(
      'emits unauthenticated after logout',
      build: () {
        when(() => mockCheckSession()).thenAnswer((_) async => right(null));
        when(() => mockLogout()).thenAnswer((_) async => right(null));
        return SessionBloc(
          checkSessionUseCase: mockCheckSession,
          logoutUseCase: mockLogout,
          repository: mockRepository,
        );
      },
      act: (bloc) => bloc.add(const SessionLogoutRequested()),
      expect: () => [
        const SessionState.unauthenticated(),
      ],
    );
  });
}
