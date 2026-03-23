/// Stoat instance configuration.
/// Pass this around rather than hardcoding URLs anywhere.
class StoatConfig {
  final String apiUrl;    // e.g. https://chat.armstream.stream/api
  final String wsUrl;     // e.g. wss://chat.armstream.stream/ws
  final String autumnUrl; // e.g. https://chat.armstream.stream/autumn

  const StoatConfig({
    required this.apiUrl,
    required this.wsUrl,
    required this.autumnUrl,
  });

  /// Your self-hosted instance.
  static const armstream = StoatConfig(
    apiUrl: 'https://chat.armstream.stream/api',
    wsUrl: 'wss://chat.armstream.stream/ws',
    autumnUrl: 'https://chat.armstream.stream/autumn',
  );
}
