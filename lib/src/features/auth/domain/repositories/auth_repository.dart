import '../entities/session.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Session> login(String email, String password);
  Future<void> logout();
  Future<User> getMe();
  Future<List<User>> listUsers();
  Future<User> createUser({
    required String email,
    required String password,
    required String role,
    required Map<String, bool> permissions,
  });
  Future<User> updateUser(
    String id, {
    String? role,
    Map<String, bool>? permissions,
    String? status,
  });
  Future<void> deleteUser(String id);
}
