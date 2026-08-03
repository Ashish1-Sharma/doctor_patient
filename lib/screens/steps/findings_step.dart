import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/visit_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/medical_image_picker.dart';

/// STEP 2: Chief Complaint & Clinical Findings step inside the New Treatment workflow.
class FindingsStep extends StatefulWidget {
  const FindingsStep({super.key});

  @override
  State<FindingsStep> createState() => _FindingsStepState();
}

class _FindingsStepState extends State<FindingsStep> {
  final _complaintController = TextEditingController();
  final _findingsController = TextEditingController();

  List<String> _complaintImages = [];
  List<String> _findingsImages = [];

  @override
  void initState() {
    super.initState();
    // Load existing form state from VisitProvider
    final provider = Provider.of<VisitProvider>(context, listen: false);
    _complaintController.text = provider.visit.chiefComplaintText;
    _findingsController.text = provider.visit.clinicalFindingsText;
    _complaintImages = List.from(provider.visit.chiefComplaintImages);
    _findingsImages = List.from(provider.visit.clinicalFindingsImages);
  }

  @override
  void dispose() {
    _complaintController.dispose();
    _findingsController.dispose();
    super.dispose();
  }

  void _syncToProvider() {
    final provider = Provider.of<VisitProvider>(context, listen: false);
    provider.updateFindings(
      chiefComplaint: _complaintController.text.trim(),
      chiefComplaintImages: _complaintImages,
      clinicalFindings: _findingsController.text.trim(),
      clinicalFindingsImages: _findingsImages,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Chief Complaint & Clinical Findings',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primarySlate,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Record the primary reason for visit and clinical examination notes.',
            style: TextStyle(color: AppTheme.secondarySlate, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Card 1: Chief Complaint (Mandatory)
          Container(
            padding: const EdgeInsets.all(20),
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
                  children: [
                    Text('Chief Complaint', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Text('*', style: TextStyle(color: AppTheme.redDestructive, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _complaintController,
                  maxLines: 4,
                  onChanged: (_) => _syncToProvider(),
                  decoration: const InputDecoration(
                    hintText: 'Enter patient chief complaints (e.g. Pain in molar, bleeding gums)...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                MedicalImagePicker(
                  label: 'Complaint Images',
                  images: _complaintImages,
                  onImagesChanged: (updated) {
                    setState(() {
                      _complaintImages = updated;
                    });
                    _syncToProvider();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Card 2: Clinical Findings (Optional)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              boxShadow: AppTheme.premiumShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clinical Findings',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _findingsController,
                  maxLines: 4,
                  onChanged: (_) => _syncToProvider(),
                  decoration: const InputDecoration(
                    hintText: 'Enter clinical observations and physical findings...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                MedicalImagePicker(
                  label: 'Findings Scan / Images',
                  images: _findingsImages,
                  onImagesChanged: (updated) {
                    setState(() {
                      _findingsImages = updated;
                    });
                    _syncToProvider();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
