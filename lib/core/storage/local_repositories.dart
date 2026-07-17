import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'isar_collections.dart';
import 'isar_service.dart';

class PropertyLocalRepository {
  Isar get _isar => IsarService().isar;

  static final Map<String, PropertyLocal> inMemory = {};

  Future<List<PropertyLocal>> getProperties({
    String? search,
    String? categoryId,
    String? areaId,
    String? listingTypeId,
    String? createdBy,
    bool? isVerified,
  }) async {
    if (kIsWeb) {
      var list = inMemory.values.toList();
      if (search != null && search.isNotEmpty) {
        final query = search.toLowerCase();
        list = list.where((p) =>
          p.title.toLowerCase().contains(query) ||
          p.propertyCode.toLowerCase().contains(query) ||
          (p.description != null && p.description!.toLowerCase().contains(query))
        ).toList();
      }
      if (categoryId != null) list = list.where((p) => p.categoryId == categoryId).toList();
      if (areaId != null) list = list.where((p) => p.areaId == areaId).toList();
      if (listingTypeId != null) list = list.where((p) => p.listingTypeId == listingTypeId).toList();
      if (createdBy != null) list = list.where((p) => p.createdBy == createdBy).toList();
      if (isVerified != null) list = list.where((p) => p.isVerified == isVerified).toList();
      return list;
    }

    final query = _isar.propertyLocals.filter().idIsNotEmpty();
    QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition> filtered = query;

    if (search != null && search.isNotEmpty) {
      filtered = filtered.and().group((q) => q
        .titleContains(search, caseSensitive: false)
        .or()
        .propertyCodeContains(search, caseSensitive: false)
        .or()
        .descriptionContains(search, caseSensitive: false)
      );
    }
    if (categoryId != null) filtered = filtered.and().categoryIdEqualTo(categoryId);
    if (areaId != null) filtered = filtered.and().areaIdEqualTo(areaId);
    if (listingTypeId != null) filtered = filtered.and().listingTypeIdEqualTo(listingTypeId);
    if (createdBy != null) filtered = filtered.and().createdByEqualTo(createdBy);
    if (isVerified != null) filtered = filtered.and().isVerifiedEqualTo(isVerified);

    return await filtered.sortByCreatedAtDesc().findAll();
  }

  Future<void> saveProperties(List<PropertyLocal> properties) async {
    if (kIsWeb) {
      for (final p in properties) {
        inMemory[p.id] = p;
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.propertyLocals.putAll(properties);
    });
  }

  Future<void> deleteProperty(String id) async {
    if (kIsWeb) {
      inMemory.remove(id);
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.propertyLocals.filter().idEqualTo(id).deleteAll();
    });
  }
}

class RequirementLocalRepository {
  Isar get _isar => IsarService().isar;

  static final Map<String, RequirementLocal> inMemory = {};

  Future<List<RequirementLocal>> getRequirements({
    String? search,
    String? configurationId,
    String? status,
  }) async {
    if (kIsWeb) {
      var list = inMemory.values.toList();
      if (search != null && search.isNotEmpty) {
        final query = search.toLowerCase();
        list = list.where((r) =>
          r.clientName.toLowerCase().contains(query) ||
          r.clientMobile.contains(query) ||
          (r.remarks != null && r.remarks!.toLowerCase().contains(query))
        ).toList();
      }
      if (configurationId != null) list = list.where((r) => r.configurationId == configurationId).toList();
      if (status != null && status != 'All') list = list.where((r) => r.status == status).toList();
      return list;
    }

    final query = _isar.requirementLocals.filter().idIsNotEmpty();
    QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition> filtered = query;

    if (search != null && search.isNotEmpty) {
      filtered = filtered.and().group((q) => q
        .clientNameContains(search, caseSensitive: false)
        .or()
        .clientMobileContains(search)
        .or()
        .remarksContains(search, caseSensitive: false)
      );
    }
    if (configurationId != null) filtered = filtered.and().configurationIdEqualTo(configurationId);
    if (status != null && status != 'All') filtered = filtered.and().statusEqualTo(status);

    return await filtered.sortByCreatedAtDesc().findAll();
  }

  Future<void> saveRequirements(List<RequirementLocal> requirements) async {
    if (kIsWeb) {
      for (final r in requirements) {
        inMemory[r.id] = r;
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.requirementLocals.putAll(requirements);
    });
  }

  Future<void> deleteRequirement(String id) async {
    if (kIsWeb) {
      inMemory.remove(id);
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.requirementLocals.filter().idEqualTo(id).deleteAll();
    });
  }
}

class FollowupLocalRepository {
  Isar get _isar => IsarService().isar;

  static final Map<String, FollowupLocal> inMemory = {};

  Future<List<FollowupLocal>> getFollowupsByClient(String clientName) async {
    if (kIsWeb) {
      return inMemory.values.where((f) => f.clientName == clientName).toList();
    }

    return await _isar.followupLocals.filter().clientNameEqualTo(clientName).findAll();
  }

