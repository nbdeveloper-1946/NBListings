import '../models/requirement_model.dart';
import '../services/requirements_service.dart';

class RequirementsRepository {
  final RequirementsService _requirementsService = RequirementsService();

  static final Map<String, List<RequirementModel>> _requirementsCache = {};
  static final Map<String, DateTime> _requirementsCacheTime = {};

  void invalidateCache() {
    _requirementsCache.clear();
    _requirementsCacheTime.clear();
  }

  Future<List<RequirementModel>> getRequirements({
    String? search,
    String? configurationId,
    String? status,
  }) async {
    final cacheKey = '$search|$configurationId|$status';
    final cached = _requirementsCache[cacheKey];
    final cacheTime = _requirementsCacheTime[cacheKey];

    if (cached != null && cacheTime != null && DateTime.now().difference(cacheTime).inSeconds < 30) {
      return cached;
    }

    if (cached != null) {
      _requirementsService.getRequirements(
        search: search,
        configurationId: configurationId,
        status: status,
      ).then((response) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        final list = data['requirements'] as List? ?? [];
        final freshList = list.map((item) => RequirementModel.fromJson(item)).toList();
        _requirementsCache[cacheKey] = freshList;
        _requirementsCacheTime[cacheKey] = DateTime.now();
      }).catchError((_) {});

      return cached;
    }

    final response = await _requirementsService.getRequirements(
      search: search,
      configurationId: configurationId,
      status: status,
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final list = data['requirements'] as List? ?? [];
    final requirements = list.map((item) => RequirementModel.fromJson(item)).toList();

    _requirementsCache[cacheKey] = requirements;
    _requirementsCacheTime[cacheKey] = DateTime.now();
    return requirements;
  }

  Future<RequirementModel> createRequirement(RequirementModel req) async {
    invalidateCache();
    final response = await _requirementsService.createRequirement(req.toBackendJson());
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return RequirementModel.fromJson(data['requirement'] ?? {});
  }

  Future<RequirementModel> updateRequirement(RequirementModel req) async {
    invalidateCache();
    final response = await _requirementsService.updateRequirement(req.id, req.toBackendJson());
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return RequirementModel.fromJson(data['requirement'] ?? {});
  }

  Future<void> deleteRequirement(String id) async {
    invalidateCache();
    await _requirementsService.deleteRequirement(id);
  }
}
