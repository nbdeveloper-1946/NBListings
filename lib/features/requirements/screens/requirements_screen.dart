import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

class RequirementsScreen extends StatefulWidget {
  const RequirementsScreen({super.key});

  @override
  State<RequirementsScreen> createState() => _RequirementsScreenState();
}

class _RequirementsScreenState extends State<RequirementsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedConfigId;
  String _selectedStatus = "All";

  @override
  void initState() {
    super.initState();
    _triggerFetch();
  }

  void _triggerFetch() {
    context.read<RequirementsBloc>().add(
          FetchRequirementsEvent(
            search: _searchController.text.trim(),
            configurationId: _selectedConfigId,
            status: _selectedStatus,
          ),
        );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedConfigId = null;
      _selectedStatus = "All";
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
          active = state.requirements.where((r) => r.status == 'Active').length;
          closed = state.requirements.where((r) => r.status == 'Closed').length;
        }

        final cards = [
          CRMKPICard(
            title: "TOTAL INQUIRIES",
            value: total.toString(),
            icon: Icons.assignment_rounded,
            iconColor: CRMColors.primary,
          ),
          CRMKPICard(
            title: "ACTIVE SEARCHES",
            value: active.toString(),
            icon: Icons.hourglass_empty_rounded,
            iconColor: CRMColors.warning,
          ),
          CRMKPICard(
            title: "MATCHED & CLOSED",
            value: closed.toString(),
            icon: Icons.check_circle_outline_rounded,
            iconColor: CRMColors.success,
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            if (!isWide) {
              return Column(
                children: cards.map((card) => Padding(
                  padding: const EdgeInsets.only(bottom: CRMSpacing.s),
                  child: card,
                )).toList(),
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
              _buildDropdownFilter(
                label: 'Configuration',
                value: _selectedConfigId,
                items: [
                  const DropdownMenuItem(value: null, child: Text("All Configurations")),
                  const DropdownMenuItem(value: '1bhk', child: Text("1 BHK")),
                  const DropdownMenuItem(value: '2bhk', child: Text("2 BHK")),
                  const DropdownMenuItem(value: '3bhk', child: Text("3 BHK")),
                  const DropdownMenuItem(value: '4bhk', child: Text("4 BHK")),
                ],
                onChanged: (val) {
                  setState(() => _selectedConfigId = val);
                  _triggerFetch();
                },
              ),
              _buildDropdownFilter(
                label: 'Status',
                value: _selectedStatus,
                items: ["All", "Active", "Closed", "Suspended"].map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
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

  Widget _buildDropdownFilter<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 200,
      height: 44,
      child: DropdownButtonFormField<T>(
        value: value,
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
                final isActive = req.status == 'Active';

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
                        '${(req.minBudget / 100000).toStringAsFixed(0)}L - ${(req.maxBudget / 100000).toStringAsFixed(0)}L',
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
        final isActive = req.status == 'Active';
        final budget = '₹${(req.minBudget / 100000).toStringAsFixed(0)}L - ₹${(req.maxBudget / 100000).toStringAsFixed(0)}L';

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
          const Divider(height: CRMSpacing.xl),
          
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
                      contentPadding: const EdgeInsets.all(CRMSpacing.m),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p.title, style: CRMTypography.bodyMedium),
                          Text(
                            '₹${(p.price / 100000).toStringAsFixed(1)}L',
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
}
