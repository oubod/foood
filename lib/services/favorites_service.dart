import 'package:flutter/foundation.dart';
import 'package:food_delivery_app/main.dart';

class FavoritesService extends ChangeNotifier {
  Set<String> _favoriteRestaurantIds = {};
  bool _isLoading = false;

  Set<String> get favoriteRestaurantIds => _favoriteRestaurantIds;
  bool get isLoading => _isLoading;

  FavoritesService() {
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    _isLoading = true;
    notifyListeners();
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final response = await supabase
          .from('favorites')
          .select('restaurant_id')
          .eq('user_id', userId);
      _favoriteRestaurantIds = {
        for (final fav in response) fav['restaurant_id'] as String
      };
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isFavorite(String restaurantId) {
    return _favoriteRestaurantIds.contains(restaurantId);
  }

  Future<void> addFavorite(String restaurantId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await supabase.from('favorites').insert({
        'user_id': userId,
        'restaurant_id': restaurantId,
      });
      _favoriteRestaurantIds.add(restaurantId);
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> removeFavorite(String restaurantId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await supabase.from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('restaurant_id', restaurantId);
      _favoriteRestaurantIds.remove(restaurantId);
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> toggleFavorite(String restaurantId) async {
    if (isFavorite(restaurantId)) {
      await removeFavorite(restaurantId);
    } else {
      await addFavorite(restaurantId);
    }
  }

  Future<List<Map<String, dynamic>>> fetchFavoriteRestaurants() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await supabase
        .from('favorites')
        .select('restaurant_id, restaurants(*)')
        .eq('user_id', userId);
    return response;
  }
}