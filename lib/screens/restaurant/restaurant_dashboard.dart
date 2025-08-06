// lib/screens/restaurant/restaurant_dashboard.dart

import 'package:flutter/material.dart';
import 'package:food_delivery_app/main.dart';
import 'package:food_delivery_app/models/dish_model.dart';
import 'package:food_delivery_app/models/restaurant_model.dart';
import 'package:food_delivery_app/screens/role_selection_screen.dart'; // CORRECT IMPORT
import 'package:food_delivery_app/screens/profile/profile_screen.dart';
import 'tabs/enhanced_menu_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/analytics_tab.dart';
import 'tabs/restaurant_profile_tab.dart';
import 'tabs/order_management_tab.dart';

class RestaurantDashboard extends StatefulWidget {
  const RestaurantDashboard({Key? key}) : super(key: key);

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard> {
  int _selectedIndex = 0;
  Restaurant? _restaurant;
  List<Dish> _dishes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantData();
  }

  Future<void> _fetchRestaurantData() async {
    setState(() { _isLoading = true; });
    try {
      final userId = supabase.auth.currentUser!.id;
      final restaurantData = await supabase.from('restaurants').select().eq('owner_id', userId).single();
      final restaurant = Restaurant.fromMap(restaurantData);
      final dishesData = await supabase.from('dishes').select().eq('restaurant_id', restaurant.id);
      final dishes = dishesData.map((map) => Dish.fromMap(map)).toList();
      setState(() {
        _restaurant = restaurant;
        _dishes = dishes;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطأ في جلب بيانات المطعم: $e'),
          backgroundColor: Colors.red,
        ));
        setState(() { _isLoading = false; });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      const OrderManagementTab(),
      _restaurant != null ? EnhancedMenuTab(restaurant: _restaurant!, dishes: _dishes) : const Center(child: Text('لم يتم العثور على مطعم')),
      _restaurant != null ? AnalyticsTab(restaurantId: _restaurant!.id) : const Center(child: Text('لم يتم العثور على مطعم')),
      _restaurant != null ? RestaurantProfileTab(restaurant: _restaurant!) : const Center(child: Text('لم يتم العثور على مطعم')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_restaurant?.name ?? 'لوحة التحكم'),
        actions: [
          // Profile/Account Icon
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ));
                  break;
                case 'logout':
                  await supabase.auth.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                      (_) => false,
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('الملف الشخصي'),
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
            ],
          ),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'الطلبات'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'القائمة'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'الإحصائيات'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}