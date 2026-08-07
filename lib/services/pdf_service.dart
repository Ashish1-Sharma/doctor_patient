import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Service responsible for converting HTML templates into A4 PDF documents.
/// Implements caching in the system temporary directory to optimize performance
/// and avoid redundant generation cycles during screen redraws or orientation changes.
class PdfService {
  // In-memory registry of cached files during the active app session
  static final Map<String, File> _cacheRegistry = {};

  /// Converts the provided [htmlContent] into A4 PDF bytes using the native print engine.
  /// Caches the resulting document under [fileName] inside the system temporary directory.
  /// Returns the generated [File] containing the PDF.
  static Future<File> getOrGeneratePdf({
    required String htmlContent,
    required String fileName,
    bool forceRefresh = false,
  }) async {
    final tempDir = Directory.systemTemp;
    final sanitizedFileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final filePath = '${tempDir.path}/$sanitizedFileName';
    final tempFile = File(filePath);

    // If cache is valid and refresh is not forced, reuse the file
    if (!forceRefresh && _cacheRegistry.containsKey(sanitizedFileName) && await tempFile.exists()) {
      return _cacheRegistry[sanitizedFileName]!;
    }

    // Convert HTML template to PDF document using the printing plugin
    // ignore: deprecated_member_use
    final Uint8List pdfBytes = await Printing.convertHtml(
      html: htmlContent,
      format: PdfPageFormat.a4,
    );

    // Persist to the system's temp directory
    await tempFile.writeAsBytes(pdfBytes, flush: true);
    _cacheRegistry[sanitizedFileName] = tempFile;

    return tempFile;
  }

  /// Removes a specific file from cache and deletes it from storage.
  static Future<void> deleteFromCache(String fileName) async {
    final sanitizedFileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = _cacheRegistry.remove(sanitizedFileName);
    if (file != null) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Silent catch: temporary file deletion failure should not block user experience
      }
    }
  }

  /// Purges all cached files from the app session cache and storage.
  static Future<void> clearAllCache() async {
    for (final file in _cacheRegistry.values) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Silent catch
      }
    }
    _cacheRegistry.clear();
  }
}
