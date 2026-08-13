import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:events_uganda/Auth/auth_service.dart';

class UserService {
  static const String _baseUrl = 'https://events-uganda-26.onrender.com/api';

  static Future<Map<String, String>> _authHeader() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Orders ────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getOrders() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/orders'),
      headers: await _authHeader(),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return (body['orders'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    }
    throw Exception('Failed to load orders');
  }

  // ─── Payment Methods ───────────────────────────────

  static Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/payment-methods'),
      headers: await _authHeader(),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return (body['paymentMethods'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    }
    throw Exception('Failed to load payment methods');
  }

  static Future<Map<String, dynamic>> addPaymentMethod({
    required String type,
    required String phone,
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/payment-methods'),
      headers: await _authHeader(),
      body: jsonEncode({'type': type, 'phone': phone, 'name': name}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(body['message'] ?? 'Failed to add payment method');
  }

  // ─── Refunds ───────────────────────────────────────

  static Future<Map<String, dynamic>> requestRefund({
    required String orderId,
    required String reason,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/refunds'),
      headers: await _authHeader(),
      body: jsonEncode({'orderId': orderId, 'reason': reason}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(body['message'] ?? 'Refund request failed');
  }

  // ─── Orders Count ──────────────────────────────────

  static Future<int> getOrdersCount() async {
    final orders = await getOrders();
    return orders.length;
  }
}
