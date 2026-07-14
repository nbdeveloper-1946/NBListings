import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../models/dashboard_summary.dart';
import '../widgets/activity_tile.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/statistic_card.dart';
import '../../users/screens/users_screen.dart';
import '../../properties/bloc/properties_bloc.dart';
import '../../properties/screens/properties_screen.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userEmail = 'admin@nbdeveloper.com';
    List<String> permissions = [];
    if (authState is Authenticated) {
      userEmail = authState.user.email;
      permissions = authState.user.permissions;
    }

    final dateString = "13 July 2026"; // Mock date matching prompt

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000;
        final isTablet = constraints.maxWidth >= 650 && constraints.maxWidth < 1000;

        Widget mainContent = BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading || state is DashboardInitial) {
              return _buildSkeletonLoader(isDesktop, isTablet);
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
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DashboardHeader(
                        email: userEmail,
                        dateString: dateString,
                      ),
                      const SizedBox(height: 24),

                      // Statistics Grid
                      _buildStatisticsGrid(data.summary, isDesktop, isTablet),
                      const SizedBox(height: 24),

                      // Quick Actions
                      _buildQuickActions(),
                      const SizedBox(height: 24),

                      // Activity Timeline & Recent Properties Split Layout
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildRecentPropertiesTable(data.recentProperties),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: _buildRecentActivitiesList(data.activity),
                            ),
                          ],
                        )
                      else ...[
                        _buildRecentPropertiesTable(data.recentProperties),
                        const SizedBox(height: 24),
                        _buildRecentActivitiesList(data.activity),
                      ],
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        );

        // Sidebar Layout for Desktop
        if (isDesktop) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F172A), // Slate 900
                    Color(0xFF1E1B4B), // Indigo 950
                  ],
                ),
              ),
              child: Row(
                children: [
                  _buildSidebar(context, userEmail, permissions, isDrawer: false),
                  Expanded(
                    child: Scaffold(
                      backgroundColor: Colors.transparent,
                      body: mainContent,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Standard Drawer Layout for Mobile/Tablet
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'NB Listings Control Center',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
          ),
          drawer: _buildSidebar(context, userEmail, permissions, isDrawer: true),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E1B4B),
                ],
              ),
            ),
            child: mainContent,
          ),
        );
      },
    );
  }

  // Sidebar implementation
  Widget _buildSidebar(BuildContext context, String email, List<String> permissions, {required bool isDrawer}) {
    final listContent = ListView(
      padding: EdgeInsets.zero,
      children: [
        if (isDrawer)
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1E1B4B)),
            accountName: const Text("Administrator", style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(email),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.indigoAccent,
              child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 36),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigoAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.blur_on_rounded, color: Colors.indigoAccent, size: 28),
                ),
                const SizedBox(width: 12),
                const Text(
                  'NB Listings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        _buildSidebarTile(Icons.dashboard_rounded, "Dashboard", isSelected: true),
        _buildSidebarTile(Icons.home_work_rounded, "Properties", onTap: () {
          if (isDrawer) {
            Navigator.pop(context);
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => PropertiesBloc(),
                child: const PropertiesScreen(),
              ),
            ),
          );
        }),
        _buildSidebarTile(Icons.assignment_turned_in_rounded, "Requirements", onTap: () => _showActionSnackbar("Requirements")),
        if (permissions.contains("users.read"))
          _buildSidebarTile(Icons.people_rounded, "Users", onTap: () {
            if (isDrawer) {
              Navigator.pop(context);
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UsersScreen()),
            );
          }),
        _buildSidebarTile(Icons.settings_rounded, "Settings", onTap: () => _showActionSnackbar("Settings")),
        const Divider(color: Colors.white10, height: 40),
        ListTile(
          leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
          onTap: () {
            context.read<AuthBloc>().add(LogoutRequested());
          },
        ),
      ],
    );

    if (isDrawer) {
      return Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: listContent,
      );
    }

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.5),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: listContent,
    );
  }

  Widget _buildSidebarTile(IconData icon, String title, {bool isSelected = false, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.indigoAccent : const Color(0xFF94A3B8)),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.indigoAccent.withOpacity(0.1),
      onTap: onTap,
    );
  }

  // Statistics responsive calculations
  Widget _buildStatisticsGrid(DashboardSummary summary, bool isDesktop, bool isTablet) {
    int crossAxisCount = 1;
    if (isDesktop) {
      crossAxisCount = 6;
    } else if (isTablet) {
      crossAxisCount = 3;
    }

    final cards = [
      StatisticCard(
        title: "Total Properties",
        value: "${summary.totalProperties}",
        icon: Icons.home_work_rounded,
        color: Colors.blueAccent,
      ),
      StatisticCard(
        title: "Available",
        value: "${summary.available}",
        icon: Icons.check_circle_rounded,
        color: Colors.tealAccent,
      ),
      StatisticCard(
        title: "Sold",
        value: "${summary.sold}",
        icon: Icons.monetization_on_rounded,
        color: Colors.orangeAccent,
      ),
      StatisticCard(
        title: "Rented",
        value: "${summary.rented}",
        icon: Icons.key_rounded,
        color: Colors.purpleAccent,
      ),
      StatisticCard(
        title: "Requirements",
        value: "${summary.requirements}",
        icon: Icons.assignment_turned_in_rounded,
        color: Colors.cyanAccent,
      ),
      StatisticCard(
        title: "Users",
        value: "${summary.users}",
        icon: Icons.people_rounded,
        color: Colors.pinkAccent,
      ),
    ];

    if (crossAxisCount == 1) {
      return Column(children: cards);
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: isDesktop ? 1.6 : 2.0,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: cards,
    );
  }

  // Quick Action Buttons
  Widget _buildQuickActions() {
    return Card(
      color: Colors.white.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Quick Operations",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 6,
              childAspectRatio: 1.1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                QuickActionCard(
                  label: "Property",
                  icon: Icons.add_business_rounded,
                  color: Colors.cyanAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (context) => PropertiesBloc(),
                          child: const PropertiesScreen(),
                        ),
                      ),
                    );
                  },
                ),
                QuickActionCard(
                  label: "Requirement",
                  icon: Icons.add_task_rounded,
                  color: Colors.tealAccent,
                  onTap: () => _showActionSnackbar("Add Requirement"),
                ),
                QuickActionCard(
                  label: "User",
                  icon: Icons.person_add_alt_1_rounded,
                  color: Colors.orangeAccent,
                  onTap: () => _showActionSnackbar("Add User"),
                ),
                QuickActionCard(
                  label: "Import",
                  icon: Icons.upload_file_rounded,
                  color: Colors.purpleAccent,
                  onTap: () => _showActionSnackbar("Import Data"),
                ),
                QuickActionCard(
                  label: "Export",
                  icon: Icons.download_rounded,
                  color: Colors.blueAccent,
                  onTap: () => _showActionSnackbar("Export Data"),
                ),
                QuickActionCard(
                  label: "Reports",
                  icon: Icons.analytics_rounded,
                  color: Colors.pinkAccent,
                  onTap: () => _showActionSnackbar("Generate Reports"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Recent Properties Table View
  Widget _buildRecentPropertiesTable(List<RecentProperty> properties) {
    return Card(
      color: Colors.white.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recent Properties",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            if (properties.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Text(
                    "No Property Records Found",
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text("Code", style: TextStyle(color: Colors.indigoAccent))),
                    DataColumn(label: Text("Title", style: TextStyle(color: Colors.indigoAccent))),
                    DataColumn(label: Text("Area", style: TextStyle(color: Colors.indigoAccent))),
                    DataColumn(label: Text("Price", style: TextStyle(color: Colors.indigoAccent))),
                    DataColumn(label: Text("Status", style: TextStyle(color: Colors.indigoAccent))),
                    DataColumn(label: Text("Created By", style: TextStyle(color: Colors.indigoAccent))),
                  ],
                  rows: properties.map((p) {
                    return DataRow(
                      cells: [
                        DataCell(Text(p.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        DataCell(Text(p.title, style: const TextStyle(color: Colors.white70))),
                        DataCell(Text(p.area, style: const TextStyle(color: Colors.white70))),
                        DataCell(Text("₹${p.price.toStringAsFixed(0)}", style: const TextStyle(color: Colors.tealAccent))),
                        DataCell(Text(p.status, style: const TextStyle(color: Colors.tealAccent))),
                        DataCell(Text(p.createdBy, style: const TextStyle(color: Colors.white70))),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Recent Activity log list
  Widget _buildRecentActivitiesList(List<RecentActivity> activities) {
    return Card(
      color: Colors.white.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recent System Activity",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            if (activities.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Text(
                    "No Activities Logged",
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  return ActivityTile(activity: activities[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Skeleton Loader structure
  Widget _buildSkeletonLoader(bool isDesktop, bool isTablet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 24),
          // Stats Skeleton
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 6 : (isTablet ? 3 : 1),
            childAspectRatio: isDesktop ? 1.6 : 2.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: List.generate(6, (index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          // Operations
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  // Error layout with retry
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            const Text(
              "Failed to Load Dashboard",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<DashboardBloc>().add(LoadDashboard());
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Retry Connection"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
