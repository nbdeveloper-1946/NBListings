import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/requirements_bloc.dart';
import '../models/requirement_model.dart';
import '../../properties/repository/properties_repository.dart';
import '../../properties/models/property_model.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/inputs.dart';

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
  final _minBudgetController = TextEditingController();
  final _maxBudgetController = TextEditingController();
  final _minAreaController = TextEditingController();
  final _maxAreaController = TextEditingController();
  final _remarksController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedTypeId;
  String? _selectedConfigId;
  String _selectedStatus = "Active";
  final List<String> _selectedAreaIds = [];

  bool _isLoadingMetadata = true;
  List<LookupItem> _categories = [];
  List<LookupItem> _types = [];
  List<LookupItem> _configurations = [];
  List<AreaLookup> _areas = [];

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _minAreaController.dispose();
    _maxAreaController.dispose();
    _remarksController.dispose();
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
        
        if (widget.requirement == null) {
          if (_categories.isNotEmpty) _selectedCategoryId = _categories.first.id;
          if (_types.isNotEmpty) _selectedTypeId = _types.first.id;
        } else {
          final req = widget.requirement!;
          _nameController.text = req.clientName;
          _mobileController.text = req.clientMobile;
          _minBudgetController.text = req.minBudget.toStringAsFixed(0);
          _maxBudgetController.text = req.maxBudget.toStringAsFixed(0);
          _minAreaController.text = req.minArea?.toStringAsFixed(0) ?? '';
          _maxAreaController.text = req.maxArea?.toStringAsFixed(0) ?? '';
          _remarksController.text = req.remarks ?? '';
          _selectedCategoryId = req.categoryId;
          _selectedTypeId = req.propertyTypeId;
          _selectedConfigId = req.configurationId;
          _selectedStatus = req.status;
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

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
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
      minBudget: double.tryParse(_minBudgetController.text) ?? 0.0,
      maxBudget: double.tryParse(_maxBudgetController.text) ?? 0.0,
      minArea: double.tryParse(_minAreaController.text),
      maxArea: double.tryParse(_maxAreaController.text),
      areaIds: _selectedAreaIds,
      areaNames: areaNames,
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      status: _selectedStatus,
      createdAt: widget.requirement?.createdAt ?? DateTime.now(),
    );

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

    return Dialog(
      backgroundColor: CRMColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(CRMSpacing.l),
          child: Form(
            key: _formKey,
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
                        child: CRMTextField(
                          controller: _mobileController,
                          labelText: 'Mobile Phone *',
                          hintText: '+91 XXXXX XXXXX',
                          prefixIcon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.isEmpty ? 'Mobile number required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Category & Type Selection
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'Category *',
                          value: _selectedCategoryId,
                          items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                          onChanged: (val) => setState(() => _selectedCategoryId = val),
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.m),
                      Expanded(
                        child: _buildDropdown(
                          label: 'Property Type *',
                          value: _selectedTypeId,
                          items: _types.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                          onChanged: (val) => setState(() => _selectedTypeId = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Configuration & Status
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'Configuration',
                          value: _selectedConfigId,
                          items: [
                            const DropdownMenuItem(value: null, child: Text("None")),
                            ..._configurations.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (val) => setState(() => _selectedConfigId = val),
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.m),
                      Expanded(
                        child: _buildDropdown(
                          label: 'Status *',
                          value: _selectedStatus,
                          items: ["Active", "Closed", "Suspended"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => setState(() => _selectedStatus = val ?? "Active"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Budget range
                  Row(
                    children: [
                      Expanded(
                        child: CRMTextField(
                          controller: _minBudgetController,
                          labelText: 'Min Budget (₹) *',
                          hintText: 'e.g. 5000000',
                          prefixIcon: Icons.currency_rupee_rounded,
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'Min budget required' : null,
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.m),
                      Expanded(
                        child: CRMTextField(
                          controller: _maxBudgetController,
                          labelText: 'Max Budget (₹) *',
                          hintText: 'e.g. 8000000',
                          prefixIcon: Icons.currency_rupee_rounded,
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'Max budget required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Target Area list chips selection
                  Text("Select Target Area(s) *", style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondary)),
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
