import 'package:flutter/material.dart';
import 'package:food_delivery_app/theme.dart';

class RestaurantCardSkeleton extends StatelessWidget {
  const RestaurantCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppConstants.s),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 140,
            decoration: const BoxDecoration(
              color: Colors.black, // Shimmer will animate over this
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                topRight: Radius.circular(AppConstants.borderRadiusLarge),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title placeholder
                Container(height: 20, width: 150, color: Colors.black),
                const SizedBox(height: AppConstants.s),
                // Subtitle placeholder
                Container(height: 14, width: 200, color: Colors.black),
                const SizedBox(height: AppConstants.s),
                // Bottom row placeholder
                Container(height: 12, width: 100, color: Colors.black),
              ],
            ),
          )
        ],
      ),
    );
  }
}