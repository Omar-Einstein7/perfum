import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';

class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final User? user;

  const Authenticated({this.user});
}

class AuthError extends AuthState {
  final String message;

  const AuthError({this.message = ''});
}
