import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ManageDoctorsScreen extends StatefulWidget {
  const ManageDoctorsScreen({super.key});

  @override
  State<ManageDoctorsScreen> createState() => _ManageDoctorsScreenState();
}

class _ManageDoctorsScreenState extends State<ManageDoctorsScreen> {
  List<dynamic> _doctors = [];
  bool _isLoading = true;
  int _parentId = 0;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadParentIdAndFetch();
  }

  Future<void> _loadParentIdAndFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileStr = prefs.getString('user_profile');
      if (profileStr != null) {
        final profile = jsonDecode(profileStr);
        final rawId = profile['id'];
        final parentId = rawId is int ? rawId : (rawId != null ? int.tryParse(rawId.toString()) : null);
        if (parentId != null) {
          setState(() {
            _parentId = parentId;
          });
          await _fetchDoctors();
          return;
        }
      }
    } catch (_) {}
    setState(() {
      _isLoading = false;
      _errorMessage = 'Failed to load session profile.';
    });
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await AuthService.getSubUsers(_parentId)
          .timeout(const Duration(seconds: 5));
      
      final responseData = jsonDecode(response.body);
      final statusCode = response.statusCode;
      final apiStatusCode = responseData['statusCode'] as int?;

      if (statusCode == 200 || apiStatusCode == 200) {
        final body = responseData['body'];
        if (body is List) {
          setState(() {
            _doctors = body;
            _isLoading = false;
          });
        } else {
          setState(() {
            _doctors = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _doctors = [];
          _isLoading = false;
          _errorMessage = responseData['message'] ?? 'Failed to load doctors list.';
        });
      }
    } catch (e) {
      setState(() {
        _doctors = [];
        _isLoading = false;
        _errorMessage = 'Network connection failed. Verify the server is running.';
      });
    }
  }

  void _showNotification(String message, Color bgColor, IconData icon) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openAddDoctorDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final mobileController = TextEditingController();
    final passwordController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Doctor / Staff',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primarySlate,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  
                  // Name Field
                  const Text('Doctor Name', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: 'e.g. Dr. Ramesh Kumar'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  const Text('Doctor Email', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(hintText: 'e.g. doctor@gmail.com'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter email' : null,
                  ),
                  const SizedBox(height: 16),

                  // Mobile Field
                  const Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: mobileController,
                    decoration: const InputDecoration(hintText: 'e.g. 9876543210'),
                    keyboardType: TextInputType.phone,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter mobile number' : null,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  const Text('Password', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(hintText: 'Minimum 6 characters'),
                    obscureText: true,
                    validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            
                            setModalState(() {
                              isSaving = true;
                            });

                            final now = DateTime.now();
                            final oneYearLater = DateTime(now.year + 1, now.month, now.day);
                            final regDateStr = now.toString().substring(0, 19);
                            final validityStr = oneYearLater.toString().substring(0, 10);
                            final purchaseDateStr = now.toString().substring(0, 10);
                            final purchaseId = "PUR${now.millisecondsSinceEpoch ~/ 1000}";

                            final Map<String, dynamic> payload = {
                              "parentId": _parentId,
                              "userName": nameController.text.trim(),
                              "userEmail": emailController.text.trim(),
                              "country": "India",
                              "countryCode": "+91",
                              "userMobile": mobileController.text.trim(),
                              "password": passwordController.text.trim(),
                              "reg_date": regDateStr,
                              "validity": validityStr,
                              "purchase_date": purchaseDateStr,
                              "purchase_id": purchaseId,
                              "flag": 0
                            };

                            try {
                              final response = await AuthService.registerSubDoctor(payload)
                                  .timeout(const Duration(seconds: 5));
                              
                              final responseData = jsonDecode(response.body);
                              
                              if (response.statusCode == 201 || responseData['statusCode'] == 201) {
                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  _showNotification('Doctor created successfully!', AppTheme.emeraldSuccess, Icons.check_circle_outline);
                                  _fetchDoctors();
                                }
                              } else {
                                setModalState(() {
                                  isSaving = false;
                                });
                                _showNotification(responseData['message'] ?? 'Failed to create doctor.', AppTheme.redDestructive, Icons.error_outline);
                              }
                            } catch (_) {
                              setModalState(() {
                                isSaving = false;
                              });
                              _showNotification('Network connection failed.', AppTheme.redDestructive, Icons.cloud_off_rounded);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tealAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Create Doctor Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Manage Doctors & Staff',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primarySlate),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDoctorDialog,
        backgroundColor: AppTheme.tealAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent))
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppTheme.redDestructive),
                          const SizedBox(height: 16),
                          Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.secondarySlate)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _fetchDoctors,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _doctors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.medical_services_outlined, size: 64, color: AppTheme.secondarySlate.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            const Text(
                              'No doctor/staff accounts found',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondarySlate, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add sub-users to enable collective records management.',
                              style: TextStyle(color: AppTheme.secondarySlate, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _doctors.length,
                        itemBuilder: (context, index) {
                          final doc = _doctors[index];
                          final docId = doc['id']?.toString() ?? '';
                          final docName = doc['userName'] ?? doc['name'] ?? 'Doctor';
                          final docEmail = doc['userEmail'] ?? 'N/A';
                          final docMobile = doc['userMobile'] ?? 'N/A';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: AppTheme.premiumShadow,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppTheme.tealAccent.withValues(alpha: 0.12),
                                    child: const Icon(Icons.person, color: AppTheme.tealAccent, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          docName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppTheme.primarySlate,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Email: $docEmail',
                                          style: const TextStyle(color: AppTheme.secondarySlate, fontSize: 12),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Mobile: $docMobile',
                                          style: const TextStyle(color: AppTheme.secondarySlate, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'ID: $docId',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondarySlate),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
