import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

class CRMAppShell extends StatefulWidget {
  final Widget child;

  const CRMAppShell({super.key, required this.child});

  @override
  State<CRMAppShell> createState() => _CRMAppShellState();
}

class _CRMAppShellState extends State<CRMAppShell> {
  bool _isSidebarExpanded = true;
  final TextEditingController _searchController = TextEditingController();

  void _handleLogout() {
    context.read<AuthBloc>().add(LogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;
    final isTablet = size.width >= 768 && size.width < 1024;
    final isDesktop = size.width >= 1024;

    final showSidebar = isDesktop || isTablet;
    final sidebarWidth = _isSidebarExpanded ? 260.0 : 78.0;

    return Scaffold(
      backgroundColor: CRMColors.background,
      drawer: isMobile ? Drawer(child: _buildSidebarContent(location, isMobile: true)) : null,
      body: Row(
        children: [
          if (showSidebar)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: sidebarWidth,
              child: Container(
                decoration: const BoxDecoration(
                  color: CRMColors.sidebarBg,
                  border: Border(right: BorderSide(color: CRMColors.border, width: 1.5)),
                ),
                child: _buildSidebarContent(location),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, isMobile),
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isMobile) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: CRMColors.cardBg,
        border: Border(bottom: BorderSide(color: CRMColors.border, width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.l),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: CRMColors.textSecondary),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          else
            IconButton(
              icon: Icon(
                _isSidebarExpanded ? Icons.menu_open_rounded : Icons.menu_rounded,
                color: CRMColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _isSidebarExpanded = !_isSidebarExpanded;
                });
              },
            ),
          const SizedBox(width: CRMSpacing.m),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextField(
                  controller: _searchController,
                  style: CRMTypography.body.copyWith(color: CRMColors.text),
                  decoration: InputDecoration(
                    hintText: 'Search CRM (Properties, Clients, Code)...',
                    hintStyle: CRMTypography.body.copyWith(color: CRMColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: CRMColors.textMuted, size: 20),
                    filled: true,
                    fillColor: CRMColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.xs),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: CRMSpacing.m),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: CRMColors.textSecondary),
            onPressed: () {},
          ),
          const SizedBox(width: CRMSpacing.s),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: CRMColors.primary),
            onPressed: () {},
          ),
          const SizedBox(width: CRMSpacing.s),
          IconButton(
            icon: const Icon(Icons.light_mode_outlined, color: CRMColors.textMuted),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(String currentPath, {bool isMobile = false}) {
    final userState = context.read<AuthBloc>().state;
    String userEmail = 'broker@nbrealty.com';
    String userRole = 'Agent';
    
    if (userState is Authenticated) {
      userEmail = userState.user.email;
      userRole = userState.user.role;
    }

    final displayEmail = _isSidebarExpanded || isMobile ? userEmail : '';
    final displayRole = _isSidebarExpanded || isMobile ? userRole : '';

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(CRMSpacing.l),
            child: Row(
              mainAxisAlignment: (_isSidebarExpanded || isMobile) ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(CRMSpacing.xs),
                  decoration: BoxDecoration(
                    color: CRMColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                  ),
                  child: const Icon(Icons.blur_on_rounded, color: CRMColors.primary, size: 28),
                ),
                if (_isSidebarExpanded || isMobile) ...[
                  const SizedBox(width: CRMSpacing.s),
                  Text(
                    'NB CRM',
                    style: CRMTypography.sectionTitle.copyWith(
                      fontWeight: FontWeight.w900,
                      color: CRMColors.text,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: CRMColors.border, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: CRMSpacing.m, horizontal: CRMSpacing.s),
              children: [
                _buildSidebarItem(context, Icons.dashboard_rounded, 'Dashboard', '/dashboard', currentPath, isMobile),
                _buildSidebarItem(context, Icons.home_work_rounded, 'Properties', '/properties', currentPath, isMobile),
                _buildSidebarItem(context, Icons.assignment_rounded, 'Requirements', '/requirements', currentPath, isMobile),
                _buildSidebarItem(context, Icons.people_rounded, 'Clients', '/clients', currentPath, isMobile),
                _buildSidebarItem(context, Icons.person_pin_rounded, 'Owners', '/owners', currentPath, isMobile),
                _buildSidebarItem(context, Icons.business_rounded, 'Builders', '/builders', currentPath, isMobile),
                _buildSidebarItem(context, Icons.people_outline_rounded, 'Employees', '/users', currentPath, isMobile),
                _buildSidebarItem(context, Icons.monetization_on_rounded, 'Finance', '/finance', currentPath, isMobile),
                _buildSidebarItem(context, Icons.analytics_rounded, 'Reports', '/reports', currentPath, isMobile),
                _buildSidebarItem(context, Icons.settings_rounded, 'Settings', '/settings', currentPath, isMobile),
              ],
            ),
          ),
          const Divider(color: CRMColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.all(CRMSpacing.m),
            child: Row(
              mainAxisAlignment: (_isSidebarExpanded || isMobile) ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: CRMColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.person_outline_rounded, color: CRMColors.primary),
                ),
                if (_isSidebarExpanded || isMobile) ...[
                  const SizedBox(width: CRMSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayEmail,
                          style: CRMTypography.captionBold.copyWith(color: CRMColors.text),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          displayRole,
                          style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: CRMColors.danger),
                    onPressed: _handleLogout,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
    String currentPath,
    bool isMobile,
  ) {
    final isSelected = currentPath == route;
    final isExpanded = _isSidebarExpanded || isMobile;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () {
          if (isMobile) {
            Navigator.pop(context);
          }
          if (currentPath != route) {
            context.go(route);
          }
        },
        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: CRMSpacing.m,
            vertical: CRMSpacing.s,
          ),
          decoration: BoxDecoration(
            color: isSelected ? CRMColors.primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
          ),
          child: Row(
            mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? CRMColors.primary : CRMColors.textSecondary,
                size: 20,
              ),
              if (isExpanded) ...[
                const SizedBox(width: CRMSpacing.m),
                Text(
                  label,
                  style: CRMTypography.bodyMedium.copyWith(
                    color: isSelected ? CRMColors.primary : CRMColors.text,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
