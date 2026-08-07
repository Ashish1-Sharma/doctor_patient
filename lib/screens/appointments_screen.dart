import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment_model.dart';
import '../models/patient_model.dart';
import '../services/appointment_service.dart';
import '../services/patient_service.dart';
import '../theme/app_theme.dart';
import 'patient_details_screen.dart';

/// Screen listing appointments grouped by date (Today, Tomorrow, Upcoming).
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool _isLoading = true;
  List<AppointmentModel> _appointments = [];
  List<PatientModel> _patients = [];
  int _doctorId = 1;
  int _parentId = 1;
  DateTimeRange? _selectedDateRange;

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now().add(const Duration(days: 14)),
      ),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
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
        _loadData();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // 1. Load doctor and parent ids
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileStr = prefs.getString('user_profile');
      if (profileStr != null) {
        final profile = jsonDecode(profileStr);
        _doctorId = profile['id'] as int? ?? 1;
        _parentId = (profile['isSubUser'] == true
            ? (profile['parentId'] ?? _doctorId)
            : _doctorId);
      }
    } catch (_) {}

    // 2. Fetch Patients (for matching name & code)
    try {
      final response = await PatientService.getPatients(_parentId);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['statusCode'] == 200 && responseData['body'] is List) {
          final list = responseData['body'] as List;
          _patients = list.map((json) => PatientModel.fromJson(json)).toList();
        }
      }
    } catch (_) {}

    // 3. Fetch Appointments directly from backend database
    List<AppointmentModel> fetchedAppts = [];
    try {
      final response = await AppointmentService.getAppointments(_doctorId).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['statusCode'] == 200 && responseData['body'] is List) {
          final list = responseData['body'] as List;
          fetchedAppts = list.map((json) => AppointmentModel.fromJson(json)).toList();
        }
      }
    } catch (_) {}

    // Sort by date ascending
    fetchedAppts.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

    setState(() {
      _appointments = fetchedAppts;
      _isLoading = false;
    });
  }

  PatientModel? _getPatient(int id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // Group appointments into Today, Tomorrow, Upcoming
  Map<String, List<AppointmentModel>> _groupAppointments() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

    final List<AppointmentModel> todayList = [];
    final List<AppointmentModel> tomorrowList = [];
    final List<AppointmentModel> upcomingList = [];
    final List<AppointmentModel> passedList = [];

    final filteredAppts = _selectedDateRange == null
        ? _appointments
        : _appointments.where((appt) {
            try {
              final apptDate = DateTime.parse(appt.appointmentDate);
              final dateOnly = DateTime(apptDate.year, apptDate.month, apptDate.day);
              final startOnly = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
              final endOnly = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day);
              return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
            } catch (_) {
              return true;
            }
          }).toList();

    for (final appt in filteredAppts) {
      if (appt.appointmentDate.length >= 10) {
        final dateStr = appt.appointmentDate.substring(0, 10);
        if (dateStr == todayStr) {
          todayList.add(appt);
        } else if (dateStr == tomorrowStr) {
          tomorrowList.add(appt);
        } else if (appt.appointmentDate.compareTo(todayStr) < 0) {
          passedList.add(appt);
        } else {
          upcomingList.add(appt);
        }
      } else {
        upcomingList.add(appt);
      }
    }

    return {
      'Today': todayList,
      'Tomorrow': tomorrowList,
      'Upcoming': upcomingList,
      'Passed / Archived': passedList,
    };
  }


  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final groups = _groupAppointments();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Appointments Scheduler', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.primarySlate,
        actions: [
          IconButton(
            icon: Icon(
              _selectedDateRange != null ? Icons.date_range : Icons.date_range_outlined,
              color: _selectedDateRange != null ? AppTheme.tealAccent : null,
            ),
            tooltip: 'Filter by Date Range',
            onPressed: () => _pickDateRange(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedDateRange != null)
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, size: 16, color: AppTheme.tealAccent),
                  const SizedBox(width: 8),
                  Text(
                    'Range: ${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primarySlate),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDateRange = null;
                      });
                    },
                    child: const Icon(Icons.cancel, size: 18, color: AppTheme.secondarySlate),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent))
                : _appointments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 64, color: AppTheme.secondarySlate.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            const Text(
                              'No appointments scheduled yet.',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondarySlate),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.tealAccent,
                        onRefresh: _loadData,
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: groups.keys.map((title) {
                            final list = groups[title]!;
                            if (list.isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                                  child: Text(
                                    title.toUpperCase(),
                                    style: textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: title == 'Today'
                                          ? AppTheme.tealAccent
                                          : title == 'Tomorrow'
                                              ? AppTheme.primarySlate
                                              : AppTheme.secondarySlate,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                ...list.map((appt) {
                                  final patient = _getPatient(appt.patientId);
                                  final patientName = patient?.fullName ?? 'Unknown Patient';
                                  final patientCode = patient?.patientCode ?? 'N/A';

                                  // Format Date & Time
                                  String displayTime = '';
                                  if (appt.appointmentDate.length >= 16) {
                                    displayTime = appt.appointmentDate.substring(11, 16); // e.g. 10:30
                                  }

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    color: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  patientName,
                                                  style: textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.primarySlate,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  displayTime.isNotEmpty ? displayTime : '10:00',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: AppTheme.primarySlate,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Code: $patientCode • Date: ${appt.appointmentDate.substring(0, 10)}',
                                            style: textTheme.bodySmall?.copyWith(color: AppTheme.secondarySlate),
                                          ),
                                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                                          Row(
                                            children: [
                                              const Icon(Icons.settings_outlined, size: 14, color: AppTheme.tealAccent),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Procedure: ${appt.procedureText}',
                                                  style: textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.primarySlate,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: () => _rescheduleAppointment(appt),
                                                icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                                                label: const Text('Reschedule', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppTheme.tealAccent,
                                                  side: const BorderSide(color: AppTheme.tealAccent),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              OutlinedButton.icon(
                                                onPressed: () {
                                                  if (patient != null) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => PatientDetailsScreen(patient: patient),
                                                      ),
                                                    );
                                                  }
                                                },
                                                icon: const Icon(Icons.folder_open_outlined, size: 16),
                                                label: const Text('View Case File', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppTheme.tealAccent,
                                                  side: const BorderSide(color: AppTheme.tealAccent),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 12),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
