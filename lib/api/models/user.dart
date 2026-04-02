class StoatUser {
  final String id;
  final String username;
  final String discriminator;
  final bool online;
  final String? avatarId;

  const StoatUser({
    required this.id,
    required this.username,
    required this.discriminator,
    required this.online,
    this.avatarId,
  });

  factory StoatUser.fromJson(Map<String, dynamic> j) => StoatUser(
        id: j['_id'] as String,
        username: j['username'] as String,
        discriminator: j['discriminator'] as String? ?? '0000',
        online: j['online'] as bool? ?? false,
        avatarId: j['avatar']?['_id'] as String?,
      );
}
