import 'package:flutter/services.dart' show rootBundle;
import '../models/visit_report_model.dart';

/// Helper class to load, parse, and build the dynamic HTML string for the PDF template.
class HtmlBuilder {
  static const String templatePath = 'lib/templates/patient_visit.html';

  /// Loads the HTML template from assets and replaces all placeholders with actual values.
  static Future<String> buildReportHtml({
    required VisitReportModel report,
    required String doctorPhone,
    required String doctorEmail,
  }) async {
    // 1. Load the raw HTML template
    String html = await rootBundle.loadString(templatePath);

    final visit = report.visit;
    final patient = report.patient;
    final clinic = report.clinic;
    final payment = report.payment;

    // 2. Build Clinic details
    final clinicName = clinic?.companyName ?? 'ABC DENTAL CLINIC';
    final clinicAddress = clinic?.companyAddress ?? '24 MG Road, Delhi - 110001';
    final clinicPhone = doctorPhone;
    final clinicEmail = doctorEmail;
    final clinicWebsite = 'www.${clinicName.toLowerCase().replaceAll(' ', '')}.com';

    html = html.replaceAll('{{clinic.name}}', clinicName);
    html = html.replaceAll('{{clinic.address}}', clinicAddress);
    html = html.replaceAll('{{clinic.phone}}', clinicPhone);
    html = html.replaceAll('{{clinic.email}}', clinicEmail);
    html = html.replaceAll('{{clinic.website}}', clinicWebsite);

    // 3. Process Clinic optional certificates (GST, DL, Trade License, etc.)
    html = _processConditionalBlock(html, 'clinic.gst', clinic?.pollutionControlCert);
    html = _processConditionalBlock(html, 'clinic.dl', clinic?.clinicRegNo);
    html = _processConditionalBlock(html, 'clinic.trade_license', clinic?.tradeLicense);
    html = _processConditionalBlock(html, 'clinic.municipality_noc', clinic?.municipalityNoc);
    html = _processConditionalBlock(html, 'clinic.doctor_reg_cert', clinic?.doctorRegCert);

    // 4. Build Patient details
    html = html.replaceAll('{{patient.id}}', patient?.patientCode ?? 'PT-00000');
    html = html.replaceAll('{{patient.name}}', patient?.fullName ?? 'N/A');
    html = html.replaceAll('{{patient.age}}', patient != null ? '${patient.age} Years' : 'N/A');
    html = html.replaceAll('{{patient.gender}}', patient?.gender ?? 'N/A');
    html = html.replaceAll('{{patient.phone}}', patient?.phone ?? 'N/A');
    html = html.replaceAll('{{patient.address}}', (patient?.address != null && patient!.address.trim().isNotEmpty) ? patient.address : 'N/A');

    // 5. Build Visit Info details
    html = html.replaceAll('{{visit.invoice_no}}', (payment != null && payment.invoiceNo.isNotEmpty) ? payment.invoiceNo : 'N/A');
    html = html.replaceAll('{{visit.visit_no}}', visit.visitNo.isNotEmpty ? visit.visitNo : 'N/A');
    html = html.replaceAll('{{visit.visit_date}}', visit.visitDate.isNotEmpty ? visit.visitDate : 'N/A');

    // 6. Build Clinical Details section & hide empty fields
    html = _processClinicalRowBlock(html, 'chief_complaint_row', visit.chiefComplaintText, '{{visit.chief_complaint}}');
    html = _processClinicalRowBlock(html, 'clinical_findings_row', visit.clinicalFindingsText, '{{visit.clinical_findings}}');
    html = _processClinicalRowBlock(html, 'lab_investigation_row', visit.labText, '{{visit.lab_investigation}}');
    html = _processClinicalRowBlock(html, 'treatment_advised_row', visit.advisedTreatmentText, '{{visit.treatment_advised}}');
    html = _processClinicalRowBlock(html, 'treatment_done_row', visit.treatmentDoneText, '{{visit.treatment_done}}');
    
    // Format medications cleanly as a list or block
    final formattedMedication = _formatMedication(visit.medicationText);
    html = _processClinicalRowBlock(html, 'medication_row', visit.medicationText, '{{visit.medication}}', customValue: formattedMedication);
    
    html = _processClinicalRowBlock(html, 'next_appointment_row', visit.nextAppointmentDate, '{{visit.next_appointment}}');
    html = _processClinicalRowBlock(html, 'doctor_notes_row', visit.notes, '{{visit.doctor_notes}}');

    // 7. Build Payment Summary details
    html = html.replaceAll('{{payment.total_amount}}', payment != null ? payment.totalAmount.toStringAsFixed(2) : '0.00');
    html = html.replaceAll('{{payment.payment_date}}', (payment != null && payment.paymentDate.isNotEmpty) ? payment.paymentDate : 'N/A');

    // 8. Build Terms & Conditions section & hide if empty
    final termsText = clinic?.terms ?? '';
    if (termsText.trim().isEmpty) {
      // Remove terms section entirely
      final pattern = RegExp(r'<!-- terms_section -->[\s\S]*?<!-- /terms_section -->');
      html = html.replaceAll(pattern, '');
    } else {
      // Replace comments and inject formatted terms list
      html = html.replaceAll('<!-- terms_section -->', '');
      html = html.replaceAll('<!-- /terms_section -->', '');
      html = html.replaceAll('{{terms}}', _formatTerms(termsText));
    }

    return html;
  }

