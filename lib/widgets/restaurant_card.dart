// lib/widgets/restaurant_card.dart
import 'package:flutter/material.dart';
import '../theme.dart'; // Import our theme constants
import 'cached_image.dart';
import 'package:provider/provider.dart';
import 'package:food_delivery_app/services/favorites_service.dart';

class RestaurantCard extends StatelessWidget {
  final String id; // Add this property
  final String imageUrl;
  final String name;
  final String cuisine;
  final double rating;
  final String deliveryTime;

  const RestaurantCard({
    Key? key,
    required this.id, // Add to constructor
    required this.imageUrl,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.deliveryTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppConstants.s),
      // Applying the custom soft shadow from our design system
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: AppConstants.softShadow,
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'restaurant-image-$id',
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                        topRight: Radius.circular(AppConstants.borderRadiusLarge),
                      ),
                      child: CachedImage(
                        imageUrl: imageUrl,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Consumer<FavoritesService>(
                        builder: (context, favoritesService, child) {
                          final isFav = favoritesService.isFavorite(id);
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => favoritesService.toggleFavorite(id),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.white,
                                size: 28,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppConstants.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant Name
                    Text(name, style: AppTheme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    // Cuisine Type
                    Text(cuisine, style: AppTheme.textTheme.bodyMedium),
                    const SizedBox(height: AppConstants.s),
                    // Rating and Delivery time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildIconText(
                          icon: Icons.star,
                          iconColor: AppTheme.starRating,
                          text: '$rating (200+)',
                        ),
                        _buildIconText(
                          icon: Icons.timer_outlined,
                          iconColor: AppTheme.textSecondary,
                          text: '$deliveryTime',
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  // A small helper widget to build icon-text pairs
  Widget _buildIconText({required IconData icon, required Color iconColor, required String text}) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 4),
        Text(text, style: AppTheme.textTheme.bodySmall),
      ],
    );
  }
}