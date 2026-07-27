import 'package:shared_preferences/shared_preferences.dart';

class MigrationPreferencesService {
  static const String _keyMigrationSeen = 'migration_animation_seen';

  Future<bool> hasSeenMigration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMigrationSeen) ?? false;
  }

  Future<void> markMigrationAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMigrationSeen, true);
  }

  Future<void> clearMigrationSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMigrationSeen);
  }
}
