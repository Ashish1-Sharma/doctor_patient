import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/patient_model.dart';
import '../models/visit_model.dart';
import '../models/payment_model.dart';
import '../models/appointment_model.dart';
import '../providers/visit_provider.dart';
import '../providers/patient_provider.dart';
import '../services/visit_service.dart';
import '../services/patient_service.dart';
import '../services/payment_service.dart';
import '../services/appointment_service.dart';
import '../theme/app_theme.dart';
import 'add_patient_screen.dart';
import 'visit_details_screen.dart';
import 'new_treatment_screen.dart';
import 'patient_visit_report_screen.dart';
import 'patient_visits_screen.dart';
import 'patient_appointments_screen.dart';
import 'patient_payments_screen.dart';

class PatientDetailsScreen extends StatefulWidget {
  final PatientModel patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  late PatientModel _currentPatient;
  List<VisitModel> _visits = [];
  List<AppointmentModel> _appointments = [];
  List<PaymentModel> _payments = [];
  
  bool _isLoadingVisits = false;
  String? _errorMessage;
  
  int _doctorId = 1;
  int _parentId = 1;
  bool _isSubUser = false;
  String _doctorName = 'Dr. Amit Sharma';

  @override
  void initState() {
    super.initState();
    _currentPatient = widget.patient;
    _loadDoctorIdAndFetchData();
  }

