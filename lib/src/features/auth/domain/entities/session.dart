class Session {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  Session copyWith({
    String? accessToken,
    String? refreshToken,
    int? expiresIn,
  }) {
    return Session(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresIn: expiresIn ?? this.expiresIn,
    );
  }
}
