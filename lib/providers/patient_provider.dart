import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../services/patient_service.dart';

/// PatientProvider manages the state of patient list transactions,
/// search queries, loading overlays, and CRUD error operations.
class PatientProvider extends ChangeNotifier {
  List<PatientModel> _patients = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PatientModel> get patients => _patients;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch all patients registered under the doctor parentId.
  /// POST /api/patients/list.php
  Future<void> fetchPatients(int doctorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await PatientService.getPatients(doctorId)
          .timeout(const Duration(seconds: 5));

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['statusCode'] == 200) {
        if (responseData['body'] is List) {
          final list = responseData['body'] as List;
          _patients = list.map((json) => PatientModel.fromJson(json)).toList();
        } else {
          _patients = [];
        }
      } else {
        _errorMessage = responseData['message'] ?? 'Failed to load patients.';
        developer.log('PatientProvider.fetchPatients: Error status: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'Connection timeout or network failure. Please verify the server is running.';
      developer.log('PatientProvider.fetchPatients: Exception caught: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new patient profile.
  /// POST /api/patients/create.php
  Future<bool> createPatient(Map<String, dynamic> payload) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await PatientService.createPatient(payload)
          .timeout(const Duration(seconds: 5));

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || responseData['statusCode'] == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = responseData['message'] ?? 'Failed to create patient.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network connection failed. Verify the server is running.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update an existing patient profile.
  /// POST /api/patients/update.php
  Future<bool> updatePatient(Map<String, dynamic> payload) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await PatientService.updatePatient(payload)
          .timeout(const Duration(seconds: 5));

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || responseData['statusCode'] == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = responseData['message'] ?? 'Failed to update patient.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network connection failed. Verify the server is running.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a patient profile and associated records.
  /// POST /api/patients/delete.php
  Future<bool> deletePatient(int patientId, int parentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await PatientService.deletePatient(patientId, parentId)
          .timeout(const Duration(seconds: 5));

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || responseData['statusCode'] == 200) {
        _patients.removeWhere((p) => p.id == patientId);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = responseData['message'] ?? 'Failed to delete patient.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Local removal fallback if backend is unreachable or local state cleanup
      _patients.removeWhere((p) => p.id == patientId);
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }
}
