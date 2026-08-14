import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/visit_report_model.dart';
import '../services/visit_service.dart';
import '../services/pdf_generator.dart';
import '../theme/app_theme.dart';

/// Fast PDF Viewer screen.
///
/// Uses pure-Dart PDF generation (no HTML, no browser) for sub-second rendering.
/// Flow: Fetch API → Build PDF with `pdf` package → Display with PdfPreview.
class PdfViewerScreen extends StatefulWidget {
  final int parentId;
  final int visitId;

  const PdfViewerScreen({
    super.key,
    required this.parentId,
    required this.visitId,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isLoading = true;
  String? _error;
  Uint8List? _pdfBytes;
  String _fileName = 'visit-report.pdf';

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  // ──────────────────────────────────────────────
  //  CORE PIPELINE (API fetch + pure-Dart PDF build)
  // ──────────────────────────────────────────────

  Future<void> _generateReport({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ── Check cache first ──
      final invoiceHint = 'INV-${widget.visitId}';
      final cachedName = 'Visit-Report-$invoiceHint.pdf';
      final tempDir = Directory.systemTemp;
      final sanitized = cachedName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final cachedFile = File('${tempDir.path}/$sanitized');

      if (!forceRefresh && await cachedFile.exists()) {
        final bytes = await cachedFile.readAsBytes();
        if (!mounted) return;
        setState(() {
          _pdfBytes = bytes;
          _fileName = cachedName;
          _isLoading = false;
        });
        return;
      }

      // ── Fetch API data ──
      final response = await VisitService.getVisitReportDetails(
        widget.parentId,
        widget.visitId,
      ).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (response.statusCode != 200 ||
          responseData['statusCode'] != 200 ||
          responseData['body'] == null) {
        throw Exception(
          responseData['message']?.toString() ?? 'Failed to fetch visit details.',
        );
      }

      final report = VisitReportModel.fromJson(
        responseData['body'] as Map<String, dynamic>,
      );

      // ── Doctor credentials from cache ──
      String doctorPhone = '';
      String doctorEmail = '';
      try {
        final prefs = await SharedPreferences.getInstance();
        final profileStr = prefs.getString('user_profile');
        if (profileStr != null) {
          final profile = jsonDecode(profileStr);
          doctorPhone = profile['phone'] as String? ?? '';
          doctorEmail = profile['email'] as String? ?? '';
        }
      } catch (_) {}

      // ── Generate PDF using pure Dart (sub-second) ──
      final pdfBytes = await PdfGenerator.generate(report, doctorPhone, doctorEmail);

      // ── Resolve filename and cache ──
      final invoiceNo = report.payment?.invoiceNo.isNotEmpty == true
          ? report.payment!.invoiceNo
          : invoiceHint;
      final fileName = 'Visit-Report-$invoiceNo.pdf';
      final finalSanitized = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final finalFile = File('${tempDir.path}/$finalSanitized');
      finalFile.writeAsBytes(pdfBytes, flush: true).catchError((_) => finalFile);

      if (!mounted) return;
      setState(() {
        _pdfBytes = pdfBytes;
        _fileName = fileName;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ──────────────────────────────────────────────
  //  ACTIONS
  // ──────────────────────────────────────────────

  Future<void> _printReport() async {
    if (_pdfBytes == null) return;
    await Printing.layoutPdf(
      onLayout: (format) async => _pdfBytes!,
      name: _fileName,
    );
  }

  Future<void> _shareReport() async {
    if (_pdfBytes == null) return;
    if (!kIsWeb && Platform.isWindows) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sharing not supported on Windows. Use Print/Save option.'),
          backgroundColor: AppTheme.amberWarning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _printReport();
      return;
    }
    await Printing.sharePdf(bytes: _pdfBytes!, filename: _fileName);
  }

  Future<void> _downloadReport() async {
    if (_pdfBytes == null) return;
    try {
      if (!kIsWeb && Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          final downloadsDir = Directory('$userProfile/Downloads');
          if (await downloadsDir.exists()) {
            final targetFile = File('${downloadsDir.path}/$_fileName');
            await targetFile.writeAsBytes(_pdfBytes!, flush: true);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved to Downloads: $_fileName'),
                backgroundColor: const Color(0xFF00796B),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
        }
      }
      await Printing.sharePdf(bytes: _pdfBytes!, filename: _fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppTheme.redDestructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ──────────────────────────────────────────────
  //  UI
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isReady = !_isLoading && _pdfBytes != null && _error == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Patient Visit Report',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primarySlate,
        actions: isReady
            ? [
                IconButton(
                  icon: const Icon(Icons.download_outlined),
                  tooltip: 'Download',
                  onPressed: _downloadReport,
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Share',
                  onPressed: _shareReport,
                ),
                IconButton(
                  icon: const Icon(Icons.print_outlined),
                  tooltip: 'Print',
                  onPressed: _printReport,
                ),
                const SizedBox(width: 4),
              ]
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // ── Loading ──
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF00796B),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading report...',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // ── Error ──
    if (_error != null || _pdfBytes == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.redDestructive.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, size: 40, color: AppTheme.redDestructive),
              ),
              const SizedBox(height: 20),
              const Text(
                'Report Generation Failed',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primarySlate),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Unknown error occurred.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.secondarySlate, height: 1.4),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => _generateReport(forceRefresh: true),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── PDF Viewer ──
    return PdfPreview(
      build: (format) async => _pdfBytes!,
      pdfFileName: _fileName,
      allowPrinting: false,
      allowSharing: false,
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      initialPageFormat: PdfPageFormat.a4,
      useActions: false,
    );
  }
}
