/// Model representing the Clinic / Company settings.
class ClinicModel {
  final int id;
  final String companyName;
  final String companyAddress;
  final String clinicRegNo;
  final String pollutionControlCert;
  final String tradeLicense;
  final String municipalityNoc;
  final String doctorRegCert;
  final String terms;

  ClinicModel({
    required this.id,
    required this.companyName,
    required this.companyAddress,
    required this.clinicRegNo,
    required this.pollutionControlCert,
    required this.tradeLicense,
    required this.municipalityNoc,
    required this.doctorRegCert,
    required this.terms,
  });

  factory ClinicModel.fromJson(Map<String, dynamic> json) {
    return ClinicModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      companyName: json['companyName'] ?? '',
      companyAddress: json['companyAddress'] ?? '',
      clinicRegNo: json['clinic_reg_no'] ?? '',
      pollutionControlCert: json['pollution_control_cert'] ?? '',
      tradeLicense: json['trade_license'] ?? '',
      municipalityNoc: json['municipality_noc'] ?? '',
      doctorRegCert: json['doctor_reg_cert'] ?? '',
      terms: json['terms'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'clinic_reg_no': clinicRegNo,
      'pollution_control_cert': pollutionControlCert,
      'trade_license': tradeLicense,
      'municipality_noc': municipalityNoc,
      'doctor_reg_cert': doctorRegCert,
      'terms': terms,
    };
  }
}
