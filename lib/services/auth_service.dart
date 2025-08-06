// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:food_delivery_app/main.dart';
import 'package:food_delivery_app/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  UserProfile? _currentUser;
  bool _isLoading = false;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _init();
  }

  void _init() {
    // Listen to auth state changes
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _loadUserProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        notifyListeners();
      }
    });

    // Load current user if already signed in
    if (supabase.auth.currentUser != null) {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null || user.id.isEmpty) return;

    try {
      final response = await supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

      _currentUser = UserProfile.fromMap({
        ...response,
        'email': user.email ?? '',
        'email_verified': user.emailConfirmedAt != null,
      });
      
      notifyListeners();
    } catch (e) {
      // If profile doesn't exist, create it
      if (user.id.isNotEmpty) {
        try {
          await supabase.from('profiles').upsert({
            'id': user.id,
            'role': 'customer',
            'full_name': user.userMetadata?['full_name'] ?? 'مستخدم',
            'phone': user.userMetadata?['phone'],
          });
          
          // Try loading again
          final response = await supabase
              .from('profiles')
              .select('*')
              .eq('id', user.id)
              .single();

          _currentUser = UserProfile.fromMap({
            ...response,
            'email': user.email ?? '',
            'email_verified': user.emailConfirmedAt != null,
          });
          
          notifyListeners();
        } catch (createError) {
          print('Error creating/loading user profile: $createError');
        }
      }
    }
  }

  Future<UserProfile?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    _setLoading(true);
    
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': role,
        },
      );

      if (response.user != null) {
        // Profile will be created automatically by database trigger
        await _loadUserProfile();
        return _currentUser;
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
    return null;
  }

  Future<UserProfile?> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      await _loadUserProfile();
      return _currentUser;
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await supabase.auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? profileImageUrl,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    _setLoading(true);
    
    try {
      // Update in profiles table
      await supabase.from('profiles').update({
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      }).eq('id', user.id);

      // Update auth metadata
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            if (fullName != null) 'full_name': fullName,
            if (phone != null) 'phone': phone,
          },
        ),
      );

      // Reload profile
      await _loadUserProfile();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    await supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> resendEmailConfirmation() async {
    final user = supabase.auth.currentUser;
    if (user?.email != null) {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: user!.email!,
      );
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}