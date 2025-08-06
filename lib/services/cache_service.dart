import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheService {
  static late SharedPreferences _prefs;
  static bool _initialized = false;

  static Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // Cache restaurants
  static Future<void> cacheRestaurants(List<Map<String, dynamic>> restaurants) async {
    await init();
    await _prefs.setString('cached_restaurants', jsonEncode(restaurants));
    await _prefs.setString('restaurants_cache_time', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>>? getCachedRestaurants() {
    if (!_initialized) return null;
    final cached = _prefs.getString('cached_restaurants');
    if (cached != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(cached));
    }
    return null;
  }

  // Cache dishes for a restaurant
  static Future<void> cacheDishes(String restaurantId, List<Map<String, dynamic>> dishes) async {
    await init();
    await _prefs.setString('cached_dishes_$restaurantId', jsonEncode(dishes));
  }

  static List<Map<String, dynamic>>? getCachedDishes(String restaurantId) {
    if (!_initialized) return null;
    final cached = _prefs.getString('cached_dishes_$restaurantId');
    if (cached != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(cached));
    }
    return null;
  }

  // Cache user profile
  static Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
    await init();
    await _prefs.setString('cached_user_profile', jsonEncode(profile));
  }

  static Map<String, dynamic>? getCachedUserProfile() {
    if (!_initialized) return null;
    final cached = _prefs.getString('cached_user_profile');
    if (cached != null) {
      return Map<String, dynamic>.from(jsonDecode(cached));
    }
    return null;
  }

  // Cache orders
  static Future<void> cacheOrders(List<Map<String, dynamic>> orders) async {
    await init();
    await _prefs.setString('cached_orders', jsonEncode(orders));
  }

  static List<Map<String, dynamic>>? getCachedOrders() {
    if (!_initialized) return null;
    final cached = _prefs.getString('cached_orders');
    if (cached != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(cached));
    }
    return null;
  }

  // Clear all cache
  static Future<void> clearCache() async {
    await init();
    final keys = _prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('cached_')) {
        await _prefs.remove(key);
      }
    }
  }

  // Check if cache is valid (not expired)
  static bool isCacheValid(String cacheKey, {int maxAgeMinutes = 30}) {
    if (!_initialized) return false;
    final cacheTime = _prefs.getString('${cacheKey}_cache_time');
    if (cacheTime != null) {
      final cached = DateTime.parse(cacheTime);
      final now = DateTime.now();
      return now.difference(cached).inMinutes < maxAgeMinutes;
    }
    return false;
  }

  // Get app settings
  static bool getOfflineMode() {
    if (!_initialized) return false;
    return _prefs.getBool('offline_mode') ?? false;
  }

  static Future<void> setOfflineMode(bool value) async {
    await init();
    await _prefs.setBool('offline_mode', value);
  }
}