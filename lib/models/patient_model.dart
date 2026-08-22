/// Model representing a patient's profile details.
class PatientModel {
  final int id;
  final int parentId;
  final String patientCode;
  final String profileImage;
  final String fullName;
  final int age;
  final String gender;
  final String dateOfBirth;
  final String phone;
  final String email;
  final String address;
  final List<String> medicalConditions;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final int totalVisits;
  final String lastVisitDate;

  /// Outstanding balance across all of this patient's non-paid invoices.
  /// Computed server-side by patients/list.php; defaults to 0 elsewhere.
  final double pendingAmount;
  final int createdBy;
  final bool status;
  final String createdAt;
  final String updatedAt;

  const PatientModel({
    required this.id,
    required this.parentId,
    required this.patientCode,
    required this.profileImage,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.dateOfBirth,
    required this.phone,
    required this.email,
    required this.address,
    required this.medicalConditions,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.totalVisits,
    required this.lastVisitDate,
    this.pendingAmount = 0.0,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    double parseAmount(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return PatientModel(
      id: parseId(json['id']),
      parentId: parseId(json['parentId'] ?? json['parent_id']),
      patientCode: json['patientCode'] as String? ?? json['patient_code'] as String? ?? '',
      profileImage: json['profileImage'] as String? ?? json['profile_image'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      age: parseId(json['age']),
      gender: json['gender'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] as String? ?? json['date_of_birth'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      medicalConditions: (json['medicalConditions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['medical_conditions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      emergencyContactName: json['emergencyContactName'] as String? ?? json['emergency_contact_name'] as String? ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] as String? ?? json['emergency_contact_phone'] as String? ?? '',
      totalVisits: parseId(json['totalVisits'] ?? json['total_visits']),
      lastVisitDate: json['lastVisitDate'] as String? ?? json['last_visit_date'] as String? ?? '',
      pendingAmount: parseAmount(json['pendingAmount'] ?? json['pending_amount']),
      createdBy: parseId(json['createdBy'] ?? json['created_by']),
      status: json['status'] is int
          ? (json['status'] as int) == 1
          : (json['status'] is String
              ? (int.tryParse(json['status'].toString()) == 1)
              : json['status'] as bool? ?? false),
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'patientCode': patientCode,
      'profileImage': profileImage,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'phone': phone,
      'email': email,
      'address': address,
      'medicalConditions': medicalConditions,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'totalVisits': totalVisits,
      'lastVisitDate': lastVisitDate,
      'pendingAmount': pendingAmount,
      'createdBy': createdBy,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
