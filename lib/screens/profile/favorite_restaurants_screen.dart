// lib/screens/profile/favorite_restaurants_screen.dart
import 'package:flutter/material.dart';
import 'package:food_delivery_app/main.dart';
import 'package:food_delivery_app/models/restaurant_model.dart';
import 'package:food_delivery_app/screens/client/restaurant_menu_screen.dart';
import 'package:food_delivery_app/services/favorites_service.dart';
import 'package:food_delivery_app/theme.dart';
import 'package:food_delivery_app/widgets/restaurant_card.dart';
import 'package:provider/provider.dart';

class FavoriteRestaurantsScreen extends StatelessWidget {
  const FavoriteRestaurantsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المطاعم المفضلة'),
      ),
      body: Consumer<FavoritesService>(
        builder: (context, favoritesService, child) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: favoritesService.fetchFavoriteRestaurants(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('خطأ: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('لا توجد مطاعم مفضلة', style: TextStyle(fontSize: 18)),
                      Text('ابدأ بإضافة مطاعمك المفضلة!'),
                    ],
                  ),
                );
              }

              final favorites = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(AppConstants.m),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final fav = favorites[index];
                  final restaurant = Restaurant.fromMap(fav['restaurants']);
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RestaurantMenuScreen(
                            restaurantId: restaurant.id,
                            restaurantName: restaurant.name,
                            restaurantImageUrl: restaurant.imageUrl ?? '',
                          ),
                        ),
                      );
                    },
                    child: RestaurantCard(
                      id: restaurant.id,
                      name: restaurant.name,
                      cuisine: restaurant.cuisine ?? 'غير محدد',
                      deliveryTime: '20-30 دقيقة',
                      rating: 4.5,
                      imageUrl: restaurant.imageUrl ?? '',
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}