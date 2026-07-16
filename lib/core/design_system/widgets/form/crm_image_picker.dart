import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:dio/dio.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

class CRMImagePicker extends StatefulWidget {
  final List<String> imageUrls;
  final Function(String url) onImageAdded;
  final Function(int index) onImageRemoved;
  final Function(int index, String url) onImageReplaced;
  final int maxImages;
  final String uploadEndpoint;

  const CRMImagePicker({
    super.key,
    required this.imageUrls,
    required this.onImageAdded,
    required this.onImageRemoved,
    required this.onImageReplaced,
    this.maxImages = 3,
    this.uploadEndpoint = '/properties/upload-media',
  });

  @override
  State<CRMImagePicker> createState() => _CRMImagePickerState();
}

class _CRMImagePickerState extends State<CRMImagePicker> {
  bool _isUploading = false;

  Future<void> _showSourceDialog(int index) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take Photo (Camera)'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(index, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(index, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(int index, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final File file = File(pickedFile.path);
      
      // Perform recompression
      final String targetPath = "${Directory.systemTemp.path}/compressed_img_${DateTime.now().millisecondsSinceEpoch}.jpg";
      
      XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 1200,
        minHeight: 1200,
      );

      File uploadFile = file;
      if (compressedFile != null) {
        uploadFile = File(compressedFile.path);
        int compressedSize = await uploadFile.length();
        if (compressedSize > 5 * 1024 * 1024) {
          throw Exception("Compressed image exceeds the 5 MB file limit.");
        }
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(uploadFile.path, filename: 'upload_image.jpg'),
      });

      // Use active HTTP client to upload (assuming a global base config exists)
      final response = await Dio(BaseOptions(baseUrl: 'http://localhost:5000/api/v1')).post(
        widget.uploadEndpoint,
        data: formData,
      );
      
      final publicUrl = response.data['data']['url'];

      setState(() {
        if (index < widget.imageUrls.length) {
          widget.onImageReplaced(index, publicUrl);
        } else {
          widget.onImageAdded(publicUrl);
        }
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e"), backgroundColor: CRMColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photos / Attachments (Max ${widget.maxImages})',
              style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
            ),
            if (_isUploading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: CRMSpacing.s),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(widget.maxImages, (index) {
            final hasImage = index < widget.imageUrls.length;
            final imageUrl = hasImage ? widget.imageUrls[index] : null;

            return Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: CRMColors.background,
                    borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                    border: Border.all(color: CRMColors.borderOf(context), width: 1.5),
                  ),
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(CRMBorderRadius.s - 1.5),
                          child: Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            width: 90,
                            height: 90,
                          ),
                        )
                      : Icon(Icons.add_photo_alternate_outlined, color: CRMColors.textSecondaryOf(context), size: 28),
                ),
                const SizedBox(height: CRMSpacing.xs),
                if (hasImage) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_outlined, size: 16, color: CRMColors.primaryOf(context)),
                        onPressed: () => _showSourceDialog(index),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: CRMColors.danger),
                        onPressed: () => widget.onImageRemoved(index),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  )
                ] else ...[
                  TextButton(
                    onPressed: () => _showSourceDialog(index),
                    child: const Text('Add', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                ],
              ],
            );
          }),
        ),
      ],
    );
  }
}
