import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Centralized service to handle payment and billing API calls directly with backend.
class PaymentService {
  static const String baseUrl = AuthService.baseUrl;

  /// Record a new payment invoice.
  /// POST /api/payments/create.php
  static Future<http.Response> createPayment(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/payments/create.php');
    developer.log('PaymentService.createPayment: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('PaymentService.createPayment: Code ${response.statusCode}.');
      return response;
    } catch (e) {
      developer.log('PaymentService.createPayment: Exception caught: $e');
      rethrow;
    }
  }

  /// Get payments list.
  /// POST /api/payments/list.php
  static Future<http.Response> getPayments(int parentId) async {
    final url = Uri.parse('$baseUrl/payments/list.php');
    final payload = {'parentId': parentId};
    developer.log('PaymentService.getPayments: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('PaymentService.getPayments: Code ${response.statusCode}.');
      return response;
    } catch (e) {
      developer.log('PaymentService.getPayments: Exception caught: $e');
      rethrow;
    }
  }

  /// Update invoice details.
  /// POST /api/payments/update.php
  static Future<http.Response> updatePaymentDetails(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/payments/update.php');
    developer.log('PaymentService.updatePaymentDetails: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('PaymentService.updatePaymentDetails: Code ${response.statusCode}.');
      return response;
    } catch (e) {
      developer.log('PaymentService.updatePaymentDetails: Exception caught: $e');
      rethrow;
    }
  }
}
