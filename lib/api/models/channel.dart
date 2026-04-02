class StoatChannel {
  final String id;
  final String serverId;
  final String name;
  final String? lastMessageId;
  final bool isVoice;

  const StoatChannel({
    required this.id,
    required this.serverId,
    required this.name,
    this.lastMessageId,
    this.isVoice = false,
  });

  factory StoatChannel.fromJson(Map<String, dynamic> j) => StoatChannel(
        id: j['_id'] as String,
        serverId: j['server'] as String,
        name: j['name'] as String,
        lastMessageId: j['last_message_id'] as String?,
        isVoice: j['voice'] != null,
      );
}
