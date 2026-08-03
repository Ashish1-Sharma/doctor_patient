/// Model representing user registration details.
class RegistrationModel {
  final int id;
  final String userName;
  final String userEmail;
  final String userMobile;
  final String country;
  final String password;
  final String regDate;
  final String validity;
  final String purchaseDate;
  final String purchaseId;
  final String flag;
  final int parentId;
  final bool status;
  final String accessKey;

  const RegistrationModel({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.userMobile,
    required this.country,
    required this.password,
    required this.regDate,
    required this.validity,
    required this.purchaseDate,
    required this.purchaseId,
    required this.flag,
    required this.parentId,
    required this.status,
    required this.accessKey,
  });

  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    return RegistrationModel(
      id: json['id'] as int? ?? 0,
      userName: json['userName'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      userMobile: json['userMobile'] as String? ?? '',
      country: json['country'] as String? ?? '',
      password: json['password'] as String? ?? '',
      regDate: json['regDate'] as String? ?? '',
      validity: json['validity'] as String? ?? '',
      purchaseDate: json['purchaseDate'] as String? ?? '',
      purchaseId: json['purchaseId'] as String? ?? '',
      flag: json['flag'] as String? ?? '0',
      parentId: json['parentId'] as int? ?? 0,
      status: json['status'] as bool? ?? false,
      accessKey: json['accessKey'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'userEmail': userEmail,
      'userMobile': userMobile,
      'country': country,
      'password': password,
      'regDate': regDate,
      'validity': validity,
      'purchaseDate': purchaseDate,
      'purchaseId': purchaseId,
      'flag': flag,
      'parentId': parentId,
      'status': status,
      'accessKey': accessKey,
    };
  }
}
