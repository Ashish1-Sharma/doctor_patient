import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/visit_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/medical_image_picker.dart';

/// STEP 4: Treatment Done & Medication step inside the New Treatment workflow.
class TreatmentStep extends StatefulWidget {
  const TreatmentStep({super.key});

  @override
  State<TreatmentStep> createState() => _TreatmentStepState();
}

class _TreatmentStepState extends State<TreatmentStep> {
  final _doneController = TextEditingController();
  final _medicationController = TextEditingController();

  List<String> _doneImages = [];
  List<String> _medicationImages = [];

  @override
  void initState() {
    super.initState();
    // Load existing form state from VisitProvider
    final provider = Provider.of<VisitProvider>(context, listen: false);
    _doneController.text = provider.visit.treatmentDoneText;
    _medicationController.text = provider.visit.medicationText;
    _doneImages = List.from(provider.visit.treatmentDoneImages);
    _medicationImages = List.from(provider.visit.medicationImages);
  }

  @override
  void dispose() {
    _doneController.dispose();
    _medicationController.dispose();
    super.dispose();
  }

  void _syncToProvider() {
    final provider = Provider.of<VisitProvider>(context, listen: false);
    provider.updateTreatment(
      treatmentDone: _doneController.text.trim(),
      treatmentDoneImages: _doneImages,
      medication: _medicationController.text.trim(),
      medicationImages: _medicationImages,
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
            'Treatment Done & Medication',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primarySlate,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Record the actual clinical treatments completed today and prescribe medications.',
            style: TextStyle(color: AppTheme.secondarySlate, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Card 1: Treatment Done (Optional)
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
                  'Treatment Administered',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _doneController,
                  maxLines: 4,
                  onChanged: (_) => _syncToProvider(),
                  decoration: const InputDecoration(
                    hintText: 'Enter clinical procedure completed (e.g. Tooth scaling, temporary filling)...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                MedicalImagePicker(
                  label: 'Procedure Images / Scans',
                  images: _doneImages,
                  onImagesChanged: (updated) {
                    setState(() {
                      _doneImages = updated;
                    });
                    _syncToProvider();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Card 2: Medication (Optional)
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
                  'Medication / Prescription',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _medicationController,
                  maxLines: 4,
                  onChanged: (_) => _syncToProvider(),
                  decoration: const InputDecoration(
                    hintText: 'Enter prescription medication list and dosages...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                MedicalImagePicker(
                  label: 'Prescription Slipping Images',
                  images: _medicationImages,
                  onImagesChanged: (updated) {
                    setState(() {
                      _medicationImages = updated;
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
