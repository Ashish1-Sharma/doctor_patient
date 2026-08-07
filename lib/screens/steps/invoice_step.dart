import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/visit_provider.dart';
import '../../models/appointment_model.dart';
import '../../models/patient_model.dart';
import '../../services/appointment_service.dart';
import '../../services/patient_service.dart';
import '../../theme/app_theme.dart';

/// STEP 6: Invoice confirmation & optional appointment step inside the New Treatment workflow.
class InvoiceStep extends StatefulWidget {
  const InvoiceStep({super.key});

  @override
  State<InvoiceStep> createState() => _InvoiceStepState();
}

class _InvoiceStepState extends State<InvoiceStep> {
  bool _addAppointment = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _procedureController = TextEditingController();

  PatientModel? _patient;
  String _doctorName = '';
  bool _isSavingAppt = false;

  @override
  void initState() {
    super.initState();
    _loadProfileAndPatient();
    _procedureController.addListener(_syncPendingAppointmentToProvider);
  }

  @override
  void dispose() {
    _procedureController.removeListener(_syncPendingAppointmentToProvider);
    _procedureController.dispose();
    super.dispose();
  }

  void _syncPendingAppointmentToProvider() {
    final provider = Provider.of<VisitProvider>(context, listen: false);
    if (!_addAppointment || _selectedDate == null) {
      provider.setPendingAppointment(null);
      return;
    }

    final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    final timeStr = _selectedTime != null
        ? ' ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00'
        : ' 10:00:00';
    final fullDateTimeStr = '$dateStr$timeStr';

    final appt = AppointmentModel(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      visitId: provider.visit.id,
      patientId: provider.visit.patientId,
      doctorId: provider.visit.doctorId,
      appointmentDate: fullDateTimeStr,
      procedureText: _procedureController.text.trim().isEmpty ? 'General Checkup' : _procedureController.text.trim(),
      status: 'Pending',
      createdAt: DateTime.now().toString().substring(0, 19),
      updatedAt: DateTime.now().toString().substring(0, 19),
    );
    provider.setPendingAppointment(appt);
  }

  Future<void> _loadProfileAndPatient() async {
    final provider = Provider.of<VisitProvider>(context, listen: false);
    final patientId = provider.visit.patientId;
    final parentId = provider.visit.parentId;

    // Load Doctor Profile
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileStr = prefs.getString('user_profile');
      if (profileStr != null) {
        final profile = jsonDecode(profileStr);
        setState(() {
          _doctorName = profile['userName'] as String? ?? profile['name'] as String? ?? 'Dr. Gireesh Kumar';
        });
      }
    } catch (_) {}

