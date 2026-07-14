import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/skeletons.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../models/dashboard_summary.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboard());
  }

  void _showActionSnackbar(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action functionality coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userEmail = 'admin@nbdeveloper.com';
    if (authState is Authenticated) {
      userEmail = authState.user.email;
    }

    final dateString = "14 July 2026";

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return const Padding(
            padding: EdgeInsets.all(CRMSpacing.l),
            child: CRMListSkeleton(count: 4),
          );
        } else if (state is DashboardError) {
          return _buildErrorState(state.message);
        } else if (state is DashboardLoadedState || state is DashboardRefreshing) {
          final data = (state is DashboardLoadedState)
              ? state.data
              : (state as DashboardRefreshing).data;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DashboardBloc>().add(RefreshDashboard());
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(CRMSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Welcome Header
                  _buildWelcomeHeader(userEmail, dateString),
                  const SizedBox(height: CRMSpacing.l),

                  // 2. Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: CRMSpacing.l),

                  // 3. Property KPI Cards & 4. Requirement KPI Cards
                  _buildKPIGrids(data.summary),
                  const SizedBox(height: CRMSpacing.l),

                  // Split analytics and Tasks layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 900;
                      if (isDesktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildAnalyticsChart(),
                                  const SizedBox(height: CRMSpacing.l),
                                  _buildRecentProperties(data.recentProperties),
                                ],
                              ),
                            ),
                            const SizedBox(width: CRMSpacing.l),
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildTodayWork(),
                                  const SizedBox(height: CRMSpacing.l),
                                  _buildRecentActivities(data.activity),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildAnalyticsChart(),
                            const SizedBox(height: CRMSpacing.l),
                            _buildTodayWork(),
                            const SizedBox(height: CRMSpacing.l),
                            _buildRecentProperties(data.recentProperties),
                            const SizedBox(height: CRMSpacing.l),
                            _buildRecentActivities(data.activity),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: CRMSpacing.l),

                  // 10. Performance Indicators
                  _buildPerformanceBlock(),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWelcomeHeader(String email, String dateString) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning,',
              style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
            ),
            Text(
              email.split('@').first,
              style: CRMTypography.pageTitle.copyWith(color: CRMColors.text),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              dateString,
              style: CRMTypography.bodyMedium.copyWith(color: CRMColors.primary),
            ),
            Text(
              'Branch: Head Office',
              style: CRMTypography.caption.copyWith(color: CRMColors.textMuted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return CRMCard(
      title: 'Quick Operations',
      subtitle: 'Perform common CRM operational workflows instantly',
      child: Wrap(
        spacing: CRMSpacing.m,
        runSpacing: CRMSpacing.m,
        children: [
          CRMButton(
            label: 'Add Property',
            prefixIcon: Icons.add_business_rounded,
            onPressed: () => context.push('/properties'),
          ),
          CRMButton(
            label: 'Add Requirement',
            prefixIcon: Icons.add_task_rounded,
            variant: CRMButtonVariant.secondary,
            onPressed: () => _showActionSnackbar('Add Requirement'),
          ),
          CRMButton(
            label: 'Import Excel',
            prefixIcon: Icons.file_upload_rounded,
            variant: CRMButtonVariant.outline,
            onPressed: () => _showActionSnackbar('Import Excel'),
          ),
          CRMButton(
            label: 'Create Follow-up',
            prefixIcon: Icons.alarm_add_rounded,
            variant: CRMButtonVariant.outline,
            onPressed: () => _showActionSnackbar('Create Follow-up'),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIGrids(DashboardSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Property Metrics', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text)),
        const SizedBox(height: CRMSpacing.s),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width >= 1100 ? 5 : (MediaQuery.of(context).size.width >= 700 ? 3 : 1),
          crossAxisSpacing: CRMSpacing.m,
          mainAxisSpacing: CRMSpacing.m,
          childAspectRatio: 1.5,
          children: [
            CRMKPICard(
              title: 'Total Properties',
              value: '${summary.totalProperties}',
              icon: Icons.inventory_2_outlined,
              growthPercent: 8.5,
            ),
            CRMKPICard(
              title: 'Available',
              value: '${summary.available}',
              icon: Icons.check_circle_outline_rounded,
              iconColor: CRMColors.success,
              growthPercent: 12.0,
            ),
            CRMKPICard(
              title: 'Sold',
              value: '${summary.sold}',
              icon: Icons.sell_outlined,
              iconColor: CRMColors.warning,
              growthPercent: -2.3,
            ),
            CRMKPICard(
              title: 'Rented',
              value: '${summary.rented}',
              icon: Icons.key_outlined,
              iconColor: CRMColors.info,
              growthPercent: 4.8,
            ),
            CRMKPICard(
              title: 'Requirements',
              value: '${summary.requirements}',
              icon: Icons.assignment_turned_in_outlined,
              growthPercent: 15.2,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayWork() {
    return CRMCard(
      title: "Today's Work checklist",
      subtitle: 'Operations and tasks assigned for today',
      child: Column(
        children: [
          _buildTaskTile('Pending Client Verification', 'Review documents for PR-1002', true),
          _buildTaskTile('Site Visit (Prahladnagar)', 'Meet client at 4:30 PM', false),
          _buildTaskTile('Excel import approval', 'Verify 12 imported rows', false),
        ],
      ),
    );
  }

  Widget _buildTaskTile(String title, String description, bool isHighPriority) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CRMSpacing.m),
      child: Row(
        children: [
          Icon(
            Icons.radio_button_off_rounded,
            color: isHighPriority ? CRMColors.danger : CRMColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: CRMSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.text)),
                Text(description, style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary)),
              ],
            ),
          ),
          if (isHighPriority)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: CRMColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('High', style: TextStyle(color: CRMColors.danger, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsChart() {
    return CRMCard(
      title: 'Properties & Requirements Analytics',
      subtitle: 'System entries volume registered month-over-month',
      child: SizedBox(
        height: 220,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBar('Jan', 60, CRMColors.primary),
            _buildBar('Feb', 90, CRMColors.primary.withOpacity(0.7)),
            _buildBar('Mar', 120, CRMColors.primary),
            _buildBar('Apr', 75, CRMColors.primary.withOpacity(0.7)),
            _buildBar('May', 150, CRMColors.success),
            _buildBar('Jun', 180, CRMColors.success),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String label, double height, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 36,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(CRMBorderRadius.xs),
              topRight: Radius.circular(CRMBorderRadius.xs),
            ),
          ),
        ),
        const SizedBox(height: CRMSpacing.xs),
        Text(label, style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary)),
      ],
    );
  }

  Widget _buildRecentProperties(List<RecentProperty> properties) {
    return CRMCard(
      title: 'Recent Properties',
      subtitle: 'Latest listings registered in the CRM platform',
      child: properties.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No listings found.')))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(CRMColors.background),
                columns: const [
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Title')),
                  DataColumn(label: Text('Area')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Status')),
                ],
                rows: properties.map((p) {
                  return DataRow(
                    cells: [
                      DataCell(Text(p.code, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(p.title)),
                      DataCell(Text(p.areaName)),
                      DataCell(Text('₹${p.price.toStringAsFixed(0)}')),
                      DataCell(Text(p.status)),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildRecentActivities(List<RecentActivity> activities) {
    return CRMCard(
      title: 'Recent Audit Activities',
      subtitle: 'Trace logs of structural edits inside CRM database',
      child: activities.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No activity logs.')))
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: CRMSpacing.m),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.history_toggle_off_rounded, color: CRMColors.primary, size: 18),
                      const SizedBox(width: CRMSpacing.s),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(activity.description, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.text)),
                            Text(
                              'User: ${activity.user} | ${activity.timestamp}',
                              style: CRMTypography.caption.copyWith(color: CRMColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPerformanceBlock() {
    return CRMCard(
      title: 'Agency CRM Performance metrics',
      subtitle: 'Real-time performance metrics tracking brokers and regions',
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 4 : 2,
        crossAxisSpacing: CRMSpacing.m,
        mainAxisSpacing: CRMSpacing.m,
        childAspectRatio: 2.0,
        children: [
          _buildPerformanceCard('Top Broker', 'System Administrator', Icons.stars_rounded),
          _buildPerformanceCard('Top Area', 'Prahladnagar', Icons.location_on_rounded),
          _buildPerformanceCard('Top Property', 'PR-1001', Icons.home_rounded),
          _buildPerformanceCard('Monthly Growth', '+24.5%', Icons.trending_up_rounded),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(CRMSpacing.s),
      decoration: BoxDecoration(
        color: CRMColors.background,
        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
      ),
      child: Row(
        children: [
          Icon(icon, color: CRMColors.primary, size: 24),
          const SizedBox(width: CRMSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary)),
                Text(
                  value,
                  style: CRMTypography.bodyMedium.copyWith(color: CRMColors.text, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CRMSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: CRMColors.danger, size: 48),
            const SizedBox(height: CRMSpacing.m),
            Text('Failed to Load Dashboard', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text)),
            const SizedBox(height: CRMSpacing.xs),
            Text(message, style: CRMTypography.body.copyWith(color: CRMColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: CRMSpacing.l),
            CRMButton(
              label: 'Retry Connection',
              onPressed: () {
                context.read<DashboardBloc>().add(LoadDashboard());
              },
            ),
          ],
        ),
      ),
    );
  }
}
