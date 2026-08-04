/// Model representing a doctor-patient clinical visit transaction.
class VisitModel {
  final int id;
  final int parentId;
  final int patientId;
  final int doctorId;
  final String visitNo;
  final String visitDate;

  final String chiefComplaintText;
  final List<String> chiefComplaintImages;

  final String clinicalFindingsText;
  final List<String> clinicalFindingsImages;

  final String labText;
  final List<String> labImages;

  final String advisedTreatmentText;
  final List<String> advisedTreatmentImages;

  final String treatmentDoneText;
  final List<String> treatmentDoneImages;

  final String medicationText;
  final List<String> medicationImages;

  final String nextAppointmentDate;
  final String notes;
  final String status;
  final String createdAt;
  final String updatedAt;

  const VisitModel({
    required this.id,
    required this.parentId,
    required this.patientId,
    required this.doctorId,
    required this.visitNo,
    required this.visitDate,
    required this.chiefComplaintText,
    required this.chiefComplaintImages,
    required this.clinicalFindingsText,
    required this.clinicalFindingsImages,
    required this.labText,
    required this.labImages,
    required this.advisedTreatmentText,
    required this.advisedTreatmentImages,
    required this.treatmentDoneText,
    required this.treatmentDoneImages,
    required this.medicationText,
    required this.medicationImages,
    required this.nextAppointmentDate,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    return VisitModel(
      id: parseId(json['id']),
      parentId: parseId(json['parentId'] ?? json['parent_id']),
      patientId: parseId(json['patientId'] ?? json['patient_id']),
      doctorId: parseId(json['doctorId'] ?? json['doctor_id']),
      visitNo: json['visitNo']?.toString() ?? json['visit_no']?.toString() ?? '',
      visitDate: json['visitDate'] as String? ?? json['visit_date'] as String? ?? '',
      chiefComplaintText: json['chiefComplaintText'] as String? ?? json['chief_complaint_text'] as String? ?? '',
      chiefComplaintImages: (json['chiefComplaintImages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['chief_complaint_images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      clinicalFindingsText: json['clinicalFindingsText'] as String? ?? json['clinical_findings_text'] as String? ?? '',
      clinicalFindingsImages: (json['clinicalFindingsImages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['clinical_findings_images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      labText: json['labText'] as String? ?? json['lab_text'] as String? ?? '',
      labImages: (json['labImages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['lab_images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      advisedTreatmentText: json['advisedTreatmentText'] as String? ?? json['advised_treatment_text'] as String? ?? '',
      advisedTreatmentImages: (json['advisedTreatmentImages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['advised_treatment_images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      treatmentDoneText: json['treatmentDoneText'] as String? ?? json['treatment_done_text'] as String? ?? json['treatmentDone'] as String? ?? '',
      treatmentDoneImages: (json['treatmentDoneImages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['treatment_done_images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      medicationText: json['medicationText'] as String? ?? json['medication_text'] as String? ?? '',
      medicationImages: (json['medicationImages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['medication_images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      nextAppointmentDate: json['nextAppointmentDate'] as String? ?? json['next_appointment_date'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'patientId': patientId,
      'doctorId': doctorId,
      'visitNo': visitNo,
      'visitDate': visitDate,
      'chiefComplaintText': chiefComplaintText,
      'chiefComplaintImages': chiefComplaintImages,
      'clinicalFindingsText': clinicalFindingsText,
      'clinicalFindingsImages': clinicalFindingsImages,
      'labText': labText,
      'labImages': labImages,
      'advisedTreatmentText': advisedTreatmentText,
      'advisedTreatmentImages': advisedTreatmentImages,
      'treatmentDoneText': treatmentDoneText,
      'treatmentDoneImages': treatmentDoneImages,
      'medicationText': medicationText,
      'medicationImages': medicationImages,
      'nextAppointmentDate': nextAppointmentDate,
      'notes': notes,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create a copy of the VisitModel with updated fields.
  VisitModel copyWith({
    int? id,
    int? parentId,
    int? patientId,
    int? doctorId,
    String? visitNo,
    String? visitDate,
    String? chiefComplaintText,
    List<String>? chiefComplaintImages,
    String? clinicalFindingsText,
    List<String>? clinicalFindingsImages,
    String? labText,
    List<String>? labImages,
    String? advisedTreatmentText,
    List<String>? advisedTreatmentImages,
    String? treatmentDoneText,
    List<String>? treatmentDoneImages,
    String? medicationText,
    List<String>? medicationImages,
    String? nextAppointmentDate,
    String? notes,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return VisitModel(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      visitNo: visitNo ?? this.visitNo,
      visitDate: visitDate ?? this.visitDate,
      chiefComplaintText: chiefComplaintText ?? this.chiefComplaintText,
      chiefComplaintImages: chiefComplaintImages ?? this.chiefComplaintImages,
      clinicalFindingsText: clinicalFindingsText ?? this.clinicalFindingsText,
      clinicalFindingsImages: clinicalFindingsImages ?? this.clinicalFindingsImages,
      labText: labText ?? this.labText,
      labImages: labImages ?? this.labImages,
      advisedTreatmentText: advisedTreatmentText ?? this.advisedTreatmentText,
      advisedTreatmentImages: advisedTreatmentImages ?? this.advisedTreatmentImages,
      treatmentDoneText: treatmentDoneText ?? this.treatmentDoneText,
      treatmentDoneImages: treatmentDoneImages ?? this.treatmentDoneImages,
      medicationText: medicationText ?? this.medicationText,
      medicationImages: medicationImages ?? this.medicationImages,
      nextAppointmentDate: nextAppointmentDate ?? this.nextAppointmentDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
