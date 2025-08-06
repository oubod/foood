import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme.dart';
import '../../../services/admin_service.dart';
import '../../../models/admin_statistics.dart';

class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminService>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مراقبة الطلبات'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminService>().fetchOrders();
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
                      adminService.fetchOrders();
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final filteredOrders = _filterOrders(adminService.orders);

          return Column(
            children: [
              _buildFilters(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => adminService.fetchOrders(),
                  child: filteredOrders.isEmpty
                      ? const Center(
                          child: Text('لا توجد طلبات'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppConstants.s),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];
                            return _buildOrderCard(order);
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
              hintText: 'البحث في الطلبات...',
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
                    DropdownMenuItem(value: 'pending_payment', child: Text('بانتظار الدفع')),
                    DropdownMenuItem(value: 'preparing', child: Text('قيد التحضير')),
                    DropdownMenuItem(value: 'ready_for_pickup', child: Text('جاهز للاستلام')),
                    DropdownMenuItem(value: 'delivering', child: Text('قيد التوصيل')),
                    DropdownMenuItem(value: 'delivered', child: Text('تم التوصيل')),
                    DropdownMenuItem(value: 'cancelled', child: Text('ملغي')),
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

  List<AdminOrder> _filterOrders(List<AdminOrder> orders) {
    return orders.where((order) {
      final matchesSearch = _searchQuery.isEmpty ||
          order.restaurantName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (order.customerName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          order.id.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _statusFilter == 'all' || order.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Widget _buildOrderCard(AdminOrder order) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppConstants.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طلب رقم: ${order.id.substring(0, 8)}...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        order.restaurantName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (order.customerName != null)
                        Text(
                          'العميل: ${order.customerName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.s,
                    vertical: AppConstants.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: const TextStyle(
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
                _buildInfoChip(
                  'المبلغ: ${order.totalPrice.toStringAsFixed(2)} د.ك',
                  color: Colors.green,
                ),
                const SizedBox(width: AppConstants.s),
                _buildInfoChip('عدد الأصناف: ${order.itemCount}'),
              ],
            ),
            const SizedBox(height: AppConstants.s),
            Row(
              children: [
                _buildInfoChip('تاريخ الطلب: ${_formatDateTime(order.createdAt)}'),
                if (order.paymentMethod != null) ...[
                  const SizedBox(width: AppConstants.s),
                  _buildInfoChip('طريقة الدفع: ${_getPaymentMethodText(order.paymentMethod!)}'),
                ],
              ],
            ),
            if (order.customerPhone != null) ...[
              const SizedBox(height: AppConstants.s),
              _buildInfoChip('هاتف العميل: ${order.customerPhone}'),
            ],
            const SizedBox(height: AppConstants.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showOrderDetails(order),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_payment':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready_for_pickup':
        return Colors.purple;
      case 'delivering':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending_payment':
        return 'بانتظار الدفع';
      case 'preparing':
        return 'قيد التحضير';
      case 'ready_for_pickup':
        return 'جاهز للاستلام';
      case 'delivering':
        return 'قيد التوصيل';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'cash':
        return 'نقدي';
      case 'knet':
        return 'كي نت';
      case 'visa':
        return 'فيزا';
      default:
        return method;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showOrderDetails(AdminOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل الطلب ${order.id.substring(0, 8)}...'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('رقم الطلب', order.id),
              _buildDetailRow('المطعم', order.restaurantName),
              _buildDetailRow('العميل', order.customerName ?? 'غير محدد'),
              _buildDetailRow('هاتف العميل', order.customerPhone ?? 'غير محدد'),
              _buildDetailRow('الحالة', _getStatusText(order.status)),
              _buildDetailRow('المبلغ الإجمالي', '${order.totalPrice.toStringAsFixed(2)} د.ك'),
              _buildDetailRow('عدد الأصناف', order.itemCount.toString()),
              _buildDetailRow('طريقة الدفع', order.paymentMethod != null ? _getPaymentMethodText(order.paymentMethod!) : 'غير محدد'),
              _buildDetailRow('تاريخ الطلب', _formatDateTime(order.createdAt)),
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