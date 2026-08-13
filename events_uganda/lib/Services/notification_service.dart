import 'dart:convert';

import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/models/app_notification.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  NotificationService._();

  static const String _baseUrl =
      'https://events-uganda-26.onrender.com/api';

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

  static List<AppNotification> _parseList(String body) {
    final List<dynamic> raw = jsonDecode(body) as List<dynamic>;
    return raw
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<AppNotification>> fetchNotifications({
    bool archived = false,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/notifications')
          .replace(queryParameters: {'archived': '$archived'}),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
    return _parseList(response.body);
  }

  static Future<int> getUnreadCount() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/notifications/unread-count'),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
    return jsonDecode(response.body) as int;
  }

  static Future<AppNotification> create({
    required String type,
    required String title,
    String? body,
    required String category,
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/notifications'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'type': type,
        'title': title,
        'body': body,
        'category': category,
        'userId': userId,
      }),
    );
    _ensureOk(response);
    return AppNotification.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> markRead(String id) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/notifications/$id/read'),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
  }

  static Future<void> markUnread(String id) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/notifications/$id/unread'),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
  }

  static Future<void> markAllRead() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/notifications/read-all'),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
  }

  static Future<void> archive(String id) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/notifications/$id/archive'),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
  }

  static Future<void> restore(String id) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/notifications/$id/restore'),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
  }

  static Future<void> delete(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/notifications/$id'),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
  }

  static Future<void> deleteRead() async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/notifications/read'),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
  }
}
