import 'dart:async';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/main.dart';
import 'package:food_delivery_app/theme.dart';
import 'package:intl/intl.dart';

class OrdersTab extends StatefulWidget {
  final String restaurantId;
  const OrdersTab({Key? key, required this.restaurantId}) : super(key: key);

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  late final Stream<List<Map<String, dynamic>>> _ordersStream;

  @override
  void initState() {
    super.initState();
    _ordersStream = supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('restaurant_id', widget.restaurantId)
        .order('created_at', ascending: false);
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await supabase.from('orders').update({'status': newStatus}).eq('id', orderId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Center(
            child: Text('لا توجد طلبات حالياً', style: AppTheme.textTheme.titleLarge),
          );
        }

        final activeOrders = orders.where((o) => o['status'] != 'delivered' && o['status'] != 'cancelled').toList();
        final completedOrders = orders.where((o) => o['status'] == 'delivered' || o['status'] == 'cancelled').toList();

        return ListView(
          padding: const EdgeInsets.all(AppConstants.m),
          children: [
            if (activeOrders.isNotEmpty) ..._buildOrderSection('الطلبات الحالية', activeOrders),
            if (completedOrders.isNotEmpty) ..._buildOrderSection('الطلبات المكتملة', completedOrders, isCompleted: true),
          ],
        );
      },
    );
  }

  List<Widget> _buildOrderSection(String title, List<Map<String, dynamic>> orders, {bool isCompleted = false}) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.s),
        child: Text(title, style: AppTheme.textTheme.titleLarge),
      ),
      ...orders.map((order) => _buildOrderCard(order, isCompleted: isCompleted)).toList(),
    ];
  }

  Widget _buildOrderCard(Map<String, dynamic> order, {required bool isCompleted}) {
    final String currentStatus = order['status'];
    final DateTime createdAt = DateTime.parse(order['created_at']);
    final formattedTime = DateFormat('hh:mm a, dd/MM/yy').format(createdAt);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: AppConstants.m),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('زبون: ${order['customer_name']}', style: AppTheme.textTheme.titleMedium),
                Text('#${order['id'].toString().substring(0, 6)}', style: AppTheme.textTheme.bodySmall),
              ],
            ),
            Text('الهاتف: ${order['customer_phone']}', style: AppTheme.textTheme.bodyMedium),
            Text('الوقت: $formattedTime', style: AppTheme.textTheme.bodySmall),
            const Divider(height: AppConstants.l),
            _buildStatusInfo(order),
            if (!isCompleted) ...[
              const SizedBox(height: AppConstants.m),
              _buildActionButton(currentStatus, order['id']),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfo(Map<String, dynamic> order) {
    final status = order['status'];
    final paymentMethod = order['payment_method'];
    final paymentProofUrl = order['payment_proof_url'];

    String statusText;
    IconData statusIcon;
    Color statusColor;

    switch (status) {
      case 'pending_payment':
        statusText = 'في انتظار تأكيد الدفع';
        statusIcon = Icons.payment;
        statusColor = Colors.orange.shade700;
        break;
      case 'preparing':
        statusText = 'قيد التحضير';
        statusIcon = Icons.soup_kitchen_outlined;
        statusColor = Colors.blue.shade700;
        break;
      case 'ready_for_pickup':
        statusText = 'جاهز للاستلام';
        statusIcon = Icons.shopping_bag_outlined;
        statusColor = Colors.purple.shade700;
        break;
      case 'delivering':
        statusText = 'قيد التوصيل';
        statusIcon = Icons.delivery_dining;
        statusColor = Colors.teal.shade700;
        break;
      case 'delivered':
        statusText = 'مكتمل';
        statusIcon = Icons.check_circle;
        statusColor = Colors.green.shade700;
        break;
      case 'cancelled':
        statusText = 'ملغي';
        statusIcon = Icons.cancel;
        statusColor = Colors.red.shade700;
        break;
      default:
        statusText = 'غير معروف';
        statusIcon = Icons.help_outline;
        statusColor = Colors.grey.shade700;
    }

    return Column(
      children: [
        Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: AppConstants.s),
            Text(statusText, style: AppTheme.textTheme.titleMedium?.copyWith(color: statusColor)),
          ],
        ),
        if (paymentMethod == 'electronic')
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('طريقة الدفع: إلكتروني'),
              if (paymentProofUrl != null)
                TextButton(
                  child: const Text('عرض الإثبات'),
                  onPressed: () => showDialog(context: context, builder: (_) => Dialog(child: Image.network(paymentProofUrl))),
                )
            ],
          )
      ],
    );
  }

  Widget _buildActionButton(String status, String orderId) {
    String buttonText;
    IconData buttonIcon;
    VoidCallback onPressed;

    switch (status) {
      case 'pending_payment':
        buttonText = 'تأكيد استلام المبلغ';
        buttonIcon = Icons.check;
        onPressed = () => _updateOrderStatus(orderId, 'preparing');
        break;
      case 'preparing':
        buttonText = 'إعلان أن الطلب جاهز';
        buttonIcon = Icons.check_circle_outline;
        onPressed = () => _updateOrderStatus(orderId, 'ready_for_pickup');
        break;
      case 'ready_for_pickup':
        buttonText = 'خارج للتوصيل';
        buttonIcon = Icons.delivery_dining;
        onPressed = () => _updateOrderStatus(orderId, 'delivering');
        break;
      case 'delivering':
        buttonText = 'تم تسليم الطلب';
        buttonIcon = Icons.task_alt;
        onPressed = () => _updateOrderStatus(orderId, 'delivered');
        break;
      default:
        return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(buttonIcon, size: 18),
        label: Text(buttonText),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.m),
        ),
      ),
    );
  }
}