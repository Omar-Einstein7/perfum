import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late LoginUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = LoginUseCase(repository: repository);
  });

  test('should call repository.login and return AppUser on success', () async {
    final user = AppUser(id: '1', email: 'test@test.com', name: 'Test', permissions: 0);
    when(() => repository.login(email: 'test@test.com', password: 'pass123')).thenAnswer(
      (_) async => right(user),
    );

    final result = await useCase(email: 'test@test.com', password: 'pass123');

    expect(result.fold((l) => l, (r) => r), user);
    verify(() => repository.login(email: 'test@test.com', password: 'pass123')).called(1);
  });

  test('should return Failure when repository fails', () async {
    when(() => repository.login(email: 'test@test.com', password: 'wrong')).thenAnswer(
      (_) async => left(ServerFailure('Invalid credentials')),
    );

    final result = await useCase(email: 'test@test.com', password: 'wrong');

    expect(result.fold((l) => l, (r) => r), isA<ServerFailure>());
  });
}
