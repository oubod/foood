// lib/models/order_model.dart
import 'package:food_delivery_app/models/order_item_model.dart';

class Order {
  final String id;
  final DateTime createdAt;
  final String status;
  final double totalPrice;
  final String restaurantId;
  final String restaurantName;
  final String? restaurantImageUrl;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.totalPrice,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantImageUrl,
    required this.items,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    // The 'restaurants' key might be a map or null
    final restaurantData = map['restaurants'] as Map<String, dynamic>? ?? {};
    
    // The 'order_items' key should be a list
    final itemsData = map['order_items'] as List<dynamic>? ?? [];

    return Order(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
      status: map['status'],
      totalPrice: (map['total_price'] as num).toDouble(),
      restaurantId: map['restaurant_id'],
      restaurantName: restaurantData['name'] as String? ?? 'مطعم غير متوفر',
      restaurantImageUrl: restaurantData['image_url'] as String?,
      items: itemsData.map((item) => OrderItem.fromMap(item)).toList(),
    );
  }
}
