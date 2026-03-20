import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../repositories/auth_repository.dart';
import '../../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/app_logo.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String resetToken;

  const ResetPasswordScreen({super.key, required this.resetToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final password = _passwordController.text;
    final authRepo = context.read<AuthRepository>();

    final response = await authRepo.resetPassword(widget.resetToken, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully. You can now log in.'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => context.pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: size.height * 0.05),
                // const AppLogo(fontSize: 48).animate().fadeIn(duration: 400.ms).scale(),
                // const SizedBox(height: AppSizes.paddingMd),
                Text(
                  'New Password',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: AppSizes.paddingSm),
                Text(
                  'Create a new strong password for your account.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: AppSizes.paddingXl),
                CustomTextField(
                  controller: _passwordController,
                  label: 'New Password',
                  hint: 'Enter new password',
                  obscureText: true,
                  validator: _validatePassword,
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: theme.colorScheme.primary,
                  ),
                  enabled: !_isLoading,
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),
                const SizedBox(height: AppSizes.paddingMd),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  obscureText: true,
                  validator: _validateConfirmPassword,
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: theme.colorScheme.primary,
                  ),
                  enabled: !_isLoading,
                ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),
                const SizedBox(height: AppSizes.paddingXl),
                CustomButton(
                      text: 'Save Password',
                      onPressed: _resetPassword,
                      isLoading: _isLoading,
                    )
                    .animate()
                    .fadeIn(delay: 600.ms)
                    .scale(begin: const Offset(0.95, 0.95)),
                const SizedBox(height: AppSizes.paddingXl),
                const AppLogo(
                  fontSize: 24,
                  showTagline: true,
                ).animate().fadeIn(delay: 700.ms),
                const SizedBox(height: AppSizes.paddingMd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
