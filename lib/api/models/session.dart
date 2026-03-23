/// Returned by a successful login.
class Session {
  final String token;
  final String userId;

  const Session({required this.token, required this.userId});

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        token: json['token'] as String,
        userId: json['user_id'] as String,
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'user_id': userId,
      };
}
