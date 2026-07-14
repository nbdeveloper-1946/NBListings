import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_exception.dart';
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

  @override
  void initState() {
    super.initState();
    _loadProperties();
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

  String _formatPrice(double price) {
    if (price >= 10000000) {
      return '${(price / 10000000).toStringAsFixed(2)} Cr';
    } else if (price >= 100000) {
      return '${(price / 100000).toStringAsFixed(2)} Lacs';
    }
    return price.toStringAsFixed(0);
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Properties Panel'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProperties,
          ),
        ],
      ),
      body: BlocConsumer<PropertiesBloc, PropertiesState>(
        listener: (context, state) {
          if (state is PropertiesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red[600]),
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

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Search/Control Row
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Filters Dropdown Button
                        PopupMenuButton<String>(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.filter_list, size: 18, color: Colors.grey[700]),
                                const SizedBox(width: 8),
                                Text('Filters', style: TextStyle(color: Colors.grey[700])),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down, size: 18),
                              ],
                            ),
                          ),
                          itemBuilder: (context) {
                            return [
                              PopupMenuItem(
                                enabled: false,
                                child: Text('Filter Categories', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo[800])),
                              ),
                              ...?(metadata?.categories.map((c) => PopupMenuItem(
                                    value: 'category:${c.id}',
                                    child: Text(c.name),
                                  ))),
                              PopupMenuItem(
                                enabled: false,
                                child: Text('Filter Listing Types', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo[800])),
                              ),
                              ...?(metadata?.listingTypes.map((l) => PopupMenuItem(
                                    value: 'listing:${l.id}',
                                    child: Text(l.name),
                                  ))),
                              const PopupMenuItem(
                                value: 'clear',
                                child: Text('Clear Filters', style: TextStyle(color: Colors.red)),
                              ),
                            ];
                          },
                          onSelected: (val) {
                            if (val == 'clear') {
                              setState(() {
                                _selectedCategory = null;
                                _selectedListingType = null;
                              });
                            } else if (val.startsWith('category:')) {
                              setState(() {
                                _selectedCategory = val.split(':')[1];
                              });
                            } else if (val.startsWith('listing:')) {
                              setState(() {
                                _selectedListingType = val.split(':')[1];
                              });
                            }
                            _loadProperties();
                          },
                        ),
                        const SizedBox(width: 12),

                        // Search Bar
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Advanced Search (Title, Landmark, Code)...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onSubmitted: (_) => _loadProperties(),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Add Property Button
                        ElevatedButton.icon(
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
                                    metadata: metadata!,
                                    activeTab: _activeTab,
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add property'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Selection Tabs
                Row(
                  children: [
                    _buildTabButton('All'),
                    _buildTabButton('My Active'),
                    _buildTabButton('My Deleted'),
                    _buildTabButton('Shortlisted'),
                  ],
                ),
                const SizedBox(height: 16),

                // Table / Grid Panel
                Expanded(
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : properties.isEmpty
                              ? Center(
                                  child: Text(
                                    'No properties found.',
                                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                                  ),
                                )
                              : _buildPropertiesTable(properties, bookmarkedIds, currentUserId),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabButton(String tab) {
    final isSelected = _activeTab == tab;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(tab),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _activeTab = tab;
            });
            _loadProperties();
          }
        },
        selectedColor: Colors.indigo[50],
        checkmarkColor: Colors.indigo[600],
        labelStyle: TextStyle(
          color: isSelected ? Colors.indigo[800] : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildPropertiesTable(
    List<PropertyModel> list,
    Set<String> bookmarks,
    String? currentUserId,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
          columns: const [
            DataColumn(label: Text('ACTION')),
            DataColumn(label: Text('VERIFIED')),
            DataColumn(label: Text('PROPERTY #')),
            DataColumn(label: Text('PROPERTY TYPE')),
            DataColumn(label: Text('DATE')),
            DataColumn(label: Text('BROKER')),
            DataColumn(label: Text('ESTATE NAME & BROKER MOBILE')),
            DataColumn(label: Text('SCHEME NAME')),
            DataColumn(label: Text('LANDMARK')),
            DataColumn(label: Text('LOCATION')),
            DataColumn(label: Text('RENT/SELL PRICE')),
            DataColumn(label: Text('AVAILABILITY')),
            DataColumn(label: Text('CONDITION')),
            DataColumn(label: Text('PROPERTY DESCRIPTION')),
            DataColumn(label: Text('PROPERTY DETAILS')),
            DataColumn(label: Text('SQFEET')),
            DataColumn(label: Text('SOURCE')),
          ],
          rows: list.map((property) {
            final isBookmarked = bookmarks.contains(property.id);
            final isMine = property.createdBy == currentUserId;

            return DataRow(
              cells: [
                // ACTION
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Toggle Verification flag
                      IconButton(
                        icon: Icon(
                          Icons.flag,
                          color: property.isVerified ? Colors.orange : Colors.grey[400],
                        ),
                        tooltip: 'Toggle verification',
                        onPressed: () {
                          context.read<PropertiesBloc>().add(
                                ToggleVerificationEvent(
                                  property.id,
                                  !property.isVerified,
                                  activeTab: _activeTab,
                                ),
                              );
                        },
                      ),
                      // Toggle Bookmark
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked ? Colors.amber[700] : Colors.grey[600],
                        ),
                        tooltip: 'Shortlist',
                        onPressed: () {
                          context.read<PropertiesBloc>().add(
                                ToggleBookmarkEvent(
                                  property.id,
                                  activeTab: _activeTab,
                                ),
                              );
                        },
                      ),
                      // WhatsApp Redirect
                      IconButton(
                        icon: const Icon(Icons.chat, color: Colors.green),
                        tooltip: 'Share on WhatsApp',
                        onPressed: () => _launchWhatsApp(property),
                      ),
                      // Edit Button
                      if (isMine && _activeTab != 'My Deleted')
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.indigo),
                          tooltip: 'Edit details',
                          onPressed: () {
                            // Find metadata from current bloc state
                            final state = context.read<PropertiesBloc>().state;
                            if (state is PropertiesLoaded && state.metadata != null) {
                              final propertiesBloc = context.read<PropertiesBloc>();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: propertiesBloc,
                                    child: AddEditPropertyScreen(
                                      metadata: state.metadata!,
                                      property: property,
                                      activeTab: _activeTab,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      // Soft-Delete / Restore
                      if (isMine)
                        _activeTab == 'My Deleted'
                            ? IconButton(
                                icon: const Icon(Icons.restore, color: Colors.green),
                                tooltip: 'Restore Listing',
                                onPressed: () {
                                  context.read<PropertiesBloc>().add(
                                        RestorePropertyEvent(
                                          property.id,
                                          activeTab: _activeTab,
                                        ),
                                      );
                                },
                              )
                            : IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Soft delete listing',
                                onPressed: () {
                                  context.read<PropertiesBloc>().add(
                                        DeletePropertyEvent(
                                          property.id,
                                          activeTab: _activeTab,
                                        ),
                                      );
                                },
                              ),
                    ],
                  ),
                ),
                // VERIFIED
                DataCell(
                  Icon(
                    property.isVerified ? Icons.check_circle : Icons.cancel,
                    color: property.isVerified ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
                // PROPERTY #
                DataCell(Text(property.propertyCode)),
                // PROPERTY TYPE
                DataCell(Text('${property.listingTypeName} - ${property.propertyTypeName}')),
                // DATE
                DataCell(Text(property.createdAt.toLocal().toString().substring(0, 10))),
                // BROKER
                DataCell(Text(property.brokerName ?? 'N/A')),
                // ESTATE NAME & BROKER MOBILE
                DataCell(Text('${property.title} (${property.ownerMobile})')),
                // SCHEME NAME
                DataCell(Text(property.title)),
                // LANDMARK
                DataCell(Text(property.landmark ?? 'N/A')),
                // LOCATION
                DataCell(Text(property.areaName)),
                // RENT/SELL PRICE
                DataCell(Text(_formatPrice(property.price))),
                // AVAILABILITY
                DataCell(Text(
                  property.configurationName != null
                      ? '${property.configurationName} ${property.propertyTypeName}'
                      : property.propertyTypeName,
                )),
                // CONDITION
                DataCell(Text(property.furnishingTypeName ?? 'N/A')),
                // PROPERTY DESCRIPTION
                DataCell(Text(property.description ?? 'N/A')),
                // PROPERTY DETAILS
                DataCell(Text(property.remarks ?? 'N/A')),
                // SQFEET
                DataCell(Text(property.superBuiltupArea != null ? '${property.superBuiltupArea!.toStringAsFixed(0)} Sq.Ft.' : 'N/A')),
                // SOURCE
                DataCell(const Text('Whatsapp')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
