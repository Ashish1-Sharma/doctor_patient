import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/clinic_model.dart';

class ClinicService {
  static const String _baseUrl = 'https://tworingz.com/doctor_patient/api/company';

  /// Retrieve the clinic profile details for a given doctor (userId).
  static Future<ClinicModel?> getClinicDetails(int doctorId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/getCompanyDetails.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': doctorId}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['statusCode'] == 200 && responseData['body'] is List) {
          final list = responseData['body'] as List;
          if (list.isNotEmpty) {
            return ClinicModel.fromJson(list.first);
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
