import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../models/visit_model.dart';
import '../theme/app_theme.dart';
import 'visit_details_screen.dart';
import 'patient_visit_report_screen.dart';

class PatientVisitsScreen extends StatelessWidget {
  final PatientModel patient;
  final List<VisitModel> visits;

  const PatientVisitsScreen({
    super.key,
    required this.patient,
    required this.visits,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Clinical Visits',
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
            
            // Visits List
            Expanded(
              child: visits.isEmpty
                  ? _buildEmptyState(textTheme)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: visits.length,
                      itemBuilder: (context, index) {
                        final visit = visits[index];
                        return _buildVisitCard(context, visit, textTheme);
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.tealAccent.withValues(alpha: 0.1),
            backgroundImage: patient.profileImage.isNotEmpty
                ? NetworkImage(patient.profileImage)
                : null,
            child: patient.profileImage.isEmpty
                ? const Icon(Icons.person_outline, color: AppTheme.tealAccent, size: 28)
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
                const SizedBox(height: 4),
                Text(
                  'Code: ${patient.patientCode} • Phone: ${patient.phone}',
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
              color: AppTheme.tealAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${visits.length} ${visits.length == 1 ? 'Visit' : 'Visits'}',
              style: const TextStyle(
                color: AppTheme.tealAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitCard(BuildContext context, VisitModel visit, TextTheme textTheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisitDetailsScreen(
                visitId: visit.id,
                doctorId: visit.doctorId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visit Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_outlined, color: AppTheme.tealAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Visit #${visit.visitNo}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primarySlate,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    visit.visitDate.length >= 10
                        ? visit.visitDate.substring(0, 10)
                        : visit.visitDate,
                    style: const TextStyle(
                      color: AppTheme.secondarySlate,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFE2E8F0)),

              // Chief Complaint
              if (visit.chiefComplaintText.trim().isNotEmpty) ...[
                const Text(
                  'Chief Complaint',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondarySlate,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  visit.chiefComplaintText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.primarySlate,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Advised Treatment
              if (visit.advisedTreatmentText.trim().isNotEmpty) ...[
                const Text(
                  'Advised Treatment',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondarySlate,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  visit.advisedTreatmentText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.primarySlate,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Actions Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PatientVisitReportScreen(
                            parentId: visit.parentId,
                            visitId: visit.id,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.tealAccent,
                      side: const BorderSide(color: AppTheme.tealAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.print_outlined, size: 14),
                    label: const Text('Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VisitDetailsScreen(
                            visitId: visit.id,
                            doctorId: visit.doctorId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tealAccent.withValues(alpha: 0.12),
                      foregroundColor: AppTheme.tealAccent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
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
                color: AppTheme.tealAccent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_toggle_off_rounded, size: 48, color: AppTheme.tealAccent),
            ),
            const SizedBox(height: 20),
            Text(
              'No Clinical Visits Yet',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primarySlate),
            ),
            const SizedBox(height: 8),
            const Text(
              'All clinical and checkup visits will be shown here when added.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.secondarySlate, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
