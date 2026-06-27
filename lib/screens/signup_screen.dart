import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../services/auth_service.dart';
import 'main_navigation_wrapper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final messenger = ScaffoldMessenger.of(context);

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    if (password.length < 6) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    if (password != confirm) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await AuthService.instance.signUpWithEmail(
        name: name,
        email: email,
        password: password,
      );
      if (!mounted) return;
      // Navigate directly to the main screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainNavigationWrapper(
            userId: credential.user!.uid,
          ),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      final message = switch (error.code) {
        'operation-not-allowed' =>
          'Email/password sign-up is disabled in Firebase Console.',
        'weak-password' => 'Password is too weak.',
        'email-already-in-use' => 'That email is already registered.',
        'invalid-email' => 'Please enter a valid email address.',
        _ => error.message ?? error.toString(),
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.pLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Image.asset(
                  'assets/images/ainterview-logo-blue.png',
                  height: 60,
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Text('Sign up', style: AppTextStyles.h1)),
              const SizedBox(height: 28),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Full Name',
                  filled: true,
                  fillColor: AppColors.light,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSizes.pMedium,
                    vertical: AppSizes.pLarge / 1.5,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    borderSide: const BorderSide(color: AppColors.main),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Ex: Nicholas Abel', style: AppTextStyles.caption),
              const SizedBox(height: 12),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: AppColors.light,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSizes.pMedium,
                    vertical: AppSizes.pLarge / 1.5,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    borderSide: const BorderSide(color: AppColors.main),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Ex: nicholasabel@gmail.com', style: AppTextStyles.caption),
              const SizedBox(height: 12),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: AppColors.light,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSizes.pMedium,
                    vertical: AppSizes.pLarge / 1.5,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    borderSide: const BorderSide(color: AppColors.main),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('*minimum 6 digit', style: AppTextStyles.caption),
              const SizedBox(height: 12),

              TextField(
                controller: _confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Confirm password',
                  filled: true,
                  fillColor: AppColors.light,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSizes.pMedium,
                    vertical: AppSizes.pLarge / 1.5,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    borderSide: const BorderSide(color: AppColors.main),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('*enter password', style: AppTextStyles.caption),
              const SizedBox(height: 18),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.main,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text('Sign up', style: AppTextStyles.button),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: AppTextStyles.caption,
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Log in'),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