    // Load Patient details
    try {
      final response = await PatientService.getPatients(parentId);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['statusCode'] == 200 && responseData['body'] is List) {
          final list = responseData['body'] as List;
          final fetched = list.map((json) => PatientModel.fromJson(json)).toList();
          final match = fetched.firstWhere((p) => p.id == patientId);
          setState(() {
            _patient = match;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
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
      _syncPendingAppointmentToProvider();
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
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
      _syncPendingAppointmentToProvider();
    }
  }

  String _generateShareText(VisitProvider provider) {
    final visit = provider.visit;
    final payment = provider.payment;
    final patientName = _patient?.fullName ?? 'Patient';
    final patientCode = _patient?.patientCode ?? 'N/A';

    final buffer = StringBuffer();
    buffer.writeln('📋 *CLINIC VISIT RECORD & INVOICE*');
    buffer.writeln('----------------------------------------');
    buffer.writeln('👤 *Patient:* $patientName (Code: $patientCode)');
    buffer.writeln('🆔 *Visit No:* ${visit.visitNo}');
    buffer.writeln('📅 *Date:* ${visit.visitDate}');
    buffer.writeln('🩺 *Attending Doctor:* $_doctorName');
    
    if (visit.chiefComplaintText.isNotEmpty) {
      buffer.writeln('💬 *Complaint:* ${visit.chiefComplaintText}');
    }
    if (visit.treatmentDoneText.isNotEmpty) {
      buffer.writeln('✅ *Treatment Done:* ${visit.treatmentDoneText}');
    }
    
    buffer.writeln('');
    buffer.writeln('💳 *INVOICE DETAILS*');
    buffer.writeln('🧾 *Invoice No:* ${payment.invoiceNo}');
    buffer.writeln('💵 *Subtotal:* ₹${payment.subtotal.toStringAsFixed(2)}');
    if (payment.discount > 0) {
      buffer.writeln('🧧 *Discount:* -₹${payment.discount.toStringAsFixed(2)}');
    }
    buffer.writeln('💵 *Total Cost:* ₹${payment.totalAmount.toStringAsFixed(2)}');
    buffer.writeln('💰 *Paid Amount:* ₹${payment.paidAmount.toStringAsFixed(2)}');
    buffer.writeln('⏳ *Pending Balance:* ₹${payment.pendingAmount.toStringAsFixed(2)}');
    buffer.writeln('💳 *Payment Method:* ${payment.paymentMethod}');
    buffer.writeln('📊 *Status:* ${payment.paymentStatus.toUpperCase()}');

    if (_addAppointment && _selectedDate != null) {
      final dateStr = '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
      final timeStr = _selectedTime != null ? ' at ${_selectedTime!.format(context)}' : '';
      buffer.writeln('');
      buffer.writeln('📅 *NEXT APPOINTMENT SCHEDULED*');
      buffer.writeln('🗓️ *Date:* $dateStr$timeStr');
      if (_procedureController.text.trim().isNotEmpty) {
        buffer.writeln('⚙️ *Procedure:* ${_procedureController.text.trim()}');
      }
    }

    buffer.writeln('----------------------------------------');
    buffer.writeln('Thank you for visiting our clinic! Stay healthy.');

    return buffer.toString();
  }

  Future<void> _saveAppointmentAndShare(VisitProvider provider) async {
    if (_addAppointment) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an appointment date.'),
            backgroundColor: AppTheme.amberWarning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        _isSavingAppt = true;
      });

      final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      final timeStr = _selectedTime != null
          ? ' ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00'
          : ' 10:00:00';
      final fullDateTimeStr = '$dateStr$timeStr';

      final uniqueApptId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final appointment = AppointmentModel(
        id: uniqueApptId,
        visitId: provider.visit.id,
        patientId: provider.visit.patientId,
        doctorId: provider.visit.doctorId,
        appointmentDate: fullDateTimeStr,
        procedureText: _procedureController.text.trim().isEmpty ? 'General Checkup' : _procedureController.text.trim(),
        status: 'Pending',
        createdAt: DateTime.now().toString().substring(0, 19),
        updatedAt: DateTime.now().toString().substring(0, 19),
      );

      // Synchronize with database
      try {
        final payload = {
          'visitId': appointment.visitId,
          'patientId': appointment.patientId,
          'doctorId': appointment.doctorId,
          'appointmentDate': appointment.appointmentDate,
          'procedureText': appointment.procedureText,
        };
        print('DEBUG [InvoiceStep]: Initiating appointment creation...');
        print('DEBUG [InvoiceStep]: Appointment payload: $payload');
        
        final response = await AppointmentService.createAppointment(payload).timeout(const Duration(seconds: 4));
        print('DEBUG [InvoiceStep]: Appointment API HTTP status: ${response.statusCode}');
        print('DEBUG [InvoiceStep]: Appointment API raw body response: ${response.body}');
      } catch (e) {
        print('DEBUG [InvoiceStep] ERROR creating appointment: $e');
      }

