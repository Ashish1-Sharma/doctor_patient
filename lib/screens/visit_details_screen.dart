import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/visit_model.dart';
import '../models/appointment_model.dart';
import '../services/visit_service.dart';
import '../services/appointment_service.dart';
import '../theme/app_theme.dart';
import 'patient_visit_report_screen.dart';

/// A premium full-screen display for Clinical Visit Details.
class VisitDetailsScreen extends StatefulWidget {
  final int visitId;
  final int doctorId;

  const VisitDetailsScreen({
    super.key,
    required this.visitId,
    required this.doctorId,
  });

  @override
  State<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen> {
  late Future<http.Response> _visitFuture;
  AppointmentModel? _linkedAppointment;
  bool _isSubUser = false;
  int _parentId = 1;

  @override
  void initState() {
    super.initState();
    _visitFuture = VisitService.getVisitById(widget.doctorId, widget.visitId);
    _loadLinkedAppointment();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileStr = prefs.getString('user_profile');
      if (profileStr != null) {
        final profile = jsonDecode(profileStr);
        final isSubUser = profile['isSubUser'] == true;
        final rawId = profile['id'];
        final doctorId = rawId is int ? rawId : (rawId != null ? int.tryParse(rawId.toString()) : 1);
        final rawParentId = isSubUser
            ? (profile['parentId'] ?? profile['mainAccountId'] ?? doctorId)
            : doctorId;
        final parentId = rawParentId is int ? rawParentId : (rawParentId != null ? int.tryParse(rawParentId.toString()) : 1);
        if (mounted) {
          setState(() {
            _isSubUser = isSubUser;
            _parentId = parentId ?? 1;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadLinkedAppointment() async {
    try {
      final response = await AppointmentService.getAppointments(widget.doctorId).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['statusCode'] == 200 && responseData['body'] is List) {
          final list = responseData['body'] as List;
          final appts = list.map((json) => AppointmentModel.fromJson(json)).toList();
          final match = appts.firstWhere((a) => a.visitId == widget.visitId);
          setState(() {
            _linkedAppointment = match;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _confirmAndDeleteVisit() async {
    if (_isSubUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only Admin has permission to delete visits.'),
          backgroundColor: AppTheme.redDestructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete This Visit?'),
        content: const Text(
          'Are you sure you want to permanently delete this visit and all associated payment records? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.redDestructive, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final response = await VisitService.deleteVisit(widget.visitId, _parentId)
            .timeout(const Duration(seconds: 5));
        final responseData = jsonDecode(response.body);

        if (!mounted) return;

        if (response.statusCode == 200 || responseData['statusCode'] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visit deleted successfully.'),
              backgroundColor: AppTheme.emeraldSuccess,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Failed to delete visit.'),
              backgroundColor: AppTheme.redDestructive,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Could not delete visit.'),
            backgroundColor: AppTheme.redDestructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(imageUrl),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageRow(List<String> images) {
    final filtered = images.where((img) => img.trim().isNotEmpty).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: SizedBox(
        height: 90,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final imageUrl = filtered[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () => _showFullScreenImage(imageUrl),
                child: Hero(
                  tag: imageUrl,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 90,
                        height: 90,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.broken_image_outlined, size: 24, color: AppTheme.secondarySlate),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 90,
                          height: 90,
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.tealAccent),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
    List<String>? images,
  }) {
    final hasContent = content.trim().isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  Icon(icon, color: AppTheme.tealAccent, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.primarySlate,
                    ),
                  ),
                ],
              ),
            ),
            // Content area
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasContent ? content : 'Not specified.',
                    style: TextStyle(
                      fontSize: 14,
                      color: hasContent ? AppTheme.primarySlate : AppTheme.secondarySlate,
                      height: 1.5,
                    ),
                  ),
                  if (images != null) _buildImageRow(images),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Clinical Case Record', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.primarySlate,
        actions: [
          if (!_isSubUser)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.redDestructive),
              onPressed: _confirmAndDeleteVisit,
              tooltip: 'Delete Visit',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<http.Response>(
        future: _visitFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent));
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 64, color: AppTheme.redDestructive),
                  const SizedBox(height: 16),
                  const Text('Error loading case record details.', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _visitFuture = VisitService.getVisitById(widget.doctorId, widget.visitId);
                    }),
                    child: const Text('Retry'),
                  )
                ],
              ),
            );
          }

          try {
            final Map<String, dynamic> responseData = jsonDecode(snapshot.data!.body);
            if (snapshot.data!.statusCode != 200 || responseData['statusCode'] != 200) {
              return Center(
                child: Text(responseData['message'] ?? 'Failed to parse record.'),
              );
            }

            final details = VisitModel.fromJson(responseData['body']);
            final formattedVisitNo = details.visitNo.replaceAll(RegExp(r'[^\d]'), '').isEmpty
                ? details.visitNo
                : int.parse(details.visitNo.replaceAll(RegExp(r'[^\d]'), '')).toString().padLeft(3, '0');

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Case Record Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primarySlate, Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppTheme.premiumShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedVisitNo,
                          style: textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Case date: ${details.visitDate}',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Detail cards
                  _buildSectionCard(
                    icon: Icons.healing_outlined,
                    title: 'Chief Complaint',
                    content: details.chiefComplaintText,
                    images: details.chiefComplaintImages,
                  ),
                  _buildSectionCard(
                    icon: Icons.visibility_outlined,
                    title: 'Clinical Findings',
                    content: details.clinicalFindingsText,
                    images: details.clinicalFindingsImages,
                  ),
                  _buildSectionCard(
                    icon: Icons.science_outlined,
                    title: 'Lab Advice',
                    content: details.labText,
                    images: details.labImages,
                  ),
                  _buildSectionCard(
                    icon: Icons.assignment_outlined,
                    title: 'Advised Treatment',
                    content: details.advisedTreatmentText,
                    images: details.advisedTreatmentImages,
                  ),
                  _buildSectionCard(
                    icon: Icons.check_circle_outline,
                    title: 'Treatment Done',
                    content: details.treatmentDoneText,
                    images: details.treatmentDoneImages,
                  ),
                  _buildSectionCard(
                    icon: Icons.medication_outlined,
                    title: 'Medication Prescribed',
                    content: details.medicationText,
                    images: details.medicationImages,
                  ),
                  _buildSectionCard(
                    icon: Icons.event_note_outlined,
                    title: 'Next Appointment Date',
                    content: details.nextAppointmentDate,
                  ),
                  _buildSectionCard(
                    icon: Icons.notes_outlined,
                    title: 'Doctor Notes & Remarks',
                    content: details.notes,
                  ),
                  if (_linkedAppointment != null)
                    _buildSectionCard(
                      icon: Icons.calendar_month,
                      title: 'Linked Appointment Details',
                      content: 'Date & Time: ${_linkedAppointment!.appointmentDate}\nProcedure: ${_linkedAppointment!.procedureText}\nStatus: ${_linkedAppointment!.status}',
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PatientVisitReportScreen(
                            parentId: details.parentId,
                            visitId: details.id,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print / View Patient Report', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tealAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );

          } catch (_) {
            return const Center(child: Text('Failed to load visit details format.'));
          }
        },
      ),
    );
  }
}
