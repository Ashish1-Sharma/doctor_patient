import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

/// Screen containing inputs to register a Doctor user.
/// Sends payload to POST /api/auth/register.php.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedCountry = 'India';
  String _countryCode = '+91';
  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  void _showSuccessDialog(String title, Map<String, dynamic> userBody) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            children: [
              const Icon(Icons.check_circle_outline, color: AppTheme.emeraldSuccess, size: 64),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Your doctor profile and subscription license are active!',
                style: TextStyle(color: AppTheme.secondarySlate, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildDetailRow('License Holder', userBody['userName'] ?? ''),
              _buildDetailRow('Mobile Number', userBody['userMobile'] ?? ''),
              // _buildDetailRow('Purchase ID', userBody['purchase_id'] ?? ''),
              // _buildDetailRow('License Validity', userBody['validity'] ?? ''),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Navigate to Dashboard and clear stack
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Enter Clinic Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.secondarySlate, fontSize: 12)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primarySlate, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final now = DateTime.now();
    final oneYearLater = DateTime(now.year + 1, now.month, now.day);
    
    final regDateStr = now.toString().substring(0, 19);
    final validityStr = oneYearLater.toString().substring(0, 10);
    final purchaseDateStr = now.toString().substring(0, 10);
    
    final purchaseId = "PUR${now.millisecondsSinceEpoch ~/ 1000}";

    // Payload exactly matching request specifications
    final Map<String, dynamic> requestPayload = {
      "userName": _nameController.text.trim(),
      "userEmail": _emailController.text.trim(),
      "country": _selectedCountry,
      "countryCode": _countryCode,
      "userMobile": _mobileController.text.trim(),
      "password": _passwordController.text.trim(),
      "reg_date": regDateStr,
      "validity": validityStr,
      "purchase_date": purchaseDateStr,
      "purchase_id": purchaseId,
      "flag": "0"
    };

    try {
      final response = await AuthService.registerDoctor(requestPayload)
          .timeout(const Duration(seconds: 5));

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 201 || responseData['statusCode'] == 201) {
        // Save registration status to persist user session logically
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_registered', true);
        await prefs.setBool('is_logged_in', true);
        
        final responseBody = responseData['body'] ?? requestPayload;
        await prefs.setString('user_profile', jsonEncode(responseBody));
        
        final String msg = responseData['message'] ?? 'User registered successfully';

        if (!mounted) return;
        _showNotification(msg, AppTheme.emeraldSuccess, Icons.check_circle_outline);
        _showSuccessDialog(msg, responseBody);
      } else if (response.statusCode == 400 || responseData['statusCode'] == 400) {
        _showNotification(responseData['message'] ?? 'User already exists.', AppTheme.amberWarning, Icons.warning_amber_rounded);
      } else {
        _showNotification(responseData['message'] ?? 'Error in user registration.', AppTheme.redDestructive, Icons.error_outline);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      _showNotification('Network connection failed. Please verify the API server is reachable.', AppTheme.redDestructive, Icons.cloud_off_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // Clinic Logo/Graphic Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.tealAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_hospital_outlined,
                          color: AppTheme.tealAccent,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Create Account',
                      style: textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primarySlate,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Register your clinic profile to get started',
                      style: TextStyle(color: AppTheme.secondarySlate, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Name Input
                    Text('Doctor Name', style: textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Dr. Gireesh Kumar',
                        prefixIcon: Icon(Icons.person_outline, color: AppTheme.secondarySlate),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Enter doctor name' : null,
                    ),
                    const SizedBox(height: 16),

                    // Email Input
                    Text('Email Address', style: textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'e.g. doctor@gmail.com',
                        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.secondarySlate),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Country Dropdown
                    Text('Country', style: textTheme.labelLarge),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.public, color: AppTheme.secondarySlate),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'India', child: Text('India (+91)')),
                        DropdownMenuItem(value: 'United Kingdom', child: Text('United Kingdom (+44)')),
                        DropdownMenuItem(value: 'United States', child: Text('United States (+1)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCountry = val;
                            if (val == 'India') {
                              _countryCode = '+91';
                            } else if (val == 'United Kingdom') {
                              _countryCode = '+44';
                            } else {
                              _countryCode = '+1';
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Mobile Input
                    Text('Mobile Number', style: textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '9876543210',
                        prefixIcon: Center(
                          widthFactor: 1.0,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                            child: Text(
                              '$_countryCode ',
                              style: const TextStyle(
                                color: AppTheme.secondarySlate,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter mobile number';
                        if (val.trim().length < 8) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Input
                    Text('Password', style: textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        hintText: '••••••',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.secondarySlate),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppTheme.secondarySlate,
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                          },
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Enter password';
                        if (val.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 36),

                    // Register Button
                    ElevatedButton(
                      onPressed: _submitRegistration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tealAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Register Account',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Already have an account Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(color: AppTheme.secondarySlate, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              color: AppTheme.tealAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Circular Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              alignment: Alignment.center,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.tealAccent),
                      SizedBox(height: 16),
                      Text('Registering Profile...', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
