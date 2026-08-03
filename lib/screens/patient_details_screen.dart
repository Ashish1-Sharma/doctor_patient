import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/patient_model.dart';
import '../models/visit_model.dart';
import '../services/visit_service.dart';
import '../services/patient_service.dart';
import '../theme/app_theme.dart';
import 'add_patient_screen.dart';
import 'visit_details_screen.dart';

class PatientDetailsScreen extends StatefulWidget {
  final PatientModel patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  late PatientModel _currentPatient;
  List<VisitModel> _visits = [];
  bool _isLoadingVisits = false;
  String? _errorMessage;
  int _doctorId = 1;

  @override
  void initState() {
    super.initState();
    _currentPatient = widget.patient;
    _loadDoctorIdAndFetchVisits();
  }

  Future<void> _loadDoctorIdAndFetchVisits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileStr = prefs.getString('user_profile');
      if (profileStr != null) {
        final profile = jsonDecode(profileStr);
        final doctorId = profile['id'] as int?;
        if (doctorId != null) {
          _doctorId = doctorId;
        }
      }
    } catch (_) {}

    _fetchVisits();
  }

  Future<void> _fetchVisits() async {
    setState(() {
      _isLoadingVisits = true;
      _errorMessage = null;
    });

    try {
      final response = await VisitService.getVisits(_doctorId, _currentPatient.id)
          .timeout(const Duration(seconds: 5));
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['statusCode'] == 200) {
        if (responseData['body'] is List) {
          final list = responseData['body'] as List;
          final apiVisits = list.map((json) => VisitModel.fromJson(json)).toList();
          apiVisits.sort((a, b) => b.visitDate.compareTo(a.visitDate));
          setState(() {
            _visits = apiVisits;
          });
        } else {
          setState(() {
            _visits = [];
          });
        }
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Failed to load visits.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load visits. Check network connection.';
      });
    } finally {
      setState(() {
        _isLoadingVisits = false;
      });
    }
  }

  Future<void> _refreshPatientDetails() async {
    try {
      final response = await PatientService.getPatients(_doctorId);
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['statusCode'] == 200 && responseData['body'] is List) {
        final list = responseData['body'] as List;
        final matching = list.map((json) => PatientModel.fromJson(json)).firstWhere(
          (p) => p.id == _currentPatient.id,
          orElse: () => _currentPatient,
        );
        setState(() {
          _currentPatient = matching;
        });
      }
    } catch (_) {}
  }

  Future<void> _editPatientProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddPatientScreen(patientToEdit: _currentPatient),
      ),
    );

    if (result == true) {
      _refreshPatientDetails();
    }
  }

  Future<void> _toggleVisitStatus(VisitModel visit) async {
    final currentStatusVal = int.tryParse(visit.status) ?? 1;
    final nextStatusVal = currentStatusVal == 1 ? 0 : 1;

    try {
      final response = await VisitService.changeVisitStatus(visit.id, _doctorId, nextStatusVal)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Visit status updated successfully to ${nextStatusVal == 1 ? "Active" : "Inactive"}.'),
              backgroundColor: AppTheme.emeraldSuccess,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _fetchVisits();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update status on server.'),
              backgroundColor: AppTheme.redDestructive,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update status. Check backend connection.'),
            backgroundColor: AppTheme.redDestructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEditVisitDialog(VisitModel visit) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<http.Response>(
          future: VisitService.getVisitById(_doctorId, visit.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.tealAccent),
                  ),
                ),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return const AlertDialog(
                content: Text('Error loading visit details for edit.'),
              );
            }

            try {
              final Map<String, dynamic> responseData = jsonDecode(snapshot.data!.body);
              final details = VisitModel.fromJson(responseData['body']);

              final complaintCtrl = TextEditingController(text: details.chiefComplaintText);
              final findingsCtrl = TextEditingController(text: details.clinicalFindingsText);
              final labCtrl = TextEditingController(text: details.labText);
              final advisedCtrl = TextEditingController(text: details.advisedTreatmentText);
              final doneCtrl = TextEditingController(text: details.treatmentDoneText);
              final medicationCtrl = TextEditingController(text: details.medicationText);
              final nextDateCtrl = TextEditingController(text: details.nextAppointmentDate);
              final notesCtrl = TextEditingController(text: details.notes);

              return AlertDialog(
                title: Text('Edit Visit: ${details.visitNo.startsWith('VIS-') ? details.visitNo : 'VIS-${details.visitNo.padLeft(4, '0')}'}'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: complaintCtrl,
                          decoration: const InputDecoration(labelText: 'Chief Complaint'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: findingsCtrl,
                          decoration: const InputDecoration(labelText: 'Clinical Findings'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: labCtrl,
                          decoration: const InputDecoration(labelText: 'Lab Details'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: advisedCtrl,
                          decoration: const InputDecoration(labelText: 'Advised Treatment'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: doneCtrl,
                          decoration: const InputDecoration(labelText: 'Treatment Done'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: medicationCtrl,
                          decoration: const InputDecoration(labelText: 'Medication Text'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: nextDateCtrl,
                          decoration: const InputDecoration(labelText: 'Next Appointment (YYYY-MM-DD)'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: notesCtrl,
                          decoration: const InputDecoration(labelText: 'Notes / Remarks'),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final Map<String, dynamic> updatePayload = {
                        "id": details.id,
                        "parentId": _doctorId,
                        "chiefComplaintText": complaintCtrl.text.trim(),
                        "chiefComplaintImages": details.chiefComplaintImages,
                        "clinicalFindingsText": findingsCtrl.text.trim(),
                        "clinicalFindingsImages": details.clinicalFindingsImages,
                        "labText": labCtrl.text.trim(),
                        "labImages": details.labImages,
                        "advisedTreatmentText": advisedCtrl.text.trim(),
                        "advisedTreatmentImages": details.advisedTreatmentImages,
                        "treatmentDoneText": doneCtrl.text.trim(),
                        "treatmentDoneImages": details.treatmentDoneImages,
                        "medicationText": medicationCtrl.text.trim(),
                        "medicationImages": details.medicationImages,
                        "nextAppointmentDate": nextDateCtrl.text.trim().isEmpty ? null : nextDateCtrl.text.trim(),
                        "notes": notesCtrl.text.trim(),
                        "status": int.tryParse(details.status) ?? 1
                      };

                      try {
                        final res = await VisitService.updateVisit(updatePayload);
                        if (res.statusCode == 200 && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Visit details updated successfully!'),
                              backgroundColor: AppTheme.emeraldSuccess,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.pop(context); // Close dialog
                          _fetchVisits(); // Refresh list
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update details on server.'),
                                backgroundColor: AppTheme.redDestructive,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to update. Check network connection.'),
                              backgroundColor: AppTheme.redDestructive,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            } catch (_) {
              return const AlertDialog(
                content: Text('Failed to parse details for editing.'),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Patient Case File',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primarySlate),
          onPressed: () => Navigator.of(context).pop(true), // Return true to trigger registry reload
        ),
      ),
      body: Column(
        children: [
          // 1. Patient Profile Card Summary
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.tealAccent.withValues(alpha: 0.1),
                        child: Text(
                          _currentPatient.fullName.isNotEmpty
                              ? _currentPatient.fullName.substring(0, 1).toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: AppTheme.tealAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentPatient.fullName,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primarySlate,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Code: ${_currentPatient.patientCode} • ${_currentPatient.age} yrs • ${_currentPatient.gender}',
                              style: textTheme.bodySmall?.copyWith(color: AppTheme.secondarySlate),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: _editPatientProfile,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.tealAccent,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                    ],
                  ),
                  if (_currentPatient.address.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.secondarySlate),
                        const SizedBox(width: 6),
                        Text(
                          _currentPatient.address,
                          style: textTheme.bodySmall?.copyWith(color: AppTheme.primarySlate),
                        ),
                      ],
                    ),
                  ],
                  if (_currentPatient.medicalConditions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _currentPatient.medicalConditions.map((condition) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.tealAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            condition,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppTheme.tealAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
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

          // Header title for Visit Log history
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Clinical Visit Log',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primarySlate,
                  ),
                ),
                Text(
                  '${_visits.length} logs found',
                  style: textTheme.bodySmall?.copyWith(color: AppTheme.secondarySlate),
                ),
              ],
            ),
          ),

          // Error Display if API fails
          if (_errorMessage != null && _visits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
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
                          _errorMessage!,
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

          // 2. Visits History List
          Expanded(
            child: _isLoadingVisits
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.tealAccent),
                  )
                : RefreshIndicator(
                    color: AppTheme.tealAccent,
                    onRefresh: _fetchVisits,
                    child: _visits.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.history_toggle_off_outlined,
                                      size: 54,
                                      color: AppTheme.secondarySlate.withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No clinic visits recorded for this patient.',
                                      style: TextStyle(
                                        color: AppTheme.secondarySlate,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: _visits.length,
                            itemBuilder: (context, index) {
                              final visit = _visits[index];
                              final isCompleted = visit.status == '1';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                                ),
                                color: Colors.white,
                                child: ListTile(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VisitDetailsScreen(
                                          visitId: visit.id,
                                          doctorId: _doctorId,
                                        ),
                                      ),
                                    );
                                  },
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        visit.visitNo.startsWith('VIS-') ? visit.visitNo : 'VIS-${visit.visitNo.padLeft(4, '0')}',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primarySlate,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? AppTheme.emeraldSuccess.withValues(alpha: 0.1)
                                              : AppTheme.secondarySlate.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isCompleted ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            color: isCompleted ? AppTheme.emeraldSuccess : AppTheme.secondarySlate,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.secondarySlate),
                                          const SizedBox(width: 6),
                                          Text(
                                            visit.visitDate,
                                            style: textTheme.bodySmall?.copyWith(color: AppTheme.secondarySlate),
                                          ),
                                        ],
                                      ),
                                      if (visit.treatmentDoneText.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.tealAccent),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                visit.treatmentDoneText,
                                                style: textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.primarySlate,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (action) {
                                      if (action == 'status') {
                                        _toggleVisitStatus(visit);
                                      } else if (action == 'edit') {
                                        _showEditVisitDialog(visit);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'status',
                                        child: Row(
                                          children: [
                                            Icon(
                                              isCompleted ? Icons.cancel_outlined : Icons.check_circle_outline,
                                              size: 18,
                                              color: isCompleted ? AppTheme.redDestructive : AppTheme.emeraldSuccess,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(isCompleted ? 'Deactivate' : 'Activate'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18, color: AppTheme.tealAccent),
                                            const SizedBox(width: 8),
                                            Text('Edit Details'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
