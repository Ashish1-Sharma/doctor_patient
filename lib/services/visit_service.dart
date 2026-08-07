import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Centralized service to handle visit API endpoints.
class VisitService {
  // Shared base API endpoint URL inherited from AuthService base
  static const String baseUrl = AuthService.baseUrl;

  /// Create a new patient visit transaction.
  /// POST /api/visits/create.php
  static Future<http.Response> createVisit(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/visits/create.php');
    developer.log('VisitService.createVisit: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('VisitService.createVisit: Success code ${response.statusCode}. Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('VisitService.createVisit: Exception caught: $e');
      rethrow;
    }
  }

  /// Update an existing patient visit transaction.
  /// POST /api/visits/update.php
  static Future<http.Response> updateVisit(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/visits/update.php');
    developer.log('VisitService.updateVisit: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('VisitService.updateVisit: Success code ${response.statusCode}. Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('VisitService.updateVisit: Exception caught: $e');
      rethrow;
    }
  }

  /// Fetch visits list for a specific patient.
  /// POST /api/visits/list.php
  static Future<http.Response> getVisits(int parentId, int patientId) async {
    final url = Uri.parse('$baseUrl/visits/list.php');
    final payload = {
      'parentId': parentId,
      'patientId': patientId,
    };
    developer.log('VisitService.getVisits: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('VisitService.getVisits: Success code ${response.statusCode}. Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('VisitService.getVisits: Exception caught: $e');
      rethrow;
    }
  }

  /// Get details of a specific visit.
  /// POST /api/visits/getById.php
  static Future<http.Response> getVisitById(int parentId, int visitId) async {
    final url = Uri.parse('$baseUrl/visits/getById.php');
    final payload = {
      'parentId': parentId,
      'visitId': visitId,
    };
    developer.log('VisitService.getVisitById: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('VisitService.getVisitById: Success code ${response.statusCode}. Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('VisitService.getVisitById: Exception caught: $e');
      rethrow;
    }
  }

  /// Fetch consolidated visit report details (visit + patient + clinic + payment) for printing.
  /// POST /api/visits/getVisitReportDetails.php
  static Future<http.Response> getVisitReportDetails(int parentId, int visitId) async {
    final url = Uri.parse('$baseUrl/visits/getVisitReportDetails.php');
    final payload = {
      'parentId': parentId,
      'visitId': visitId,
    };
    developer.log('VisitService.getVisitReportDetails: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('VisitService.getVisitReportDetails: Success code ${response.statusCode}. Body: ${response.body}');
      // ignore: avoid_print
      print('VisitService.getVisitReportDetails response [${response.statusCode}]: ${response.body}');
      return response;
    } catch (e) {
      developer.log('VisitService.getVisitReportDetails: Exception caught: $e');
      rethrow;
    }
  }

  /// Change status of a specific visit.
  /// POST /api/visits/changeStatus.php
  static Future<http.Response> changeVisitStatus(int id, int parentId, int status) async {
    final url = Uri.parse('$baseUrl/visits/changeStatus.php');
    final payload = {
      'id': id,
      'parentId': parentId,
      'status': status,
    };
    developer.log('VisitService.changeVisitStatus: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('VisitService.changeVisitStatus: Success code ${response.statusCode}. Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('VisitService.changeVisitStatus: Exception caught: $e');
      rethrow;
    }
  }

  /// Delete a specific visit and its associated records.
  /// POST /api/visits/delete.php
  static Future<http.Response> deleteVisit(int id, int parentId) async {
    final url = Uri.parse('$baseUrl/visits/delete.php');
    final payload = {
      'id': id,
      'parentId': parentId,
    };
    developer.log('VisitService.deleteVisit: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('VisitService.deleteVisit: Success code ${response.statusCode}. Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('VisitService.deleteVisit: Exception caught: $e');
      rethrow;
    }
  }
}