  Future<void> _loadDoctorIdAndFetchData() async {
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
          _doctorName = profile['userName'] as String? ?? 'Dr. Amit Sharma';
        });
      }
    } catch (_) {}

    _fetchVisits();
    _fetchAppointments();
    _fetchPayments();
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

  Future<void> _fetchAppointments() async {
    try {
      final response = await AppointmentService.getAppointments(_doctorId).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['statusCode'] == 200 && responseData['body'] is List) {
          final list = responseData['body'] as List;
          final allAppts = list.map((json) => AppointmentModel.fromJson(json)).toList();
          setState(() {
            _appointments = allAppts
                .where((appt) => appt.patientId == _currentPatient.id)
                .toList();
            _appointments.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchPayments() async {
    try {
      final response = await PaymentService.getPayments(_doctorId).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['statusCode'] == 200 && responseData['body'] is List) {
          final list = responseData['body'] as List;
          final allPayments = list.map((json) => PaymentModel.fromJson(json)).toList();
          setState(() {
            _payments = allPayments.where((p) => p.patientId == _currentPatient.id).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _confirmAndDeletePatient() async {
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
        title: const Text('Delete Patient & All Records?'),
        content: Text(
          'Are you sure you want to permanently delete ${_currentPatient.fullName} (${_currentPatient.patientCode}) and all associated visit records?',
        ),
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
      final success = await provider.deletePatient(_currentPatient.id, _parentId);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patient ${_currentPatient.fullName} and records deleted.'),
            backgroundColor: AppTheme.emeraldSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
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

  Future<void> _confirmAndDeleteVisit(VisitModel visit) async {
    if (_isSubUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only Admin has permission to delete visits.'),
          backgroundColor: AppTheme.redDestructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final visitLabel = "VST-${visit.visitNo.replaceAll(RegExp(r'[^\d]'), '').isEmpty ? visit.visitNo : int.parse(visit.visitNo.replaceAll(RegExp(r'[^\d]'), '')).toString().padLeft(3, '0')}";

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Visit Record?'),
        content: Text(
          'Are you sure you want to permanently delete visit $visitLabel (${visit.visitDate}) and all associated payment records?',
        ),
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
      try {
        final response = await VisitService.deleteVisit(visit.id, _parentId)
            .timeout(const Duration(seconds: 5));
        final responseData = jsonDecode(response.body);

        if (!mounted) return;

        if (response.statusCode == 200 || responseData['statusCode'] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Visit $visitLabel deleted successfully.'),
              backgroundColor: AppTheme.emeraldSuccess,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Refresh visits, payments, appointments
          _fetchVisits();
          _fetchPayments();
          _fetchAppointments();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Failed to delete visit.'),
              backgroundColor: AppTheme.redDestructive,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Could not delete visit.'),
            backgroundColor: AppTheme.redDestructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rescheduleAppointment(AppointmentModel appointment) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(appointment.appointmentDate) ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.tealAccent,
              onPrimary: Colors.white,
              onSurface: AppTheme.primarySlate,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.tryParse(appointment.appointmentDate) ?? DateTime.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.tealAccent,
              onPrimary: Colors.white,
              onSurface: AppTheme.primarySlate,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final dateStr = '${newDateTime.year}-${newDateTime.month.toString().padLeft(2, '0')}-${newDateTime.day.toString().padLeft(2, '0')}';
    final timeStr = ' ${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}:00';
    final fullDateTimeStr = '$dateStr$timeStr';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.tealAccent),
      ),
    );

    bool success = false;
    try {
      final response = await AppointmentService.updateAppointment({
        'id': appointment.id,
        'appointmentDate': fullDateTimeStr,
        'procedureText': appointment.procedureText,
        'status': appointment.status,
      }).timeout(const Duration(seconds: 8));

      success = response.statusCode == 200;
    } catch (_) {}

    if (mounted) Navigator.pop(context); // Pop spinner

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Appointment rescheduled successfully.' : 'Failed to reschedule appointment.'),
          backgroundColor: success ? AppTheme.emeraldSuccess : AppTheme.redDestructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (success) {
        _fetchAppointments();
      }
    }
  }

  Future<void> _confirmAndDeleteAppointment(AppointmentModel appointment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Appointment?'),
        content: const Text('Are you sure you want to permanently delete this appointment slot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.secondarySlate)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.redDestructive, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    bool success = false;
    try {
      final response = await AppointmentService.deleteAppointment(appointment.id)
          .timeout(const Duration(seconds: 8));
      success = response.statusCode == 200;
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Appointment deleted successfully.' : 'Failed to delete appointment.'),
          backgroundColor: success ? AppTheme.emeraldSuccess : AppTheme.redDestructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (success) {
        _fetchAppointments();
      }
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.tealAccent),
      ),
    );

    VisitModel? fullVisit;
    try {
      final res = await VisitService.getVisitById(_parentId, visit.id);
      if (res.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(res.body);
        if (responseData['statusCode'] == 200) {
          fullVisit = VisitModel.fromJson(responseData['body']);
        }
      }
    } catch (_) {}

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

    linkedPayment ??= PaymentModel(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      parentId: _parentId,
      visitId: visit.id,
      patientId: visit.patientId,
      invoiceNo: 'INV-${visit.id}',
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

    if (!mounted) return;
    Provider.of<VisitProvider>(context, listen: false).populateForEdit(
      fullVisit,
      linkedPayment,
    );

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

      bool visitSuccess = false;
      try {
        final payload = {
          "id": updatedVisit.id,
          "parentId": _parentId,
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
      _fetchPayments();
    }
  }

  Future<void> _navigateToNewTreatment() async {
    // Reset provider state first
    final provider = Provider.of<VisitProvider>(context, listen: false);
    provider.reset(
      parentId: _parentId,
      doctorId: _doctorId,
    );
    // Pre-populate patient
    provider.updatePatient(
      patientId: _currentPatient.id,
      visitNo: _visits.length + 1,
    );

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const NewTreatmentScreen(startAtStep1: true),
      ),
    );

    if (result != null && mounted) {
      final VisitModel visit = result['visit'] as VisitModel;
      final PaymentModel payment = result['payment'] as PaymentModel;
      final AppointmentModel? appointment = result['appointment'] as AppointmentModel?;

      await _asyncCreateVisitAndPayment(visit, payment, appointment);
    }
  }

  Future<void> _asyncCreateVisitAndPayment(VisitModel visit, PaymentModel payment, AppointmentModel? appointment) async {
    setState(() {
      _isLoadingVisits = true;
    });

    int numericVisitNo = 1;
    final match = RegExp(r'\d+').firstMatch(visit.visitNo);
    if (match != null) {
      numericVisitNo = int.tryParse(match.group(0)!) ?? 1;
    }

    final payload = {
      "parentId": _parentId,
      "patientId": visit.patientId,
      "doctorId": _doctorId,
      "visitNo": numericVisitNo,
      "visitDate": visit.visitDate.length >= 10 ? visit.visitDate.substring(0, 10) : visit.visitDate,
      "chiefComplaintText": visit.chiefComplaintText,
      "chiefComplaintImages": visit.chiefComplaintImages,
      "clinicalFindingsText": visit.clinicalFindingsText,
      "clinicalFindingsImages": visit.clinicalFindingsImages,
      "labText": visit.labText,
      "labImages": visit.labImages,
      "advisedTreatmentText": visit.advisedTreatmentText,
      "advisedTreatmentImages": visit.advisedTreatmentImages,
      "treatmentDoneText": visit.treatmentDoneText,
      "treatmentDoneImages": visit.treatmentDoneImages,
      "medicationText": visit.medicationText,
      "medicationImages": visit.medicationImages,
      "nextAppointmentDate": visit.nextAppointmentDate.trim().isEmpty ? null : (visit.nextAppointmentDate.length >= 10 ? visit.nextAppointmentDate.substring(0, 10) : visit.nextAppointmentDate),
      "notes": visit.notes
    };

    try {
      final response = await VisitService.createVisit(payload).timeout(const Duration(seconds: 8));
      final responseData = jsonDecode(response.body);
      final httpOk = response.statusCode == 200 || response.statusCode == 201;
      final serverOk = responseData['statusCode'] == 200 || responseData['statusCode'] == 201;

      if (httpOk || serverOk) {
        final rawId = responseData['body'] != null ? responseData['body']['id'] : null;
        if (rawId == null) {
          throw Exception('Visit created but did not return insert ID.');
        }
        final newVisitId = rawId is int ? rawId : int.parse(rawId.toString());

        // Now record payment linked to this actual newVisitId
        final paymentPayload = {
          "parentId": _parentId,
          "visitId": newVisitId,
          "patientId": payment.patientId,
          "invoiceNo": payment.invoiceNo,
          "subtotal": payment.subtotal,
          "discount": payment.discount,
          "totalAmount": payment.totalAmount,
          "paidAmount": payment.paidAmount,
          "pendingAmount": payment.pendingAmount,
          "paymentMethod": payment.paymentMethod,
          "paymentStatus": payment.paymentStatus,
          "paymentDate": payment.paymentDate,
          "remarks": payment.remarks,
          "createdBy": _doctorId,
        };

        final payRes = await PaymentService.createPayment(paymentPayload).timeout(const Duration(seconds: 8));
        final payData = jsonDecode(payRes.body);

        // If an appointment was configured, schedule it with the real visit ID
        if (appointment != null) {
          final appointmentPayload = {
            'visitId': newVisitId,
            'patientId': appointment.patientId,
            'doctorId': appointment.doctorId,
            'appointmentDate': appointment.appointmentDate,
            'procedureText': appointment.procedureText,
          };
          await AppointmentService.createAppointment(appointmentPayload).timeout(const Duration(seconds: 8));
        }

        // Update patient's visit count and last visit date
        final updatedP = PatientModel(
          id: _currentPatient.id,
          parentId: _currentPatient.parentId,
          patientCode: _currentPatient.patientCode,
          profileImage: _currentPatient.profileImage,
          fullName: _currentPatient.fullName,
          age: _currentPatient.age,
          gender: _currentPatient.gender,
          dateOfBirth: _currentPatient.dateOfBirth,
          phone: _currentPatient.phone,
          email: _currentPatient.email,
          address: _currentPatient.address,
          medicalConditions: _currentPatient.medicalConditions,
          emergencyContactName: _currentPatient.emergencyContactName,
          emergencyContactPhone: _currentPatient.emergencyContactPhone,
          totalVisits: _currentPatient.totalVisits + 1,
          lastVisitDate: visit.visitDate.length >= 10 ? visit.visitDate.substring(0, 10) : visit.visitDate,
          createdBy: _currentPatient.createdBy,
          status: _currentPatient.status,
          createdAt: _currentPatient.createdAt,
          updatedAt: DateTime.now().toString().substring(0, 19),
        );

        // Update local patient profile on backend database
        await PatientService.updatePatient(updatedP.toJson());

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Treatment visit and payment recorded in database!'),
              backgroundColor: AppTheme.emeraldSuccess,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        throw Exception(responseData['message'] ?? 'Failed to save visit');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving visit: $e'),
            backgroundColor: AppTheme.redDestructive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      // Re-fetch all data to refresh
      await _fetchVisits();
      await _fetchAppointments();
      await _fetchPayments();
      await _refreshPatientDetails();
      if (mounted) {
        setState(() {
          _isLoadingVisits = false;
        });
      }
    }
  }

  double get _pendingPaymentSum {
    return _payments.fold(0.0, (sum, item) => sum + item.pendingAmount);
  }



  PaymentModel? _getPaymentForVisit(int visitId) {
    try {
      return _payments.firstWhere((p) => p.visitId == visitId);
    } catch (_) {
      return null;
    }
  }

  AppointmentModel? get _nextUpcomingAppointment {
    if (_appointments.isEmpty) return null;
    return _appointments.first;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Patient Case File',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primarySlate),
          onPressed: () => Navigator.of(context).pop(true),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.primarySlate),
            onSelected: (value) {
              if (value == 'edit') {
                _editPatientProfile();
              } else if (value == 'delete') {
                _confirmAndDeletePatient();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined, color: AppTheme.tealAccent),
                  title: Text('Edit Profile'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              if (!_isSubUser)
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: AppTheme.redDestructive),
                    title: Text('Delete Record', style: TextStyle(color: AppTheme.redDestructive)),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToNewTreatment,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Visit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF00796B),
        elevation: 4,
      ),
      body: RefreshIndicator(
        color: AppTheme.tealAccent,
        onRefresh: () async {
          await _fetchVisits();
          await _fetchAppointments();
          await _fetchPayments();
          await _refreshPatientDetails();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Patient Profile Summary Card
              _buildPatientProfileCard(textTheme),

              // 2. Summary Grid Metrics (4 Horizontal Boxes)
              _buildMetricsSummaryRow(),

              // 3. Upcoming Appointment Section
              _buildUpcomingAppointmentSection(textTheme),

              // 4. Clinical Visit History
              _buildVisitHistorySection(textTheme),

              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientProfileCard(TextTheme textTheme) {
    final statusColor = _currentPatient.status ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final statusTextColor = _currentPatient.status ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Profile Image, Name, Status, Patient Code and Edit
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE0F2F1),
                  child: Text(
                    _currentPatient.fullName.isNotEmpty
                        ? _currentPatient.fullName.substring(0, 1).toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      color: Color(0xFF00796B),
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _currentPatient.fullName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primarySlate,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _currentPatient.status ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: statusTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentPatient.patientCode,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00796B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.wc_outlined, size: 14, color: AppTheme.secondarySlate),
                          const SizedBox(width: 4),
                          Text(
                            _currentPatient.gender,
                            style: const TextStyle(fontSize: 12, color: AppTheme.secondarySlate),
                          ),
                          const SizedBox(width: 8),
                          const Text('•', style: TextStyle(color: AppTheme.secondarySlate)),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.secondarySlate),
                          const SizedBox(width: 4),
                          Text(
                            '${_currentPatient.age} Years',
                            style: const TextStyle(fontSize: 12, color: AppTheme.secondarySlate),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _editPatientProfile,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primarySlate,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Contact Phone Row
            InkWell(
              onTap: () async {
                final phone = _currentPatient.phone.replaceAll(RegExp(r'\D'), '');
                final uri = Uri.parse('tel:$phone');
                try {
                  await launchUrl(uri);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to open dialer: $e'),
                        backgroundColor: AppTheme.redDestructive,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: AppTheme.tealAccent),
                    const SizedBox(width: 8),
                    Text(
                      _currentPatient.phone,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.primarySlate,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_currentPatient.address.isNotEmpty) ...[
              const SizedBox(height: 8),
              // Contact Address Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2.0),
                    child: Icon(Icons.location_on_outlined, size: 16, color: AppTheme.secondarySlate),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentPatient.address,
                      style: const TextStyle(fontSize: 13, color: AppTheme.primarySlate, height: 1.3),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
            const SizedBox(height: 8),
            // Bottom section: Medical History, Last Visit, Total Visits, Doctor
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Medical History',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondarySlate),
                      ),
                      const SizedBox(height: 6),
                      _currentPatient.medicalConditions.isEmpty
                          ? const Text('None', style: TextStyle(fontSize: 13, color: AppTheme.primarySlate))
                          : Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: _currentPatient.medicalConditions.take(5).map((condition) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2F1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    condition,
                                    style: const TextStyle(
                                      color: Color(0xFF00796B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
                Container(width: 1, height: 50, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildProfileInfoColumn(
                            'Last Visit',
                            _currentPatient.lastVisitDate.isNotEmpty 
                                ? _currentPatient.lastVisitDate.split(' ').first 
                                : '-',
                          ),
                          _buildProfileInfoColumn('Total Visits', '${_visits.length}'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildProfileInfoColumn('Doctor', _doctorName),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondarySlate),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primarySlate),
        ),
      ],
    );
  }

  Widget _buildMetricsSummaryRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = (constraints.maxWidth - 16) / 3; // 3 boxes with spacing
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricBox(
                width: boxWidth,
                icon: Icons.history_outlined,
                iconColor: const Color(0xFF2E7D32),
                bgColor: const Color(0xFFE8F5E9),
                value: '${_visits.length}',
                label: 'Total Visits',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientVisitsScreen(
                        patient: _currentPatient,
                        visits: _visits,
                      ),
                    ),
                  );
                },
              ),
              _buildMetricBox(
                width: boxWidth,
                icon: Icons.calendar_today_outlined,
                iconColor: const Color(0xFF1565C0),
                bgColor: const Color(0xFFE3F2FD),
                value: '${_appointments.length}',
                label: 'Upcoming Appt',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientAppointmentsScreen(
                        patient: _currentPatient,
                        appointments: _appointments,
                        doctorId: _doctorId,
                        onRefresh: _fetchAppointments,
                      ),
                    ),
                  );
                },
              ),
              _buildMetricBox(
                width: boxWidth,
                icon: Icons.account_balance_wallet_outlined,
                iconColor: const Color(0xFFEF6C00),
                bgColor: const Color(0xFFFFF3E0),
                value: '₹${_pendingPaymentSum.toStringAsFixed(0)}',
                label: 'Pending Pay',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientPaymentsScreen(
                        patient: _currentPatient,
                        payments: _payments,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricBox({
    required double width,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primarySlate),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 9, color: AppTheme.secondarySlate, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointmentSection(TextTheme textTheme) {
    final appt = _nextUpcomingAppointment;
    if (appt == null) return const SizedBox.shrink();

    // Parse appointment date details safely
    String day = '01';
    String month = 'JAN';
    String year = '2026';
    String time = '10:00 AM';

    final parsedDate = DateTime.tryParse(appt.appointmentDate);
    if (parsedDate != null) {
      day = parsedDate.day.toString().padLeft(2, '0');
      month = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'][parsedDate.month - 1];
      year = parsedDate.year.toString();

      int hour = parsedDate.hour;
      String period = 'AM';
      if (hour >= 12) {
        period = 'PM';
        if (hour > 12) hour -= 12;
      }
      if (hour == 0) hour = 12;
      final minute = parsedDate.minute.toString().padLeft(2, '0');
      time = '$hour:$minute $period';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Appointment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primarySlate,
                ),
              ),
              Text(
                '${_appointments.length} scheduled',
                style: const TextStyle(fontSize: 12, color: AppTheme.secondarySlate),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                // Left Green Date Block
                Container(
                  width: 90,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF00796B)),
                      const SizedBox(height: 6),
                      Text(
                        day,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00796B),
                        ),
                      ),
                      Text(
                        '$month $year',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00796B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time, size: 11, color: Color(0xFF00796B)),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF00796B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right Details Column
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // const Text(
                            //   'Procedure',
                            //   style: TextStyle(fontSize: 11, color: AppTheme.secondarySlate, fontWeight: FontWeight.bold),
                            // ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                appt.status,
                                style: const TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // const SizedBox(height: 4),
                        // Text(
                        //   appt.procedureText,
                        //   style: const TextStyle(
                        //     fontSize: 15,
                        //     fontWeight: FontWeight.bold,
                        //     color: AppTheme.primarySlate,
                        //   ),
                        // ),
                        const SizedBox(height: 8),
                        const Text(
                          'Doctor',
                          style: TextStyle(fontSize: 10, color: AppTheme.secondarySlate, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _doctorName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primarySlate),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () => _confirmAndDeleteAppointment(appt),
                              icon: const Icon(Icons.delete_outline, color: AppTheme.redDestructive, size: 20),
                              tooltip: 'Delete Appointment',
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _rescheduleAppointment(appt),
                              icon: const Icon(Icons.edit_calendar_outlined, size: 14),
                              label: const Text('Reschedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00796B),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitHistorySection(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Clinical Visit History',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primarySlate,
                ),
              ),
              Text(
                '${_visits.length} visits total',
                style: const TextStyle(fontSize: 12, color: AppTheme.secondarySlate),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingVisits)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: CircularProgressIndicator(color: AppTheme.tealAccent),
              ),
            )
          else if (_errorMessage != null && _visits.isEmpty)
            Card(
              color: AppTheme.redDestructive.withValues(alpha: 0.1),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppTheme.redDestructive, fontWeight: FontWeight.w500),
                ),
              ),
            )
          else if (_visits.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.history_toggle_off_outlined,
                      size: 48,
                      color: AppTheme.secondarySlate.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No visit history logs recorded yet.',
                      style: TextStyle(color: AppTheme.secondarySlate, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _visits.length,
              itemBuilder: (context, index) {
                final visit = _visits[index];
                final payment = _getPaymentForVisit(visit.id);
                final isPaid = payment?.paymentStatus.trim().toLowerCase() == 'paid';
                
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline Dots Decoration
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(top: 24),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00796B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (index < _visits.length - 1)
                          Container(
                            width: 2,
                            height: 160, // approximate visit card height
                            color: const Color(0xFFE2E8F0),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Timeline Content Card
                    Expanded(
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                        ),
                        color: Colors.white,
                        child: InkWell(
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
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Visit Code & Date & View Report Button Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "VST-${visit.visitNo.replaceAll(RegExp(r'[^\d]'), '').isEmpty ? visit.visitNo : int.parse(visit.visitNo.replaceAll(RegExp(r'[^\d]'), '')).toString().padLeft(3, '0')}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: AppTheme.primarySlate,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF00796B), size: 16),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.only(left: 6),
                                          onPressed: () => _showEditVisitDialog(visit),
                                          tooltip: 'Edit Visit Details',
                                        ),
                                        if (!_isSubUser)
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: AppTheme.redDestructive, size: 16),
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.only(left: 4),
                                            onPressed: () => _confirmAndDeleteVisit(visit),
                                            tooltip: 'Delete Visit',
                                          ),
                                      ],
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PatientVisitReportScreen(
                                              parentId: _parentId,
                                              visitId: visit.id,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.description_outlined, size: 14),
                                      label: const Text('View Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFF00796B),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        backgroundColor: const Color(0xFFE0F2F1),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Date / Time Row
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.secondarySlate),
                                    const SizedBox(width: 4),
                                    Text(
                                      visit.visitDate,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.secondarySlate),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                // Detail Attributes Grid
                                Column(
                                  children: [
                                    // Row(
                                    //   crossAxisAlignment: CrossAxisAlignment.start,
                                    //   children: [
                                    //     Expanded(
                                    //       child: _buildVisitDetailField(
                                    //         'Chief Complaint',
                                    //         visit.chiefComplaintText.isNotEmpty
                                    //             ? visit.chiefComplaintText
                                    //             : 'None',
                                    //       ),
                                    //     ),
                                    //     Expanded(
                                    //       child: _buildVisitDetailField(
                                    //         'Diagnosis',
                                    //         visit.clinicalFindingsText.isNotEmpty
                                    //             ? visit.clinicalFindingsText
                                    //             : '-',
                                    //       ),
                                    //     ),
                                    //     Expanded(
                                    //       child: _buildVisitDetailField(
                                    //         'Treatment',
                                    //         visit.treatmentDoneText.isNotEmpty
                                    //             ? visit.treatmentDoneText
                                    //             : '-',
                                    //       ),
                                    //     ),
                                    //   ],
                                    // ),
                                    // const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Expanded(
                                        //   child: _buildVisitDetailField('Doctor', _doctorName),
                                        // ),
                                        Expanded(
                                          child: _buildVisitDetailField(
                                            'Payment',
                                            payment != null 
                                                ? '₹${payment.totalAmount.toStringAsFixed(0)}' 
                                                : '-',
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Status',
                                                style: TextStyle(fontSize: 9, color: AppTheme.secondarySlate, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: isPaid ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  payment?.paymentStatus ?? 'Pending',
                                                  style: TextStyle(
                                                    color: isPaid ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildVisitDetailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: AppTheme.secondarySlate, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primarySlate),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
