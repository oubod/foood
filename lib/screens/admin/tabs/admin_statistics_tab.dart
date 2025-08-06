import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme.dart';
import '../../../services/admin_service.dart';
import '../../../models/admin_statistics.dart';

class AdminStatisticsTab extends StatefulWidget {
  const AdminStatisticsTab({super.key});

  @override
  State<AdminStatisticsTab> createState() => _AdminStatisticsTabState();
}

class _AdminStatisticsTabState extends State<AdminStatisticsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminService>().fetchStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إحصائيات النظام'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminService>().fetchStatistics();
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
                      adminService.fetchStatistics();
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final statistics = adminService.statistics;
          if (statistics == null) {
            return const Center(
              child: Text('لا توجد إحصائيات متاحة'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => adminService.fetchStatistics(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('إحصائيات المستخدمين'),
                  _buildUserStatsCards(statistics.users),
                  const SizedBox(height: AppConstants.l),
                  
                  _buildSectionTitle('إحصائيات المطاعم'),
                  _buildRestaurantStatsCards(statistics.restaurants),
                  const SizedBox(height: AppConstants.l),
                  
                  _buildSectionTitle('إحصائيات الطلبات'),
                  _buildOrderStatsCards(statistics.orders),
                  const SizedBox(height: AppConstants.l),
                  
                  _buildSectionTitle('إحصائيات الإيرادات'),
                  _buildRevenueStatsCards(statistics.revenue),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.s),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildUserStatsCards(UserStats users) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'إجمالي المستخدمين',
                users.total.toString(),
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: AppConstants.s),
            Expanded(
              child: _buildStatCard(
                'العملاء',
                users.customers.toString(),
                Icons.person,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.s),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'أصحاب المطاعم',
                users.owners.toString(),
                Icons.restaurant,
                Colors.orange,
              ),
            ),
            const SizedBox(width: AppConstants.s),
            Expanded(
              child: _buildStatCard(
                'المديرين',
                users.admins.toString(),
                Icons.admin_panel_settings,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.s),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'جديد اليوم',
                users.newToday.toString(),
                Icons.today,
                Colors.teal,
              ),
            ),
            const SizedBox(width: AppConstants.s),
            Expanded(
              child: _buildStatCard(
                'جديد هذا الأسبوع',
                users.newThisWeek.toString(),
                Icons.date_range,
                Colors.indigo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRestaurantStatsCards(RestaurantStats restaurants) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'إجمالي المطاعم',
            restaurants.total.toString(),
            Icons.restaurant_menu,
            Colors.red,
          ),
        ),
        const SizedBox(width: AppConstants.s),
        Expanded(
          child: _buildStatCard(
            'نشط',
            restaurants.active.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: AppConstants.s),
        Expanded(
          child: _buildStatCard(
            'بانتظار الموافقة',
            restaurants.pendingApproval.toString(),
            Icons.pending,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderStatsCards(OrderStats orders) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'إجمالي الطلبات',
                orders.total.toString(),
                Icons.shopping_cart,
                Colors.blue,
              ),
            ),
            const SizedBox(width: AppConstants.s),
            Expanded(
              child: _buildStatCard(
                'اليوم',
                orders.today.toString(),
                Icons.today,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.s),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'مكتملة',
                orders.completed.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: AppConstants.s),
            Expanded(
              child: _buildStatCard(
                'ملغية',
                orders.cancelled.toString(),
                Icons.cancel,
                Colors.red,
              ),
            ),
            const SizedBox(width: AppConstants.s),
            Expanded(
              child: _buildStatCard(
                'قيد التنفيذ',
                orders.inProgress.toString(),
                Icons.pending,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueStatsCards(RevenueStats revenue) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'إجمالي الإيرادات',
                '${revenue.total.toStringAsFixed(2)} د.ك',
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: AppConstants.s),
            Expanded(
              child: _buildStatCard(
                'اليوم',
                '${revenue.today.toStringAsFixed(2)} د.ك',
                Icons.today,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.s),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'هذا الأسبوع',
                '${revenue.thisWeek.toStringAsFixed(2)} د.ك',
                Icons.date_range,
                Colors.purple,
              ),
            ),
            const SizedBox(width: AppConstants.s),
            Expanded(
              child: _buildStatCard(
                'هذا الشهر',
                '${revenue.thisMonth.toStringAsFixed(2)} د.ك',
                Icons.calendar_month,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.m),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: AppConstants.s),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: AppConstants.xs),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}