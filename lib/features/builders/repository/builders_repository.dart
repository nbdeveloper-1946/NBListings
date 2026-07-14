import '../models/builder_model.dart';
import '../services/builders_service.dart';

class BuildersRepository {
  final BuildersService _buildersService = BuildersService();

  Future<List<BuilderModel>> getBuilders({String? search, String? tier}) async {
    final response = await _buildersService.getBuilders(search: search, tier: tier);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final list = data['builders'] as List? ?? [];
    return list.map((item) => BuilderModel.fromJson(item)).toList();
  }

  Future<BuilderModel> createBuilder(BuilderModel builder) async {
    final response = await _buildersService.createBuilder(builder.toJson());
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return BuilderModel.fromJson(data['builder'] ?? {});
  }

  Future<BuilderModel> updateBuilder(BuilderModel builder) async {
    final response = await _buildersService.updateBuilder(builder.id, builder.toJson());
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return BuilderModel.fromJson(data['builder'] ?? {});
  }

  Future<void> deleteBuilder(String id) async {
    await _buildersService.deleteBuilder(id);
  }
}
