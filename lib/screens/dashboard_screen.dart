import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient_model.dart';
import '../models/visit_model.dart';
import '../models/payment_model.dart';
import '../providers/visit_provider.dart';
import '../services/patient_service.dart';
import '../services/visit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import 'patient_registry_screen.dart';
import 'new_treatment_screen.dart';
import 'profile_screen.dart';
import 'manage_doctors_screen.dart';

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
  }

  Future<void> _savePaymentsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paymentsJson = _payments.map((p) => p.toJson()).toList();
      await prefs.setString('local_payments', jsonEncode(paymentsJson));
    } catch (_) {}
  }

  Future<List<VisitModel>> _loadLocalVisits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final visitsStr = prefs.getString('local_visits');
      if (visitsStr != null) {
        final List decoded = jsonDecode(visitsStr);
        return decoded.map((json) => VisitModel.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _saveLocalVisits(List<VisitModel> visits) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final visitsJson = visits.map((v) => v.toJson()).toList();
      await prefs.setString('local_visits', jsonEncode(visitsJson));
    } catch (_) {}
  }

  Future<void> _saveNewVisitToLocalCache(VisitModel visit) async {
    final localVisits = await _loadLocalVisits();
    localVisits.insert(0, visit);
    await _saveLocalVisits(localVisits);
  }

  Future<void> _fetchVisitsAndPaymentsFromApi() async {
    List<VisitModel> allVisits = [];
    final prefs = await SharedPreferences.getInstance();

    // Load cached payments
    final paymentsStr = prefs.getString('local_payments');
    List<PaymentModel> savedPayments = [];
    if (paymentsStr != null) {
      final List decoded = jsonDecode(paymentsStr);
      savedPayments = decoded.map((json) => PaymentModel.fromJson(json)).toList();
    } else {
      savedPayments = [];
    }

    // Load cached visit overrides/additions
    List<VisitModel> localVisits = [];
    final visitsStr = prefs.getString('local_visits');
    if (visitsStr != null) {
      final List decoded = jsonDecode(visitsStr);
      localVisits = decoded.map((json) => VisitModel.fromJson(json)).toList();
    }

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

    // Merge API and local visits
    final mergedVisits = <int, VisitModel>{};
    for (final visit in apiVisits) {
      mergedVisits[visit.id] = visit;
    }
    for (final visit in localVisits) {
      mergedVisits[visit.id] = visit;
    }

    allVisits = mergedVisits.values.toList();

    if (allVisits.isNotEmpty) {
      allVisits.sort((a, b) => b.visitDate.compareTo(a.visitDate));
    }

    setState(() {
      _visits = allVisits;
      _payments = savedPayments;
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

      // Save payments list locally so it persists
      _savePaymentsToPrefs();

      // Save visit locally so it persists and reflects in PatientDetailsScreen
      _saveNewVisitToLocalCache(visit);

      // Asynchronously synchronize visit details to database
      _asyncCreateVisit(visit);

      _calculateStats();
    }
  }

  Future<void> _asyncCreateVisit(VisitModel visit) async {
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
      final response = await VisitService.createVisit(payload)
          .timeout(const Duration(seconds: 5));
      final responseData = jsonDecode(response.body);
      if ((response.statusCode == 201 || responseData['statusCode'] == 201) && mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Treatment visit synchronized to database!'),
            backgroundColor: AppTheme.emeraldSuccess,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {}
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
                        // Notification Button
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_none_outlined, color: AppTheme.primarySlate),
                                onPressed: () {},
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.redDestructive,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                            backgroundImage: NetworkImage(
                              'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=150',
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
                                primaryValue: '18 ',
                                secondaryText: '6 remaining today',
                                icon: Icons.calendar_today_outlined,
                                gradient: AppTheme.appointmentCardGradient,
                                quickLinks: const ['Schedules', 'Calendar'],
                                onTap: () {},
                                onQuickLinkTap: (idx) {},
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
                                onTap: () {},
                                onQuickLinkTap: (idx) {},
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
                            primaryValue: '18',
                            secondaryText: '6 remaining today',
                            icon: Icons.calendar_today_outlined,
                            gradient: AppTheme.appointmentCardGradient,
                            quickLinks: const ['Schedules', 'Calendar'],
                            onTap: () {},
                          ),
                          StatCard(
                            title: 'Payments / Bills',
                            primaryValue: '₹${_totalEarnings.toStringAsFixed(0)}',
                            secondaryText: '$_pendingPaymentsCount pending bills',
                            icon: Icons.account_balance_wallet_outlined,
                            gradient: AppTheme.paymentCardGradient,
                            quickLinks: const ['Invoices', 'Reports'],
                            onTap: () {},
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
