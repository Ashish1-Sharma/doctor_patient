import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../theme/app_theme.dart';

/// Reusable Patient Identity Strip displayed on detail screens and case files.
class PatientIdentityStrip extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback? onTap;

  const PatientIdentityStrip({
    super.key,
    required this.patient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isPatientActive = patient.status;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Hero(
                  tag: 'patient_avatar_${patient.id}',
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE0F2F1),
                    backgroundImage: patient.profileImage.isNotEmpty
                        ? NetworkImage(patient.profileImage)
                        : null,
                    child: patient.profileImage.isEmpty
                        ? Text(
                            patient.fullName.isNotEmpty
                                ? patient.fullName.substring(0, 1).toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.tealAccent,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              patient.fullName,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primarySlate,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPatientActive
                                  ? AppTheme.emeraldSuccess.withValues(alpha: 0.12)
                                  : AppTheme.redDestructive.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPatientActive ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                color: isPatientActive ? AppTheme.emeraldSuccess : AppTheme.redDestructive,
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
                        'Code: ${patient.patientCode} • ${patient.phone.isNotEmpty ? patient.phone : "No Phone"}',
                        style: textTheme.bodySmall?.copyWith(color: AppTheme.secondarySlate),
                      ),
                      if (patient.gender.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${patient.age} yrs • ${patient.gender}',
                          style: textTheme.bodySmall?.copyWith(color: AppTheme.secondarySlate, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.secondarySlate,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