  /// Processes if/else block comments: keeps the block if value is present, removes if empty.
  static String _processConditionalBlock(String html, String fieldKey, String? value) {
    final startTag = '<!-- IF $fieldKey -->';
    final endTag = '<!-- ENDIF $fieldKey -->';
    
    if (value == null || value.trim().isEmpty) {
      // Remove the entire block including the tags
      final pattern = RegExp('$startTag[\\s\\S]*?$endTag');
      return html.replaceAll(pattern, '');
    } else {
      // Keep the block, replace placeholders, and strip the tags
      var processed = html;
      processed = processed.replaceAll(startTag, '');
      processed = processed.replaceAll(endTag, '');
      processed = processed.replaceAll('{{$fieldKey}}', value.trim());
      return processed;
    }
  }

  /// Processes clinical row blocks: if the field value is empty, removes the entire block from the DOM.
  static String _processClinicalRowBlock(
    String html, 
    String rowKey, 
    String textValue, 
    String placeholder, {
    String? customValue,
  }) {
    final startTag = '<!-- $rowKey -->';
    final endTag = '<!-- /$rowKey -->';

    if (textValue.trim().isEmpty) {
      // Remove the entire block
      final pattern = RegExp('$startTag[\\s\\S]*?$endTag');
      return html.replaceAll(pattern, '');
    } else {
      // Keep block, replace placeholder, and strip block comments
      var processed = html;
      processed = processed.replaceAll(startTag, '');
      processed = processed.replaceAll(endTag, '');
      processed = processed.replaceAll(placeholder, customValue ?? textValue.trim().replaceAll('\n', '<br>'));
      return processed;
    }
  }

  /// Formats a multi-line medication string into a clean HTML ordered list.
  static String _formatMedication(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    
    if (!trimmed.contains('\n')) {
      return trimmed.replaceAll('\n', '<br>');
    }
    
    final lines = trimmed.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final listItems = lines.map((line) {
      // Strip any existing number prefix like "1. ", "2. " since <ol> auto-generates numbers
      final cleanLine = line.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '');
      return '<li>$cleanLine</li>';
    }).join('');
    
    return '<ol class="medication-list">$listItems</ol>';
  }

  /// Formats multi-line terms and conditions into HTML bullet list items.
  static String _formatTerms(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    
    final lines = trimmed.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    return lines.map((line) {
      // Strip any bullet prefixes like "- ", "* ", "• "
      final cleanLine = line.replaceFirst(RegExp(r'^[-*•]\s*'), '');
      return '<li>$cleanLine</li>';
    }).join('');
  }
}
