// lib/dish_card.dart
import 'package:flutter/material.dart';
import 'package:food_delivery_app/theme.dart';
import 'package:food_delivery_app/models/dish_model.dart'; // Import Dish model

class DishCard extends StatelessWidget {
  final Dish dish; // Use the Dish model
  final VoidCallback onAddToCart;

  const DishCard({
    Key? key,
    required this.dish, // Accept the whole object
    required this.onAddToCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.l),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: AppConstants.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dish Details (Name, Description, Price)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dish.name, style: AppTheme.textTheme.titleMedium),
                  const SizedBox(height: AppConstants.s),
                  Text(
                    dish.description,
                    style: AppTheme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppConstants.s),
                  Text(
                    '${dish.price} MRU', // MRU is the currency for Mauritania
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppConstants.m),
          // Dish Image and Add Button
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadiusMedium),
                  bottomLeft: Radius.circular(AppConstants.borderRadiusMedium),
                ),
                child: dish.imageUrl.isNotEmpty
                    ? Image.network(
                        dish.imageUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      )
                    : const Placeholder(
                        fallbackWidth: 120,
                        fallbackHeight: 120,
                      ),
              ),
              // Add to Cart Button
              Transform.translate(
                offset: const Offset(0, 15),
                child: ElevatedButton(
                  onPressed: onAddToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(AppConstants.m),
                  ),
                  child: const Icon(Icons.add, color: AppTheme.textOnPrimary),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}