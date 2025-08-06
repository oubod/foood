import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme.dart';
import '../../../services/auth_service.dart';

class OrderManagementTab extends StatefulWidget {
  const OrderManagementTab({super.key});

  @override
  State<OrderManagementTab> createState() => _OrderManagementTabState();
}

class _OrderManagementTabState extends State<OrderManagementTab> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _subscribeToOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userId = context.read<AuthService>().currentUser?.id;
      if (userId == null) return;

      // Get restaurant ID for current user
      final restaurantResponse = await _supabase
          .from('restaurants')
          .select('id')
          .eq('owner_id', userId)
          .single();

      final restaurantId = restaurantResponse['id'];

      // Get orders for this restaurant
      final ordersResponse = await _supabase
          .from('orders')
          .select('''
            *,
            order_items(*, dishes(name, price)),
            profiles:customer_id(full_name, phone)
          ''')
          .eq('restaurant_id', restaurantId)
          .order('created_at', ascending: false);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(ordersResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل في تحميل الطلبات: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _subscribeToOrders() {
    final userId = context.read<AuthService>().currentUser?.id;
    if (userId == null) return;

    _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .listen((data) {
          if (mounted) {
            _loadOrders(); // Reload all orders when there's a change
          }
        });
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث حالة الطلب إلى ${_getStatusText(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحديث الطلب: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmOrderPayment(String orderId) async {
    try {
      final result = await _supabase.rpc(
        'confirm_order',
        params: {'p_order_id': orderId},
      );

      if (result == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تأكيد الطلب بنجاح.'),
              backgroundColor: Colors.green,
            ),
          );
          _loadOrders(); // Refresh the list
        }
      } else {
        throw Exception('فشل في تأكيد الطلب');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطلبات'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppConstants.m),
                            ElevatedButton(
                              onPressed: _loadOrders,
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.m),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Text('تصفية حسب الحالة: '),
          const SizedBox(width: AppConstants.s),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedStatus,
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
                  _selectedStatus = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    final filteredOrders = _selectedStatus == 'all'
        ? _orders
        : _orders.where((order) => order['status'] == _selectedStatus).toList();

    if (filteredOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey),
            SizedBox(height: AppConstants.m),
            Text('لا توجد طلبات'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.s),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          final order = filteredOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderItems = order['order_items'] as List;
    final customerProfile = order['profiles'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.s),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'طلب رقم: ${order['id'].toString().substring(0, 8)}...',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.s,
                    vertical: AppConstants.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(order['status']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.s),
            Text(
              'العميل: ${customerProfile?['full_name'] ?? 'غير محدد'}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (order['customer_phone'] != null)
              Text(
                'الهاتف: ${order['customer_phone']}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            const SizedBox(height: AppConstants.s),
            Text(
              'الأصناف: ${orderItems.length}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'المبلغ: ${order['total_price'].toStringAsFixed(2)} د.ك',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
            Text(
              'وقت الطلب: ${_formatDate(order['created_at'])}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: AppConstants.s),
            _buildOrderActions(order),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderActions(Map<String, dynamic> order) {
    final status = order['status'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (status == 'pending_payment') ...[
          ElevatedButton(
            onPressed: () => _confirmOrderPayment(order['id']),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('قبول'),
          ),
          const SizedBox(width: AppConstants.s),
          ElevatedButton(
            onPressed: () => _showCancelDialog(order['id']),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('رفض'),
          ),
        ] else if (status == 'preparing') ...[
          ElevatedButton(
            onPressed: () => _updateOrderStatus(order['id'], 'ready_for_pickup'),
            child: const Text('جاهز للاستلام'),
          ),
        ] else if (status == 'ready_for_pickup') ...[
          ElevatedButton(
            onPressed: () => _updateOrderStatus(order['id'], 'delivering'),
            child: const Text('تم التسليم للتوصيل'),
          ),
        ] else if (status == 'delivering') ...[
          ElevatedButton(
            onPressed: () => _updateOrderStatus(order['id'], 'delivered'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('تم التوصيل'),
          ),
        ],
        const SizedBox(width: AppConstants.s),
        TextButton(
          onPressed: () => _showOrderDetails(order),
          child: const Text('التفاصيل'),
        ),
      ],
    );
  }

  void _showCancelDialog(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الطلب'),
        content: const Text('هل أنت متأكد من إلغاء هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus(orderId, 'cancelled');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إلغاء الطلب'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final orderItems = order['order_items'] as List;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل الطلب ${order['id'].toString().substring(0, 8)}...'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...orderItems.map((item) {
                final dish = item['dishes'];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppConstants.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('${dish['name']} x${item['quantity']}'),
                      ),
                      Text(
                        '${(item['quantity'] * item['unit_price']).toStringAsFixed(2)} د.ك',
                      ),
                    ],
                  ),
                );
              }).toList(),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الإجمالي:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${order['total_price'].toStringAsFixed(2)} د.ك',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
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

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}