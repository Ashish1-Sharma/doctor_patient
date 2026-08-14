import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Centralized service to handle appointment scheduling API calls directly with backend.
class AppointmentService {
  static const String baseUrl = AuthService.baseUrl;

  /// Book a new appointment.
  /// POST /api/appointments/create.php
  static Future<http.Response> createAppointment(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/appointments/create.php');
    developer.log('AppointmentService.createAppointment: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('AppointmentService.createAppointment: Code ${response.statusCode}.');
      return response;
    } catch (e) {
      developer.log('AppointmentService.createAppointment: Exception caught: $e');
      rethrow;
    }
  }

  /// Get scheduled appointments list for a doctor.
  /// POST /api/appointments/list.php
  static Future<http.Response> getAppointments(int doctorId) async {
    final url = Uri.parse('$baseUrl/appointments/list.php');
    final payload = {'doctorId': doctorId};
    developer.log('AppointmentService.getAppointments: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('AppointmentService.getAppointments: Code ${response.statusCode}.');
      return response;
    } catch (e) {
      developer.log('AppointmentService.getAppointments: Exception caught: $e');
      rethrow;
    }
  }

  /// Update/reschedule an existing appointment.
  /// POST /api/appointments/update.php
  static Future<http.Response> updateAppointment(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/appointments/update.php');
    developer.log('AppointmentService.updateAppointment: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('AppointmentService.updateAppointment: Code ${response.statusCode}.');
      return response;
    } catch (e) {
      developer.log('AppointmentService.updateAppointment: Exception caught: $e');
      rethrow;
    }
  }

  /// Delete a specific appointment.
  /// POST /api/appointments/delete.php
  static Future<http.Response> deleteAppointment(int id) async {
    final url = Uri.parse('$baseUrl/appointments/delete.php');
    final payload = {'id': id};
    developer.log('AppointmentService.deleteAppointment: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('AppointmentService.deleteAppointment: Code ${response.statusCode}.');
      return response;
    } catch (e) {
      developer.log('AppointmentService.deleteAppointment: Exception caught: $e');
      rethrow;
    }
  }
}
