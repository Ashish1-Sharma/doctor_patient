import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/upload_service.dart';

/// Reusable and interactive Image Picker widget for clinical uploads.
/// Supports taking new photos via Camera and picking files from Gallery.
/// Uploads real image files to revecosmetic.com.
class MedicalImagePicker extends StatefulWidget {
  final String label;
  final List<String> images;
  final Function(List<String>) onImagesChanged;

  const MedicalImagePicker({
    super.key,
    required this.label,
    required this.images,
    required this.onImagesChanged,
  });

  @override
  State<MedicalImagePicker> createState() => _MedicalImagePickerState();
}

class _MedicalImagePickerState extends State<MedicalImagePicker> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Widget _buildSourceButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.tealAccent, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primarySlate,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Optimize size for medical uploading
      );

      if (file == null) return;

      setState(() {
        _isUploading = true;
      });

      final String? uploadedUrl = await UploadService.uploadImage(file);

      setState(() {
        _isUploading = false;
      });

      if (uploadedUrl != null) {
        final updated = List<String>.from(widget.images)..add(uploadedUrl);
        widget.onImagesChanged(updated);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded successfully!'),
              backgroundColor: AppTheme.tealAccent,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image. Please try again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showUploadPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Attach Clinical Document',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primarySlate,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Camera and Gallery buttons in a Row
                Row(
                  children: [
                    Expanded(
                      child: _buildSourceButton(
                        context: context,
                        icon: Icons.camera_alt_outlined,
                        label: 'Take Photo',
                        onTap: () {
                          Navigator.pop(context);
                          _pickAndUploadImage(ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSourceButton(
                        context: context,
                        icon: Icons.photo_library_outlined,
                        label: 'Upload Gallery',
                        onTap: () {
                          Navigator.pop(context);
                          _pickAndUploadImage(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPreviewDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label, style: textTheme.labelLarge),
            Text(
              '${widget.images.length} Attached',
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: AppTheme.secondarySlate.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add button
              GestureDetector(
                onTap: _isUploading ? null : () => _showUploadPicker(context),
                child: Opacity(
                  opacity: _isUploading ? 0.6 : 1.0,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.tealAccent.withValues(alpha: 0.3),
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: AppTheme.tealAccent, size: 24),
                        SizedBox(height: 4),
                        Text('Add Image', style: TextStyle(color: AppTheme.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Uploading indicator
              if (_isUploading) ...[
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tealAccent),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Uploading...',
                        style: TextStyle(color: AppTheme.secondarySlate, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Image cards
              ...List.generate(widget.images.length, (index) {
                final imgUrl = widget.images[index];
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _showPreviewDialog(context, imgUrl),
                      child: Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(imgUrl, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          final updated = List<String>.from(widget.images)..removeAt(index);
                          widget.onImagesChanged(updated);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
