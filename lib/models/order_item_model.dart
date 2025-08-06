// lib/models/order_item_model.dart

class OrderItem {
  final String id;
  final int quantity;
  final double unitPrice;
  final String dishId;
  final String dishName;
  final String? dishImageUrl;

  OrderItem({
    required this.id,
    required this.quantity,
    required this.unitPrice,
    required this.dishId,
    required this.dishName,
    this.dishImageUrl,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    // The 'dishes' key might be a map or null
    final dishData = map['dishes'] as Map<String, dynamic>? ?? {};

    return OrderItem(
      id: map['id'],
      quantity: map['quantity'],
      unitPrice: (map['unit_price'] as num).toDouble(),
      dishId: map['dish_id'],
      dishName: dishData['name'] as String? ?? 'طبق غير متوفر',
      dishImageUrl: dishData['image_url'] as String?,
    );
  }

  double get totalPrice => quantity * unitPrice;
}
