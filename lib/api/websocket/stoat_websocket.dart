import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config.dart';
import 'events.dart';

/// Connection states for the WebSocket.
enum WsState { disconnected, connecting, authenticating, connected, reconnecting }

/// Manages the WebSocket connection to Stoat's Bonfire events service.
///
/// Usage:
///   final ws = StoatWebSocket(config: StoatConfig.armstream, token: session.token);
///   ws.events.listen((event) { ... });
///   await ws.connect();
///
class StoatWebSocket {
  final StoatConfig config;
  final String token;

  // Public streams
  final _eventController = StreamController<StoatEvent>.broadcast();
  Stream<StoatEvent> get events => _eventController.stream;

  final _stateController = StreamController<WsState>.broadcast();
  Stream<WsState> get stateStream => _stateController.stream;

  WsState _state = WsState.disconnected;
  WsState get state => _state;

  // Internals
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  static const _maxReconnectDelay = Duration(seconds: 30);
  static const _initialReconnectDelay = Duration(seconds: 2);

  StoatWebSocket({required this.config, required this.token});

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> connect() async {
    if (_state == WsState.connected || _state == WsState.connecting) return;
    _setState(WsState.connecting);
    await _connect();
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _setState(WsState.disconnected);
  }

  // ── Connection logic ───────────────────────────────────────────────────────

  Future<void> _connect() async {
    try {
      dev.log('[WS] Connecting to ${config.wsUrl}', name: 'stoat.ws');
      _channel = WebSocketChannel.connect(Uri.parse(config.wsUrl));

      // Wait for the connection to be established before sending auth.
      await _channel!.ready;

      _setState(WsState.authenticating);
      _sendRaw({'type': 'Authenticate', 'token': token});
      dev.log('[WS] Authenticate sent', name: 'stoat.ws');

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      dev.log('[WS] Connection failed: $e', name: 'stoat.ws');
      _scheduleReconnect();
    }
  }

  // ── Message handling ───────────────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (e) {
      dev.log('[WS] Failed to parse message: $e', name: 'stoat.ws');
      return;
    }

    dev.log('[WS] Raw: $raw', name: 'stoat.ws');

    final event = StoatEvent.fromJson(json);

    switch (event) {
      case AuthenticatedEvent():
        _reconnectAttempts = 0;
        _setState(WsState.connected);
        dev.log('[WS] Authenticated ✓', name: 'stoat.ws');

      case PingEvent():
        // Must respond immediately or the server will close the connection.
        _sendRaw({'type': 'Pong'});
        dev.log('[WS] Pong sent', name: 'stoat.ws');
        return; // Don't forward Ping/Pong to consumers.

      case LogoutEvent():
        dev.log('[WS] Session invalidated by server', name: 'stoat.ws');
        _setState(WsState.disconnected);
        // Forward so the app layer can redirect to login.

      case ErrorEvent(:final error):
        dev.log('[WS] Server error: $error', name: 'stoat.ws');

      case UnknownEvent(:final type):
        dev.log('[WS] Unknown event type: $type', name: 'stoat.ws');

      default:
        break;
    }

    _eventController.add(event);
  }

  void _onError(Object error) {
    dev.log('[WS] Stream error: $error', name: 'stoat.ws');
    _scheduleReconnect();
  }

  void _onDone() {
    dev.log('[WS] Connection closed', name: 'stoat.ws');
    if (_state != WsState.disconnected) {
      _scheduleReconnect();
    }
  }

  // ── Reconnect ──────────────────────────────────────────────────────────────

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive == true) return;

    final delay = _reconnectDelay();
    _setState(WsState.reconnecting);
    dev.log(
      '[WS] Reconnecting in ${delay.inSeconds}s (attempt ${_reconnectAttempts + 1})',
      name: 'stoat.ws',
    );

    _reconnectTimer = Timer(delay, () async {
      _reconnectAttempts++;
      await _subscription?.cancel();
      _channel = null;
      _setState(WsState.connecting);
      await _connect();
    });
  }

  Duration _reconnectDelay() {
    // Exponential back-off: 2s, 4s, 8s, 16s, 30s (capped).
    final seconds = _initialReconnectDelay.inSeconds * (1 << _reconnectAttempts);
    return Duration(
      seconds: seconds.clamp(
        _initialReconnectDelay.inSeconds,
        _maxReconnectDelay.inSeconds,
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _sendRaw(Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode(payload));
  }

  void _setState(WsState next) {
    if (_state == next) return;
    _state = next;
    _stateController.add(next);
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _stateController.close();
  }
}
