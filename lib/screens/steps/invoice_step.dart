import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/visit_provider.dart';
import '../../theme/app_theme.dart';

/// STEP 6: Invoice confirmation step inside the New Treatment workflow.
class InvoiceStep extends StatelessWidget {
  const InvoiceStep({super.key});

  void _showMockAction(BuildContext context, String title, String detail, Color color) {
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(detail, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
                
                _buildRow(context, 'Attending Doctor', 'Dr. Gireesh Kumar'),
                const SizedBox(height: 12),
                _buildRow(context, 'Transaction Date', payment.paymentDate),
                const SizedBox(height: 12),
                _buildRow(context, 'Payment Method', payment.paymentMethod),
                const SizedBox(height: 12),
                _buildRow(context, 'Billing Status', payment.paymentStatus.toUpperCase(), isStatus: true),
                
                const Divider(color: Color(0xFFF1F5F9), height: 32),
                
                _buildAmountRow(context, 'Subtotal', payment.subtotal, isBold: false),
                const SizedBox(height: 8),
                _buildAmountRow(context, 'Total Cost', payment.totalAmount, isBold: true),
                const SizedBox(height: 8),
                _buildAmountRow(context, 'Paid Deposit', payment.paidAmount, isBold: true, isPaid: true),
                const SizedBox(height: 8),
                _buildAmountRow(context, 'Pending Balance', payment.pendingAmount, isBold: true, isPending: true),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          // Invoice Button Suite
          ElevatedButton.icon(
            onPressed: () => _showMockAction(
              context,
              'Invoice PDF Downloaded',
              'Receipt ${payment.invoiceNo}.pdf saved to device Downloads.',
              AppTheme.primarySlate,
            ),
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
            onPressed: () => _showMockAction(
              context,
              'Receipt Link Generated',
              'Share card prepared for WhatsApp / SMS messaging.',
              AppTheme.whatsappGreen,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.whatsappGreen,
              side: const BorderSide(color: AppTheme.whatsappGreen, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.share_outlined, size: 20),
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
        Text(label, style: const TextStyle(color: AppTheme.secondarySlate, fontSize: 13)),
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
            : Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primarySlate, fontSize: 13),
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
  }) {
    Color amountColor = AppTheme.primarySlate;
    if (isPaid) amountColor = AppTheme.emeraldSuccess;
    if (isPending && value > 0) amountColor = AppTheme.amberWarning;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? AppTheme.primarySlate : AppTheme.secondarySlate,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 14 : 13,
          ),
        ),
        Text(
          '₹${value.toStringAsFixed(2)}',
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
