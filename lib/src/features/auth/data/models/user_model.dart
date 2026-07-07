import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    String? name,
    String? photoUrl,
    @Default(0) int permissions,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}

extension UserModelX on UserModel {
  AppUser toEntity() => AppUser(
        id: id,
        email: email,
        name: name,
        photoUrl: photoUrl,
        permissions: permissions,
      );
}
