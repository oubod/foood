// lib/screens/client/client_home_screen.dart
import 'dart:async'; // Add this import
import 'package:flutter/material.dart';
import 'package:food_delivery_app/screens/client/restaurant_menu_screen.dart';
import 'package:provider/provider.dart';
import 'package:food_delivery_app/services/order_service.dart';
import 'package:food_delivery_app/services/auth_service.dart';
import 'package:food_delivery_app/services/cart_service.dart';
import 'package:food_delivery_app/screens/client/order_tracking_screen.dart';
import 'package:food_delivery_app/screens/profile/profile_screen.dart';
import 'package:food_delivery_app/screens/auth/login_screen.dart';
import 'package:food_delivery_app/screens/client/cart_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:food_delivery_app/widgets/restaurant_card_skeleton.dart';
import '../../main.dart'; // Import to get the 'supabase' client instance
import '../../theme.dart';
import 'package:food_delivery_app/widgets/restaurant_card.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:food_delivery_app/models/restaurant_model.dart';
import 'package:food_delivery_app/services/cache_service.dart';
import 'package:geolocator/geolocator.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  // --- REPLACEMENT START ---
  List<Restaurant> _restaurants = []; // Now uses the model
  bool _isLoading = true;
  bool _isSortByNearby = false; // Add this back
  // --- REPLACEMENT END ---

  String? _lastShownStatus;

  @override
  void initState() {
    super.initState();
    _fetchRestaurants(); // Initial fetch
  }
  
  @override
  void dispose() {
    // Nothing to dispose of for now
    super.dispose();
  }

  // --- NEW METHODS ---
  Future<void> _fetchRestaurants({bool sortByNearby = false}) async {
    // Try to load from cache first for instant display
    final cachedRestaurants = CacheService.getCachedRestaurants();
    if (cachedRestaurants != null && !sortByNearby) {
      final restaurants = cachedRestaurants.map<Restaurant>((map) => Restaurant(
        id: map['id'],
        name: map['name'],
        cuisine: map['cuisine'],
        imageUrl: map['image_url'],
      )).toList();
      
      if (mounted) {
        setState(() {
          _restaurants = restaurants;
          _isLoading = false;
        });
      }
      
      // Continue to update from network in background
    } else {
      setState(() {
        _isLoading = true;
        if(sortByNearby) _restaurants = [];
      });
    }

    try {
      if (sortByNearby) {
        final position = await _determinePosition();
        final data = await supabase.rpc('nearby_restaurants', params: {
          'lat': position.latitude,
          'long': position.longitude,
        });
        final nearbyRestaurants = data.map<Restaurant>((map) => Restaurant(
            id: map['id'],
            name: map['name'],
            cuisine: map['cuisine'],
            imageUrl: map['image_url'],
        )).toList();
        if (mounted) setState(() => _restaurants = nearbyRestaurants);

      } else {
        // First try to get from cache for instant display
        final cachedData = CacheService.getCachedRestaurants();
        if (cachedData != null && mounted) {
          final cachedRestaurants = cachedData.map<Restaurant>((map) => Restaurant.fromMap(map)).toList();
          setState(() {
            _restaurants = cachedRestaurants;
            _isLoading = false;
          });
        }

        // Then fetch fresh data in background
        try {
          final data = await supabase
              .from('restaurants')
              .select()
              .order('created_at')
              .limit(20); // Limit to improve performance
          
          final freshRestaurants = data.map((map) => Restaurant.fromMap(map)).toList();
          
          // Cache the fresh data
          await CacheService.cacheRestaurants(data);
          
          // Update Hive cache in background
          final box = await Hive.openBox<Restaurant>('restaurants');
          await box.clear();
          await box.putAll(Map.fromEntries(freshRestaurants.map((r) => MapEntry(r.id, r))));
          
          // Only update if not sorting by nearby, to avoid overwriting results
          if (mounted && !_isSortByNearby) {
            setState(() => _restaurants = freshRestaurants);
          }
        } catch (e) {
          // If network fails, stick with cached data
          print('Network error, using cached data: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
    // --- HYBRID LOGIC END ---
  }

  Future<Position> _determinePosition() async {
    // It handles service checks and permissions for Geolocator.
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Location permissions are denied');
    }
    if (permission == LocationPermission.deniedForever) return Future.error('Location permissions are permanently denied');
    return await Geolocator.getCurrentPosition();
  }
  // --- END OF NEW METHODS ---

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderService>(
      builder: (context, orderService, child) {
        // Popup logic remains the same...
        if (orderService.isTrackingOrder && orderService.activeOrderStatus != _lastShownStatus) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('تحديث الطلب: ${orderService.activeOrderStatus}'),
              backgroundColor: AppTheme.primary,
            ));
            _lastShownStatus = orderService.activeOrderStatus;
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('المطاعم'),
            centerTitle: false,
            actions: [
              // Cart Icon
              Consumer<CartService>(
                builder: (context, cartService, child) {
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const CartScreen(),
                          ));
                        },
                      ),
                      if (cartService.totalItems > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Text(
                              '${cartService.totalItems}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              // Profile/Account Icon
              Consumer<AuthService>(
                builder: (context, authService, child) {
                  return PopupMenuButton<String>(
                    icon: CircleAvatar(
                      radius: 18,
                      backgroundImage: authService.currentUser?.profileImageUrl != null
                          ? NetworkImage(authService.currentUser!.profileImageUrl!)
                          : null,
                      child: authService.currentUser?.profileImageUrl == null
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    ),
                    onSelected: (value) async {
                      switch (value) {
                        case 'profile':
                          if (authService.isAuthenticated) {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ));
                          } else {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ));
                          }
                          break;
                        case 'login':
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ));
                          break;
                        case 'logout':
                          await authService.signOut();
                          break;
                      }
                    },
                    itemBuilder: (context) {
                      if (authService.isAuthenticated) {
                        return [
                          PopupMenuItem<String>(
                            value: 'profile',
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline),
                                const SizedBox(width: 8),
                                Text(authService.currentUser?.fullName ?? 'الملف الشخصي'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout),
                                SizedBox(width: 8),
                                Text('تسجيل الخروج'),
                              ],
                            ),
                          ),
                        ];
                      } else {
                        return [
                          const PopupMenuItem<String>(
                            value: 'login',
                            child: Row(
                              children: [
                                Icon(Icons.login),
                                SizedBox(width: 8),
                                Text('تسجيل الدخول'),
                              ],
                            ),
                          ),
                        ];
                      }
                    },
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              if (orderService.isTrackingOrder)
                _buildActiveOrderBanner(context, orderService),
              
              // --- NEW "NEARBY" BUTTON ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.l, vertical: AppConstants.s),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilterChip(
                      label: const Text('الأقرب مني'),
                      avatar: const Icon(Icons.location_on_outlined, size: 16),
                      selected: false, // Always false now
                      onSelected: (isSelected) {
                        // Do nothing, just a placeholder
                      },
                      selectedColor: AppTheme.primary.withOpacity(0.2),
                      showCheckmark: false,
                    ),
                  ],
                ),
              ),
              // --- END OF "NEARBY" BUTTON ---

              // --- NEW UI LOGIC (replaces FutureBuilder) ---
              Expanded(
                child: _isLoading
                    ? Shimmer.fromColors( // Show shimmer while loading
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppConstants.l),
                          itemCount: 5,
                          itemBuilder: (context, index) => const RestaurantCardSkeleton(),
                        ),
                      )
                    : _restaurants.isEmpty
                        ? Center( // Show empty state if no results
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset('assets/images/no_restaurants.svg', height: 120, color: AppTheme.iconDefault),
                                const SizedBox(height: AppConstants.l),
                                Text('لم يتم العثور على نتائج', style: AppTheme.textTheme.titleLarge),
                                const SizedBox(height: AppConstants.s),
                                Text('جرّب كلمة بحث مختلفة', style: AppTheme.textTheme.bodyMedium),
                              ],
                            ),
                          )
                        : ListView.builder( // Show the results
                            padding: const EdgeInsets.symmetric(horizontal: AppConstants.l),
                            itemCount: _restaurants.length,
                            itemBuilder: (context, index) {
                              final restaurant = _restaurants[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (context) => RestaurantMenuScreen(
                                      restaurantId: restaurant.id,
                                      restaurantName: restaurant.name,
                                      restaurantImageUrl: restaurant.imageUrl ?? '',
                                    ),
                                  ));
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
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveOrderBanner(BuildContext context, OrderService orderService) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => OrderTrackingScreen(orderId: orderService.activeOrderId!),
        ));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.l, vertical: AppConstants.m),
        color: AppTheme.accentOrange['background'],
        child: Row(
          children: [
            const Icon(Icons.delivery_dining_outlined, color: AppTheme.primary),
            const SizedBox(width: AppConstants.m),
            Expanded(
              child: Text(
                'لديك طلب قيد التنفيذ: ${orderService.activeOrderStatus ?? "جاري التحميل..."}',
                style: AppTheme.textTheme.bodyLarge,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}