// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/models/dish_model.dart';
import 'package:food_delivery_app/models/restaurant_model.dart';
import 'package:food_delivery_app/screens/admin/admin_dashboard.dart'; // CORRECT IMPORT
import 'package:food_delivery_app/screens/restaurant/restaurant_dashboard.dart';
import 'package:food_delivery_app/screens/role_selection_screen.dart';
import 'package:food_delivery_app/screens/client/client_home_screen.dart';
import 'package:food_delivery_app/services/cart_service.dart';
import 'package:food_delivery_app/services/order_service.dart';
import 'package:food_delivery_app/services/auth_service.dart';
import 'package:food_delivery_app/services/favorites_service.dart';
import 'package:food_delivery_app/services/admin_service.dart';
import 'package:food_delivery_app/services/location_service.dart';
import 'package:food_delivery_app/services/notification_service.dart';
import 'package:food_delivery_app/services/cache_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize cache first for offline support
  await CacheService.init();
  
  await Hive.initFlutter();
  Hive.registerAdapter(RestaurantAdapter());
  Hive.registerAdapter(DishAdapter());

  await Supabase.initialize(
    url: 'https://opusisnfqbkiaqljojmn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9wdXNpc25mcWJraWFxbGpvam1uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQzNDY5NzksImV4cCI6MjA2OTkyMjk3OX0.S3P_DavkKZ5fmK4PcvntEVBieVwoTQEV6FLSN-vv73U',
  );
  
  runApp(const FoodApp());
}

final supabase = Supabase.instance.client;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FoodApp extends StatefulWidget {
  const FoodApp({Key? key}) : super(key: key);
  @override
  State<FoodApp> createState() => _FoodAppState();
}

class _FoodAppState extends State<FoodApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _handleRedirect(data.session);
      } else if (event == AuthChangeEvent.signedOut) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
          (route) => false,
        );
      }
    });
  }

  Future<void> _handleRedirect(Session? session) async {
    if (session == null) return;
    try {
      final userId = session.user.id;
      final response = await supabase.from('profiles').select('role').eq('id', userId).single();
      final role = response['role'];
      if (role == 'admin') {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
          (route) => false,
        );
      } else if (role == 'owner') {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RestaurantDashboard()),
          (route) => false,
        );
      } else {
        // Customer role - go to client home
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ClientHomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // If no profile, assume customer
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ClientHomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => CartService()),
        ChangeNotifierProvider(create: (context) => OrderService()),
        ChangeNotifierProvider(create: (context) => FavoritesService()),
        ChangeNotifierProvider(create: (context) => AdminService()),
        ChangeNotifierProvider(create: (context) => LocationService()),
        ChangeNotifierProvider(create: (context) => NotificationService()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Food Delivery App',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: const RoleSelectionScreen(),
      ),
    );
  }
}