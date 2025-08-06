import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_statistics.dart';

class AdminService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  AdminStatistics? _statistics;
  List<AdminUser> _users = [];
  List<AdminRestaurant> _restaurants = [];
  List<AdminOrder> _orders = [];
  List<AdminActivityLog> _activityLogs = [];

  bool _isLoading = false;
  String? _error;

  // Getters
  AdminStatistics? get statistics => _statistics;
  List<AdminUser> get users => _users;
  List<AdminRestaurant> get restaurants => _restaurants;
  List<AdminOrder> get orders => _orders;
  List<AdminActivityLog> get activityLogs => _activityLogs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get system statistics
  Future<void> fetchStatistics() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabase.rpc('get_system_statistics');
      
      if (response != null) {
        _statistics = AdminStatistics.fromJson(response);
      }
    } catch (e) {
      _error = 'فشل في تحميل الإحصائيات: ${e.toString()}';
      if (kDebugMode) print('Error fetching statistics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // User Management
  Future<void> fetchUsers() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabase
          .from('admin_users_view')
          .select()
          .order('created_at', ascending: false);

      _users = (response as List)
          .map((json) => AdminUser.fromJson(json))
          .toList();
    } catch (e) {
      _error = 'فشل في تحميل المستخدمين: ${e.toString()}';
      if (kDebugMode) print('Error fetching users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> suspendUser(String userId, String reason) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _supabase.rpc('manage_user_status', params: {
        'user_id': userId,
        'action': 'suspend',
        'reason': reason,
      });

      await fetchUsers(); // Refresh the list
    } catch (e) {
      _error = 'فشل في تعليق المستخدم: ${e.toString()}';
      if (kDebugMode) print('Error suspending user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> activateUser(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _supabase.rpc('manage_user_status', params: {
        'user_id': userId,
        'action': 'activate',
      });

      await fetchUsers(); // Refresh the list
    } catch (e) {
      _error = 'فشل في تفعيل المستخدم: ${e.toString()}';
      if (kDebugMode) print('Error activating user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Restaurant Management
  Future<void> fetchRestaurants() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabase
          .from('admin_restaurants_view')
          .select()
          .order('created_at', ascending: false);

      _restaurants = (response as List)
          .map((json) => AdminRestaurant.fromJson(json))
          .toList();
    } catch (e) {
      _error = 'فشل في تحميل المطاعم: ${e.toString()}';
      if (kDebugMode) print('Error fetching restaurants: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveRestaurant(String restaurantId, String ownerId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _supabase.rpc('approve_restaurant', params: {
        'restaurant_id': restaurantId,
        'owner_id': ownerId,
      });

      await fetchRestaurants(); // Refresh the list
    } catch (e) {
      _error = 'فشل في الموافقة على المطعم: ${e.toString()}';
      if (kDebugMode) print('Error approving restaurant: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Order Management
  Future<void> fetchOrders({int limit = 100}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabase
          .from('admin_orders_view')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      _orders = (response as List)
          .map((json) => AdminOrder.fromJson(json))
          .toList();
    } catch (e) {
      _error = 'فشل في تحميل الطلبات: ${e.toString()}';
      if (kDebugMode) print('Error fetching orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Activity Logs
  Future<void> fetchActivityLogs({int limit = 50}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabase
          .from('admin_activity_log')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      _activityLogs = (response as List)
          .map((json) => AdminActivityLog.fromJson(json))
          .toList();
    } catch (e) {
      _error = 'فشل في تحميل سجل الأنشطة: ${e.toString()}';
      if (kDebugMode) print('Error fetching activity logs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Review Management
  Future<void> moderateReview(String reviewId, String action) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _supabase.rpc('manage_review', params: {
        'review_id': reviewId,
        'action': action, // 'approve', 'reject', or 'remove'
      });

      // You might want to refresh relevant data here
    } catch (e) {
      _error = 'فشل في مراجعة التقييم: ${e.toString()}';
      if (kDebugMode) print('Error moderating review: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get restaurant analytics
  Future<Map<String, dynamic>?> getRestaurantAnalytics(String restaurantId) async {
    try {
      final response = await _supabase.rpc('get_restaurant_analytics', params: {
        'restaurant_id': restaurantId,
      });
      
      return response;
    } catch (e) {
      _error = 'فشل في تحميل إحصائيات المطعم: ${e.toString()}';
      if (kDebugMode) print('Error fetching restaurant analytics: $e');
      return null;
    }
  }

  // Get popular dishes
  Future<List<Map<String, dynamic>>?> getPopularDishes({String? restaurantId}) async {
    try {
      final response = await _supabase.rpc('get_popular_dishes', params: {
        if (restaurantId != null) 'restaurant_id': restaurantId,
      });
      
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      _error = 'فشل في تحميل الأطباق الشائعة: ${e.toString()}';
      if (kDebugMode) print('Error fetching popular dishes: $e');
      return null;
    }
  }

  // Refresh all data
  Future<void> refreshAllData() async {
    await Future.wait([
      fetchStatistics(),
      fetchUsers(),
      fetchRestaurants(),
      fetchOrders(),
      fetchActivityLogs(),
    ]);
  }
}