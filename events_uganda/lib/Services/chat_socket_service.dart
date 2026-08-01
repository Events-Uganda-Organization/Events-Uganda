import 'dart:async';
import 'dart:convert';

import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/Services/chat_service.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';

/// Singleton STOMP client for real-time chat messaging.
///
/// Connects once to the backend WebSocket endpoint, subscribes to the
/// authenticated user's private queue (`/user/queue/messages`) and exposes
/// incoming messages as a broadcast [Stream]. Sending is done via
/// [sendMessage], which publishes to `/app/chat.sendMessage`.
class ChatSocketService {
  ChatSocketService._();

  static final ChatSocketService instance = ChatSocketService._();

  static const String _wsUrl =
      'wss://eventsuganda-backend-production-8c3a.up.railway.app/ws';
  static const String _userQueue = '/user/queue/messages';
  static const String _sendDestination = '/app/chat.sendMessage';

  final StreamController<ChatMessage> _messages =
      StreamController<ChatMessage>.broadcast();

  StompClient? _client;
  String? _myUserId;

  Stream<ChatMessage> get messages => _messages.stream;

  bool get isActive => _client?.connected ?? false;

  Future<String?> _myId() async {
    if (_myUserId != null && _myUserId!.isNotEmpty) return _myUserId;
    final id = await ChatService.myUserId();
    _myUserId = id;
    return id;
  }

  /// Ensures the socket is connected, (re)connecting if needed.
  Future<void> ensureConnected() async {
    if (isActive) return;
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return;
    await _myId();

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
          final message = _parseMessage(raw);
          if (message != null) _messages.add(message);
        } catch (_) {}
      },
    );
  }

  ChatMessage? _parseMessage(Map<String, dynamic> raw) {
    final senderId = raw['senderId'] as String? ?? '';
    final myId = _myUserId ?? '';
    final message = ChatMessage.fromJson(raw);
    return ChatMessage(
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      text: message.text,
      imageUrl: message.imageUrl,
      createdAt: message.createdAt,
      isMine: senderId.isNotEmpty && senderId == myId,
    );
  }

  /// Sends a text message over STOMP. Returns true if queued, false if the
  /// socket is not connected (caller should fall back to REST).
  bool sendMessage(String conversationId, String text) {
    final client = _client;
    if (client == null || !client.connected) return false;
    client.send(
      destination: _sendDestination,
      body: jsonEncode({'conversationId': conversationId, 'text': text}),
    );
    return true;
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
  }

  void dispose() {
    disconnect();
    _messages.close();
  }
}
