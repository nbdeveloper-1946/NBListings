import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/data_table.dart';
import '../../../core/design_system/widgets/drawers.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/properties_bloc.dart';
import '../models/property_model.dart';
import 'add_edit_property_screen.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeTab = 'All';
  String? _selectedCategory;
  String? _selectedArea;
  String? _selectedListingType;
  bool? _selectedVerification;
  int _currentPage = 0;
  int _pageSize = 10;

  static const _pageSizeOptions = [10, 25, 50];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadProperties() {
    context.read<PropertiesBloc>().add(
      LoadPropertiesEvent(
        search: _searchController.text.trim(),
        categoryId: _selectedCategory,
        areaId: _selectedArea,
        listingTypeId: _selectedListingType,
        isVerified: _selectedVerification,
        activeTab: _activeTab,
      ),
    );
  }

  Future<void> _launchWhatsApp(PropertyModel property) async {
    final text = 'Hello, I am interested in your property ${property.propertyCode} (${property.title}) located at ${property.areaName}.';
    final url = 'https://wa.me/${property.ownerMobile}?text=${Uri.encodeComponent(text)}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String? currentUserId;
    if (authState is Authenticated) {
      currentUserId = authState.user.id;
    }

    return BlocConsumer<PropertiesBloc, PropertiesState>(
      listener: (context, state) {
        if (state is PropertiesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: CRMColors.danger),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is PropertiesLoading || state is PropertiesInitial;
        List<PropertyModel> properties = [];
        PropertyMetadataModel? metadata;
        Set<String> bookmarkedIds = {};

        if (state is PropertiesLoaded) {
          properties = state.properties;
          metadata = state.metadata;
          bookmarkedIds = state.bookmarkedIds;
        }

        final totalPages = properties.isEmpty ? 1 : (properties.length / _pageSize).ceil();
        final safePage = _currentPage.clamp(0, totalPages - 1);
        final pageStart = safePage * _pageSize;
        final pageEnd = (pageStart + _pageSize).clamp(0, properties.length);
        final pagedProperties = properties.isEmpty
            ? properties
            : properties.sublist(pageStart, pageEnd);

        // 1. Header Layout
        return Scaffold(
          backgroundColor: CRMColors.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(CRMSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPageHeader(metadata),
                const SizedBox(height: CRMSpacing.l),

                // 2. Statistics Cards
                _buildStatisticsRow(properties),
                const SizedBox(height: CRMSpacing.l),

                // 3. Search & 4. Advanced Filters
                _buildSearchAndFilters(metadata),
                const SizedBox(height: CRMSpacing.l),

                // 5. Action Toolbar
                _buildActionToolbar(),
                const SizedBox(height: CRMSpacing.m),

                // 6. Property Table & 7. Pagination
                CRMDataTable(
                  isLoading: isLoading,
                  emptyTitle: 'No Properties Found',
                  emptyDescription: 'No records match your active search terms.',
                  columns: const [
                    DataColumn(label: Text('Shortlist')),
                    DataColumn(label: Text('Actions')),
                    DataColumn(label: Text('Verified')),
                    DataColumn(label: Text('Code')),
                    DataColumn(label: Text('Title')),
                    DataColumn(label: Text('City')),
                    DataColumn(label: Text('Area')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: pagedProperties.map((p) {
                    final isMine = p.createdBy == currentUserId;
                    final isBookmarked = bookmarkedIds.contains(p.id);
                    return DataRow(
                      onSelectChanged: (_) => showCRMPropertyDrawer(context, p),
                      cells: [
                        DataCell(
                          IconButton(
                            icon: Icon(
                              isBookmarked ? Icons.star_rounded : Icons.star_border_rounded,
                              color: isBookmarked ? CRMColors.warning : CRMColors.textMuted,
                            ),
                            onPressed: () {
                              context.read<PropertiesBloc>().add(
                                ToggleBookmarkEvent(p.id, activeTab: _activeTab),
                              );
                            },
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isMine && _activeTab != 'My Deleted') ...[
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: CRMColors.primary, size: 18),
                                  onPressed: () {
                                    if (metadata != null) {
                                      final propertiesBloc = context.read<PropertiesBloc>();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BlocProvider.value(
                                            value: propertiesBloc,
                                            child: AddEditPropertyScreen(
                                              metadata: metadata!,
                                              property: p,
                                              activeTab: _activeTab,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 18),
                                  onPressed: () {
                                    context.read<PropertiesBloc>().add(
                                      DeletePropertyEvent(p.id, activeTab: _activeTab),
                                    );
                                  },
                                ),
                              ] else if (isMine && _activeTab == 'My Deleted') ...[
                                IconButton(
                                  icon: const Icon(Icons.restore_rounded, color: CRMColors.success, size: 18),
                                  onPressed: () {
                                    context.read<PropertiesBloc>().add(
                                      RestorePropertyEvent(p.id, activeTab: _activeTab),
                                    );
                                  },
                                ),
                              ],
                              IconButton(
                                icon: const Icon(Icons.share_outlined, color: CRMColors.success, size: 18),
                                onPressed: () => _launchWhatsApp(p),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Switch(
                            value: p.isVerified,
                            activeColor: CRMColors.success,
                            onChanged: (val) {
                              context.read<PropertiesBloc>().add(
                                ToggleVerificationEvent(p.id, val, activeTab: _activeTab),
                              );
                            },
                          ),
                        ),
                        DataCell(Text(p.propertyCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(p.title)),
                        DataCell(Text(p.cityName)),
                        DataCell(Text(p.areaName)),
                        DataCell(Text('₹${p.price.toStringAsFixed(0)}')),
                        DataCell(Text(p.propertyStatusName)),
                      ],
                    );
                  }).toList(),
                ),
                if (properties.isNotEmpty) ...[
                  const SizedBox(height: CRMSpacing.m),
                  _buildPagination(properties.length, totalPages, safePage),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageHeader(PropertyMetadataModel? metadata) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Workspace', style: CRMTypography.body.copyWith(color: CRMColors.textSecondary)),
            Text('Properties Operating System', style: CRMTypography.pageTitle.copyWith(color: CRMColors.text)),
          ],
        ),
        CRMButton(
          label: 'Add Property',
          prefixIcon: Icons.add_circle_outline_rounded,
          onPressed: () {
            if (metadata == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Metadata lookups loading, please try again.')),
              );
              return;
            }
            final propertiesBloc = context.read<PropertiesBloc>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: propertiesBloc,
                  child: AddEditPropertyScreen(
                    metadata: metadata,
                    activeTab: _activeTab,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatisticsRow(List<PropertyModel> properties) {
    final bookmarkedIds = (context.read<PropertiesBloc>().state is PropertiesLoaded)
        ? (context.read<PropertiesBloc>().state as PropertiesLoaded).bookmarkedIds
        : <String>{};

    final total = properties.length;
    final verified = properties.where((p) => p.isVerified).length;
    final active = properties.where((p) => p.propertyStatusName == 'Available').length;
    final shortlisted = properties.where((p) => bookmarkedIds.contains(p.id)).length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 4 : 2,
      crossAxisSpacing: CRMSpacing.m,
      mainAxisSpacing: CRMSpacing.m,
      childAspectRatio: 2.2,
      children: [
        CRMKPICard(title: 'Properties Count', value: '$total', icon: Icons.inventory_2_outlined),
        CRMKPICard(title: 'Verified listings', value: '$verified', icon: Icons.verified_user_outlined, iconColor: CRMColors.success),
        CRMKPICard(title: 'Active listings', value: '$active', icon: Icons.bolt_rounded, iconColor: CRMColors.primary),
        CRMKPICard(title: 'Shortlisted listings', value: '$shortlisted', icon: Icons.star_outline_rounded, iconColor: CRMColors.warning),
      ],
    );
  }

  Widget _buildSearchAndFilters(PropertyMetadataModel? metadata) {
    final categories = metadata != null ? metadata.categories : <LookupItem>[];
    final areas = metadata != null ? metadata.areas : <AreaLookup>[];
    final listingTypes = metadata != null ? metadata.listingTypes : <LookupItem>[];

    return CRMCard(
      title: 'Advanced Search Filter Drawer',
      subtitle: 'Perform refined lookup filters across listing records',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: CRMTypography.body.copyWith(color: CRMColors.text),
                  decoration: InputDecoration(
                    hintText: 'Search property code, title, owner mobile...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: CRMColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s), borderSide: BorderSide.none),
                  ),
                  onChanged: (_) => _loadProperties(),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              CRMButton(
                label: 'Search',
                onPressed: _loadProperties,
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              return Wrap(
                spacing: CRMSpacing.m,
                runSpacing: CRMSpacing.s,
                children: [
                  _buildDropdown(
                    label: 'Category',
                    value: _selectedCategory,
                    items: categories.map((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategory = val;
                        _currentPage = 0;
                      });
                      _loadProperties();
                    },
                    width: isWide ? 180 : double.infinity,
                  ),
                  _buildDropdown(
                    label: 'Area',
                    value: _selectedArea,
                    items: areas.map((a) => DropdownMenuItem<String>(value: a.id, child: Text(a.name))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedArea = val;
                        _currentPage = 0;
                      });
                      _loadProperties();
                    },
                    width: isWide ? 180 : double.infinity,
                  ),
                  _buildDropdown(
                    label: 'Listing Type',
                    value: _selectedListingType,
                    items: listingTypes.map((l) => DropdownMenuItem<String>(value: l.id, child: Text(l.name))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedListingType = val;
                        _currentPage = 0;
                      });
                      _loadProperties();
                    },
                    width: isWide ? 180 : double.infinity,
                  ),
                  _buildVerificationDropdown(isWide ? 180 : double.infinity),
                  CRMButton(
                    label: 'Clear Filters',
                    variant: CRMButtonVariant.outline,
                    onPressed: _clearFilters,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedArea = null;
      _selectedListingType = null;
      _selectedVerification = null;
      _currentPage = 0;
    });
    _loadProperties();
  }

  Widget _buildVerificationDropdown(double width) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<bool?>(
        value: _selectedVerification,
        decoration: InputDecoration(
          labelText: 'Verification',
          filled: true,
          fillColor: CRMColors.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s), borderSide: BorderSide.none),
        ),
        items: const [
          DropdownMenuItem<bool?>(value: null, child: Text('All Verification')),
          DropdownMenuItem<bool?>(value: true, child: Text('Verified')),
          DropdownMenuItem<bool?>(value: false, child: Text('Unverified')),
        ],
        onChanged: (val) {
          setState(() {
            _selectedVerification = val;
            _currentPage = 0;
          });
          _loadProperties();
        },
      ),
    );
  }

  Widget _buildPagination(int totalItems, int totalPages, int currentPage) {
    final from = currentPage * _pageSize + 1;
    final to = ((currentPage + 1) * _pageSize).clamp(0, totalItems);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing $from–$to of $totalItems',
          style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
        ),
        Row(
          children: [
            Text('Rows:', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary)),
            const SizedBox(width: CRMSpacing.xs),
            DropdownButton<int>(
              value: _pageSize,
              underline: const SizedBox.shrink(),
              items: _pageSizeOptions
                  .map((size) => DropdownMenuItem(value: size, child: Text('$size')))
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _pageSize = val;
                  _currentPage = 0;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: currentPage > 0
                  ? () => setState(() => _currentPage--)
                  : null,
            ),
            Text(
              '${currentPage + 1} / $totalPages',
              style: CRMTypography.captionBold.copyWith(color: CRMColors.text),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: currentPage < totalPages - 1
                  ? () => setState(() => _currentPage++)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: CRMColors.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s), borderSide: BorderSide.none),
        ),
        items: [
          DropdownMenuItem<String>(value: null, child: Text('All $label')),
          ...items,
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionToolbar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Tabs
        Wrap(
          spacing: CRMSpacing.s,
          children: ['All', 'My Active', 'My Deleted', 'Shortlisted'].map((tab) {
            final isSelected = _activeTab == tab;
            return ChoiceChip(
              label: Text(tab),
              selected: isSelected,
              selectedColor: CRMColors.primary.withOpacity(0.12),
              labelStyle: TextStyle(color: isSelected ? CRMColors.primary : CRMColors.text, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _activeTab = tab;
                    _currentPage = 0;
                  });
                  _loadProperties();
                }
              },
            );
          }).toList(),
        ),
        // Toolbar Refresh
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: CRMColors.textSecondary),
          onPressed: _loadProperties,
        ),
      ],
    );
  }
}
