import '../models/dashboard_summary.dart';
import '../services/dashboard_service.dart';

class DashboardRepository {
  final DashboardService _dashboardService = DashboardService();

  Future<DashboardData> getDashboardData() async {
    final data = await _dashboardService.getDashboardData();
    return DashboardData.fromJson(data);
  }
}
