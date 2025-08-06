// lib/models/dish_model.dart
import 'package:hive/hive.dart';

part 'dish_model.g.dart'; // This file will be generated

@HiveType(typeId: 1)
class Dish extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final double price;
  @HiveField(4)
  final String imageUrl;
  @HiveField(5)
  final String restaurantId;

  Dish({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.restaurantId,
  });

  // A factory constructor to create a Dish from a map (the data from Supabase)
  factory Dish.fromMap(Map<String, dynamic> map) {
    return Dish(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] ?? '',
      price: (map['price'] as num).toDouble(),
      imageUrl: map['image_url'] ?? '',
      restaurantId: map['restaurant_id'] as String,
    );
  }
}