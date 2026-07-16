import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/users_bloc.dart';
import '../models/user_model.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/data_table.dart';
import '../../../core/design_system/widgets/inputs.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRoleId;
  String _selectedStatus = "All";

  @override
  void initState() {
    super.initState();
    _triggerFetch();
  }

  void _triggerFetch() {
    context.read<UsersBloc>().add(
          FetchUsers(
            search: _searchController.text.trim(),
            roleId: _selectedRoleId,
            status: _selectedStatus,
          ),
        );
  }

  void _showAddEditUserDialog([UserModel? user]) {
    final isEditing = user != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: user?.fullName);
    final emailController = TextEditingController(text: user?.email);
    final mobileController = TextEditingController(text: user?.mobile);
    final passwordController = TextEditingController();

    String? localSelectedRoleId = user?.roleId;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final usersState = context.read<UsersBloc>().state;
        List<RoleModel> roles = [];
        if (usersState is UsersLoaded) {
          roles = usersState.roles;
        }

        if (localSelectedRoleId == null && roles.isNotEmpty) {
          localSelectedRoleId = roles.first.id;
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: CRMColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CRMBorderRadius.m),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.all(CRMSpacing.l),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? "Edit User Account" : "Add User Account",
                            style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text),
                          ),
                          const SizedBox(height: CRMSpacing.xs),
                          Text(
                            isEditing ? "Modify the system credentials and role permissions." : "Create new employee logins for the NB Realty system.",
                            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                          ),
                          const SizedBox(height: CRMSpacing.l),
                          
                          // Full Name Input
                          CRMTextField(
                            controller: nameController,
                            labelText: 'Full Name *',
                            hintText: 'Enter complete name',
                            prefixIcon: Icons.person_rounded,
                            validator: (val) => val == null || val.trim().isEmpty ? "Full name required" : null,
                          ),
                          const SizedBox(height: CRMSpacing.m),

                          // Email Input
                          CRMTextField(
                            controller: emailController,
                            labelText: 'Email Address *',
                            hintText: 'user@nbrealty.com',
                            prefixIcon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) => val == null || val.trim().isEmpty ? "Email required" : null,
                          ),
                          const SizedBox(height: CRMSpacing.m),

                          // Mobile Phone
                          CRMTextField(
                            controller: mobileController,
                            labelText: 'Phone Number',
                            hintText: '+91 XXXXX XXXXX',
                            prefixIcon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: CRMSpacing.m),

                          // Password
                          CRMTextField(
                            controller: passwordController,
                            labelText: isEditing ? "New Password (Optional)" : "Password *",
                            hintText: 'Min 6 characters',
                            prefixIcon: Icons.lock_rounded,
                            obscureText: true,
                            validator: (val) {
                              if (!isEditing && (val == null || val.isEmpty)) {
                                return "Password required";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: CRMSpacing.m),

                          // Role Selector
                          if (roles.isNotEmpty) ...[
                            Text(
                              'System Role *',
                              style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondary),
                            ),
                            const SizedBox(height: CRMSpacing.xs),
                            DropdownButtonFormField<String>(
                              value: localSelectedRoleId,
                              dropdownColor: CRMColors.cardBg,
                              style: CRMTypography.body.copyWith(color: CRMColors.text),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.admin_panel_settings_rounded, color: CRMColors.textMuted),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: CRMSpacing.m,
                                  vertical: CRMSpacing.s,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                                  borderSide: BorderSide(color: CRMColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                                  borderSide: BorderSide(color: CRMColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                                  borderSide: BorderSide(color: CRMColors.primary, width: 1.5),
                                ),
                              ),
                              items: roles.map((r) {
                                return DropdownMenuItem<String>(
                                  value: r.id,
                                  child: Text(r.name),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  localSelectedRoleId = val;
                                });
                              },
                            ),
                          ],
                          const SizedBox(height: CRMSpacing.xl),
                          
                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              CRMButton(
                                label: 'Cancel',
                                variant: CRMButtonVariant.outline,
                                onPressed: () => Navigator.pop(dialogContext),
                              ),
                              const SizedBox(width: CRMSpacing.s),
                              CRMButton(
                                label: isEditing ? 'Save Changes' : 'Create Account',
                                onPressed: () {
                                  if (formKey.currentState?.validate() ?? false) {
                                    final userData = {
                                      'full_name': nameController.text.trim(),
                                      'email': emailController.text.trim(),
                                      'mobile': mobileController.text.trim(),
                                      'role_id': localSelectedRoleId,
                                    };

                                    if (passwordController.text.isNotEmpty) {
                                      userData['password'] = passwordController.text;
                                    }

                                    if (isEditing) {
                                      context.read<UsersBloc>().add(
                                            UpdateUserRequested(id: user.id, userData: userData),
                                          );
                                    } else {
                                      context.read<UsersBloc>().add(
                                            CreateUserRequested(userData: userData),
                                          );
                                    }

                                    Navigator.pop(dialogContext);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: CRMColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.m),
          ),
          title: Text(
            "Confirm Deletion",
            style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text),
          ),
          content: Text(
            "Are you sure you want to delete ${user.fullName}? This operation will perform a soft delete.",
            style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
          ),
          actions: [
            CRMButton(
              label: "Cancel",
              variant: CRMButtonVariant.outline,
              onPressed: () => Navigator.pop(dialogContext),
            ),
            const SizedBox(width: CRMSpacing.xs),
            CRMButton(
              label: "Delete",
              variant: CRMButtonVariant.danger,
              onPressed: () {
                context.read<UsersBloc>().add(DeleteUserRequested(id: user.id));
                Navigator.pop(dialogContext);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    final authState = context.watch<AuthBloc>().state;
    bool hasAccess = false;
    if (authState is Authenticated) {
      hasAccess = authState.user.permissions.contains("users.read");
    }

    if (!hasAccess) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(CRMSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad_rounded, color: CRMColors.danger, size: 72),
                const SizedBox(height: CRMSpacing.m),
                Text(
                  "403 - Forbidden",
                  style: CRMTypography.pageTitle.copyWith(color: CRMColors.text),
                ),
                const SizedBox(height: CRMSpacing.xs),
                Text(
                  "You do not have permission to view this page.",
                  style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
                ),
                const SizedBox(height: CRMSpacing.xl),
                CRMButton(
                  label: "Back to Dashboard",
                  onPressed: () => Navigator.maybePop(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocListener<UsersBloc, UsersState>(
        listener: (context, state) {
          if (state is UsersOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: CRMColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _triggerFetch();
          } else if (state is UsersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error: ${state.message}"),
                backgroundColor: CRMColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? CRMSpacing.m : CRMSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Row
              _buildPageHeader(),
              const SizedBox(height: CRMSpacing.l),

              // 2. Statistics Overview Cards
              _buildStatisticsRow(),
              const SizedBox(height: CRMSpacing.l),

              // 3. Search and Filters Card
              _buildSearchAndFiltersCard(),
              const SizedBox(height: CRMSpacing.l),

              // 4. Employees Data Table
              _buildEmployeesTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "User Management",
          style: CRMTypography.pageTitle.copyWith(
            color: CRMColors.text,
            fontSize: isMobile ? 22 : 28,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          "Configure workspace permissions, logins, and enterprise roles",
          style: CRMTypography.body.copyWith(
            color: CRMColors.textSecondary,
            fontSize: isMobile ? 13 : 14,
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textColumn,
          const SizedBox(height: CRMSpacing.m),
          SizedBox(
            width: double.infinity,
            child: CRMButton(
              label: "Add Employee",
              prefixIcon: Icons.add_rounded,
              onPressed: () => _showAddEditUserDialog(),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: textColumn),
        const SizedBox(width: CRMSpacing.m),
        CRMButton(
          label: "Add Employee",
          prefixIcon: Icons.add_rounded,
          onPressed: () => _showAddEditUserDialog(),
        ),
      ],
    );
  }

  Widget _buildStatisticsRow() {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        int total = 0;
        int active = 0;
        int admins = 0;

        if (state is UsersLoaded) {
          total = state.users.length;
          active = state.users.where((u) => u.isActive).length;
          admins = state.users.where((u) => u.roleName.toLowerCase() == 'admin').length;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            double mobileRatio = 1.35;
            if (!isWide) {
              final double cardWidth = (constraints.maxWidth - CRMSpacing.m) / 2;
              if (cardWidth < 150) {
                mobileRatio = 1.1;
              } else if (cardWidth < 180) {
                mobileRatio = 1.25;
              }
            }

            return GridView.count(
              crossAxisCount: isWide ? 3 : 2,
              crossAxisSpacing: CRMSpacing.m,
              mainAxisSpacing: CRMSpacing.m,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isWide ? 2.5 : mobileRatio,
              children: [
                CRMKPICard(
                  title: "TOTAL EMPLOYEES",
                  value: total.toString(),
                  icon: Icons.people_rounded,
                  iconColor: CRMColors.primary,
                ),
                CRMKPICard(
                  title: "ACTIVE SYSTEM USERS",
                  value: active.toString(),
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: CRMColors.success,
                ),
                CRMKPICard(
                  title: "ADMINISTRATORS",
                  value: admins.toString(),
                  icon: Icons.admin_panel_settings_rounded,
                  iconColor: CRMColors.info,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSearchAndFiltersCard() {
    return CRMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Search input
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: CRMTypography.body.copyWith(color: CRMColors.text),
                  decoration: InputDecoration(
                    hintText: 'Search by employee name, email, phone number...',
                    hintStyle: CRMTypography.body.copyWith(color: CRMColors.textMuted),
                    prefixIcon: Icon(Icons.search_rounded, color: CRMColors.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: CRMColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              _triggerFetch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: CRMColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: CRMSpacing.m,
                      vertical: CRMSpacing.s,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      borderSide: BorderSide(color: CRMColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      borderSide: BorderSide(color: CRMColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      borderSide: BorderSide(color: CRMColors.primary, width: 1.5),
                    ),
                  ),
                  onChanged: (val) => _triggerFetch(),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              CRMButton(
                label: "Search",
                onPressed: _triggerFetch,
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          
          // Role & Status Dropdown Row
          BlocBuilder<UsersBloc, UsersState>(
            builder: (context, state) {
              List<RoleModel> roles = [];
              if (state is UsersLoaded) {
                roles = state.roles;
              }

              return Wrap(
                spacing: CRMSpacing.m,
                runSpacing: CRMSpacing.s,
                children: [
                  // Role Filter
                  _buildDropdown(
                    label: 'Filter by Role',
                    value: _selectedRoleId,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text("All Roles"),
                      ),
                      ...roles.map((r) => DropdownMenuItem<String?>(
                            value: r.id,
                            child: Text(r.name),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedRoleId = val;
                      });
                      _triggerFetch();
                    },
                  ),
                  
                  // Status Filter
                  _buildDropdown(
                    label: 'Filter by Status',
                    value: _selectedStatus,
                    items: ["All", "Active", "Inactive"].map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedStatus = val ?? "All";
                      });
                      _triggerFetch();
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 200,
      height: 44,
      child: DropdownButtonFormField<T>(
        value: value,
        dropdownColor: CRMColors.cardBg,
        style: CRMTypography.body.copyWith(color: CRMColors.text),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: CRMSpacing.m,
            vertical: 4,
          ),
          filled: true,
          fillColor: CRMColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            borderSide: BorderSide(color: CRMColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            borderSide: BorderSide(color: CRMColors.border),
          ),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildEmployeesTable() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        final isLoading = state is UsersLoading || state is UsersInitial;
        List<UserModel> users = [];

        if (state is UsersLoaded) {
          users = state.users;
        }

        if (isLoading) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }

        if (users.isEmpty) {
          return CRMCard(
            child: Padding(
              padding: const EdgeInsets.all(CRMSpacing.xl),
              child: Column(
                children: [
                  Text('No Employees Found', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text)),
                  const SizedBox(height: CRMSpacing.s),
                  Text('Try adjusting your filters or add a new employee profile.', style: CRMTypography.body.copyWith(color: CRMColors.textSecondary)),
                ],
              ),
            ),
          );
        }

        if (isMobile) {
          return Column(
            children: users.map((user) => _buildMobileUserCard(user)).toList(),
          );
        }

        return CRMDataTable(
          isLoading: isLoading,
          emptyTitle: 'No Employees Found',
          emptyDescription: 'Try adjusting your filters or add a new employee profile.',
          columns: const [
            DataColumn(label: Text('Full Name')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Email Address')),
            DataColumn(label: Text('Mobile')),
            DataColumn(label: Text('Active Logins')),
            DataColumn(label: Text('Actions')),
          ],
          rows: users.map((user) {
            final isAdmin = user.roleName.toLowerCase() == 'admin';

            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isAdmin
                            ? CRMColors.info.withOpacity(0.1)
                            : CRMColors.primary.withOpacity(0.1),
                        radius: 16,
                        child: Icon(
                          isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                          color: isAdmin ? CRMColors.info : CRMColors.primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.s),
                      Text(
                        user.fullName,
                        style: CRMTypography.bodyMedium.copyWith(color: CRMColors.text),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: CRMSpacing.xxs),
                    decoration: BoxDecoration(
                      color: isAdmin ? CRMColors.info.withOpacity(0.12) : CRMColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                    ),
                    child: Text(
                      user.roleName,
                      style: CRMTypography.captionBold.copyWith(
                        color: isAdmin ? CRMColors.info : CRMColors.primary,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(user.email, style: CRMTypography.body.copyWith(color: CRMColors.textSecondary))),
                DataCell(Text(user.mobile ?? '-', style: CRMTypography.body.copyWith(color: CRMColors.textSecondary))),
                DataCell(
                  Switch(
                    value: user.isActive,
                    activeColor: CRMColors.primary,
                    onChanged: (val) {
                      context.read<UsersBloc>().add(
                            ToggleUserStatusRequested(id: user.id, isActive: val),
                          );
                    },
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: CRMColors.primary, size: 18),
                        onPressed: () => _showAddEditUserDialog(user),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 18),
                        onPressed: () => _showDeleteConfirmDialog(user),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMobileUserCard(UserModel user) {
    final isAdmin = user.roleName.toLowerCase() == 'admin';

    return Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.s),
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.m),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isAdmin
                    ? CRMColors.info.withOpacity(0.1)
                    : CRMColors.primary.withOpacity(0.1),
                radius: 18,
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                  color: isAdmin ? CRMColors.info : CRMColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: CRMTypography.bodyMedium.copyWith(
                        color: CRMColors.textOf(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: CRMSpacing.xxs),
                decoration: BoxDecoration(
                  color: isAdmin ? CRMColors.info.withOpacity(0.12) : CRMColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                ),
                child: Text(
                  user.roleName,
                  style: CRMTypography.captionBold.copyWith(
                    color: isAdmin ? CRMColors.info : CRMColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          Divider(color: CRMColors.borderOf(context).withOpacity(0.5), height: 1),
          const SizedBox(height: CRMSpacing.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.phone_rounded, size: 16, color: CRMColors.textMutedOf(context)),
                  const SizedBox(width: 6),
                  Text(
                    user.mobile ?? '-',
                    style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Active Login',
                    style: CRMTypography.body.copyWith(
                      color: CRMColors.textSecondaryOf(context),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: CRMSpacing.xs),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: user.isActive,
                      activeColor: CRMColors.primary,
                      onChanged: (val) {
                        context.read<UsersBloc>().add(
                              ToggleUserStatusRequested(id: user.id, isActive: val),
                            );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.s),
          Divider(color: CRMColors.borderOf(context).withOpacity(0.5), height: 1),
          const SizedBox(height: CRMSpacing.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showAddEditUserDialog(user),
                icon: Icon(Icons.edit_outlined, color: CRMColors.primary, size: 16),
                label: Text(
                  'Edit',
                  style: TextStyle(color: CRMColors.primary),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              TextButton.icon(
                onPressed: () => _showDeleteConfirmDialog(user),
                icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 16),
                label: Text(
                  'Delete',
                  style: TextStyle(color: CRMColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
