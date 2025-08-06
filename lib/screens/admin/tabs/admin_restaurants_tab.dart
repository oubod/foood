import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme.dart';
import '../../../services/admin_service.dart';
import '../../../models/admin_statistics.dart';

class AdminRestaurantsTab extends StatefulWidget {
  const AdminRestaurantsTab({super.key});

  @override
  State<AdminRestaurantsTab> createState() => _AdminRestaurantsTabState();
}

class _AdminRestaurantsTabState extends State<AdminRestaurantsTab> {
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminService>().fetchRestaurants();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المطاعم'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminService>().fetchRestaurants();
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
                      adminService.fetchRestaurants();
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final filteredRestaurants = _filterRestaurants(adminService.restaurants);

          return Column(
            children: [
              _buildFilters(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => adminService.fetchRestaurants(),
                  child: filteredRestaurants.isEmpty
                      ? const Center(
                          child: Text('لا توجد مطاعم'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppConstants.s),
                          itemCount: filteredRestaurants.length,
                          itemBuilder: (context, index) {
                            final restaurant = filteredRestaurants[index];
                            return _buildRestaurantCard(restaurant, adminService);
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
              hintText: 'البحث عن مطعم...',
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
              const Text('تصفية حسب الحالة: '),
              const SizedBox(width: AppConstants.s),
              Expanded(
                child: DropdownButton<String>(
                  value: _statusFilter,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('الكل')),
                    DropdownMenuItem(value: 'active', child: Text('نشط')),
                    DropdownMenuItem(value: 'pending', child: Text('بانتظار الموافقة')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value!;
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

  List<AdminRestaurant> _filterRestaurants(List<AdminRestaurant> restaurants) {
    return restaurants.where((restaurant) {
      final matchesSearch = _searchQuery.isEmpty ||
          restaurant.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (restaurant.cuisine?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (restaurant.ownerName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesStatus = _statusFilter == 'all' ||
          (_statusFilter == 'active' && restaurant.ownerName != null) ||
          (_statusFilter == 'pending' && restaurant.ownerName == null);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Widget _buildRestaurantCard(AdminRestaurant restaurant, AdminService adminService) {
    final isPending = restaurant.ownerName == null;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppConstants.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                  ),
                  child: restaurant.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            restaurant.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.restaurant, size: 30);
                            },
                          ),
                        )
                      : const Icon(Icons.restaurant, size: 30),
                ),
                const SizedBox(width: AppConstants.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.s,
                              vertical: AppConstants.xs,
                            ),
                            decoration: BoxDecoration(
                              color: isPending ? Colors.orange : Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isPending ? 'بانتظار الموافقة' : 'نشط',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (restaurant.cuisine != null)
                        Text(
                          restaurant.cuisine!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      if (restaurant.ownerName != null) ...[
                        Text(
                          'المالك: ${restaurant.ownerName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        if (restaurant.ownerEmail != null)
                          Text(
                            restaurant.ownerEmail!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.s),
            Row(
              children: [
                _buildInfoChip('إجمالي الطلبات: ${restaurant.totalOrders}'),
                const SizedBox(width: AppConstants.s),
                _buildInfoChip('الطلبات المكتملة: ${restaurant.completedOrders}'),
              ],
            ),
            const SizedBox(height: AppConstants.s),
            Row(
              children: [
                _buildInfoChip(
                  'الإيرادات: ${restaurant.totalRevenue.toStringAsFixed(2)} د.ك',
                  color: Colors.green,
                ),
                const SizedBox(width: AppConstants.s),
                _buildInfoChip('تاريخ التسجيل: ${_formatDate(restaurant.createdAt)}'),
              ],
            ),
            const SizedBox(height: AppConstants.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isPending)
                  ElevatedButton.icon(
                    onPressed: () => _showApprovalDialog(restaurant, adminService),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('الموافقة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const SizedBox(width: AppConstants.s),
                TextButton.icon(
                  onPressed: () => _showRestaurantAnalytics(restaurant, adminService),
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('الإحصائيات'),
                ),
                const SizedBox(width: AppConstants.s),
                TextButton.icon(
                  onPressed: () => _showRestaurantDetails(restaurant),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showApprovalDialog(AdminRestaurant restaurant, AdminService adminService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الموافقة على المطعم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من الموافقة على مطعم "${restaurant.name}"؟'),
            const SizedBox(height: AppConstants.m),
            const Text(
              'ملاحظة: يجب أن يكون لدى المطعم مالك مسجل لإتمام الموافقة.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
              ),
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
              // For now, we'll use a placeholder owner ID
              // In a real app, you'd have a way to assign an owner
              _showOwnerSelectionDialog(restaurant, adminService);
            },
            child: const Text('الموافقة'),
          ),
        ],
      ),
    );
  }

  void _showOwnerSelectionDialog(AdminRestaurant restaurant, AdminService adminService) {
    final ownerIdController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحديد المالك'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('يرجى إدخال معرف المالك:'),
            const SizedBox(height: AppConstants.m),
            TextField(
              controller: ownerIdController,
              decoration: const InputDecoration(
                labelText: 'معرف المالك (UUID)',
                border: OutlineInputBorder(),
              ),
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
              if (ownerIdController.text.isNotEmpty) {
                Navigator.pop(context);
                adminService.approveRestaurant(
                  restaurant.id,
                  ownerIdController.text,
                );
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _showRestaurantAnalytics(AdminRestaurant restaurant, AdminService adminService) async {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        content: SizedBox(
          width: 100,
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    final analytics = await adminService.getRestaurantAnalytics(restaurant.id);
    
    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      
      if (analytics != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('إحصائيات ${restaurant.name}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAnalyticsRow('إجمالي الطلبات', analytics['orders']['total'].toString()),
                  _buildAnalyticsRow('الطلبات المكتملة', analytics['orders']['completed'].toString()),
                  _buildAnalyticsRow('الطلبات الملغية', analytics['orders']['cancelled'].toString()),
                  _buildAnalyticsRow('الطلبات قيد التنفيذ', analytics['orders']['in_progress'].toString()),
                  const Divider(),
                  _buildAnalyticsRow('إجمالي الإيرادات', '${analytics['revenue']['total']} د.ك'),
                  _buildAnalyticsRow('إيرادات هذا الشهر', '${analytics['revenue']['this_month']} د.ك'),
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في تحميل الإحصائيات')),
        );
      }
    }
  }

  void _showRestaurantDetails(AdminRestaurant restaurant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(restaurant.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('اسم المطعم', restaurant.name),
              _buildDetailRow('نوع الطبخ', restaurant.cuisine ?? 'غير محدد'),
              _buildDetailRow('اسم المالك', restaurant.ownerName ?? 'غير محدد'),
              _buildDetailRow('إيميل المالك', restaurant.ownerEmail ?? 'غير محدد'),
              _buildDetailRow('هاتف المالك', restaurant.ownerPhone ?? 'غير محدد'),
              _buildDetailRow('تاريخ التسجيل', _formatDate(restaurant.createdAt)),
              _buildDetailRow('إجمالي الطلبات', restaurant.totalOrders.toString()),
              _buildDetailRow('الطلبات المكتملة', restaurant.completedOrders.toString()),
              _buildDetailRow('إجمالي الإيرادات', '${restaurant.totalRevenue.toStringAsFixed(2)} د.ك'),
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

  Widget _buildAnalyticsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
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