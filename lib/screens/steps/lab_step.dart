import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/visit_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/medical_image_picker.dart';

/// STEP 3: Lab & Advised Treatment step inside the New Treatment workflow.
class LabStep extends StatefulWidget {
  const LabStep({super.key});

  @override
  State<LabStep> createState() => _LabStepState();
}

class _LabStepState extends State<LabStep> {
  final _labController = TextEditingController();
  final _advisedController = TextEditingController();

  List<String> _labImages = [];
  List<String> _advisedImages = [];

  @override
  void initState() {
    super.initState();
    // Load existing form state from VisitProvider
    final provider = Provider.of<VisitProvider>(context, listen: false);
    _labController.text = provider.visit.labText;
    _advisedController.text = provider.visit.advisedTreatmentText;
    _labImages = List.from(provider.visit.labImages);
    _advisedImages = List.from(provider.visit.advisedTreatmentImages);
  }

  @override
  void dispose() {
    _labController.dispose();
    _advisedController.dispose();
    super.dispose();
  }

  void _syncToProvider() {
    final provider = Provider.of<VisitProvider>(context, listen: false);
    provider.updateLab(
      labText: _labController.text.trim(),
      labImages: _labImages,
      advisedTreatment: _advisedController.text.trim(),
      advisedTreatmentImages: _advisedImages,
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
            'Lab & Advised Treatment',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primarySlate,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Record any advised pathology/radiology tests and recommended clinical procedures.',
            style: TextStyle(color: AppTheme.secondarySlate, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Card 1: Lab (Optional)
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
                  'Lab Investigations',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _labController,
                  maxLines: 4,
                  onChanged: (_) => _syncToProvider(),
                  decoration: const InputDecoration(
                    hintText: 'Enter advised blood tests, scans, or radiography reports...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                MedicalImagePicker(
                  label: 'Lab Attachments / X-Rays',
                  images: _labImages,
                  onImagesChanged: (updated) {
                    setState(() {
                      _labImages = updated;
                    });
                    _syncToProvider();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Card 2: Advised Treatment (Optional)
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
                  'Advised Treatment Plan',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _advisedController,
                  maxLines: 4,
                  onChanged: (_) => _syncToProvider(),
                  decoration: const InputDecoration(
                    hintText: 'Enter recommended clinical plan or surgical advice...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                MedicalImagePicker(
                  label: 'Treatment Plan Attachments',
                  images: _advisedImages,
                  onImagesChanged: (updated) {
                    setState(() {
                      _advisedImages = updated;
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
