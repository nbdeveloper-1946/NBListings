import 'package:nblistings/features/dashboard/models/dashboard_summary.dart';
import 'package:nblistings/features/dashboard/services/dashboard_service.dart';
import 'package:nblistings/core/storage/repository_coordinator.dart';
import 'package:nblistings/core/storage/isar_collections.dart';
import 'package:nblistings/core/storage/model_mappers.dart';
import 'package:nblistings/core/storage/performance_logger.dart';

class DashboardRepository {
  final DashboardService _dashboardService = DashboardService();
  final RepositoryCoordinator _coordinator = RepositoryCoordinator();

  Future<DashboardData> getDashboardData() async {
    final start = DateTime.now();
    
    // Read from local Isar
    final localDashboard = await _coordinator.dashboardLocal.getDashboard();
    final isarReadMs = DateTime.now().difference(start).inMilliseconds;
    
    DashboardData? cachedData;
    int jsonParseMs = 0;
    if (localDashboard != null) {
      final parseStart = DateTime.now();
      cachedData = localDashboard.toModel();
      jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;
    }

    final totalMs = DateTime.now().difference(start).inMilliseconds;
    PerformanceLogger().logMetric(
      operation: 'DashboardRepository.getDashboardData (local)',
      isarReadMs: isarReadMs,
      jsonParseMs: jsonParseMs,
      totalMs: totalMs,
    );

    // Trigger async background refresh
    _triggerBackgroundDashboardRefresh();

    if (cachedData != null) {
      return cachedData;
    }

    // Fallback if cache is completely empty on first launch
    final data = await _dashboardService.getDashboardData();
    final model = DashboardData.fromJson(data);
    await _coordinator.dashboardLocal.saveDashboard(model.toLocal());
    return model;
  }

  void _triggerBackgroundDashboardRefresh() {
    final start = DateTime.now();
    _dashboardService.getDashboardData().then((response) async {
      final networkMs = DateTime.now().difference(start).inMilliseconds;

      final parseStart = DateTime.now();
      final freshData = DashboardData.fromJson(response);
      final jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;

      final writeStart = DateTime.now();
      // Save locally to dashboard local table
      await _coordinator.dashboardLocal.saveDashboard(freshData.toLocal());
      
      // Also synchronize structured followups table inside Isar
      final listData = response['followups'] as List? ?? [];
      final freshFollowups = listData.map((item) => DashboardFollowup.fromJson(item)).toList();
      final localEntities = freshFollowups.map((f) => f.toLocal('System')).toList();
      await _coordinator.followupLocal.saveFollowups(localEntities);
      final isarWriteMs = DateTime.now().difference(writeStart).inMilliseconds;

      final totalMs = DateTime.now().difference(start).inMilliseconds;
      PerformanceLogger().logMetric(
        operation: 'DashboardRepository.getDashboardData (background refresh)',
        networkMs: networkMs,
        jsonParseMs: jsonParseMs,
        isarWriteMs: isarWriteMs,
        totalMs: totalMs,
      );

      _coordinator.refreshDashboard();
    }).catchError((_) {});
  }
}
