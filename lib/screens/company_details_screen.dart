import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

/// Screen to manage Clinic/Company settings (GST, terms, address, logo, name).
class CompanyDetailsScreen extends StatefulWidget {
  const CompanyDetailsScreen({super.key});

  @override
  State<CompanyDetailsScreen> createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  final _dlController = TextEditingController();
  final _termsController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  int _doctorId = 1;
  int? _existingCompanyId;

  @override
  void initState() {
    super.initState();
    _loadClinicDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    _dlController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _loadClinicDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileStr = prefs.getString('user_profile');
      if (profileStr != null) {
        final profile = jsonDecode(profileStr);
        final rawId = profile['id'];
        _doctorId = rawId is int ? rawId : (rawId != null ? (int.tryParse(rawId.toString()) ?? 1) : 1);
      }
      await _fetchFromBackend();
    } catch (_) {}

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchFromBackend() async {
    try {
      final response = await http.post(
        Uri.parse('https://tworingz.com/doctor_patient/api/company/getCompanyDetails.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': _doctorId}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['statusCode'] == 200 && responseData['body'] is List) {
          final list = responseData['body'] as List;
          if (list.isNotEmpty) {
            final companyData = list.first; // Load the first clinic profile
            setState(() {
              _existingCompanyId = companyData['id'] is int ? companyData['id'] : int.tryParse(companyData['id'].toString());
              _nameController.text = companyData['companyName'] ?? '';
              _addressController.text = companyData['companyAddress'] ?? '';
              _gstController.text = companyData['gst'] ?? '';
              _dlController.text = companyData['dlNo'] ?? '';
              _termsController.text = companyData['terms'] ?? '';
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final payload = {
      if (_existingCompanyId != null) 'id': _existingCompanyId,
      'userId': _doctorId,
      'companyName': _nameController.text.trim(),
      'companyAddress': _addressController.text.trim(),
      'gst': _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
      'dlNo': _dlController.text.trim().isEmpty ? null : _dlController.text.trim(),
      'terms': _termsController.text.trim().isEmpty ? null : _termsController.text.trim(),
    };

    // Save to backend database
    bool success = false;
    try {
      final response = await http.post(
        Uri.parse('https://tworingz.com/doctor_patient/api/company/create.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 201) {
        success = true;
        final responseData = jsonDecode(response.body);
        if (responseData['body'] != null && responseData['body']['id'] != null) {
          _existingCompanyId = responseData['body']['id'] as int?;
        }
      }
    } catch (_) {}

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Clinic branding details saved and synchronized.'
              : 'Failed to save branding details. Check network connection.'),
          backgroundColor: success ? AppTheme.emeraldSuccess : AppTheme.redDestructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Clinic Branding Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.primarySlate,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Clinic Details & Receipts branding',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primarySlate),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Set clinic details to personalize printed invoices and receipts.',
                      style: TextStyle(color: AppTheme.secondarySlate, fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Clinic / Company Name *',
                                hintText: 'Enter clinic name',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Clinic name is required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _addressController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Clinic Address *',
                                hintText: 'Enter complete address',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Clinic address is required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _gstController,
                              decoration: const InputDecoration(
                                labelText: 'GSTIN Number (Optional)',
                                hintText: 'e.g. 22AAAAA0000A1Z5',
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _dlController,
                              decoration: const InputDecoration(
                                labelText: 'Drug License (DL) Number (Optional)',
                                hintText: 'e.g. DL-12345/A',
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _termsController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Receipt Terms & Conditions (Optional)',
                                hintText: 'Terms printed at the bottom of the invoice',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveDetails,
                      icon: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_outlined),
                      label: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tealAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
