class AdminStatistics {
  final UserStats users;
  final RestaurantStats restaurants;
  final OrderStats orders;
  final RevenueStats revenue;

  AdminStatistics({
    required this.users,
    required this.restaurants,
    required this.orders,
    required this.revenue,
  });

  factory AdminStatistics.fromJson(Map<String, dynamic> json) {
    return AdminStatistics(
      users: UserStats.fromJson(json['users']),
      restaurants: RestaurantStats.fromJson(json['restaurants']),
      orders: OrderStats.fromJson(json['orders']),
      revenue: RevenueStats.fromJson(json['revenue']),
    );
  }
}

class UserStats {
  final int total;
  final int customers;
  final int owners;
  final int admins;
  final int newToday;
  final int newThisWeek;
  final int newThisMonth;

  UserStats({
    required this.total,
    required this.customers,
    required this.owners,
    required this.admins,
    required this.newToday,
    required this.newThisWeek,
    required this.newThisMonth,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      total: json['total'] ?? 0,
      customers: json['customers'] ?? 0,
      owners: json['owners'] ?? 0,
      admins: json['admins'] ?? 0,
      newToday: json['new_today'] ?? 0,
      newThisWeek: json['new_this_week'] ?? 0,
      newThisMonth: json['new_this_month'] ?? 0,
    );
  }
}

class RestaurantStats {
  final int total;
  final int active;
  final int pendingApproval;
  final int newThisMonth;

  RestaurantStats({
    required this.total,
    required this.active,
    required this.pendingApproval,
    required this.newThisMonth,
  });

  factory RestaurantStats.fromJson(Map<String, dynamic> json) {
    return RestaurantStats(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      pendingApproval: json['pending_approval'] ?? 0,
      newThisMonth: json['new_this_month'] ?? 0,
    );
  }
}

class OrderStats {
  final int total;
  final int today;
  final int thisWeek;
  final int thisMonth;
  final int completed;
  final int cancelled;
  final int inProgress;

  OrderStats({
    required this.total,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.completed,
    required this.cancelled,
    required this.inProgress,
  });

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    return OrderStats(
      total: json['total'] ?? 0,
      today: json['today'] ?? 0,
      thisWeek: json['this_week'] ?? 0,
      thisMonth: json['this_month'] ?? 0,
      completed: json['completed'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
      inProgress: json['in_progress'] ?? 0,
    );
  }
}

class RevenueStats {
  final double total;
  final double today;
  final double thisWeek;
  final double thisMonth;

  RevenueStats({
    required this.total,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
  });

  factory RevenueStats.fromJson(Map<String, dynamic> json) {
    return RevenueStats(
      total: (json['total'] ?? 0).toDouble(),
      today: (json['today'] ?? 0).toDouble(),
      thisWeek: (json['this_week'] ?? 0).toDouble(),
      thisMonth: (json['this_month'] ?? 0).toDouble(),
    );
  }
}

class AdminUser {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? role;
  final bool isSuspended;
  final String? suspendedReason;
  final DateTime createdAt;
  final DateTime? lastSignInAt;
  final DateTime? emailConfirmedAt;

  AdminUser({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.role,
    this.isSuspended = false,
    this.suspendedReason,
    required this.createdAt,
    this.lastSignInAt,
    this.emailConfirmedAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      phone: json['phone'],
      role: json['role'],
      isSuspended: json['is_suspended'] ?? false,
      suspendedReason: json['suspended_reason'],
      createdAt: DateTime.parse(json['created_at']),
      lastSignInAt: json['last_sign_in_at'] != null 
          ? DateTime.parse(json['last_sign_in_at']) 
          : null,
      emailConfirmedAt: json['email_confirmed_at'] != null 
          ? DateTime.parse(json['email_confirmed_at']) 
          : null,
    );
  }
}

class AdminRestaurant {
  final String id;
  final String name;
  final String? cuisine;
  final String? imageUrl;
  final DateTime createdAt;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerEmail;
  final int totalOrders;
  final int completedOrders;
  final double totalRevenue;

  AdminRestaurant({
    required this.id,
    required this.name,
    this.cuisine,
    this.imageUrl,
    required this.createdAt,
    this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.totalRevenue = 0.0,
  });

  factory AdminRestaurant.fromJson(Map<String, dynamic> json) {
    return AdminRestaurant(
      id: json['id'],
      name: json['name'],
      cuisine: json['cuisine'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      ownerName: json['owner_name'],
      ownerPhone: json['owner_phone'],
      ownerEmail: json['owner_email'],
      totalOrders: json['total_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
    );
  }
}

class AdminOrder {
  final String id;
  final DateTime createdAt;
  final String status;
  final double totalPrice;
  final String? paymentMethod;
  final String restaurantName;
  final String? customerName;
  final String? customerPhone;
  final int itemCount;

  AdminOrder({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.totalPrice,
    this.paymentMethod,
    required this.restaurantName,
    this.customerName,
    this.customerPhone,
    this.itemCount = 0,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    return AdminOrder(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      status: json['status'],
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'],
      restaurantName: json['restaurant_name'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      itemCount: json['item_count'] ?? 0,
    );
  }
}

class AdminActivityLog {
  final String id;
  final String adminId;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  AdminActivityLog({
    required this.id,
    required this.adminId,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.details,
    required this.createdAt,
  });

  factory AdminActivityLog.fromJson(Map<String, dynamic> json) {
    return AdminActivityLog(
      id: json['id'],
      adminId: json['admin_id'],
      action: json['action'],
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      details: json['details'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}