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
import 'package:intl/intl.dart';
import '../../dashboard/repository/dashboard_repository.dart';
import '../../dashboard/models/dashboard_summary.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/utils/budget_formatter.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user_model.dart';

class RequirementsScreen extends StatefulWidget {
  const RequirementsScreen({super.key});

  @override
  State<RequirementsScreen> createState() => _RequirementsScreenState();
}

class _RequirementsScreenState extends State<RequirementsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedConfigId;
  String _selectedStatus = "All";
  String _activeListingTab = "Rent"; // "Rent" or "Re-Sale"
  String _activeMainTab = "Requirements"; // "Requirements" or "Follow-ups"
  DateTime? _reqFollowupDateFilter = DateTime.now();
  int _currentPage = 1;
  static const int _requirementsPerPage = 5;
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
    String? listingTypeId;
    if (_metadata != null && _metadata!.listingTypes.isNotEmpty) {
      try {
        final matched = _metadata!.listingTypes.firstWhere(
          (lt) => lt.name.toLowerCase().contains(_activeListingTab == 'Rent' ? 'rent' : 'sale'),
        );
        listingTypeId = matched.id;
      } catch (_) {}
    }

    context.read<RequirementsBloc>().add(
      FetchRequirementsEvent(
        search: _searchController.text.trim(),
        configurationId: _selectedConfigId,
        status: _selectedStatus,
        listingTypeId: listingTypeId,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedConfigId = null;
      _selectedStatus = "All";
      _activeListingTab = "Rent";
      _currentPage = 1;
    });
    _triggerFetch();
  }

  void _showAddEditDialog([RequirementModel? req]) {
    if (req == null) {
      showDialog(
        context: context,
        builder: (dialogContext) => AddEditRequirementScreen(
          requirement: null,
          onSaved: () {
            _triggerFetch();
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (dialogContext) => RequirementStepperDialog(
          requirement: req,
          initialStep: 1, // Default directly to Step 2: Add Followup
          onSaved: () {
            _triggerFetch();
          },
        ),
      );
    }
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
              const SizedBox(height: CRMSpacing.m),

              // Main View Tabs (Requirements vs Follow-ups)
              Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: CRMColors.cardBg,
                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                  border: Border.all(color: CRMColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMainViewTabButton('Requirements'),
                    const SizedBox(width: 4),
                    _buildMainViewTabButton('Follow-ups'),
                  ],
                ),
              ),
              const SizedBox(height: CRMSpacing.l),

              if (_activeMainTab == 'Requirements') ...[
                // Filters & Search Card
                _buildSearchAndFiltersCard(),
                const SizedBox(height: CRMSpacing.l),

                // Data Table
                _buildRequirementsTable(),
              ] else ...[
                // Follow-ups View
                _buildFollowupsView(),
              ],
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
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Rent / Re-Sale Toggle Tabs
              Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: CRMColors.background,
                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                  border: Border.all(color: CRMColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildListingTabButton('Rent'),
                    const SizedBox(width: 4),
                    _buildListingTabButton('Re-Sale'),
                  ],
                ),
              ),
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
                items: const [
                  DropdownMenuItem(value: "All", child: Text("All")),
                  DropdownMenuItem(value: "Live", child: Text("Interested")),
                  DropdownMenuItem(value: "Won", child: Text("Won")),
                  DropdownMenuItem(value: "Dead", child: Text("Not Interested")),
                ],
                onChanged: (val) {
                  setState(() => _selectedStatus = val ?? "All");
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

  Widget _buildListingTabButton(String label) {
    final isSelected = _activeListingTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeListingTab = label;
          _currentPage = 1;
        });
        _triggerFetch();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? CRMColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
        ),
        child: Text(
          label,
          style: CRMTypography.bodyMedium.copyWith(
            color: isSelected ? Colors.white : CRMColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
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

  bool _hasEditAccess(RequirementModel r, UserModel? currentUser) {
    if (currentUser == null) return true;
    if (currentUser.role == 'Super Admin' || currentUser.role == 'Admin') return true;
    if (currentUser.role == 'Sales' && r.adminId == currentUser.adminId) return true;
    return true;
  }

  Widget _buildRequirementsTable() {
    final authState = context.read<AuthBloc>().state;
    UserModel? currentUser;
    if (authState is Authenticated) {
      currentUser = authState.user;
    }

    return BlocBuilder<RequirementsBloc, RequirementsState>(
      builder: (context, state) {
        final isLoading = state is RequirementsLoading || state is RequirementsInitial;
        List<RequirementModel> requirements = [];

        if (state is RequirementsLoaded) {
          requirements = state.requirements.where((r) {
            return getListingTypeLabel(r) == _activeListingTab;
          }).toList();
        }

        final totalCount = requirements.length;
        final totalPages = (totalCount / _requirementsPerPage).ceil();
        final currentPage = _currentPage.clamp(1, totalPages > 0 ? totalPages : 1);

        final startIndex = (currentPage - 1) * _requirementsPerPage;
        final endIndex = (startIndex + _requirementsPerPage).clamp(0, totalCount);

        final pageItems = (startIndex < totalCount)
            ? requirements.sublist(startIndex, endIndex)
            : <RequirementModel>[];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            if (isMobile) {
              return _buildRequirementCards(pageItems, isLoading, currentUser, currentPage, totalPages, totalCount);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CRMDataTable(
                  isLoading: isLoading,
                  emptyTitle: 'No Requirements Found',
                  emptyDescription: 'Try adjusting filters or create a new requirement pipeline.',
                  columns: const [
                    DataColumn(label: Text('Client')),
                    DataColumn(label: Text('Specs / Config')),
                    DataColumn(label: Text('Budget Range')),
                    DataColumn(label: Text('Target Area(s)')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Matches')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: pageItems.map((req) {
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
                        DataCell(Text('${req.propertyTypeName} (${req.configurationName ?? "-"})', style: CRMTypography.body.copyWith(color: CRMColors.text))),
                        DataCell(
                          Text(
                            '${BudgetFormatter.format(req.minBudget)} - ${BudgetFormatter.format(req.maxBudget)}',
                            style: CRMTypography.bodyMedium.copyWith(color: CRMColors.primary),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 160,
                            child: Tooltip(
                              message: req.areaNames.join(', '),
                              child: Text(
                                req.areaNames.join(', '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          PopupMenuButton<String>(
                            tooltip: 'Change Status',
                            onSelected: (String newStatus) {
                              if (newStatus != req.status) {
                                context.read<RequirementsBloc>().add(
                                  UpdateRequirementEvent(req.copyWith(status: newStatus)),
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'Live',
                                child: Text('Interested'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'Won',
                                child: Text('Won'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'Dead',
                                child: Text('Not Interested'),
                              ),
                            ],
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: CRMSpacing.xxs),
                                decoration: BoxDecoration(
                                  color: isActive ? CRMColors.success.withValues(alpha: 0.12) : CRMColors.textMuted.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                                  border: Border.all(
                                    color: (isActive ? CRMColors.success : CRMColors.textMuted).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      displayStatusLabel(req.status),
                                      style: CRMTypography.captionBold.copyWith(
                                        color: isActive ? CRMColors.success : CRMColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.arrow_drop_down_rounded,
                                      size: 16,
                                      color: isActive ? CRMColors.success : CRMColors.textSecondary,
                                    ),
                                  ],
                                ),
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
                              if (_hasEditAccess(req, currentUser)) ...[
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, color: CRMColors.primary, size: 18),
                                  onPressed: () => _showAddEditDialog(req),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 18),
                                  onPressed: () => _showDeleteConfirmDialog(req),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                if (totalPages > 1) ...[
                  const SizedBox(height: CRMSpacing.m),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Page $currentPage of $totalPages ($totalCount requirements)',
                        style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, size: 20),
                            onPressed: currentPage > 1
                                ? () => setState(() => _currentPage--)
                                : null,
                            tooltip: 'Previous Page',
                          ),
                          Text(
                            '$currentPage / $totalPages',
                            style: CRMTypography.captionBold.copyWith(color: CRMColors.text),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, size: 20),
                            onPressed: currentPage < totalPages
                                ? () => setState(() => _currentPage++)
                                : null,
                            tooltip: 'Next Page',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRequirementCards(
    List<RequirementModel> requirements,
    bool isLoading,
    UserModel? currentUser,
    int currentPage,
    int totalPages,
    int totalCount,
  ) {
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
      children: [
        ...requirements.map((req) {
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
                      PopupMenuButton<String>(
                        tooltip: 'Change Status',
                        onSelected: (String newStatus) {
                          if (newStatus != req.status) {
                            context.read<RequirementsBloc>().add(
                              UpdateRequirementEvent(req.copyWith(status: newStatus)),
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'Live',
                            child: Text('Interested'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'Won',
                            child: Text('Won'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'Dead',
                            child: Text('Not Interested'),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: CRMSpacing.xxs),
                          decoration: BoxDecoration(
                            color: isActive ? CRMColors.success.withValues(alpha: 0.12) : CRMColors.textMuted.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                            border: Border.all(
                              color: (isActive ? CRMColors.success : CRMColors.textMuted).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displayStatusLabel(req.status),
                                style: CRMTypography.captionBold.copyWith(
                                  color: isActive ? CRMColors.success : CRMColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 16,
                                color: isActive ? CRMColors.success : CRMColors.textSecondary,
                              ),
                            ],
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
                      _buildDetailChip(Icons.sell_outlined, 'Listing Type', getListingTypeLabel(req)),
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
                      if (_hasEditAccess(req, currentUser)) ...[
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
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        if (totalPages > 1) ...[
          const SizedBox(height: CRMSpacing.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page $currentPage of $totalPages',
                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    onPressed: currentPage > 1
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  Text(
                    '$currentPage / $totalPages',
                    style: CRMTypography.captionBold.copyWith(color: CRMColors.text),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    onPressed: currentPage < totalPages
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
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

  Widget _buildMainViewTabButton(String label) {
    final isSelected = _activeMainTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeMainTab = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? CRMColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
        ),
        child: Text(
          label,
          style: CRMTypography.bodyMedium.copyWith(
            color: isSelected ? Colors.white : CRMColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFollowupsView() {
    final dateStr = _reqFollowupDateFilter != null
        ? DateFormat('dd/MM/yyyy').format(_reqFollowupDateFilter!)
        : 'All Dates';

    return CRMCard(
      title: 'Follow-ups Management',
      subtitle: 'Scheduled client communications and appointments',
      headerAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateStr,
            style: CRMTypography.captionBold.copyWith(color: CRMColors.primary),
          ),
          IconButton(
            icon: Icon(Icons.calendar_today_rounded, color: CRMColors.primary, size: 18),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _reqFollowupDateFilter ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() {
                  _reqFollowupDateFilter = picked;
                });
              }
            },
            tooltip: 'Filter by Date',
          ),
          if (_reqFollowupDateFilter != null)
            IconButton(
              icon: Icon(Icons.clear_rounded, color: CRMColors.textMuted, size: 18),
              onPressed: () {
                setState(() {
                  _reqFollowupDateFilter = null;
                });
              },
              tooltip: 'Show All Dates',
            ),
        ],
      ),
      child: FutureBuilder<DashboardData>(
        future: DashboardRepository().getDashboardData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final followups = snapshot.data?.followups ?? [];
          final filtered = followups.where((f) {
            if (_reqFollowupDateFilter == null) return true;
            final parsed = DateTime.tryParse(f.followupDate);
            if (parsed == null) return false;
            return parsed.year == _reqFollowupDateFilter!.year &&
                parsed.month == _reqFollowupDateFilter!.month &&
                parsed.day == _reqFollowupDateFilter!.day;
          }).toList();

          if (filtered.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  _reqFollowupDateFilter != null ? 'No follow-ups for $dateStr.' : 'No follow-ups found.',
                  style: TextStyle(color: CRMColors.textSecondaryOf(context)),
                ),
              ),
            );
          }

          return CRMDataTable(
            columns: const [
              DataColumn(label: Text('Client Name')),
              DataColumn(label: Text('Mobile')),
              DataColumn(label: Text('Scheduled Date')),
              DataColumn(label: Text('Remarks / Agenda')),
            ],
            rows: filtered.map((f) {
              return DataRow(
                cells: [
                  DataCell(Text(f.clientName, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(f.mobile)),
                  DataCell(Builder(
                    builder: (_) {
                      final parsed = DateTime.tryParse(f.followupDate);
                      final displayDate = parsed != null
                          ? DateFormat('dd/MM/yyyy hh:mm a').format(parsed)
                          : f.followupDate;
                      return Text(displayDate, style: TextStyle(color: CRMColors.primary, fontWeight: FontWeight.w600));
                    },
                  )),
                  DataCell(Text(f.notes ?? '-')),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class RequirementStepperDialog extends StatefulWidget {
  final RequirementModel requirement;
  final int initialStep;
  final VoidCallback onSaved;

  const RequirementStepperDialog({
    super.key,
    required this.requirement,
    this.initialStep = 1,
    required this.onSaved,
  });

  @override
  State<RequirementStepperDialog> createState() => _RequirementStepperDialogState();
}

class _RequirementStepperDialogState extends State<RequirementStepperDialog> {
  late int _currentStep;
  DateTime _followupDate = DateTime.now();
  TimeOfDay _followupTime = TimeOfDay.now();
  final TextEditingController _remarksController = TextEditingController();
  bool _isSavingFollowup = false;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _saveFollowup() async {
    final remarks = _remarksController.text.trim();
    if (remarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter followup remarks.')),
      );
      return;
    }

    setState(() => _isSavingFollowup = true);
    try {
      final scheduledDateTime = DateTime(
        _followupDate.year,
        _followupDate.month,
        _followupDate.day,
        _followupTime.hour,
        _followupTime.minute,
      );

      await DioClient.dio.post('/followup', data: {
        'clientName': widget.requirement.clientName,
        'clientMobile': widget.requirement.clientMobile,
        'remarks': remarks,
        'scheduledAt': scheduledDateTime.toIso8601String(),
        'requirementId': widget.requirement.id,
      });

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Followup added successfully!'), backgroundColor: CRMColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingFollowup = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add followup: $e'), backgroundColor: CRMColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Dialog(
      backgroundColor: CRMColors.cardBgOf(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.l)),
      child: Container(
        width: isMobile ? double.infinity : 700,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(CRMSpacing.m),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Update Requirement & Add Followup',
                    style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Stepper Content
            Expanded(
              child: Stepper(
                type: StepperType.horizontal,
                currentStep: _currentStep,
                onStepTapped: (step) => setState(() => _currentStep = step),
                controlsBuilder: (context, details) => const SizedBox.shrink(),
                steps: [
                  Step(
                    title: const Text('Edit Details'),
                    isActive: _currentStep == 0,
                    state: _currentStep == 0 ? StepState.editing : StepState.complete,
                    content: SizedBox(
                      height: 500,
                      child: AddEditRequirementScreen(
                        requirement: widget.requirement,
                        onSaved: () {
                          widget.onSaved();
                          setState(() => _currentStep = 1);
                        },
                      ),
                    ),
                  ),
                  Step(
                    title: const Text('Add Followup'),
                    isActive: _currentStep == 1,
                    state: _currentStep == 1 ? StepState.editing : StepState.indexed,
                    content: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: CRMSpacing.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Client: ${widget.requirement.clientName} (${widget.requirement.clientMobile})',
                              style: CRMTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: CRMColors.primary,
                              ),
                            ),
                            const SizedBox(height: CRMSpacing.m),
                            // Date & Time pickers row
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _followupDate,
                                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setState(() => _followupDate = picked);
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Followup Date *',
                                        prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                                      ),
                                      child: Text(DateFormat('dd/MM/yyyy').format(_followupDate)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: CRMSpacing.m),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: _followupTime,
                                      );
                                      if (picked != null) {
                                        setState(() => _followupTime = picked);
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Followup Time *',
                                        prefixIcon: const Icon(Icons.access_time_rounded, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                                      ),
                                      child: Text(_followupTime.format(context)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: CRMSpacing.m),
                            // Remarks textfield
                            TextField(
                              controller: _remarksController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Followup Remarks *',
                                hintText: 'Enter call summary, next meeting notes or client feedback...',
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                              ),
                            ),
                            const SizedBox(height: CRMSpacing.l),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: CRMSpacing.m),
                                CRMButton(
                                  label: _isSavingFollowup ? 'Saving...' : 'Save Followup',
                                  onPressed: _isSavingFollowup ? null : _saveFollowup,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
          await DioClient.dio.download(imgUrl, filePath);
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

String displayStatusLabel(String status) {
  if (status == 'Live' || status == 'Active') return 'Interested';
  if (status == 'Dead' || status == 'Suspended') return 'Not Interested';
  return status;
}

String getListingTypeLabel(RequirementModel r) {
  final name = r.listingTypeName ?? '';
  final id = r.listingTypeId ?? '';
  final combined = '$name $id'.toLowerCase();
  if (combined.contains('rent')) {
    return 'Rent';
  } else if (combined.contains('sale') || combined.contains('resale')) {
    return 'Re-Sale';
  }
  return 'Rent';
}