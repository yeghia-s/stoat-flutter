class StoatMember {
  final String serverId;
  final String userId;
  final String? avatarId;

  const StoatMember({
    required this.serverId,
    required this.userId,
    this.avatarId,
  });

  factory StoatMember.fromJson(Map<String, dynamic> j) => StoatMember(
        serverId: j['_id']?['server'] as String? ?? '',
        userId: j['_id']?['user'] as String? ?? '',
        avatarId: j['avatar']?['_id'] as String?,
      );
}
