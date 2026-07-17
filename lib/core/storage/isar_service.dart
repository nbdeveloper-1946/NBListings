import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'isar_collections.dart';
import 'local_repositories.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();
  factory IsarService() => _instance;
  IsarService._internal();

  Isar? _isar;

  Isar get isar {
    if (_isar == null) {
      if (kIsWeb) {
        throw StateError("Isar database is not available on Flutter Web. Running in-memory instead.");
      }
      throw StateError("Isar has not been initialized. Call initialize() first.");
    }
    return _isar!;
  }

  Future<void> initialize() async {
    if (_isar != null) return;

    if (kIsWeb) {
      print("🌐 [ISAR WEB] Bypassing Isar.open. Running local repositories in-memory.");
      await LookupLocalRepository().loadInMemoryCache();
      await PropertyLocalRepository().loadInMemoryCache();
      await RequirementLocalRepository().loadInMemoryCache();
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        LookupItemLocalSchema,
        PropertyLocalSchema,
        RequirementLocalSchema,
        FollowupLocalSchema,
        BuilderLocalSchema,
        OwnerLocalSchema,
        OutboxLocalSchema,
        DashboardLocalSchema,
      ],
      directory: dir.path,
    );
  }

  Future<void> clearAll() async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}
