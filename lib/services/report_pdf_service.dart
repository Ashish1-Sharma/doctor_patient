import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/visit_model.dart';
import '../models/patient_model.dart';
import '../models/payment_model.dart';
import '../models/clinic_model.dart';
import '../theme/report_theme.dart';

/// Builds the printable Patient Visit Report as an actual paginated PDF
/// (using package:pdf) so long content flows onto extra pages instead of
/// overflowing a fixed-size widget preview. Mirrors the on-screen template
/// in [PatientVisitReportScreen] section-for-section.
class ReportPdfService {
  static const _fallbackClinicName = 'ABC DENTAL CLINIC';
  static const _fallbackClinicAddress = '24 MG Road, Delhi - 110001';

  static Future<Uint8List> buildVisitReportPdf({
    required VisitModel visit,
    PatientModel? patient,
    ClinicModel? clinic,
    PaymentModel? payment,
    required String doctorPhone,
    required String doctorEmail,
  }) async {
    // Noto Sans covers the ₹ glyph and other unicode chars the default
    // built-in PDF fonts don't render. Noto Emoji is registered as a
    // fallback so emoji typed into notes/terms (🙏, ❣️, skin-tone modifiers,
    // variation selectors, ...) don't log "Unable to find a font" and get
    // dropped — package:pdf can't render *color* emoji fonts, so the
    // monochrome Noto Emoji is used instead of Noto Color Emoji.
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final emojiFont = await PdfGoogleFonts.notoEmojiRegular();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
        fontFallback: [emojiFont],
      ),
    );

    final clinicName = _orFallback(clinic?.companyName, _fallbackClinicName);
    final clinicAddress = _orFallback(
      clinic?.companyAddress,
      _fallbackClinicAddress,
    );
    final webUrl = 'www.${clinicName.toLowerCase().replaceAll(' ', '')}.com';

    // Clinical images live at remote URLs in the visit record; pw widgets
    // build synchronously, so every image referenced by this visit is
    // downloaded up front and keyed by the same label used in the
    // clinical-details rows below.
    final clinicalImages = await _fetchClinicalImages(visit);
    developer.log(
      'PDF input: textLengths=${<String, int>{'chiefComplaint': visit.chiefComplaintText.length, 'clinicalFindings': visit.clinicalFindingsText.length, 'lab': visit.labText.length, 'advisedTreatment': visit.advisedTreatmentText.length, 'treatmentDone': visit.treatmentDoneText.length, 'medication': visit.medicationText.length, 'notes': visit.notes.length, 'terms': clinic?.terms.length ?? 0}}, imageCounts=${clinicalImages.map((key, value) => MapEntry(key, value.length))}',
      name: 'ReportPdfService',
    );

    try {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          // The package default is only 20 pages and throws in debug builds.
          // Reports can legitimately exceed that when many clinical photos or
          // imported terms are present.
          maxPages: 200,
          margin: const pw.EdgeInsets.all(28),
          footer:
              (context) => pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(top: 8),
                child: pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: ReportTheme.pdfTextMuted,
                  ),
                ),
              ),
          build:
              (context) => [
                _clinicHeader(
                  clinicName,
                  clinicAddress,
                  doctorPhone,
                  doctorEmail,
                  webUrl,
                ),
                pw.SizedBox(height: 12),
                pw.Divider(
                  color: ReportTheme.pdfPrimary,
                  thickness: 1.5,
                  height: 1,
                ),
                pw.SizedBox(height: 12),
                pw.Center(
                  child: pw.Text(
                    'PATIENT VISIT REPORT',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18,
                      color: ReportTheme.pdfSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                pw.SizedBox(height: 12),
                _visitInfoCard(
                  invoiceNo: payment?.invoiceNo ?? '',
                  visitNo: visit.visitNo,
                  visitDate: visit.visitDate,
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: _companyDetailsCard(
                        clinic,
                        clinicName,
                        clinicAddress,
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(child: _patientDetailsCard(patient)),
                  ],
                ),
                pw.SizedBox(height: 16),
                _clinicalDetailsSection(visit, clinicalImages),
                if (payment != null) ...[
                  pw.SizedBox(height: 16),
                  _paymentSummarySection(payment),
                ],
                if (clinic != null && clinic.terms.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  _termsSection(clinic.terms),
                ],
                pw.SizedBox(height: 20),
                _footerSection(),
              ],
        ),
      );
    } catch (error, stackTrace) {
      // Never make the report unusable because one pdf widget cannot span.
      // Keep the original failure in logs, then generate a text-only report
      // using simple page primitives as a guaranteed fallback.
      developer.log(
        'Paginated PDF failed; using safe text fallback: $error',
        name: 'ReportPdfService',
        error: error,
        stackTrace: stackTrace,
      );
      return _buildSafeFallbackPdf(
        visit: visit,
        patient: patient,
        payment: payment,
        clinicName: clinicName,
      );
    }

    return doc.save();
  }

  static Future<Uint8List> _buildSafeFallbackPdf({
    required VisitModel visit,
    PatientModel? patient,
    PaymentModel? payment,
    required String clinicName,
  }) async {
    final doc = pw.Document();
    final lines = <String>[
      clinicName,
      'PATIENT VISIT REPORT',
      'Patient: ${patient?.fullName ?? 'N/A'}',
      'Patient ID: ${patient?.patientCode ?? 'N/A'}',
      'Visit No: ${visit.visitNo}',
      'Visit Date: ${visit.visitDate}',
      if (payment != null)
        'Invoice: ${payment.invoiceNo} | Status: ${payment.paymentStatus}',
      if (visit.chiefComplaintText.trim().isNotEmpty)
        'Chief Complaint: ${visit.chiefComplaintText}',
      if (visit.clinicalFindingsText.trim().isNotEmpty)
        'Clinical Findings: ${visit.clinicalFindingsText}',
      if (visit.labText.trim().isNotEmpty)
        'Lab Investigation: ${visit.labText}',
      if (visit.advisedTreatmentText.trim().isNotEmpty)
        'Treatment Advised: ${visit.advisedTreatmentText}',
      if (visit.treatmentDoneText.trim().isNotEmpty)
        'Treatment Done: ${visit.treatmentDoneText}',
      if (visit.medicationText.trim().isNotEmpty)
        'Medication: ${visit.medicationText}',
    ];
    doc.addPage(
      pw.MultiPage(
        maxPages: 20,
        build:
            (_) => [
              for (final line in lines)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Text(line),
                ),
            ],
      ),
    );
    return doc.save();
  }

  static String _orFallback(String? value, String fallback) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value;
  }

  /// Downloads every clinical image attached to the visit, keyed by the same
  /// section label used in [_clinicalDetailsSection]. Images that fail to
  /// download (bad URL, network hiccup, deleted file) are silently skipped
  /// so one broken image doesn't take down the whole report.
  static Future<Map<String, List<pw.MemoryImage>>> _fetchClinicalImages(
    VisitModel visit,
  ) async {
    final categories = <String, List<String>>{
      'Chief Complaint': visit.chiefComplaintImages,
      'Clinical Findings': visit.clinicalFindingsImages,
      'Lab Investigation': visit.labImages,
      'Treatment Advised': visit.advisedTreatmentImages,
      'Treatment Done': visit.treatmentDoneImages,
      'Medication': visit.medicationImages,
    };

    final result = <String, List<pw.MemoryImage>>{};
    for (final category in categories.entries) {
      if (category.value.isEmpty) continue;
      final downloads = await Future.wait(category.value.map(_downloadImage));
      final images = downloads.whereType<pw.MemoryImage>().toList();
      if (images.isNotEmpty) result[category.key] = images;
    }
    return result;
  }

  static Future<pw.MemoryImage?> _downloadImage(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (_) {
      // Skip — a broken/missing image shouldn't fail the whole report.
    }
    return null;
  }

  // ---- Section builders (mirrors patient_visit_report_screen.dart) ----

  static pw.Widget _clinicHeader(
    String clinicName,
    String clinicAddress,
    String phone,
    String email,
    String webUrl,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              clinicName.toUpperCase(),
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 20,
                color: ReportTheme.pdfPrimary,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Your Smile, Our Care',
              style: const pw.TextStyle(
                fontSize: 11,
                color: ReportTheme.pdfTextMuted,
              ),
            ),
          ],
        ),
        pw.Container(
          constraints: const pw.BoxConstraints(maxWidth: 240),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                clinicAddress,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: ReportTheme.pdfSecondary,
                ),
                textAlign: pw.TextAlign.right,
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                phone,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: ReportTheme.pdfSecondary,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                email,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: ReportTheme.pdfSecondary,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                webUrl,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: ReportTheme.pdfSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _cardWrapper({
    required String title,
    required pw.Widget child,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: ReportTheme.pdfBorderLight, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const pw.BoxDecoration(
              color: ReportTheme.pdfBgHeaderBar,
              border: pw.Border(
                bottom: pw.BorderSide(color: ReportTheme.pdfBorderLight),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
                color: ReportTheme.pdfPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          pw.Padding(padding: const pw.EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }

  static pw.Widget _visitInfoCard({
    required String invoiceNo,
    required String visitNo,
    required String visitDate,
  }) {
    pw.Widget infoItem(String label, String value) => pw.Expanded(
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              color: ReportTheme.pdfTextMuted,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: ReportTheme.pdfSecondary,
            ),
          ),
        ],
      ),
    );

    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: ReportTheme.pdfBorderLight, width: 1),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Row(
        children: [
          infoItem('INVOICE NO', invoiceNo.isNotEmpty ? invoiceNo : 'N/A'),
          pw.Container(height: 26, width: 1, color: ReportTheme.pdfBorderLight),
          infoItem('VISIT NO', visitNo),
          pw.Container(height: 26, width: 1, color: ReportTheme.pdfBorderLight),
          infoItem('VISIT DATE', visitDate),
        ],
      ),
    );
  }

  static pw.Widget _companyDetailsCard(
    ClinicModel? clinic,
    String clinicName,
    String clinicAddress,
  ) {
    final rows = <pw.Widget>[
      pw.Text(
        clinicName,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
          color: ReportTheme.pdfSecondary,
        ),
      ),
      pw.SizedBox(height: 5),
      _bulletLine(clinicAddress),
    ];
    if (clinic != null && clinic.clinicRegNo.trim().isNotEmpty) {
      rows.addAll([
        pw.SizedBox(height: 3),
        _bulletLine('Clinic Reg No: ${clinic.clinicRegNo}'),
      ]);
    }
    if (clinic != null && clinic.pollutionControlCert.trim().isNotEmpty) {
      rows.addAll([
        pw.SizedBox(height: 3),
        _bulletLine('Pollution Cert: ${clinic.pollutionControlCert}'),
      ]);
    }
    if (clinic != null && clinic.tradeLicense.trim().isNotEmpty) {
      rows.addAll([
        pw.SizedBox(height: 3),
        _bulletLine('Trade License: ${clinic.tradeLicense}'),
      ]);
    }
    if (clinic != null && clinic.municipalityNoc.trim().isNotEmpty) {
      rows.addAll([
        pw.SizedBox(height: 3),
        _bulletLine('Municipality NOC: ${clinic.municipalityNoc}'),
      ]);
    }
    if (clinic != null && clinic.doctorRegCert.trim().isNotEmpty) {
      rows.addAll([
        pw.SizedBox(height: 3),
        _bulletLine('Doc Reg Cert: ${clinic.doctorRegCert}'),
      ]);
    }

    return _cardWrapper(
      title: 'COMPANY / CLINIC DETAILS',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }

  static pw.Widget _patientDetailsCard(PatientModel? patient) {
    pw.Widget row(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: ReportTheme.pdfSecondary,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 10,
                color: ReportTheme.pdfSecondary,
              ),
            ),
          ),
        ],
      ),
    );

    return _cardWrapper(
      title: 'PATIENT INFORMATION',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          row('Patient ID', ':  ${patient?.patientCode ?? 'PT-00000'}'),
          row('Patient Name', ':  ${patient?.fullName ?? 'Patient Name'}'),
          row(
            'Age / Gender',
            ':  ${patient != null ? "${patient.age} Years / ${patient.gender}" : 'N/A'}',
          ),
          row('Phone', ':  ${patient?.phone ?? 'N/A'}'),
          row(
            'Address',
            ':  ${(patient?.address.trim().isNotEmpty ?? false) ? patient!.address : 'N/A'}',
          ),
        ],
      ),
    );
  }

  static pw.Widget _bulletLine(String text) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '•  ',
          style: const pw.TextStyle(
            fontSize: 10,
            color: ReportTheme.pdfPrimary,
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            text,
            style: const pw.TextStyle(
              fontSize: 10,
              color: ReportTheme.pdfSecondary,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _clinicalDetailsSection(
    VisitModel visit,
    Map<String, List<pw.MemoryImage>> imagesByCategory,
  ) {
    final entries = <MapEntry<String, String>>[];
    if (visit.chiefComplaintText.trim().isNotEmpty)
      entries.add(MapEntry('Chief Complaint', visit.chiefComplaintText));
    if (visit.clinicalFindingsText.trim().isNotEmpty)
      entries.add(MapEntry('Clinical Findings', visit.clinicalFindingsText));
    if (visit.labText.trim().isNotEmpty)
      entries.add(MapEntry('Lab Investigation', visit.labText));
    if (visit.advisedTreatmentText.trim().isNotEmpty)
      entries.add(MapEntry('Treatment Advised', visit.advisedTreatmentText));
    if (visit.treatmentDoneText.trim().isNotEmpty)
      entries.add(MapEntry('Treatment Done', visit.treatmentDoneText));
    if (visit.medicationText.trim().isNotEmpty)
      entries.add(MapEntry('Medication', visit.medicationText));
    if (visit.nextAppointmentDate.trim().isNotEmpty)
      entries.add(MapEntry('Next Appointment', visit.nextAppointmentDate));
    if (visit.notes.trim().isNotEmpty)
      entries.add(MapEntry('Doctor Notes', visit.notes));

    // A category can carry images without any note text (e.g. lab photos
    // with no lab_text) — make sure those still get their own row.
    for (final category in imagesByCategory.keys) {
      if (entries.every((e) => e.key != category)) {
        entries.add(MapEntry(category, ''));
      }
    }

    final children = <pw.Widget>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final images = imagesByCategory[entry.key];
      if (i > 0) {
        children.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Divider(
              color: ReportTheme.pdfBorderLight,
              thickness: 0.5,
              height: 1,
            ),
          ),
        );
      }
      // Label sits on its own line and the value is a direct Column child
      // (not nested inside a Row's Expanded) so a long note can wrap and
      // split across as many pages as it needs — a Row can't break a tall
      // child across a page boundary, only Column/Text can.
      children.add(
        pw.Text(
          '${entry.key} :',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 10.5,
            color: ReportTheme.pdfSecondary,
          ),
        ),
      );
      if (entry.value.isNotEmpty || images == null) {
        children.add(pw.SizedBox(height: 3));
        children.add(
          pw.Text(
            entry.value.isNotEmpty
                ? entry.value
                : (images != null ? '(see attached images)' : ''),
            style: const pw.TextStyle(
              fontSize: 10.5,
              color: ReportTheme.pdfSecondary,
              lineSpacing: 2,
            ),
          ),
        );
      }
      if (images != null && images.isNotEmpty) {
        children.add(pw.SizedBox(height: 6));
        // Keep each image row small and independently breakable. A single
        // Wrap containing many images is measured as one widget by pdf and
        // can become taller than the page, causing TooManyPagesException.
        final imageTiles =
            images
                .map(
                  (img) => pw.Container(
                    width: 90,
                    height: 90,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: ReportTheme.pdfBorderLight,
                        width: 1,
                      ),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 4,
                      verticalRadius: 4,
                      child: pw.Image(img, fit: pw.BoxFit.cover),
                    ),
                  ),
                )
                .toList();
        for (var start = 0; start < imageTiles.length; start += 3) {
          final end =
              (start + 3 < imageTiles.length) ? start + 3 : imageTiles.length;
          children.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                children: [
                  for (final tile in imageTiles.sublist(start, end)) ...[
                    tile,
                    if (tile != imageTiles.sublist(start, end).last)
                      pw.SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          );
        }
      }
    }
    if (children.isEmpty) {
      children.add(
        pw.Text(
          'No clinical details recorded for this visit.',
          style: const pw.TextStyle(
            fontSize: 10.5,
            color: ReportTheme.pdfTextMuted,
          ),
        ),
      );
    }

    // NOTE: unlike the other cards, this section's content is unbounded
    // (arbitrary note length + any number of attached images), so it must
    // NOT be wrapped in a single decorated (bordered/filled) pw.Container —
    // package:pdf can only lay out a decorated box on a single page, and a
    // box that ends up taller than one page sends MultiPage into an
    // infinite "doesn't fit, try next page" loop, which eventually throws
    // TooManyPagesException. Only the (always-small) header bar keeps its
    // decoration; the variable-length body is a plain, undecorated Column
    // so it can be split across as many pages as it needs.
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          decoration: pw.BoxDecoration(
            color: ReportTheme.pdfBgHeaderBar,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(6),
              topRight: pw.Radius.circular(6),
            ),
            border: pw.Border.all(color: ReportTheme.pdfBorderLight, width: 1),
          ),
          child: pw.Center(
            child: pw.Text(
              'CLINICAL DETAILS',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
                color: ReportTheme.pdfPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          ),
        ),
        pw.Container(height: 1, color: ReportTheme.pdfBorderLight),
      ],
    );
  }

  static pw.Widget _paymentSummarySection(PaymentModel payment) {
    // Do not put the whole payment section in one decorated Container: a
    // decorated box is atomic in package:pdf and cannot paginate safely.
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const pw.BoxDecoration(
            color: ReportTheme.pdfBgHeaderBar,
            border: pw.Border(
              bottom: pw.BorderSide(color: ReportTheme.pdfBorderLight),
            ),
          ),
          child: pw.Text(
            'PAYMENT SUMMARY',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: ReportTheme.pdfPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        pw.Container(height: 1, color: ReportTheme.pdfBorderLight),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: pw.Wrap(
            runSpacing: 6,
            children: [
              pw.Row(
                children: [
                  pw.Text(
                    'Total Amount',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: ReportTheme.pdfSecondary,
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Text(
                    '₹ ${payment.totalAmount.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 13,
                      color: ReportTheme.pdfPrimary,
                    ),
                  ),
                  if (payment.discount > 0) ...[
                    pw.SizedBox(width: 10),
                    pw.Text(
                      '(Subtotal: ₹${payment.subtotal.toStringAsFixed(2)} | Discount: -₹${payment.discount.toStringAsFixed(2)})',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: ReportTheme.pdfTextMuted,
                      ),
                    ),
                  ],
                ],
              ),
              pw.SizedBox(width: double.infinity, height: 0),
              pw.Row(
                children: [
                  pw.Text(
                    'Payment Method',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: ReportTheme.pdfSecondary,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    ':  ${payment.paymentMethod.isNotEmpty ? payment.paymentMethod : 'N/A'}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: ReportTheme.pdfSecondary,
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Text(
                    'Payment Status',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: ReportTheme.pdfSecondary,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    ':  ${payment.paymentStatus.isNotEmpty ? payment.paymentStatus : 'N/A'}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: ReportTheme.pdfSecondary,
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Text(
                    'Payment Date',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: ReportTheme.pdfSecondary,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    ':  ${payment.paymentDate.isNotEmpty ? payment.paymentDate : 'N/A'}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: ReportTheme.pdfSecondary,
                    ),
                  ),
                ],
              ),
              if (payment.remarks.trim().isNotEmpty)
                pw.Text(
                  'Remarks: ${payment.remarks}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: ReportTheme.pdfTextMuted,
                  ),
                ),
            ],
          ),
        ),
        pw.Container(height: 1, color: ReportTheme.pdfBorderLight),
      ],
    );
  }

  static pw.Widget _termsSection(String terms) {
    final bulletPoints =
        terms.split('\n').where((t) => t.trim().isNotEmpty).toList();
    // Same reasoning as _clinicalDetailsSection: terms text is admin-editable
    // and unbounded in length, so only the header keeps its decorated box —
    // the body stays undecorated so it can split across pages safely.
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: ReportTheme.pdfBgHeaderBar,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(6),
              topRight: pw.Radius.circular(6),
            ),
            border: pw.Border.all(color: ReportTheme.pdfBorderLight, width: 1),
          ),
          child: pw.Text(
            'TERMS & CONDITIONS',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: ReportTheme.pdfPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children:
                bulletPoints.map((bp) {
                  final clean =
                      bp.startsWith('•') || bp.startsWith('-')
                          ? bp.substring(1).trim()
                          : bp.trim();
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: _bulletLine(clean),
                  );
                }).toList(),
          ),
        ),
        pw.Container(height: 1, color: ReportTheme.pdfBorderLight),
      ],
    );
  }

  static pw.Widget _footerSection() {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Divider(
            color: ReportTheme.pdfPrimary,
            thickness: 1,
            height: 1,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14),
          child: pw.Text(
            '*  Thank You For Visiting  *',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: ReportTheme.pdfPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Divider(
            color: ReportTheme.pdfPrimary,
            thickness: 1,
            height: 1,
          ),
        ),
      ],
    );
  }
}
