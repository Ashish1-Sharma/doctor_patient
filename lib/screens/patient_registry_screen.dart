import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/patient_model.dart';
import '../providers/patient_provider.dart';
import '../theme/app_theme.dart';
import 'add_patient_screen.dart';
import 'patient_details_screen.dart';

/// PatientRegistryScreen displays search and contact information for the clinic's patients.
class PatientRegistryScreen extends StatefulWidget {
  final List<PatientModel> patients;

  const PatientRegistryScreen({super.key, required this.patients});

  @override
  State<PatientRegistryScreen> createState() => _PatientRegistryScreenState();
}

class _PatientRegistryScreenState extends State<PatientRegistryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _doctorId = 1;
  int _parentId = 1;
  bool _isSubUser = false;

  @override
  void initState() {
    super.initState();
    _loadDoctorIdAndFetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorIdAndFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileStr = prefs.getString('user_profile');
      if (profileStr != null) {
        final profile = jsonDecode(profileStr);
        final rawId = profile['id'];
        final doctorId = rawId is int ? rawId : (rawId != null ? int.tryParse(rawId.toString()) : 1);
        final isSubUser = profile['isSubUser'] == true;
        
        final rawParentId = isSubUser 
            ? (profile['parentId'] ?? profile['mainAccountId'] ?? doctorId)
            : doctorId;
        final parentId = rawParentId is int ? rawParentId : (rawParentId != null ? int.tryParse(rawParentId.toString()) : 1);

        setState(() {
          _doctorId = doctorId ?? 1;
          _parentId = parentId ?? 1;
          _isSubUser = isSubUser;
        });
      }
    } catch (_) {}

    // Fetch once when screen opens
    if (mounted) {
      Provider.of<PatientProvider>(context, listen: false).fetchPatients(_doctorId);
    }
  }

  Future<void> _confirmAndDeletePatient(PatientModel patient) async {
    if (_isSubUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only Admin has permission to delete patients.'),
          backgroundColor: AppTheme.redDestructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Patient Record?'),
        content: Text('Are you sure you want to delete ${patient.fullName} (${patient.patientCode}) and all associated records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.redDestructive, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = Provider.of<PatientProvider>(context, listen: false);
      final success = await provider.deletePatient(patient.id, _parentId);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patient ${patient.fullName} deleted successfully.'),
            backgroundColor: AppTheme.emeraldSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to delete patient.'),
            backgroundColor: AppTheme.redDestructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, PatientModel patient) async {
    final phone = patient.phone.replaceAll(RegExp(r'\D'), '');
    final urlStr = 'https://wa.me/$phone';
    final uri = Uri.parse(urlStr);
    
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open WhatsApp: $e'),
            backgroundColor: AppTheme.redDestructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _launchCall(BuildContext context, PatientModel patient) async {
    final phone = patient.phone.replaceAll(RegExp(r'\D'), '');
    final urlStr = 'tel:$phone';
    final uri = Uri.parse(urlStr);
    
    try {
      await launchUrl(uri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to make call: $e'),
            backgroundColor: AppTheme.redDestructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddPatient() async {
    final dynamic didCreate = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddPatientScreen(),
      ),
    );

    if (didCreate == true && mounted) {
      Provider.of<PatientProvider>(context, listen: false).fetchPatients(_doctorId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final provider = Provider.of<PatientProvider>(context);

    // Perform local searching & filtering in Flutter using the fetched patient list
    final filteredPatients = provider.patients.where((patient) {
      final query = _searchQuery.toLowerCase();
      final nameMatches = patient.fullName.toLowerCase().contains(query);
      final phoneMatches = patient.phone.contains(query);
      final codeMatches = patient.patientCode.toLowerCase().contains(query);
      final conditionMatches = patient.medicalConditions.any(
        (c) => c.toLowerCase().contains(query),
      );
      return nameMatches || phoneMatches || codeMatches || conditionMatches;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Patient Registry',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primarySlate),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by Name, Code, Phone, or Conditions...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.secondarySlate),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.secondarySlate),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            
            // Error Display if API fails
            if (provider.errorMessage != null && provider.patients.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: AppTheme.redDestructive.withValues(alpha: 0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.redDestructive),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            provider.errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.redDestructive,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Patient List with Loader / Refresh Indicator
            Expanded(
              child: provider.isLoading && provider.patients.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.tealAccent),
                    )
                  : RefreshIndicator(
                      color: AppTheme.tealAccent,
                      onRefresh: () => provider.fetchPatients(_doctorId),
                      child: filteredPatients.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_search_outlined,
                                        size: 64,
                                        color: AppTheme.secondarySlate.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'No patients found matching "$_searchQuery"'
                                            : 'No patients registered yet',
                                        style: textTheme.bodyLarge?.copyWith(
                                          color: AppTheme.secondarySlate.withValues(alpha: 0.6),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: filteredPatients.length,
                              itemBuilder: (context, index) {
                                final patient = filteredPatients[index];
                                return InkWell(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PatientDetailsScreen(patient: patient),
                                      ),
                                    );
                                    if (result == true && mounted) {
                                      provider.fetchPatients(_doctorId);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                                    ),
                                    color: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              // Profile Avatar
                                              CircleAvatar(
                                                radius: 26,
                                                backgroundColor: AppTheme.tealAccent.withValues(alpha: 0.1),
                                                child: Text(
                                                  patient.fullName.isNotEmpty
                                                      ? patient.fullName.substring(0, 1).toUpperCase()
                                                      : 'P',
                                                  style: const TextStyle(
                                                    color: AppTheme.tealAccent,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              // Name and Code
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            patient.fullName,
                                                            style: textTheme.titleMedium?.copyWith(
                                                              fontWeight: FontWeight.bold,
                                                              color: AppTheme.primarySlate,
                                                            ),
                                                          ),
                                                        ),
                                                        // Status Badge
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: (patient.status)
                                                                ? AppTheme.emeraldSuccess.withValues(alpha: 0.12)
                                                                : AppTheme.secondarySlate.withValues(alpha: 0.12),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Text(
                                                            patient.status ? 'Active' : 'Inactive',
                                                            style: TextStyle(
                                                              color: (patient.status) ? AppTheme.emeraldSuccess : AppTheme.secondarySlate,
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFF1F5F9),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            patient.patientCode,
                                                            style: textTheme.bodySmall?.copyWith(
                                                              fontFamily: 'monospace',
                                                              fontWeight: FontWeight.bold,
                                                              color: AppTheme.primarySlate,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          '${patient.age} yrs • ${patient.gender}',
                                                          style: textTheme.bodyMedium?.copyWith(
                                                            color: AppTheme.secondarySlate,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          const Divider(color: Color(0xFFF1F5F9), height: 1),
                                          const SizedBox(height: 12),
                                          // Details Rows
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.phone_outlined, size: 16, color: AppTheme.secondarySlate),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    patient.phone,
                                                    style: textTheme.bodyMedium?.copyWith(color: AppTheme.primarySlate),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.secondarySlate),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    patient.lastVisitDate.isNotEmpty ? 'Last: ${patient.lastVisitDate}' : 'No visits yet',
                                                    style: textTheme.bodyMedium?.copyWith(color: AppTheme.primarySlate),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.event_available_outlined, size: 16, color: AppTheme.secondarySlate),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        'Total Visits: ${patient.totalVisits}',
                                                        style: textTheme.bodyMedium?.copyWith(color: AppTheme.primarySlate),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // WhatsApp, Call, and Admin Delete Quick Action Icons
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.whatsappGreen, size: 18),
                                                    onPressed: () => _launchWhatsApp(context, patient),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  IconButton(
                                                    icon: const Icon(Icons.phone_outlined, color: Colors.blue, size: 18),
                                                    onPressed: () => _launchCall(context, patient),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                  if (!_isSubUser) ...[
                                                    const SizedBox(width: 12),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_outline, color: AppTheme.redDestructive, size: 18),
                                                      onPressed: () => _confirmAndDeletePatient(patient),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                          // Medical Conditions
                                          if (patient.medicalConditions.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 6,
                                              children: patient.medicalConditions.map((condition) {
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.tealAccent.withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: AppTheme.tealAccent.withValues(alpha: 0.2), width: 0.5),
                                                  ),
                                                  child: Text(
                                                    condition,
                                                    style: textTheme.bodySmall?.copyWith(
                                                      color: AppTheme.tealAccent,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPatient,
        backgroundColor: AppTheme.tealAccent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white),
      ),
    );
  }
}
