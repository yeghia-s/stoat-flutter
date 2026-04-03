import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api/stoat_client.dart';
import 'api/config.dart';
import 'api/websocket/events.dart';
import 'api/websocket/stoat_websocket.dart';
import 'state/app_state.dart';
import 'ui/shell.dart';
import 'api/models/message.dart';

void main() {
  runApp(const StoatApp());
}

class StoatApp extends StatelessWidget {
  const StoatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Stoat Client',
        theme: ThemeData.dark(useMaterial3: true),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  final _client = StoatClient(config: StoatConfig.armstream);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tryRestore();
  }

  Future<void> _tryRestore() async {
    await _client.tryRestoreSession();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_client.isLoggedIn) {
      return LoginScreen(client: _client);
    }
    return MainScreen(client: _client);
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }
}

// ── Login screen ─────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  final StoatClient client;
  const LoginScreen({super.key, required this.client});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await widget.client.login(_emailCtrl.text.trim(), _passCtrl.text);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainScreen(client: widget.client)),
        );
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in to Stoat')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main screen ───────────────────────────────────────────────────────────────

class MainScreen extends StatefulWidget {
  final StoatClient client;
  const MainScreen({super.key, required this.client});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  WsState _wsState = WsState.disconnected;

  @override
  void initState() {
    super.initState();

    widget.client.connectionState.listen((state) {
      if (mounted) setState(() => _wsState = state);
    });

    widget.client.events.listen((event) {
      if (event is ReadyEvent) {
        final appState = context.read<AppState>();
        appState.loadFromReady(
          servers: event.servers,
          channels: event.channels,
          users: event.users,
          members: event.members,
        );
      }
      if (event is MessageEvent) {
        final appState = context.read<AppState>();
        appState.prependMessage(
          event.channelId,
          StoatMessage(
            id: event.id,
            channelId: event.channelId,
            authorId: event.authorId,
            content: event.content,
            timestamp: event.timestamp,
          ),
        );
      }
      if (event is LogoutEvent && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LoginScreen(client: widget.client),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stoat'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Chip(
              label: Text(_wsState.name),
              backgroundColor: switch (_wsState) {
                WsState.connected      => Colors.green.shade800,
                WsState.authenticating => Colors.orange.shade800,
                WsState.reconnecting   => Colors.yellow.shade800,
                _                      => Colors.red.shade800,
              },
            ),
          ),
        ],
      ),
      body: ShellScreen(client: widget.client),
    );
  }
}
