import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

/// Service to handle file uploading to revecosmetic.com.
class UploadService {
  static const String uploadUrl = 'https://revecosmetic.com/upload.php';

  /// Uploads a selected XFile to the server and returns the image URL.
  /// Returns null if the upload fails.
  static Future<String?> uploadImage(XFile file) async {
    developer.log('UploadService.uploadImage: Starting upload for ${file.name}');
    try {
      final uri = Uri.parse(uploadUrl);

      final request = http.MultipartRequest('POST', uri);

      // Read file bytes
      final bytes = await file.readAsBytes();
      
      String extension = file.name.split('.').last.toLowerCase();

      MediaType mediaType;

      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mediaType = MediaType('image', 'jpeg');
          break;

        case 'png':
          mediaType = MediaType('image', 'png');
          break;

        case 'gif':
          mediaType = MediaType('image', 'gif');
          break;

        case 'webp':
          mediaType = MediaType('image', 'webp');
          break;

        default:
          mediaType = MediaType('application', 'octet-stream');
      }

      // Create multipart file from bytes (works for both web and mobile) with specific Content-Type
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: file.name,
        contentType: mediaType,
      );

      request.files.add(multipartFile);

      developer.log('UploadService.uploadImage: Sending POST request to $uploadUrl');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      developer.log('UploadService.uploadImage: Response status: ${response.statusCode}');
      developer.log('UploadService.uploadImage: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['url'] != null) {
          return data['url'] as String;
        }
      }
      return null;
    } catch (e) {
      developer.log('UploadService.uploadImage: Exception caught: $e');
      return null;
    }
  }
}
