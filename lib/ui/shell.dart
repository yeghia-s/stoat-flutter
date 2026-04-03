import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../api/models/server.dart';
import '../api/models/channel.dart';
import '../api/stoat_client.dart';
import '../api/models/user.dart';

class ShellScreen extends StatelessWidget {
  final StoatClient client;
  const ShellScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ServerList(),
        const ChannelList(),
        Expanded(child: MessageArea(client: client)),
      ],
    );
  }
}

// ── Server list (left column) ─────────────────────────────────────────────────

class ServerList extends StatelessWidget {
  const ServerList({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Container(
      width: 72,
      color: Theme.of(context).colorScheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.servers.length,
        itemBuilder: (context, i) {
          final server = state.servers[i];
          final selected = state.selectedServer?.id == server.id;
          return _ServerIcon(
            server: server,
            selected: selected,
            onTap: () => state.selectServer(server),
          );
        },
      ),
    );
  }
}

class _ServerIcon extends StatelessWidget {
  final StoatServer server;
  final bool selected;
  final VoidCallback onTap;

  const _ServerIcon({
    required this.server,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Tooltip(
        message: server.name,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(selected ? 16 : 24),
            ),
            child: Center(
              child: Text(
                server.name.characters.first.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Channel list (middle column) ──────────────────────────────────────────────

class ChannelList extends StatelessWidget {
  const ChannelList({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final server = state.selectedServer;

    if (server == null) {
      return const SizedBox(width: 220);
    }

    final channels = state.channelsFor(server);

    return Container(
      width: 220,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              server.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: channels.length,
              itemBuilder: (context, i) {
                final channel = channels[i];
                final selected = state.selectedChannel?.id == channel.id;
                return _ChannelTile(
                  channel: channel,
                  selected: selected,
                  onTap: () => state.selectChannel(channel),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final StoatChannel channel;
  final bool selected;
  final VoidCallback onTap;

  const _ChannelTile({
    required this.channel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
      leading: Icon(
        channel.isVoice ? Icons.volume_up : Icons.tag,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        channel.name,
        style: const TextStyle(fontSize: 14),
      ),
      onTap: onTap,
    );
  }
}

// ── Message area (right panel) ────────────────────────────────────────────────

class MessageArea extends StatefulWidget {
  final StoatClient client;
  const MessageArea({super.key, required this.client});

  @override
  State<MessageArea> createState() => _MessageAreaState();
}

class _MessageAreaState extends State<MessageArea> {
  String? _loadedChannelId;
  bool _loading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final channel = context.read<AppState>().selectedChannel;
    if (channel != null && channel.id != _loadedChannelId) {
      _loadMessages(channel.id);
    }
  }

  Future<void> _loadMessages(String channelId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final messages = await widget.client.http.fetchMessages(channelId);
      if (mounted) {
        context.read<AppState>().setMessages(channelId, messages);
        _loadedChannelId = channelId;
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final channel = context.watch<AppState>().selectedChannel;

    if (channel == null) {
      return const Center(child: Text('Select a channel'));
    }

    final messages = context.watch<AppState>().messagesFor(channel.id);

    return Column(
      children: [
        // Channel header
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              Icon(channel.isVoice ? Icons.volume_up : Icons.tag, size: 16),
              const SizedBox(width: 6),
              Text(
                channel.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        // Message list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : messages.isEmpty
                      ? const Center(child: Text('No messages'))
                      : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, i) {
                            final message = messages[i];
                            final author = context
                                .watch<AppState>()
                                .cachedUser(message.authorId);

                            if (author == null) {
                              WidgetsBinding.instance
                                  .addPostFrameCallback((_) async {
                                try {
                                  final data = await widget.client.http
                                      .fetchUser(message.authorId);
                                  if (mounted) {
                                    context
                                        .read<AppState>()
                                        .cacheUser(StoatUser.fromJson(data));
                                  }
                                } catch (_) {}
                              });
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _Avatar(
                                    user: author,
                                    autumnUrl: widget.client.config.autumnUrl,
                                    memberAvatarId: context.read<AppState>().memberAvatarId(message.authorId),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          author?.username ?? message.authorId,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          message.content ?? '',
                                          style:
                                              const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final StoatUser? user;
  final String autumnUrl;
  final String? memberAvatarId;

  const _Avatar({
    required this.user,
    required this.autumnUrl,
    this.memberAvatarId,
  });

  @override
  Widget build(BuildContext context) {
    final avatarId = user?.avatarId ?? memberAvatarId;
    return CircleAvatar(
      radius: 20,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      backgroundImage: avatarId != null
          ? NetworkImage('$autumnUrl/avatars/$avatarId')
          : null,
      child: avatarId == null
          ? Text(
              user?.username.characters.first.toUpperCase() ?? '?',
              style: const TextStyle(fontSize: 14),
            )
          : null,
    );
  }
}
