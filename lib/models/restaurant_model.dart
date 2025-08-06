import 'package:hive/hive.dart';

part 'restaurant_model.g.dart'; // This file will be generated

@HiveType(typeId: 0) // Unique typeId for each model
class Restaurant extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? cuisine;
  @HiveField(3)
  final String? imageUrl;

  Restaurant({
    required this.id,
    required this.name,
    this.cuisine,
    this.imageUrl,
  });

  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'] as String,
      name: map['name'] as String,
      cuisine: map['cuisine'] as String?,
      imageUrl: map['image_url'] as String?,
    );
  }
}
