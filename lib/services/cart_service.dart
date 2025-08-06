// lib/services/cart_service.dart
import 'package:flutter/foundation.dart';
import 'package:food_delivery_app/models/cart_item_model.dart';
import 'package:food_delivery_app/models/dish_model.dart';

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0.0, (sum, item) => sum + (item.dish.price * item.quantity));

  void addItem(Dish dish) {
    // Check if the dish is already in the cart
    for (var item in _items) {
      if (item.dish.id == dish.id) {
        item.increment();
        notifyListeners(); // Notify UI to update
        return;
      }
    }
    // If not, add it as a new item
    _items.add(CartItem(dish: dish));
    notifyListeners(); // Notify UI to update
  }

  void removeItem(String dishId) {
    _items.removeWhere((item) => item.dish.id == dishId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void incrementItem(String dishId) {
    for (var item in _items) {
      if (item.dish.id == dishId) {
        item.increment();
        notifyListeners();
        return;
      }
    }
  }

  void decrementItem(String dishId) {
    for (var item in _items) {
      if (item.dish.id == dishId) {
        if (item.quantity > 1) {
          item.quantity--;
        } else {
          // If quantity is 1, just remove the item from the cart
          _items.remove(item);
        }
        notifyListeners();
        return;
      }
    }
  }

  bool canAddItem(Dish dish) {
    if (_items.isEmpty) {
      return true;
    }
    return _items.first.dish.restaurantId == dish.restaurantId;
  }
}