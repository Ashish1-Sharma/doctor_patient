import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/patient_model.dart';
import '../../providers/visit_provider.dart';
import '../../services/patient_service.dart';
import '../../services/visit_service.dart';
import '../../theme/app_theme.dart';
import '../add_patient_screen.dart';
import '../new_treatment_screen.dart';

/// STEP 1: Select Patient step inside the New Treatment workflow.
class PatientSelectionStep extends StatefulWidget {
  const PatientSelectionStep({super.key});

  @override
  State<PatientSelectionStep> createState() => _PatientSelectionStepState();
}

class _PatientSelectionStepState extends State<PatientSelectionStep> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<PatientModel> _patients = [];
  bool _isLoading = true;
  int _doctorId = 1;
  int _parentId = 1;

  @override
  void initState() {
    super.initState();
    _loadDoctorAndPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorAndPatients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileStr = prefs.getString('user_profile');
      if (profileStr != null) {
        final profile = jsonDecode(profileStr);
        final rawId = profile['id'];
        _doctorId = rawId is int ? rawId : (rawId != null ? (int.tryParse(rawId.toString()) ?? 1) : 1);
        final isSubUser = profile['isSubUser'] == true;
        _parentId = isSubUser
            ? (profile['parentId'] ?? profile['mainAccountId'] ?? _doctorId)
            : _doctorId;
      }
    } catch (_) {}

    await _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      final response = await PatientService.getPatients(_parentId)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['statusCode'] == 200 && responseData['body'] is List) {
          final list = responseData['body'] as List;
          final fetched = list.map((json) => PatientModel.fromJson(json)).toList();
          setState(() {
            _patients = fetched;
          });
        }
      }
    } catch (_) {}

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createNewPatient(BuildContext context) async {
    final dynamic didCreate = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddPatientScreen(),
      ),
    );

    if (didCreate == true) {
      setState(() {
        _isLoading = true;
      });
      await _fetchPatients();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VisitProvider>(context);
    final selectedPatientId = provider.visit.patientId;
    final textTheme = Theme.of(context).textTheme;
    final editMode = context.findAncestorWidgetOfExactType<NewTreatmentScreen>()?.visitToEdit != null;

    // Filter patients based on query matching Name, Mobile, or Code
    final filtered = _patients.where((p) {
      final query = _searchQuery.toLowerCase();
      final nameMatches = p.fullName.toLowerCase().contains(query);
      final phoneMatches = p.phone.contains(query);
      final codeMatches = p.patientCode.toLowerCase().contains(query);
      return nameMatches || phoneMatches || codeMatches;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select Patient',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primarySlate,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          editMode
              ? 'Patient details are locked for editing this visit record.'
              : 'Search for an existing patient or add a new profile to continue.',
          style: const TextStyle(color: AppTheme.secondarySlate, fontSize: 13),
        ),
        const SizedBox(height: 20),

        if (editMode)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.amberWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.amberWarning.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: AppTheme.amberWarning, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Editing Visit #${provider.visit.visitNo} - Selected patient is locked.',
                    style: const TextStyle(
                      color: AppTheme.amberWarning,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Search Bar Row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search Name, Mobile, or Patient Code...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.secondarySlate),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.secondarySlate),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
            if (!editMode) ...[
              const SizedBox(width: 12),
              // Quick Add Button
              InkWell(
                onTap: () => _createNewPatient(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.tealAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_add_alt_1_outlined, color: AppTheme.tealAccent, size: 22),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 24),

        // Patient Selection list
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.tealAccent),
                )
              : filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search_rounded, size: 48, color: AppTheme.secondarySlate.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      const Text(
                        'No patients found',
                        style: TextStyle(color: AppTheme.secondarySlate, fontWeight: FontWeight.bold),
                      ),
                      if (!editMode) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _createNewPatient(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.tealAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Patient'),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final patient = filtered[index];
                    final isSelected = selectedPatientId == patient.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.tealAccent : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: AppTheme.tealAccent.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1)]
                            : AppTheme.premiumShadow,
                      ),
                      child: InkWell(
                        onTap: () async {
                          if (editMode) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Patient cannot be changed when editing a visit.'),
                                backgroundColor: AppTheme.amberWarning,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          // Dynamically fetch total visits count from database
                          int databaseVisitCount = 0;
                          try {
                            final response = await VisitService.getVisits(_parentId, patient.id).timeout(const Duration(seconds: 4));
                            if (response.statusCode == 200) {
                              final Map<String, dynamic> responseData = jsonDecode(response.body);
                              if (responseData['statusCode'] == 200 && responseData['body'] is List) {
                                final list = responseData['body'] as List;
                                databaseVisitCount = list.length;
                              }
                            }
                          } catch (_) {}

                          provider.updatePatient(
                            patientId: patient.id,
                            visitNo: databaseVisitCount + 1,
                          );
                        },
                        borderRadius: const BorderRadius.all(Radius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(patient.profileImage),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patient.fullName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isSelected ? AppTheme.tealAccent : AppTheme.primarySlate,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Code: ${patient.patientCode} • Mob: ${patient.phone}',
                                      style: const TextStyle(
                                        color: AppTheme.secondarySlate,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: AppTheme.tealAccent)
                              else
                                const Icon(Icons.circle_outlined, color: Color(0xFFCBD5E1)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
