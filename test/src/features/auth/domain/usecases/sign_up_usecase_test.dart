import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late SignUpUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = SignUpUseCase(repository: repository);
  });

  test('should call repository.signUp and return AppUser on success', () async {
    final user = AppUser(id: '1', email: 'new@test.com', name: 'New User', permissions: 0);
    when(() => repository.signUp(name: 'New User', email: 'new@test.com', password: 'pass123')).thenAnswer(
      (_) async => right(user),
    );

    final result = await useCase(name: 'New User', email: 'new@test.com', password: 'pass123');

    expect(result.fold((l) => l, (r) => r), user);
    verify(() => repository.signUp(name: 'New User', email: 'new@test.com', password: 'pass123')).called(1);
  });

  test('should return Failure on duplicate email', () async {
    when(() => repository.signUp(name: 'New User', email: 'existing@test.com', password: 'pass123')).thenAnswer(
      (_) async => left(ServerFailure('Email already registered')),
    );

    final result = await useCase(name: 'New User', email: 'existing@test.com', password: 'pass123');

    expect(result.fold((l) => l, (r) => r), isA<ServerFailure>());
  });
}
