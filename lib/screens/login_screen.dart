import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'registration_screen.dart';

/// Screen containing inputs to authenticate/login a Doctor user.
/// Sends payload to POST /api/auth/login.php.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _emailMobileController = TextEditingController();
  final _clinicEmailController = TextEditingController();
  final _doctorEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoginAsSubUser = false; // false = Clinic Owner, true = Doctor / Staff
  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailMobileController.dispose();
    _clinicEmailController.dispose();
    _doctorEmailController.dispose();
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

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final http.Response response;
      if (_isLoginAsSubUser) {
        final Map<String, dynamic> requestPayload = {
          "parentEmail": _clinicEmailController.text.trim(),
          "childEmail": _doctorEmailController.text.trim(),
          "inputPassword": _passwordController.text.trim(),
        };
        response = await AuthService.loginSubUser(requestPayload)
            .timeout(const Duration(seconds: 5));
      } else {
        final Map<String, dynamic> requestPayload = {
          "userEmailMobile": _emailMobileController.text.trim(),
          "password": _passwordController.text.trim(),
        };
        response = await AuthService.loginDoctor(requestPayload).timeout(const Duration(seconds: 5));
      }

      print(jsonDecode(response.body));
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      setState(() {
        _isLoading = false;
      });

      final statusCode = response.statusCode;
      final apiStatusCode = responseData['statusCode'] as int?;

      if (statusCode == 200 && apiStatusCode == 200) {
        // Save logged in status to persist session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        
        final profileBody = responseData['body'];
        if (profileBody != null) {
          // If Doctor/Staff login succeeded, we should inject isSubUser: true if not present
          if (_isLoginAsSubUser && profileBody is Map) {
            profileBody['isSubUser'] = true;
          }
          await prefs.setString('user_profile', jsonEncode(profileBody));
        }

        final successMsg = responseData['message'] ?? 'Login successful';
        if (!mounted) return;
        _showNotification(successMsg, AppTheme.emeraldSuccess, Icons.check_circle_outline);
        
        // Route to dashboard and clear login screen from stack
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else if (statusCode == 401 || apiStatusCode == 401) {
        _showNotification(responseData['message'] ?? 'Invalid email/mobile or password.', AppTheme.amberWarning, Icons.warning_amber_rounded);
      } else if (statusCode == 400 || apiStatusCode == 400) {
        _showNotification(responseData['message'] ?? 'Invalid request.', AppTheme.amberWarning, Icons.error_outline);
      } else {
        _showNotification(responseData['message'] ?? 'Error during login.', AppTheme.redDestructive, Icons.error_outline);
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
                    const SizedBox(height: 40),
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
                      'Welcome Back',
                      style: textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primarySlate,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Log in to access your clinic dashboard',
                      style: TextStyle(color: AppTheme.secondarySlate, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Modern Role Segment Selection
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isLoginAsSubUser = false;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isLoginAsSubUser ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: !_isLoginAsSubUser
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  'Clinic Owner',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: !_isLoginAsSubUser ? AppTheme.tealAccent : AppTheme.secondarySlate,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isLoginAsSubUser = true;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isLoginAsSubUser ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _isLoginAsSubUser
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  'Doctor / Staff',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: _isLoginAsSubUser ? AppTheme.tealAccent : AppTheme.secondarySlate,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Dynamic form fields
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: _isLoginAsSubUser
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              key: const ValueKey('subUserFields'),
                              children: [
                                Text('Clinic Email', style: textTheme.labelLarge),
                                const SizedBox(height: 8),
                                TextFormField(
                                  key: const ValueKey('parentEmailField'),
                                  controller: _clinicEmailController,
                                  decoration: const InputDecoration(
                                    hintText: 'clinic@gmail.com',
                                    prefixIcon: Icon(Icons.business_outlined, color: AppTheme.secondarySlate),
                                  ),
                                  validator: (val) =>
                                      val == null || val.trim().isEmpty ? 'Enter clinic email' : null,
                                ),
                                const SizedBox(height: 16),
                                Text('Doctor Email', style: textTheme.labelLarge),
                                const SizedBox(height: 8),
                                TextFormField(
                                  key: const ValueKey('childEmailField'),
                                  controller: _doctorEmailController,
                                  decoration: const InputDecoration(
                                    hintText: 'doctor@gmail.com',
                                    prefixIcon: Icon(Icons.medical_services_outlined, color: AppTheme.secondarySlate),
                                  ),
                                  validator: (val) =>
                                      val == null || val.trim().isEmpty ? 'Enter doctor email' : null,
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              key: const ValueKey('ownerFields'),
                              children: [
                                Text('Email or Mobile Number', style: textTheme.labelLarge),
                                const SizedBox(height: 8),
                                TextFormField(
                                  key: const ValueKey('ownerEmailField'),
                                  controller: _emailMobileController,
                                  decoration: const InputDecoration(
                                    hintText: 'clinic@gmail.com or 9876543210',
                                    prefixIcon: Icon(Icons.person_outline, color: AppTheme.secondarySlate),
                                  ),
                                  validator: (val) =>
                                      val == null || val.trim().isEmpty ? 'Enter email or mobile' : null,
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Password Input (Shared)
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
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter password' : null,
                    ),
                    const SizedBox(height: 36),

                    // Login Button
                    ElevatedButton(
                      onPressed: _submitLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tealAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Log In',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Register Account Shortcut Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: AppTheme.secondarySlate, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                            );
                          },
                          child: const Text(
                            'Register',
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
                      Text('Logging In...', style: TextStyle(fontWeight: FontWeight.bold)),
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
