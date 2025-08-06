// lib/screens/restaurant/tabs/restaurant_profile_tab.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/main.dart';
import 'package:food_delivery_app/models/restaurant_model.dart';
import 'package:food_delivery_app/theme.dart';
import 'package:image_picker/image_picker.dart';

class RestaurantProfileTab extends StatefulWidget {
  final Restaurant restaurant;
  const RestaurantProfileTab({Key? key, required this.restaurant}) : super(key: key);

  @override
  State<RestaurantProfileTab> createState() => _RestaurantProfileTabState();
}

class _RestaurantProfileTabState extends State<RestaurantProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cuisineController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isOpen = true;
  bool _isSaving = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.restaurant.name;
    _cuisineController.text = widget.restaurant.cuisine ?? '';
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSaving = true; });

    try {
      String? imageUrl = widget.restaurant.imageUrl;

      if (_selectedImage != null) {
        final fileName = 'restaurant_${widget.restaurant.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final imageBytes = await _selectedImage!.readAsBytes();
        
        await supabase.storage
            .from('restaurant_images')
            .uploadBinary(fileName, imageBytes);
        
        imageUrl = supabase.storage
            .from('restaurant_images')
            .getPublicUrl(fileName);
      }

      await supabase.from('restaurants').update({
        'name': _nameController.text,
        'cuisine': _cuisineController.text,
        'image_url': imageUrl,
      }).eq('id', widget.restaurant.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث بيانات المطعم بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التحديث: $e')),
        );
      }
    } finally {
      setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.m),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Restaurant Image
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : widget.restaurant.imageUrl != null
                            ? NetworkImage(widget.restaurant.imageUrl!)
                            : null,
                    child: _selectedImage == null && widget.restaurant.imageUrl == null
                        ? const Icon(Icons.restaurant, size: 60)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primary,
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.xl),

            // Restaurant Status
            Card(
              child: SwitchListTile(
                title: const Text('حالة المطعم'),
                subtitle: Text(_isOpen ? 'مفتوح' : 'مغلق'),
                value: _isOpen,
                onChanged: (value) => setState(() => _isOpen = value),
              ),
            ),
            const SizedBox(height: AppConstants.m),

            // Restaurant Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('بيانات المطعم', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppConstants.m),
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المطعم',
                        prefixIcon: Icon(Icons.restaurant),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'اسم المطعم مطلوب' : null,
                    ),
                    const SizedBox(height: AppConstants.m),
                    
                    TextFormField(
                      controller: _cuisineController,
                      decoration: const InputDecoration(
                        labelText: 'نوع المأكولات',
                        prefixIcon: Icon(Icons.fastfood),
                      ),
                    ),
                    const SizedBox(height: AppConstants.m),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'وصف المطعم',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
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
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppConstants.m),
                  backgroundColor: AppTheme.primary,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('حفظ التغييرات'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cuisineController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}