import 'dart:convert';

import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/models/review_model.dart';
import 'package:http/http.dart' as http;

class ReviewSummary {
  final double avgRating;
  final int totalCount;
  final List<int> starCounts;

  ReviewSummary({
    required this.avgRating,
    required this.totalCount,
    required this.starCounts,
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['starCounts'] as List<dynamic>? ?? const [];
    final starCounts = List<int>.generate(
      6,
      (i) => i < raw.length ? (raw[i] as num).toInt() : 0,
    );
    return ReviewSummary(
      avgRating: ((json['avgRating'] as num?)?.toDouble()) ?? 0,
      totalCount: ((json['totalCount'] as num?)?.toInt()) ?? 0,
      starCounts: starCounts,
    );
  }
}

class ReviewService {
  ReviewService._();

  static const String _baseUrl =
      'https://events-uganda-26.onrender.com/api';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
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

  static Future<List<ReviewModel>> fetchReviews(String serviceId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/reviews/service/$serviceId'),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
    final List<dynamic> raw = jsonDecode(response.body) as List<dynamic>;
    return raw
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<ReviewSummary> fetchSummary(String serviceId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/reviews/service/$serviceId/summary'),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
    return ReviewSummary.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<void> submitReview(
    String serviceId, {
    required int rating,
    required String text,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/reviews/service/$serviceId'),
      headers: await _authHeaders(),
      body: jsonEncode({'rating': rating, 'reviewText': text}),
    );
    _ensureOk(response);
  }

  static Future<void> updateReview(
    String reviewId, {
    required int rating,
    required String text,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/reviews/$reviewId'),
      headers: await _authHeaders(),
      body: jsonEncode({'rating': rating, 'reviewText': text}),
    );
    _ensureOk(response);
  }

  static Future<void> deleteReview(String reviewId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/reviews/$reviewId'),
      headers: await _authHeaders(),
    );
    _ensureOk(response);
  }
}
