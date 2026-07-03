import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/bloc/user_management_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late UserManagementBloc bloc;

  setUp(() {
    repository = MockAuthRepository();
    bloc = UserManagementBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('LoadUsers', () {
    blocTest<UserManagementBloc, UserManagementState>(
      'emits [Loading, UsersLoaded] on success',
      setUp: () {
        when(() => repository.listUsers()).thenAnswer((_) async => <User>[]);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(LoadUsers()),
      expect: () => [isA<UserManagementLoading>(), isA<UsersLoaded>()],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'emits [Loading, UserManagementError] on failure',
      setUp: () {
        when(() => repository.listUsers()).thenThrow(Exception('Failed'));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(LoadUsers()),
      expect: () => [isA<UserManagementLoading>(), isA<UserManagementError>()],
    );
  });
}
