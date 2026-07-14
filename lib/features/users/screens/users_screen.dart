import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/users_bloc.dart';
import '../models/user_model.dart';
import '../../auth/bloc/auth_bloc.dart';

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
        // We get roles from the state of UsersBloc
        final usersState = context.read<UsersBloc>().state;
        List<RoleModel> roles = [];
        if (usersState is UsersLoaded) {
          roles = usersState.roles;
        }

        // Set default role if none selected
        if (localSelectedRoleId == null && roles.isNotEmpty) {
          localSelectedRoleId = roles.first.id;
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1B4B), // Indigo 950
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEditing ? "Edit User Account" : "Add User Account",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Full Name
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration("Full Name", Icons.person_rounded),
                        validator: (val) => val == null || val.trim().isEmpty ? "Full name required" : null,
                      ),
                      const SizedBox(height: 16),

                      // Email Address
                      TextFormField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.white),
                        enabled: !isEditing, // Disable email edits
                        decoration: _buildInputDecoration("Email Address", Icons.email_rounded),
                        validator: (val) => val == null || val.trim().isEmpty ? "Email required" : null,
                      ),
                      const SizedBox(height: 16),

                      // Mobile Phone
                      TextFormField(
                        controller: mobileController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration("Phone Number", Icons.phone_rounded),
                      ),
                      const SizedBox(height: 16),

                      // Password (required for add, optional for edit)
                      TextFormField(
                        controller: passwordController,
                        style: const TextStyle(color: Colors.white),
                        obscureText: true,
                        decoration: _buildInputDecoration(
                          isEditing ? "New Password (Optional)" : "Password",
                          Icons.lock_rounded,
                        ),
                        validator: (val) {
                          if (!isEditing && (val == null || val.isEmpty)) {
                            return "Password required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Role Select Dropdown
                      if (roles.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: localSelectedRoleId,
                          dropdownColor: const Color(0xFF1E1B4B),
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration("System Role", Icons.admin_panel_settings_rounded),
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
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel", style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(isEditing ? "Save Changes" : "Create Account"),
                ),
              ],
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
          backgroundColor: const Color(0xFF1E1B4B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Confirm Deletion", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            "Are you sure you want to delete ${user.fullName}? This operation will perform a soft delete.",
            style: const TextStyle(color: Color(0xFFCBD5E1)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel", style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<UsersBloc>().add(DeleteUserRequested(id: user.id));
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      labelText: hint,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, color: Colors.indigoAccent),
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.indigoAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    bool hasAccess = false;
    if (authState is Authenticated) {
      hasAccess = authState.user.permissions.contains("users.read");
    }

    if (!hasAccess) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Access Denied"),
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 72),
                const SizedBox(height: 20),
                const Text(
                  "403 - Forbidden",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  "You do not have permission to view this page.",
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text("Back to Dashboard"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "User Management",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
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
        child: BlocListener<UsersBloc, UsersState>(
          listener: (context, state) {
            if (state is UsersOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.teal.shade800,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _triggerFetch(); // Reload users after success operations
            } else if (state is UsersError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Error: ${state.message}"),
                  backgroundColor: Colors.red.shade800,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search and Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by name, email, or phone...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.indigoAccent),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _searchController.clear();
                            _triggerFetch();
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.indigoAccent, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (val) => _triggerFetch(),
                    ),
                    const SizedBox(height: 12),

                    // Filter chips row
                    BlocBuilder<UsersBloc, UsersState>(
                      builder: (context, state) {
                        List<RoleModel> roles = [];
                        if (state is UsersLoaded) {
                          roles = state.roles;
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Role Dropdown Filter
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String?>(
                                    value: _selectedRoleId,
                                    hint: const Text("Filter by Role", style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
                                    dropdownColor: const Color(0xFF1E1B4B),
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text("All Roles"),
                                      ),
                                      ...roles.map((r) {
                                        return DropdownMenuItem<String?>(
                                          value: r.id,
                                          child: Text(r.name),
                                        );
                                      }),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedRoleId = val;
                                      });
                                      _triggerFetch();
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Status chips
                              ...["All", "Active", "Inactive"].map((status) {
                                final isSelected = _selectedStatus == status;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: FilterChip(
                                    label: Text(status, style: const TextStyle(fontSize: 12)),
                                    selected: isSelected,
                                    selectedColor: Colors.indigoAccent.withOpacity(0.2),
                                    checkmarkColor: Colors.indigoAccent,
                                    backgroundColor: Colors.white.withOpacity(0.03),
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    side: BorderSide(
                                      color: isSelected ? Colors.indigoAccent : Colors.white.withOpacity(0.08),
                                    ),
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedStatus = status;
                                      });
                                      _triggerFetch();
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Users List Display
              Expanded(
                child: BlocBuilder<UsersBloc, UsersState>(
                  builder: (context, state) {
                    if (state is UsersLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is UsersError) {
                      return _buildErrorState(state.message);
                    } else if (state is UsersLoaded) {
                      final users = state.users;
                      if (users.isEmpty) {
                        return const Center(
                          child: Text(
                            "No users found matching query.",
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final isAdmin = user.roleName.toLowerCase() == 'admin';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: Colors.white.withOpacity(0.04),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.white.withOpacity(0.06)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              leading: CircleAvatar(
                                backgroundColor: isAdmin ? Colors.blueAccent.withOpacity(0.2) : Colors.orangeAccent.withOpacity(0.2),
                                radius: 24,
                                child: Icon(
                                  isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                                  color: isAdmin ? Colors.blueAccent : Colors.orangeAccent,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user.fullName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isAdmin ? Colors.blueAccent.withOpacity(0.12) : Colors.orangeAccent.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      user.roleName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isAdmin ? Colors.blueAccent : Colors.orangeAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.email_rounded, size: 13, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 6),
                                      Text(user.email, style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
                                    ],
                                  ),
                                  if (user.mobile != null && user.mobile!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_rounded, size: 13, color: Color(0xFF94A3B8)),
                                        const SizedBox(width: 6),
                                        Text(user.mobile!, style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Active Switch
                                  Switch(
                                    value: user.isActive,
                                    activeColor: Colors.indigoAccent,
                                    onChanged: (val) {
                                      context.read<UsersBloc>().add(
                                            ToggleUserStatusRequested(id: user.id, isActive: val),
                                          );
                                    },
                                  ),
                                  // Edit Button
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: Colors.indigoAccent, size: 20),
                                    onPressed: () => _showAddEditUserDialog(user),
                                  ),
                                  // Delete Button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () => _showDeleteConfirmDialog(user),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditUserDialog(),
        backgroundColor: Colors.indigoAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          const Text("Error Loading Users", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(message, style: const TextStyle(color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _triggerFetch,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}
