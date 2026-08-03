import 'package:flutter/material.dart';
import '../models/visit_model.dart';
import '../models/payment_model.dart';

/// VisitProvider holds the active VisitModel and PaymentModel state
/// for the New Treatment workflow.
class VisitProvider extends ChangeNotifier {
  late VisitModel _visit;
  late PaymentModel _payment;

  VisitModel get visit => _visit;
  PaymentModel get payment => _payment;

  VisitProvider() {
    reset();
  }

  /// Reset the provider to the default clean state.
  void reset({int parentId = 1, int doctorId = 1}) {
    final nowStr = DateTime.now().toString().substring(0, 19);
    final uniqueId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    _visit = VisitModel(
      id: uniqueId,
      parentId: parentId,
      patientId: 0,
      doctorId: doctorId,
      visitNo: 'VIS-0001',
      visitDate: nowStr,
      chiefComplaintText: '',
      chiefComplaintImages: const [],
      clinicalFindingsText: '',
      clinicalFindingsImages: const [],
      labText: '',
      labImages: const [],
      advisedTreatmentText: '',
      advisedTreatmentImages: const [],
      treatmentDoneText: '',
      treatmentDoneImages: const [],
      medicationText: '',
      medicationImages: const [],
      nextAppointmentDate: '',
      notes: '',
      status: 'Pending',
      createdAt: nowStr,
      updatedAt: nowStr,
    );

    _payment = PaymentModel(
      id: uniqueId + 1,
      parentId: parentId,
      visitId: uniqueId,
      patientId: 0,
      invoiceNo: 'INV-${uniqueId.toString().substring(3)}',
      subtotal: 0.0,
      discount: 0.0,
      totalAmount: 0.0,
      paidAmount: 0.0,
      pendingAmount: 0.0,
      paymentMethod: 'UPI',
      paymentStatus: 'Pending',
      paymentDate: nowStr,
      remarks: '',
      createdBy: doctorId,
      createdAt: nowStr,
      updatedAt: nowStr,
    );
    notifyListeners();
  }

  /// Step 1: Update patient details in the visit and payment.
  void updatePatient({required int patientId, required dynamic visitNo}) {
    String formattedVisitNo = 'VIS-0001';
    if (visitNo is int) {
      formattedVisitNo = 'VIS-${visitNo.toString().padLeft(4, '0')}';
    } else if (visitNo != null) {
      formattedVisitNo = visitNo.toString();
    }

    _visit = _visit.copyWith(
      patientId: patientId,
      visitNo: formattedVisitNo,
      visitDate: DateTime.now().toString().substring(0, 19),
    );
    _payment = PaymentModel(
      id: _payment.id,
      parentId: _payment.parentId,
      visitId: _payment.visitId,
      patientId: patientId,
      invoiceNo: _payment.invoiceNo,
      subtotal: _payment.subtotal,
      discount: _payment.discount,
      totalAmount: _payment.totalAmount,
      paidAmount: _payment.paidAmount,
      pendingAmount: _payment.pendingAmount,
      paymentMethod: _payment.paymentMethod,
      paymentStatus: _payment.paymentStatus,
      paymentDate: _payment.paymentDate,
      remarks: _payment.remarks,
      createdBy: _payment.createdBy,
      createdAt: _payment.createdAt,
      updatedAt: _payment.updatedAt,
    );
    notifyListeners();
  }

  /// Step 2: Update complaints and clinical findings.
  void updateFindings({
    required String chiefComplaint,
    required List<String> chiefComplaintImages,
    required String clinicalFindings,
    required List<String> clinicalFindingsImages,
  }) {
    _visit = _visit.copyWith(
      chiefComplaintText: chiefComplaint,
      chiefComplaintImages: chiefComplaintImages,
      clinicalFindingsText: clinicalFindings,
      clinicalFindingsImages: clinicalFindingsImages,
      updatedAt: DateTime.now().toString().substring(0, 19),
    );
    notifyListeners();
  }

  /// Step 3: Update Lab & Advised Treatments.
  void updateLab({
    required String labText,
    required List<String> labImages,
    required String advisedTreatment,
    required List<String> advisedTreatmentImages,
  }) {
    _visit = _visit.copyWith(
      labText: labText,
      labImages: labImages,
      advisedTreatmentText: advisedTreatment,
      advisedTreatmentImages: advisedTreatmentImages,
      updatedAt: DateTime.now().toString().substring(0, 19),
    );
    notifyListeners();
  }

  /// Step 4: Update Done Treatments & Medications.
  void updateTreatment({
    required String treatmentDone,
    required List<String> treatmentDoneImages,
    required String medication,
    required List<String> medicationImages,
  }) {
    _visit = _visit.copyWith(
      treatmentDoneText: treatmentDone,
      treatmentDoneImages: treatmentDoneImages,
      medicationText: medication,
      medicationImages: medicationImages,
      updatedAt: DateTime.now().toString().substring(0, 19),
    );
    notifyListeners();
  }

  /// Step 5: Update Payment figures.
  void updatePayment({
    required double total,
    required double paid,
    required String method,
  }) {
    final pending = total - paid;
    String status = 'Pending';
    if (pending <= 0) {
      status = 'Paid';
    } else if (paid > 0) {
      status = 'Partial';
    }

    _payment = PaymentModel(
      id: _payment.id,
      parentId: _payment.parentId,
      visitId: _payment.visitId,
      patientId: _payment.patientId,
      invoiceNo: _payment.invoiceNo,
      subtotal: total,
      discount: 0.0,
      totalAmount: total,
      paidAmount: paid,
      pendingAmount: pending < 0 ? 0.0 : pending,
      paymentMethod: method,
      paymentStatus: status,
      paymentDate: DateTime.now().toString().substring(0, 19),
      remarks: pending > 0 ? 'Balance ₹${pending.toStringAsFixed(0)} pending.' : 'Fully paid.',
      createdBy: _payment.createdBy,
      createdAt: _payment.createdAt,
      updatedAt: DateTime.now().toString().substring(0, 19),
    );
    notifyListeners();
  }
}
