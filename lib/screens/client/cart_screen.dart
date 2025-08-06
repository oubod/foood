// lib/screens/client/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Add this import
import 'package:food_delivery_app/models/cart_item_model.dart';
import 'package:food_delivery_app/services/cart_service.dart';
import 'package:food_delivery_app/theme.dart';
import 'package:provider/provider.dart';
import 'package:food_delivery_app/screens/client/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to listen to changes in the CartService
    return Consumer<CartService>(
      builder: (context, cart, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('سلتي'), // "My Cart"
          ),
          body: cart.items.isEmpty
              ? _buildEmptyCart()
              : _buildCart(cart),
          // The bottom navigation bar will be our summary and checkout button
          bottomNavigationBar: cart.items.isEmpty ? null : _buildSummary(context, cart),
        );
      },
    );
  }
  
  // Widget to show when the cart is empty
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- REPLACEMENT ---
          SvgPicture.asset(
            'assets/images/empty_cart.svg',
            height: 120,
            colorFilter: const ColorFilter.mode(AppTheme.iconDefault, BlendMode.srcIn),
          ),
          // --- END OF REPLACEMENT ---
          const SizedBox(height: AppConstants.l),
          Text('سلتك فارغة!', style: AppTheme.textTheme.titleLarge),
          const SizedBox(height: AppConstants.s),
          Text('أضف بعض الأطباق الشهية لتبدأ', style: AppTheme.textTheme.bodyMedium),
        ],
      ),
    );
  }
  
  // Widget to show the list of cart items
  Widget _buildCart(CartService cart) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.l),
      itemCount: cart.items.length,
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return _buildCartItem(context, item);
      },
    );
  }

  // Widget for a single row in the cart list
  Widget _buildCartItem(BuildContext context, CartItem item) {
    final cartService = Provider.of<CartService>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.l),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            child: Image.network(item.dish.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
          ),
          const SizedBox(width: AppConstants.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.dish.name, style: AppTheme.textTheme.titleMedium),
                Text('${item.dish.price} MRU', style: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.primary)),
              ],
            ),
          ),
          // Quantity Controller
          Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusPill),
            ),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.remove, size: 16), onPressed: () => cartService.decrementItem(item.dish.id)),
                Text(item.quantity.toString(), style: AppTheme.textTheme.titleMedium),
                IconButton(icon: const Icon(Icons.add, size: 16), onPressed: () => cartService.incrementItem(item.dish.id)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Widget for the summary and checkout button at the bottom
  Widget _buildSummary(BuildContext context, CartService cart) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.l).copyWith(bottom: AppConstants.xl), // Extra padding for safe area
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: AppConstants.softShadow, // Using soft shadow for a subtle lift
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.borderRadiusLarge),
          topRight: Radius.circular(AppConstants.borderRadiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المجموع', style: AppTheme.textTheme.titleMedium),
              Text('${cart.totalPrice} MRU', style: AppTheme.textTheme.titleLarge?.copyWith(color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: AppConstants.l),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: AppConstants.m),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
              ),
              child: const Text('المتابعة للدفع', style: TextStyle(color: AppTheme.textOnPrimary, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}