import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'models/session.dart';
import 'models/message.dart';

/// All REST calls go through here.
/// Throws [StoatApiException] on non-2xx responses.
class StoatHttpClient {
  final StoatConfig config;
  String? _token;

  StoatHttpClient(this.config);

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// Login with email + password. Stores the token internally.
  /// Returns the full [Session] object.
  Future<Session> login(String email, String password) async {
    final res = await _post(
      '/auth/session/login',
      body: {'email': email, 'password': password},
      authenticated: false,
    );

    final session = Session.fromJson(res);
    _token = session.token;
    return session;
  }

  /// Log out, invalidating the current session token on the server.
  Future<void> logout() async {
    await _delete('/auth/session/logout');
    _token = null;
  }

  /// Restore a session from a persisted token (e.g. flutter_secure_storage).
  /// Call this on app startup before connecting the WebSocket.
  Future<void> restoreSession(String token) async {
    _token = token;
    // Validate by fetching /users/@me — throws if token is invalid.
    await fetchMe();
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchMe() async {
    return _get('/users/@me');
  }

  // ── Low-level ─────────────────────────────────────────────────────────────

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'x-session-token': _token!,
      };

  Uri _uri(String path) => Uri.parse('${config.apiUrl}$path');

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(_uri(path), headers: _headers);
    return _handle(res);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final headers = authenticated
        ? _headers
        : {'Content-Type': 'application/json'};
    final res = await http.post(
      _uri(path),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final res = await http.delete(_uri(path), headers: _headers);
    return _handle(res);
  }

  Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    throw StoatApiException(
      statusCode: res.statusCode,
      type: body['type'] as String? ?? 'Unknown',
      message: body['err'] as String? ?? res.body,
    );
  }

  Future<List<StoatMessage>> fetchMessages(String channelId, {int limit = 50}) async {
  final res = await http.get(
    _uri('/channels/$channelId/messages?limit=$limit'),
    headers: _headers,
  );
  if (res.statusCode < 200 || res.statusCode >= 300) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    throw StoatApiException(
      statusCode: res.statusCode,
      type: body['type'] as String? ?? 'Unknown',
      message: body['err'] as String? ?? res.body,
    );
  }
  final decoded = jsonDecode(res.body);
  final list = decoded is List ? decoded : (decoded['messages'] as List? ?? []);
  return list
      .map((m) => StoatMessage.fromJson(m as Map<String, dynamic>))
      .toList();
}

  Future<void> sendMessage(String channelId, String content) async {
    await _post(
      '/channels/$channelId/messages',
      body: {'content': content},
    );
  }

Future<Map<String, dynamic>> fetchUser(String userId) async {
  final result = await _get('/users/$userId');
  return result;
}

}

class StoatApiException implements Exception {
  final int statusCode;
  final String type;
  final String message;

  const StoatApiException({
    required this.statusCode,
    required this.type,
    required this.message,
  });

  @override
  String toString() => 'StoatApiException($statusCode): $type — $message';
}
