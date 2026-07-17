import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:nblistings/core/api/dio_client.dart';
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
      MultipartFile multipartFile;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          throw Exception("Image size exceeds the 5 MB file limit.");
        }
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: pickedFile.name,
          contentType: MediaType('image', 'jpeg'),
        );
      } else {
        final File file = File(pickedFile.path);
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

        multipartFile = await MultipartFile.fromFile(
          uploadFile.path, 
          filename: 'upload_image.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
      }

      final formData = FormData.fromMap({
        'file': multipartFile,
      });

      final response = await DioClient.dio.post(
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
    final showUploadField = widget.imageUrls.length < widget.maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photos / Attachments (${widget.imageUrls.length}/${widget.maxImages})',
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
        
        // Horizontal Upload Button/Field
        if (showUploadField) ...[
          InkWell(
            onTap: _isUploading ? null : () => _showSourceDialog(widget.imageUrls.length),
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            child: CustomPaint(
              painter: DashedBorderPainter(
                color: CRMColors.primaryOf(context).withOpacity(0.4),
                radius: CRMBorderRadius.s,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: CRMSpacing.m, horizontal: CRMSpacing.m),
                decoration: BoxDecoration(
                  color: CRMColors.primaryOf(context).withOpacity(0.02),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined, 
                      size: 32, 
                      color: _isUploading ? CRMColors.textMutedOf(context) : CRMColors.primaryOf(context),
                    ),
                    const SizedBox(height: CRMSpacing.xs),
                    Text(
                      'Click to upload photo',
                      style: CRMTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _isUploading ? CRMColors.textMutedOf(context) : CRMColors.primaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supports JPEG, PNG up to 5MB (Max ${widget.maxImages} photos)',
                      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(CRMSpacing.m),
            decoration: BoxDecoration(
              color: CRMColors.backgroundOf(context),
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              border: Border.all(color: CRMColors.borderOf(context)),
            ),
            child: Center(
              child: Text(
                'Maximum limit of ${widget.maxImages} photos reached',
                style: CRMTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: CRMColors.textSecondaryOf(context),
                ),
              ),
            ),
          ),
        ],

        if (_isUploading) ...[
          const SizedBox(height: CRMSpacing.s),
          Center(
            child: Text(
              'Uploading image... Please wait.',
              style: CRMTypography.caption.copyWith(color: CRMColors.primaryOf(context)),
            ),
          ),
        ],

        if (widget.imageUrls.isNotEmpty) ...[
          const SizedBox(height: CRMSpacing.m),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final crossAxisCount = isMobile ? 1 : (constraints.maxWidth > 900 ? 4 : 3);
              final itemSpacing = CRMSpacing.s;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.imageUrls.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: itemSpacing,
                  mainAxisSpacing: itemSpacing,
                  childAspectRatio: isMobile ? 16 / 10 : 4 / 3.5,
                ),
                itemBuilder: (context, index) {
                  final imageUrl = widget.imageUrls[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: CRMColors.cardBgOf(context),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      border: Border.all(color: CRMColors.borderOf(context), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(CRMBorderRadius.s - 1)),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: CRMColors.backgroundOf(context),
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: CRMColors.textSecondaryOf(context),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.xs, vertical: CRMSpacing.xxs),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: CRMColors.borderOf(context), width: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Text(
                                  'Photo ${index + 1}',
                                  style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context)),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined, size: 16, color: CRMColors.primaryOf(context)),
                                    onPressed: () => _showSourceDialog(index),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                    tooltip: 'Replace Photo',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: CRMColors.danger),
                                    onPressed: () => widget.onImageRemoved(index),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                    tooltip: 'Delete Photo',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double radius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 4.0,
    this.dashLength = 6.0,
    this.radius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    ));

    final dashPath = Path();
    double distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final len = dashLength;
        if (distance + len > pathMetric.length) {
          dashPath.addPath(
            pathMetric.extractPath(distance, pathMetric.length),
            Offset.zero,
          );
        } else {
          dashPath.addPath(
            pathMetric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.radius != radius;
  }
}
