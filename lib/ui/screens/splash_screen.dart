import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;
  DateTime? _splashStartTime;

  @override
  void initState() {
    super.initState();
    _splashStartTime = DateTime.now();
    debugPrint('=== Splash Screen initState ===');

    // Check auth status with error handling
    try {
      context.read<AuthBloc>().add(const AuthCheckRequested());
      debugPrint('Auth check requested successfully');
    } catch (e) {
      debugPrint('Error in splash screen initState: $e');
      // Navigate to login on error
      _navigateToLogin();
    }

    // Fallback: Navigate to login after 3 seconds if nothing happens
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_hasNavigated) {
        debugPrint('Timeout reached - navigating to login as fallback');
        _navigateToLogin();
      }
    });
  }

  Future<void> _ensureMinimumSplashDuration() async {
    if (_splashStartTime != null) {
      final elapsed = DateTime.now().difference(_splashStartTime!);
      const minDuration = Duration(milliseconds: 500);

      if (elapsed < minDuration) {
        final remaining = minDuration - elapsed;
        debugPrint(
          '⏱️ Waiting ${remaining.inMilliseconds}ms to meet minimum splash duration',
        );
        await Future.delayed(remaining);
      }
    }
  }

  void _navigateToLogin() async {
    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      await _ensureMinimumSplashDuration();
      if (mounted) {
        // Check if onboarding is completed
        final storageService = context.read<StorageService>();
        final onboardingCompleted = storageService.isOnboardingCompleted();

        if (onboardingCompleted) {
          context.go('/login');
        } else {
          context.go('/onboarding');
        }
      }
    }
  }

  void _navigateToHome() async {
    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      await _ensureMinimumSplashDuration();
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    debugPrint('=== Splash Screen build called ===');

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        debugPrint('Splash Screen - Auth State Changed: ${state.runtimeType}');
        if (state is AuthAuthenticated) {
          debugPrint('Navigating to /home');
          _navigateToHome();
        } else if (state is AuthUnauthenticated) {
          debugPrint('Navigating to /login');
          _navigateToLogin();
        } else if (state is AuthError) {
          debugPrint('Auth Error: ${state.message}');
          _navigateToLogin();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF8B4513), // Fallback color
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: theme.brightness == Brightness.light
                  ? [AppColors.primaryBrown, AppColors.primaryGold]
                  : [AppColors.primaryGold, AppColors.primaryBrown],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon
                  const Icon(Icons.music_note, size: 120, color: Colors.white),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.appName,
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Worship Through Music',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 64),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
