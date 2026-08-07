import 'visit_model.dart';
import 'patient_model.dart';
import 'payment_model.dart';
import 'clinic_model.dart';

/// Consolidated response of `POST /api/visits/getVisitReportDetails.php`,
/// bundling everything the printable Patient Visit Report template needs
/// into a single round trip (visit + patient + clinic + payment).
class VisitReportModel {
  final VisitModel visit;
  final PatientModel? patient;
  final ClinicModel? clinic;
  final PaymentModel? payment;

  const VisitReportModel({
    required this.visit,
    this.patient,
    this.clinic,
    this.payment,
  });

  factory VisitReportModel.fromJson(Map<String, dynamic> json) {
    final visitJson = json['visit'] as Map<String, dynamic>?;
    if (visitJson == null) {
      throw const FormatException('Visit report response is missing the "visit" object.');
    }
    final patientJson = json['patient'] as Map<String, dynamic>?;
    final clinicJson = json['clinic'] as Map<String, dynamic>?;
    final paymentJson = json['payment'] as Map<String, dynamic>?;

    return VisitReportModel(
      visit: VisitModel.fromJson(visitJson),
      patient: patientJson != null ? PatientModel.fromJson(patientJson) : null,
      clinic: clinicJson != null ? ClinicModel.fromJson(clinicJson) : null,
      payment: paymentJson != null ? PaymentModel.fromJson(paymentJson) : null,
    );
  }
}
