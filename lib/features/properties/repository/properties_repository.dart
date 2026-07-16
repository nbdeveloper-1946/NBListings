import '../models/property_model.dart';
import '../services/properties_service.dart';

class PropertiesRepository {
  final PropertiesService _propertiesService = PropertiesService();

  static final Map<String, List<PropertyModel>> _propertiesCache = {};
  static final Map<String, DateTime> _propertiesCacheTime = {};

  void invalidateCache() {
    _propertiesCache.clear();
    _propertiesCacheTime.clear();
  }

  Future<List<PropertyModel>> getProperties({
    String? search,
    String? categoryId,
    String? areaId,
    String? listingTypeId,
    String? createdBy,
    bool? isVerified,
    bool? includeDeleted,
  }) async {
    final cacheKey = '$search|$categoryId|$areaId|$listingTypeId|$createdBy|$isVerified|$includeDeleted';
    final cached = _propertiesCache[cacheKey];
    final cacheTime = _propertiesCacheTime[cacheKey];

    if (cached != null && cacheTime != null && DateTime.now().difference(cacheTime).inSeconds < 30) {
      return cached;
    }

    if (cached != null) {
      _propertiesService.getProperties(
        search: search,
        categoryId: categoryId,
        areaId: areaId,
        listingTypeId: listingTypeId,
        createdBy: createdBy,
        isVerified: isVerified,
        includeDeleted: includeDeleted,
      ).then((response) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        final list = data['properties'] as List? ?? [];
        final freshList = list.map((item) => PropertyModel.fromJson(item)).toList();
        _propertiesCache[cacheKey] = freshList;
        _propertiesCacheTime[cacheKey] = DateTime.now();
      }).catchError((_) {});

      return cached;
    }

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
    final properties = list.map((item) => PropertyModel.fromJson(item)).toList();

    _propertiesCache[cacheKey] = properties;
    _propertiesCacheTime[cacheKey] = DateTime.now();
    return properties;
  }

  Future<PropertyMetadataModel> getPropertyMetadata() async {
    final response = await _propertiesService.getPropertyMetadata();
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return PropertyMetadataModel.fromJson(data['metadata'] ?? {});
  }

  Future<LookupItem> createCity(String name) async {
    final response = await _propertiesService.createCity(name);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final city = data['city'] as Map<String, dynamic>? ?? {};
    return LookupItem(id: city['id'], name: city['city_name']);
  }

  Future<AreaLookup> createArea(String cityId, String name, String pincode) async {
    final response = await _propertiesService.createArea(cityId, name, pincode);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final area = data['area'] as Map<String, dynamic>? ?? {};
    return AreaLookup(
      id: area['id'] ?? '',
      name: area['area_name'] ?? '',
      cityId: area['city_id'] ?? '',
      pincode: area['pincode'] ?? '',
    );
  }

  Future<LookupItem> createAmenity(String name) async {
    final response = await _propertiesService.createAmenity(name);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final amenity = data['amenity'] as Map<String, dynamic>? ?? {};
    return LookupItem(
      id: amenity['id'] ?? '',
      name: amenity['name'] ?? '',
    );
  }

  Future<PropertyModel> createProperty(Map<String, dynamic> propertyData) async {
    invalidateCache();
    final response = await _propertiesService.createProperty(propertyData);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return PropertyModel.fromJson(data['property'] ?? {});
  }

  Future<PropertyModel> updateProperty(String id, Map<String, dynamic> propertyData) async {
    invalidateCache();
    final response = await _propertiesService.updateProperty(id, propertyData);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return PropertyModel.fromJson(data['property'] ?? {});
  }

  Future<PropertyModel> togglePropertyVerification(String id, bool isVerified) async {
    invalidateCache();
    final response = await _propertiesService.togglePropertyVerification(id, isVerified);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return PropertyModel.fromJson(data['property'] ?? {});
  }

  Future<PropertyModel> softDeleteProperty(String id) async {
    invalidateCache();
    final response = await _propertiesService.softDeleteProperty(id);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return PropertyModel.fromJson(data['property'] ?? {});
  }

  Future<PropertyModel> restoreProperty(String id) async {
    invalidateCache();
    final response = await _propertiesService.restoreProperty(id);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return PropertyModel.fromJson(data['property'] ?? {});
  }

  Future<LookupItem> createLookup(String masterType, Map<String, dynamic> payload) async {
    final response = await _propertiesService.createLookup(masterType, payload);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final key = masterType == 'property-type' ? 'propertyType' :
                masterType == 'listing-type' ? 'listingType' : masterType;
    final item = data[key] as Map<String, dynamic>? ?? {};
    if (masterType == 'area') {
      return AreaLookup.fromJson(item);
    }
    return LookupItem.fromJson(item);
  }
}
