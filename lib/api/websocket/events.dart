import '../models/server.dart';
import '../models/channel.dart';
import '../models/user.dart';
import '../models/member.dart';

/// Every message received from the Stoat WebSocket (Bonfire) is one of these.
/// Unrecognised types are wrapped in [UnknownEvent] so nothing crashes.
sealed class StoatEvent {
  const StoatEvent();

  factory StoatEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    return switch (type) {
      'Authenticated'   => const AuthenticatedEvent(),
      'Ready'           => ReadyEvent.fromJson(json),
      'Ping'            => const PingEvent(),
      'Message'         => MessageEvent.fromJson(json),
      'MessageUpdate'   => MessageUpdateEvent.fromJson(json),
      'MessageDelete'   => MessageDeleteEvent.fromJson(json),
      'ChannelCreate'   => ChannelEvent.fromJson(json),
      'ChannelUpdate'   => ChannelEvent.fromJson(json),
      'ChannelDelete'   => ChannelDeleteEvent.fromJson(json),
      'ServerMemberJoin'   => ServerMemberEvent.fromJson(json),
      'ServerMemberLeave'  => ServerMemberEvent.fromJson(json),
      'UserUpdate'      => UserUpdateEvent.fromJson(json),
      'Logout'          => const LogoutEvent(),
      'Error'           => ErrorEvent.fromJson(json),
      _                 => UnknownEvent(type, json),
    };
  }
}

// ── Connection lifecycle ───────────────────────────────────────────────────

/// Server confirmed our token is valid.
final class AuthenticatedEvent extends StoatEvent {
  const AuthenticatedEvent();
}

/// Server sent the initial state snapshot right after authentication.
final class ReadyEvent extends StoatEvent {
  final List<StoatUser> users;
  final List<StoatServer> servers;
  final List<StoatChannel> channels;
  final List<StoatMember> members;

  const ReadyEvent({
    required this.users,
    required this.servers,
    required this.channels,
    required this.members,
  });

  factory ReadyEvent.fromJson(Map<String, dynamic> j) => ReadyEvent(
        users: (j['users'] as List? ?? [])
            .map((u) => StoatUser.fromJson(u as Map<String, dynamic>))
            .toList(),
        servers: (j['servers'] as List? ?? [])
            .map((s) => StoatServer.fromJson(s as Map<String, dynamic>))
            .toList(),
        channels: (j['channels'] as List? ?? [])
            .map((c) => StoatChannel.fromJson(c as Map<String, dynamic>))
            .toList(),
        members: (j['members'] as List? ?? [])
            .map((m) => StoatMember.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

/// Server is checking we are still alive — respond with Pong immediately.
final class PingEvent extends StoatEvent {
  const PingEvent();
}

/// Server invalidated our session (token expired / revoked).
final class LogoutEvent extends StoatEvent {
  const LogoutEvent();
}

/// Server sent a protocol error.
final class ErrorEvent extends StoatEvent {
  final String error;
  const ErrorEvent(this.error);

  factory ErrorEvent.fromJson(Map<String, dynamic> j) =>
      ErrorEvent(j['error'] as String? ?? 'Unknown');
}

/// Any event type we do not yet handle — stored raw so we can inspect it.
final class UnknownEvent extends StoatEvent {
  final String type;
  final Map<String, dynamic> raw;
  const UnknownEvent(this.type, this.raw);
}

// ── Messages ───────────────────────────────────────────────────────────────

final class MessageEvent extends StoatEvent {
  final String id;
  final String channelId;
  final String authorId;
  final String? content;
  final DateTime timestamp;

  const MessageEvent({
    required this.id,
    required this.channelId,
    required this.authorId,
    this.content,
    required this.timestamp,
  });

  factory MessageEvent.fromJson(Map<String, dynamic> j) => MessageEvent(
        id: j['_id'] as String,
        channelId: j['channel'] as String,
        authorId: j['author'] as String,
        content: j['content'] as String?,
        timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}

final class MessageUpdateEvent extends StoatEvent {
  final String id;
  final String channelId;
  final Map<String, dynamic> data;

  const MessageUpdateEvent({
    required this.id,
    required this.channelId,
    required this.data,
  });

  factory MessageUpdateEvent.fromJson(Map<String, dynamic> j) =>
      MessageUpdateEvent(
        id: j['id'] as String,
        channelId: j['channel'] as String,
        data: j['data'] as Map<String, dynamic>? ?? {},
      );
}

final class MessageDeleteEvent extends StoatEvent {
  final String id;
  final String channelId;

  const MessageDeleteEvent({required this.id, required this.channelId});

  factory MessageDeleteEvent.fromJson(Map<String, dynamic> j) =>
      MessageDeleteEvent(
        id: j['id'] as String,
        channelId: j['channel'] as String,
      );
}

// ── Channels ───────────────────────────────────────────────────────────────

final class ChannelEvent extends StoatEvent {
  final String id;
  final Map<String, dynamic> raw;

  const ChannelEvent({required this.id, required this.raw});

  factory ChannelEvent.fromJson(Map<String, dynamic> j) => ChannelEvent(
        id: j['id'] as String? ?? j['_id'] as String? ?? '',
        raw: j,
      );
}

final class ChannelDeleteEvent extends StoatEvent {
  final String id;
  const ChannelDeleteEvent(this.id);

  factory ChannelDeleteEvent.fromJson(Map<String, dynamic> j) =>
      ChannelDeleteEvent(j['id'] as String);
}

// ── Server members ─────────────────────────────────────────────────────────

final class ServerMemberEvent extends StoatEvent {
  final String serverId;
  final String userId;

  const ServerMemberEvent({required this.serverId, required this.userId});

  factory ServerMemberEvent.fromJson(Map<String, dynamic> j) =>
      ServerMemberEvent(
        serverId: j['id']?['server'] as String? ?? '',
        userId: j['id']?['user'] as String? ?? '',
      );
}

// ── Users ──────────────────────────────────────────────────────────────────

final class UserUpdateEvent extends StoatEvent {
  final String id;
  final Map<String, dynamic> data;

  const UserUpdateEvent({required this.id, required this.data});

  factory UserUpdateEvent.fromJson(Map<String, dynamic> j) => UserUpdateEvent(
        id: j['id'] as String,
        data: j['data'] as Map<String, dynamic>? ?? {},
      );
}
