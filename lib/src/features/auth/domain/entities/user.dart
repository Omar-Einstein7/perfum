import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final int permissions;

  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    this.permissions = 0,
  });

  // --- Permission flag constants (bitmask) ---
  static const int canViewSales     = 1;   // bit 0
  static const int canEditSales     = 2;   // bit 1
  static const int canViewPurchases = 4;   // bit 2
  static const int canEditPurchases = 8;   // bit 3
  static const int canViewStock     = 16;  // bit 4
  static const int canEditMasters   = 32;  // bit 5
  static const int isAdmin          = 64;  // bit 6

  /// Returns true if this user holds the given permission flag.
  bool can(int flag) => (permissions & flag) != 0;

  factory AppUser.empty() => const AppUser(id: '', email: '');

  bool get isEmpty    => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  @override
  List<Object?> get props => [id, email, name, photoUrl, permissions];
}
