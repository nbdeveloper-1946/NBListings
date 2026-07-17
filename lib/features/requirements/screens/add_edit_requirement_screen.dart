import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/requirements_bloc.dart';
import '../models/requirement_model.dart';
import '../../properties/repository/properties_repository.dart';
import '../../properties/models/property_model.dart';
import '../../../core/design_system/crm_design_system.dart';
import '../../../core/storage/crm_draft_repository.dart';

class AddEditRequirementScreen extends StatefulWidget {
  final RequirementModel? requirement;
  final VoidCallback onSaved;

  const AddEditRequirementScreen({
    super.key,
    this.requirement,
    required this.onSaved,
  });

  @override
  State<AddEditRequirementScreen> createState() => _AddEditRequirementScreenState();
}

class _AddEditRequirementScreenState extends State<AddEditRequirementScreen> {
  final _formKey = GlobalKey<FormState>();
  final PropertiesRepository _propertiesRepository = PropertiesRepository();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _budgetController = TextEditingController();
  final _minAreaController = TextEditingController();
  final _maxAreaController = TextEditingController();
  final _remarksController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedTypeId;
  String? _selectedConfigId;
  String? _selectedListingTypeId;
  String? _selectedFurnishing = 'None';
  String _selectedStatus = "Live";
  final List<String> _selectedAreaIds = [];
  bool _isSaved = false;

  bool _isLoadingMetadata = true;
  List<LookupItem> _categories = [];
  List<LookupItem> _types = [];
  List<LookupItem> _configurations = [];
  List<AreaLookup> _areas = [];
  List<LookupItem> _cities = [];
  List<LookupItem> _listingTypes = [];

  @override
  void initState() {
    super.initState();
    _loadMetadata();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.requirement == null && CRMDraftRepository().hasDraft('requirement')) {
        _showRestoreDraftDialog();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _budgetController.dispose();
    _minAreaController.dispose();
    _maxAreaController.dispose();
    _remarksController.dispose();
    if (!_isSaved && widget.requirement == null) {
      _saveCurrentDraft();
    }
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    try {
      final metadata = await _propertiesRepository.getPropertyMetadata();
      setState(() {
        _categories = metadata.categories;
        _types = metadata.types;
        _configurations = metadata.configurations;
        _areas = metadata.areas;
        _cities = metadata.cities;
        _listingTypes = metadata.listingTypes;
        
        if (widget.requirement == null) {
          if (_categories.isNotEmpty) _selectedCategoryId = _categories.first.id;
          if (_types.isNotEmpty) _selectedTypeId = _types.first.id;
          if (_listingTypes.isNotEmpty) _selectedListingTypeId = _listingTypes.first.id;
        } else {
          final req = widget.requirement!;
          _nameController.text = req.clientName;
          _mobileController.text = req.clientMobile;
          final double avgBudget = req.minBudget == req.maxBudget ? req.minBudget : (req.minBudget + req.maxBudget) / 2;
          _budgetController.text = CRMCurrencyFormatter.format(avgBudget);
          _minAreaController.text = req.minArea?.toStringAsFixed(0) ?? '';
          _maxAreaController.text = req.maxArea?.toStringAsFixed(0) ?? '';
          
          String remarks = req.remarks ?? '';
          String? extractedFurnishing = 'None';
          if (remarks.startsWith('[Furnishing: ')) {
            final endIdx = remarks.indexOf(']');
            if (endIdx != -1) {
              extractedFurnishing = remarks.substring('[Furnishing: '.length, endIdx);
              remarks = remarks.substring(endIdx + 1).trim();
            }
          }
          _remarksController.text = remarks;
          _selectedFurnishing = extractedFurnishing;

          _selectedCategoryId = req.categoryId;
          _selectedTypeId = req.propertyTypeId;
          _selectedConfigId = req.configurationId;
          _selectedListingTypeId = req.listingTypeId;
          
          String mappedStatus = req.status;
          if (mappedStatus == 'Active') mappedStatus = 'Live';
          if (mappedStatus == 'Closed') mappedStatus = 'Won';
          if (mappedStatus == 'Suspended') mappedStatus = 'Dead';
          _selectedStatus = mappedStatus;
          
          _selectedAreaIds.addAll(req.areaIds);
        }
        
        _isLoadingMetadata = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMetadata = false;
      });
    }
  }

