import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../repositories/auth_repository.dart';
import '../../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/app_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  String _verifiedEmailToken = '';

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage++);
  }

  void _prevPage() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage--);
  }

  Future<void> _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _isSendingOtp = true);

    final response = await context.read<AuthRepository>().sendRegistrationOtp(
      _emailController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSendingOtp = false);

    if (response.success) {
      _nextPage();
    } else {
      _showError(response.message);
    }
  }

  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    setState(() => _isVerifyingOtp = true);

    final response = await context.read<AuthRepository>().verifyRegistrationOtp(
      _emailController.text.trim(),
      _otpController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isVerifyingOtp = false);

    if (response.success && response.data != null) {
      _verifiedEmailToken = response.data!;
      _nextPage();
    } else {
      _showError(response.message);
    }
  }

  void _register() {
    if (_passwordFormKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          verifiedEmailToken: _verifiedEmailToken,
        ),
      );
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthError) {
          _showError(state.message);
        }
      },
      builder: (context, state) {
        final isAuthLoading = state is AuthLoading;

        return Scaffold(
          bottomNavigationBar: SafeArea(
            child: const AppLogo(
              fontSize: 20,
              showTagline: true,
            ).animate().fadeIn(delay: 500.ms),
          ),
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: (isAuthLoading || _isSendingOtp || _isVerifyingOtp)
                  ? null
                  : () {
                      if (_currentPage > 0) {
                        _prevPage();
                      } else {
                        context.go('/login');
                      }
                    },
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: SafeArea(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe
              children: [
                _buildEmailStep(theme),
                _buildOtpStep(theme),
                _buildPasswordStep(theme, isAuthLoading),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- STEP 1: Email & Name ---
  Widget _buildEmailStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // const AppLogo(fontSize: 40).animate().fadeIn(duration: 400.ms).scale(),
            // const SizedBox(height: AppSizes.paddingMd),
            Text(
              'Create Account',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingSm),
            Text(
              'Join us to start worshipping',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingXl),
            CustomTextField(
              controller: _nameController,
              label: AppStrings.name,
              hint: 'Enter your name',
              validator: _validateName,
              prefixIcon: Icon(
                Icons.person_outline,
                color: theme.colorScheme.primary,
              ),
              enabled: !_isSendingOtp,
            ),
            const SizedBox(height: AppSizes.paddingMd),
            CustomTextField(
              controller: _emailController,
              label: AppStrings.email,
              hint: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
              prefixIcon: Icon(
                Icons.email_outlined,
                color: theme.colorScheme.primary,
              ),
              enabled: !_isSendingOtp,
            ),
            const SizedBox(height: AppSizes.paddingXl),
            CustomButton(
              text: 'Continue',
              onPressed: _sendOtp,
              isLoading: _isSendingOtp,
            ),
            const SizedBox(height: AppSizes.paddingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: theme.textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: _isSendingOtp ? null : () => context.go('/login'),
                  child: Text(
                    AppStrings.login,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- STEP 2: OTP Verification ---
  Widget _buildOtpStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      child: Form(
        key: _otpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const AppLogo(
              fontSize: 40,
            ).animate().fadeIn(duration: 400.ms).scale(),
            const SizedBox(height: AppSizes.paddingMd),
            Text(
              'Verify Email',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingSm),
            Text(
              'We sent a 6-digit code to\n${_emailController.text}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingXl),
            CustomTextField(
              controller: _otpController,
              label: '6-Digit Code',
              hint: 'Enter verification code',
              keyboardType: TextInputType.number,
              maxLength: 6,
              validator: (v) => v == null || v.trim().length != 6
                  ? 'Enter a 6-digit code'
                  : null,
              prefixIcon: Icon(
                Icons.pin_outlined,
                color: theme.colorScheme.primary,
              ),
              enabled: !_isVerifyingOtp,
            ),
            const SizedBox(height: AppSizes.paddingXl),
            CustomButton(
              text: 'Verify Code',
              onPressed: _verifyOtp,
              isLoading: _isVerifyingOtp,
            ),
            const SizedBox(height: AppSizes.paddingXl),
            const AppLogo(
              fontSize: 20,
              showTagline: true,
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: AppSizes.paddingMd),
          ],
        ),
      ),
    );
  }

  // --- STEP 3: Password ---
  Widget _buildPasswordStep(ThemeData theme, bool isAuthLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const AppLogo(
              fontSize: 40,
            ).animate().fadeIn(duration: 400.ms).scale(),
            const SizedBox(height: AppSizes.paddingMd),
            Text(
              'Create Password',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingSm),
            Text(
              'Secure your account with a strong password.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingXl),
            CustomTextField(
              controller: _passwordController,
              label: AppStrings.password,
              hint: 'Enter your password',
              obscureText: true,
              validator: _validatePassword,
              prefixIcon: Icon(
                Icons.lock_outline,
                color: theme.colorScheme.primary,
              ),
              enabled: !isAuthLoading,
            ),
            const SizedBox(height: AppSizes.paddingMd),
            CustomTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              obscureText: true,
              validator: (v) {
                if (v == null || v.isEmpty)
                  return 'Please confirm your password';
                if (v != _passwordController.text)
                  return 'Passwords do not match';
                return null;
              },
              prefixIcon: Icon(
                Icons.lock_outline,
                color: theme.colorScheme.primary,
              ),
              enabled: !isAuthLoading,
            ),
            const SizedBox(height: AppSizes.paddingXl),
            CustomButton(
              text: 'Complete Registration',
              onPressed: _register,
              isLoading: isAuthLoading,
            ),
            const SizedBox(height: AppSizes.paddingXl),
            const AppLogo(
              fontSize: 20,
              showTagline: true,
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: AppSizes.paddingMd),
          ],
        ),
      ),
    );
  }
}