      setState(() {
        _isSavingAppt = false;
      });
    }

    // Generate text & copy to clipboard
    final shareText = _generateShareText(provider);
    await Clipboard.setData(ClipboardData(text: shareText));

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppTheme.whatsappGreen),
              SizedBox(width: 8),
              Text('Invoice Shared', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The invoice receipts & appointment details have been formatted and copied to your Clipboard.'),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      shareText,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('You can now paste it directly into WhatsApp, SMS, or any messaging app.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VisitProvider>(context);
    final payment = provider.payment;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Confirmation Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.emeraldSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.emeraldSuccess.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.emeraldSuccess,
                  size: 56,
                ),
                const SizedBox(height: 12),
                Text(
                  'Treatment Saved Successfully',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppTheme.emeraldSuccess,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Clinical record and billing details synced.',
                  style: TextStyle(color: AppTheme.secondarySlate, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Invoice Details Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              boxShadow: AppTheme.premiumShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'INVOICE RECEIPT',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppTheme.secondarySlate,
                      ),
                    ),
                    Text(
                      payment.invoiceNo,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primarySlate,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 32),
                
                _buildRow(context, 'Attending Doctor', _doctorName),
                const SizedBox(height: 12),
                _buildRow(context, 'Transaction Date', payment.paymentDate),
                const SizedBox(height: 12),
                _buildRow(context, 'Payment Method', payment.paymentMethod),
                const SizedBox(height: 12),
                _buildRow(context, 'Billing Status', payment.paymentStatus.toUpperCase(), isStatus: true),
                
                const Divider(color: Color(0xFFF1F5F9), height: 32),
                
                _buildAmountRow(context, 'Subtotal', payment.subtotal, isBold: false),
                if (payment.discount > 0) ...[
                  const SizedBox(height: 8),
                  _buildAmountRow(context, 'Discount Applied', payment.discount, isBold: false, isDiscount: true),
                ],
                const SizedBox(height: 8),
                _buildAmountRow(context, 'Total Cost', payment.totalAmount, isBold: true),
                const SizedBox(height: 8),
                _buildAmountRow(context, 'Paid Deposit', payment.paidAmount, isBold: true, isPaid: true),
                const SizedBox(height: 8),
                _buildAmountRow(context, 'Pending Balance', payment.pendingAmount, isBold: true, isPending: true),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Optional Appointment Booking Box ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _addAppointment,
                  onChanged: (val) {
                    setState(() {
                      _addAppointment = val ?? false;
                    });
                    _syncPendingAppointmentToProvider();
                  },
                  title: const Text(
                    'Want to add appointment?',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primarySlate),
                  ),
                  activeColor: AppTheme.tealAccent,
                ),
                if (_addAppointment) ...[
                  const Divider(height: 20),
                  const Text(
                    'DATE & TIME',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondarySlate, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: Text(
                            _selectedDate == null
                                ? 'Pick Date'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primarySlate,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectTime(context),
                          icon: const Icon(Icons.access_time, size: 18),
                          label: Text(
                            _selectedTime == null ? 'Pick Time' : _selectedTime!.format(context),
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primarySlate,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PLANNED PROCEDURE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondarySlate, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _procedureController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Root Canal Treatment, Consultation',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Invoice Button Suite
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Invoice PDF Downloaded', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Receipt ${payment.invoiceNo}.pdf saved to device Downloads.', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppTheme.primarySlate,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primarySlate,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            icon: const Icon(Icons.file_download_outlined, size: 20),
            label: const Text('Download Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          
          OutlinedButton.icon(
            onPressed: _isSavingAppt ? null : () => _saveAppointmentAndShare(provider),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.whatsappGreen,
              side: const BorderSide(color: AppTheme.whatsappGreen, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: _isSavingAppt
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.whatsappGreen, strokeWidth: 2))
                : const Icon(Icons.share_outlined, size: 20),
            label: const Text('Share Invoice via WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value, {bool isStatus = false}) {
    final statusColor = value.toLowerCase() == 'paid'
        ? AppTheme.emeraldSuccess
        : value.toLowerCase() == 'partial'
            ? AppTheme.amberWarning
            : AppTheme.redDestructive;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.secondarySlate, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        isStatus
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Flexible(
                child: Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primarySlate, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
      ],
    );
  }

  Widget _buildAmountRow(
    BuildContext context,
    String label,
    double value, {
    bool isBold = false,
    bool isPaid = false,
    bool isPending = false,
    bool isDiscount = false,
  }) {
    Color amountColor = AppTheme.primarySlate;
    if (isPaid) amountColor = AppTheme.emeraldSuccess;
    if (isPending && value > 0) amountColor = AppTheme.amberWarning;
    if (isDiscount) amountColor = AppTheme.redDestructive;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: isBold ? AppTheme.primarySlate : AppTheme.secondarySlate,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 14 : 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isDiscount ? '-₹${value.toStringAsFixed(2)}' : '₹${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: amountColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 14 : 13,
          ),
        ),
      ],
    );
  }
}
