import 'dart:convert';
import 'package:http/http.dart' as http;

const _baseUrl = 'https://events-uganda-26.onrender.com/api';
final token = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJmYjhmNjgxMC0wOGVjLTQ0NzYtYWRlYi0wMWVmYzJhODRhOGMiLCJlbWFpbCI6InJldmlld3Rlc3Q1NTI5NjNAdGVzdC5jb20iLCJpYXQiOjE3ODY4NjIyNDcsImV4cCI6MTc4NzQ2NzA0N30.nDoamQkKbYcPuz5WM2eR62E0tY6AqpyfemF9nlmeXuI';

Future<Map<String, String>> _authHeaders() async {
  return <String, String>{
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

void _ensureOk(http.Response response) {
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

Future<void> main() async {
  final text = 'Great service!';
  final rating = 5;
  final serviceId = 'cake-design';

  print('=== POST ===');
  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/reviews/service/$serviceId'),
      headers: await _authHeaders(),
      body: jsonEncode({'rating': rating, 'reviewText': text}),
    );
    print('status: ${response.statusCode}');
    _ensureOk(response);
    print('post ok: ${response.body}');
  } catch (e) {
    print('POST ERROR: $e');
    return;
  }

  print('=== GET list ===');
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/reviews/service/$serviceId'),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
    final List<dynamic> raw = jsonDecode(response.body) as List<dynamic>;
    for (final e in raw) {
      final m = e as Map<String, dynamic>;
      final id = m['id'] as String? ?? '';
      final userName = m['userName'] as String? ?? 'User';
      final userImageUrl = m['userImageUrl'] as String? ?? '';
      final reviewText = m['reviewText'] as String? ?? '';
      final date = m['date'] as String? ?? '';
      final ratingN = (m['rating'] as num?)?.toInt() ?? 0;
      print('review: $id | $userName | $userImageUrl | $reviewText | $date | $ratingN');
    }
  } catch (e) {
    print('LIST ERROR: $e');
    return;
  }

  print('=== GET summary ===');
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/reviews/service/$serviceId/summary'),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = json['starCounts'] as List<dynamic>? ?? const [];
    final starCounts = List<int>.generate(
      6,
      (i) => i < raw.length ? (raw[i] as num).toInt() : 0,
    );
    final avg = ((json['avgRating'] as num?)?.toDouble()) ?? 0;
    final total = ((json['totalCount'] as num?)?.toInt()) ?? 0;
    print('summary: avg=$avg total=$total stars=$starCounts');
  } catch (e) {
    print('SUMMARY ERROR: $e');
    return;
  }
  print('ALL OK');
}
