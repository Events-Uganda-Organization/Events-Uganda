import 'dart:convert';

import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/models/notification_preferences.dart';
import 'package:http/http.dart' as http;

class NotificationSettingsService {
  NotificationSettingsService._();

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

  static Future<NotificationPreferences> fetch() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/notification-settings'),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
    return NotificationPreferences.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<NotificationPreferences> save(NotificationPreferences prefs) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/notification-settings'),
      headers: await _authHeaders(),
      body: jsonEncode(prefs.toJson()),
    );
    _ensureOk(response);
    return NotificationPreferences.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<NotificationPreferences> reset() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/notification-settings/reset'),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic> && body['data'] != null) {
      return NotificationPreferences.fromJson(
          body['data'] as Map<String, dynamic>);
    }
    return NotificationPreferences.defaults();
  }
}
