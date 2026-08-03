import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/visit_provider.dart';
import '../theme/app_theme.dart';
import 'steps/patient_selection_step.dart';
import 'steps/findings_step.dart';
import 'steps/lab_step.dart';
import 'steps/treatment_step.dart';
import 'steps/payment_step.dart';
import 'steps/invoice_step.dart';

/// The main NewTreatmentScreen coordinator, managing multi-step page views and validations.
class NewTreatmentScreen extends StatefulWidget {
  const NewTreatmentScreen({super.key});

  @override
  State<NewTreatmentScreen> createState() => _NewTreatmentScreenState();
}

class _NewTreatmentScreenState extends State<NewTreatmentScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final List<String> _stepTitles = [
    'Patient',
    'Findings',
    'Lab',
    'Treatment',
    'Payment',
    'Invoice',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.redDestructive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool _validateStep(int step, VisitProvider provider) {
    switch (step) {
      case 0:
        if (provider.visit.patientId == 0) {
          _showValidationError('Please select a patient to continue.');
          return false;
        }
        break;
      case 1:
        if (provider.visit.chiefComplaintText.trim().isEmpty) {
          _showValidationError('Chief Complaint is mandatory.');
          return false;
        }
        break;
      case 4:
        if (provider.payment.totalAmount <= 0) {
          _showValidationError('Total Amount is mandatory.');
          return false;
        }
        if (provider.payment.paidAmount > provider.payment.totalAmount) {
          _showValidationError('Paid Amount cannot exceed Total Amount.');
          return false;
        }
        break;
    }
    return true;
  }

  void _nextPage(VisitProvider provider) {
    if (_validateStep(_currentStep, provider)) {
      if (_currentStep < 5) {
        setState(() {
          _currentStep++;
        });
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishWorkflow(VisitProvider provider) {
    // Return the visit and payment back to the dashboard state
    Navigator.of(context).pop({
      'visit': provider.visit,
      'payment': provider.payment,
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VisitProvider>(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'New Treatment Record',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.primarySlate),
          onPressed: () {
            // Confirm cancel
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Discard Treatment?'),
                content: const Text('Are you sure you want to cancel and discard this treatment workflow?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('No, Continue'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Pop dialog
                      Navigator.pop(context); // Pop screen
                    },
                    child: const Text('Yes, Discard', style: TextStyle(color: AppTheme.redDestructive)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Premium Progress Indicator
              _buildProgressIndicator(),
              const SizedBox(height: 28),

              // Page Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Disable swiping
                  onPageChanged: (idx) {
                    setState(() {
                      _currentStep = idx;
                    });
                  },
                  children: const [
                    PatientSelectionStep(),
                    FindingsStep(),
                    LabStep(),
                    TreatmentStep(),
                    PaymentStep(),
                    InvoiceStep(),
                  ],
                ),
              ),

              // Fixed Bottom Navigation Bar
              _buildBottomNavigation(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_stepTitles.length, (index) {
            final isActive = index <= _currentStep;
            final isCurrent = index == _currentStep;

            return Expanded(
              child: Row(
                children: [
                  // Step dot
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppTheme.tealAccent
                          : isActive
                              ? AppTheme.primarySlate
                              : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent
                            ? AppTheme.tealAccent
                            : isActive
                                ? AppTheme.primarySlate
                                : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isActive || isCurrent ? Colors.white : AppTheme.secondarySlate,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Progress line (except last element)
                  if (index < _stepTitles.length - 1)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        color: index < _currentStep ? AppTheme.primarySlate : const Color(0xFFF1F5F9),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_stepTitles.length, (index) {
            final isCurrent = index == _currentStep;
            return Expanded(
              child: Text(
                _stepTitles[index],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent ? AppTheme.tealAccent : AppTheme.secondarySlate,
                ),
                textAlign: index == 0
                    ? TextAlign.left
                    : index == _stepTitles.length - 1
                        ? TextAlign.right
                        : TextAlign.center,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(VisitProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          _currentStep > 0
              ? TextButton.icon(
                  onPressed: _prevPage,
                  icon: const Icon(Icons.arrow_back, color: AppTheme.secondarySlate),
                  label: const Text(
                    'Back',
                    style: TextStyle(color: AppTheme.secondarySlate, fontWeight: FontWeight.bold),
                  ),
                )
              : TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.redDestructive, fontWeight: FontWeight.bold),
                  ),
                ),
          
          // Next/Finish Button
          _currentStep < 5
              ? ElevatedButton(
                  onPressed: () => _nextPage(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tealAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Row(
                    children: [
                      Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                )
              : ElevatedButton(
                  onPressed: () => _finishWorkflow(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldSuccess,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Finish', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
        ],
      ),
    );
  }
}
