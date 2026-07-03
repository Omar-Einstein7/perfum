import 'dart:convert';
import 'user_model.dart';

class TokenResponseModel {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserModel? user;

  const TokenResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.user,
  });

  factory TokenResponseModel.fromJson(Map<String, dynamic> json) {
    return TokenResponseModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresIn: json['expiresIn'] as int? ?? 86400,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  factory TokenResponseModel.fromJsonString(String source) {
    return TokenResponseModel.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      if (user != null) 'user': user!.toJson(),
    };
  }
}
