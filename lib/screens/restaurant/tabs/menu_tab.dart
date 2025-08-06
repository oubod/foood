// lib/screens/restaurant/tabs/menu_tab.dart
import 'package:flutter/material.dart';
import 'package:food_delivery_app/models/dish_model.dart';
import 'package:food_delivery_app/models/restaurant_model.dart';
import 'package:food_delivery_app/theme.dart';

class MenuTab extends StatelessWidget {
  final Restaurant restaurant;
  final List<Dish> dishes;

  const MenuTab({
    Key? key,
    required this.restaurant,
    required this.dishes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.l),
      children: [
        // Restaurant Info Section
        _buildRestaurantInfoCard(context),
        const SizedBox(height: AppConstants.xl),
        
        // Dishes Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('قائمة الأطباق', style: AppTheme.textTheme.titleLarge),
            FilledButton.icon(
              onPressed: () { /* TODO: Add New Dish */ },
              icon: const Icon(Icons.add),
              label: const Text('إضافة طبق'),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.m),
        ...dishes.map((dish) => _buildDishListItem(context, dish)),
      ],
    );
  }

  Widget _buildRestaurantInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('معلومات المطعم', style: AppTheme.textTheme.titleMedium),
            const Divider(height: AppConstants.l),
            if (restaurant.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                child: Image.network(restaurant.imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: AppConstants.m),
            Text(restaurant.name, style: AppTheme.textTheme.titleLarge),
            Text(restaurant.cuisine ?? 'لا يوجد وصف', style: AppTheme.textTheme.bodyMedium),
            const SizedBox(height: AppConstants.m),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () { /* TODO: Edit Restaurant Details */ },
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('تعديل التفاصيل'),
              ),
            )
          ],
        ),
      ),
    );
  }
  
  Widget _buildDishListItem(BuildContext context, Dish dish) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.m),
      child: ListTile(
        leading: dish.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.s),
                child: Image.network(dish.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
              )
            : const Icon(Icons.fastfood),
        title: Text(dish.name, style: AppTheme.textTheme.titleMedium),
        subtitle: Text('${dish.price} MRU', style: AppTheme.textTheme.bodyMedium),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: AppTheme.iconDefault),
          onPressed: () { /* TODO: Edit Dish */ },
        ),
      ),
    );
  }
}