import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_delivery_app/services/auth_service.dart';
import 'package:food_delivery_app/theme.dart';
import 'package:food_delivery_app/screens/auth/signup_screen.dart';
import 'package:food_delivery_app/screens/auth/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  /// Signs the user in using email and password.
  Future<void> _signIn() async {
    // First, validate the form.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the AuthService to sign in.
      await Provider.of<AuthService>(context, listen: false).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // After a successful login, the listener in main.dart will
      // automatically handle navigation, so we don't need to navigate here.

    } catch (e) {
      // If there's an error, show it in a snackbar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('فشل تسجيل الدخول. يرجى التحقق من البيانات.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      // Ensure the loading indicator is turned off, even if there's an error.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Always dispose of controllers to free up resources.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The headlineSmall style might not be in your theme.
    // Replace it with titleLarge if you get a compilation error.
    final headlineStyle = Theme.of(context).textTheme.headlineSmall ?? Theme.of(context).textTheme.titleLarge;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول للمالكين'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Text
                Text(
                  'مرحباً بعودتك!',
                  style: headlineStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.s),
                Text(
                  'أدخل بياناتك لإدارة مطعمك',
                  style: AppTheme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.xl * 2),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'الرجاء إدخال بريد إلكتروني صالح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.m),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'كلمة المرور'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الحقل مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.xl),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppConstants.m),
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.textOnPrimary,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('تسجيل الدخول'),
                ),
                const SizedBox(height: AppConstants.m),

                // Forgot Password Link
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                    );
                  },
                  child: const Text('نسيت كلمة المرور؟'),
                ),
                const SizedBox(height: AppConstants.m),

                // Signup Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('ليس لديك حساب؟ '),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const SignupScreen()),
                        );
                      },
                      child: const Text('إنشاء حساب جديد'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}