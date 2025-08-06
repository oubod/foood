// lib/models/cart_item_model.dart
import 'package:food_delivery_app/models/dish_model.dart';

class CartItem {
  final Dish dish;
  int quantity;

  CartItem({required this.dish, this.quantity = 1});

  void increment() {
    quantity++;
  }
}