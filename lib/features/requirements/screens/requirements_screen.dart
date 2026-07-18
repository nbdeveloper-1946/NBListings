import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/widgets/drawers.dart';
import '../bloc/requirements_bloc.dart';
import '../models/requirement_model.dart';
import 'add_edit_requirement_screen.dart';
import '../../properties/repository/properties_repository.dart';
import '../../properties/models/property_model.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/data_table.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/utils/budget_formatter.dart';

class RequirementsScreen extends StatefulWidget {
  const RequirementsScreen({super.key});

  @override
  State<RequirementsScreen> createState() => _RequirementsScreenState();
}

class _RequirementsScreenState extends State<RequirementsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedConfigId;
  String _selectedStatus = "All";
  String? _selectedListingTypeId;
  final PropertiesRepository _propertiesRepository = PropertiesRepository();
  PropertyMetadataModel? _metadata;
  bool _isLoadingMetadata = true;
  bool _hasAutoOpenedAdd = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
    _triggerFetch();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final action = GoRouterState.of(context).uri.queryParameters['action'];
        if (action == 'add' && !_hasAutoOpenedAdd) {
          _hasAutoOpenedAdd = true;
          _showAddEditDialog();
        }
      }
    });
  }

  Future<void> _loadMetadata() async {
    try {
      final meta = await _propertiesRepository.getPropertyMetadata();
      setState(() {
        _metadata = meta;
        _isLoadingMetadata = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMetadata = false;
      });
    }
  }

  void _triggerFetch() {
    context.read<RequirementsBloc>().add(
      FetchRequirementsEvent(
        search: _searchController.text.trim(),
        configurationId: _selectedConfigId,
        status: _selectedStatus,
        listingTypeId: _selectedListingTypeId,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedConfigId = null;
      _selectedStatus = "All";
      _selectedListingTypeId = null;
    });
    _triggerFetch();
  }

  void _showAddEditDialog([RequirementModel? req]) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddEditRequirementScreen(
        requirement: req,
        onSaved: () {
          _triggerFetch();
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(RequirementModel req) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: CRMColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
          title: Text("Delete Requirement", style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text)),
          content: Text(
            "Are you sure you want to delete the requirement for ${req.clientName}?",
            style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
          ),
          actions: [
            CRMButton(
              label: "Cancel",
              variant: CRMButtonVariant.outline,
              onPressed: () => Navigator.pop(dialogContext),
            ),
            const SizedBox(width: CRMSpacing.xs),
            CRMButton(
              label: "Delete",
              variant: CRMButtonVariant.danger,
              onPressed: () {
                context.read<RequirementsBloc>().add(DeleteRequirementEvent(req.id));
                Navigator.pop(dialogContext);
              },
            ),
          ],
        );
      },
    );
  }

  void _showMatchesDrawer(RequirementModel req) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _CRMPropertyMatchesDrawer(requirement: req);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocListener<RequirementsBloc, RequirementsState>(
        listener: (context, state) {
          if (state is RequirementsSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: CRMColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _triggerFetch();
          } else if (state is RequirementsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error: ${state.message}"),
                backgroundColor: CRMColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CRMSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              _buildPageHeader(),
              const SizedBox(height: CRMSpacing.l),

              // KPI Stats
              _buildStatsGrid(),
              const SizedBox(height: CRMSpacing.l),

              // Filters & Search Card
              _buildSearchAndFiltersCard(),
              const SizedBox(height: CRMSpacing.l),

              // Data Table
              _buildRequirementsTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Requirements Tracker",
                style: CRMTypography.pageTitle.copyWith(color: CRMColors.text),
              ),
              const SizedBox(height: 4.0),
              Text(
                "Manage buyer requirements and run listing match iterations",
                style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
              ),
              const SizedBox(height: CRMSpacing.m),
              SizedBox(
                width: double.infinity,
                child: CRMButton(
                  label: "Add Requirement",
                  prefixIcon: Icons.add_rounded,
                  onPressed: () => _showAddEditDialog(),
                ),
              ),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Requirements Tracker",
                    style: CRMTypography.pageTitle.copyWith(color: CRMColors.text),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    "Manage buyer requirements and run listing match iterations",
                    style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: CRMSpacing.m),
            CRMButton(
              label: "Add Requirement",
              prefixIcon: Icons.add_rounded,
              onPressed: () => _showAddEditDialog(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsGrid() {
    return BlocBuilder<RequirementsBloc, RequirementsState>(
      builder: (context, state) {
        int total = 0;
        int active = 0;
        int closed = 0;

        if (state is RequirementsLoaded) {
          total = state.requirements.length;
          active = state.requirements.where((r) => r.status == 'Active' || r.status == 'Live').length;
          closed = state.requirements.where((r) => r.status == 'Closed' || r.status == 'Won').length;
        }

        final cards = [
          CRMKPICard(
            title: "TOTAL INQUIRIES",
            value: total.toString(),
            icon: Icons.assignment_rounded,
            iconColor: CRMColors.primary,
          ),
          CRMKPICard(
            title: "LIVE SEARCHES",
            value: active.toString(),
            icon: Icons.hourglass_empty_rounded,
            iconColor: CRMColors.warning,
          ),
          CRMKPICard(
            title: "WON",
            value: closed.toString(),
            icon: Icons.check_circle_outline_rounded,
            iconColor: CRMColors.success,
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            if (!isWide) {
              final double cardWidth = (constraints.maxWidth - CRMSpacing.m) / 2;
              double mobileRatio = 1.35;
              if (cardWidth < 150) {
                mobileRatio = 1.1;
              } else if (cardWidth < 180) {
                mobileRatio = 1.25;
              }

              return GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: CRMSpacing.m,
                mainAxisSpacing: CRMSpacing.m,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: mobileRatio,
                children: cards,
              );
            }
            return Row(
              children: cards.map((card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.xs),
                  child: card,
                ),
              )).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchAndFiltersCard() {
    return CRMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: CRMTypography.body.copyWith(color: CRMColors.text),
                  decoration: InputDecoration(
                    hintText: 'Search by client name, mobile, specs, remarks...',
                    hintStyle: CRMTypography.body.copyWith(color: CRMColors.textMuted),
                    prefixIcon: Icon(Icons.search_rounded, color: CRMColors.textMuted),
                    filled: true,
                    fillColor: CRMColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      borderSide: BorderSide(color: CRMColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      borderSide: BorderSide(color: CRMColors.border),
                    ),
                  ),
                  onChanged: (val) => _triggerFetch(),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              CRMButton(label: "Search", onPressed: _triggerFetch),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          Wrap(
            spacing: CRMSpacing.m,
            runSpacing: CRMSpacing.s,
            children: [
              _buildDropdownFilter<String?>(
                label: 'Configuration',
                value: _selectedConfigId,
                items: [
                  const DropdownMenuItem(value: null, child: Text("All Configurations")),
                  ...?_metadata?.configurations.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                ],
                onChanged: (val) {
                  setState(() => _selectedConfigId = val);
                  _triggerFetch();
                },
              ),
              _buildDropdownFilter(
                label: 'Status',
                value: _selectedStatus,
                items: ["All", "Live", "Won", "Dead"].map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedStatus = val ?? "All");
                  _triggerFetch();
                },
              ),
              _buildDropdownFilter<String?>(
                label: 'Listing Type',
                value: _selectedListingTypeId,
                items: [
                  const DropdownMenuItem(value: null, child: Text("All")),
                  ...?_metadata?.listingTypes.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                ],
                onChanged: (val) {
                  setState(() => _selectedListingTypeId = val);
                  _triggerFetch();
                },
              ),
              CRMButton(
                label: "Clear Filters",
                variant: CRMButtonVariant.outline,
                onPressed: _clearFilters,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final bool hasValue = value == null || items.any((item) => item.value == value);
    final T? safeValue = hasValue ? value : null;

    return SizedBox(
      width: 200,
      height: 44,
      child: DropdownButtonFormField<T>(
        value: safeValue,
        dropdownColor: CRMColors.cardBg,
        style: CRMTypography.body.copyWith(color: CRMColors.text),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
          contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 4),
          filled: true,
          fillColor: CRMColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            borderSide: BorderSide(color: CRMColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            borderSide: BorderSide(color: CRMColors.border),
          ),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildRequirementsTable() {
    return BlocBuilder<RequirementsBloc, RequirementsState>(
      builder: (context, state) {
        final isLoading = state is RequirementsLoading || state is RequirementsInitial;
        List<RequirementModel> requirements = [];

        if (state is RequirementsLoaded) {
          requirements = state.requirements;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            if (isMobile) {
              return _buildRequirementCards(requirements, isLoading);
            }

            return CRMDataTable(
              isLoading: isLoading,
              emptyTitle: 'No Requirements Found',
              emptyDescription: 'Try adjusting filters or create a new requirement pipeline.',
              columns: const [
                DataColumn(label: Text('Client')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Specs / Config')),
                DataColumn(label: Text('Budget Range')),
                DataColumn(label: Text('Target Area(s)')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Matches')),
                DataColumn(label: Text('Actions')),
              ],
              rows: requirements.map((req) {
                final isActive = req.status == 'Active' || req.status == 'Live';

                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(req.clientName, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.text)),
                          Text(req.clientMobile, style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary)),
                        ],
                      ),
                    ),
                    DataCell(Text(req.categoryName, style: CRMTypography.body.copyWith(color: CRMColors.textSecondary))),
                    DataCell(Text('${req.propertyTypeName} (${req.configurationName ?? "-"})', style: CRMTypography.body.copyWith(color: CRMColors.text))),
                    DataCell(
                      Text(
                        '${BudgetFormatter.format(req.minBudget)} - ${BudgetFormatter.format(req.maxBudget)}',
                        style: CRMTypography.bodyMedium.copyWith(color: CRMColors.primary),
                      ),
                    ),
                    DataCell(
                      Tooltip(
                        message: req.areaNames.join(', '),
                        child: Text(
                          req.areaNames.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: CRMSpacing.xxs),
                        decoration: BoxDecoration(
                          color: isActive ? CRMColors.success.withValues(alpha: 0.12) : CRMColors.textMuted.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                        ),
                        child: Text(
                          req.status,
                          style: CRMTypography.captionBold.copyWith(
                            color: isActive ? CRMColors.success : CRMColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      CRMButton(
                        label: "Run Matches",
                        prefixIcon: Icons.bolt_rounded,
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s),
                        onPressed: () => _showMatchesDrawer(req),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: CRMColors.primary, size: 18),
                            onPressed: () => _showAddEditDialog(req),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 18),
                            onPressed: () => _showDeleteConfirmDialog(req),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildRequirementCards(List<RequirementModel> requirements, bool isLoading) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(CRMSpacing.m),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (requirements.isEmpty) {
      return CRMCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: CRMSpacing.xl),
          child: Column(
            children: [
              Icon(Icons.folder_open_rounded, size: 48, color: CRMColors.textMuted),
              const SizedBox(height: CRMSpacing.s),
              Text('No Requirements Found', style: CRMTypography.cardTitle.copyWith(color: CRMColors.text)),
              const SizedBox(height: CRMSpacing.xxs),
              Text(
                'Try adjusting filters or create a new requirement pipeline.',
                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: requirements.map((req) {
        final isActive = req.status == 'Active' || req.status == 'Live';
        final budget = '₹${BudgetFormatter.format(req.minBudget)} - ₹${BudgetFormatter.format(req.maxBudget)}';

        return Container(
          margin: const EdgeInsets.only(bottom: CRMSpacing.m),
          decoration: BoxDecoration(
            color: CRMColors.cardBg,
            borderRadius: BorderRadius.circular(CRMBorderRadius.m),
            border: Border.all(color: CRMColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client header with status
              Padding(
                padding: const EdgeInsets.fromLTRB(CRMSpacing.m, CRMSpacing.m, CRMSpacing.m, CRMSpacing.s),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: CRMColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        req.clientName.isNotEmpty ? req.clientName[0].toUpperCase() : '?',
                        style: CRMTypography.bodyMedium.copyWith(color: CRMColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: CRMSpacing.s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.clientName,
                            style: CRMTypography.bodyMedium.copyWith(color: CRMColors.text, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            req.clientMobile,
                            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: CRMSpacing.xxs),
                      decoration: BoxDecoration(
                        color: isActive ? CRMColors.success.withValues(alpha: 0.12) : CRMColors.textMuted.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                      ),
                      child: Text(
                        req.status,
                        style: CRMTypography.captionBold.copyWith(
                          color: isActive ? CRMColors.success : CRMColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: CRMColors.border, height: 1),
              // Details grid
              Padding(
                padding: const EdgeInsets.all(CRMSpacing.m),
                child: Wrap(
                  spacing: CRMSpacing.m,
                  runSpacing: CRMSpacing.s,
                  children: [
                    _buildDetailChip(Icons.category_rounded, 'Category', req.categoryName),
                    _buildDetailChip(Icons.apartment_rounded, 'Type', '${req.propertyTypeName} (${req.configurationName ?? "-"})'),
                    _buildDetailChip(Icons.currency_rupee_rounded, 'Budget', budget),
                    _buildDetailChip(Icons.location_on_rounded, 'Area', req.areaNames.join(', ')),
                  ],
                ),
              ),
              // Action buttons
              Divider(color: CRMColors.border, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: CRMSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: Icon(Icons.bolt_rounded, size: 18, color: CRMColors.primary),
                        label: Text('Matches', style: CRMTypography.captionBold.copyWith(color: CRMColors.primary)),
                        onPressed: () => _showMatchesDrawer(req),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: CRMColors.primary, size: 18),
                      onPressed: () => _showAddEditDialog(req),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 18),
                      onPressed: () => _showDeleteConfirmDialog(req),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: CRMColors.textMuted),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: CRMTypography.caption.copyWith(color: CRMColors.textMuted, fontSize: 10)),
            Text(
              value,
              style: CRMTypography.captionBold.copyWith(color: CRMColors.text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}

class _CRMPropertyMatchesDrawer extends StatefulWidget {
  final RequirementModel requirement;

  const _CRMPropertyMatchesDrawer({required this.requirement});

  @override
  State<_CRMPropertyMatchesDrawer> createState() => _CRMPropertyMatchesDrawerState();
}

class _CRMPropertyMatchesDrawerState extends State<_CRMPropertyMatchesDrawer> {
  final PropertiesRepository _propertiesRepository = PropertiesRepository();
  bool _isLoading = true;
  List<PropertyModel> _matchedProperties = [];
  bool _includePhotos = false;

  Future<void> _shareProperty(PropertyModel p) async {
    final BHK = p.configurationName ?? "${p.bedrooms} BHK";
    final size = p.superBuiltupArea != null ? "${p.superBuiltupArea} sq ft" : "${p.plotArea ?? '-'} sq ft";
    final price = '₹${BudgetFormatter.format(p.price)}';
    
    final message = "Dear Customer,\n\n"
        "We found a property matching your requirements.\n\n"
        "Reference ID: ${p.propertyCode}\n\n"
        "📍 Location: ${p.areaName}\n\n"
        "🏠 Configuration: $BHK\n\n"
        "📐 Size: $size\n\n"
        "💰 Price: $price\n\n"
        "📞 For more details, please contact NB Prop Tech.";

    if (_includePhotos && p.images != null && p.images!.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final directory = await getTemporaryDirectory();
        final List<XFile> xFiles = [];
        final limit = p.images!.length > 3 ? 3 : p.images!.length;
        for (int i = 0; i < limit; i++) {
          final imgUrl = p.images![i];
          final ext = imgUrl.split('.').last.split('?').first;
          final filePath = '${directory.path}/share_${p.propertyCode}_$i.$ext';
          await Dio().download(imgUrl, filePath);
          xFiles.add(XFile(filePath));
        }
        
        Navigator.pop(context);
        
        await Share.shareXFiles(xFiles, text: message);
        await _logShareAction(p, true);
      } catch (e) {
        Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to download images: $e')),
          );
        }
      }
    } else {
      final phone = widget.requirement.clientMobile;
      final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        await _logShareAction(p, false);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch WhatsApp')),
          );
        }
      }
    }
  }

  Future<void> _logShareAction(PropertyModel p, bool isPhotoIncluded) async {
    try {
      await DioClient.dio.post('/audit/share', data: {
        'recordId': p.id,
        'clientMobile': widget.requirement.clientMobile,
        'requirementId': widget.requirement.id,
        'isPhotoIncluded': isPhotoIncluded,
      });
    } catch (e) {
      print("Failed to log share action: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAndFilterMatches();
  }

  Future<void> _loadAndFilterMatches() async {
    try {
      final properties = await _propertiesRepository.getProperties();
      final req = widget.requirement;

      final matches = properties.where((p) {
        // 1. Category Check
        final catMatch = p.categoryId == req.categoryId;

        // 2. Property Type Check
        final typeMatch = p.propertyTypeId == req.propertyTypeId;

        // 3. Configuration Check
        final configMatch = req.configurationId == null || p.configurationId == req.configurationId;

        // 4. Budget Range Check
        final budgetMatch = p.price >= req.minBudget && p.price <= req.maxBudget;

        // 5. Area Check
        final areaMatch = req.areaIds.isEmpty || req.areaIds.contains(p.areaId);

        return catMatch && typeMatch && configMatch && budgetMatch && areaMatch;
      }).toList();

      setState(() {
        _matchedProperties = matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CRMColors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(CRMBorderRadius.l)),
      ),
      padding: const EdgeInsets.all(CRMSpacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(color: CRMColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: CRMSpacing.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Matching System Listings", style: CRMTypography.sectionTitle),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: CRMSpacing.xs),
          Text(
            "Showing properties that match criteria: ${widget.requirement.configurationName ?? '-'} ${widget.requirement.propertyTypeName} in ${widget.requirement.areaNames.join(', ')}",
            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
          ),
          const SizedBox(height: CRMSpacing.s),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _includePhotos,
                  onChanged: (val) {
                    setState(() {
                      _includePhotos = val ?? false;
                    });
                  },
                  activeColor: CRMColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Include Property Photos in WhatsApp Share",
                style: CRMTypography.body.copyWith(fontSize: 13),
              ),
            ],
          ),
          const Divider(height: CRMSpacing.m),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_matchedProperties.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 48, color: CRMColors.textMuted),
                  const SizedBox(height: CRMSpacing.s),
                  Text("No Active Matches Found", style: CRMTypography.cardTitle),
                  const SizedBox(height: 4),
                  Text("No database properties currently fit these filters.", style: CRMTypography.body.copyWith(color: CRMColors.textSecondary)),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _matchedProperties.length,
                itemBuilder: (context, index) {
                  final p = _matchedProperties[index];
                  return Card(
                    color: CRMColors.background,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: CRMSpacing.s),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      side: BorderSide(color: CRMColors.border),
                    ),
                    child: ListTile(
                      onTap: () => _openPropertyDetails(context, p),
                      contentPadding: const EdgeInsets.all(CRMSpacing.m),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p.title, style: CRMTypography.bodyMedium),
                          Text(
                            '₹${BudgetFormatter.format(p.price)}',
                            style: CRMTypography.bodyMedium.copyWith(color: CRMColors.primary),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 14, color: CRMColors.textSecondary),
                              const SizedBox(width: 4),
                              Text('${p.areaName}, ${p.cityName}', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.square_foot_rounded, size: 14, color: CRMColors.textSecondary),
                              const SizedBox(width: 4),
                              Text('${p.superBuiltupArea ?? "-"} sq ft', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary)),
                              const SizedBox(width: CRMSpacing.m),
                              Icon(Icons.phone_iphone_rounded, size: 14, color: CRMColors.textSecondary),
                              const SizedBox(width: 4),
                              Text('${p.ownerName} (${p.ownerMobile})', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  foregroundColor: CRMColors.primary,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.share_rounded, size: 14),
                                label: const Text('Share', style: TextStyle(fontSize: 11)),
                                onPressed: () => _shareProperty(p),
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  foregroundColor: CRMColors.success,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.phone_rounded, size: 14),
                                label: const Text('Call', style: TextStyle(fontSize: 11)),
                                onPressed: () async {
                                  final url = Uri.parse('tel:${p.ownerMobile}');
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  }
                                },
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  foregroundColor: CRMColors.textSecondary,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 14),
                                label: const Text('Copy', style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  final BHK = p.configurationName ?? "${p.bedrooms} BHK";
                                  final size = p.superBuiltupArea != null ? "${p.superBuiltupArea} sq ft" : "${p.plotArea ?? '-'} sq ft";
                                  final price = '₹${BudgetFormatter.format(p.price)}';
                                  final message = "Dear Customer,\n\n"
                                      "We found a property matching your requirements.\n\n"
                                      "Reference ID: ${p.propertyCode}\n\n"
                                      "📍 Location: ${p.areaName}\n\n"
                                      "🏠 Configuration: $BHK\n\n"
                                      "📐 Size: $size\n\n"
                                      "💰 Price: $price\n\n"
                                      "📞 For more details, please contact NB Prop Tech.";
                                  Clipboard.setData(ClipboardData(text: message));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Copied to clipboard')),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  foregroundColor: Colors.blue,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.directions_rounded, size: 14),
                                label: const Text('Route', style: TextStyle(fontSize: 11)),
                                onPressed: () async {
                                  final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(p.title + ", " + p.areaName)}');
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openPropertyDetails(BuildContext context, PropertyModel p) {
    showCRMPropertyDrawer(context, p);
  }
}