# stoat-client

A native [Stoat](https://github.com/revoltchat) (Revolt-compatible) client built with Flutter, targeting Linux desktop, Android, and iOS.

## What's Working

- Email/password authentication with persistent sessions via secure storage
- Session restore on app startup
- WebSocket connection to Stoat's Bonfire event service with automatic reconnect and exponential backoff
- Ping/Pong keepalive handling
- Server and channel browsing
- Message history with user display names and avatars

## Roadmap

### In Progress
- [ ] Avatar loading (URL resolves correctly, parsing bug under investigation)

### UI
- [ ] Message input and sending
- [ ] Live message appending from WebSocket `Message` events
- [ ] Mention rendering (`<@userId>` → display name)
- [ ] Server icons (currently showing first letter placeholder)
- [ ] Timestamps on messages
- [ ] Image/attachment rendering

### Features
- [ ] Notifications for new messages
- [ ] Unread indicators on channels and servers
- [ ] Member list sidebar
- [ ] User profile popover on avatar click
- [ ] Message reactions
- [ ] Edit and delete messages

### Platform
- [ ] Android build and testing
- [ ] iOS build via TestFlight + Codemagic CI/CD

### Polish
- [ ] Error handling UI (reconnect banner, failed message send)
- [ ] Empty state illustrations
- [ ] Settings screen (instance URL, logout)
- [ ] Theming / accent colour picker

## Target Platforms

| Platform | Status |
|----------|--------|
| Linux desktop | ✅ Working |
| Android | 🚧 Planned |
| iOS | 🚧 Planned |

## Requirements

### Linux

```bash
sudo dnf install -y clang cmake ninja-build gtk3-devel pkg-config libsecret-devel
```

### Flutter

Flutter 3.29+ is required. Install via the [official SDK](https://docs.flutter.dev/get-started/install/linux).

## Getting Started

```bash
git clone git@github.com:yeghia-s/stoat-flutter.git
cd stoat-flutter
flutter pub get
flutter run -d linux
```

By default the client connects to `chat.armstream.stream`. To point it at a different instance, edit `lib/api/config.dart`.

## Project Structure

```
lib/
├── api/
│   ├── config.dart           # Instance URLs
│   ├── http_client.dart      # REST API calls
│   ├── stoat_client.dart     # Top-level client (auth + WebSocket)
│   ├── models/
│   │   ├── channel.dart
│   │   ├── message.dart
│   │   ├── server.dart
│   │   ├── session.dart
│   │   └── user.dart
│   └── websocket/
│       ├── events.dart       # Sealed event hierarchy
│       └── stoat_websocket.dart
├── state/
│   └── app_state.dart        # ChangeNotifier state layer
└── ui/
    └── shell.dart            # Main shell (server list, channel list, message area)
```

## Dependencies

- [`provider`](https://pub.dev/packages/provider) — state management
- [`http`](https://pub.dev/packages/http) — REST calls
- [`web_socket_channel`](https://pub.dev/packages/web_socket_channel) — WebSocket
- [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) — token persistence
- [`characters`](https://pub.dev/packages/characters) — Unicode-safe string operations
