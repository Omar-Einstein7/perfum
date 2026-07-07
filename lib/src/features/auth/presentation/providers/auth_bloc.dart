import 'package:perfum_ahmed_gaper/src/imports/packages_imports.dart';

import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/forgot_password_usecase.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final SignUpUseCase _signUpUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required SignUpUseCase signUpUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
  })  : _loginUseCase = loginUseCase,
        _signUpUseCase = signUpUseCase,
        _forgotPasswordUseCase = forgotPasswordUseCase,
        super(const AuthState.initial()) {
    on<LoginRequested>(_onLoginRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null, isSuccess: null));

    final result = await _loginUseCase(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(isLoading: false, errorMessage: failure.message));
      },
      (_) {
        emit(state.copyWith(isLoading: false, isSuccess: true));
      },
    );
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null, isSuccess: null));

    final result = await _signUpUseCase(
      name: event.name,
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(isLoading: false, errorMessage: failure.message));
      },
      (_) {
        emit(state.copyWith(isLoading: false, isSuccess: true));
      },
    );
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null, passwordResetSent: null));

    final result = await _forgotPasswordUseCase(email: event.email);

    result.fold(
      (failure) {
        emit(state.copyWith(isLoading: false, errorMessage: failure.message));
      },
      (_) {
        emit(state.copyWith(isLoading: false, passwordResetSent: true));
      },
    );
  }
}

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});
}

class SignUpRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  const SignUpRequested({required this.name, required this.email, required this.password});
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;
  const ForgotPasswordRequested({required this.email});
}

class AuthState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final bool? isSuccess;
  final bool? passwordResetSent;

  const AuthState({
    required this.isLoading,
    this.errorMessage,
    this.isSuccess,
    this.passwordResetSent,
  });

  const AuthState.initial()
      : isLoading = false,
        errorMessage = null,
        isSuccess = null,
        passwordResetSent = null;

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    bool? passwordResetSent,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess,
      passwordResetSent: passwordResetSent,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, isSuccess, passwordResetSent];
}
