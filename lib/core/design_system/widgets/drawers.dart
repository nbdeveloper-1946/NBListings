import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import '../../../../features/properties/models/property_model.dart';
import 'buttons.dart';
import 'cards.dart';
import 'package:cached_network_image/cached_network_image.dart';

void showCRMPropertyDrawer(BuildContext context, PropertyModel property) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Property Details barrier',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, anim1, anim2) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: BuildPropertyDetailWidget(property: property, showHeaderClose: true),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return FadeTransition(
        opacity: anim1,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(anim1),
          child: child,
        ),
      );
    },
  );
}

class BuildPropertyDetailWidget extends StatelessWidget {
  final PropertyModel property;
  final bool showHeaderClose;

  const BuildPropertyDetailWidget({
    super.key,
    required this.property,
    this.showHeaderClose = true,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isMobile = screenWidth < 768;

    return Container(
      width: screenWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: CRMColors.background,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Full-width wrapper)
            Container(
              color: CRMColors.cardBg,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(CRMSpacing.m),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.propertyCode,
                            style: CRMTypography.sectionTitle.copyWith(color: CRMColors.primary, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            property.title,
                            style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (showHeaderClose)
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: CRMColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                  ],
                ),
              ),
            ),
            Divider(color: CRMColors.border, height: 1),
            
            // Details Body (Full screen width)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(CRMSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      CRMImageSlider(images: property.images),
                      const SizedBox(height: CRMSpacing.l),
                      
