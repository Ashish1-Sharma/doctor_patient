import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'company_details_screen.dart';

/// Screen displaying Doctor's profile and providing option to log out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileStr = prefs.getString('user_profile');
      if (profileStr != null) {
        setState(() {
          _profileData = jsonDecode(profileStr);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
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

  void _openEditProfileDialog() {
    if (_profileData == null) return;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: _profileData!['userName'] ?? '');
    final emailController = TextEditingController(text: _profileData!['userEmail'] ?? '');
    final mobileController = TextEditingController(text: _profileData!['userMobile'] ?? '');
    final countryController = TextEditingController(text: _profileData!['country'] ?? 'India');
    final passwordController = TextEditingController(text: _profileData!['password'] ?? '');
    bool isSaving = false;
    bool isPasswordObscure = true;
    String? errorMessage;

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
                        'Edit Profile Details',
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
                  const Text('Name', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter name',
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.secondarySlate),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: 'Enter email address',
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.secondarySlate),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter email';
                      final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!regex.hasMatch(val.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Mobile Field
                  const Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: mobileController,
                    decoration: const InputDecoration(
                      hintText: 'Enter mobile number',
                      prefixIcon: Icon(Icons.phone_android_outlined, color: AppTheme.secondarySlate),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter mobile number' : null,
                  ),
                  const SizedBox(height: 16),

                  // Country Field
                  const Text('Country', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: countryController,
                    decoration: const InputDecoration(
                      hintText: 'Enter country',
                      prefixIcon: Icon(Icons.public_outlined, color: AppTheme.secondarySlate),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter country' : null,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  const Text('Password', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.secondarySlate),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppTheme.secondarySlate,
                        ),
                        onPressed: () {
                          setModalState(() {
                            isPasswordObscure = !isPasswordObscure;
                          });
                        },
                      ),
                    ),
                    obscureText: isPasswordObscure,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Enter password';
                      }
                      if (val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Inline Error Alert Box (renders inside the bottom sheet context)
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.redDestructive.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.redDestructive.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.redDestructive, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: AppTheme.redDestructive,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submit Button
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            
                            setModalState(() {
                              isSaving = true;
                              errorMessage = null; // Clear previous errors on retry
                            });

                            final Map<String, dynamic> payload = {
                              "id": _profileData!['id'],
                              "name": nameController.text.trim(),
                              "email": emailController.text.trim(),
                              "mobile": mobileController.text.trim(),
                              "country": countryController.text.trim(),
                              "password": passwordController.text.trim(),
                            };

                            try {
                              final response = await AuthService.updateUser(payload)
                                  .timeout(const Duration(seconds: 5));
                              
                              final responseData = jsonDecode(response.body);
                              
                              if (response.statusCode == 200 && responseData['statusCode'] == 200) {
                                final updatedBody = responseData['body'];
                                if (updatedBody != null) {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('user_profile', jsonEncode(updatedBody));
                                }

                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  _showNotification(
                                    'Profile updated successfully!',
                                    AppTheme.emeraldSuccess,
                                    Icons.check_circle_outline,
                                  );
                                  _loadProfile();
                                }
                              } else {
                                setModalState(() {
                                  isSaving = false;
                                  errorMessage = responseData['message'] ?? 'Failed to update profile.';
                                });
                              }
                            } catch (_) {
                              setModalState(() {
                                isSaving = false;
                                errorMessage = 'Network connection failed.';
                              });
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
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('user_profile');

    if (!mounted) return;
    
    // Clear navigation stack and route to Login Screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.secondarySlate)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.redDestructive,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isAdmin = _profileData != null && _profileData!['isSubUser'] != true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.primarySlate,
        actions: isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Profile',
                  onPressed: _openEditProfileDialog,
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent))
          : _profileData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.amberWarning),
                      const SizedBox(height: 16),
                      const Text('Failed to load profile details'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _logout,
                        child: const Text('Go back to Login'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundImage: AssetImage(
                                  'assets/doctor.jpeg',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _profileData!['userName'] ?? 'Dr. Gireesh Kumar',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primarySlate,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                               Text(
                                _profileData!['userEmail'] ?? 'doctor@gmail.com',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.secondarySlate,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _profileData!['isSubUser'] == true
                                      ? AppTheme.tealAccent.withValues(alpha: 0.12)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _profileData!['isSubUser'] == true
                                      ? 'Doctor / Staff'
                                      : 'Clinic Owner',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: _profileData!['isSubUser'] == true
                                        ? AppTheme.tealAccent
                                        : AppTheme.secondarySlate,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Profile Details Card
                      Text('Account Info', style: textTheme.labelLarge),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                icon: Icons.phone_android_outlined,
                                label: 'Mobile Number',
                                value: _profileData!['userMobile'] ?? 'N/A',
                              ),
                              const Divider(height: 24, color: Color(0xFFF1F5F9)),
                              _buildInfoRow(
                                icon: Icons.public_outlined,
                                label: 'Country',
                                value: _profileData!['country'] ?? 'N/A',
                              ),
                              if (_profileData!['isSubUser'] != true) ...[
                                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                                _buildInfoRow(
                                  icon: Icons.badge_outlined,
                                  label: 'Purchase ID',
                                  value: _profileData!['purchase_id'] ?? 'N/A',
                                ),
                                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                                _buildInfoRow(
                                  icon: Icons.verified_user_outlined,
                                  label: 'License Validity',
                                  value: _profileData!['validity'] ?? 'N/A',
                                ),
                              ] else ...[
                                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                                _buildInfoRow(
                                  icon: Icons.business_outlined,
                                  label: 'Clinic Account ID',
                                  value: (_profileData!['parentId'] ?? _profileData!['mainAccountId'] ?? 'N/A').toString(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (_profileData!['isSubUser'] != true) ...[
                        const SizedBox(height: 24),
                        Text('Clinic Management', style: textTheme.labelLarge),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CompanyDetailsScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.business_outlined, color: AppTheme.tealAccent, size: 24),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Clinic Branding & Settings',
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primarySlate,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Configure clinic details, registration, and terms.',
                                          style: TextStyle(color: AppTheme.secondarySlate, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.secondarySlate, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Logout Button
                      ElevatedButton.icon(
                        onPressed: _showLogoutConfirmation,
                        icon: const Icon(Icons.logout_outlined, size: 20),
                        label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.redDestructive,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppTheme.redDestructive, width: 1.5),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.secondarySlate, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.secondarySlate,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.primarySlate,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
