import '../models/requirement_model.dart';
import '../services/requirements_service.dart';

class RequirementsRepository {
  final RequirementsService _requirementsService = RequirementsService();

  Future<List<RequirementModel>> getRequirements({
    String? search,
    String? configurationId,
    String? status,
  }) async {
    final response = await _requirementsService.getRequirements(
      search: search,
      configurationId: configurationId,
      status: status,
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final list = data['requirements'] as List? ?? [];
    return list.map((item) => RequirementModel.fromJson(item)).toList();
  }

  Future<RequirementModel> createRequirement(RequirementModel req) async {
    final response = await _requirementsService.createRequirement(req.toBackendJson());
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return RequirementModel.fromJson(data['requirement'] ?? {});
  }

  Future<RequirementModel> updateRequirement(RequirementModel req) async {
    final response = await _requirementsService.updateRequirement(req.id, req.toBackendJson());
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return RequirementModel.fromJson(data['requirement'] ?? {});
  }

  Future<void> deleteRequirement(String id) async {
    await _requirementsService.deleteRequirement(id);
  }
}
