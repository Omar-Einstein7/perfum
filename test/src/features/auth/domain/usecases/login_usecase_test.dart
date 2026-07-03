import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/session.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late LoginUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = LoginUseCase(repository: repository);
  });

  group('LoginUseCase', () {
    const email = 'test@example.com';
    const password = 'Test@123';
    final session = Session(
      accessToken: 'token',
      refreshToken: 'refresh',
      expiresIn: 900,
    );

    test('should call repository.login and return session', () async {
      when(
        () => repository.login(email, password),
      ).thenAnswer((_) async => session);

      final result = await useCase(email, password);

      expect(result, session);
      verify(() => repository.login(email, password)).called(1);
    });

    test('should throw when repository throws', () async {
      when(
        () => repository.login(email, password),
      ).thenThrow(Exception('Login failed'));

      expect(() => useCase(email, password), throwsA(isA<Exception>()));
    });
  });
}
