// lib/screens/restaurant/tabs/enhanced_menu_tab.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/main.dart';
import 'package:food_delivery_app/models/dish_model.dart';
import 'package:food_delivery_app/models/restaurant_model.dart';
import 'package:food_delivery_app/theme.dart';
import 'package:image_picker/image_picker.dart';

class EnhancedMenuTab extends StatefulWidget {
  final Restaurant restaurant;
  final List<Dish> dishes;

  const EnhancedMenuTab({Key? key, required this.restaurant, required this.dishes}) : super(key: key);

  @override
  State<EnhancedMenuTab> createState() => _EnhancedMenuTabState();
}

class _EnhancedMenuTabState extends State<EnhancedMenuTab> {
  List<Dish> _dishes = [];

  @override
  void initState() {
    super.initState();
    _dishes = List.from(widget.dishes);
  }

  Future<void> _addOrEditDish({Dish? dish}) async {
    final result = await showDialog<Dish>(
      context: context,
      builder: (context) => _DishFormDialog(restaurant: widget.restaurant, dish: dish),
    );
    
    if (result != null) {
      setState(() {
        if (dish == null) {
          _dishes.add(result);
        } else {
          final index = _dishes.indexWhere((d) => d.id == dish.id);
          if (index != -1) _dishes[index] = result;
        }
      });
    }
  }

  Future<void> _deleteDish(Dish dish) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الطبق'),
        content: Text('هل تريد حذف "${dish.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('dishes').delete().eq('id', dish.id);
        setState(() => _dishes.removeWhere((d) => d.id == dish.id));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحذف: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _dishes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('لا يوجد أطباق في القائمة'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _addOrEditDish(),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة أول طبق'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.m),
              itemCount: _dishes.length,
              itemBuilder: (context, index) {
                final dish = _dishes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppConstants.m),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: dish.imageUrl.isNotEmpty ? NetworkImage(dish.imageUrl) : null,
                      child: dish.imageUrl.isEmpty ? const Icon(Icons.fastfood) : null,
                    ),
                    title: Text(dish.name),
                    subtitle: Text('${dish.description}\n${dish.price} د.ل'),
                    isThreeLine: true,
                    trailing: PopupMenuButton(
                      onSelected: (value) {
                        if (value == 'edit') _addOrEditDish(dish: dish);
                        if (value == 'delete') _deleteDish(dish);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                        const PopupMenuItem(value: 'delete', child: Text('حذف')),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditDish(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DishFormDialog extends StatefulWidget {
  final Restaurant restaurant;
  final Dish? dish;

  const _DishFormDialog({required this.restaurant, this.dish});

  @override
  State<_DishFormDialog> createState() => _DishFormDialogState();
}

class _DishFormDialogState extends State<_DishFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  File? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.dish != null) {
      _nameController.text = widget.dish!.name;
      _descriptionController.text = widget.dish!.description;
      _priceController.text = widget.dish!.price.toString();
    }
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _saveDish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? imageUrl = widget.dish?.imageUrl;

      if (_selectedImage != null) {
        final fileName = 'dish_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final imageBytes = await _selectedImage!.readAsBytes();
        
        await supabase.storage.from('dish_images').uploadBinary(fileName, imageBytes);
        imageUrl = supabase.storage.from('dish_images').getPublicUrl(fileName);
      }

      final dishData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'image_url': imageUrl ?? '',
        'restaurant_id': widget.restaurant.id,
      };

      if (widget.dish == null) {
        final response = await supabase.from('dishes').insert(dishData).select().single();
        final newDish = Dish.fromMap(response);
        Navigator.pop(context, newDish);
      } else {
        await supabase.from('dishes').update(dishData).eq('id', widget.dish!.id);
        final updatedDish = Dish(
          id: widget.dish!.id,
          name: _nameController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          imageUrl: imageUrl ?? '',
          restaurantId: widget.restaurant.id,
        );
        Navigator.pop(context, updatedDish);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الحفظ: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dish == null ? 'إضافة طبق جديد' : 'تعديل الطبق'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : widget.dish?.imageUrl.isNotEmpty == true
                          ? Image.network(widget.dish!.imageUrl, fit: BoxFit.cover)
                          : const Icon(Icons.camera_alt),
                ),
              ),
              const SizedBox(height: AppConstants.m),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم الطبق'),
                validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'الوصف'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'السعر'),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveDish,
          child: _isSaving ? const CircularProgressIndicator() : const Text('حفظ'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}