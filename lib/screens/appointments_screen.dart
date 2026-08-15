import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment_model.dart';
import '../models/patient_model.dart';
import '../services/appointment_service.dart';
import '../services/patient_service.dart';
import '../theme/app_theme.dart';
import 'appointment_detail_screen.dart';

/// Screen listing appointments with range filtering (Today, Tomorrow, Week, Custom),
/// animated transitions, grouped date headers, and simplified tappable appointment cards.
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

  final _searchController = TextEditingController();
  String _searchQuery = '';

  String _selectedRange = 'all'; // 'all', 'today', 'tomorrow', 'week', 'custom'
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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

    // 2. Fetch Patients (for matching names & avatars)
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

    // 3. Fetch Appointments for the selected range
    await _fetchAppointmentsForRange();
  }

  Future<void> _fetchAppointmentsForRange() async {
    List<AppointmentModel> fetchedAppts = [];
    String? fromStr;
    String? toStr;

    if (_selectedRange == 'custom' && _customDateRange != null) {
      final start = _customDateRange!.start;
      final end = _customDateRange!.end;
      fromStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      toStr = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    }

    try {
      final response = await AppointmentService.getAppointments(
        _parentId,
        range: _selectedRange,
        from: fromStr,
        to: toStr,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['statusCode'] == 200 && responseData['body'] is List) {
          final list = responseData['body'] as List;
          fetchedAppts = list.map((json) {
            final appt = AppointmentModel.fromJson(json);
            // If patient name exists in payload from join, update patient if needed
            if (json['patient_name'] != null && json['patient_name'].toString().isNotEmpty) {
              final existingPatient = _getPatient(appt.patientId);
              if (existingPatient == null) {
                _patients.add(PatientModel(
                  id: appt.patientId,
                  parentId: _parentId,
                  patientCode: json['patient_code'] ?? 'PAT-${appt.patientId}',
                  profileImage: json['patient_image'] ?? '',
                  fullName: json['patient_name'],
                  age: 0,
                  gender: '',
                  dateOfBirth: '',
                  phone: json['patient_phone'] ?? '',
                  email: '',
                  address: '',
                  medicalConditions: [],
                  emergencyContactName: '',
                  emergencyContactPhone: '',
                  totalVisits: 0,
                  lastVisitDate: '',
                  createdBy: _doctorId,
                  status: true,
                  createdAt: '',
                  updatedAt: '',
                ));
              }
            }
            return appt;
          }).toList();
        }
      }
    } catch (_) {}

    // Sort by date ascending
    fetchedAppts.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

    if (mounted) {
      setState(() {
        _appointments = fetchedAppts;
        _isLoading = false;
      });
    }
  }

  PatientModel? _getPatient(int id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(days: 7)),
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
        _selectedRange = 'custom';
        _customDateRange = picked;
        _isLoading = true;
      });
      await _fetchAppointmentsForRange();
    }
  }

  // Group appointments into Section Headers
  Map<String, List<AppointmentModel>> _groupAppointments() {
    final Map<String, List<AppointmentModel>> groups = {};

    final filteredAppts = _appointments.where((appt) {
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final patient = _getPatient(appt.patientId);
        final patientName = (patient?.fullName ?? '').toLowerCase();
        final patientCode = (patient?.patientCode ?? '').toLowerCase();
        final procedure = appt.procedureText.toLowerCase();
        if (!patientName.contains(query) && !patientCode.contains(query) && !procedure.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

    for (final appt in filteredAppts) {
      String dateKey = 'Upcoming';
      if (appt.appointmentDate.length >= 10) {
        final dateStr = appt.appointmentDate.substring(0, 10);
        if (dateStr == todayStr) {
          dateKey = 'Today — ${_formatDate(now)}';
        } else if (dateStr == tomorrowStr) {
          dateKey = 'Tomorrow — ${_formatDate(tomorrow)}';
        } else {
          try {
            final dt = DateTime.parse(dateStr);
            dateKey = _formatDate(dt);
          } catch (_) {
            dateKey = dateStr;
          }
        }
      }
      groups.putIfAbsent(dateKey, () => []).add(appt);
    }

    return groups;
  }

  void _openDetailScreen(AppointmentModel appt, PatientModel? patient) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailScreen(
          appointment: appt,
          patient: patient,
          doctorId: _doctorId,
          parentId: _parentId,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final groups = _groupAppointments();
    final hasAppointments = groups.values.any((list) => list.isNotEmpty);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Appointments Scheduler', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.primarySlate,
      ),
      body: Column(
        children: [
          // 1. Search Input Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by patient name, code, or procedure...',
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. Range Filter Chips Row
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Today', 'today'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Tomorrow', 'tomorrow'),
                  const SizedBox(width: 8),
                  _buildFilterChip('This week', 'week'),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    _selectedRange == 'custom' && _customDateRange != null
                        ? '${_formatDate(_customDateRange!.start).substring(0, 6)} - ${_formatDate(_customDateRange!.end).substring(0, 6)}'
                        : 'Custom',
                    'custom',
                    icon: Icons.date_range_outlined,
                  ),
                ],
              ),
            ),
          ),

          // 3. Appointments Content with AnimatedSwitcher
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _isLoading
                  ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator(color: AppTheme.tealAccent))
                  : !hasAppointments
                      ? Center(
                          key: ValueKey('empty_${_selectedRange}_$_searchQuery'),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 64, color: AppTheme.secondarySlate.withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No appointments matching "$_searchQuery".'
                                    : 'No appointments scheduled for this filter.',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondarySlate),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          key: ValueKey('list_${_selectedRange}_${_appointments.length}'),
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
                                        color: title.startsWith('Today')
                                            ? AppTheme.tealAccent
                                            : AppTheme.primarySlate,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  ...list.map((appt) {
                                    final patient = _getPatient(appt.patientId);
                                    return _AppointmentCardItem(
                                      appointment: appt,
                                      patient: patient,
                                      onTap: () => _openDetailScreen(appt, patient),
                                    );
                                  }),
                                  const SizedBox(height: 12),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String key, {IconData? icon}) {
    final isSelected = _selectedRange == key;
    return ChoiceChip(
      avatar: icon != null ? Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.secondarySlate) : null,
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: isSelected ? Colors.white : AppTheme.primarySlate,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.tealAccent,
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) {
        if (key == 'custom') {
          _pickDateRange(context);
        } else if (val && _selectedRange != key) {
          setState(() {
            _selectedRange = key;
            _isLoading = true;
          });
          _fetchAppointmentsForRange();
        }
      },
    );
  }
}

