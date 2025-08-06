// lib/screens/profile/order_details_screen.dart
import 'package:flutter/material.dart';
import 'package:food_delivery_app/models/order_model.dart';
import 'package:food_delivery_app/theme.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل الطلب #${order.id.substring(0, 8)}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'ملخص الطلب'),
            _buildOrderSummaryCard(context),
            const SizedBox(height: AppConstants.l),
            _buildSectionTitle(context, 'الاطباق المطلوبة'),
            _buildOrderItemsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.s),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.m),
        child: Column(
          children: [
            _buildSummaryRow('رقم الطلب', '#${order.id.substring(0, 8)}'),
            _buildSummaryRow('التاريخ', DateFormat.yMMMd('ar').add_jm().format(order.createdAt)),
            _buildSummaryRow('المطعم', order.restaurantName),
            _buildSummaryRow('الحالة', order.status, isStatus: true),
            const Divider(),
            _buildSummaryRow('الإجمالي', '${order.totalPrice.toStringAsFixed(2)} د.ل', isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isStatus = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isStatus ? AppTheme.primary : (isTotal ? Colors.black : null),
              fontSize: isTotal ? 16 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard() {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: order.items.length,
        itemBuilder: (context, index) {
          final item = order.items[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: item.dishImageUrl != null ? NetworkImage(item.dishImageUrl!) : null,
              child: item.dishImageUrl == null ? const Icon(Icons.fastfood) : null,
            ),
            title: Text(item.dishName),
            subtitle: Text('الكمية: ${item.quantity}'),
            trailing: Text('${item.totalPrice.toStringAsFixed(2)} د.ل'),
          );
        },
        separatorBuilder: (context, index) => const Divider(indent: 72),
      ),
    );
  }
}
