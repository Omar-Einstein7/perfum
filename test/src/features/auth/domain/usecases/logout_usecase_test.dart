import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/logout_usecase.dart';
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late LogoutUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = LogoutUseCase(repository: repository);
  });

  test('should call repository.logout and return void on success', () async {
    when(() => repository.logout()).thenAnswer((_) async => right(null));

    final result = await useCase();

    expect(result.isRight(), true);
    verify(() => repository.logout()).called(1);
  });

  test('should return Failure when repository fails', () async {
    when(() => repository.logout()).thenAnswer(
      (_) async => left(ServerFailure('Logout failed')),
    );

    final result = await useCase();

    result.fold(
      (l) => expect(l, isA<ServerFailure>()),
      (r) => fail('Expected failure'),
    );
  });
}
