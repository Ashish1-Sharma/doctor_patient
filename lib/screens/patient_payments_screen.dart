import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../models/payment_model.dart';
import '../theme/app_theme.dart';
import 'patient_visit_report_screen.dart';

class PatientPaymentsScreen extends StatelessWidget {
  final PatientModel patient;
  final List<PaymentModel> payments;

  const PatientPaymentsScreen({
    super.key,
    required this.patient,
    required this.payments,
  });

  double get _totalPaid {
    return payments.fold(0.0, (sum, item) => sum + item.paidAmount);
  }

  double get _totalPending {
    return payments.fold(0.0, (sum, item) => sum + item.pendingAmount);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Billing & Payments',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primarySlate,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Patient Info Banner Card
            _buildPatientBanner(context, textTheme),
            
            // Financial Summary Row
            _buildFinancialSummaryRow(textTheme),
            
            // Payments List
            Expanded(
              child: payments.isEmpty
                  ? _buildEmptyState(textTheme)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final payment = payments[index];
                        return _buildPaymentCard(context, payment, textTheme);
                      },
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.tealAccent.withValues(alpha: 0.1),
            backgroundImage: patient.profileImage.isNotEmpty
                ? NetworkImage(patient.profileImage)
                : null,
            child: patient.profileImage.isEmpty
                ? const Icon(Icons.person_outline, color: AppTheme.tealAccent, size: 24)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primarySlate,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Code: ${patient.patientCode} • Phone: ${patient.phone}',
                  style: const TextStyle(
                    color: AppTheme.secondarySlate,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryRow(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryBox(
              label: 'Total Paid',
              amount: _totalPaid,
              color: AppTheme.emeraldSuccess,
              bgColor: AppTheme.emeraldSuccess.withValues(alpha: 0.08),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryBox(
              label: 'Total Pending',
              amount: _totalPending,
              color: AppTheme.amberWarning,
              bgColor: AppTheme.amberWarning.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox({
    required String label,
    required double amount,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, PaymentModel payment, TextTheme textTheme) {
    final statusColor = _getStatusColor(payment.paymentStatus);
    final statusBgColor = _getStatusBgColor(payment.paymentStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice & status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_outlined, color: AppTheme.primarySlate, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      payment.invoiceNo,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primarySlate,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    payment.paymentStatus,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFE2E8F0)),

            // Date & Payment method
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppTheme.secondarySlate, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      payment.paymentDate.length >= 10
                          ? payment.paymentDate.substring(0, 10)
                          : payment.paymentDate,
                      style: const TextStyle(fontSize: 12, color: AppTheme.secondarySlate),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.payment, color: AppTheme.secondarySlate, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      payment.paymentMethod,
                      style: const TextStyle(fontSize: 12, color: AppTheme.secondarySlate, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Financial Breakdown row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInvoiceLine('Total Amount', payment.totalAmount, isBold: true),
                  const SizedBox(height: 6),
                  _buildInvoiceLine('Paid Amount', payment.paidAmount, color: AppTheme.emeraldSuccess),
                  if (payment.pendingAmount > 0) ...[
                    const SizedBox(height: 6),
                    _buildInvoiceLine('Pending Amount', payment.pendingAmount, color: AppTheme.amberWarning),
                  ],
                ],
              ),
            ),

            if (payment.remarks.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Remarks: ${payment.remarks}',
                style: const TextStyle(fontSize: 11, color: AppTheme.secondarySlate, fontStyle: FontStyle.italic),
              ),
            ],

            const SizedBox(height: 16),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientVisitReportScreen(
                          parentId: payment.parentId,
                          visitId: payment.visitId,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primarySlate,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('View Invoice PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceLine(String label, double value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: AppTheme.secondarySlate,
          ),
        ),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppTheme.primarySlate,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'paid':
        return AppTheme.emeraldSuccess;
      case 'partial':
        return AppTheme.amberWarning;
      case 'pending':
      default:
        return AppTheme.redDestructive;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'paid':
        return AppTheme.emeraldSuccess.withValues(alpha: 0.1);
      case 'partial':
        return AppTheme.amberWarning.withValues(alpha: 0.1);
      case 'pending':
      default:
        return AppTheme.redDestructive.withValues(alpha: 0.1);
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
                color: const Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.money_off_csred_outlined, size: 48, color: Color(0xFFEF6C00)),
            ),
            const SizedBox(height: 20),
            Text(
              'No Payment Records Found',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primarySlate),
            ),
            const SizedBox(height: 8),
            const Text(
              'Billing statement history will populate here once transactions occur.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.secondarySlate, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
