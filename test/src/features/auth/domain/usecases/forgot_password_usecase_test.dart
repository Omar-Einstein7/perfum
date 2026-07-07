import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late ForgotPasswordUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = ForgotPasswordUseCase(repository: repository);
  });

  test('should call repository.forgotPassword and return void on success', () async {
    when(() => repository.forgotPassword(email: 'test@test.com')).thenAnswer(
      (_) async => right(null),
    );

    final result = await useCase(email: 'test@test.com');

    expect(result.isRight(), true);
    verify(() => repository.forgotPassword(email: 'test@test.com')).called(1);
  });

  test('should return Failure on network error', () async {
    when(() => repository.forgotPassword(email: 'test@test.com')).thenAnswer(
      (_) async => left(ServerFailure('Network error')),
    );

    final result = await useCase(email: 'test@test.com');

    result.fold(
      (l) => expect(l, isA<ServerFailure>()),
      (r) => fail('Expected failure'),
    );
  });
}
