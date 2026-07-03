import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';

abstract class UserManagementEvent {}

class LoadUsers extends UserManagementEvent {}

class CreateUser extends UserManagementEvent {
  final String email;
  final String password;
  final String role;
  final Map<String, bool> permissions;

  CreateUser({
    required this.email,
    required this.password,
    required this.role,
    required this.permissions,
  });
}

class UpdateUser extends UserManagementEvent {
  final String id;
  final String? role;
  final Map<String, bool>? permissions;
  final String? status;

  UpdateUser({required this.id, this.role, this.permissions, this.status});
}

class DeleteUser extends UserManagementEvent {
  final String id;
  DeleteUser({required this.id});
}

abstract class UserManagementState {
  const UserManagementState();
}

class UserManagementInitial extends UserManagementState {
  const UserManagementInitial();
}

class UserManagementLoading extends UserManagementState {
  const UserManagementLoading();
}

class UsersLoaded extends UserManagementState {
  final List<User> users;

  const UsersLoaded({required this.users});
}

class UserManagementError extends UserManagementState {
  final String message;
  const UserManagementError({this.message = ''});
}

class UserManagementBloc
    extends Bloc<UserManagementEvent, UserManagementState> {
  final AuthRepository repository;

  UserManagementBloc({required this.repository})
    : super(UserManagementInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<CreateUser>(_onCreateUser);
    on<UpdateUser>(_onUpdateUser);
    on<DeleteUser>(_onDeleteUser);
  }

  Future<void> _onLoadUsers(
    LoadUsers event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    try {
      final users = await repository.listUsers();
      emit(UsersLoaded(users: users));
    } catch (e) {
      emit(UserManagementError(message: e.toString()));
    }
  }

  Future<void> _onCreateUser(
    CreateUser event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    try {
      await repository.createUser(
        email: event.email,
        password: event.password,
        role: event.role,
        permissions: event.permissions,
      );
      final users = await repository.listUsers();
      emit(UsersLoaded(users: users));
    } catch (e) {
      emit(UserManagementError(message: e.toString()));
    }
  }

  Future<void> _onUpdateUser(
    UpdateUser event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    try {
      await repository.updateUser(
        event.id,
        role: event.role,
        permissions: event.permissions,
        status: event.status,
      );
      final users = await repository.listUsers();
      emit(UsersLoaded(users: users));
    } catch (e) {
      emit(UserManagementError(message: e.toString()));
    }
  }

  Future<void> _onDeleteUser(
    DeleteUser event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    try {
      await repository.deleteUser(event.id);
      final users = await repository.listUsers();
      emit(UsersLoaded(users: users));
    } catch (e) {
      emit(UserManagementError(message: e.toString()));
    }
  }
}
