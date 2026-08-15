import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment_model.dart';
import '../models/patient_model.dart';
import '../services/appointment_service.dart';
import '../services/patient_service.dart';
import '../theme/app_theme.dart';
import '../widgets/patient_identity_strip.dart';
import 'patient_details_screen.dart';

/// Screen allowing doctors to view, reschedule, edit status/procedure, or delete an appointment.
class AppointmentDetailScreen extends StatefulWidget {
  final AppointmentModel appointment;
  final PatientModel? patient;
  final int doctorId;
  final int parentId;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
    this.patient,
    required this.doctorId,
    required this.parentId,
  });

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _status;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late TextEditingController _procedureController;

  PatientModel? _patient;
  bool _isLoadingPatient = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isSubUser = false;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _loadUserProfile();

    // Parse appointment datetime
    DateTime parsedDt;
    try {
      parsedDt = DateTime.parse(widget.appointment.appointmentDate);
    } catch (_) {
      parsedDt = DateTime.now();
    }
    _selectedDate = parsedDt;
    _selectedTime = TimeOfDay.fromDateTime(parsedDt);
    _status = widget.appointment.status.isEmpty ? 'Pending' : widget.appointment.status;
    _procedureController = TextEditingController(text: widget.appointment.procedureText);

    if (_patient == null) {
      _fetchPatientDetails();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileStr = prefs.getString('user_profile');
      if (profileStr != null) {
        final profile = jsonDecode(profileStr);
        if (mounted) {
          setState(() {
            _isSubUser = profile['isSubUser'] == true;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _procedureController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatientDetails() async {
    setState(() {
      _isLoadingPatient = true;
    });

    try {
      // 1. Try single appointment detail endpoint first
      final detailRes = await AppointmentService.getAppointmentDetail(widget.appointment.id).timeout(const Duration(seconds: 5));
      if (detailRes.statusCode == 200) {
        final data = jsonDecode(detailRes.body);
        if (data['statusCode'] == 200 && data['body'] != null) {
          final body = data['body'];
          setState(() {
            _patient = PatientModel(
              id: widget.appointment.patientId,
              parentId: widget.parentId,
              patientCode: body['patient_code'] ?? 'PAT-${widget.appointment.patientId}',
              profileImage: body['patient_image'] ?? '',
              fullName: body['patient_name'] ?? 'Patient #${widget.appointment.patientId}',
              age: body['patient_age'] is int ? body['patient_age'] : int.tryParse(body['patient_age']?.toString() ?? ''),
              gender: body['patient_gender'] ?? '',
              dateOfBirth: '',
              phone: body['patient_phone'] ?? '',
              email: '',
              address: '',
              medicalConditions: [],
              emergencyContactName: '',
              emergencyContactPhone: '',
              totalVisits: 0,
              lastVisitDate: '',
              createdBy: widget.doctorId,
              status: true,
              createdAt: '',
              updatedAt: '',
            );
          });
          setState(() => _isLoadingPatient = false);
          return;
        }
      }
    } catch (_) {}

    // 2. Fallback to patient list endpoint
    try {
      final response = await PatientService.getPatients(widget.parentId).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['statusCode'] == 200 && responseData['body'] is List) {
          final list = responseData['body'] as List;
          final patients = list.map((json) => PatientModel.fromJson(json)).toList();
          final matched = patients.firstWhere((p) => p.id == widget.appointment.patientId);
          setState(() {
            _patient = matched;
          });
        }
      }
    } catch (_) {}

    setState(() {
      _isLoadingPatient = false;
    });
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final timeStr = ' ${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';
    final fullDateTimeStr = '$dateStr$timeStr';

    bool success = false;
    try {
      final response = await AppointmentService.updateAppointment({
        'id': widget.appointment.id,
        'appointmentDate': fullDateTimeStr,
        'procedureText': _procedureController.text.trim(),
        'status': _status,
      }).timeout(const Duration(seconds: 8));

      success = response.statusCode == 200;
    } catch (_) {}

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Appointment changes saved successfully.' : 'Failed to save changes.'),
          backgroundColor: success ? AppTheme.emeraldSuccess : AppTheme.redDestructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (success) {
        Navigator.pop(context, true); // Return true to indicate list needs refresh
      }
    }
  }

  Future<void> _confirmAndDelete() async {
    if (_isSubUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only Admin has permission to delete appointments.'),
          backgroundColor: AppTheme.redDestructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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

    setState(() {
      _isDeleting = true;
    });

    bool success = false;
    try {
      final response = await AppointmentService.deleteAppointment(widget.appointment.id)
          .timeout(const Duration(seconds: 8));
      success = response.statusCode == 200;
    } catch (_) {}

    setState(() {
      _isDeleting = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Appointment deleted.' : 'Failed to delete appointment.'),
          backgroundColor: success ? AppTheme.emeraldSuccess : AppTheme.redDestructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (success) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final fallbackPatient = PatientModel(
      id: widget.appointment.patientId,
      parentId: widget.parentId,
      patientCode: 'PAT-${widget.appointment.patientId}',
      profileImage: '',
      fullName: 'Patient #${widget.appointment.patientId}',
      age: 0,
      gender: '',
      dateOfBirth: '',
      phone: '',
      email: '',
      address: '',
      medicalConditions: [],
      emergencyContactName: '',
      emergencyContactPhone: '',
      totalVisits: 0,
      lastVisitDate: '',
      createdBy: widget.doctorId,
      status: true,
      createdAt: '',
      updatedAt: '',
    );

    final displayPatient = _patient ?? fallbackPatient;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Appointment Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.primarySlate,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Patient Identity Strip
              if (_isLoadingPatient)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.tealAccent)),
                  ),
                )
              else
                PatientIdentityStrip(
                  patient: displayPatient,
                  onTap: () {
                    if (_patient != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PatientDetailsScreen(patient: _patient!),
                        ),
                      );
                    }
                  },
                ),
              const SizedBox(height: 20),

              // 2. Editable Form Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appointment Status',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondarySlate,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Status Segmented Control
                      Row(
                        children: ['Pending', 'Completed', 'Cancelled'].map((st) {
                          final isSelected = _status.toLowerCase() == st.toLowerCase();
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Center(
                                  child: Text(
                                    st,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isSelected ? Colors.white : AppTheme.primarySlate,
                                    ),
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: st == 'Completed'
                                    ? AppTheme.emeraldSuccess
                                    : st == 'Cancelled'
                                        ? AppTheme.redDestructive
                                        : AppTheme.tealAccent,
                                backgroundColor: const Color(0xFFF1F5F9),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                onSelected: (val) {
                                  if (val) {
                                    setState(() {
                                      _status = st;
                                    });
                                  }
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const Divider(height: 32, color: Color(0xFFF1F5F9)),

                      // Date & Time Picker Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.secondarySlate,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_month_outlined, size: 18, color: AppTheme.tealAccent),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _formatDate(_selectedDate),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primarySlate),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time Slot',
                                  style: textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.secondarySlate,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _pickTime,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time_outlined, size: 18, color: AppTheme.tealAccent),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _formatTime(_selectedTime),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primarySlate),
                                          ),
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
                      const SizedBox(height: 24),

                      // Procedure Text Input
                      Text(
                        'Advised Procedure / Notes',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondarySlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _procedureController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Enter procedure or consultation details...',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Procedure text is required';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 3. Action Buttons Row
              Row(
                children: [
                  if (!_isSubUser) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isDeleting || _isSaving ? null : _confirmAndDelete,
                        icon: _isDeleting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppTheme.redDestructive, strokeWidth: 2))
                            : const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.redDestructive,
                          side: const BorderSide(color: AppTheme.redDestructive),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    flex: !_isSubUser ? 2 : 1,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving || _isDeleting ? null : _saveChanges,
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tealAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
