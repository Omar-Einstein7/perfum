import 'dart:convert';
import '../../domain/entities/session.dart';

class SessionModel {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const SessionModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresIn: json['expiresIn'] as int? ?? 86400,
    );
  }

  factory SessionModel.fromJsonString(String source) {
    return SessionModel.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
    };
  }

  Session toEntity() {
    return Session(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
    );
  }
}
