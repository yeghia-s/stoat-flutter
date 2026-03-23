import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';
import 'http_client.dart';
import 'models/session.dart';
import 'websocket/stoat_websocket.dart';
import 'websocket/events.dart';

const _kTokenKey = 'stoat_session_token';
const _kUserIdKey = 'stoat_user_id';

/// Top-level entry point. Wire this up with your state management of choice.
///
///   final client = StoatClient(config: StoatConfig.armstream);
///   await client.login('you@example.com', 'password');
///   client.events.listen((event) { ... });
///
class StoatClient {
  final StoatConfig config;
  final _storage = const FlutterSecureStorage();

  late final StoatHttpClient http;
  StoatWebSocket? _ws;

  Session? _session;
  Session? get session => _session;
  bool get isLoggedIn => _session != null;

  // Proxy the WebSocket event stream so callers don't need to null-check _ws.
  Stream<StoatEvent> get events =>
      _ws?.events ?? const Stream.empty();

  Stream<WsState> get connectionState =>
      _ws?.stateStream ?? const Stream.empty();

  StoatClient({required this.config}) {
    http = StoatHttpClient(config);
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  /// Login and immediately open the WebSocket.
Future<void> login(String email, String password) async {
  final session = await http.login(email, password);
  _session = session;
  try {
    await _storage.write(key: _kTokenKey, value: session.token);
    await _storage.write(key: _kUserIdKey, value: session.userId);
  } catch (_) {
    // Keyring unavailable, session won't persist across restarts
  }
  await _openWebSocket(session.token);
}

  /// Call on app startup. Returns true if a valid session was restored.
Future<bool> tryRestoreSession() async {
  String? token;
  String? userId;
  try {
    token = await _storage.read(key: _kTokenKey);
    userId = await _storage.read(key: _kUserIdKey);
  } catch (_) {
    return false;
  }
  if (token == null || userId == null) return false;

  try {
    await http.restoreSession(token);
    _session = Session(token: token, userId: userId);
    await _openWebSocket(token);
    return true;
  } on StoatApiException {
    await _clearStorage();
    return false;
  }
}

  /// Log out, kill the WebSocket, and wipe stored credentials.
  Future<void> logout() async {
    _ws?.dispose();
    _ws = null;
    try {
      await http.logout();
    } catch (_) {
      // Best-effort — if the server is unreachable, we still clear locally.
    }
    _session = null;
    await _clearStorage();
  }

  // ── WebSocket ──────────────────────────────────────────────────────────────

  Future<void> _openWebSocket(String token) async {
    _ws?.dispose();
    _ws = StoatWebSocket(config: config, token: token);

    // If the server tells us the session is gone, wipe credentials.
    _ws!.events.listen((event) {
      if (event is LogoutEvent) {
        _session = null;
        _clearStorage();
      }
    });

    await _ws!.connect();
  }

  // ── Misc ───────────────────────────────────────────────────────────────────

Future<void> _clearStorage() async {
  try {
    await _storage.delete(key: _kTokenKey);
    await _storage.delete(key: _kUserIdKey);
  } catch (_) {}
}

  void dispose() {
    _ws?.dispose();
  }
}
