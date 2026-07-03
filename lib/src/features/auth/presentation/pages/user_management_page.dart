import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/bloc/user_management_bloc.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UserManagementBloc>().add(LoadUsers());
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _UserFormDialog(
        onSave: (email, password, role, permissions) {
          context.read<UserManagementBloc>().add(
            CreateUser(
              email: email,
              password: password,
              role: role,
              permissions: permissions,
            ),
          );
        },
      ),
    );
  }

  void _showEditDialog(User user) {
    showDialog(
      context: context,
      builder: (ctx) => _UserFormDialog(
        user: user,
        onSave: (email, password, role, permissions) {
          context.read<UserManagementBloc>().add(
            UpdateUser(id: user.id, role: role, permissions: permissions),
          );
        },
      ),
    );
  }

  void _confirmDelete(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete ${user.email}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<UserManagementBloc>().add(DeleteUser(id: user.id));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showCreateDialog),
        ],
      ),
      body: BlocBuilder<UserManagementBloc, UserManagementState>(
        builder: (context, state) {
          if (state is UserManagementLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is UsersLoaded) {
            final users = state.users;
            if (users.isEmpty) {
              return const Center(child: Text('No users found.'));
            }
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(user.email[0].toUpperCase()),
                  ),
                  title: Text(user.email),
                  subtitle: Text('Role: ${user.role} | Status: ${user.status}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditDialog(user),
                      ),
                      if (user.role != 'superadmin')
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(user),
                        ),
                    ],
                  ),
                );
              },
            );
          }
          if (state is UserManagementError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: Text('Initializing...'));
        },
      ),
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  final User? user;
  final Function(
    String email,
    String password,
    String role,
    Map<String, bool> permissions,
  )
  onSave;

  const _UserFormDialog({this.user, required this.onSave});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'staff';
  late Map<String, bool> _permissions;

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _permissions = {
      'p_info': widget.user?.permissions['p_info'] ?? false,
      'p_res': widget.user?.permissions['p_res'] ?? false,
      'p_sell': widget.user?.permissions['p_sell'] ?? false,
      'p_snadat': widget.user?.permissions['p_snadat'] ?? false,
      'p_user': widget.user?.permissions['p_user'] ?? false,
      'p_report': widget.user?.permissions['p_report'] ?? false,
      'p_report2': widget.user?.permissions['p_report2'] ?? false,
    };
    if (isEditing) {
      _emailController.text = widget.user!.email;
      _role = widget.user!.role;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit User' : 'Create User'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              if (!isEditing)
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 8) return 'Min 8 chars';
                    return null;
                  },
                ),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: ['superadmin', 'admin', 'staff']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 8),
              const Text(
                'Permissions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._permissionLabels.entries.map(
                (e) => CheckboxListTile(
                  title: Text(e.key),
                  subtitle: Text(e.value),
                  value: _permissions[e.key] ?? false,
                  onChanged: (v) =>
                      setState(() => _permissions[e.key] = v ?? false),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _emailController.text.trim(),
                _passwordController.text,
                _role,
                _permissions,
              );
              Navigator.pop(context);
            }
          },
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}

const Map<String, String> _permissionLabels = {
  'p_info': 'View info (materials, categories, units)',
  'p_res': 'Manage resources (suppliers, purchases)',
  'p_sell': 'Manage sales (customers, invoices)',
  'p_snadat': 'Manage vouchers',
  'p_user': 'Manage users',
  'p_report': 'View reports',
  'p_report2': 'Advanced reports',
};
