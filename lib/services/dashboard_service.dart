import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Centralized service to handle dashboard aggregate endpoints.
class DashboardService {
  // Shared base API endpoint URL inherited from AuthService base
  static const String baseUrl = AuthService.baseUrl;

  /// Fetch all dashboard tile stats in a single aggregated call.
  /// POST /api/dashboard/summary.php
  static Future<http.Response> getSummary(int parentId) async {
    final url = Uri.parse('$baseUrl/dashboard/summary.php');
    final payload = {'parentId': parentId};
    developer.log('DashboardService.getSummary: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('DashboardService.getSummary: Code ${response.statusCode}. Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('DashboardService.getSummary: Exception caught: $e');
      rethrow;
    }
  }
}
