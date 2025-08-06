// lib/screens/client/checkout_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import
import 'package:food_delivery_app/main.dart';
import 'package:food_delivery_app/services/cart_service.dart';
import 'package:food_delivery_app/services/order_service.dart'; // <<< ADD THIS LINE
import 'package:food_delivery_app/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:food_delivery_app/services/auth_service.dart';
import 'package:food_delivery_app/models/user_model.dart';
import 'package:food_delivery_app/screens/auth/login_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
// Import the tracking screen we will create next
import 'package:food_delivery_app/screens/client/order_tracking_screen.dart';
import 'package:food_delivery_app/screens/client/client_home_screen.dart'; // <<< ADD THIS LINE
import 'package:food_delivery_app/screens/profile/profile_screen.dart';
import 'package:food_delivery_app/screens/client/client_auth_screen.dart';


class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

enum PaymentMethod { cash, electronic }

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  
  UserProfile? _userProfile;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  XFile? _proofImage;
  bool _isLoading = false;
  Position? _currentPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAuthAndLoadProfile();
  }

  Future<void> _checkAuthAndLoadProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isAuthenticated || authService.currentUser == null) {
      // If user is not logged in, show a dialog and navigate them to login.
      // Using addPostFrameCallback to safely show a dialog from didChangeDependencies.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('تسجيل الدخول مطلوب'),
            content: const Text('يجب عليك تسجيل الدخول أو إنشاء حساب للمتابعة.'),
            actions: [
              TextButton(
                onPressed: () {
                  // Pop the dialog and the checkout screen to go back
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Pop the dialog
                  // Replace the checkout screen with the auth screen
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const ClientAuthScreen(),
                  ));
                },
                child: const Text('تسجيل الدخول / إنشاء حساب'),
              ),
            ],
          ),
        );
      });
    } else {
      setState(() {
        _userProfile = authService.currentUser;
      });
    }
  }




  // Handle picking an image from the gallery
  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _proofImage = image;
      });
    }
  }

  // The main function to place the order
  Future<void> _placeOrder() async {
    // Validation checks
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, do nothing
    }
    
    final cartService = Provider.of<CartService>(context, listen: false);
    if (cartService.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('السلة فارغة'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    
    if (_paymentMethod == PaymentMethod.electronic && _proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('الرجاء تحميل إثبات الدفع'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('الرجاء إدخال عنوان التوصيل'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      String? proofUrl;

      // 1. Upload payment proof if electronic payment is chosen
      if (_paymentMethod == PaymentMethod.electronic && _proofImage != null) {
        final imageFile = File(_proofImage!.path);
        final fileName = 'payment_proof_${_userProfile!.id}_${DateTime.now().millisecondsSinceEpoch}.png';
        
        await supabase.storage
            .from('payment_proofs')
            .upload(fileName, imageFile);
            
        proofUrl = supabase.storage
            .from('payment_proofs')
            .getPublicUrl(fileName);
      }

      // 2. Prepare order items for the RPC
      final orderItems = cartService.items.map((item) => {
        'dish_id': item.dish.id,
        'quantity': item.quantity,
        'unit_price': item.dish.price
      }).toList();
      
      // 3. Prepare location data
      final Map<String, dynamic>? locationData = _currentPosition != null
        ? {'lat': _currentPosition!.latitude, 'lng': _currentPosition!.longitude, 'address': _locationController.text}
        : {'address': _locationController.text};

      // 4. Call the PostgreSQL function with correct parameters
      final result = await supabase.rpc('create_order', params: {
        'restaurant_id': cartService.items.first.dish.restaurantId,
        'total_price': cartService.totalPrice,
        'payment_method': _paymentMethod == PaymentMethod.electronic ? 'electronic' : 'cash',
        'order_items': orderItems,
        'payment_proof_url': proofUrl,
        'customer_location': locationData,
      });

      final newOrderId = result.toString(); // Ensure it's a string
      print('Created order with ID: $newOrderId'); // Debug log

      // Add haptic feedback for successful order placement
      HapticFeedback.heavyImpact();

      // Start tracking the new order globally
      Provider.of<OrderService>(context, listen: false).startTrackingOrder(newOrderId);

      // Clear the local cart
      cartService.clearCart();

      // Navigate to order tracking screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderTrackingScreen(orderId: newOrderId),
          ),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('فشل إنشاء الطلب: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('خدمات الموقع معطلة. الرجاء تفعيلها.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفض إذن الوصول للموقع.')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم رفض إذن الموقع بشكل دائم، لا يمكننا طلب الإذن.')));
      return;
    }

    // When we reach here, permissions are granted and we can
          // continue accessing the position of the device.
      setState(() { _isLoading = true; }); // Show a loading indicator
      try {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentPosition = position;
        });
        
        // Optional: Convert coordinates to an address
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        String address = "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
        if(placemarks.isNotEmpty) {
            final place = placemarks.first;
            address = "${place.street}, ${place.locality}, ${place.country}";
        }

        _locationController.text = address;

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل الحصول على الموقع: $e')));
      } finally {
        setState(() { _isLoading = false; });
      }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدفع')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.l),
        child: Form(
          key: _formKey,
          child: _userProfile == null 
            ? const Center(child: CircularProgressIndicator()) 
            : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Information Section
              Text('معلومات التوصيل', style: AppTheme.textTheme.titleLarge),
              const SizedBox(height: AppConstants.l),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(_userProfile!.fullName ?? 'مستخدم غير معروف'),
                  subtitle: Text(_userProfile!.phone ?? 'لا يوجد رقم هاتف'),
                  trailing: TextButton(
                    child: const Text('تعديل'),
                    onPressed: () {
                      // Navigate to profile screen to edit details
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ));
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.m),
              // Location Input
              TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'العنوان أو نقطة GPS'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _getCurrentLocation,
                  icon: const Icon(Icons.my_location, size: 16),
                  label: const Text('استخدام موقعي الحالي'),
                ),
              ),
              const SizedBox(height: AppConstants.xl),
              
              Text('طريقة الدفع', style: AppTheme.textTheme.titleLarge),
              RadioListTile<PaymentMethod>(
                title: const Text('كاش عند الاستلام'),
                value: PaymentMethod.cash,
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              RadioListTile<PaymentMethod>(
                title: const Text('دفع إلكتروني (بنكلي، مسروفي)'),
                value: PaymentMethod.electronic,
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              
              if (_paymentMethod == PaymentMethod.electronic)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.l, vertical: AppConstants.s),
                  child: _proofImage == null
                      ? OutlinedButton.icon(icon: const Icon(Icons.upload_file), label: const Text('تحميل إثبات الدفع'), onPressed: _pickImage)
                      : Row(children: [const Icon(Icons.check_circle, color: Colors.green), const SizedBox(width: AppConstants.s), const Expanded(child: Text('تم تحميل الصورة بنجاح'))]),
                ),

              const SizedBox(height: AppConstants.xl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: AppConstants.m)),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('تأكيد الطلب', style: TextStyle(color: AppTheme.textOnPrimary, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