/// Simplified Appointment Card Item with tap scale feedback and clamped procedure text.
class _AppointmentCardItem extends StatefulWidget {
  final AppointmentModel appointment;
  final PatientModel? patient;
  final VoidCallback onTap;

  const _AppointmentCardItem({
    required this.appointment,
    required this.patient,
    required this.onTap,
  });

  @override
  State<_AppointmentCardItem> createState() => _AppointmentCardItemState();
}

class _AppointmentCardItemState extends State<_AppointmentCardItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final patientName = widget.patient?.fullName ?? 'Patient #${widget.appointment.patientId}';
    final patientCode = widget.patient?.patientCode ?? 'PAT-${widget.appointment.patientId}';

    String displayTime = '10:00 AM';
    if (widget.appointment.appointmentDate.length >= 16) {
      try {
        final dt = DateTime.parse(widget.appointment.appointmentDate);
        final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
        final minute = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        displayTime = '$hour:$minute $period';
      } catch (_) {
        displayTime = widget.appointment.appointmentDate.substring(11, 16);
      }
    }

    final isCompleted = widget.appointment.status.toLowerCase() == 'completed';
    final isCancelled = widget.appointment.status.toLowerCase() == 'cancelled';

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Card(
          margin: const EdgeInsets.only(bottom: 14),
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
                      child: Row(
                        children: [
                          Hero(
                            tag: 'patient_avatar_${widget.appointment.patientId}',
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFE0F2F1),
                              backgroundImage: (widget.patient?.profileImage.isNotEmpty ?? false)
                                  ? NetworkImage(widget.patient!.profileImage)
                                  : null,
                              child: (widget.patient?.profileImage.isEmpty ?? true)
                                  ? Text(
                                      patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.tealAccent),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patientName,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primarySlate,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Code: $patientCode • Date: ${widget.appointment.appointmentDate.substring(0, 10)}',
                                  style: textTheme.bodySmall?.copyWith(color: AppTheme.secondarySlate, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Time Badge Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.emeraldSuccess.withValues(alpha: 0.12)
                            : isCancelled
                                ? AppTheme.redDestructive.withValues(alpha: 0.12)
                                : AppTheme.tealAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        displayTime,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isCompleted
                              ? AppTheme.emeraldSuccess
                              : isCancelled
                                  ? AppTheme.redDestructive
                                  : AppTheme.tealAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.appointment.procedureText.trim().isNotEmpty) ...[
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  Text(
                    'Procedure: ${widget.appointment.procedureText}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primarySlate,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