                      // Two-column layout for details
                      if (isMobile) ...[
                        _buildDetailCard(context, 'Basic Details', [
                          _buildDetailRow('Listing Type', property.listingTypeName),
                          _buildDetailRow('Category', property.categoryName),
                          _buildDetailRow('Property Type', property.propertyTypeName),
                          _buildDetailRow('Configuration', property.configurationName ?? 'N/A'),
                          _buildDetailRow('Price', '₹${property.price.toStringAsFixed(0)}'),
                          _buildDetailRow('Deposit', '₹${property.deposit.toStringAsFixed(0)}'),
                          _buildDetailRow('Maintenance', '₹${property.maintenance.toStringAsFixed(0)}'),
                          _buildDetailRow('Status', property.statusDisplayName),
                          _buildDetailRow('Verification', property.isVerified ? 'Verified' : 'Pending Verification'),
                        ]),
                        const SizedBox(height: CRMSpacing.m),
                        _buildDetailCard(context, 'Specifications & Floor Details', [
                          _buildDetailRow('Bedrooms', '${property.bedrooms} BHK'),
                          _buildDetailRow('Bathrooms', '${property.bathrooms}'),
                          _buildDetailRow('Balconies', '${property.balconies}'),
                          _buildDetailRow('Floor', '${property.floorNo ?? "N/A"} / ${property.totalFloor ?? "N/A"}'),
                          _buildDetailRow('Property Age', '${property.ageOfProperty ?? "N/A"} years'),
                          _buildDetailRow('Furnishing', property.furnishingTypeName ?? 'None'),
                          _buildDetailRow('Facing', property.facingTypeName ?? 'N/A'),
                          _buildDetailRow('Parking', _getParkingDisplay(property.parking)),
                        ]),
                        const SizedBox(height: CRMSpacing.m),
                        _buildDetailCard(context, 'Location & Address', [
                          _buildDetailRow('City', property.cityName),
                          _buildDetailRow('Area', property.areaName),
                          _buildDetailRow('Address', property.address),
                          _buildDetailRow('Landmark', property.landmark ?? 'N/A'),
                          _buildDetailRow('Coordinates', property.latitude != null && property.longitude != null 
                              ? '${property.latitude!.toStringAsFixed(5)}, ${property.longitude!.toStringAsFixed(5)}'
                              : 'N/A'),
                        ]),
                        const SizedBox(height: CRMSpacing.m),
                        _buildDetailCard(context, 'Contacts & Key Management', [
                          _buildDetailRow('Ownership', property.ownershipTypeName ?? 'N/A'),
                          _buildDetailRow('Owner Name', property.ownerName),
                          _buildDetailRow('Owner Mobile', property.ownerMobile),
                          _buildDetailRow('Reffer / Key Collect', property.brokerName ?? 'N/A'),
                          _buildDetailRow('Brokerage Type', property.brokerageTypeName ?? 'N/A'),
                        ]),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildDetailCard(context, 'Basic Details', [
                                    _buildDetailRow('Listing Type', property.listingTypeName),
                                    _buildDetailCardRowHelper([
                                      _buildDetailRow('Category', property.categoryName),
                                      _buildDetailRow('Property Type', property.propertyTypeName),
                                    ]),
                                    _buildDetailCardRowHelper([
                                      _buildDetailRow('Configuration', property.configurationName ?? 'N/A'),
                                      _buildDetailRow('Status', property.statusDisplayName),
                                    ]),
                                    _buildDetailCardRowHelper([
                                      _buildDetailRow('Price', '₹${property.price.toStringAsFixed(0)}'),
                                      _buildDetailRow('Deposit', '₹${property.deposit.toStringAsFixed(0)}'),
                                    ]),
                                    _buildDetailCardRowHelper([
                                      _buildDetailRow('Maintenance', '₹${property.maintenance.toStringAsFixed(0)}'),
                                      _buildDetailRow('Verification', property.isVerified ? 'Verified' : 'Pending Verification'),
                                    ]),
                                  ]),
                                  const SizedBox(height: CRMSpacing.m),
                                  _buildDetailCard(context, 'Location & Address', [
                                    _buildDetailCardRowHelper([
                                      _buildDetailRow('City', property.cityName),
                                      _buildDetailRow('Area', property.areaName),
                                    ]),
                                    _buildDetailRow('Address', property.address),
                                    _buildDetailCardRowHelper([
                                      _buildDetailRow('Landmark', property.landmark ?? 'N/A'),
                                      _buildDetailRow('Coordinates', property.latitude != null && property.longitude != null 
                                          ? '${property.latitude!.toStringAsFixed(5)}, ${property.longitude!.toStringAsFixed(5)}'
                                          : 'N/A'),
                                    ]),
                                  ]),
                                ],
                              ),
                            ),
                            const SizedBox(width: CRMSpacing.m),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildDetailCard(context, 'Specifications & Floor Details', [
                                    _buildDetailCardRowHelper([
                                      _buildDetailRow('Bedrooms', '${property.bedrooms} BHK'),
                                      _buildDetailRow('Bathrooms', '${property.bathrooms}'),
                                    ]),
                                    _buildDetailCardRowHelper([
                                      _buildDetailRow('Balconies', '${property.balconies}'),
                                      _buildDetailRow('Floor', '${property.floorNo ?? "N/A"} / ${property.totalFloor ?? "N/A"}'),
                                    ]),
                                    _buildDetailCardRowHelper([
                                      _buildDetailRow('Property Age', '${property.ageOfProperty ?? "N/A"} years'),
                                      _buildDetailRow('Furnishing', property.furnishingTypeName ?? 'None'),
                                    ]),
                                    _buildDetailCardRowHelper([
                                      _buildDetailRow('Facing', property.facingTypeName ?? 'N/A'),
                                      _buildDetailRow('Parking', _getParkingDisplay(property.parking)),
                                    ]),
                                  ]),
                                  const SizedBox(height: CRMSpacing.m),
                                  _buildDetailCard(context, 'Contacts & Key Management', [
                                    _buildDetailCardRowHelper([
                                      _buildDetailRow('Ownership', property.ownershipTypeName ?? 'N/A'),
                                      _buildDetailRow('Owner Name', property.ownerName),
                                    ]),
                                    _buildDetailCardRowHelper([
                                      _buildDetailRow('Owner Mobile', property.ownerMobile),
                                      _buildDetailRow('Reffer / Key Collect', property.brokerName ?? 'N/A'),
                                    ]),
                                    _buildDetailRow('Brokerage Type', property.brokerageTypeName ?? 'N/A'),
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: CRMSpacing.m),
                      
                      // Description & Internal Remarks
                      _buildDetailCard(context, 'Description & Internal Remarks', [
                        _buildTextSection('Description', property.description ?? 'No description provided.'),
                        const SizedBox(height: CRMSpacing.m),
                        _buildTextSection('Operational CRM Remarks', property.remarks ?? 'No internal remarks.'),
                        const SizedBox(height: CRMSpacing.m),
                        _buildAmenitiesSection('Amenities', property.amenities),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CRMImageSlider extends StatefulWidget {
  final List<String> images;
  const CRMImageSlider({super.key, required this.images});

  @override
  State<CRMImageSlider> createState() => _CRMImageSliderState();
}

class _CRMImageSliderState extends State<CRMImageSlider> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.images.isNotEmpty;
    if (!hasImages) {
      return Container(
        height: 320,
        width: double.infinity,
        decoration: BoxDecoration(
          color: CRMColors.cardBg,
          borderRadius: BorderRadius.circular(CRMBorderRadius.m),
          border: Border.all(color: CRMColors.border, width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, color: CRMColors.textMuted, size: 48),
              const SizedBox(height: CRMSpacing.s),
              Text(
                'No Images Uploaded',
                style: CRMTypography.caption.copyWith(color: CRMColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 360,
      width: double.infinity,
      decoration: BoxDecoration(
        color: CRMColors.cardBg,
        borderRadius: BorderRadius.circular(CRMBorderRadius.m),
        border: Border.all(color: CRMColors.border, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CRMBorderRadius.m - 1.5),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withOpacity(0.85),
                      builder: (context) => CRMImageZoomViewer(
                        images: widget.images,
                        initialIndex: index,
                      ),
                    );
                  },
                  child: _buildPropertyImage(widget.images[index]),
                );
              },
            ),
            if (_currentIndex > 0)
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 14),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ),
              ),
            if (_currentIndex < widget.images.length - 1)
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (index) {
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index ? Colors.white : Colors.white54,
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentIndex + 1}/${widget.images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyImage(String url) {
    if (url.startsWith('data:image') || url.contains('base64')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover);
      } catch (_) {}
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => Center(
        child: Icon(Icons.broken_image_outlined, color: CRMColors.textMuted, size: 48),
      ),
    );
  }
}

class CRMImageZoomViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const CRMImageZoomViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<CRMImageZoomViewer> createState() => _CRMImageZoomViewerState();
}

class _CRMImageZoomViewerState extends State<CRMImageZoomViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (idx) {
              setState(() {
                _currentIndex = idx;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: _buildZoomImage(widget.images[index]),
                ),
              );
            },
          ),
          Positioned(
            top: 24,
            right: 24,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          if (_currentIndex > 0)
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
            ),
          if (_currentIndex < widget.images.length - 1)
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomImage(String url) {
    if (url.startsWith('data:image') || url.contains('base64')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(base64Decode(base64Str));
      } catch (_) {}
    }
    return CachedNetworkImage(
      imageUrl: url,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (context, url, error) => const Icon(
        Icons.broken_image_outlined,
        color: Colors.white60,
        size: 64,
      ),
    );
  }
}

Widget _buildDetailCard(BuildContext context, String title, List<Widget> children) {
  return CRMCard(
    padding: const EdgeInsets.all(CRMSpacing.m),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: CRMTypography.bodyMedium.copyWith(color: CRMColors.primary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: CRMSpacing.s),
        Divider(color: CRMColors.border),
        const SizedBox(height: CRMSpacing.s),
        ...children,
      ],
    ),
  );
}

Widget _buildDetailCardRowHelper(List<Widget> children) {
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) ...[
            const SizedBox(width: CRMSpacing.m),
            VerticalDivider(color: CRMColors.border, width: 1, thickness: 1),
            const SizedBox(width: CRMSpacing.m),
          ],
        ],
      ],
    ),
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondary),
        ),
        const SizedBox(width: CRMSpacing.m),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: CRMTypography.body.copyWith(color: CRMColors.text, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

Widget _buildTextSection(String label, String content) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondary),
      ),
      const SizedBox(height: CRMSpacing.xs),
      Text(
        content,
        style: CRMTypography.body.copyWith(color: CRMColors.text),
      ),
    ],
  );
}

Widget _buildAmenitiesSection(String label, List<String> amenities) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondary),
      ),
      const SizedBox(height: CRMSpacing.xs),
      if (amenities.isEmpty)
        Text(
          'No amenities selected.',
          style: CRMTypography.body.copyWith(color: CRMColors.textMuted),
        )
      else
        Wrap(
          spacing: CRMSpacing.s,
          runSpacing: CRMSpacing.xs,
          children: amenities.map((am) {
            return Chip(
              label: Text(
                am,
                style: CRMTypography.bodyMedium.copyWith(color: CRMColors.text),
              ),
              backgroundColor: CRMColors.primary.withOpacity(0.08),
              side: BorderSide(color: CRMColors.primary.withOpacity(0.2)),
              padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: 0),
            );
          }).toList(),
        ),
    ],
  );
}

String _getParkingDisplay(int parkingVal) {
  if (parkingVal >= 11) {
    final optIndex = parkingVal ~/ 10;
    final slotVal = parkingVal % 10;
    String option = 'Basement 1';
    if (optIndex == 1) {
      option = 'Basement 1';
    } else if (optIndex == 2) {
      option = 'Basement 2';
    } else if (optIndex == 3) {
      option = 'Ground Floor';
    }
    return 'Allocated - $option (Slot $slotVal)';
  } else if (parkingVal == 1) {
    return 'Allocated - Basement 1';
  } else if (parkingVal == 2) {
    return 'Allocated - Ground Floor';
  } else {
    return 'Open';
  }
}
