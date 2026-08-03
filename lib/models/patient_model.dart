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
    required this.createdBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as int? ?? 0,
      parentId: json['parentId'] as int? ?? json['parent_id'] as int? ?? 0,
      patientCode: json['patientCode'] as String? ?? json['patient_code'] as String? ?? '',
      profileImage: json['profileImage'] as String? ?? json['profile_image'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      age: json['age'] as int? ?? 0,
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
      totalVisits: json['totalVisits'] as int? ?? json['total_visits'] as int? ?? 0,
      lastVisitDate: json['lastVisitDate'] as String? ?? json['last_visit_date'] as String? ?? '',
      createdBy: json['createdBy'] as int? ?? json['created_by'] as int? ?? 0,
      status: json['status'] is int
          ? (json['status'] as int) == 1
          : json['status'] as bool? ?? false,
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
      'createdBy': createdBy,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
