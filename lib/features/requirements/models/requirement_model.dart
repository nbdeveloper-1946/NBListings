class RequirementModel {
  final String id;
  final String clientName;
  final String clientMobile;
  final String categoryId;
  final String categoryName;
  final String propertyTypeId;
  final String propertyTypeName;
  final String? configurationId;
  final String? configurationName;
  final String? listingTypeId;
  final String? listingTypeName;
  final double minBudget;
  final double maxBudget;
  final double? minArea;
  final double? maxArea;
  final List<String> areaIds;
  final List<String> areaNames;
  final String? remarks;
  final String status; // 'Active', 'Closed', 'Suspended'
  final DateTime createdAt;
  final String? adminId;
  final String? organizationId;

  RequirementModel({
    required this.id,
    required this.clientName,
    required this.clientMobile,
    required this.categoryId,
    required this.categoryName,
    required this.propertyTypeId,
    required this.propertyTypeName,
    this.configurationId,
    this.configurationName,
    this.listingTypeId,
    this.listingTypeName,
    required this.minBudget,
    required this.maxBudget,
    this.minArea,
    this.maxArea,
    required this.areaIds,
    required this.areaNames,
    this.remarks,
    required this.status,
    required this.createdAt,
    this.adminId,
    this.organizationId,
  });

  factory RequirementModel.fromJson(Map<String, dynamic> json) {
    // Handle category name from joined category object
    String catName = '';
    if (json['categoryName'] != null) {
      catName = json['categoryName'];
    } else if (json['category'] != null && json['category'] is Map) {
      catName = json['category']['name'] ?? '';
    }

    // Handle property type name from joined object
    String typeName = '';
    if (json['propertyTypeName'] != null) {
      typeName = json['propertyTypeName'];
    } else if (json['property_type'] != null && json['property_type'] is Map) {
      typeName = json['property_type']['name'] ?? '';
    }

    // Handle configuration name from joined object
    String? configName;
    if (json['configurationName'] != null) {
      configName = json['configurationName'];
    } else if (json['configuration'] != null && json['configuration'] is Map) {
      configName = json['configuration']['name'];
    }

    // Handle listing type name from joined object
    String? listingName;
    if (json['listingTypeName'] != null) {
      listingName = json['listingTypeName'];
    } else if (json['listing_type'] != null && json['listing_type'] is Map) {
      listingName = json['listing_type']['name'];
    }

    // Handle target areas
    List<String> aIds = [];
    if (json['areaIds'] != null) {
      aIds = List<String>.from(json['areaIds']);
    } else if (json['area_id'] != null) {
      aIds = [json['area_id'].toString()];
    }

    List<String> aNames = [];
    if (json['areaNames'] != null) {
      aNames = List<String>.from(json['areaNames']);
    } else if (json['area'] != null && json['area'] is Map) {
      aNames = [json['area']['area_name']?.toString() ?? ''];
    }

    return RequirementModel(
      id: json['id'] ?? '',
      clientName: json['clientName'] ?? json['customer_name'] ?? '',
      clientMobile: json['clientMobile'] ?? json['mobile'] ?? '',
      categoryId: json['categoryId'] ?? json['category_id'] ?? '',
      categoryName: catName,
      propertyTypeId: json['propertyTypeId'] ?? json['property_type_id'] ?? '',
      propertyTypeName: typeName,
      configurationId: json['configurationId'] ?? json['configuration_id'],
      configurationName: configName,
      listingTypeId: json['listingTypeId'] ?? json['listing_type_id'],
      listingTypeName: listingName,
      minBudget: (json['minBudget'] ?? json['budget_from'] as num?)?.toDouble() ?? 0.0,
      maxBudget: (json['maxBudget'] ?? json['budget_to'] as num?)?.toDouble() ?? 0.0,
      minArea: (json['minArea'] ?? json['min_area'] as num?)?.toDouble(),
      maxArea: (json['maxArea'] ?? json['max_area'] as num?)?.toDouble(),
      areaIds: aIds,
      areaNames: aNames,
      remarks: json['remarks'],
      status: json['status'] ?? 'Active',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      adminId: json['admin_id'] as String?,
      organizationId: json['organization_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientName': clientName,
      'clientMobile': clientMobile,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'propertyTypeId': propertyTypeId,
      'propertyTypeName': propertyTypeName,
      'configurationId': configurationId,
      'configurationName': configurationName,
      'listingTypeId': listingTypeId,
      'listingTypeName': listingTypeName,
      'minBudget': minBudget,
      'maxBudget': maxBudget,
      'minArea': minArea,
      'maxArea': maxArea,
      'areaIds': areaIds,
      'areaNames': areaNames,
      'remarks': remarks,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'adminId': adminId,
      'organizationId': organizationId,
    };
  }

  Map<String, dynamic> toBackendJson() {
    return {
      'customer_name': clientName,
      'mobile': clientMobile,
      'category_id': categoryId,
      'property_type_id': propertyTypeId,
      'configuration_id': configurationId,
      'listing_type_id': listingTypeId,
      'budget': (minBudget + maxBudget) / 2,
      'budget_from': minBudget,
      'budget_to': maxBudget,
      'min_area': minArea,
      'max_area': maxArea,
      'area_id': areaIds.isNotEmpty ? areaIds.first : null,
      'area_ids': areaIds,
      'remarks': remarks,
      'status': status,
    };
  }

  RequirementModel copyWith({
    String? id,
    String? clientName,
    String? clientMobile,
    String? categoryId,
    String? categoryName,
    String? propertyTypeId,
    String? propertyTypeName,
    String? configurationId,
    String? configurationName,
    String? listingTypeId,
    String? listingTypeName,
    double? minBudget,
    double? maxBudget,
    double? minArea,
    double? maxArea,
    List<String>? areaIds,
    List<String>? areaNames,
    String? remarks,
    String? status,
    DateTime? createdAt,
    String? adminId,
    String? organizationId,
  }) {
    return RequirementModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientMobile: clientMobile ?? this.clientMobile,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      propertyTypeId: propertyTypeId ?? this.propertyTypeId,
      propertyTypeName: propertyTypeName ?? this.propertyTypeName,
      configurationId: configurationId ?? this.configurationId,
      configurationName: configurationName ?? this.configurationName,
      listingTypeId: listingTypeId ?? this.listingTypeId,
      listingTypeName: listingTypeName ?? this.listingTypeName,
      minBudget: minBudget ?? this.minBudget,
      maxBudget: maxBudget ?? this.maxBudget,
      minArea: minArea ?? this.minArea,
      maxArea: maxArea ?? this.maxArea,
      areaIds: areaIds ?? this.areaIds,
      areaNames: areaNames ?? this.areaNames,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      adminId: adminId ?? this.adminId,
      organizationId: organizationId ?? this.organizationId,
    );
  }
}
