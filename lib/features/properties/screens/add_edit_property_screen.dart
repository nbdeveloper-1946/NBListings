import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/properties_bloc.dart';
import '../models/property_model.dart';

class AddEditPropertyScreen extends StatefulWidget {
  final PropertyMetadataModel metadata;
  final PropertyModel? property; // If null, we are adding new
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

  // Form Field Controllers
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

  // Selected Option States
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

  // Selected Amenities List
  final List<String> _selectedAmenities = [];

  List<AreaLookup> _filteredAreas = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Populate dropdown options
    if (widget.metadata.categories.isNotEmpty) _selectedCategory = widget.metadata.categories.first.id;
    if (widget.metadata.types.isNotEmpty) _selectedType = widget.metadata.types.first.id;
    if (widget.metadata.listingTypes.isNotEmpty) _selectedListingType = widget.metadata.listingTypes.first.id;
    if (widget.metadata.statuses.isNotEmpty) _selectedStatus = widget.metadata.statuses.first.id;
    if (widget.metadata.cities.isNotEmpty) {
      _selectedCity = widget.metadata.cities.first.id;
      _updateAreasForCity(_selectedCity!);
    }

    // Load edit values if editing
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

      // Match amenities from names back to IDs if possible
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
      'price': double.parse(_priceController.text),
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
      'images': widget.property?.images ?? [], // Preserve existing images
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Property Details' : 'Add New Property'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildMainFormLeft()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildMainFormRight()),
                      ],
                    )
                  else ...[
                    _buildMainFormLeft(),
                    const SizedBox(height: 24),
                    _buildMainFormRight(),
                  ],
                  const SizedBox(height: 32),

                  // Bottom Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(isEdit ? 'Save Changes' : 'Publish Property'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainFormLeft() {
    return Column(
      children: [
        // Section: Basic Info
        _buildSectionCard(
          title: 'Basic Information',
          icon: Icons.info_outline,
          children: [
            _buildTextField(
              controller: _titleController,
              label: 'Title / Scheme Name *',
              validator: (v) => v!.isEmpty ? 'Scheme name is required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField<String>(
                    label: 'Category *',
                    value: _selectedCategory,
                    items: widget.metadata.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdownField<String>(
                    label: 'Listing Type *',
                    value: _selectedListingType,
                    items: widget.metadata.listingTypes.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                    onChanged: (v) => setState(() => _selectedListingType = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField<String>(
                    label: 'Property Type *',
                    value: _selectedType,
                    items: widget.metadata.types.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                    onChanged: (v) => setState(() => _selectedType = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdownField<String>(
                    label: 'Configuration',
                    value: _selectedConfig,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...widget.metadata.configurations.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v) => setState(() => _selectedConfig = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDropdownField<String>(
              label: 'Property Status *',
              value: _selectedStatus,
              items: widget.metadata.statuses.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              onChanged: (v) => setState(() => _selectedStatus = v),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Section: Location details
        _buildSectionCard(
          title: 'Location & Address',
          icon: Icons.location_on_outlined,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField<String>(
                    label: 'City *',
                    value: _selectedCity,
                    items: widget.metadata.cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (v) {
                      setState(() => _selectedCity = v);
                      if (v != null) _updateAreasForCity(v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdownField<String>(
                    label: 'Area *',
                    value: _selectedArea,
                    items: _filteredAreas.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                    onChanged: (v) => setState(() => _selectedArea = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _landmarkController,
              label: 'Landmark',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: 'Complete Address *',
              maxLines: 3,
              validator: (v) => v!.isEmpty ? 'Address is required' : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainFormRight() {
    return Column(
      children: [
        // Section: Pricing & Size details
        _buildSectionCard(
          title: 'Pricing & Sizing',
          icon: Icons.payments_outlined,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _priceController,
                    label: 'Rent/Sell Price *',
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Price is required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _depositController,
                    label: 'Deposit',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _maintenanceController,
              label: 'Monthly Maintenance',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _superBuiltupController,
                    label: 'Super Builtup Area (SqFt) *',
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _carpetController,
                    label: 'Carpet Area (SqFt)',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Section: Contacts Info
        _buildSectionCard(
          title: 'Owner & Contact Details',
          icon: Icons.contact_phone_outlined,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _ownerNameController,
                    label: 'Owner Name *',
                    validator: (v) => v!.isEmpty ? 'Owner name is required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _ownerMobileController,
                    label: 'Owner Mobile *',
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Mobile number is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _brokerNameController,
              label: 'Broker Name',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _remarksController,
              label: 'Remarks / Extra details',
              maxLines: 2,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.indigo[600], size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
