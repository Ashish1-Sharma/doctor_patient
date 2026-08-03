import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

/// Centralized service to handle authentication API calls with the backend.
class AuthService {
  // Shared base API endpoint URL
  static const String baseUrl = 'https://tworingz.com/doctor_patient/api';

  /// Register a new Doctor user.
  /// POST /api/auth/register.php
  static Future<http.Response> registerDoctor(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/auth/register.php');
    developer.log('AuthService.registerDoctor: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('AuthService.registerDoctor: Success code ${response.statusCode}. Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('AuthService.registerDoctor: Exception caught: $e');
      rethrow;
    }
  }
  static Future<http.Response> registerSubDoctor(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/sub_user/addUser.php');
    developer.log('AuthService.registerDoctor: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('AuthService.registerDoctor: Success code ${response.statusCode}. Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('AuthService.registerDoctor: Exception caught: $e');
      rethrow;
    }
  }

  /// Authenticate/Login an existing Doctor user.
  /// POST /api/auth/login.php
  static Future<http.Response> loginDoctor(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/auth/login.php');
    developer.log('AuthService.loginDoctor: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('AuthService.loginDoctor: Success code ${response.statusCode}. Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('AuthService.loginDoctor: Exception caught: $e');
      rethrow;
    }
  }

  /// Authenticate/Login a sub-user (Doctor/Staff).
  /// POST /api/auth/subUserLogin.php
  static Future<http.Response> loginSubUser(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/sub_user/subUserLogin.php');
    developer.log('AuthService.loginSubUser: Calling POST $url with payload: $payload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      developer.log('AuthService.loginSubUser: Success code ${response.statusCode}. Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('AuthService.loginSubUser: Exception caught: $e');
      rethrow;
    }
  }

  /// Fetch all sub-users (Doctors/Staff) under a parent ID.
  /// GET /api/users/getByParentUserId.php?parentId=X
  static Future<http.Response> getSubUsers(int parentId) async {
    final url = Uri.parse('$baseUrl/sub_user/getUsersByParentId.php?parentId=$parentId');
    developer.log('AuthService.getSubUsers: Calling GET $url');
    try {
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );
      developer.log('AuthService.getSubUsers: Success code ${response.statusCode}. Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('AuthService.getSubUsers: Exception caught: $e');
      rethrow;
    }
  }
}

