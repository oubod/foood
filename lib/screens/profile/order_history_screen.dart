// lib/screens/profile/order_history_screen.dart
import 'package:flutter/material.dart';
import 'package:food_delivery_app/main.dart';
import 'package:food_delivery_app/models/order_model.dart';
import 'package:food_delivery_app/screens/profile/order_details_screen.dart';
import 'package:food_delivery_app/theme.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchOrderHistory();
  }

  Future<List<Order>> _fetchOrderHistory() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw 'User not authenticated';
    }

    final response = await supabase
        .from('orders')
        .select('*, restaurants(name, image_url), order_items(*, dishes(*))')
        .eq('customer_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((data) => Order.fromMap(data)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الطلبات'),
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا يوجد طلبات سابقة.'));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.m),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(context, order);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.m),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(order: order),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: order.restaurantImageUrl != null
                        ? NetworkImage(order.restaurantImageUrl!)
                        : null,
                    child: order.restaurantImageUrl == null
                        ? const Icon(Icons.restaurant)
                        : null,
                  ),
                  const SizedBox(width: AppConstants.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.restaurantName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          DateFormat.yMMMd('ar').add_jm().format(order.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              const Divider(height: AppConstants.l),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${order.totalPrice.toStringAsFixed(2)} د.ل'),
                  Text(
                    order.status,
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
