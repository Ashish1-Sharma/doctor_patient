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

  /// Get scheduled appointments list for a doctor with optional range (today, tomorrow, week, custom, all).
  /// POST /api/appointments/list.php
  static Future<http.Response> getAppointments(int doctorId, {String range = 'all', String? from, String? to}) async {
    final url = Uri.parse('$baseUrl/appointments/list.php');
    final payload = {
      'doctorId': doctorId,
      'range': range,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    };
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

  /// Fetch single appointment details with joined patient information.
  /// POST /api/appointments/detail.php
  static Future<http.Response> getAppointmentDetail(int id) async {
    final url = Uri.parse('$baseUrl/appointments/detail.php');
    final payload = {'id': id};
    developer.log('AppointmentService.getAppointmentDetail: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('AppointmentService.getAppointmentDetail: Code ${response.statusCode}.');
      return response;
    } catch (e) {
      developer.log('AppointmentService.getAppointmentDetail: Exception caught: $e');
      rethrow;
    }
  }

  /// Fetch appointment stats (today count & total upcoming count).
  /// POST /api/appointments/stats.php
  static Future<http.Response> getAppointmentStats(int doctorId) async {
    final url = Uri.parse('$baseUrl/appointments/stats.php');
    final payload = {'doctorId': doctorId};
    developer.log('AppointmentService.getAppointmentStats: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('AppointmentService.getAppointmentStats: Code ${response.statusCode}.');
      return response;
    } catch (e) {
      developer.log('AppointmentService.getAppointmentStats: Exception caught: $e');
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
