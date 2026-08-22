import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/visit_report_model.dart';

/// Pure-Dart PDF generator using the `pdf` package.
/// Generates a professional A4 medical visit report in under 2 seconds.
/// Downloads visit images in parallel and embeds them in the report.
/// Uses Noto Sans fonts for full Unicode support (₹, emojis, Hindi, etc.).
class PdfGenerator {
  // ── Color tokens ──
  static const _navy = PdfColor.fromInt(0xFF0F4C81);
  static const _teal = PdfColor.fromInt(0xFF00796B);
  static const _textDark = PdfColor.fromInt(0xFF1E293B);
  static const _textMuted = PdfColor.fromInt(0xFF64748B);
  static const _borderLight = PdfColor.fromInt(0xFFE2E8F0);
  static const _bgLight = PdfColor.fromInt(0xFFF8FAFC);

  /// Generates the PDF bytes for the given [report].
  static Future<Uint8List> generate(
    VisitReportModel report,
    String doctorPhone,
    String doctorEmail,
  ) async {
    // ── Load Unicode fonts + fetch images in parallel ──
    final results = await Future.wait([
      PdfGoogleFonts.notoSansRegular(),
      PdfGoogleFonts.notoSansBold(),
      PdfGoogleFonts.notoSansItalic(),
      _downloadAllImages(report),
    ]);

    final regular = results[0] as pw.Font;
    final bold = results[1] as pw.Font;
    final italic = results[2] as pw.Font;
    final imageCache = results[3] as Map<String, Uint8List>;

    final doc = pw.Document(
      title: 'Patient Visit Report',
      author: report.clinic?.companyName ?? 'Clinic',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(report, doctorPhone, doctorEmail, bold, regular),
        footer: (context) => _buildFooter(italic),
        build: (context) => [
          pw.SizedBox(height: 16),
          _buildPatientVisitInfo(report, bold, regular),
          pw.SizedBox(height: 16),
          _buildClinicalDetails(report, imageCache, bold, regular),
          if (report.payment != null) ...[
            pw.SizedBox(height: 16),
            _buildPaymentSummary(report, bold, regular),
          ],
          if (report.clinic?.terms.trim().isNotEmpty == true) ...[
            pw.SizedBox(height: 16),
            _buildTerms(report.clinic!.terms, bold, regular),
          ],
        ],
      ),
    );

