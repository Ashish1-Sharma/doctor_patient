/// Model representing a scheduled patient appointment.
class AppointmentModel {
  final int id;
  final int? visitId;
  final int patientId;
  final int doctorId;
  final String appointmentDate;
  final String procedureText;
  final String status;
  final String createdAt;
  final String updatedAt;

  const AppointmentModel({
    required this.id,
    this.visitId,
    required this.patientId,
    required this.doctorId,
    required this.appointmentDate,
    required this.procedureText,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    int? parseOptionalId(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      return int.tryParse(val.toString());
    }

    return AppointmentModel(
      id: parseId(json['id']),
      visitId: parseOptionalId(json['visitId'] ?? json['visit_id']),
      patientId: parseId(json['patientId'] ?? json['patient_id']),
      doctorId: parseId(json['doctorId'] ?? json['doctor_id']),
      appointmentDate: json['appointmentDate'] as String? ?? json['appointment_date'] as String? ?? '',
      procedureText: json['procedureText'] as String? ?? json['procedure_text'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visitId': visitId,
      'patientId': patientId,
      'doctorId': doctorId,
      'appointmentDate': appointmentDate,
      'procedureText': procedureText,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  AppointmentModel copyWith({
    int? id,
    int? visitId,
    int? patientId,
    int? doctorId,
    String? appointmentDate,
    String? procedureText,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      procedureText: procedureText ?? this.procedureText,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
