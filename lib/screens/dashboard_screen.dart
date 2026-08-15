import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient_model.dart';
import '../models/visit_model.dart';
import '../models/payment_model.dart';
import '../models/appointment_model.dart';
import '../providers/visit_provider.dart';
import '../services/patient_service.dart';
import '../services/visit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import 'patient_registry_screen.dart';
import 'new_treatment_screen.dart';
import 'profile_screen.dart';
import 'manage_doctors_screen.dart';
import 'appointments_screen.dart';
import 'payments_screen.dart';
import '../services/appointment_service.dart';
import '../services/payment_service.dart';

/// The main DashboardScreen. Serves as the page container and coordinator of state.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Local state lists for patients, visits, and payments
  late List<PatientModel> _patients;
  late List<VisitModel> _visits;
  late List<PaymentModel> _payments;

  double _totalEarnings = 0.0;
  int _pendingPaymentsCount = 0;
  int _appointmentsTodayCount = 0;
  int _appointmentsUpcomingCount = 0;

  bool _isAddButtonPressed = false;
  bool _isAddButtonHovered = false;

  int? _parentId;
  int? _loggedInUserId;
  bool _isSubUser = false;
  String _doctorName = '';

  @override
  void initState() {
    super.initState();
    _patients = [];
    _visits = [];
    _payments = [];

    _calculateStats();
    _loadDoctorProfileAndFetchPatients();
  }

  Future<void> _loadDoctorProfileAndFetchPatients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileStr = prefs.getString('user_profile');
      if (profileStr != null) {
        final profile = jsonDecode(profileStr);
        final rawId = profile['id'];
        final loggedInUserId = rawId is int ? rawId : (rawId != null ? int.tryParse(rawId.toString()) : null);
        final isSubUser = profile['isSubUser'] == true;
        
        final rawParentId = isSubUser 
            ? (profile['parentId'] ?? profile['mainAccountId'] ?? loggedInUserId)
            : loggedInUserId;
        final parentId = rawParentId is int ? rawParentId : (rawParentId != null ? int.tryParse(rawParentId.toString()) : null);

        final doctorName = profile['userName'] as String? ?? profile['name'] as String?;
        
        setState(() {
          _loggedInUserId = loggedInUserId;
          _parentId = parentId;
          _isSubUser = isSubUser;
          if (doctorName != null) {
            _doctorName = doctorName;
          }
        });
      }
    } catch (_) {}
    
    // Fetch patients from API
    await _fetchPatientsFromApi();

    // Fetch visits and payments dynamically
    await _fetchVisitsAndPaymentsFromApi();

    // Fetch appointment stats from API
    try {
      final response = await AppointmentService.getAppointmentStats(_loggedInUserId!).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['statusCode'] == 200 && responseData['body'] != null) {
          final body = responseData['body'];
          setState(() {
            _appointmentsTodayCount = body['appointments_today'] is int ? body['appointments_today'] : (int.tryParse(body['appointments_today'].toString()) ?? 0);
            _appointmentsUpcomingCount = body['appointments_upcoming_total'] is int ? body['appointments_upcoming_total'] : (int.tryParse(body['appointments_upcoming_total'].toString()) ?? 0);
          });
        }
      }
    } catch (_) {
      try {
        final response = await AppointmentService.getAppointments(_loggedInUserId!).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          if (responseData['statusCode'] == 200 && responseData['body'] is List) {
            final list = responseData['body'] as List;
            final appts = list.map((json) => AppointmentModel.fromJson(json)).toList();
            final now = DateTime.now();
            final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
            int todayCount = 0;
            int upcomingCount = 0;
            for (var a in appts) {
              if (a.status.toLowerCase() == 'cancelled') continue;
              final aDate = a.appointmentDate.length >= 10 ? a.appointmentDate.substring(0, 10) : a.appointmentDate;
              if (aDate == todayStr) todayCount++;
              if (aDate.compareTo(todayStr) >= 0) upcomingCount++;
            }
            setState(() {
              _appointmentsTodayCount = todayCount;
              _appointmentsUpcomingCount = upcomingCount;
            });
          }
        }
      } catch (_) {}
    }
  }



  Future<void> _fetchVisitsAndPaymentsFromApi() async {
    List<VisitModel> allVisits = [];
    List<PaymentModel> allPayments = [];

    // Fetch API visits for all patients
    List<VisitModel> apiVisits = [];
    try {
      final futures = _patients.map((patient) async {
        try {
          final response = await VisitService.getVisits(_parentId!, patient.id)
              .timeout(const Duration(seconds: 3));
          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            if (responseData['statusCode'] == 200 && responseData['body'] is List) {
              final list = responseData['body'] as List;
              return list.map((json) => VisitModel.fromJson(json)).toList();
            }
          }
        } catch (_) {}
        return <VisitModel>[];
      });

      final results = await Future.wait(futures);
      for (final list in results) {
        apiVisits.addAll(list);
      }
    } catch (_) {}

    allVisits = apiVisits;
    if (allVisits.isNotEmpty) {
      allVisits.sort((a, b) => b.visitDate.compareTo(a.visitDate));
    }

    // Fetch Payments from API
    try {
      final response = await PaymentService.getPayments(_parentId!)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['statusCode'] == 200 && responseData['body'] is List) {
          final list = responseData['body'] as List;
          allPayments = list.map((json) => PaymentModel.fromJson(json)).toList();
        }
      }
    } catch (_) {}

    setState(() {
      _visits = allVisits;
      _payments = allPayments;
    });
    _calculateStats();
  }

  Future<void> _fetchPatientsFromApi() async {
    try {
      final response = await PatientService.getPatients(_parentId!)
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
    } catch (_) {
      // Fallback: keep existing list
    }
  }

  void _calculateStats() {
    double earnings = 0.0;
    int pendingCount = 0;
    
    for (final p in _payments) {
      if (p.paymentStatus.toLowerCase() == 'paid') {
        earnings += p.totalAmount;
      } else if (p.paymentStatus.toLowerCase() == 'partial') {
        earnings += p.paidAmount;
        pendingCount++;
      } else if (p.paymentStatus.toLowerCase() == 'unpaid' || p.paymentStatus.toLowerCase() == 'pending') {
        pendingCount++;
      }
    }

    setState(() {
      _totalEarnings = earnings;
      _pendingPaymentsCount = pendingCount;
    });
  }

  Future<void> _showAddTreatmentDialog() async {
    // Reset provider state first
    Provider.of<VisitProvider>(context, listen: false).reset(
      parentId: _parentId!,
      doctorId: _loggedInUserId!,
    );

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const NewTreatmentScreen(),
      ),
    );

    if (result != null && mounted) {
      final VisitModel visit = result['visit'] as VisitModel;
      final PaymentModel payment = result['payment'] as PaymentModel;

      setState(() {
        _visits.insert(0, visit);
        _payments.insert(0, payment);

        // Update patient's visit count and last visit date
        final pIndex = _patients.indexWhere((p) => p.id == visit.patientId);
        if (pIndex != -1) {
          final oldP = _patients[pIndex];
          final updatedP = PatientModel(
            id: oldP.id,
            parentId: oldP.parentId,
            patientCode: oldP.patientCode,
            profileImage: oldP.profileImage,
            fullName: oldP.fullName,
            age: oldP.age,
            gender: oldP.gender,
            dateOfBirth: oldP.dateOfBirth,
            phone: oldP.phone,
            email: oldP.email,
            address: oldP.address,
            medicalConditions: oldP.medicalConditions,
            emergencyContactName: oldP.emergencyContactName,
            emergencyContactPhone: oldP.emergencyContactPhone,
            totalVisits: oldP.totalVisits + 1,
            lastVisitDate: visit.visitDate.length >= 10 ? visit.visitDate.substring(0, 10) : visit.visitDate,
            createdBy: oldP.createdBy,
            status: oldP.status,
            createdAt: oldP.createdAt,
            updatedAt: DateTime.now().toString().substring(0, 19),
          );

          _patients[pIndex] = updatedP;

          // Asynchronously update patient profile on backend database
          _asyncUpdatePatient(updatedP);
        }
      });

      // Asynchronously synchronize visit, payment and appointment details to database
      final AppointmentModel? appointment = result['appointment'] as AppointmentModel?;
      _asyncCreateVisitAndPayment(visit, payment, appointment);

      _calculateStats();
    }
  }

  Future<void> _asyncCreateVisitAndPayment(VisitModel visit, PaymentModel payment, AppointmentModel? appointment) async {
    int numericVisitNo = 1;
    final match = RegExp(r'\d+').firstMatch(visit.visitNo);
    if (match != null) {
      numericVisitNo = int.tryParse(match.group(0)!) ?? 1;
    }

    final payload = {
      "parentId": _parentId!,
      "patientId": visit.patientId,
      "doctorId": _loggedInUserId!,
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
      print('DEBUG [DashboardScreen]: Clicked finish. Initiating visit creation...');
      print('DEBUG [DashboardScreen]: Visit payload: $payload');
      
      final response = await VisitService.createVisit(payload).timeout(const Duration(seconds: 8));
      print('DEBUG [DashboardScreen]: Visit API HTTP status: ${response.statusCode}');
      print('DEBUG [DashboardScreen]: Visit API raw body response: ${response.body}');
      
      final responseData = jsonDecode(response.body);
      print('DEBUG [DashboardScreen]: Visit response decoded: $responseData');
      
      final httpOk = response.statusCode == 200 || response.statusCode == 201;
      final serverOk = responseData['statusCode'] == 200 || responseData['statusCode'] == 201;
      
      if (httpOk || serverOk) {
        final rawId = responseData['body'] != null ? responseData['body']['id'] : null;
        if (rawId == null) {
          throw Exception('Visit created but did not return insert ID.');
        }
        final newVisitId = rawId is int ? rawId : int.parse(rawId.toString());
        print('DEBUG [DashboardScreen]: Visit created successfully. Assigned database ID: $newVisitId');

        // Now record payment linked to this actual newVisitId
        final paymentPayload = {
          "parentId": _parentId!,
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
          "createdBy": _loggedInUserId!,
        };

        print('DEBUG [DashboardScreen]: Initiating payment creation...');
        print('DEBUG [DashboardScreen]: Payment payload: $paymentPayload');
        
        final payRes = await PaymentService.createPayment(paymentPayload).timeout(const Duration(seconds: 8));
        print('DEBUG [DashboardScreen]: Payment API HTTP status: ${payRes.statusCode}');
        print('DEBUG [DashboardScreen]: Payment API raw body response: ${payRes.body}');
        
        final payData = jsonDecode(payRes.body);
        print('DEBUG [DashboardScreen]: Payment response decoded: $payData');

        // If an appointment was configured, schedule it with the real visit ID
        if (appointment != null) {
          final appointmentPayload = {
            'visitId': newVisitId,
            'patientId': appointment.patientId,
            'doctorId': appointment.doctorId,
            'appointmentDate': appointment.appointmentDate,
            'procedureText': appointment.procedureText,
          };
          print('DEBUG [DashboardScreen]: Clicked finish. Initiating appointment creation...');
          print('DEBUG [DashboardScreen]: Appointment payload: $appointmentPayload');
          
          final apptRes = await AppointmentService.createAppointment(appointmentPayload).timeout(const Duration(seconds: 8));
          print('DEBUG [DashboardScreen]: Appointment API HTTP status: ${apptRes.statusCode}');
          print('DEBUG [DashboardScreen]: Appointment API raw body response: ${apptRes.body}');
          
          final apptData = jsonDecode(apptRes.body);
          print('DEBUG [DashboardScreen]: Appointment response decoded: $apptData');
        }

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
        _fetchVisitsAndPaymentsFromApi(); // reload lists to get server synced IDs
      } else {
        print('DEBUG [DashboardScreen]: Visit API returned non-success structure: statusCode=${responseData['statusCode']}, message=${responseData['message']}');
        throw Exception('Server returned non-success response: ${responseData['message']}');
      }
    } catch (e, stackTrace) {
      print('DEBUG [DashboardScreen] ERROR caught inside _asyncCreateVisitAndPayment:');
      print(e.toString());
      print(stackTrace.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync details. Error: $e'),
            backgroundColor: AppTheme.redDestructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _asyncUpdatePatient(PatientModel updatedP) async {
    try {
      await PatientService.updatePatient({
        "id": updatedP.id,
        "parentId": updatedP.parentId,
        "profileImage": updatedP.profileImage,
        "fullName": updatedP.fullName,
        "age": updatedP.age,
        "gender": updatedP.gender,
        "dateOfBirth": updatedP.dateOfBirth,
        "phone": updatedP.phone,
        "email": updatedP.email,
        "address": updatedP.address,
        "medicalConditions": updatedP.medicalConditions,
        "emergencyContactName": updatedP.emergencyContactName,
        "emergencyContactPhone": updatedP.emergencyContactPhone,
        "status": updatedP.status ? 1 : 0
      }).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> _navigateToPatientRegistry() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientRegistryScreen(patients: _patients),
      ),
    );
    _fetchPatientsFromApi();
  }

  @override
  Widget build(BuildContext context) {
    if (_parentId == null || _loggedInUserId == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.shrink(),
      );
    }
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive design card counts
    final crossAxisCount = screenWidth > 1200
        ? 3
        : screenWidth > 800
            ? 2
            : 1;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Premium Custom App Header (Localized for India)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppTheme.secondarySlate,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _doctorName,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primarySlate,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Profile Avatar
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileScreen()),
                            ).then((_) {
                              _loadDoctorProfileAndFetchPatients();
                            });
                          },
                          child: const CircleAvatar(
                            radius: 22,
                            backgroundImage: AssetImage(
                              'assets/doctor.jpeg',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Grid Row of the Three Cards (Patient, Appointments, Payments)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: crossAxisCount == 3
                    ? SizedBox(
                        height: 180,
                        child: Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: 'Patient Details',
                                primaryValue: '${_patients.length}',
                                secondaryText: 'Tap to view registry search',
                                icon: Icons.people_alt_outlined,
                                gradient: AppTheme.patientCardGradient,
                                quickLinks: const ['Registry', 'Search'],
                                onTap: _navigateToPatientRegistry,
                                onQuickLinkTap: (idx) => _navigateToPatientRegistry(),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: StatCard(
                                title: 'Appointments',
                                primaryValue: '$_appointmentsTodayCount Today',
                                secondaryText: '$_appointmentsUpcomingCount Upcoming total',
                                icon: Icons.calendar_today_outlined,
                                gradient: AppTheme.appointmentCardGradient,
                                quickLinks: const ['Schedules', 'Calendar'],
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AppointmentsScreen()),
                                ).then((_) => _loadDoctorProfileAndFetchPatients()),
                                onQuickLinkTap: (idx) => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AppointmentsScreen()),
                                ).then((_) => _loadDoctorProfileAndFetchPatients()),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: StatCard(
                                title: 'Payments / Bills',
                                primaryValue: '₹${_totalEarnings.toStringAsFixed(0)}',
                                secondaryText: '$_pendingPaymentsCount pending bills',
                                icon: Icons.account_balance_wallet_outlined,
                                gradient: AppTheme.paymentCardGradient,
                                quickLinks: const ['Invoices', 'Reports'],
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const PaymentsScreen()),
                                ).then((_) => _loadDoctorProfileAndFetchPatients()),
                                onQuickLinkTap: (idx) => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const PaymentsScreen()),
                                ).then((_) => _loadDoctorProfileAndFetchPatients()),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 2.1,
                        children: [
                          StatCard(
                            title: 'Patient Details',
                            primaryValue: '${_patients.length}',
                            secondaryText: 'Tap to view registry search',
                            icon: Icons.people_alt_outlined,
                            gradient: AppTheme.patientCardGradient,
                            quickLinks: const ['Registry', 'Search'],
                            onTap: _navigateToPatientRegistry,
                            onQuickLinkTap: (idx) => _navigateToPatientRegistry(),
                          ),
                          StatCard(
                            title: 'Appointments',
                            primaryValue: '$_appointmentsTodayCount Today',
                            secondaryText: '$_appointmentsUpcomingCount Upcoming total',
                            icon: Icons.calendar_today_outlined,
                            gradient: AppTheme.appointmentCardGradient,
                            quickLinks: const ['Schedules', 'Calendar'],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AppointmentsScreen()),
                            ).then((_) => _loadDoctorProfileAndFetchPatients()),
                          ),
                          StatCard(
                            title: 'Payments / Bills',
                            primaryValue: '₹${_totalEarnings.toStringAsFixed(0)}',
                            secondaryText: '$_pendingPaymentsCount pending bills',
                            icon: Icons.account_balance_wallet_outlined,
                            gradient: AppTheme.paymentCardGradient,
                            quickLinks: const ['Invoices', 'Reports'],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PaymentsScreen()),
                            ).then((_) => _loadDoctorProfileAndFetchPatients()),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              // 3. Wide "Add New Treatment" Call-to-Action Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isAddButtonHovered = true),
                  onExit: (_) => setState(() => _isAddButtonHovered = false),
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _isAddButtonPressed = true),
                    onTapUp: (_) => setState(() => _isAddButtonPressed = false),
                    onTapCancel: () => setState(() => _isAddButtonPressed = false),
                    onTap: _showAddTreatmentDialog,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      height: 70,
                      transform: Matrix4.identity()
                        ..scale(_isAddButtonPressed
                            ? 0.98
                            : _isAddButtonHovered
                                ? 1.015
                                : 1.0),
                      decoration: BoxDecoration(
                        gradient: AppTheme.newTreatmentGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _isAddButtonHovered
                            ? [
                                BoxShadow(
                                  color: AppTheme.primarySlate.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                )
                              ]
                            : AppTheme.premiumShadow,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_circle_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Add New Treatment',
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (!_isSubUser) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ManageDoctorsScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: AppTheme.premiumShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.tealAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.people_outline_rounded,
                              color: AppTheme.tealAccent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Manage Doctors & Staff',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primarySlate,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'View, add and coordinate clinic team roles',
                                  style: TextStyle(color: AppTheme.secondarySlate, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppTheme.secondarySlate,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
