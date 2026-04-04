class StoatCategory {
  final String id;
  final String title;
  final List<String> channelIds;

  const StoatCategory({
    required this.id,
    required this.title,
    required this.channelIds,
  });

  factory StoatCategory.fromJson(Map<String, dynamic> j) => StoatCategory(
        id: j['id'] as String,
        title: j['title'] as String,
        channelIds: (j['channels'] as List? ?? []).cast<String>(),
      );
}

class StoatServer {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final List<String> channelIds;
  final List<StoatCategory> categories;
  final String? iconId;
  final String? bannerId;

  const StoatServer({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.channelIds,
    required this.categories,
    this.iconId,
    this.bannerId,
  });

  factory StoatServer.fromJson(Map<String, dynamic> j) => StoatServer(
        id: j['_id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        ownerId: j['owner'] as String,
        channelIds: (j['channels'] as List? ?? []).cast<String>(),
        categories: (j['categories'] as List? ?? [])
            .map((c) => StoatCategory.fromJson(c as Map<String, dynamic>))
            .toList(),
        iconId: j['icon']?['_id'] as String?,
        bannerId: j['banner']?['_id'] as String?,
      );
}
