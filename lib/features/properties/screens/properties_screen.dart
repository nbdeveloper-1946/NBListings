import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/data_table.dart';
import '../../../core/design_system/widgets/drawers.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user_model.dart';
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
  final ScrollController _scrollController = ScrollController();
  String? _highlightedPropertyId;
  String _activeTab = 'All';
  bool _hasAutoOpenedAdd = false;
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
    _scrollController.dispose();
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
    final authState = context.read<AuthBloc>().state;
    String userName = 'User';
    if (authState is Authenticated) {
      userName = authState.user.fullName;
    }

    final text = 'Hello,\n'
        'I am $userName from NB Prop Tech.\n'
        'Is your property still available?\n'
        'Thank you.';
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

  bool _hasEditAccess(PropertyModel p, UserModel? currentUser) {
    if (currentUser == null) return false;
    if (currentUser.role == 'Super Admin') return true;
    if (p.createdBy == currentUser.id) return true;
    if (p.adminId != null && p.adminId == currentUser.adminId) return true;
    if (currentUser.role == 'Admin' && p.adminId == currentUser.id) return true;
    return false;
  }

  Widget _buildMobilePropertyCard(PropertyModel p, UserModel? currentUser, Set<String> bookmarkedIds, PropertyMetadataModel? metadata) {
    final isMine = _hasEditAccess(p, currentUser);
    final isBookmarked = bookmarkedIds.contains(p.id);
    final isHighlighted = p.id == _highlightedPropertyId;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CRMBorderRadius.m),
        border: Border.all(
          color: isHighlighted ? CRMColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: CRMCard(
        padding: const EdgeInsets.all(CRMSpacing.m),
        child: InkWell(
          onTap: () => showCRMPropertyDrawer(context, p),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  p.propertyCode,
                  style: CRMTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: CRMColors.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.isStatusAvailable 
                        ? CRMColors.success.withOpacity(0.1) 
                        : CRMColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                  ),
                  child: Text(
                    p.statusDisplayName,
                    style: TextStyle(
                      color: p.isStatusAvailable 
                          ? CRMColors.success 
                          : CRMColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.s),
            Text(
              p.title,
              style: CRMTypography.cardTitle.copyWith(
                color: CRMColors.textOf(context),
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: CRMSpacing.s),
            Wrap(
              spacing: CRMSpacing.m,
              runSpacing: CRMSpacing.xs,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: CRMColors.textSecondaryOf(context)),
                    const SizedBox(width: 4),
                    Text(
                      '${p.areaName}, ${p.cityName}',
                      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sell_outlined, size: 14, color: CRMColors.textSecondaryOf(context)),
                    const SizedBox(width: 4),
                    Text(
                      '₹${p.price.toStringAsFixed(0)}',
                      style: CRMTypography.captionBold.copyWith(
                        color: CRMColors.textOf(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: CRMSpacing.l),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Verified: ',
                      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: p.isVerified,
                        activeColor: CRMColors.success,
                        onChanged: (val) {
                          context.read<PropertiesBloc>().add(
                            ToggleVerificationEvent(p.id, val, activeTab: _activeTab),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.star_rounded : Icons.star_border_rounded,
                        color: isBookmarked ? CRMColors.warning : CRMColors.textMutedOf(context),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        context.read<PropertiesBloc>().add(
                          ToggleBookmarkEvent(p.id, activeTab: _activeTab),
                        );
                      },
                    ),
                    const SizedBox(width: CRMSpacing.m),
                    if (isMine && _activeTab != 'My Deleted') ...[
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: CRMColors.primary, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          if (metadata != null) {
                            _showAddEditPropertyDialog(context, metadata, p);
                          }
                        },
                      ),
                      const SizedBox(width: CRMSpacing.m),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          context.read<PropertiesBloc>().add(
                            DeletePropertyEvent(p.id, activeTab: _activeTab),
                          );
                        },
                      ),
                      const SizedBox(width: CRMSpacing.m),
                    ] else if (isMine && _activeTab == 'My Deleted') ...[
                      IconButton(
                        icon: Icon(Icons.restore_rounded, color: CRMColors.success, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          context.read<PropertiesBloc>().add(
                            RestorePropertyEvent(p.id, activeTab: _activeTab),
                          );
                        },
                      ),
                      const SizedBox(width: CRMSpacing.m),
                    ],
                    IconButton(
                      icon: Icon(Icons.chat_bubble_outline_rounded, color: CRMColors.success, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _launchWhatsApp(p),
                      tooltip: 'Contact on WhatsApp',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String? currentUserId;
    UserModel? currentUser;
    if (authState is Authenticated) {
      currentUserId = authState.user.id;
      currentUser = authState.user;
    }
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<PropertiesBloc, PropertiesState>(
        listener: (context, state) {
          if (state is PropertiesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: CRMColors.danger),
            );
          } else if (state is PropertySavedState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showCRMPropertyDrawer(context, state.property);
              if (_scrollController.hasClients) {
                _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
              }
              setState(() {
                _highlightedPropertyId = state.property.id;
              });
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    _highlightedPropertyId = null;
                  });
                }
              });
            });
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

            final action = GoRouterState.of(context).uri.queryParameters['action'];
            if (action == 'add' && !_hasAutoOpenedAdd && state.metadata != null) {
              _hasAutoOpenedAdd = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showAddEditPropertyDialog(context, state.metadata!);
              });
            }
          }

          final totalPages = properties.isEmpty ? 1 : (properties.length / _pageSize).ceil();
          final safePage = _currentPage.clamp(0, totalPages - 1);
          final pageStart = safePage * _pageSize;
          final pageEnd = (pageStart + _pageSize).clamp(0, properties.length);
          final pagedProperties = properties.isEmpty
              ? properties
              : properties.sublist(pageStart, pageEnd);

          return SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m,
              vertical: CRMSpacing.l,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Responsive Page Header
                _buildPageHeader(metadata),
                const SizedBox(height: CRMSpacing.l),

                // 2. Statistics Row (Overflow Fixed Layout)
                _buildStatisticsRow(properties),
                const SizedBox(height: CRMSpacing.l),

                // 3. Search & 4. Advanced Filters
                _buildSearchAndFilters(metadata),
                const SizedBox(height: CRMSpacing.l),

                // 5. Action Toolbar (Responsive choice chips)
                _buildActionToolbar(),
                const SizedBox(height: CRMSpacing.m),

                // 6. Property Table (Desktop) / Property Cards (Mobile) & 7. Pagination
                if (screenWidth < 768) ...[
                  if (isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  else if (pagedProperties.isEmpty)
                    CRMCard(
                      child: Padding(
                        padding: const EdgeInsets.all(CRMSpacing.xl),
                        child: Column(
                          children: [
                            Text('No Properties Found', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text)),
                            const SizedBox(height: CRMSpacing.s),
                            Text('No records match your active search terms.', style: CRMTypography.body.copyWith(color: CRMColors.textSecondary)),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: pagedProperties.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: CRMSpacing.m),
                          child: _buildMobilePropertyCard(p, currentUser, bookmarkedIds, metadata),
                        );
                      }).toList(),
                    ),
                ] else ...[
                  CRMDataTable(
                    isLoading: isLoading,
                    emptyTitle: 'No Properties Found',
                    emptyDescription: 'No records match your active search terms.',
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Code')),
                      DataColumn(label: Text('Society/Property Name')),
                      DataColumn(label: Text('Owner')),
                      DataColumn(label: Text('Area')),
                      DataColumn(label: Text('BHK')),
                      DataColumn(label: Text('Price')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Shortlist')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: pagedProperties.map((p) {
                      final isMine = _hasEditAccess(p, currentUser);
                      final isBookmarked = bookmarkedIds.contains(p.id);
                      return DataRow(
                        color: WidgetStateProperty.resolveWith<Color?>((states) {
                          if (p.id == _highlightedPropertyId) {
                            return CRMColors.primary.withOpacity(0.08);
                          }
                          return null;
                        }),
                        onSelectChanged: (_) => showCRMPropertyDrawer(context, p),
                        cells: [
                          DataCell(Text(p.propertyCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(p.title)),
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(p.ownerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(p.ownerMobile, style: TextStyle(color: CRMColors.textMuted, fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                          DataCell(Text(p.areaName)),
                          DataCell(Text('${p.bedrooms} BHK')),
                          DataCell(Text('₹${p.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(p.listingTypeName)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: p.isStatusAvailable 
                                    ? CRMColors.success.withOpacity(0.1) 
                                    : CRMColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                              ),
                              child: Text(
                                p.statusDisplayName,
                                style: TextStyle(
                                  color: p.isStatusAvailable ? CRMColors.success : CRMColors.warning,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ),
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
                                    icon: Icon(Icons.edit_outlined, color: CRMColors.primary, size: 18),
                                    onPressed: () {
                                      if (metadata != null) {
                                        _showAddEditPropertyDialog(context, metadata!, p);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 18),
                                    onPressed: () {
                                      context.read<PropertiesBloc>().add(
                                        DeletePropertyEvent(p.id, activeTab: _activeTab),
                                      );
                                    },
                                  ),
                                ] else if (isMine && _activeTab == 'My Deleted') ...[
                                  IconButton(
                                    icon: Icon(Icons.restore_rounded, color: CRMColors.success, size: 18),
                                    onPressed: () {
                                      context.read<PropertiesBloc>().add(
                                        RestorePropertyEvent(p.id, activeTab: _activeTab),
                                      );
                                    },
                                  ),
                                ],
                                IconButton(
                                  icon: Icon(Icons.chat_bubble_outline_rounded, color: CRMColors.success, size: 18),
                                  onPressed: () => _launchWhatsApp(p),
                                  tooltip: 'Contact on WhatsApp',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
                if (properties.isNotEmpty) ...[
                  const SizedBox(height: CRMSpacing.m),
                  _buildPagination(properties.length, totalPages, safePage),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageHeader(PropertyMetadataModel? metadata) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Workspace', style: CRMTypography.body.copyWith(color: CRMColors.textSecondary)),
        Text(
          'Properties Operating System', 
          style: CRMTypography.pageTitle.copyWith(
            color: CRMColors.text,
            fontSize: isMobile ? 20 : 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    Widget rightColumn = CRMButton(
      label: 'Add Property',
      prefixIcon: Icons.add_circle_outline_rounded,
      onPressed: () {
        if (metadata == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Metadata lookups loading, please try again.')),
          );
          return;
        }
        _showAddEditPropertyDialog(context, metadata!);
      },
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          leftColumn,
          const SizedBox(height: CRMSpacing.m),
          rightColumn,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: leftColumn),
        const SizedBox(width: CRMSpacing.m),
        rightColumn,
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

    final double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth >= 1440) {
      crossAxisCount = 4;
      childAspectRatio = 1.5;
    } else if (screenWidth >= 1024) {
      crossAxisCount = 4;
      childAspectRatio = 1.35;
    } else if (screenWidth >= 600) {
      crossAxisCount = 2;
      childAspectRatio = 1.5;
    } else {
      // Mobile 2-column view: Lower ratio gives cards more height for wrapped titles
      crossAxisCount = 2;
      childAspectRatio = 0.8;
    }

    final cards = [
      CRMKPICard(title: 'Properties Count', value: '$total', icon: Icons.inventory_2_outlined),
      CRMKPICard(title: 'Verified listings', value: '$verified', icon: Icons.verified_user_outlined, iconColor: CRMColors.success),
      CRMKPICard(title: 'Active listings', value: '$active', icon: Icons.bolt_rounded, iconColor: CRMColors.primary),
      CRMKPICard(title: 'Shortlisted listings', value: '$shortlisted', icon: Icons.star_outline_rounded, iconColor: CRMColors.warning),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: CRMSpacing.m,
        mainAxisSpacing: CRMSpacing.m,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return cards[index];
      },
    );
  }

  Widget _buildSearchAndFilters(PropertyMetadataModel? metadata) {
    final categories = metadata != null ? metadata.categories : <LookupItem>[];
    final areas = metadata != null ? metadata.areas : <AreaLookup>[];
    final listingTypes = metadata != null ? metadata.listingTypes : <LookupItem>[];

    return CRMCard(
      title: 'Advanced Search Filter Drawer',
      subtitle: 'Perform refined lookup filters across listing records',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.s),
        child: Column(
          children: [
            // Search Input Row
            LayoutBuilder(
              builder: (context, searchConstraints) {
                final isCompactSearch = searchConstraints.maxWidth < 500;
                
                final searchField = TextField(
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
                );

                final searchButton = CRMButton(
                  label: 'Search',
                  onPressed: _loadProperties,
                );

                if (isCompactSearch) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchField,
                      const SizedBox(height: CRMSpacing.s),
                      searchButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: CRMSpacing.s),
                    searchButton,
                  ],
                );
              },
            ),
            const SizedBox(height: CRMSpacing.m),
            
            // Filters Dropdowns Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                double targetWidth;
                
                if (width >= 900) {
                  targetWidth = (width - (CRMSpacing.m * 4)) / 5;
                } else if (width >= 600) {
                  targetWidth = (width - CRMSpacing.m) / 2;
                } else {
                  targetWidth = width;
                }

                return Wrap(
                  spacing: CRMSpacing.m,
                  runSpacing: CRMSpacing.m,
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
                      width: targetWidth,
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
                      width: targetWidth,
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
                      width: targetWidth,
                    ),
                    _buildVerificationDropdown(targetWidth),
                    SizedBox(
                      width: targetWidth,
                      height: 48, 
                      child: CRMButton(
                        label: 'Clear Filters',
                        variant: CRMButtonVariant.outline,
                        onPressed: _clearFilters,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
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
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Verification',
          filled: true,
          fillColor: CRMColors.background,
          contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.s),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s), borderSide: BorderSide.none),
        ),
        items: const [
          DropdownMenuItem<bool?>(value: null, child: Text('All Verification', overflow: TextOverflow.ellipsis)),
          DropdownMenuItem<bool?>(value: true, child: Text('Verified', overflow: TextOverflow.ellipsis)),
          DropdownMenuItem<bool?>(value: false, child: Text('Unverified', overflow: TextOverflow.ellipsis)),
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    final infoText = Text(
      'Showing $from–$to of $totalItems',
      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
    );

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
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
    );

    if (isMobile) {
      return Column(
        children: [
          infoText,
          const SizedBox(height: CRMSpacing.s),
          controls,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        infoText,
        controls,
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
    final bool hasValue = value == null || items.any((item) => item.value == value);
    final String? safeValue = hasValue ? value : null;

    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: safeValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: CRMColors.background,
          contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.s),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s), borderSide: BorderSide.none),
        ),
        items: [
          DropdownMenuItem<String>(value: null, child: Text('All $label', overflow: TextOverflow.ellipsis)),
          ...items,
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionToolbar() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final chipsList = Wrap(
      spacing: CRMSpacing.s,
      runSpacing: CRMSpacing.xs,
      children: ['All', 'My Active', 'My Deleted', 'Shortlisted'].map((tab) {
        final isSelected = _activeTab == tab;
        return ChoiceChip(
          label: Text(tab),
          selected: isSelected,
          selectedColor: CRMColors.primary.withOpacity(0.12),
          labelStyle: TextStyle(
            color: isSelected ? CRMColors.primary : CRMColors.text, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
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
    );

    final refreshButton = IconButton(
      icon: Icon(Icons.refresh_rounded, color: CRMColors.textSecondary),
      onPressed: _loadProperties,
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Views', style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              refreshButton,
            ],
          ),
          const SizedBox(height: CRMSpacing.xs),
          chipsList,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: chipsList),
        refreshButton,
      ],
    );
  }

  void _showAddEditPropertyDialog(BuildContext context, PropertyMetadataModel metadata, [PropertyModel? property]) {
    final propertiesBloc = context.read<PropertiesBloc>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12.0 : 40.0,
          vertical: isMobile ? 16.0 : 24.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: CRMColors.cardBg,
            borderRadius: BorderRadius.circular(CRMBorderRadius.m),
          ),
          width: isMobile ? screenWidth - 24 : screenWidth * 0.95,
          height: MediaQuery.of(context).size.height * 0.95,
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 750),
          clipBehavior: Clip.antiAlias,
          child: BlocProvider.value(
            value: propertiesBloc,
            child: AddEditPropertyScreen(
              metadata: metadata,
              property: property,
              activeTab: _activeTab,
            ),
          ),
        ),
      ),
    );
  }
}