import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';
import '../theme/app_theme.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  final PatientModel patient;
  final List<AppointmentModel> appointments;
  final int doctorId;
  final VoidCallback? onRefresh;

  const PatientAppointmentsScreen({
    super.key,
    required this.patient,
    required this.appointments,
    required this.doctorId,
    this.onRefresh,
  });

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  late List<AppointmentModel> _localAppointments;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _localAppointments = List.from(widget.appointments);
  }

  Future<void> _confirmAndDeleteAppointment(AppointmentModel appointment) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Appointment?'),
        content: const Text('Are you sure you want to permanently delete this appointment slot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.secondarySlate)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              setState(() {
                _isLoading = true;
              });

              bool success = false;
              try {
                final response = await AppointmentService.deleteAppointment(appointment.id)
                    .timeout(const Duration(seconds: 8));
                success = response.statusCode == 200;
              } catch (_) {}

              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Appointment deleted successfully.' : 'Failed to delete appointment.'),
                    backgroundColor: success ? AppTheme.emeraldSuccess : AppTheme.redDestructive,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                
                if (success) {
                  setState(() {
                    _localAppointments.removeWhere((a) => a.id == appointment.id);
                  });
                  if (widget.onRefresh != null) {
                    widget.onRefresh!();
                  }
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.redDestructive, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Appointments',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primarySlate,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Patient Info Banner Card
                _buildPatientBanner(context, textTheme),
                
                // Appointments List
                Expanded(
                  child: _localAppointments.isEmpty
                      ? _buildEmptyState(textTheme)
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _localAppointments.length,
                          itemBuilder: (context, index) {
                            final appointment = _localAppointments[index];
                            return _buildAppointmentCard(context, appointment, textTheme);
                          },
                        ),
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black12,
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.tealAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientBanner(BuildContext context, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.tealAccent.withValues(alpha: 0.1),
            backgroundImage: widget.patient.profileImage.isNotEmpty
                ? NetworkImage(widget.patient.profileImage)
                : null,
            child: widget.patient.profileImage.isEmpty
                ? const Icon(Icons.person_outline, color: AppTheme.tealAccent, size: 28)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patient.fullName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primarySlate,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Code: ${widget.patient.patientCode} • Phone: ${widget.patient.phone}',
                  style: const TextStyle(
                    color: AppTheme.secondarySlate,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_localAppointments.length} Total',
              style: const TextStyle(
                color: Color(0xFF1565C0),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, AppointmentModel appt, TextTheme textTheme) {
    final statusColor = _getStatusColor(appt.status);
    final statusBgColor = _getStatusBgColor(appt.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date & Time Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, color: AppTheme.secondarySlate, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _formatApptDate(appt.appointmentDate),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primarySlate,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        appt.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.redDestructive, size: 20),
                      onPressed: () => _confirmAndDeleteAppointment(appt),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFE2E8F0)),

            // Procedure / Notes
            const Text(
              'Advised Procedure / Purpose',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondarySlate,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              appt.procedureText.trim().isEmpty ? 'General Consultation' : appt.procedureText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.primarySlate,
              ),
            ),

            const SizedBox(height: 12),
            // Time display
            Row(
              children: [
                const Icon(Icons.access_time_outlined, color: AppTheme.secondarySlate, size: 14),
                const SizedBox(width: 6),
                Text(
                  _formatApptTime(appt.appointmentDate),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondarySlate,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'completed':
        return AppTheme.emeraldSuccess;
      case 'cancelled':
        return AppTheme.redDestructive;
      case 'pending':
      default:
        return AppTheme.amberWarning;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'completed':
        return AppTheme.emeraldSuccess.withValues(alpha: 0.1);
      case 'cancelled':
        return AppTheme.redDestructive.withValues(alpha: 0.1);
      case 'pending':
      default:
        return AppTheme.amberWarning.withValues(alpha: 0.1);
    }
  }

  String _formatApptDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatApptTime(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      final hour = parsed.hour;
      final minute = parsed.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$formattedHour:$minute $period';
    } catch (_) {
      return '10:00 AM'; // default fallback
    }
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_busy_outlined, size: 48, color: Color(0xFF1565C0)),
            ),
            const SizedBox(height: 20),
            Text(
              'No Appointments Scheduled',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primarySlate),
            ),
            const SizedBox(height: 8),
            const Text(
              'All future and past appointment cards will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.secondarySlate, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
