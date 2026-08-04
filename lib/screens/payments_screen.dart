import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_model.dart';
import '../models/patient_model.dart';
import '../services/patient_service.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';

/// Screen listing all invoices sorted by updatedAt, allowing doctors to update status and paid amounts.
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  bool _isLoading = true;
  List<PaymentModel> _payments = [];
  List<PatientModel> _patients = [];
  int _parentId = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileStr = prefs.getString('user_profile');
      if (profileStr != null) {
        final profile = jsonDecode(profileStr);
        final rawId = profile['id'];
        final doctorId = rawId is int ? rawId : (rawId != null ? int.tryParse(rawId.toString()) : null);
        final isSubUser = profile['isSubUser'] == true;
        _parentId = isSubUser
            ? (profile['parentId'] ?? profile['mainAccountId'] ?? doctorId ?? 1)
            : (doctorId ?? 1);
      }
    } catch (_) {}

    // Load patients
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

    // Load payments from API
    try {
      final response = await PaymentService.getPayments(_parentId).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['statusCode'] == 200 && responseData['body'] is List) {
          final list = responseData['body'] as List;
          final apiPayments = list.map((json) => PaymentModel.fromJson(json)).toList();
          // Sort by updatedAt descending
          apiPayments.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          setState(() {
            _payments = apiPayments;
          });
        }
      }
    } catch (_) {}

    setState(() {
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



  void _showEditPaymentSheet(PaymentModel payment) {
    final formKey = GlobalKey<FormState>();
    final paidController = TextEditingController(text: payment.paidAmount.toStringAsFixed(0));
    double updatedPaid = payment.paidAmount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Update Payment status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Invoice Receipt: ${payment.invoiceNo}',
                    style: const TextStyle(color: AppTheme.secondarySlate, fontSize: 13),
                  ),
                  const Divider(height: 28, color: Color(0xFFF1F5F9)),
                  Text(
                    'Total Invoice Cost: ₹${payment.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primarySlate),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: paidController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Paid Amount (₹)',
                      hintText: 'Enter amount paid',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Paid amount is required';
                      final parsed = double.tryParse(val.trim());
                      if (parsed == null || parsed < 0) return 'Enter a valid amount';
                      if (parsed > payment.totalAmount) return 'Paid amount cannot exceed total';
                      return null;
                    },
                    onChanged: (val) {
                      updatedPaid = double.tryParse(val.trim()) ?? payment.paidAmount;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final pending = payment.totalAmount - updatedPaid;
                        String status = 'Pending';
                        if (pending <= 0) {
                          status = 'Paid';
                        } else if (updatedPaid > 0) {
                          status = 'Partial';
                        }

                        bool success = false;
                        try {
                          final response = await PaymentService.updatePaymentDetails({
                            'id': payment.id,
                            'paidAmount': updatedPaid,
                            'pendingAmount': pending < 0 ? 0.0 : pending,
                            'paymentStatus': status,
                            'remarks': pending > 0
                                ? 'Balance ₹${pending.toStringAsFixed(0)} pending.'
                                : 'Fully paid.',
                          }).timeout(const Duration(seconds: 5));
                          if (response.statusCode == 200) {
                            success = true;
                          }
                        } catch (_) {}

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Invoice payment details updated successfully.'
                                  : 'Failed to update details. Check server connection.'),
                              backgroundColor: success ? AppTheme.emeraldSuccess : AppTheme.redDestructive,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          _loadData();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tealAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMockDownload(PaymentModel payment) {
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
  }

  Color _getStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'paid':
        return AppTheme.emeraldSuccess;
      case 'partial':
        return AppTheme.amberWarning;
      default:
        return AppTheme.redDestructive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Payments Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.primarySlate,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent))
          : _payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.secondarySlate.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text(
                        'No invoices recorded yet.',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondarySlate),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.tealAccent,
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final payment = _payments[index];
                      final patient = _getPatient(payment.patientId);
                      final patientName = patient?.fullName ?? 'Unknown Patient';
                      final patientCode = patient?.patientCode ?? 'N/A';
                      final statusColor = _getStatusColor(payment.paymentStatus);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      payment.paymentStatus.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Code: $patientCode • Invoice: ${payment.invoiceNo}',
                                style: textTheme.bodySmall?.copyWith(color: AppTheme.secondarySlate),
                              ),
                              const Divider(height: 24, color: Color(0xFFF1F5F9)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Total Cost', style: TextStyle(color: AppTheme.secondarySlate, fontSize: 11)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${payment.totalAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primarySlate, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Paid Deposit', style: TextStyle(color: AppTheme.secondarySlate, fontSize: 11)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${payment.paidAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Pending Bal.', style: TextStyle(color: AppTheme.secondarySlate, fontSize: 11)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${payment.pendingAmount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: payment.pendingAmount > 0 ? AppTheme.amberWarning : AppTheme.emeraldSuccess,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 24, color: Color(0xFFF1F5F9)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Updated: ${payment.updatedAt}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.secondarySlate),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.file_download_outlined, color: AppTheme.primarySlate),
                                        onPressed: () => _showMockDownload(payment),
                                        tooltip: 'Download Invoice',
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _showEditPaymentSheet(payment),
                                        icon: const Icon(Icons.edit, size: 14),
                                        label: const Text('Update Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.tealAccent.withValues(alpha: 0.12),
                                          foregroundColor: AppTheme.tealAccent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
