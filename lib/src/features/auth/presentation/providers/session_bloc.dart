import 'dart:async';
import 'package:perfum_ahmed_gaper/src/imports/packages_imports.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/check_session_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/logout_usecase.dart';

/// Session events
abstract class SessionEvent extends Equatable {
  const SessionEvent();
  @override
  List<Object?> get props => [];
}

class SessionCheckRequested extends SessionEvent {
  const SessionCheckRequested();
}

class SessionUserChanged extends SessionEvent {
  final AppUser? user;
  const SessionUserChanged(this.user);
  @override
  List<Object?> get props => [user];
}

class SessionLogoutRequested extends SessionEvent {
  const SessionLogoutRequested();
}

/// Session states
enum SessionStatus { unknown, authenticated, unauthenticated }

class SessionState extends Equatable {
  final SessionStatus status;
  final AppUser? user;

  const SessionState({
    this.status = SessionStatus.unknown,
    this.user,
  });

  const SessionState.unknown() : this();
  const SessionState.authenticated(AppUser user) : this(status: SessionStatus.authenticated, user: user);
  const SessionState.unauthenticated() : this(status: SessionStatus.unauthenticated);

  @override
  List<Object?> get props => [status, user];
}

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final CheckSessionUseCase _checkSessionUseCase;
  final LogoutUseCase _logoutUseCase;
  final AuthRepository _repository;
  StreamSubscription<AppUser?>? _authSub;

  SessionBloc({
    required CheckSessionUseCase checkSessionUseCase,
    required LogoutUseCase logoutUseCase,
    required AuthRepository repository,
  })  : _checkSessionUseCase = checkSessionUseCase,
        _logoutUseCase = logoutUseCase,
        _repository = repository,
        super(const SessionState.unknown()) {
    on<SessionCheckRequested>(_onCheckRequested);
    on<SessionUserChanged>(_onUserChanged);
    on<SessionLogoutRequested>(_onLogoutRequested);

    // Start checking
    add(const SessionCheckRequested());
  }

  Future<void> _onCheckRequested(
    SessionCheckRequested event,
    Emitter<SessionState> emit,
  ) async {
    final result = await _checkSessionUseCase();
    result.fold(
      (_) => emit(const SessionState.unauthenticated()),
      (user) {
        if (user != null) {
          emit(SessionState.authenticated(user));
        } else {
          emit(const SessionState.unauthenticated());
        }
      },
    );

    // Listen for future changes
    await _authSub?.cancel();
    _authSub = _repository.onAuthStateChanged.listen((user) {
      add(SessionUserChanged(user));
    });
  }

  void _onUserChanged(
    SessionUserChanged event,
    Emitter<SessionState> emit,
  ) {
    if (event.user != null) {
      emit(SessionState.authenticated(event.user!));
    } else {
      emit(const SessionState.unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    SessionLogoutRequested event,
    Emitter<SessionState> emit,
  ) async {
    await _logoutUseCase();
    emit(const SessionState.unauthenticated());
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}

