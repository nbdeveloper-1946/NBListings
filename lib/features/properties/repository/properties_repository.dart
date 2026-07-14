import '../models/property_model.dart';
import '../services/properties_service.dart';

class PropertiesRepository {
  final PropertiesService _propertiesService = PropertiesService();

  Future<List<PropertyModel>> getProperties({
    String? search,
    String? categoryId,
    String? areaId,
    String? listingTypeId,
    String? createdBy,
    bool? isVerified,
    bool? includeDeleted,
  }) async {
    final response = await _propertiesService.getProperties(
      search: search,
      categoryId: categoryId,
      areaId: areaId,
      listingTypeId: listingTypeId,
      createdBy: createdBy,
      isVerified: isVerified,
      includeDeleted: includeDeleted,
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final list = data['properties'] as List? ?? [];
    return list.map((item) => PropertyModel.fromJson(item)).toList();
  }

  Future<PropertyMetadataModel> getPropertyMetadata() async {
    final response = await _propertiesService.getPropertyMetadata();
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return PropertyMetadataModel.fromJson(data['metadata'] ?? {});
  }

  Future<PropertyModel> createProperty(Map<String, dynamic> propertyData) async {
    final response = await _propertiesService.createProperty(propertyData);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return PropertyModel.fromJson(data['property'] ?? {});
  }

  Future<PropertyModel> updateProperty(String id, Map<String, dynamic> propertyData) async {
    final response = await _propertiesService.updateProperty(id, propertyData);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return PropertyModel.fromJson(data['property'] ?? {});
  }

  Future<PropertyModel> togglePropertyVerification(String id, bool isVerified) async {
    final response = await _propertiesService.togglePropertyVerification(id, isVerified);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return PropertyModel.fromJson(data['property'] ?? {});
  }

  Future<PropertyModel> softDeleteProperty(String id) async {
    final response = await _propertiesService.softDeleteProperty(id);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return PropertyModel.fromJson(data['property'] ?? {});
  }

  Future<PropertyModel> restoreProperty(String id) async {
    final response = await _propertiesService.restoreProperty(id);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return PropertyModel.fromJson(data['property'] ?? {});
  }
}
