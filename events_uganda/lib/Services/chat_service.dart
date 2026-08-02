import 'dart:convert';

import 'package:events_uganda/Auth/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    required this.isMine,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isMine;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String? ?? '',
        conversationId: json['conversationId'] as String? ?? '',
        senderId: json['senderId'] as String? ?? '',
        text: json['text'] as String?,
        imageUrl: json['imageUrl'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['createdAt'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
        ),
        isMine: (json['mine'] ?? json['isMine']) as bool? ?? false,
      );
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageAt,
    required this.unreadCount,
  });

  final String id;
  final List<String> participantIds;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final int unreadCount;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final List<String> ids = (json['participantIds'] as String? ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return ChatConversation(
      id: json['id'] as String? ?? '',
      participantIds: ids,
      lastMessage: json['lastMessage'] as String?,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['lastMessageAt'] as num).toInt(),
            )
          : null,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  String? otherParticipantId(String myUserId) {
    for (final id in participantIds) {
      if (id != myUserId) return id;
    }
    return participantIds.isNotEmpty ? participantIds.first : null;
  }
}

class ChatSearchResults {
  const ChatSearchResults({this.conversations = const [], this.messages = const []});

  final List<ChatConversation> conversations;
  final List<ChatMessage> messages;

  factory ChatSearchResults.fromJson(Map<String, dynamic> json) {
    final List<ChatConversation> conversations = (json['conversations'] as List<dynamic>? ?? [])
        .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
        .toList();
    final List<ChatMessage> messages = (json['messages'] as List<dynamic>? ?? [])
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    return ChatSearchResults(conversations: conversations, messages: messages);
  }
}

class ChatService {
  static const String _baseUrl =
      'https://eventsuganda-backend-production-8c3a.up.railway.app/api';

  static const String kDefaultVendorId = 'vendor-1';
  static const String _namesKey = 'chat_user_names';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static void _ensureOk(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String message = 'Request failed (${response.statusCode})';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] != null) {
        message = body['message'] as String;
      }
    } catch (_) {}
    throw Exception(message);
  }

  static Future<String> myUserId() async {
    final user = await AuthService.getUser();
    final id = user?['id'];
    return (id is String && id.isNotEmpty) ? id : '';
  }

  static Future<List<ChatConversation>> getConversations() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/chat/conversations'),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
    final List<dynamic> raw = jsonDecode(response.body) as List<dynamic>;
    return raw
        .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<ChatConversation> createConversation(
    Set<String> participantIds, {
    String? initialMessage,
    String? otherName,
  }) async {
    final body = <String, dynamic>{'participantIds': participantIds.toList()};
    if (initialMessage != null && initialMessage.isNotEmpty) {
      body['initialMessage'] = initialMessage;
    }
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/conversations'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    _ensureOk(response);
    final conversation = ChatConversation.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    if (otherName != null && otherName.isNotEmpty) {
      final myId = await myUserId();
      final otherId = conversation.otherParticipantId(myId);
      if (otherId != null) await registerName(otherId, otherName);
    }
    return conversation;
  }

  static Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int page = 0,
    int size = 100,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/chat/conversations/$conversationId/messages')
          .replace(queryParameters: {'page': '$page', 'size': '$size'}),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
    final List<dynamic> raw = jsonDecode(response.body) as List<dynamic>;
    return raw
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<ChatMessage> sendMessage(
    String conversationId,
    String text,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/conversations/$conversationId/messages'),
      headers: await _authHeaders(),
      body: jsonEncode({'text': text}),
    );
    _ensureOk(response);
    return ChatMessage.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> markRead(String conversationId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/conversations/$conversationId/read'),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
  }

  static Future<Map<String, dynamic>?> getMe() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/me'),
      headers: await _authHeaders(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, String>> _readNames() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_namesKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeNames(Map<String, String> names) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_namesKey, jsonEncode(names));
  }

  static Future<void> registerName(String id, String name) async {
    final names = await _readNames();
    names[id] = name;
    await _writeNames(names);
  }

  static Future<String> nameFor(String id) async {
    final names = await _readNames();
    return names[id] ?? '';
  }
}
