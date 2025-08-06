import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';
import '../../services/notification_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _subscribeToOrderUpdates();
  }

  Future<void> _loadOrder() async {
    try {
      print('Loading order with ID: ${widget.orderId}'); // Debug log
      
      // First get the basic order info
      final response = await _supabase
          .from('orders')
          .select('*')
          .eq('id', widget.orderId)
          .maybeSingle();

      if (response == null) {
        setState(() {
          _error = 'لم يتم العثور على الطلب';
          _isLoading = false;
        });
        return;
      }

      print('Order data: $response'); // Debug log

      // Then get restaurant info
      final restaurantData = await _supabase
          .from('restaurants')
          .select('name, phone')
          .eq('id', response['restaurant_id'])
          .maybeSingle();

      // Get order items - try with dish info first, fallback if needed
      List<Map<String, dynamic>> orderItemsData;
      try {
        orderItemsData = await _supabase
            .from('order_items')
            .select('*, dishes(name, price)')
            .eq('order_id', widget.orderId);
      } catch (e) {
        print('Failed to get order items with dish info, trying without: $e');
        // Fallback: get order items without dish info
        orderItemsData = await _supabase
            .from('order_items')
            .select('*')
            .eq('order_id', widget.orderId);
        
        // Manually fetch dish info for each item
        for (var item in orderItemsData) {
          try {
            final dishData = await _supabase
                .from('dishes')
                .select('name, price')
                .eq('id', item['dish_id'])
                .maybeSingle();
            item['dishes'] = dishData;
          } catch (dishError) {
            print('Failed to get dish info for ${item['dish_id']}: $dishError');
            item['dishes'] = {'name': 'منتج غير متوفر', 'price': 0};
          }
        }
      }

      print('Restaurant data: $restaurantData'); // Debug log
      print('Order items data: $orderItemsData'); // Debug log

      // Combine all data
      final completeOrder = {
        ...response,
        'restaurants': restaurantData,
        'order_items': orderItemsData,
      };

      setState(() {
        _order = completeOrder;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading order: $e'); // Debug log
      setState(() {
        _error = 'فشل في تحميل تفاصيل الطلب: $e';
        _isLoading = false;
      });
    }
  }

  void _subscribeToOrderUpdates() {
    _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', widget.orderId)
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            setState(() {
              _order = {..._order!, ...data.first};
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع الطلب'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrder,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: AppConstants.m),
                      ElevatedButton(
                        onPressed: _loadOrder,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _buildOrderDetails(),
    );
  }

  Widget _buildOrderDetails() {
    if (_order == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.m),
      child: Column(
        children: [
          _buildOrderHeader(),
          const SizedBox(height: AppConstants.l),
          _buildOrderStatus(),
          const SizedBox(height: AppConstants.l),
          _buildOrderItems(),
          const SizedBox(height: AppConstants.l),
          _buildRestaurantInfo(),
          const SizedBox(height: AppConstants.l),
          _buildOrderSummary(),
        ],
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'طلب رقم: ${widget.orderId.substring(0, 8)}...',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.s,
                    vertical: AppConstants.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_order!['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(_order!['status']),
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
              'تاريخ الطلب: ${_formatDate(_order!['created_at'])}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatus() {
    final status = _order!['status'];
    final steps = [
      {'key': 'pending_payment', 'title': 'بانتظار الدفع'},
      {'key': 'preparing', 'title': 'قيد التحضير'},
      {'key': 'ready_for_pickup', 'title': 'جاهز للاستلام'},
      {'key': 'delivering', 'title': 'قيد التوصيل'},
      {'key': 'delivered', 'title': 'تم التوصيل'},
    ];

    if (status == 'cancelled') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.m),
          child: Row(
            children: [
              const Icon(Icons.cancel, color: Colors.red, size: 32),
              const SizedBox(width: AppConstants.m),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تم إلغاء الطلب',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    'تم إلغاء طلبك من قبل المطعم',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'حالة الطلب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.m),
            ...steps.map((step) {
              final isActive = _isStepActive(step['key']!, status);
              final isCompleted = _isStepCompleted(step['key']!, status);
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppConstants.s),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted 
                            ? Colors.green 
                            : isActive 
                                ? AppConstants.primaryColor 
                                : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : Icons.circle,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppConstants.m),
                    Text(
                      step['title']!,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted || isActive ? Colors.black : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    final items = _order!['order_items'] as List;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تفاصيل الطلب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.m),
            ...items.map((item) {
              final dish = item['dishes'];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppConstants.s),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${dish['name']} x${item['quantity']}'),
                    ),
                    Text(
                      '${(item['quantity'] * item['unit_price']).toStringAsFixed(2)} د.ك',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantInfo() {
    final restaurant = _order!['restaurants'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات المطعم',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.m),
            Row(
              children: [
                const Icon(Icons.restaurant),
                const SizedBox(width: AppConstants.s),
                Text(restaurant['name']),
              ],
            ),
            const SizedBox(height: AppConstants.s),
            Row(
              children: [
                const Icon(Icons.phone),
                const SizedBox(width: AppConstants.s),
                Text(restaurant['phone'] ?? 'غير متوفر'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملخص الطلب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.m),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('طريقة الدفع:'),
                Text(_getPaymentMethodText(_order!['payment_method'])),
              ],
            ),
            const SizedBox(height: AppConstants.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('المبلغ الإجمالي:'),
                Text(
                  '${_order!['total_price'].toStringAsFixed(2)} د.ك',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ],
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
      case 'electronic':
        return 'إلكتروني';
      default:
        return method;
    }
  }

  bool _isStepActive(String stepKey, String currentStatus) {
    return stepKey == currentStatus;
  }

  bool _isStepCompleted(String stepKey, String currentStatus) {
    const statusOrder = [
      'pending_payment',
      'preparing',
      'ready_for_pickup',
      'delivering',
      'delivered'
    ];
    
    final stepIndex = statusOrder.indexOf(stepKey);
    final currentIndex = statusOrder.indexOf(currentStatus);
    
    return stepIndex < currentIndex;
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
