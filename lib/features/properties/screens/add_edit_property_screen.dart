import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/api/dio_client.dart';
import '../bloc/properties_bloc.dart';
import '../models/property_model.dart';
import '../services/properties_service.dart';
import '../repository/properties_repository.dart';
import '../../../core/utils/budget_formatter.dart';

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
  final _blockWingController = TextEditingController();
  final _flatNoController = TextEditingController();
  TextEditingController _facingController = TextEditingController();
  
  final List<String> _propertyImages = [];
  bool _isUploadingImage = false;

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
  List<LookupItem> _cities = [];
  List<AreaLookup> _areas = [];
  List<LookupItem> _localAmenities = [];

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
    _blockWingController.dispose();
    _flatNoController.dispose();
    _facingController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    _cities = List.from(widget.metadata.cities);
    _areas = List.from(widget.metadata.areas);
    _localAmenities = List.from(widget.metadata.amenities);

    if (widget.metadata.categories.isNotEmpty) _selectedCategory = widget.metadata.categories.first.id;
    if (widget.metadata.types.isNotEmpty) _selectedType = widget.metadata.types.first.id;
    if (widget.metadata.listingTypes.isNotEmpty) _selectedListingType = widget.metadata.listingTypes.first.id;
    if (widget.metadata.statuses.isNotEmpty) _selectedStatus = widget.metadata.statuses.first.id;
    if (_cities.isNotEmpty) {
      _selectedCity = _cities.first.id;
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
      _priceController.text = BudgetFormatter.format(p.price);
      _depositController.text = p.deposit.toStringAsFixed(0);
      _maintenanceController.text = p.maintenance.toStringAsFixed(0);
      _selectedFurnishing = p.furnishingTypeId;
      _selectedFacing = p.facingTypeId;
      if (p.facingTypeId != null) {
        final match = widget.metadata.facings.firstWhere(
          (f) => f.id == p.facingTypeId,
          orElse: () => LookupItem(id: '', name: ''),
        );
        if (match.id.isNotEmpty) {
          _facingController.text = match.name;
        }
      }
      _selectedOwnership = p.ownershipTypeId;
      _blockWingController.text = p.blockWing ?? '';
      _flatNoController.text = p.flatNo ?? '';
      _propertyImages.addAll(p.images);
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


  void _showAddCityDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New City'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'City Name'),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Add'),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                try {
                  final service = PropertiesService();
                  final result = await service.createCity(name);
                  final LookupItem newCity = LookupItem(
                    id: result['data']['city']['id'],
                    name: result['data']['city']['city_name'],
                  );
                  setState(() {
                    _cities.add(newCity);
                    _selectedCity = newCity.id;
                  });
                  _updateAreasForCity(newCity.id);
                  if (mounted) Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add city: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddAreaDialog() {
    final nameController = TextEditingController();
    final pincodeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Area'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Area Name'),
            ),
            TextField(
              controller: pincodeController,
              decoration: const InputDecoration(labelText: 'Pincode'),
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
              if (name.isNotEmpty && pincode.isNotEmpty && _selectedCity != null) {
                try {
                  final service = PropertiesService();
                  final result = await service.createArea(_selectedCity!, name, pincode);
                  final AreaLookup newArea = AreaLookup(
                    id: result['data']['area']['id'],
                    name: result['data']['area']['area_name'],
                    cityId: result['data']['area']['city_id'],
                    pincode: result['data']['area']['pincode'],
                  );
                  setState(() {
                    _areas.add(newArea);
                    _filteredAreas.add(newArea);
                    _selectedArea = newArea.id;
                  });
                  if (mounted) Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add area: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _updateAreasForCity(String cityId) {
    setState(() {
      _filteredAreas = _areas.where((a) => a.cityId == cityId).toList();
      if (_filteredAreas.isNotEmpty) {
        _selectedArea = _filteredAreas.first.id;
      } else {
        _selectedArea = null;
      }
    });
  }

  List<LookupItem> _getFilteredTypes() {
    if (_selectedCategory == null) return [];
    return widget.metadata.types.where((t) => t.categoryId == _selectedCategory).toList();
  }

  List<LookupItem> _getFilteredConfigs() {
    if (_selectedCategory == null) return [];
    return widget.metadata.configurations.where((c) => c.categoryId == _selectedCategory).toList();
  }

  Future<void> _showImageSourceDialog(int index) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take Photo (Camera)'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(index, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(index, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(int index, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final File file = File(pickedFile.path);
      final int sizeInBytes = await file.length();
      
      File uploadFile = file;

      if (sizeInBytes > 0) {
        final String targetPath = "${Directory.systemTemp.path}/compressed_prop_${DateTime.now().millisecondsSinceEpoch}.jpg";
        
        XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 80,
          minWidth: 1200,
          minHeight: 1200,
        );

        if (compressedFile != null) {
          uploadFile = File(compressedFile.path);
          int compressedSize = await uploadFile.length();

          if (compressedSize > 5 * 1024 * 1024) {
            throw Exception("Compressed image exceeds 5 MB limit.");
          }
        }
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(uploadFile.path, filename: 'property_image.jpg'),
      });

      final response = await DioClient.dio.post('/properties/upload-media', data: formData);
      final publicUrl = response.data['data']['url'];

      setState(() {
        if (index < _propertyImages.length) {
          _propertyImages[index] = publicUrl;
        } else {
          _propertyImages.add(publicUrl);
        }
        _isUploadingImage = false;
      });
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e"), backgroundColor: CRMColors.danger),
      );
    }
  }

  void _showAddMasterDialog(String masterType) {
    final controller = TextEditingController();
    final String friendlyTitle = masterType == 'property-type' ? 'Property Type' :
                                 masterType == 'listing-type' ? 'Listing Type' :
                                 masterType[0].toUpperCase() + masterType.substring(1);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add New $friendlyTitle'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '$friendlyTitle Name *',
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Add'),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                try {
                  final payload = {'name': name};
                  
                  if (masterType == 'property-type' || masterType == 'configuration') {
                    if (_selectedCategory == null) {
                      throw Exception("Please select a Category first.");
                    }
                    payload['category_id'] = _selectedCategory!;
                  }
                  
                  final repository = PropertiesRepository();
                  final response = await repository.createLookup(masterType, payload);
                  
                  setState(() {
                    if (masterType == 'category') {
                      widget.metadata.categories.add(response);
                      _selectedCategory = response.id;
                      _selectedType = null;
                      _selectedConfig = null;
                    } else if (masterType == 'property-type') {
                      widget.metadata.types.add(response);
                      _selectedType = response.id;
                    } else if (masterType == 'configuration') {
                      widget.metadata.configurations.add(response);
                      _selectedConfig = response.id;
                    } else if (masterType == 'listing-type') {
                      widget.metadata.listingTypes.add(response);
                      _selectedListingType = response.id;
                    }
                  });
                  
                  if (mounted) Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll("Exception: ", "")),
                      backgroundColor: CRMColors.danger,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final String typedFacing = _facingController.text.trim();
      if (typedFacing.isNotEmpty) {
        final match = widget.metadata.facings.firstWhere(
          (f) => f.name.trim().toLowerCase() == typedFacing.toLowerCase(),
          orElse: () => LookupItem(id: '', name: ''),
        );
        if (match.id.isNotEmpty) {
          _selectedFacing = match.id;
        } else {
          final repository = PropertiesRepository();
          final newFacing = await repository.createLookup("facing", {"name": typedFacing});
          widget.metadata.facings.add(newFacing);
          _selectedFacing = newFacing.id;
        }
      } else {
        _selectedFacing = null;
      }

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
        'block_wing': _blockWingController.text.trim().isEmpty ? null : _blockWingController.text.trim(),
        'flat_no': _flatNoController.text.trim().isEmpty ? null : _flatNoController.text.trim(),
        'super_builtup_area': double.tryParse(_superBuiltupController.text),
        'carpet_area': double.tryParse(_carpetController.text),
        'plot_area': double.tryParse(_plotController.text),
        'price': BudgetFormatter.parse(_priceController.text),
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
        'images': _propertyImages,
      };

      if (mounted) {
        Navigator.pop(context); // pop loading spinner
      }

      if (widget.property == null) {
        context.read<PropertiesBloc>().add(
              CreatePropertyEvent(propertyData, activeTab: widget.activeTab),
            );
      } else {
        context.read<PropertiesBloc>().add(
              UpdatePropertyEvent(widget.property!.id, propertyData, activeTab: widget.activeTab),
            );
      }

      if (mounted) {
        Navigator.pop(context); // close form screen
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // pop loading spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to publish property: $e"), backgroundColor: CRMColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.property != null;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit CRM Listing' : 'Add New Property', style: CRMTypography.sectionTitle),
        backgroundColor: CRMColors.cardBg,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildWizardProgress(isMobile),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(CRMSpacing.l),
                child: _buildActiveStepContent(isMobile),
              ),
            ),
            _buildWizardActions(isEdit),
          ],
        ),
      ),
    );
  }

  Widget _buildWizardProgress(bool isMobile) {
    return Container(
      color: CRMColors.cardBg,
      padding: EdgeInsets.symmetric(
        vertical: CRMSpacing.m,
        horizontal: isMobile ? CRMSpacing.m : CRMSpacing.l,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStepNode(0, 'Basic Info', isMobile),
          _buildStepDivider(),
          _buildStepNode(1, 'Location', isMobile),
          _buildStepDivider(),
          _buildStepNode(2, 'Pricing', isMobile),
          _buildStepDivider(),
          _buildStepNode(3, 'Contacts', isMobile),
        ],
      ),
    );
  }

  Widget _buildStepNode(int index, String label, bool isMobile) {
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
        if (!isMobile) ...[
          const SizedBox(width: CRMSpacing.xs),
          Text(
            label,
            style: CRMTypography.captionBold.copyWith(
              color: isActive ? CRMColors.primary : CRMColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepDivider() {
    return Expanded(
      child: Divider(color: CRMColors.border, thickness: 1.5, indent: 8, endIndent: 8),
    );
  }

  Widget _buildActiveStepContent(bool isMobile) {
    switch (_currentStep) {
      case 0:
        return _buildBasicStep(isMobile);
      case 1:
        return _buildLocationStep(isMobile);
      case 2:
        return _buildPricingStep(isMobile);
      case 3:
        return _buildContactsStep(isMobile);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicStep(bool isMobile) {
    final filteredTypes = _getFilteredTypes();
    if (_selectedType != null && !filteredTypes.any((t) => t.id == _selectedType)) {
      _selectedType = filteredTypes.isNotEmpty ? filteredTypes.first.id : null;
    }
    final filteredConfigs = _getFilteredConfigs();
    if (_selectedConfig != null && !filteredConfigs.any((c) => c.id == _selectedConfig)) {
      _selectedConfig = null;
    }

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

          if (isMobile) ...[
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
                    onChanged: (v) {
                      setState(() {
                        _selectedCategory = v;
                        _selectedType = null;
                        _selectedConfig = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: CRMSpacing.xs),
                IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primary),
                  onPressed: () => _showAddMasterDialog('category'),
                  tooltip: 'Add Category',
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.m),
            Row(
              children: [
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
                const SizedBox(width: CRMSpacing.xs),
                IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primary),
                  onPressed: () => _showAddMasterDialog('listing-type'),
                  tooltip: 'Add Listing Type',
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                          ),
                          items: widget.metadata.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedCategory = v;
                              _selectedType = null;
                              _selectedConfig = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.xs),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primary),
                        onPressed: () => _showAddMasterDialog('category'),
                        tooltip: 'Add Category',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: CRMSpacing.s),
                Expanded(
                  child: Row(
                    children: [
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
                      const SizedBox(width: CRMSpacing.xs),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primary),
                        onPressed: () => _showAddMasterDialog('listing-type'),
                        tooltip: 'Add Listing Type',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: CRMSpacing.m),
          if (isMobile) ...[
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Property Type *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                    ),
                    items: filteredTypes.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                    onChanged: (v) => setState(() => _selectedType = v),
                  ),
                ),
                const SizedBox(width: CRMSpacing.xs),
                IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primary),
                  onPressed: () => _showAddMasterDialog('property-type'),
                  tooltip: 'Add Property Type',
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.m),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedConfig,
                    decoration: InputDecoration(
                      labelText: 'Configuration',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...filteredConfigs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v) => setState(() => _selectedConfig = v),
                  ),
                ),
                const SizedBox(width: CRMSpacing.xs),
                IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primary),
                  onPressed: () => _showAddMasterDialog('configuration'),
                  tooltip: 'Add Configuration',
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: InputDecoration(
                            labelText: 'Property Type *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                          ),
                          items: filteredTypes.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                          onChanged: (v) => setState(() => _selectedType = v),
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.xs),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primary),
                        onPressed: () => _showAddMasterDialog('property-type'),
                        tooltip: 'Add Property Type',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: CRMSpacing.s),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedConfig,
                          decoration: InputDecoration(
                            labelText: 'Configuration',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('None')),
                            ...filteredConfigs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (v) => setState(() => _selectedConfig = v),
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.xs),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primary),
                        onPressed: () => _showAddMasterDialog('configuration'),
                        tooltip: 'Add Configuration',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
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
          const SizedBox(height: CRMSpacing.l),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Property Images (Max 3)', style: CRMTypography.captionBold.copyWith(color: CRMColors.text)),
              if (_isUploadingImage)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: CRMSpacing.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              final hasImage = index < _propertyImages.length;
              final imageUrl = hasImage ? _propertyImages[index] : null;

              return Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: CRMColors.cardBg,
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      border: Border.all(color: CRMColors.border, width: 1.5),
                    ),
                    child: hasImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(CRMBorderRadius.s - 1.5),
                            child: Image.network(
                              imageUrl!,
                              fit: BoxFit.cover,
                              width: 90,
                              height: 90,
                            ),
                          )
                        : Icon(Icons.add_photo_alternate_outlined, color: CRMColors.textSecondary, size: 28),
                  ),
                  const SizedBox(height: CRMSpacing.xs),
                  if (hasImage) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined, size: 16, color: CRMColors.primary),
                          onPressed: () => _showImageSourceDialog(index),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: CRMColors.danger),
                          onPressed: () {
                            setState(() {
                              _propertyImages.removeAt(index);
                            });
                          },
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                      ],
                    )
                  ] else ...[
                    TextButton(
                      onPressed: () => _showImageSourceDialog(index),
                      child: const Text('Add', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep(bool isMobile) {
    final cityField = Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedCity,
            decoration: InputDecoration(
              labelText: 'City *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
            items: _cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) {
              setState(() => _selectedCity = v);
              if (v != null) _updateAreasForCity(v);
            },
          ),
        ),
        IconButton(
          icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primary),
          onPressed: _showAddCityDialog,
          tooltip: 'Add New City',
        ),
      ],
    );

    final areaField = Row(
      children: [
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
        IconButton(
          icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primary),
          onPressed: _selectedCity == null ? null : _showAddAreaDialog,
          tooltip: 'Add New Area',
        ),
      ],
    );

    final blockWingField = TextFormField(
      controller: _blockWingController,
      style: CRMTypography.body.copyWith(color: CRMColors.text),
      decoration: InputDecoration(
        labelText: 'Block / Wing',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
    );

    final flatNoField = TextFormField(
      controller: _flatNoController,
      style: CRMTypography.body.copyWith(color: CRMColors.text),
      decoration: InputDecoration(
        labelText: 'Flat Number',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
    );

    return CRMCard(
      title: 'Location Mapping',
      subtitle: 'Specify geo-coordinates and landmark directions',
      child: Column(
        children: [
          if (isMobile) ...[
            cityField,
            const SizedBox(height: CRMSpacing.m),
            areaField,
          ] else ...[
            Row(
              children: [
                Expanded(child: cityField),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: areaField),
              ],
            ),
          ],
          const SizedBox(height: CRMSpacing.m),
          if (isMobile) ...[
            blockWingField,
            const SizedBox(height: CRMSpacing.m),
            flatNoField,
          ] else ...[
            Row(
              children: [
                Expanded(child: blockWingField),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: flatNoField),
              ],
            ),
          ],
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

  Widget _buildPricingStep(bool isMobile) {
    final priceField = TextFormField(
      controller: _priceController,
      style: CRMTypography.body.copyWith(color: CRMColors.text),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Rent/Sell Price *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
      validator: (v) => v!.isEmpty ? 'Price is required' : null,
    );

    final depositField = TextFormField(
      controller: _depositController,
      style: CRMTypography.body.copyWith(color: CRMColors.text),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Deposit Amount',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
    );

    final superBuiltupField = TextFormField(
      controller: _superBuiltupController,
      style: CRMTypography.body.copyWith(color: CRMColors.text),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Super Builtup Area *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
      validator: (v) => v!.isEmpty ? 'Area required' : null,
    );

    final carpetField = TextFormField(
      controller: _carpetController,
      style: CRMTypography.body.copyWith(color: CRMColors.text),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Carpet Area Size',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
    );

    final bedroomsField = _buildNumberField(_bedroomsController, 'Bedrooms');
    final bathroomsField = _buildNumberField(_bathroomsController, 'Bathrooms');
    final balconiesField = _buildNumberField(_balconiesController, 'Balconies');
    final parkingField = _buildNumberField(_parkingController, 'Parking');

    final floorNoField = TextFormField(
      controller: _floorNoController,
      style: CRMTypography.body.copyWith(color: CRMColors.text),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Floor No.',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
    );

    final totalFloorField = TextFormField(
      controller: _totalFloorController,
      style: CRMTypography.body.copyWith(color: CRMColors.text),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Total Floors',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
    );

    final ageField = TextFormField(
      controller: _ageController,
      style: CRMTypography.body.copyWith(color: CRMColors.text),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Age (years)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
    );

    final furnishingField = DropdownButtonFormField<String>(
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
    );

    final facingField = Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return widget.metadata.facings.map((f) => f.name);
        }
        return widget.metadata.facings
            .map((f) => f.name)
            .where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        final match = widget.metadata.facings.firstWhere(
          (f) => f.name.toLowerCase() == selection.toLowerCase(),
          orElse: () => LookupItem(id: '', name: ''),
        );
        if (match.id.isNotEmpty) {
          _selectedFacing = match.id;
          _facingController.text = match.name;
        }
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        textEditingController.text = _facingController.text;
        _facingController = textEditingController;
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          style: CRMTypography.body.copyWith(color: CRMColors.text),
          decoration: InputDecoration(
            labelText: 'Facing',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
          ),
          onChanged: (val) {
            _selectedFacing = null;
          },
        );
      },
    );

    final ownershipField = DropdownButtonFormField<String>(
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
    );

    return CRMCard(
      title: 'Pricing & Sizing Sockets',
      subtitle: 'Complete budget calculations and builtup area parameters',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            priceField,
            const SizedBox(height: CRMSpacing.m),
            depositField,
          ] else ...[
            Row(
              children: [
                Expanded(child: priceField),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: depositField),
              ],
            ),
          ],
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
          if (isMobile) ...[
            superBuiltupField,
            const SizedBox(height: CRMSpacing.m),
            carpetField,
          ] else ...[
            Row(
              children: [
                Expanded(child: superBuiltupField),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: carpetField),
              ],
            ),
          ],
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
          if (isMobile) ...[
            Row(
              children: [
                Expanded(child: bedroomsField),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: bathroomsField),
              ],
            ),
            const SizedBox(height: CRMSpacing.m),
            Row(
              children: [
                Expanded(child: balconiesField),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: parkingField),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(child: bedroomsField),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: bathroomsField),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: balconiesField),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: parkingField),
              ],
            ),
          ],
          const SizedBox(height: CRMSpacing.m),
          if (isMobile) ...[
            floorNoField,
            const SizedBox(height: CRMSpacing.m),
            totalFloorField,
            const SizedBox(height: CRMSpacing.m),
            ageField,
          ] else ...[
            Row(
              children: [
                Expanded(child: floorNoField),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: totalFloorField),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: ageField),
              ],
            ),
          ],
          const SizedBox(height: CRMSpacing.l),
          Text('Property Attributes', style: CRMTypography.captionBold.copyWith(color: CRMColors.text)),
          const SizedBox(height: CRMSpacing.s),
          if (isMobile) ...[
            furnishingField,
            const SizedBox(height: CRMSpacing.m),
            facingField,
            const SizedBox(height: CRMSpacing.m),
            ownershipField,
          ] else ...[
            Row(
              children: [
                Expanded(child: furnishingField),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: facingField),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: ownershipField),
              ],
            ),
          ],
          const SizedBox(height: CRMSpacing.l),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Amenities', style: CRMTypography.captionBold.copyWith(color: CRMColors.text)),
              TextButton.icon(
                onPressed: _showAddAmenityDialog,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: const Text('Add Custom Amenity'),
                style: TextButton.styleFrom(
                  foregroundColor: CRMColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.s),
          Wrap(
            spacing: CRMSpacing.s,
            runSpacing: CRMSpacing.xs,
            children: _localAmenities.map((amenity) {
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
      ),
    );
  }

  Future<void> _showAddAmenityDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CRMColors.cardBg,
        title: Text('Add Custom Amenity', style: TextStyle(color: CRMColors.textOf(context))),
        content: TextField(
          controller: controller,
          style: TextStyle(color: CRMColors.textOf(context)),
          decoration: const InputDecoration(
            hintText: 'Enter amenity name (e.g. Solar Panels)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                try {
                  final newAmenity = await PropertiesRepository().createAmenity(name);
                  setState(() {
                    _localAmenities.add(newAmenity);
                    _selectedAmenities.add(newAmenity.id);
                  });
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add amenity: $e'), backgroundColor: CRMColors.danger),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
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

  Widget _buildContactsStep(bool isMobile) {
    final ownerNameField = TextFormField(
      controller: _ownerNameController,
      style: CRMTypography.body.copyWith(color: CRMColors.text),
      decoration: InputDecoration(
        labelText: 'Owner Name *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
      validator: (v) => v!.isEmpty ? 'Owner name required' : null,
    );

    final ownerMobileField = TextFormField(
      controller: _ownerMobileController,
      style: CRMTypography.body.copyWith(color: CRMColors.text),
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: 'Owner Mobile *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
      validator: (v) => v!.isEmpty ? 'Mobile required' : null,
    );

    return CRMCard(
      title: 'Contacts Info & Visibility',
      subtitle: 'Verify owner profiles and direct remarks',
      child: Column(
        children: [
          if (isMobile) ...[
            ownerNameField,
            const SizedBox(height: CRMSpacing.m),
            ownerMobileField,
          ] else ...[
            Row(
              children: [
                Expanded(child: ownerNameField),
                const SizedBox(width: CRMSpacing.s),
                Expanded(child: ownerMobileField),
              ],
            ),
          ],
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
      decoration: BoxDecoration(
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