  void _saveCurrentDraft() {
    if (widget.requirement != null) return;
    final draftData = {
      'clientName': _nameController.text,
      'clientMobile': _mobileController.text,
      'category_id': _selectedCategoryId,
      'property_type_id': _selectedTypeId,
      'configuration_id': _selectedConfigId,
      'listing_type_id': _selectedListingTypeId,
      'furnishing': _selectedFurnishing,
      'budget': _budgetController.text,
      'minArea': _minAreaController.text,
      'maxArea': _maxAreaController.text,
      'remarks': _remarksController.text,
      'status': _selectedStatus,
      'areaIds': _selectedAreaIds,
    };
    CRMDraftRepository().saveDraft('requirement', draftData);
  }

  void _showRestoreDraftDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Unsaved Draft?'),
        content: const Text('We found an unsaved draft from your previous session. Would you like to restore it?'),
        actions: [
          TextButton(
            child: const Text('Discard'),
            onPressed: () {
              CRMDraftRepository().clearDraft('requirement');
              Navigator.pop(ctx);
            },
          ),
          TextButton(
            child: const Text('Restore'),
            onPressed: () {
              final draft = CRMDraftRepository().getDraft('requirement');
              if (draft != null) {
                setState(() {
                  _nameController.text = draft['clientName'] ?? '';
                  _mobileController.text = draft['clientMobile'] ?? '';
                  _selectedCategoryId = draft['category_id'];
                  _selectedTypeId = draft['property_type_id'];
                  _selectedConfigId = draft['configuration_id'];
                  _selectedListingTypeId = draft['listing_type_id'];
                  _selectedFurnishing = draft['furnishing'] ?? 'None';
                  _budgetController.text = draft['budget'] ?? '';
                  _minAreaController.text = draft['minArea'] ?? '';
                  _maxAreaController.text = draft['maxArea'] ?? '';
                  _remarksController.text = draft['remarks'] ?? '';
                  _selectedStatus = draft['status'] ?? 'Live';
                  
                  final List<String> areas = List<String>.from(draft['areaIds'] ?? []);
                  _selectedAreaIds.clear();
                  _selectedAreaIds.addAll(areas);
                });
              }
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  List<LookupItem> _getFilteredTypes() {
    if (_selectedCategoryId == null) return [];
    return _types.where((t) => t.categoryId == _selectedCategoryId).toList();
  }

  List<LookupItem> _getFilteredConfigs() {
    if (_selectedCategoryId == null) return [];
    return _configurations.where((c) => c.categoryId == _selectedCategoryId).toList();
  }

  void _showAddAreaDialog() {
    final nameController = TextEditingController();
    final pincodeController = TextEditingController();
    String? selectedCityId = _cities.isNotEmpty ? _cities.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: CRMColors.cardBg,
            title: Text('Add New Area', style: TextStyle(color: CRMColors.textOf(context))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCityId,
                  dropdownColor: CRMColors.cardBg,
                  style: TextStyle(color: CRMColors.textOf(context)),
                  decoration: const InputDecoration(labelText: 'City *'),
                  items: _cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedCityId = val;
                    });
                  },
                ),
                const SizedBox(height: CRMSpacing.m),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: CRMColors.textOf(context)),
                  decoration: const InputDecoration(labelText: 'Area Name *'),
                ),
                const SizedBox(height: CRMSpacing.m),
                TextField(
                  controller: pincodeController,
                  style: TextStyle(color: CRMColors.textOf(context)),
                  decoration: const InputDecoration(labelText: 'Pincode *'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(ctx),
              ),
              TextButton(
                child: const Text('Add'),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final pincode = pincodeController.text.trim();
                  if (selectedCityId != null && name.isNotEmpty && pincode.isNotEmpty) {
                    try {
                      final repository = PropertiesRepository();
                      final payload = {
                        'city_id': selectedCityId!,
                        'area_name': name,
                        'pincode': pincode,
                      };
                      final response = await repository.createLookup('area', payload);
                      final newArea = AreaLookup(
                        id: response.id,
                        name: response.name,
                        cityId: selectedCityId!,
                        pincode: pincode,
                      );
                      setState(() {
                        _areas.add(newArea);
                        _selectedAreaIds.add(newArea.id);
                      });
                      if (mounted) Navigator.pop(ctx);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add area: $e'), backgroundColor: CRMColors.danger),
                      );
                    }
                  }
                },
              ),
            ],
          );
        }
      ),
    );
  }

  void _submitForm() {
    if (!CRMFormUtils.validateAndScroll(_formKey, context)) return;
    if (_selectedAreaIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one target area."), backgroundColor: CRMColors.danger),
      );
      return;
    }

    final cat = _categories.firstWhere((c) => c.id == _selectedCategoryId);
    final type = _types.firstWhere((t) => t.id == _selectedTypeId);
    final config = _configurations.firstWhere(
      (c) => c.id == _selectedConfigId,
      orElse: () => LookupItem(id: '', name: 'N/A'),
    );

    final List<String> areaNames = _selectedAreaIds.map((id) {
      final match = _areas.firstWhere((a) => a.id == id, orElse: () => AreaLookup(id: id, name: id, cityId: '', pincode: ''));
      return match.name;
    }).toList();

    final budgetVal = CRMCurrencyFormatter.parse(_budgetController.text);
    final String remarksText = _remarksController.text.trim();
    final String? finalRemarks = (_selectedFurnishing != null && _selectedFurnishing != 'None')
        ? '[Furnishing: $_selectedFurnishing] $remarksText'
        : (remarksText.isEmpty ? null : remarksText);

    final listingType = _listingTypes.firstWhere(
      (lt) => lt.id == _selectedListingTypeId,
      orElse: () => LookupItem(id: '', name: 'N/A'),
    );

    final req = RequirementModel(
      id: widget.requirement?.id ?? '',
      clientName: _nameController.text.trim(),
      clientMobile: _mobileController.text.trim(),
      categoryId: _selectedCategoryId!,
      categoryName: cat.name,
      propertyTypeId: _selectedTypeId!,
      propertyTypeName: type.name,
      configurationId: _selectedConfigId,
      configurationName: config.id.isNotEmpty ? config.name : null,
      listingTypeId: _selectedListingTypeId,
      listingTypeName: listingType.id.isNotEmpty ? listingType.name : null,
      minBudget: budgetVal * 0.8,
      maxBudget: budgetVal * 1.2,
      minArea: double.tryParse(_minAreaController.text),
      maxArea: double.tryParse(_maxAreaController.text),
      areaIds: _selectedAreaIds,
      areaNames: areaNames,
      remarks: finalRemarks,
      status: _selectedStatus,
      createdAt: widget.requirement?.createdAt ?? DateTime.now(),
    );

    _isSaved = true;
    CRMDraftRepository().clearDraft('requirement');

    if (widget.requirement == null) {
      context.read<RequirementsBloc>().add(CreateRequirementEvent(req));
    } else {
      context.read<RequirementsBloc>().add(UpdateRequirementEvent(req));
    }

    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingMetadata) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(CRMSpacing.xl),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: CRMSpacing.m),
              Text("Loading parameters..."),
            ],
          ),
        ),
      );
    }

    final isEditing = widget.requirement != null;

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final filteredTypes = _getFilteredTypes();
    if (_selectedTypeId != null && !filteredTypes.any((t) => t.id == _selectedTypeId)) {
      _selectedTypeId = filteredTypes.isNotEmpty ? filteredTypes.first.id : null;
    }
    final filteredConfigs = _getFilteredConfigs();
    if (_selectedConfigId != null && !filteredConfigs.any((c) => c.id == _selectedConfigId)) {
      _selectedConfigId = null;
    }

    return Dialog(
      backgroundColor: CRMColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(CRMSpacing.l),
          child: CRMForm(
            formKey: _formKey,
            isDirty: true,
            onSave: () async {
              _submitForm();
              return true;
            },
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? "Edit Client Inquiry" : "Publish Buyer Requirement",
                    style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text),
                  ),
                  const SizedBox(height: CRMSpacing.xs),
                  Text(
                    "Setup search parameters for automated property matching",
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                  ),
                  const SizedBox(height: CRMSpacing.l),
                  
                  // Client info
                  if (isMobile) ...[
                    CRMTextField(
                      controller: _nameController,
                      labelText: 'Client Name *',
                      hintText: 'Enter name',
                      prefixIcon: Icons.person_rounded,
                      validator: (v) => v == null || v.isEmpty ? 'Client name required' : null,
                    ),
                    const SizedBox(height: CRMSpacing.m),
                    CRMPhoneField(
                      controller: _mobileController,
                      labelText: 'Client Mobile',
                      isRequired: true,
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: CRMTextField(
                            controller: _nameController,
                            labelText: 'Client Name *',
                            hintText: 'Enter name',
                            prefixIcon: Icons.person_rounded,
                            validator: (v) => v == null || v.isEmpty ? 'Client name required' : null,
                          ),
                        ),
                        const SizedBox(width: CRMSpacing.m),
                        Expanded(
                          child: CRMPhoneField(
                            controller: _mobileController,
                            labelText: 'Client Mobile',
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: CRMSpacing.m),

                  // Category & Type Selection
                  if (isMobile) ...[
                    _buildDropdown(
                      label: 'Category *',
                      value: _selectedCategoryId,
                      items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (val) => setState(() {
                        _selectedCategoryId = val;
                        _selectedTypeId = null;
                        _selectedConfigId = null;
                      }),
                    ),
                    const SizedBox(height: CRMSpacing.m),
                    _buildDropdown(
                      label: 'Property Type *',
                      value: _selectedTypeId,
                      items: filteredTypes.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                      onChanged: (val) => setState(() => _selectedTypeId = val),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: 'Category *',
                            value: _selectedCategoryId,
                            items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                            onChanged: (val) => setState(() {
                              _selectedCategoryId = val;
                              _selectedTypeId = null;
                              _selectedConfigId = null;
                            }),
                          ),
                        ),
                        const SizedBox(width: CRMSpacing.m),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Property Type *',
                            value: _selectedTypeId,
                            items: filteredTypes.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                            onChanged: (val) => setState(() => _selectedTypeId = val),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: CRMSpacing.m),

                  // Configuration & Status
                  if (isMobile) ...[
                    if (filteredConfigs.isNotEmpty) ...[
                      _buildDropdown(
                        label: 'Configuration',
                        value: _selectedConfigId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text("None")),
                          ...filteredConfigs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (val) => setState(() => _selectedConfigId = val),
                      ),
                      const SizedBox(height: CRMSpacing.m),
                    ],
                    _buildDropdown(
                      label: 'Status *',
                      value: _selectedStatus,
                      items: ["Live", "Won", "Dead"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _selectedStatus = val ?? "Live"),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        if (filteredConfigs.isNotEmpty) ...[
                          Expanded(
                            child: _buildDropdown(
                              label: 'Configuration',
                              value: _selectedConfigId,
                              items: [
                                const DropdownMenuItem(value: null, child: Text("None")),
                                ...filteredConfigs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                              ],
                              onChanged: (val) => setState(() => _selectedConfigId = val),
                            ),
                          ),
                          const SizedBox(width: CRMSpacing.m),
                        ],
                        Expanded(
                          child: _buildDropdown(
                            label: 'Status *',
                            value: _selectedStatus,
                            items: ["Live", "Won", "Dead"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) => setState(() => _selectedStatus = val ?? "Live"),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: CRMSpacing.m),

                  // Listing Type & Furnishing
                  if (isMobile) ...[
                    _buildDropdown(
                      label: 'Listing Type',
                      value: _selectedListingTypeId,
                      items: (_listingTypes.isNotEmpty ? _listingTypes : [
                        LookupItem(id: 'rent', name: 'Rent'),
                        LookupItem(id: 'resale', name: 'Re-Sale'),
                      ]).map((lt) => DropdownMenuItem(value: lt.id, child: Text(lt.name))).toList(),
                      onChanged: (val) => setState(() => _selectedListingTypeId = val),
                    ),
                    const SizedBox(height: CRMSpacing.m),
                    _buildDropdown(
                      label: 'Furnishing',
                      value: _selectedFurnishing,
                      items: const [
                        DropdownMenuItem(value: 'None', child: Text('None')),
                        DropdownMenuItem(value: 'Unfurnished', child: Text('Unfurnished')),
                        DropdownMenuItem(value: 'Semi-Furnished', child: Text('Semi-Furnished')),
                        DropdownMenuItem(value: 'Fully Furnished', child: Text('Fully Furnished')),
                      ],
                      onChanged: (val) => setState(() => _selectedFurnishing = val),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: 'Listing Type',
                            value: _selectedListingTypeId,
                            items: (_listingTypes.isNotEmpty ? _listingTypes : [
                              LookupItem(id: 'rent', name: 'Rent'),
                              LookupItem(id: 'resale', name: 'Re-Sale'),
                            ]).map((lt) => DropdownMenuItem(value: lt.id, child: Text(lt.name))).toList(),
                            onChanged: (val) => setState(() => _selectedListingTypeId = val),
                          ),
                        ),
                        const SizedBox(width: CRMSpacing.m),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Furnishing',
                            value: _selectedFurnishing,
                            items: const [
                              DropdownMenuItem(value: 'None', child: Text('None')),
                              DropdownMenuItem(value: 'Unfurnished', child: Text('Unfurnished')),
                              DropdownMenuItem(value: 'Semi-Furnished', child: Text('Semi-Furnished')),
                              DropdownMenuItem(value: 'Fully Furnished', child: Text('Fully Furnished')),
                            ],
                            onChanged: (val) => setState(() => _selectedFurnishing = val),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: CRMSpacing.m),

                  CRMCurrencyField(
                    controller: _budgetController,
                    labelText: 'Target Budget',
                    isRequired: true,
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Target Area list chips selection
                  Row(
                    children: [
                      Text("Select Target Area(s) *", style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondary)),
                      const SizedBox(width: CRMSpacing.xs),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primary, size: 20),
                        onPressed: _showAddAreaDialog,
                        tooltip: 'Add New Area',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: CRMSpacing.xs),
                  Wrap(
                    spacing: CRMSpacing.xs,
                    runSpacing: CRMSpacing.xxs,
                    children: _areas.map((a) {
                      final isSelected = _selectedAreaIds.contains(a.id);
                      return FilterChip(
                        label: Text(a.name, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        selectedColor: CRMColors.primary.withOpacity(0.12),
                        checkmarkColor: CRMColors.primary,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedAreaIds.add(a.id);
                            } else {
                              _selectedAreaIds.remove(a.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Remarks Input
                  CRMTextField(
                    controller: _remarksController,
                    labelText: 'Internal CRM Remarks',
                    hintText: 'Add additional requirements here...',
                    prefixIcon: Icons.chat_bubble_outline_rounded,
                    maxLength: 150,
                  ),
                  const SizedBox(height: CRMSpacing.xl),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CRMButton(
                        label: 'Cancel',
                        variant: CRMButtonVariant.outline,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: CRMSpacing.s),
                      CRMButton(
                        label: isEditing ? 'Save Changes' : 'Publish Requirement',
                        onPressed: _submitForm,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondary)),
        const SizedBox(height: CRMSpacing.xs),
        DropdownButtonFormField<T>(
          value: value,
          dropdownColor: CRMColors.cardBg,
          style: CRMTypography.body.copyWith(color: CRMColors.text),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.s),
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
      ],
    );
  }
}
