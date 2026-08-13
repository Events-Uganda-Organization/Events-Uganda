import 'dart:async';
import 'dart:convert';

import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/models/app_notification.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';

/// Singleton STOMP client for real-time notifications.
///
/// Connects to the backend WebSocket endpoint and subscribes to the
/// authenticated user's private queue (`/user/queue/notifications`).
/// Incoming notifications are broadcast via [notifications].
class NotificationSocketService {
  NotificationSocketService._();

  static final NotificationSocketService instance = NotificationSocketService._();

  static const String _wsUrl =
      'wss://events-uganda-26.onrender.com/ws';
  static const String _userQueue = '/user/queue/notifications';

  final StreamController<AppNotification> _notifications =
      StreamController<AppNotification>.broadcast();

  StompClient? _client;

  Stream<AppNotification> get notifications => _notifications.stream;

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
          final notification = AppNotification.fromJson(raw);
          if (notification.id.isNotEmpty) _notifications.add(notification);
        } catch (_) {}
      },
    );
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
  }

  void dispose() {
    disconnect();
    _notifications.close();
  }
}
