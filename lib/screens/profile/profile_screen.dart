// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:food_delivery_app/main.dart';
import 'package:food_delivery_app/theme.dart';
import 'package:food_delivery_app/models/user_model.dart';
import 'package:food_delivery_app/screens/role_selection_screen.dart';
import 'package:food_delivery_app/screens/profile/order_history_screen.dart';
import 'package:food_delivery_app/screens/profile/favorite_restaurants_screen.dart';
import 'package:food_delivery_app/screens/profile/manage_addresses_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _selectedImage;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _navigateToLogin();
        return;
      }

      // Fetch user profile from profiles table
      final response = await supabase
          .from('profiles')
          .select('*, email')
          .eq('id', user.id)
          .single();

      final profileData = {
        ...response,
        'email': user.email,
        'email_verified': user.emailConfirmedAt != null,
      };

      setState(() {
        _userProfile = UserProfile.fromMap(profileData);
        _fullNameController.text = _userProfile?.fullName ?? '';
        _phoneController.text = _userProfile?.phone ?? '';
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الملف الشخصي: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _navigateToLogin();
        return;
      }

      String? imageUrl = _userProfile?.profileImageUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        final fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final imageBytes = await _selectedImage!.readAsBytes();
        
        await supabase.storage
            .from('profile_images')
            .uploadBinary(fileName, imageBytes);
        
        imageUrl = supabase.storage
            .from('profile_images')
            .getPublicUrl(fileName);
      }

      // Update profile in database
      await supabase.from('profiles').update({
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profile_image_url': imageUrl,
      }).eq('id', user.id);

      // Update auth metadata
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': _fullNameController.text.trim(),
            'phone': _phoneController.text.trim(),
          },
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث الملف الشخصي بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUserProfile(); // Reload to get updated data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الملف الشخصي: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      _navigateToLogin();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الخروج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.xl),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image Section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : _userProfile?.profileImageUrl != null
                              ? NetworkImage(_userProfile!.profileImageUrl!)
                              : null,
                      child: _selectedImage == null && _userProfile?.profileImageUrl == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primary,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.xl),

              // User Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معلومات الحساب',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppConstants.m),
                      
                      // Email (Read-only)
                      TextFormField(
                        initialValue: _userProfile?.email,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          prefixIcon: Icon(Icons.email_outlined),
                          enabled: false,
                        ),
                      ),
                      const SizedBox(height: AppConstants.m),

                      // Role (Read-only)
                      TextFormField(
                        initialValue: _userProfile?.role == 'owner' ? 'صاحب مطعم' : 'مسؤول',
                        decoration: const InputDecoration(
                          labelText: 'نوع الحساب',
                          prefixIcon: Icon(Icons.badge_outlined),
                          enabled: false,
                        ),
                      ),
                      const SizedBox(height: AppConstants.m),

                      // Email Verification Status
                      Row(
                        children: [
                          Icon(
                            _userProfile?.emailVerified == true
                                ? Icons.verified
                                : Icons.warning,
                            color: _userProfile?.emailVerified == true
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: AppConstants.s),
                          Text(
                            _userProfile?.emailVerified == true
                                ? 'البريد الإلكتروني مؤكد'
                                : 'البريد الإلكتروني غير مؤكد',
                            style: TextStyle(
                              color: _userProfile?.emailVerified == true
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.l),

              // Menu Options Card
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('سجل الطلبات'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const OrderHistoryScreen(),
                        ));
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.favorite_border),
                      title: const Text('المطاعم المفضلة'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const FavoriteRestaurantsScreen(),
                        ));
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: const Text('عناويني'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Navigate to Address Management Screen
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.l),

              // Editable Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المعلومات الشخصية',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppConstants.m),

                      // Full Name
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'الاسم الكامل',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'الرجاء إدخال الاسم الكامل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.m),

                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'الرجاء إدخال رقم الهاتف';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.xl),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppConstants.m),
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.textOnPrimary,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('حفظ التغييرات'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}