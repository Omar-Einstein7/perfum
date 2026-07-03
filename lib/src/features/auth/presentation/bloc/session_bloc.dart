import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

class SessionState {
  final SessionStatus status;
  final User? user;

  const SessionState({this.status = SessionStatus.unknown, this.user});

  SessionState copyWith({
    SessionStatus? status,
    User? user,
    bool clearUser = false,
  }) {
    return SessionState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
    );
  }
}

abstract class SessionEvent {
  const SessionEvent();
}

class SessionInit extends SessionEvent {
  const SessionInit();
}

class SessionCheck extends SessionEvent {
  const SessionCheck();
}

class SessionLogout extends SessionEvent {
  const SessionLogout();
}

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final AuthRepository repository;

  SessionBloc({required this.repository}) : super(const SessionState()) {
    on<SessionInit>(_onInit);
    on<SessionCheck>(_onCheck);
    on<SessionLogout>(_onLogout);
    add(const SessionInit());
  }

  Future<void> _onInit(SessionInit event, Emitter<SessionState> emit) async {
    try {
      final user = await repository.getMe();
      emit(state.copyWith(status: SessionStatus.authenticated, user: user));
    } catch (_) {
      emit(
        state.copyWith(status: SessionStatus.unauthenticated, clearUser: true),
      );
    }
  }

  Future<void> _onCheck(SessionCheck event, Emitter<SessionState> emit) async {
    try {
      final user = await repository.getMe();
      emit(state.copyWith(status: SessionStatus.authenticated, user: user));
    } catch (_) {
      emit(
        state.copyWith(status: SessionStatus.unauthenticated, clearUser: true),
      );
    }
  }

  Future<void> _onLogout(
    SessionLogout event,
    Emitter<SessionState> emit,
  ) async {
    await repository.logout();
    emit(
      state.copyWith(status: SessionStatus.unauthenticated, clearUser: true),
    );
  }
}
