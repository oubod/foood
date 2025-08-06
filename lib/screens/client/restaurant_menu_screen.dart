// lib/screens/client/restaurant_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import
import 'package:food_delivery_app/dish_card.dart';
import 'package:food_delivery_app/main.dart';
import 'package:food_delivery_app/theme.dart';
import 'package:food_delivery_app/models/dish_model.dart';
import 'package:food_delivery_app/services/cart_service.dart'; // Import service
import 'package:provider/provider.dart'; // Import provider
import 'package:food_delivery_app/screens/client/cart_screen.dart'; // Import CartScreen

class RestaurantMenuScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String restaurantImageUrl; // Add this property

  const RestaurantMenuScreen({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantImageUrl, // Add to constructor
  }) : super(key: key);

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  late final Future<List<Dish>> _dishesFuture; // Future now returns List<Dish>

  @override
  void initState() {
    super.initState();
    _dishesFuture = _getDishes(); // Call the new fetching method
  }

  // New method to fetch and parse dishes
  Future<List<Dish>> _getDishes() async {
    final response = await supabase
        .from('dishes')
        .select()
        .eq('restaurant_id', widget.restaurantId);

    // Convert the List<Map<String, dynamic>> to List<Dish>
    final dishes = response.map((map) => Dish.fromMap(map)).toList();
    return dishes;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartService>(
      builder: (context, cart, child) {
        return Scaffold(
          // The FloatingActionButton is now correctly part of the Scaffold
          // and will be managed by the Consumer.
          floatingActionButton: cart.items.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartScreen()),
                    );
                  },
                  label: Text('${cart.totalItems} Items'),
                  icon: const Icon(Icons.shopping_cart),
                  backgroundColor: AppTheme.primary,
                ),
          // We use a Stack to layer the image, a back button, and the list.
          body: Stack(
            children: [
              // Layer 1: The Hero Image
              Positioned.fill(
                child: Hero(
                  tag: 'restaurant-image-${widget.restaurantId}',
                  child: Image.network(
                    widget.restaurantImageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              // Layer 2: A gradient overlay for text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Layer 3: The back button
              Positioned(
                top: 40,
                left: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              
              // Layer 4: The scrolling list of dishes
              Positioned.fill(
                top: 150, // Start the list below the main image area
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                      topRight: Radius.circular(AppConstants.borderRadiusLarge),
                    ),
                  ),
                  child: FutureBuilder<List<Dish>>(
                    future: _dishesFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                      }
                      final dishes = snapshot.data!;
                      if (dishes.isEmpty) {
                        return const Center(
                            child: Text('لا توجد أطباق متاحة في هذا المطعم'));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(AppConstants.l, AppConstants.l, AppConstants.l, 80), // Add padding at the bottom
                        itemCount: dishes.length,
                        itemBuilder: (context, index) {
                          final dish = dishes[index];
                          // Your DishCard logic here remains the same
                          return DishCard(
                            dish: dish,
                            onAddToCart: () {
                              final cartService = Provider.of<CartService>(context, listen: false);
                              if (cartService.canAddItem(dish)) {
                                cartService.addItem(dish);
                                HapticFeedback.lightImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppTheme.textPrimary,
                                    content: Text('تمت إضافة ${dish.name}!', style: const TextStyle(color: AppTheme.textOnPrimary)),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Colors.red,
                                    content: Text('لا يمكنك الطلب من مطاعم مختلفة في نفس الوقت', style: TextStyle(color: AppTheme.textOnPrimary)),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}