import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/visit_provider.dart';
import '../../theme/app_theme.dart';

/// STEP 5: Payment details step inside the New Treatment workflow.
class PaymentStep extends StatefulWidget {
  const PaymentStep({super.key});

  @override
  State<PaymentStep> createState() => _PaymentStepState();
}

class _PaymentStepState extends State<PaymentStep> {
  final _formKey = GlobalKey<FormState>();
  final _totalController = TextEditingController();
  final _paidController = TextEditingController();
  String _paymentMethod = 'UPI';

  double _total = 0.0;
  double _paid = 0.0;

  @override
  void initState() {
    super.initState();
    // Load existing form state from VisitProvider
    final provider = Provider.of<VisitProvider>(context, listen: false);
    _paymentMethod = provider.payment.paymentMethod.isEmpty ? 'UPI' : provider.payment.paymentMethod;
    _total = provider.payment.totalAmount;
    _paid = provider.payment.paidAmount;

    if (_total > 0) _totalController.text = _total.toStringAsFixed(0);
    if (_paid > 0) _paidController.text = _paid.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _totalController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  void _syncToProvider() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<VisitProvider>(context, listen: false);
      provider.updatePayment(
        total: _total,
        paid: _paid,
        method: _paymentMethod,
      );
    }
  }

  double get pending => _total - _paid;

  String get calculatedStatus {
    final bal = pending;
    if (bal <= 0) return 'Paid';
    if (_paid > 0) return 'Partial';
    return 'Pending';
  }

  Color get statusColor {
    switch (calculatedStatus) {
      case 'Paid':
        return AppTheme.emeraldSuccess;
      case 'Partial':
        return AppTheme.amberWarning;
      default:
        return AppTheme.redDestructive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Billing & Payments',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primarySlate,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Input procedure costs, paid deposits, and select transaction methods.',
              style: TextStyle(color: AppTheme.secondarySlate, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Billing Card
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
                        'Payment Details',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      // Dynamic Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          calculatedStatus.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Total Amount Input
                  Row(
                    children: [
                      Text('Total Amount', style: textTheme.labelLarge),
                      const SizedBox(width: 4),
                      const Text('*', style: TextStyle(color: AppTheme.redDestructive, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _totalController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      setState(() {
                        _total = double.tryParse(val.trim()) ?? 0.0;
                      });
                      _syncToProvider();
                    },
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      prefixIcon: Center(
                        widthFactor: 1.0,
                        child: Text('₹ ', style: TextStyle(color: AppTheme.secondarySlate, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Total amount is mandatory';
                      final parsed = double.tryParse(val.trim());
                      if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Paid Amount Input
                  Text('Paid Amount', style: textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _paidController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      setState(() {
                        _paid = double.tryParse(val.trim()) ?? 0.0;
                      });
                      _syncToProvider();
                    },
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      prefixIcon: Center(
                        widthFactor: 1.0,
                        child: Text('₹ ', style: TextStyle(color: AppTheme.secondarySlate, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty) {
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null) return 'Enter a valid amount';
                        if (parsed > _total) return 'Paid amount cannot exceed total';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Auto Calculated Balance Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Outstanding Balance (Pending)',
                          style: TextStyle(
                            color: AppTheme.secondarySlate,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₹${(pending < 0 ? 0.0 : pending).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: pending > 0 ? AppTheme.amberWarning : AppTheme.emeraldSuccess,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Method Dropdown
                  Text('Payment Method', style: textTheme.labelLarge),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'UPI', child: Text('UPI (GPay / PhonePe / Paytm)')),
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Card', child: Text('Debit / Credit Card')),
                      DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer (NEFT/IMPS)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _paymentMethod = val;
                        });
                        _syncToProvider();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
