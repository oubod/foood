import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class NotificationService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription? _orderSubscription;
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  void initializeOrderTracking(String userId) {
    _orderSubscription?.cancel();
    
    _orderSubscription = _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('customer_id', userId)
        .listen((data) {
          for (var order in data) {
            _handleOrderUpdate(order);
          }
        });
  }

  void _handleOrderUpdate(Map<String, dynamic> order) {
    String message = _getStatusMessage(order['status']);
    
    _addNotification(
      title: 'تحديث الطلب',
      message: message,
      orderId: order['id'],
    );
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'preparing':
        return 'جاري تحضير طلبك';
      case 'ready_for_pickup':
        return 'طلبك جاهز للاستلام';
      case 'delivering':
        return 'طلبك في الطريق إليك';
      case 'delivered':
        return 'تم توصيل طلبك بنجاح';
      case 'cancelled':
        return 'تم إلغاء طلبك';
      default:
        return 'تحديث على طلبك';
    }
  }

  void _addNotification({
    required String title,
    required String message,
    String? orderId,
  }) {
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
      'orderId': orderId,
    };

    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n['id'] == notificationId);
    if (index != -1 && !_notifications[index]['read']) {
      _notifications[index]['read'] = true;
      _unreadCount--;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var notification in _notifications) {
      notification['read'] = true;
    }
    _unreadCount = 0;
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }
}