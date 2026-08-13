import 'dart:convert';
import 'package:http/http.dart' as http;

class OtpApiService {
  static const String _baseUrl = 'https://events-uganda-26.onrender.com/api/otp';

  static Future<Map<String, dynamic>> sendOtp({
    String? email,
    String? phone,
  }) async {
    final body = <String, String>{};
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;

    final response = await http.post(
      Uri.parse('$_baseUrl/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> verifyOtp({
    String? email,
    String? phone,
    required String otp,
  }) async {
    final body = <String, String>{'otp': otp};
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;

    final response = await http.post(
      Uri.parse('$_baseUrl/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
