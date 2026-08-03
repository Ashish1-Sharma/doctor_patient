import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.primarySlate,
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
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.tealAccent.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.medical_services_outlined,
                                  color: AppTheme.tealAccent,
                                  size: 48,
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
