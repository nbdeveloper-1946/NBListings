import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/design_system/tokens/app_typography.dart';
import '../../../../core/design_system/widgets/buttons.dart';
import '../../../../core/design_system/widgets/cards.dart';

class PublicPropertyDetailScreen extends StatefulWidget {
  final String sessionId;
  final String propertyId;

  const PublicPropertyDetailScreen({
    super.key,
    required this.sessionId,
    required this.propertyId,
  });

  @override
  State<PublicPropertyDetailScreen> createState() => _PublicPropertyDetailScreenState();
}

class _PublicPropertyDetailScreenState extends State<PublicPropertyDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _agent;
  Map<String, dynamic>? _property;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPropertyDetails();
  }

  Future<void> _loadPropertyDetails() async {
    try {
      final response = await DioClient.dio.get('/share-sessions/public/${widget.sessionId}');
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        final agent = data['agent'];
        final List<dynamic> properties = data['properties'] ?? [];

        final prop = properties.firstWhere(
          (p) => p['id'] == widget.propertyId,
          orElse: () => null,
        );

        if (prop != null) {
          setState(() {
            _agent = agent;
            _property = prop;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = "Property not found in this shortlist.";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = response.data['message'] ?? "Failed to load property details.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load property details.";
        _isLoading = false;
      });
    }
  }

  Future<void> _logClick(String actionType) async {
    try {
      await DioClient.dio.post(
        '/share-sessions/public/${widget.sessionId}/click',
        data: {
          'propertyId': widget.propertyId,
          'actionType': actionType,
        },
      );
    } catch (e) {
      debugPrint("Failed to log click event: $e");
    }
  }

  Future<void> _launchUrlHelper(String url, String actionType) async {
    await _logClick(actionType);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: CRMColors.text),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(CRMSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
                const SizedBox(height: CRMSpacing.m),
                Text(
                  _errorMessage!,
                  style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final p = _property!;
    final agentName = _agent?['full_name'] ?? 'Agent';
    final agentMobile = _agent?['mobile'] ?? '';
    final code = p['property_code'] ?? '';
    final price = p['price'] != null ? '₹${p['price']}' : 'Price N/A';
    final config = p['configuration_name'] ?? '${p['bedrooms'] ?? "-"} BHK';
    final areaName = p['area_name'] ?? '';
    final images = p['images'] as List<dynamic>? ?? [];
    final amenities = p['amenities'] as List<dynamic>? ?? [];
    final society = p['society'] ?? '';

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: CRMColors.backgroundOf(context),
        elevation: 0,
        title: Text(
          "Property Details ($code)",
          style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.text),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: CRMColors.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            if (images.isNotEmpty) ...[
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (index) => setState(() => _currentImageIndex = index),
                      itemBuilder: (context, index) {
                        return Image.network(
                          images[index].toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported_rounded, size: 64, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${_currentImageIndex + 1} / ${images.length}",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_rounded, size: 64, color: Colors.grey),
              ),
            ],

            Padding(
              padding: const EdgeInsets.all(CRMSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "$config in $areaName",
                          style: CRMTypography.sectionTitle.copyWith(fontWeight: FontWeight.bold, fontSize: 20, color: CRMColors.text),
                        ),
                      ),
                      Text(
                        price,
                        style: CRMTypography.sectionTitle.copyWith(color: CRMColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                  if (society.isNotEmpty) ...[
                    const SizedBox(height: CRMSpacing.xxs),
                    Text(society, style: CRMTypography.body.copyWith(color: CRMColors.textSecondary)),
                  ],
                  const SizedBox(height: CRMSpacing.m),
                  
                  // Highlight card
                  CRMCard(
                    child: Padding(
                      padding: const EdgeInsets.all(CRMSpacing.m),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailColumn(Icons.bed_rounded, "Bedrooms", "${p['bedrooms'] ?? '-'}"),
                          _buildDetailColumn(Icons.square_foot_rounded, "Area", p['super_builtup_area'] != null ? "${p['super_builtup_area']} sqft" : "-"),
                          _buildDetailColumn(Icons.event_available_rounded, "Available From", p['available_from'] ?? "Immediate"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: CRMSpacing.l),

                  // Pricing detail section
                  Text("Pricing details", style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.text)),
                  const SizedBox(height: CRMSpacing.s),
                  Row(
                    children: [
                      _buildPriceTag("Deposit", p['deposit'] != null ? "₹${p['deposit']}" : "N/A"),
                      const SizedBox(width: CRMSpacing.m),
                      _buildPriceTag("Maintenance", p['maintenance'] != null ? "₹${p['maintenance']}" : "N/A"),
                    ],
                  ),
                  const SizedBox(height: CRMSpacing.l),

                  // Description
                  if (p['description'] != null && p['description'].toString().isNotEmpty) ...[
                    Text("Description", style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.text)),
                    const SizedBox(height: CRMSpacing.s),
                    Text(
                      p['description'],
                      style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                    const SizedBox(height: CRMSpacing.l),
                  ],

                  // Amenities
                  if (amenities.isNotEmpty) ...[
                    Text("Amenities", style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.text)),
                    const SizedBox(height: CRMSpacing.s),
                    Wrap(
                      spacing: CRMSpacing.s,
                      runSpacing: CRMSpacing.s,
                      children: amenities.map((am) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: CRMColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                            border: Border.all(color: CRMColors.primary.withValues(alpha: 0.15)),
                          ),
                          child: Text(
                            am.toString(),
                            style: CRMTypography.captionBold.copyWith(color: CRMColors.primary),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: CRMSpacing.l),
                  ],

                  // Agent Info box
                  CRMCard(
                    child: Padding(
                      padding: const EdgeInsets.all(CRMSpacing.m),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: CRMColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              agentName.isNotEmpty ? agentName[0].toUpperCase() : 'A',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: CRMSpacing.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Need Help?", style: CRMTypography.caption.copyWith(color: CRMColors.textMuted)),
                                Text(agentName, style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.text)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 100), // padding for floating bottom action bar
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: agentMobile.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(CRMSpacing.m),
              decoration: BoxDecoration(
                color: CRMColors.cardBgOf(context),
                border: Border(top: BorderSide(color: CRMColors.borderOf(context))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.phone_rounded),
                      label: const Text("Call Agent"),
                      onPressed: () => _launchUrlHelper("tel:$agentMobile", "Call"),
                    ),
                  ),
                  const SizedBox(width: CRMSpacing.s),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text("Schedule Visit"),
                      onPressed: () {
                        final text = Uri.encodeComponent("Hi, I would like to schedule a visit to see property $code from your shortlisted share.");
                        _launchUrlHelper("https://wa.me/$agentMobile?text=$text", "Schedule");
                      },
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildDetailColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 24, color: CRMColors.primary),
        const SizedBox(height: CRMSpacing.xxs),
        Text(label, style: CRMTypography.caption.copyWith(color: CRMColors.textMuted)),
        Text(value, style: CRMTypography.captionBold.copyWith(color: CRMColors.text)),
      ],
    );
  }

  Widget _buildPriceTag(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(CRMSpacing.s),
        decoration: BoxDecoration(
          color: CRMColors.backgroundOf(context),
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
          border: Border.all(color: CRMColors.borderOf(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: CRMTypography.caption.copyWith(color: CRMColors.textMuted)),
            const SizedBox(height: 2),
            Text(value, style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.text)),
          ],
        ),
      ),
    );
  }
}
