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
    Theme.of(context); // Register theme dependency to rebuild on toggle
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
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: CRMSpacing.m,
                vertical: CRMSpacing.l,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Welcome Header
                  _buildWelcomeHeader(userEmail, dateString),
                  const SizedBox(height: CRMSpacing.l),

                  // 2. Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: CRMSpacing.l),

                  // 3. KPI Grids (Overflow Fixed inside this method)
                  _buildKPIGrids(data.summary),
                  const SizedBox(height: CRMSpacing.l),

                  // Split analytics and Tasks layout (Responsive LayoutBuilder)
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good Morning,',
          style: CRMTypography.body.copyWith(
            color: CRMColors.textSecondaryOf(context),
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        Text(
          email.split('@').first,
          style: CRMTypography.pageTitle.copyWith(
            color: CRMColors.textOf(context),
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 22 : 28,
          ),
        ),
      ],
    );

    Widget rightColumn = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          dateString,
          style: CRMTypography.bodyMedium.copyWith(
            color: CRMColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'Branch: Head Office',
          style: CRMTypography.caption.copyWith(color: CRMColors.textMutedOf(context)),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftColumn,
          const SizedBox(height: CRMSpacing.s),
          rightColumn,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        leftColumn,
        rightColumn,
      ],
    );
  }

  Widget _buildQuickActions() {
    return CRMCard(
      title: 'Quick Operations',
      subtitle: 'Perform common CRM operational workflows instantly',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.s),
        child: Wrap(
          spacing: CRMSpacing.s,
          runSpacing: CRMSpacing.s,
          alignment: WrapAlignment.start,
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
      ),
    );
  }

  Widget _buildKPIGrids(DashboardSummary summary) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final cards = [
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
    ];

    // MOBILE VIEW MEIN OVERFLOW FIX KARNE KE LIYE HORIZONTAL LIST BANAYI HAI
    if (screenWidth < 600) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: CRMSpacing.xs, bottom: CRMSpacing.s),
            child: Text(
              'Property Metrics', 
              style: CRMTypography.sectionTitle.copyWith(
                color: CRMColors.textOf(context),
                fontWeight: FontWeight.bold,
              )
            ),
          ),
          SizedBox(
            height: 140, // Custom CRMKPICard ki internal height ke hisab se ideal height
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                return Container(
                  width: screenWidth * 0.44, // Ek bar me screen par do cards perfectly dikhenge 
                  margin: const EdgeInsets.only(right: CRMSpacing.m),
                  child: cards[index],
                );
              },
            ),
          ),
        ],
      );
    }

    // DESKTOP/TABLET KE LIYE GRID LAYOUT (BINA LOGIC CHANGE)
    int crossAxisCount = screenWidth >= 1440 ? 5 : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: CRMSpacing.xs, bottom: CRMSpacing.s),
          child: Text(
            'Property Metrics', 
            style: CRMTypography.sectionTitle.copyWith(
              color: CRMColors.textOf(context),
              fontWeight: FontWeight.bold,
            )
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: CRMSpacing.m,
            mainAxisSpacing: CRMSpacing.m,
            childAspectRatio: 1.4,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            return cards[index];
          },
        ),
      ],
    );
  }

  Widget _buildTodayWork() {
    return CRMCard(
      title: "Today's Work checklist",
      subtitle: 'Operations and tasks assigned for today',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.m),
        child: Column(
          children: [
            _buildTaskTile('Pending Client Verification', 'Review documents for PR-1002', true),
            _buildTaskTile('Site Visit (Prahladnagar)', 'Meet client at 4:30 PM', false),
            _buildTaskTile('Excel import approval', 'Verify 12 imported rows', false),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(String title, String description, bool isHighPriority) {
    return Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.s),
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.backgroundOf(context).withOpacity(0.4),
        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        border: Border.all(color: CRMColors.backgroundOf(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.radio_button_off_rounded,
            color: isHighPriority ? CRMColors.danger : CRMColors.textMutedOf(context),
            size: 20,
          ),
          const SizedBox(width: CRMSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: CRMTypography.bodyMedium.copyWith(
                    color: CRMColors.textOf(context),
                    fontWeight: FontWeight.w600
                  )
                ),
                const SizedBox(height: 2),
                Text(description, style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
              ],
            ),
          ),
          if (isHighPriority)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CRMColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
              ),
              child: const Text(
                'High', 
                style: TextStyle(color: CRMColors.danger, fontSize: 10, fontWeight: FontWeight.bold)
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsChart() {
    return CRMCard(
      title: 'Properties & Requirements Analytics',
      subtitle: 'System entries volume registered month-over-month',
      child: Container(
        height: 240,
        padding: const EdgeInsets.only(top: CRMSpacing.l),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double containerWidth = constraints.maxWidth;
            final double barWidth = (containerWidth / 7).clamp(24.0, 48.0);

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar('Jan', 60, CRMColors.primary, barWidth),
                _buildBar('Feb', 90, CRMColors.primary.withOpacity(0.7), barWidth),
                _buildBar('Mar', 120, CRMColors.primary, barWidth),
                _buildBar('Apr', 75, CRMColors.primary.withOpacity(0.7), barWidth),
                _buildBar('May', 150, CRMColors.success, barWidth),
                _buildBar('Jun', 180, CRMColors.success, barWidth),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBar(String label, double height, Color color, double width) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(CRMBorderRadius.xs),
              topRight: Radius.circular(CRMBorderRadius.xs),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ]
          ),
        ),
        const SizedBox(height: CRMSpacing.s),
        Text(
          label, 
          style: CRMTypography.caption.copyWith(
            color: CRMColors.textSecondaryOf(context),
            fontWeight: FontWeight.w500
          )
        ),
      ],
    );
  }

  Widget _buildRecentProperties(List<RecentProperty> properties) {
    return CRMCard(
      title: 'Recent Properties',
      subtitle: 'Latest listings registered in the CRM platform',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.s),
        child: properties.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No listings found.')))
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(CRMColors.backgroundOf(context).withOpacity(0.5)),
                    horizontalMargin: CRMSpacing.m,
                    columnSpacing: CRMSpacing.l,
                    headingRowHeight: 44,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 52,
                    columns: [
                      DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold, color: CRMColors.textOf(context)))),
                      DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold, color: CRMColors.textOf(context)))),
                      DataColumn(label: Text('Area', style: TextStyle(fontWeight: FontWeight.bold, color: CRMColors.textOf(context)))),
                      DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold, color: CRMColors.textOf(context)))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: CRMColors.textOf(context)))),
                    ],
                    rows: properties.map((p) {
                      return DataRow(
                        cells: [
                          DataCell(Text(p.code, style: TextStyle(fontWeight: FontWeight.bold, color: CRMColors.primary))),
                          DataCell(Text(p.title, style: TextStyle(color: CRMColors.textOf(context)))),
                          DataCell(Text(p.areaName, style: TextStyle(color: CRMColors.textSecondaryOf(context)))),
                          DataCell(Text('₹${p.price.toStringAsFixed(0)}', style: TextStyle(color: CRMColors.textOf(context), fontWeight: FontWeight.w600))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: p.status.toLowerCase() == 'available' 
                                    ? CRMColors.success.withOpacity(0.1) 
                                    : CRMColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                              ),
                              child: Text(
                                p.status, 
                                style: TextStyle(
                                  color: p.status.toLowerCase() == 'available' ? CRMColors.success : CRMColors.warning,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold
                                )
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRecentActivities(List<RecentActivity> activities) {
    return CRMCard(
      title: 'Recent Audit Activities',
      subtitle: 'Trace logs of structural edits inside CRM database',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.m),
        child: activities.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No activity logs.')))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: CRMSpacing.s),
                    padding: const EdgeInsets.all(CRMSpacing.m),
                    decoration: BoxDecoration(
                      color: CRMColors.backgroundOf(context).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, color: CRMColors.primary, size: 20),
                        const SizedBox(width: CRMSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.description, 
                                style: CRMTypography.bodyMedium.copyWith(
                                  color: CRMColors.textOf(context),
                                  fontWeight: FontWeight.w500
                                )
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'User: ${activity.user} | ${activity.timestamp}',
                                style: CRMTypography.caption.copyWith(color: CRMColors.textMutedOf(context)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildPerformanceBlock() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        double childAspectRatio = 2.2;
        
        if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
          childAspectRatio = 1.4;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 2;
          childAspectRatio = 1.8;
        }

        return CRMCard(
          title: 'Agency CRM Performance metrics',
          subtitle: 'Real-time performance metrics tracking brokers and regions',
          child: Padding(
            padding: const EdgeInsets.only(top: CRMSpacing.m),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: CRMSpacing.m,
              mainAxisSpacing: CRMSpacing.m,
              childAspectRatio: childAspectRatio,
              children: [
                _buildPerformanceCard('Top Broker', 'System Administrator', Icons.stars_rounded),
                _buildPerformanceCard('Top Area', 'Prahladnagar', Icons.location_on_rounded),
                _buildPerformanceCard('Top Property', 'PR-1001', Icons.home_rounded),
                _buildPerformanceCard('Monthly Growth', '+24.5%', Icons.trending_up_rounded),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerformanceCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.backgroundOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        border: Border.all(color: CRMColors.backgroundOf(context).withOpacity(0.8)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: CRMColors.primary.withOpacity(0.1),
            radius: 18,
            child: Icon(icon, color: CRMColors.primary, size: 20),
          ),
          const SizedBox(width: CRMSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label, 
                  style: CRMTypography.caption.copyWith(
                    color: CRMColors.textSecondaryOf(context),
                    fontWeight: FontWeight.w500
                  )
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: CRMTypography.bodyMedium.copyWith(
                    color: CRMColors.textOf(context), 
                    fontWeight: FontWeight.bold
                  ),
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
            const Icon(Icons.error_outline_rounded, color: CRMColors.danger, size: 54),
            const SizedBox(height: CRMSpacing.m),
            Text(
              'Failed to Load Dashboard', 
              style: CRMTypography.sectionTitle.copyWith(
                color: CRMColors.textOf(context),
                fontWeight: FontWeight.bold
              )
            ),
            const SizedBox(height: CRMSpacing.xs),
            Text(message, style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)), textAlign: TextAlign.center),
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