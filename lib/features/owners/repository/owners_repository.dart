import '../models/owner_model.dart';
import '../services/owners_service.dart';

class OwnersRepository {
  final OwnersService _ownersService = OwnersService();

  Future<List<OwnerModel>> getOwners({String? search}) async {
    final response = await _ownersService.getOwners(search: search);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final list = data['owners'] as List? ?? [];
    return list.map((item) => OwnerModel.fromJson(item)).toList();
  }

  Future<OwnerModel> createOwner(OwnerModel owner) async {
    final response = await _ownersService.createOwner(owner.toJson());
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return OwnerModel.fromJson(data['owner'] ?? {});
  }

  Future<OwnerModel> updateOwner(OwnerModel owner) async {
    final response = await _ownersService.updateOwner(owner.id, owner.toJson());
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return OwnerModel.fromJson(data['owner'] ?? {});
  }

  Future<void> deleteOwner(String id) async {
    await _ownersService.deleteOwner(id);
  }
}
