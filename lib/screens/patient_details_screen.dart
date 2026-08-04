import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:provider/provider.dart';
import '../models/patient_model.dart';
import '../models/visit_model.dart';
import '../models/payment_model.dart';
import '../providers/visit_provider.dart';
import '../services/visit_service.dart';
import '../services/patient_service.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import 'add_patient_screen.dart';
import 'visit_details_screen.dart';
import 'new_treatment_screen.dart';

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
          .timeout(const Duration(seconds: 8));
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


  Future<void> _showEditVisitDialog(VisitModel visit) async {
    // 1. Fetch visit details from backend (so we have findings, etc.)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.tealAccent),
      ),
    );

    VisitModel? fullVisit;
    try {
      final res = await VisitService.getVisitById(_doctorId, visit.id);
      if (res.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(res.body);
        if (responseData['statusCode'] == 200) {
          fullVisit = VisitModel.fromJson(responseData['body']);
        }
      }
    } catch (_) {}

    // Pop the loading spinner dialog
    if (mounted) Navigator.pop(context);

    if (fullVisit == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading visit details for edit.'),
            backgroundColor: AppTheme.redDestructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // 2. Fetch linked payment from database API
    PaymentModel? linkedPayment;
    try {
      final response = await PaymentService.getPayments(_doctorId).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['statusCode'] == 200 && responseData['body'] is List) {
          final list = responseData['body'] as List;
          final fetchedPayments = list.map((json) => PaymentModel.fromJson(json)).toList();
          linkedPayment = fetchedPayments.firstWhere((p) => p.visitId == visit.id);
        }
      }
    } catch (_) {}

    if (linkedPayment == null) {
      // Create a default payment if not found
      linkedPayment = PaymentModel(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        parentId: _doctorId,
        visitId: visit.id,
        patientId: visit.patientId,
        invoiceNo: 'INV-${visit.id.toString().substring(3)}',
        subtotal: 0.0,
        discount: 0.0,
        totalAmount: 0.0,
        paidAmount: 0.0,
        pendingAmount: 0.0,
        paymentMethod: 'UPI',
        paymentStatus: 'Pending',
        paymentDate: visit.visitDate,
        remarks: '',
        createdBy: _doctorId,
        createdAt: visit.createdAt,
        updatedAt: visit.updatedAt,
      );
    }

    // 3. Populate provider
    if (!mounted) return;
    Provider.of<VisitProvider>(context, listen: false).populateForEdit(
      fullVisit,
      linkedPayment,
    );

    // 4. Navigate to NewTreatmentScreen for editing
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => NewTreatmentScreen(
          visitToEdit: fullVisit,
          paymentToEdit: linkedPayment,
        ),
      ),
    );

    if (result != null && mounted) {
      final updatedVisit = result['visit'] as VisitModel;
      final updatedPayment = result['payment'] as PaymentModel;

      setState(() {
        _isLoadingVisits = true;
      });

      // Update visit on backend
      bool visitSuccess = false;
      try {
        final payload = {
          "id": updatedVisit.id,
          "parentId": _doctorId,
          "chiefComplaintText": updatedVisit.chiefComplaintText,
          "chiefComplaintImages": updatedVisit.chiefComplaintImages,
          "clinicalFindingsText": updatedVisit.clinicalFindingsText,
          "clinicalFindingsImages": updatedVisit.clinicalFindingsImages,
          "labText": updatedVisit.labText,
          "labImages": updatedVisit.labImages,
          "advisedTreatmentText": updatedVisit.advisedTreatmentText,
          "advisedTreatmentImages": updatedVisit.advisedTreatmentImages,
          "treatmentDoneText": updatedVisit.treatmentDoneText,
          "treatmentDoneImages": updatedVisit.treatmentDoneImages,
          "medicationText": updatedVisit.medicationText,
          "medicationImages": updatedVisit.medicationImages,
          "nextAppointmentDate": updatedVisit.nextAppointmentDate.isEmpty ? null : updatedVisit.nextAppointmentDate,
          "notes": updatedVisit.notes,
          "status": int.tryParse(updatedVisit.status) ?? 1
        };

        final response = await VisitService.updateVisit(payload).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          visitSuccess = true;
        }
      } catch (_) {}

      // Update payment on backend
      try {
        await PaymentService.updatePaymentDetails({
          'id': updatedPayment.id,
          'paidAmount': updatedPayment.paidAmount,
          'pendingAmount': updatedPayment.pendingAmount,
          'paymentStatus': updatedPayment.paymentStatus,
          'remarks': updatedPayment.remarks,
        }).timeout(const Duration(seconds: 5));
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(visitSuccess
                ? 'Visit details saved and synchronized.'
                : 'Failed to synchronize details with database.'),
            backgroundColor: visitSuccess ? AppTheme.emeraldSuccess : AppTheme.redDestructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      _fetchVisits();
    }
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
                                  title: Text("VST-${visit.visitNo.replaceAll(RegExp(r'[^\d]'), '').isEmpty
                                      ? visit.visitNo
                                      : int.parse(visit.visitNo.replaceAll(RegExp(r'[^\d]'), '')).toString().padLeft(3, '0')}",
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primarySlate,
                                    ),
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
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppTheme.tealAccent, size: 20),
                                    onPressed: () => _showEditVisitDialog(visit),
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
