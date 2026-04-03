import 'package:flutter/foundation.dart';
import '../api/models/server.dart';
import '../api/models/channel.dart';
import '../api/models/user.dart';
import '../api/models/message.dart';
import '../api/models/member.dart';

class AppState extends ChangeNotifier {
  List<StoatServer> servers = [];
  List<StoatChannel> channels = [];
  List<StoatUser> users = [];

  StoatServer? selectedServer;
  StoatChannel? selectedChannel;

  final Map<String, String> _memberAvatars = {};

  void loadFromReady({
    required List<StoatServer> servers,
    required List<StoatChannel> channels,
    required List<StoatUser> users,
    required List<StoatMember> members,
  }) {
    this.servers = servers;
    this.channels = channels;
    this.users = users;
    for (final m in members) {
      if (m.avatarId != null) {
        _memberAvatars[m.userId] = m.avatarId!;
      }
    }
    selectedServer = servers.isNotEmpty ? servers.first : null;
    selectedChannel = _firstChannelFor(selectedServer);
    notifyListeners();
  }

  String? memberAvatarId(String userId) => _memberAvatars[userId];

  List<StoatChannel> channelsFor(StoatServer server) =>
      channels.where((c) => c.serverId == server.id).toList();

  void selectServer(StoatServer server) {
    selectedServer = server;
    selectedChannel = _firstChannelFor(server);
    notifyListeners();
  }

  void selectChannel(StoatChannel channel) {
    selectedChannel = channel;
    notifyListeners();
  }

  StoatChannel? _firstChannelFor(StoatServer? server) {
    if (server == null) return null;
    final list = channelsFor(server);
    return list.isNotEmpty ? list.first : null;
  }

  final Map<String, List<StoatMessage>> _messages = {};

  List<StoatMessage> messagesFor(String channelId) =>
    _messages[channelId] ?? [];

  void setMessages(String channelId, List<StoatMessage> messages) {
    _messages[channelId] = messages;
    notifyListeners();
  }

  void prependMessage(String channelId, StoatMessage message) {
    _messages[channelId] = [message, ...(_messages[channelId] ?? [])];
    notifyListeners();
  }

  final Map<String, StoatUser> _userCache = {};

StoatUser? cachedUser(String id) => _userCache[id];

void cacheUser(StoatUser user) {
  _userCache[user.id] = user;
  notifyListeners();
}
}
