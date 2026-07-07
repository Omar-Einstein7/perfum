import 'package:bloc_test/bloc_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/providers/auth_bloc.dart';
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockSignUpUseCase extends Mock implements SignUpUseCase {}
class MockForgotPasswordUseCase extends Mock implements ForgotPasswordUseCase {}

void main() {
  late MockLoginUseCase mockLogin;
  late MockSignUpUseCase mockSignUp;
  late MockForgotPasswordUseCase mockForgotPassword;
  late AuthBloc bloc;

  setUp(() {
    mockLogin = MockLoginUseCase();
    mockSignUp = MockSignUpUseCase();
    mockForgotPassword = MockForgotPasswordUseCase();
    bloc = AuthBloc(
      loginUseCase: mockLogin,
      signUpUseCase: mockSignUp,
      forgotPasswordUseCase: mockForgotPassword,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('LoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, success] on successful login',
      build: () {
        when(() => mockLogin(email: 'test@test.com', password: 'pass')).thenAnswer(
          (_) async => right(AppUser(id: '1', email: 'test@test.com', name: 'Test', permissions: 0)),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const LoginRequested(email: 'test@test.com', password: 'pass')),
      expect: () => [
        const AuthState(isLoading: true),
        const AuthState(isLoading: false, isSuccess: true),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] on failed login',
      build: () {
        when(() => mockLogin(email: 'test@test.com', password: 'wrong')).thenAnswer(
          (_) async => left(ServerFailure('Invalid credentials')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const LoginRequested(email: 'test@test.com', password: 'wrong')),
      expect: () => [
        const AuthState(isLoading: true),
        const AuthState(isLoading: false, errorMessage: 'Invalid credentials'),
      ],
    );
  });

  group('SignUpRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, success] on successful signup',
      build: () {
        when(() => mockSignUp(name: 'Test', email: 'test@test.com', password: 'pass')).thenAnswer(
          (_) async => right(AppUser(id: '1', email: 'test@test.com', name: 'Test', permissions: 0)),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const SignUpRequested(name: 'Test', email: 'test@test.com', password: 'pass')),
      expect: () => [
        const AuthState(isLoading: true),
        const AuthState(isLoading: false, isSuccess: true),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] on duplicate email',
      build: () {
        when(() => mockSignUp(name: 'Test', email: 'existing@test.com', password: 'pass')).thenAnswer(
          (_) async => left(ServerFailure('Email already registered')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const SignUpRequested(name: 'Test', email: 'existing@test.com', password: 'pass')),
      expect: () => [
        const AuthState(isLoading: true),
        const AuthState(isLoading: false, errorMessage: 'Email already registered'),
      ],
    );
  });

  group('ForgotPasswordRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, passwordResetSent] on success',
      build: () {
        when(() => mockForgotPassword(email: 'test@test.com')).thenAnswer(
          (_) async => right(null),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const ForgotPasswordRequested(email: 'test@test.com')),
      expect: () => [
        const AuthState(isLoading: true),
        const AuthState(isLoading: false, passwordResetSent: true),
      ],
    );
  });
}