  Future<void> saveFollowups(List<FollowupLocal> followups) async {
    if (kIsWeb) {
      for (final f in followups) {
        inMemory[f.id] = f;
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.followupLocals.putAll(followups);
    });
  }

  Future<void> deleteFollowup(String id) async {
    if (kIsWeb) {
      inMemory.remove(id);
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.followupLocals.filter().idEqualTo(id).deleteAll();
    });
  }
}

class BuilderLocalRepository {
  Isar get _isar => IsarService().isar;

  static final Map<String, BuilderLocal> inMemory = {};

  Future<List<BuilderLocal>> getBuilders({String? search, String? tier}) async {
    if (kIsWeb) {
      var list = inMemory.values.toList();
      if (search != null && search.isNotEmpty) {
        final query = search.toLowerCase();
        list = list.where((b) => b.companyName.toLowerCase().contains(query)).toList();
      }
      if (tier != null) list = list.where((b) => b.tier == tier).toList();
      return list;
    }

    final query = _isar.builderLocals.filter().idIsNotEmpty();
    QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> filtered = query;

    if (search != null && search.isNotEmpty) {
      filtered = filtered.and().companyNameContains(search, caseSensitive: false);
    }
    if (tier != null) filtered = filtered.and().tierEqualTo(tier);

    return await filtered.sortByCreatedAtDesc().findAll();
  }

  Future<void> saveBuilders(List<BuilderLocal> builders) async {
    if (kIsWeb) {
      for (final b in builders) {
        inMemory[b.id] = b;
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.builderLocals.putAll(builders);
    });
  }

  Future<void> deleteBuilder(String id) async {
    if (kIsWeb) {
      inMemory.remove(id);
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.builderLocals.filter().idEqualTo(id).deleteAll();
    });
  }
}

class OwnerLocalRepository {
  Isar get _isar => IsarService().isar;

  static final Map<String, OwnerLocal> inMemory = {};

  Future<List<OwnerLocal>> getOwners({String? search}) async {
    if (kIsWeb) {
      var list = inMemory.values.toList();
      if (search != null && search.isNotEmpty) {
        final query = search.toLowerCase();
        list = list.where((o) => o.name.toLowerCase().contains(query)).toList();
      }
      return list;
    }

    final query = _isar.ownerLocals.filter().idIsNotEmpty();
    QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> filtered = query;

    if (search != null && search.isNotEmpty) {
      filtered = filtered.and().nameContains(search, caseSensitive: false);
    }

    return await filtered.sortByCreatedAtDesc().findAll();
  }

  Future<void> saveOwners(List<OwnerLocal> owners) async {
    if (kIsWeb) {
      for (final o in owners) {
        inMemory[o.id] = o;
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.ownerLocals.putAll(owners);
    });
  }

  Future<void> deleteOwner(String id) async {
    if (kIsWeb) {
      inMemory.remove(id);
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.ownerLocals.filter().idEqualTo(id).deleteAll();
    });
  }
}

class LookupLocalRepository {
  Isar get _isar => IsarService().isar;

  static final Map<String, LookupItemLocal> inMemory = {};

  Future<List<LookupItemLocal>> getLookupsByCategory(String category) async {
    if (kIsWeb) {
      return inMemory.values.where((l) => l.category == category).toList();
    }

    return await _isar.lookupItemLocals.filter().categoryEqualTo(category).findAll();
  }

  Future<void> saveLookups(List<LookupItemLocal> items) async {
    if (kIsWeb) {
      for (final item in items) {
        inMemory[item.id] = item;
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.lookupItemLocals.putAll(items);
    });
  }

  Future<void> saveSingleLookup(LookupItemLocal item) async {
    if (kIsWeb) {
      inMemory[item.id] = item;
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.lookupItemLocals.put(item);
    });
  }
}

class OutboxLocalRepository {
  Isar get _isar => IsarService().isar;

  static final Map<String, OutboxLocal> inMemory = {};

  Future<List<OutboxLocal>> getQueuedRequests() async {
    if (kIsWeb) {
      final list = inMemory.values.toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    }

    return await _isar.outboxLocals.where().sortByCreatedAt().findAll();
  }

  Future<void> queueRequest(OutboxLocal request) async {
    if (kIsWeb) {
      inMemory[request.id] = request;
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.outboxLocals.put(request);
    });
  }

  Future<void> removeRequest(String id) async {
    if (kIsWeb) {
      inMemory.remove(id);
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.outboxLocals.filter().idEqualTo(id).deleteAll();
    });
  }
}

class DashboardLocalRepository {
  Isar get _isar => IsarService().isar;

  static DashboardLocal? inMemoryDashboard;

  Future<DashboardLocal?> getDashboard() async {
    if (kIsWeb) {
      return inMemoryDashboard;
    }

    return await _isar.dashboardLocals.filter().idEqualTo('singleton').findFirst();
  }

  Future<void> saveDashboard(DashboardLocal dashboard) async {
    if (kIsWeb) {
      inMemoryDashboard = dashboard;
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.dashboardLocals.put(dashboard);
    });
  }
}
