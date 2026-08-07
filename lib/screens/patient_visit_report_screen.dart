import 'package:flutter/material.dart';
import '../viewer/pdf_viewer_screen.dart';

/// Legacy screen entry point that redirects and delegates to [PdfViewerScreen].
/// This ensures backward compatibility with existing navigation calls in the codebase.
class PatientVisitReportScreen extends StatelessWidget {
  final int parentId;
  final int visitId;

  const PatientVisitReportScreen({
    super.key,
    required this.parentId,
    required this.visitId,
  });

  @override
  Widget build(BuildContext context) {
    return PdfViewerScreen(
      parentId: parentId,
      visitId: visitId,
    );
  }
}
