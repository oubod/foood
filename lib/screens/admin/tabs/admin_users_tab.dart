import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme.dart';
import '../../../services/admin_service.dart';
import '../../../models/admin_statistics.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  String _searchQuery = '';
  String _selectedRole = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminService>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminService>().fetchUsers();
            },
          ),
        ],
      ),
      body: Consumer<AdminService>(
        builder: (context, adminService, child) {
          if (adminService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminService.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    adminService.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.m),
                  ElevatedButton(
                    onPressed: () {
                      adminService.clearError();
                      adminService.fetchUsers();
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final filteredUsers = _filterUsers(adminService.users);

          return Column(
            children: [
              _buildFilters(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => adminService.fetchUsers(),
                  child: filteredUsers.isEmpty
                      ? const Center(
                          child: Text('لا توجد مستخدمين'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppConstants.s),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return _buildUserCard(user, adminService);
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.m),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'البحث عن مستخدم...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: AppConstants.s),
          Row(
            children: [
              const Text('تصفية حسب الدور: '),
              const SizedBox(width: AppConstants.s),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedRole,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('الكل')),
                    DropdownMenuItem(value: 'admin', child: Text('مدير')),
                    DropdownMenuItem(value: 'owner', child: Text('صاحب مطعم')),
                    DropdownMenuItem(value: 'customer', child: Text('عميل')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<AdminUser> _filterUsers(List<AdminUser> users) {
    return users.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (user.fullName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesRole = _selectedRole == 'all' ||
          (user.role == _selectedRole) ||
          (_selectedRole == 'customer' && user.role == null);

      return matchesSearch && matchesRole;
    }).toList();
  }

  Widget _buildUserCard(AdminUser user, AdminService adminService) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppConstants.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(user.role),
                  child: Icon(
                    _getRoleIcon(user.role),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppConstants.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName ?? 'غير محدد',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (user.phone != null)
                        Text(
                          user.phone!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                if (user.isSuspended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.s,
                      vertical: AppConstants.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'معلق',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.s),
            Row(
              children: [
                _buildInfoChip('الدور: ${_getRoleText(user.role)}'),
                const SizedBox(width: AppConstants.s),
                _buildInfoChip(
                  'الإيميل: ${user.emailConfirmedAt != null ? "مؤكد" : "غير مؤكد"}',
                  color: user.emailConfirmedAt != null ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.s),
            Row(
              children: [
                _buildInfoChip('تاريخ التسجيل: ${_formatDate(user.createdAt)}'),
                if (user.lastSignInAt != null) ...[
                  const SizedBox(width: AppConstants.s),
                  _buildInfoChip('آخر دخول: ${_formatDate(user.lastSignInAt!)}'),
                ],
              ],
            ),
            if (user.isSuspended && user.suspendedReason != null) ...[
              const SizedBox(height: AppConstants.s),
              Container(
                padding: const EdgeInsets.all(AppConstants.s),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: AppConstants.s),
                    Expanded(
                      child: Text(
                        'سبب التعليق: ${user.suspendedReason}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppConstants.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (user.isSuspended)
                  TextButton.icon(
                    onPressed: () => _activateUser(user, adminService),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('تفعيل'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () => _showSuspendDialog(user, adminService),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('تعليق'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                const SizedBox(width: AppConstants.s),
                TextButton.icon(
                  onPressed: () => _showUserDetails(user),
                  icon: const Icon(Icons.info, size: 16),
                  label: const Text('التفاصيل'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.s,
        vertical: AppConstants.xs,
      ),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (color ?? Colors.blue).withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? Colors.blue,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'owner':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'owner':
        return Icons.restaurant;
      default:
        return Icons.person;
    }
  }

  String _getRoleText(String? role) {
    switch (role) {
      case 'admin':
        return 'مدير';
      case 'owner':
        return 'صاحب مطعم';
      default:
        return 'عميل';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _activateUser(AdminUser user, AdminService adminService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفعيل المستخدم'),
        content: Text('هل أنت متأكد من تفعيل ${user.fullName ?? user.email}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              adminService.activateUser(user.id);
            },
            child: const Text('تفعيل'),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog(AdminUser user, AdminService adminService) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعليق المستخدم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل أنت متأكد من تعليق ${user.fullName ?? user.email}؟'),
            const SizedBox(height: AppConstants.m),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب التعليق',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              adminService.suspendUser(
                user.id,
                reasonController.text.isNotEmpty 
                    ? reasonController.text 
                    : 'لم يتم تحديد السبب',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تعليق'),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.fullName ?? 'تفاصيل المستخدم'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('الإيميل', user.email),
              _buildDetailRow('الاسم الكامل', user.fullName ?? 'غير محدد'),
              _buildDetailRow('رقم الهاتف', user.phone ?? 'غير محدد'),
              _buildDetailRow('الدور', _getRoleText(user.role)),
              _buildDetailRow('حالة الحساب', user.isSuspended ? 'معلق' : 'نشط'),
              _buildDetailRow('تاريخ التسجيل', _formatDate(user.createdAt)),
              if (user.lastSignInAt != null)
                _buildDetailRow('آخر دخول', _formatDate(user.lastSignInAt!)),
              _buildDetailRow(
                'حالة الإيميل', 
                user.emailConfirmedAt != null ? 'مؤكد' : 'غير مؤكد'
              ),
              if (user.isSuspended && user.suspendedReason != null)
                _buildDetailRow('سبب التعليق', user.suspendedReason!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}