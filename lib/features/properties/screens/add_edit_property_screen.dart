import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../bloc/properties_bloc.dart';
import '../models/property_model.dart';

class AddEditPropertyScreen extends StatefulWidget {
  final PropertyMetadataModel metadata;
  final PropertyModel? property;
  final String activeTab;

  const AddEditPropertyScreen({
    super.key,
    required this.metadata,
    this.property,
    required this.activeTab,
  });

  @override
  State<AddEditPropertyScreen> createState() => _AddEditPropertyScreenState();
}

class _AddEditPropertyScreenState extends State<AddEditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _superBuiltupController = TextEditingController();
  final _carpetController = TextEditingController();
  final _plotController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
  final _maintenanceController = TextEditingController();
  final _bedroomsController = TextEditingController(text: '0');
  final _bathroomsController = TextEditingController(text: '0');
  final _balconiesController = TextEditingController(text: '0');
  final _parkingController = TextEditingController(text: '0');
  final _floorNoController = TextEditingController();
  final _totalFloorController = TextEditingController();
  final _ageController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerMobileController = TextEditingController();
  final _brokerNameController = TextEditingController();
  final _remarksController = TextEditingController();

  String? _selectedCategory;
  String? _selectedType;
  String? _selectedConfig;
  String? _selectedListingType;
  String? _selectedStatus;
  String? _selectedCity;
  String? _selectedArea;
  String? _selectedFurnishing;
  String? _selectedFacing;
  String? _selectedOwnership;

  final List<String> _selectedAmenities = [];
  List<AreaLookup> _filteredAreas = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _superBuiltupController.dispose();
    _carpetController.dispose();
    _plotController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _maintenanceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _balconiesController.dispose();
    _parkingController.dispose();
    _floorNoController.dispose();
    _totalFloorController.dispose();
    _ageController.dispose();
    _ownerNameController.dispose();
    _ownerMobileController.dispose();
    _brokerNameController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.metadata.categories.isNotEmpty) _selectedCategory = widget.metadata.categories.first.id;
    if (widget.metadata.types.isNotEmpty) _selectedType = widget.metadata.types.first.id;
    if (widget.metadata.listingTypes.isNotEmpty) _selectedListingType = widget.metadata.listingTypes.first.id;
    if (widget.metadata.statuses.isNotEmpty) _selectedStatus = widget.metadata.statuses.first.id;
    if (widget.metadata.cities.isNotEmpty) {
      _selectedCity = widget.metadata.cities.first.id;
      _updateAreasForCity(_selectedCity!);
    }

    final p = widget.property;
    if (p != null) {
      _titleController.text = p.title;
      _descriptionController.text = p.description ?? '';
      _selectedCategory = p.categoryId;
      _selectedType = p.propertyTypeId;
      _selectedConfig = p.configurationId;
      _selectedListingType = p.listingTypeId;
      _selectedStatus = p.propertyStatusId;
      _selectedCity = p.cityId;
      _updateAreasForCity(p.cityId);
      _selectedArea = p.areaId;
      _addressController.text = p.address;
      _landmarkController.text = p.landmark ?? '';
      _superBuiltupController.text = p.superBuiltupArea?.toStringAsFixed(0) ?? '';
      _carpetController.text = p.carpetArea?.toStringAsFixed(0) ?? '';
      _plotController.text = p.plotArea?.toStringAsFixed(0) ?? '';
      _priceController.text = p.price.toStringAsFixed(0);
      _depositController.text = p.deposit.toStringAsFixed(0);
      _maintenanceController.text = p.maintenance.toStringAsFixed(0);
      _selectedFurnishing = p.furnishingTypeId;
      _selectedFacing = p.facingTypeId;
      _selectedOwnership = p.ownershipTypeId;
      _bedroomsController.text = p.bedrooms.toString();
      _bathroomsController.text = p.bathrooms.toString();
      _balconiesController.text = p.balconies.toString();
      _parkingController.text = p.parking.toString();
      _floorNoController.text = p.floorNo?.toString() ?? '';
      _totalFloorController.text = p.totalFloor?.toString() ?? '';
      _ageController.text = p.ageOfProperty?.toString() ?? '';
      _ownerNameController.text = p.ownerName;
      _ownerMobileController.text = p.ownerMobile;
      _brokerNameController.text = p.brokerName ?? '';
      _remarksController.text = p.remarks ?? '';

      for (final amName in p.amenities) {
        final matched = widget.metadata.amenities.firstWhere(
          (a) => a.name.toLowerCase() == amName.toLowerCase(),
          orElse: () => LookupItem(id: '', name: ''),
        );
        if (matched.id.isNotEmpty) {
          _selectedAmenities.add(matched.id);
        }
      }
    }
  }

  void _updateAreasForCity(String cityId) {
    setState(() {
      _filteredAreas = widget.metadata.areas.where((a) => a.cityId == cityId).toList();
      if (_filteredAreas.isNotEmpty) {
        _selectedArea = _filteredAreas.first.id;
      } else {
        _selectedArea = null;
      }
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final propertyData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      'category_id': _selectedCategory,
      'property_type_id': _selectedType,
      'configuration_id': _selectedConfig,
      'listing_type_id': _selectedListingType,
      'property_status_id': _selectedStatus,
      'city_id': _selectedCity,
      'area_id': _selectedArea,
      'address': _addressController.text.trim(),
      'landmark': _landmarkController.text.trim().isEmpty ? null : _landmarkController.text.trim(),
      'super_builtup_area': double.tryParse(_superBuiltupController.text),
      'carpet_area': double.tryParse(_carpetController.text),
      'plot_area': double.tryParse(_plotController.text),
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'deposit': double.tryParse(_depositController.text) ?? 0.0,
      'maintenance': double.tryParse(_maintenanceController.text) ?? 0.0,
      'furnishing_type_id': _selectedFurnishing,
      'facing_type_id': _selectedFacing,
      'ownership_type_id': _selectedOwnership,
      'bedrooms': int.tryParse(_bedroomsController.text) ?? 0,
      'bathrooms': int.tryParse(_bathroomsController.text) ?? 0,
      'balconies': int.tryParse(_balconiesController.text) ?? 0,
      'parking': int.tryParse(_parkingController.text) ?? 0,
      'floor_no': int.tryParse(_floorNoController.text),
      'total_floor': int.tryParse(_totalFloorController.text),
      'age_of_property': int.tryParse(_ageController.text),
      'owner_name': _ownerNameController.text.trim(),
      'owner_mobile': _ownerMobileController.text.trim(),
      'broker_name': _brokerNameController.text.trim().isEmpty ? null : _brokerNameController.text.trim(),
      'remarks': _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      'amenities': _selectedAmenities,
      'images': widget.property?.images ?? [],
    };

    if (widget.property == null) {
      context.read<PropertiesBloc>().add(
            CreatePropertyEvent(propertyData, activeTab: widget.activeTab),
          );
    } else {
      context.read<PropertiesBloc>().add(
            UpdatePropertyEvent(widget.property!.id, propertyData, activeTab: widget.activeTab),
          );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.property != null;

    return Scaffold(
      backgroundColor: CRMColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit CRM Listing' : 'Publish New Property', style: CRMTypography.sectionTitle),
        backgroundColor: CRMColors.cardBg,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildWizardProgress(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(CRMSpacing.l),
                child: _buildActiveStepContent(),
              ),
            ),
            _buildWizardActions(isEdit),
          ],
        ),
      ),
    );
  }

  Widget _buildWizardProgress() {
    return Container(
      color: CRMColors.cardBg,
      padding: const EdgeInsets.symmetric(vertical: CRMSpacing.m, horizontal: CRMSpacing.l),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStepNode(0, 'Basic Info'),
          _buildStepDivider(),
          _buildStepNode(1, 'Location'),
          _buildStepDivider(),
          _buildStepNode(2, 'Pricing'),
          _buildStepDivider(),
          _buildStepNode(3, 'Contacts'),
        ],
      ),
    );
  }

  Widget _buildStepNode(int index, String label) {
    final isActive = _currentStep == index;
    final isPassed = _currentStep > index;

    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isPassed
              ? CRMColors.success
              : (isActive ? CRMColors.primary : CRMColors.border),
          child: isPassed
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('${index + 1}', style: TextStyle(color: isActive ? Colors.white : CRMColors.textSecondary, fontSize: 12)),
        ),
        const SizedBox(width: CRMSpacing.xs),
        Text(
          label,
          style: CRMTypography.captionBold.copyWith(
            color: isActive ? CRMColors.primary : CRMColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return const Expanded(
      child: Divider(color: CRMColors.border, thickness: 1.5, indent: 8, endIndent: 8),
    );
  }

  Widget _buildActiveStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBasicStep();
      case 1:
        return _buildLocationStep();
      case 2:
        return _buildPricingStep();
      case 3:
        return _buildContactsStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicStep() {
    return CRMCard(
      title: 'Basic Property Setup',
      subtitle: 'Complete listing definitions and categories',
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            style: CRMTypography.body.copyWith(color: CRMColors.text),
            decoration: InputDecoration(
              labelText: 'Title / Scheme Name *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
            validator: (v) => v!.isEmpty ? 'Scheme name is required' : null,
          ),
          const SizedBox(height: CRMSpacing.m),
          TextFormField(
            controller: _descriptionController,
            style: CRMTypography.body.copyWith(color: CRMColors.text),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
          ),
          const SizedBox(height: CRMSpacing.m),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                  items: widget.metadata.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedListingType,
                  decoration: InputDecoration(
                    labelText: 'Listing Type *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                  items: widget.metadata.listingTypes.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                  onChanged: (v) => setState(() => _selectedListingType = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Property Type *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                  items: widget.metadata.types.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                  onChanged: (v) => setState(() => _selectedType = v),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedConfig,
                  decoration: InputDecoration(
                    labelText: 'Configuration',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...widget.metadata.configurations.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (v) => setState(() => _selectedConfig = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Property Status *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
            items: widget.metadata.statuses.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
            onChanged: (v) => setState(() => _selectedStatus = v),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return CRMCard(
      title: 'Location Mapping',
      subtitle: 'Specify geo-coordinates and landmark directions',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: InputDecoration(
                    labelText: 'City *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                  items: widget.metadata.cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) {
                    setState(() => _selectedCity = v);
                    if (v != null) _updateAreasForCity(v);
                  },
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedArea,
                  decoration: InputDecoration(
                    labelText: 'Area *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                  items: _filteredAreas.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                  onChanged: (v) => setState(() => _selectedArea = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          TextFormField(
            controller: _landmarkController,
            style: CRMTypography.body.copyWith(color: CRMColors.text),
            decoration: InputDecoration(
              labelText: 'Landmark',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
          ),
          const SizedBox(height: CRMSpacing.m),
          TextFormField(
            controller: _addressController,
            style: CRMTypography.body.copyWith(color: CRMColors.text),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Complete Address *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
            validator: (v) => v!.isEmpty ? 'Address is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingStep() {
    return CRMCard(
      title: 'Pricing & Sizing Sockets',
      subtitle: 'Complete budget calculations and builtup area parameters',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  style: CRMTypography.body.copyWith(color: CRMColors.text),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Rent/Sell Price *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                  validator: (v) => v!.isEmpty ? 'Price is required' : null,
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              Expanded(
                child: TextFormField(
                  controller: _depositController,
                  style: CRMTypography.body.copyWith(color: CRMColors.text),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Deposit Amount',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          TextFormField(
            controller: _maintenanceController,
            style: CRMTypography.body.copyWith(color: CRMColors.text),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Monthly Maintenance Charge',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
          ),
          const SizedBox(height: CRMSpacing.m),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _superBuiltupController,
                  style: CRMTypography.body.copyWith(color: CRMColors.text),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Super Builtup Area *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                  validator: (v) => v!.isEmpty ? 'Area required' : null,
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              Expanded(
                child: TextFormField(
                  controller: _carpetController,
                  style: CRMTypography.body.copyWith(color: CRMColors.text),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Carpet Area Size',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          TextFormField(
            controller: _plotController,
            style: CRMTypography.body.copyWith(color: CRMColors.text),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Plot Area Size',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
          ),
          const SizedBox(height: CRMSpacing.l),
          Text('Room & Floor Details', style: CRMTypography.captionBold.copyWith(color: CRMColors.text)),
          const SizedBox(height: CRMSpacing.s),
          Row(
            children: [
              Expanded(child: _buildNumberField(_bedroomsController, 'Bedrooms')),
              const SizedBox(width: CRMSpacing.s),
              Expanded(child: _buildNumberField(_bathroomsController, 'Bathrooms')),
              const SizedBox(width: CRMSpacing.s),
              Expanded(child: _buildNumberField(_balconiesController, 'Balconies')),
              const SizedBox(width: CRMSpacing.s),
              Expanded(child: _buildNumberField(_parkingController, 'Parking')),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _floorNoController,
                  style: CRMTypography.body.copyWith(color: CRMColors.text),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Floor No.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              Expanded(
                child: TextFormField(
                  controller: _totalFloorController,
                  style: CRMTypography.body.copyWith(color: CRMColors.text),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Total Floors',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              Expanded(
                child: TextFormField(
                  controller: _ageController,
                  style: CRMTypography.body.copyWith(color: CRMColors.text),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Age (years)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.l),
          Text('Property Attributes', style: CRMTypography.captionBold.copyWith(color: CRMColors.text)),
          const SizedBox(height: CRMSpacing.s),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFurnishing,
                  decoration: InputDecoration(
                    labelText: 'Furnishing',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...widget.metadata.furnishings.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))),
                  ],
                  onChanged: (v) => setState(() => _selectedFurnishing = v),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFacing,
                  decoration: InputDecoration(
                    labelText: 'Facing',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...widget.metadata.facings.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))),
                  ],
                  onChanged: (v) => setState(() => _selectedFacing = v),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedOwnership,
                  decoration: InputDecoration(
                    labelText: 'Ownership',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...widget.metadata.ownerships.map((o) => DropdownMenuItem(value: o.id, child: Text(o.name))),
                  ],
                  onChanged: (v) => setState(() => _selectedOwnership = v),
                ),
              ),
            ],
          ),
          if (widget.metadata.amenities.isNotEmpty) ...[
            const SizedBox(height: CRMSpacing.l),
            Text('Amenities', style: CRMTypography.captionBold.copyWith(color: CRMColors.text)),
            const SizedBox(height: CRMSpacing.s),
            Wrap(
              spacing: CRMSpacing.s,
              runSpacing: CRMSpacing.xs,
              children: widget.metadata.amenities.map((amenity) {
                final isSelected = _selectedAmenities.contains(amenity.id);
                return FilterChip(
                  label: Text(amenity.name),
                  selected: isSelected,
                  selectedColor: CRMColors.primary.withOpacity(0.12),
                  checkmarkColor: CRMColors.primary,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAmenities.add(amenity.id);
                      } else {
                        _selectedAmenities.remove(amenity.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      style: CRMTypography.body.copyWith(color: CRMColors.text),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
    );
  }

  Widget _buildContactsStep() {
    return CRMCard(
      title: 'Contacts Info & Visibility',
      subtitle: 'Verify owner profiles and direct remarks',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ownerNameController,
                  style: CRMTypography.body.copyWith(color: CRMColors.text),
                  decoration: InputDecoration(
                    labelText: 'Owner Name *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                  validator: (v) => v!.isEmpty ? 'Owner name required' : null,
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              Expanded(
                child: TextFormField(
                  controller: _ownerMobileController,
                  style: CRMTypography.body.copyWith(color: CRMColors.text),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Owner Mobile *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                  validator: (v) => v!.isEmpty ? 'Mobile required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          TextFormField(
            controller: _brokerNameController,
            style: CRMTypography.body.copyWith(color: CRMColors.text),
            decoration: InputDecoration(
              labelText: 'Broker Referrer Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
          ),
          const SizedBox(height: CRMSpacing.m),
          TextFormField(
            controller: _remarksController,
            style: CRMTypography.body.copyWith(color: CRMColors.text),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Operational CRM internal remarks',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWizardActions(bool isEdit) {
    return Container(
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: const BoxDecoration(
        color: CRMColors.cardBg,
        border: Border(top: BorderSide(color: CRMColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CRMButton(
            label: 'Cancel',
            variant: CRMButtonVariant.outline,
            onPressed: () => Navigator.pop(context),
          ),
          Row(
            children: [
              if (_currentStep > 0) ...[
                CRMButton(
                  label: 'Back',
                  variant: CRMButtonVariant.secondary,
                  onPressed: () => setState(() => _currentStep--),
                ),
                const SizedBox(width: CRMSpacing.s),
              ],
              if (_currentStep < 3)
                CRMButton(
                  label: 'Next Step',
                  variant: CRMButtonVariant.primary,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _currentStep++);
                    }
                  },
                )
              else
                CRMButton(
                  label: isEdit ? 'Save Changes' : 'Publish Property',
                  variant: CRMButtonVariant.primary,
                  onPressed: _submitForm,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
