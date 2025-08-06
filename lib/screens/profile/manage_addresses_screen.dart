import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../services/location_service.dart';
import '../../models/address_model.dart';
import '../../services/auth_service.dart';

class ManageAddressesScreen extends StatefulWidget {
  const ManageAddressesScreen({super.key});

  @override
  State<ManageAddressesScreen> createState() => _ManageAddressesScreenState();
}

class _ManageAddressesScreenState extends State<ManageAddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationService>().fetchSavedAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العناوين'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<LocationService>(
        builder: (context, locationService, child) {
          if (locationService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (locationService.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    locationService.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.m),
                  ElevatedButton(
                    onPressed: () {
                      locationService.clearError();
                      locationService.fetchSavedAddresses();
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.m),
                child: ElevatedButton.icon(
                  onPressed: () => _showAddAddressDialog(locationService),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة عنوان جديد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
              Expanded(
                child: locationService.savedAddresses.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off, size: 80, color: Colors.grey),
                            SizedBox(height: AppConstants.m),
                            Text('لا توجد عناوين محفوظة'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.m),
                        itemCount: locationService.savedAddresses.length,
                        itemBuilder: (context, index) {
                          final address = locationService.savedAddresses[index];
                          return _buildAddressCard(address, locationService);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressCard(UserAddress address, LocationService locationService) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.s),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getAddressIcon(address.label),
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: AppConstants.s),
                Expanded(
                  child: Text(
                    address.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.s,
                      vertical: AppConstants.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'افتراضي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.s),
            Text(
              address.fullAddress,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppConstants.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!address.isDefault)
                  TextButton(
                    onPressed: () => locationService.setDefaultAddress(address.id),
                    child: const Text('جعل افتراضي'),
                  ),
                TextButton(
                  onPressed: () => _confirmDelete(address, locationService),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('حذف'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAddressIcon(String label) {
    switch (label.toLowerCase()) {
      case 'منزل':
      case 'home':
        return Icons.home;
      case 'عمل':
      case 'work':
        return Icons.work;
      case 'أخرى':
      case 'other':
        return Icons.location_on;
      default:
        return Icons.location_on;
    }
  }

  void _showAddAddressDialog(LocationService locationService) {
    final labelController = TextEditingController();
    final address1Controller = TextEditingController();
    final address2Controller = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final zipController = TextEditingController();
    String selectedLabel = 'منزل';
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة عنوان جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedLabel,
                  decoration: const InputDecoration(
                    labelText: 'نوع العنوان',
                    border: OutlineInputBorder(),
                  ),
                  items: ['منزل', 'عمل', 'أخرى'].map((label) {
                    return DropdownMenuItem(value: label, child: Text(label));
                  }).toList(),
                  onChanged: (value) => setState(() => selectedLabel = value!),
                ),
                const SizedBox(height: AppConstants.s),
                TextField(
                  controller: address1Controller,
                  decoration: const InputDecoration(
                    labelText: 'العنوان الأول',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppConstants.s),
                TextField(
                  controller: address2Controller,
                  decoration: const InputDecoration(
                    labelText: 'العنوان الثاني (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppConstants.s),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'المدينة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppConstants.s),
                TextField(
                  controller: stateController,
                  decoration: const InputDecoration(
                    labelText: 'المحافظة (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppConstants.s),
                TextField(
                  controller: zipController,
                  decoration: const InputDecoration(
                    labelText: 'الرمز البريدي (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppConstants.s),
                CheckboxListTile(
                  title: const Text('جعل هذا العنوان افتراضي'),
                  value: isDefault,
                  onChanged: (value) => setState(() => isDefault = value!),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (address1Controller.text.isNotEmpty && cityController.text.isNotEmpty) {
                  final userId = context.read<AuthService>().currentUser?.id;
                  if (userId != null) {
                    final address = UserAddress(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      userId: userId,
                      addressLine1: address1Controller.text,
                      addressLine2: address2Controller.text.isNotEmpty ? address2Controller.text : null,
                      city: cityController.text,
                      state: stateController.text.isNotEmpty ? stateController.text : null,
                      zipCode: zipController.text.isNotEmpty ? zipController.text : null,
                      label: selectedLabel,
                      isDefault: isDefault,
                    );
                    locationService.saveAddress(address);
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(UserAddress address, LocationService locationService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العنوان'),
        content: Text('هل أنت متأكد من حذف عنوان "${address.label}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              locationService.deleteAddress(address.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}