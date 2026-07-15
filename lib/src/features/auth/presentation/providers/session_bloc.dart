import 'dart:async';
import 'package:perfum_ahmed_gaper/src/imports/imports.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';

abstract class SessionEvent extends Equatable {
  const SessionEvent();
  @override
  List<Object?> get props => [];
}

class SessionCheckRequested extends SessionEvent {
  const SessionCheckRequested();
}

class SessionLogoutRequested extends SessionEvent {
  const SessionLogoutRequested();
}

enum SessionStatus { unknown, authenticated, unauthenticated }

class SessionState extends Equatable {
  final SessionStatus status;

  const SessionState({this.status = SessionStatus.unknown});

  const SessionState.unknown() : this();
  const SessionState.authenticated() : this(status: SessionStatus.authenticated);
  const SessionState.unauthenticated() : this(status: SessionStatus.unauthenticated);

  @override
  List<Object?> get props => [status];
}

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final AuthRepository _repository;
  StreamSubscription<bool>? _authSub;

  SessionBloc({required AuthRepository repository})
      : _repository = repository,
        super(const SessionState.unknown()) {
    on<SessionCheckRequested>(_onCheckRequested);
    on<SessionLogoutRequested>(_onLogoutRequested);

    add(const SessionCheckRequested());
  }

  Future<void> _onCheckRequested(
    SessionCheckRequested event,
    Emitter<SessionState> emit,
  ) async {
    final hasSession = await _repository.hasStoredSession();
    hasSession.fold(
      (_) => emit(const SessionState.unauthenticated()),
      (hasToken) {
        if (hasToken) {
          emit(const SessionState.authenticated());
        } else {
          emit(const SessionState.unauthenticated());
        }
      },
    );

    await _authSub?.cancel();
    _authSub = _repository.onAuthStateChanged.listen((isAuthenticated) {
      if (isAuthenticated) {
        emit(const SessionState.authenticated());
      } else {
        emit(const SessionState.unauthenticated());
      }
    });
  }

  Future<void> _onLogoutRequested(
    SessionLogoutRequested event,
    Emitter<SessionState> emit,
  ) async {
    await _repository.logout();
    emit(const SessionState.unauthenticated());
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
