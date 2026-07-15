import 'package:perfum_ahmed_gaper/src/imports/core_imports.dart';
import 'package:perfum_ahmed_gaper/src/imports/packages_imports.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc({required AuthRepository repository}) : _repository = repository, super(const AuthState.initial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    final result = await _repository.login(username: event.username, password: event.password);

    result.fold(
      (failure) {
        emit(state.copyWith(isLoading: false, error: failure.message));
      },
      (employee) {
        emit(state.copyWith(isLoading: false, isAuthenticated: true, employee: employee, error: null));
      },
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logout();
    emit(const AuthState.initial());
  }
}

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String username;
  final String password;
  const LoginSubmitted({required this.username, required this.password});
  @override
  List<Object> get props => [username, password];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class AuthState extends Equatable {
  final bool isLoading;
  final bool isAuthenticated;
  final Employee? employee;
  final String? error;

  const AuthState({
    required this.isLoading,
    this.isAuthenticated = false,
    this.employee,
    this.error,
  });

  const AuthState.initial()
      : isLoading = false,
        isAuthenticated = false,
        employee = null,
        error = null;

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Employee? employee,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      employee: employee ?? this.employee,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, isAuthenticated, employee, error];
}