    return doc.save();
  }

  // ──────────────────────────────────────────────
  //  IMAGE DOWNLOADER (parallel, fault-tolerant)
  // ──────────────────────────────────────────────

  /// Downloads all visit images concurrently and returns a map of URL → bytes.
  /// Failed downloads are silently skipped.
  static Future<Map<String, Uint8List>> _downloadAllImages(VisitReportModel report) async {
    final visit = report.visit;

    // Collect all non-empty image URLs
    final allUrls = <String>[
      ...visit.chiefComplaintImages,
      ...visit.clinicalFindingsImages,
      ...visit.labImages,
      ...visit.advisedTreatmentImages,
      ...visit.treatmentDoneImages,
      ...visit.medicationImages,
    ].where((url) => url.trim().isNotEmpty).toSet().toList();

    if (allUrls.isEmpty) return {};

    // Download all in parallel with a short timeout per image
    final results = await Future.wait(
      allUrls.map((url) => _downloadImage(url)),
      eagerError: false,
    );

    final cache = <String, Uint8List>{};
    for (int i = 0; i < allUrls.length; i++) {
      final bytes = results[i];
      if (bytes != null && bytes.lengthInBytes > 100) {
        cache[allUrls[i]] = bytes;
      }
    }
    return cache;
  }

  /// Downloads a single image. Returns null on failure.
  static Future<Uint8List?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  // ──────────────────────────────────────────────
  //  HEADER
  // ──────────────────────────────────────────────

  static pw.Widget _buildHeader(
    VisitReportModel report,
    String doctorPhone,
    String doctorEmail,
    pw.Font bold,
    pw.Font regular,
  ) {
    final clinicName = (report.clinic?.companyName.trim().isNotEmpty == true)
        ? report.clinic!.companyName.trim()
        : 'Dental Clinic';
    final clinicAddress = report.clinic?.companyAddress.trim() ?? '';

    final regList = <String>[];
    if (report.clinic?.clinicRegNo.trim().isNotEmpty == true) {
      regList.add('Clinic Reg: ${report.clinic!.clinicRegNo.trim()}');
    }
    if (report.clinic?.doctorRegCert.trim().isNotEmpty == true) {
      regList.add('Doctor Reg: ${report.clinic!.doctorRegCert.trim()}');
    }
    if (report.clinic?.tradeLicense.trim().isNotEmpty == true) {
      regList.add('Trade Lic: ${report.clinic!.tradeLicense.trim()}');
    }
    if (report.clinic?.pollutionControlCert.trim().isNotEmpty == true) {
      regList.add('Pollution Cert: ${report.clinic!.pollutionControlCert.trim()}');
    }
    if (report.clinic?.municipalityNoc.trim().isNotEmpty == true) {
      regList.add('NOC: ${report.clinic!.municipalityNoc.trim()}');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const pw.BoxDecoration(
            color: _navy,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      clinicName.toUpperCase(),
                      style: pw.TextStyle(font: bold, fontSize: 16, color: PdfColors.white, letterSpacing: 0.5),
                    ),
                    if (clinicAddress.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        clinicAddress,
                        style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColor.fromInt(0xCCFFFFFF)),
                      ),
                    ],
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (doctorPhone.isNotEmpty)
                    pw.Text('Ph: $doctorPhone', style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.white)),
                  if (doctorEmail.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text('Email: $doctorEmail', style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.white)),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (regList.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              color: _bgLight,
              border: pw.Border.all(color: _borderLight, width: 0.6),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              regList.join('   •   '),
              style: pw.TextStyle(font: regular, fontSize: 8, color: _textMuted),
            ),
          ),
        ],
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  PATIENT & VISIT INFO
  // ──────────────────────────────────────────────

  static pw.Widget _buildPatientVisitInfo(
    VisitReportModel report,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderLight, width: 1),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('PATIENT DETAILS',
                      style: pw.TextStyle(font: bold, fontSize: 9, color: _teal, letterSpacing: 0.5)),
                  pw.SizedBox(height: 10),
                  _infoRow('Name', report.patient?.fullName ?? 'N/A', bold, regular),
                  _infoRow('Patient Code', report.patient?.patientCode ?? 'N/A', bold, regular),
                  _infoRow('Age / Gender',
                      '${report.patient?.age ?? 'N/A'} Yrs / ${report.patient?.gender ?? 'N/A'}', bold, regular),
                  _infoRow('Phone', report.patient?.phone ?? 'N/A', bold, regular),
                  if (report.patient?.address.trim().isNotEmpty == true)
                    _infoRow('Address', report.patient!.address, bold, regular),
                ],
              ),
            ),
          ),
          pw.Container(width: 1, color: _borderLight),
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('VISIT DETAILS',
                      style: pw.TextStyle(font: bold, fontSize: 9, color: _teal, letterSpacing: 0.5)),
                  pw.SizedBox(height: 10),
                  _infoRow('Visit No', report.visit.visitNo.isNotEmpty ? report.visit.visitNo : 'N/A', bold, regular),
                  _infoRow('Visit Date', report.visit.visitDate.isNotEmpty ? report.visit.visitDate : 'N/A', bold, regular),
                  _infoRow('Invoice No', report.payment?.invoiceNo ?? 'N/A', bold, regular),
                  if (report.clinic?.clinicRegNo.trim().isNotEmpty == true)
                    _infoRow('Clinic Reg', report.clinic!.clinicRegNo.trim(), bold, regular),
                  if (report.clinic?.doctorRegCert.trim().isNotEmpty == true)
                    _infoRow('Doctor Reg', report.clinic!.doctorRegCert.trim(), bold, regular),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value, pw.Font bold, pw.Font regular) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(label, style: pw.TextStyle(font: regular, fontSize: 8, color: _textMuted)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 9, color: _textDark)),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  CLINICAL DETAILS (with images)
  // ──────────────────────────────────────────────

  static pw.Widget _buildClinicalDetails(
    VisitReportModel report,
    Map<String, Uint8List> imageCache,
    pw.Font bold,
    pw.Font regular,
  ) {
    final visit = report.visit;

    final sections = <_ClinicalSection>[
      _ClinicalSection('Chief Complaint', visit.chiefComplaintText, visit.chiefComplaintImages),
      _ClinicalSection('Clinical Findings', visit.clinicalFindingsText, visit.clinicalFindingsImages),
      _ClinicalSection('Lab Investigation', visit.labText, visit.labImages),
      _ClinicalSection('Treatment Advised', visit.advisedTreatmentText, visit.advisedTreatmentImages),
      _ClinicalSection('Treatment Done', visit.treatmentDoneText, visit.treatmentDoneImages),
      _ClinicalSection('Medication', visit.medicationText, const []),
      _ClinicalSection('Next Appointment', visit.nextAppointmentDate, const []),
      _ClinicalSection('Doctor Notes', visit.notes, const []),
    ].where((s) => s.hasContent(imageCache)).toList();

    if (sections.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _borderLight),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Text(
          'No clinical details recorded for this visit.',
          style: pw.TextStyle(font: regular, fontSize: 10, color: _textMuted),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('CLINICAL DETAILS',
            style: pw.TextStyle(font: bold, fontSize: 9, color: _teal, letterSpacing: 0.5)),
        pw.SizedBox(height: 8),
        // Build each clinical section as a bordered block
        ...sections.asMap().entries.map((entry) {
          final idx = entry.key;
          final section = entry.value;
          final isEven = idx % 2 == 0;
          final hasText = section.text.trim().isNotEmpty;
          final availableImages = section.imageUrls
              .where((url) => url.trim().isNotEmpty && imageCache.containsKey(url))
              .toList();

          return pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: isEven ? _bgLight : PdfColors.white,
              border: pw.Border(
                left: const pw.BorderSide(color: _borderLight, width: 0.8),
                right: const pw.BorderSide(color: _borderLight, width: 0.8),
                top: idx == 0
                    ? const pw.BorderSide(color: _borderLight, width: 0.8)
                    : pw.BorderSide.none,
                bottom: const pw.BorderSide(color: _borderLight, width: 0.8),
              ),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Label column (30%)
                pw.Container(
                  width: 130,
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    section.label,
                    style: pw.TextStyle(font: bold, fontSize: 9, color: _navy),
                  ),
                ),
                // Value + Images column (70%)
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (hasText)
                          pw.Text(
                            section.text.trim(),
                            style: pw.TextStyle(font: regular, fontSize: 9, color: _textDark),
                          ),
                        // Render images as a row of thumbnails
                        if (availableImages.isNotEmpty) ...[
                          if (hasText) pw.SizedBox(height: 6),
                          pw.Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: availableImages.map((url) {
                              final bytes = imageCache[url]!;
                              try {
                                final image = pw.MemoryImage(bytes);
                                return pw.Container(
                                  width: 80,
                                  height: 80,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(color: _borderLight, width: 0.5),
                                    borderRadius: pw.BorderRadius.circular(4),
                                  ),
                                  child: pw.ClipRRect(
                                    horizontalRadius: 4,
                                    verticalRadius: 4,
                                    child: pw.Image(image, fit: pw.BoxFit.cover, width: 80, height: 80),
                                  ),
                                );
                              } catch (_) {
                                return pw.SizedBox.shrink();
                              }
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  PAYMENT SUMMARY
  // ──────────────────────────────────────────────

  static pw.Widget _buildPaymentSummary(
    VisitReportModel report,
    pw.Font bold,
    pw.Font regular,
  ) {
    final payment = report.payment!;
    final rows = <_PaymentRow>[
      _PaymentRow('Total Amount', '\u20b9${payment.totalAmount.toStringAsFixed(2)}'),
      _PaymentRow('Paid Amount', '\u20b9${payment.paidAmount.toStringAsFixed(2)}'),
      _PaymentRow('Pending Amount', '\u20b9${payment.pendingAmount.toStringAsFixed(2)}'),
      if (payment.paymentMethod.trim().isNotEmpty)
        _PaymentRow('Payment Method', payment.paymentMethod),
      _PaymentRow('Payment Status', payment.paymentStatus.isNotEmpty ? payment.paymentStatus : 'N/A'),
      if (payment.paymentDate.trim().isNotEmpty)
        _PaymentRow('Payment Date', payment.paymentDate),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('PAYMENT SUMMARY',
            style: pw.TextStyle(font: bold, fontSize: 9, color: _teal, letterSpacing: 0.5)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: _borderLight, width: 0.8),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(7),
          },
          children: rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final row = entry.value;
            final isEven = idx % 2 == 0;

            return pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  color: isEven ? _bgLight : PdfColors.white,
                  child: pw.Text(row.label, style: pw.TextStyle(font: bold, fontSize: 9, color: _navy)),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  color: isEven ? _bgLight : PdfColors.white,
                  child: pw.Text(row.value, style: pw.TextStyle(font: regular, fontSize: 9, color: _textDark)),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  TERMS & CONDITIONS
  // ──────────────────────────────────────────────

  static pw.Widget _buildTerms(String terms, pw.Font bold, pw.Font regular) {
    final lines = terms
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map((l) => l.replaceFirst(RegExp(r'^[-*•]\s*'), ''))
        .toList();

    if (lines.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('TERMS & CONDITIONS',
            style: pw.TextStyle(font: bold, fontSize: 9, color: _teal, letterSpacing: 0.5)),
        pw.SizedBox(height: 6),
        ...lines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('\u2022  ', style: pw.TextStyle(font: regular, fontSize: 8, color: _textMuted)),
                pw.Expanded(
                  child: pw.Text(line, style: pw.TextStyle(font: regular, fontSize: 8, color: _textMuted)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  FOOTER
  // ──────────────────────────────────────────────

  static pw.Widget _buildFooter(pw.Font italic) {
    return pw.Column(
      children: [
        pw.Divider(color: _navy, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            'This is a computer-generated document.',
            style: pw.TextStyle(font: italic, fontSize: 8, color: _textMuted),
          ),
        ),
      ],
    );
  }
}

/// Internal helper for clinical sections with text + images.
class _ClinicalSection {
  final String label;
  final String text;
  final List<String> imageUrls;
  const _ClinicalSection(this.label, this.text, this.imageUrls);

  /// Returns true if this section has any content to display.
  bool hasContent(Map<String, Uint8List> imageCache) {
    if (text.trim().isNotEmpty) return true;
    return imageUrls.any((url) => url.trim().isNotEmpty && imageCache.containsKey(url));
  }
}

/// Internal helper for payment rows.
class _PaymentRow {
  final String label;
  final String value;
  const _PaymentRow(this.label, this.value);
}
