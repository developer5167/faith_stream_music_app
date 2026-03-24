import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../repositories/auth_repository.dart';
import '../../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/app_logo.dart';

class VerifyResetOtpScreen extends StatefulWidget {
  final String email;

  const VerifyResetOtpScreen({super.key, required this.email});

  @override
  State<VerifyResetOtpScreen> createState() => _VerifyResetOtpScreenState();
}

class _VerifyResetOtpScreenState extends State<VerifyResetOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final otp = _otpController.text.trim();
    final authRepo = context.read<AuthRepository>();

    final response = await authRepo.verifyPasswordResetOtp(widget.email, otp);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success && response.data != null) {
      final resetToken = response.data!;
      // Pass the resetToken to the next screen to set the new password
      context.push('/forgot-password/reset', extra: resetToken);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String? _validateOtp(String? value) {
    if (value == null || value.trim().length != 6)
      return 'Enter a valid 6-digit code';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: const AppLogo(
          fontSize: 24,
          showTagline: true,
        ).animate().fadeIn(delay: 600.ms),
      ),
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
                Text(
                  'Check Your Email',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: AppSizes.paddingSm),
                Text(
                  'We sent a 6-digit code to\n${widget.email}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: AppSizes.paddingXl),
                CustomTextField(
                  controller: _otpController,
                  label: '6-Digit Code',
                  hint: 'Enter 6-digit code',
                  keyboardType: TextInputType.number,
                  validator: _validateOtp,
                  maxLength: 6,
                  prefixIcon: Icon(
                    Icons.pin_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  enabled: !_isLoading,
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),
                const SizedBox(height: AppSizes.paddingXl),
                CustomButton(
                      text: 'Verify Code',
                      onPressed: _verifyOtp,
                      isLoading: _isLoading,
                    )
                    .animate()
                    .fadeIn(delay: 500.ms)
                    .scale(begin: const Offset(0.95, 0.95)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
