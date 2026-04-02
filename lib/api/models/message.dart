class StoatMessage {
  final String id;
  final String channelId;
  final String authorId;
  final String? content;
  final DateTime timestamp;

  const StoatMessage({
    required this.id,
    required this.channelId,
    required this.authorId,
    this.content,
    required this.timestamp,
  });

  factory StoatMessage.fromJson(Map<String, dynamic> j) => StoatMessage(
        id: j['_id'] as String,
        channelId: j['channel'] as String,
        authorId: j['author'] as String,
        content: j['content'] as String?,
        timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}
