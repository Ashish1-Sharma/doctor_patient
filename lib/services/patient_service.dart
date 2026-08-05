import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Centralized service to handle patient API endpoints.
class PatientService {
  // Shared base API endpoint URL inherited from AuthService base
  static const String baseUrl = AuthService.baseUrl;

  /// Fetch patients for a specific doctor parentId.
  /// POST /api/patients/list.php
  static Future<http.Response> getPatients(int parentId) async {
    final url = Uri.parse('$baseUrl/patients/list.php');
    developer.log('PatientService.getPatients: Calling POST $url with parentId: $parentId');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'parentId': parentId}),
      );
      developer.log('PatientService.getPatients: Success code ${response.statusCode}. Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('PatientService.getPatients: Exception caught: $e');
      rethrow;
    }
  }

  /// Create a new patient profile.
  /// POST /api/patients/create.php
  static Future<http.Response> createPatient(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/patients/create.php');
    developer.log('PatientService.createPatient: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('PatientService.createPatient: Success code ${response.statusCode}. Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('PatientService.createPatient: Exception caught: $e');
      rethrow;
    }
  }

  /// Update an existing patient profile.
  /// POST /api/patients/update.php
  static Future<http.Response> updatePatient(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/patients/update.php');
    developer.log('PatientService.updatePatient: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('PatientService.updatePatient: Success code ${response.statusCode}. Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('PatientService.updatePatient: Exception caught: $e');
      rethrow;
    }
  }

  /// Delete a patient profile and associated records.
  /// POST /api/patients/delete.php
  static Future<http.Response> deletePatient(int id, int parentId) async {
    final url = Uri.parse('$baseUrl/patients/delete.php');
    developer.log('PatientService.deletePatient: Calling POST $url with id: $id, parentId: $parentId');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'parentId': parentId}),
      );
      developer.log('PatientService.deletePatient: Success code ${response.statusCode}. Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('PatientService.deletePatient: Exception caught: $e');
      rethrow;
    }
  }
}
