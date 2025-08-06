import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/address_model.dart';

class LocationService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Position? _currentPosition;
  String? _currentAddress;
  List<UserAddress> _savedAddresses = [];
  bool _isLoading = false;
  String? _error;

  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  List<UserAddress> get savedAddresses => _savedAddresses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _error = 'خدمات الموقع غير مفعلة';
      notifyListeners();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _error = 'تم رفض إذن الموقع';
        notifyListeners();
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _error = 'إذن الموقع مرفوض نهائياً';
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<void> getCurrentLocation() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (!await checkPermissions()) return;

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _getAddressFromCoordinates(_currentPosition!);
    } catch (e) {
      _error = 'فشل في الحصول على الموقع: ${e.toString()}';
      if (kDebugMode) print('Error getting location: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _getAddressFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentAddress = '${place.street}, ${place.locality}, ${place.country}';
      }
    } catch (e) {
      if (kDebugMode) print('Error getting address: $e');
      _currentAddress = 'عنوان غير محدد';
    }
  }

  Future<void> fetchSavedAddresses() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('user_addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      _savedAddresses = (response as List)
          .map((json) => UserAddress.fromJson(json))
          .toList();
    } catch (e) {
      _error = 'فشل في تحميل العناوين: ${e.toString()}';
      if (kDebugMode) print('Error fetching addresses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveAddress(UserAddress address) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (address.isDefault) {
        await _supabase
            .from('user_addresses')
            .update({'is_default': false})
            .eq('user_id', address.userId);
      }

      await _supabase.from('user_addresses').insert(address.toJson());
      await fetchSavedAddresses();
    } catch (e) {
      _error = 'فشل في حفظ العنوان: ${e.toString()}';
      if (kDebugMode) print('Error saving address: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _supabase.from('user_addresses').delete().eq('id', addressId);
      await fetchSavedAddresses();
    } catch (e) {
      _error = 'فشل في حذف العنوان: ${e.toString()}';
      if (kDebugMode) print('Error deleting address: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('user_addresses')
          .update({'is_default': false})
          .eq('user_id', userId);

      await _supabase
          .from('user_addresses')
          .update({'is_default': true})
          .eq('id', addressId);

      await fetchSavedAddresses();
    } catch (e) {
      _error = 'فشل في تعيين العنوان الافتراضي: ${e.toString()}';
      if (kDebugMode) print('Error setting default address: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}