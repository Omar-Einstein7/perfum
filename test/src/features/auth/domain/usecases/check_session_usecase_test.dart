import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/check_session_usecase.dart';
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late CheckSessionUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = CheckSessionUseCase(repository: repository);
  });

  test('should return AppUser when token is valid', () async {
    final user = AppUser(id: '1', email: 'test@test.com', name: 'Test', permissions: 32);
    when(() => repository.checkAuthState()).thenAnswer((_) async => right(user));

    final result = await useCase.call();

    expect(result.fold((l) => l, (r) => r), user);
    verify(() => repository.checkAuthState()).called(1);
  });

  test('should return null when no token exists', () async {
    when(() => repository.checkAuthState()).thenAnswer((_) async => right(null));

    final result = await useCase.call();

    expect(result.fold((l) => l, (r) => r), isNull);
  });

  test('should return Failure when check fails', () async {
    when(() => repository.checkAuthState()).thenAnswer(
      (_) async => left(ServerFailure('Network error')),
    );

    final result = await useCase.call();

    expect(result.fold((l) => l, (r) => r), isA<ServerFailure>());
  });
}
