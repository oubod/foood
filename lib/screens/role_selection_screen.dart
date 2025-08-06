// lib/screens/role_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:food_delivery_app/screens/auth/login_screen.dart';
import 'package:food_delivery_app/screens/client/client_auth_screen.dart';
import 'package:food_delivery_app/theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('مرحباً في تطبيقنا', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppConstants.s),
              Text('اختر دورك للبدء', style: AppTheme.textTheme.bodyLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppConstants.xl * 2),
              
              // Customer Button
              _buildRoleButton(
                context: context,
                icon: Icons.fastfood_outlined,
                label: 'أنا زبون',
                subtitle: 'تصفح المطاعم واطلب الطعام',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ClientAuthScreen()));
                }
              ),
              const SizedBox(height: AppConstants.l),

              // Owner Button
              _buildRoleButton(
                context: context,
                icon: Icons.storefront_outlined,
                label: 'أنا صاحب مطعم',
                subtitle: 'إدارة قائمتك واستقبال الطلبات',
                onTap: () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LoginScreen()));
                }
              ),
               const SizedBox(height: AppConstants.l),

              // Admin Button
              _buildRoleButton(
                context: context,
                icon: Icons.admin_panel_settings_outlined,
                label: 'أنا مسؤول',
                subtitle: 'الإشراف على النظام بالكامل',
                 onTap: () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LoginScreen()));
                }
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.l),
          child: Row(
            children: [
              Icon(icon, size: 40, color: AppTheme.primary),
              const SizedBox(width: AppConstants.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTheme.textTheme.titleLarge),
                    Text(subtitle, style: AppTheme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: AppTheme.iconDefault),
            ],
          ),
        ),
      ),
    );
  }
}