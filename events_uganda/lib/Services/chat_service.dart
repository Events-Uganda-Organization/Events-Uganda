import 'dart:convert';

import 'package:events_uganda/Auth/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.audioUrl,
    this.audioDurationMs,
    required this.createdAt,
    required this.isMine,
    this.readAt,
    this.deliveredAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final String? audioUrl;
  final int? audioDurationMs;
  final DateTime createdAt;
  final bool isMine;
  final DateTime? readAt;
  final DateTime? deliveredAt;

  bool get hasMedia => imageUrl != null || audioUrl != null;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String? ?? '',
        conversationId: json['conversationId'] as String? ?? '',
        senderId: json['senderId'] as String? ?? '',
        text: json['text'] as String?,
        imageUrl: json['imageUrl'] as String?,
        audioUrl: json['audioUrl'] as String?,
        audioDurationMs: (json['audioDurationMs'] as num?)?.toInt(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['createdAt'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
        ),
        isMine: (json['mine'] ?? json['isMine']) as bool? ?? false,
        readAt: _parseEpoch(json['readAt']),
        deliveredAt: _parseEpoch(json['deliveredAt']),
      );

  static DateTime? _parseEpoch(dynamic value) {
    final num? ms = value as num?;
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms.toInt());
  }
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageAt,
    required this.unreadCount,
    this.disappearingMode = 'OFF',
    this.blocked = false,
    this.amBlocked = false,
  });

  final String id;
  final List<String> participantIds;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String disappearingMode;
  final bool blocked;
  final bool amBlocked;

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
      disappearingMode: json['disappearingMode'] as String? ?? 'OFF',
      blocked: json['blocked'] as bool? ?? false,
      amBlocked: json['amBlocked'] as bool? ?? false,
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
      'https://events-uganda-26.onrender.com/api';

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

  static Future<http.Response> _mutatingRequest(
    Future<http.Response> Function() request, {
    int attempts = 2,
  }) async {
    Object? lastError;
    http.Response? lastResponse;
    for (int attempt = 0; attempt < attempts; attempt++) {
      try {
        final response = await request();
        if (response.statusCode < 500) return response;
        lastResponse = response;
      } catch (e) {
        lastError = e;
      }
      if (attempt < attempts - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
      }
    }
    if (lastResponse != null) return lastResponse!;
    throw lastError!;
  }

  static Future<String> myUserId() async {
    final user = await AuthService.getUser();
    final id = user?['id'];
    return (id is String && id.isNotEmpty) ? id : '';
  }

  static String mediaUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    return '$_baseUrl$relativePath';
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
    final response = await _mutatingRequest(
      () async => http.post(
        Uri.parse('$_baseUrl/chat/conversations'),
        headers: await _authHeaders(),
        body: jsonEncode(body),
      ),
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

  static Future<ChatSearchResults> searchChat(
    String query, {
    int page = 0,
    int size = 50,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/chat/search')
          .replace(queryParameters: {'q': query, 'page': '$page', 'size': '$size'}),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
    return ChatSearchResults.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
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

  static Future<ChatMessage> sendImage(
    String conversationId,
    List<int> bytes, {
    String? caption,
    String filename = 'photo.jpg',
  }) =>
      _uploadMedia(
        conversationId,
        'IMAGE',
        bytes,
        filename,
        contentType: _detectImageType(bytes),
        caption: caption,
      );

  static Future<ChatMessage> sendVoice(
    String conversationId,
    List<int> bytes, {
    required String filename,
    required Duration duration,
  }) =>
      _uploadMedia(
        conversationId,
        'AUDIO',
        bytes,
        filename,
        contentType: filename.toLowerCase().endsWith('.webm')
            ? MediaType('audio', 'webm')
            : MediaType('audio', 'mp4'),
        durationMs: duration.inMilliseconds,
      );

  static MediaType _detectImageType(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return MediaType('image', 'jpeg');
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return MediaType('image', 'png');
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return MediaType('image', 'webp');
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return MediaType('image', 'gif');
    }
    return MediaType('image', 'jpeg');
  }

  static Future<ChatMessage> _uploadMedia(
    String conversationId,
    String type,
    List<int> bytes,
    String filename, {
    required MediaType contentType,
    String? caption,
    int? durationMs,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse(
      '$_baseUrl/chat/conversations/$conversationId/media',
    ).replace(queryParameters: {
      'type': type,
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      if (durationMs != null) 'durationMs': '$durationMs',
    });

    final request = http.MultipartRequest('POST', uri);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: contentType,
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
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

  static Future<ChatConversation> getConversation(String conversationId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/chat/conversations/$conversationId'),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
    return ChatConversation.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<void> clearChat(String conversationId) async {
    final response = await _mutatingRequest(
      () async => http.delete(
        Uri.parse('$_baseUrl/chat/conversations/$conversationId/messages'),
        headers: await _authHeaders(),
      ),
    );
    _ensureOk(response);
  }

  static Future<void> setDisappearingMode(
    String conversationId,
    String mode,
  ) async {
    final response = await _mutatingRequest(
      () async => http.put(
        Uri.parse('$_baseUrl/chat/conversations/$conversationId/disappearing'),
        headers: await _authHeaders(),
        body: jsonEncode({'mode': mode}),
      ),
    );
    _ensureOk(response);
  }

  static Future<void> blockUser(String conversationId) async {
    final response = await _mutatingRequest(
      () async => http.post(
        Uri.parse('$_baseUrl/chat/conversations/$conversationId/block'),
        headers: await _authHeaders(),
      ),
    );
    _ensureOk(response);
  }

  static Future<void> unblockUser(String conversationId) async {
    final response = await _mutatingRequest(
      () async => http.post(
        Uri.parse('$_baseUrl/chat/conversations/$conversationId/unblock'),
        headers: await _authHeaders(),
      ),
    );
    _ensureOk(response);
  }

  static Future<void> reportUser(String conversationId, String reason) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/conversations/$conversationId/report'),
      headers: await _authHeaders(),
      body: jsonEncode({'reason': reason}),
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
