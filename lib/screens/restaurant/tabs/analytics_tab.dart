// lib/screens/restaurant/tabs/analytics_tab.dart
import 'package:flutter/material.dart';
import 'package:food_delivery_app/main.dart';
import 'package:food_delivery_app/theme.dart';
import 'package:intl/intl.dart';

class AnalyticsTab extends StatefulWidget {
  final String restaurantId;
  const AnalyticsTab({Key? key, required this.restaurantId}) : super(key: key);

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() { _isLoading = true; });
    try {
      // Get orders count and revenue
      final ordersResponse = await supabase
          .from('orders')
          .select('id, total_price, created_at, status')
          .eq('restaurant_id', widget.restaurantId);

      double totalRevenue = 0;
      int totalOrders = ordersResponse.length;
      int todayOrders = 0;
      int completedOrders = 0;

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final orderIds = ordersResponse.map((o) => o['id'] as String).toList();

      for (final order in ordersResponse) {
        final orderDate = DateTime.parse(order['created_at']);
        final price = (order['total_price'] as num).toDouble();
        
        if (order['status'] == 'delivered') {
          totalRevenue += price;
          completedOrders++;
        }
        
        if (orderDate.isAfter(todayStart)) {
          todayOrders++;
        }
      }

      // Get popular dishes
      final dishesResponse = await supabase
          .from('order_items')
          .select('dish_id, quantity, dishes(name)')
          .filter('order_id', 'in', orderIds);

      Map<String, int> dishCounts = {};
      for (final item in dishesResponse) {
        final dishName = item['dishes']['name'] ?? 'Unknown';
        dishCounts[dishName] = (dishCounts[dishName] ?? 0) + (item['quantity'] as int);
      }

      final popularDishes = dishCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        _analytics = {
          'totalRevenue': totalRevenue,
          'totalOrders': totalOrders,
          'todayOrders': todayOrders,
          'completedOrders': completedOrders,
          'popularDishes': popularDishes.take(5).toList(),
        };
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في جلب البيانات: $e')),
        );
      }
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_analytics == null) {
      return const Center(child: Text('خطأ في جلب البيانات'));
    }

    return RefreshIndicator(
      onRefresh: _fetchAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            Row(
              children: [
                Expanded(child: _buildStatCard('إجمالي الإيرادات', '${_analytics!['totalRevenue'].toStringAsFixed(2)} د.ل', Icons.monetization_on, Colors.green)),
                const SizedBox(width: AppConstants.m),
                Expanded(child: _buildStatCard('إجمالي الطلبات', '${_analytics!['totalOrders']}', Icons.receipt_long, Colors.blue)),
              ],
            ),
            const SizedBox(height: AppConstants.m),
            Row(
              children: [
                Expanded(child: _buildStatCard('طلبات اليوم', '${_analytics!['todayOrders']}', Icons.today, Colors.orange)),
                const SizedBox(width: AppConstants.m),
                Expanded(child: _buildStatCard('مكتملة', '${_analytics!['completedOrders']}', Icons.check_circle, Colors.teal)),
              ],
            ),
            const SizedBox(height: AppConstants.xl),
            
            // Popular Dishes
            Text('الأطباق الأكثر طلباً', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppConstants.m),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: (_analytics!['popularDishes'] as List).length,
                itemBuilder: (context, index) {
                  final dish = (_analytics!['popularDishes'] as List)[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(dish.key),
                    trailing: Text('${dish.value} طلب'),
                  );
                },
                separatorBuilder: (context, index) => const Divider(height: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.m),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: AppConstants.s),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}