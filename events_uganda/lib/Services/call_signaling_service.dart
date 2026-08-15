import 'dart:async';
import 'dart:convert';

import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/models/call_models.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';

/// Singleton STOMP client for call signaling.
///
/// Connects to the backend WebSocket endpoint and subscribes to the
/// authenticated user's private queue (`/user/queue/calls`). Incoming
/// signals are broadcast via [signals]. Outgoing actions are sent to the
/// `/app/call.*` destinations, where the backend relays them to the
/// other party.
class CallSignalingService {
  CallSignalingService._();

  static final CallSignalingService instance = CallSignalingService._();

  static const String _wsUrl = 'wss://events-uganda-26.onrender.com/ws';
  static const String _userQueue = '/user/queue/calls';

  final StreamController<CallSignal> _signals =
      StreamController<CallSignal>.broadcast();

  StompClient? _client;

  Stream<CallSignal> get signals => _signals.stream;

  bool get isActive => _client?.connected ?? false;

  /// Ensures the socket is connected, (re)connecting if needed.
  Future<void> ensureConnected() async {
    if (isActive) return;
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return;

    if (_client != null) {
      _client!.activate();
      return;
    }

    _client = StompClient(
      config: StompConfig(
        url: _wsUrl,
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 0),
        heartbeatOutgoing: const Duration(seconds: 0),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (_) {
          _subscribeUserQueue();
        },
        onStompError: (_) {},
        onWebSocketError: (_) {},
      ),
    );
    _client!.activate();
  }

  void _subscribeUserQueue() {
    final client = _client;
    if (client == null || !client.connected) return;
    client.subscribe(
      destination: _userQueue,
      callback: (frame) {
        final body = frame.body;
        if (body == null || body.isEmpty) return;
        try {
          final raw = jsonDecode(body) as Map<String, dynamic>;
          final signal = CallSignal.fromJson(raw);
          if (signal.type.isNotEmpty) _signals.add(signal);
        } catch (_) {}
      },
    );
  }

  /// Sends an action to a `/app/call.*` destination.
  void send(String action, Map<String, dynamic> payload) {
    final client = _client;
    if (client == null || !client.connected) return;
    client.send(
      destination: '/app/call.$action',
      body: jsonEncode(payload),
    );
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
  }

  void dispose() {
    disconnect();
    _signals.close();
  }
}
