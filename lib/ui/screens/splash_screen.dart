import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/home/home_bloc.dart';
import '../../blocs/home/home_event.dart';
import '../../models/home_feed.dart';
import '../../services/storage_service.dart';
import '../../config/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _hasNavigated = false;
  bool _isExpanded = false;
  DateTime? _splashStartTime;

  @override
  void initState() {
    super.initState();
    _splashStartTime = DateTime.now();

    // Start expansion almost immediately
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _isExpanded = true);
    });

    // Check auth status
    try {
      context.read<AuthBloc>().add(const AuthCheckRequested());
    } catch (e) {
      _navigateToLogin();
    }

    // Fallback navigation
    Future.delayed(const Duration(seconds: 7), () {
      if (mounted && !_hasNavigated) _navigateToLogin();
    });
  }

  Future<void> _ensureMinimumSplashDuration() async {
    if (_splashStartTime != null) {
      final elapsed = DateTime.now().difference(_splashStartTime!);
      const minDuration = Duration(milliseconds: 4500);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
    }
  }

  void _navigateToLogin() async {
    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      await _ensureMinimumSplashDuration();
      if (mounted) {
        final storageService = context.read<StorageService>();
        if (storageService.isOnboardingCompleted()) {
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
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.displayLarge?.copyWith(
      fontSize: 50,
      fontWeight: FontWeight.w900,
      letterSpacing: -1,
      height: 1.0,
    );

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (state.bootstrapData != null) {
            final bootstrap = state.bootstrapData!;
            final homeFeed = HomeFeed(
              recentlyPlayed: bootstrap.recentlyPlayed,
              topPlayedSongs: bootstrap.topPlayed,
              trendingSongs: bootstrap.newReleases,
              albums: bootstrap.newAlbums,
              followedArtists: const [],
              topArtists: const [],
              topPlayedArtists: const [],
            );
            context.read<HomeBloc>().add(HomeBootstrapLoaded(homeFeed));
          }
          _navigateToHome();
        } else if (state is AuthUnauthenticated || state is AuthError) {
          _navigateToLogin();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.premiumDarkGradient,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 'F' Anchor
                            Text(
                                  'F',
                                  style: textStyle?.copyWith(
                                    color: Colors.white,
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .scale(
                                  begin: const Offset(0.5, 0.5),
                                  curve: Curves.easeOutBack,
                                  duration: 400.ms,
                                ),

                            // 'aith' Expansion
                            AnimatedSize(
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutQuart,
                              child: _isExpanded
                                  ? ClipRect(
                                      child:
                                          Text(
                                            'aith',
                                            style: textStyle?.copyWith(
                                              color: Colors.white,
                                            ),
                                          ).animate().fadeIn(
                                            duration: 500.ms,
                                            delay: 200.ms,
                                          ),
                                    )
                                  : const SizedBox(width: 0),
                            ),

                            // 'S' Anchor
                            ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          Color(0xFF8B5CF6), // Royal Purple
                                          Color(0xFFD946EF), // Electric Magenta
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                  child: Text(
                                    'S',
                                    style: textStyle?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 100.ms)
                                .scale(
                                  begin: const Offset(0.5, 0.5),
                                  curve: Curves.easeOutBack,
                                  duration: 400.ms,
                                  delay: 100.ms,
                                ),

                            // 'tream' Expansion
                            AnimatedSize(
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutQuart,
                              child: _isExpanded
                                  ? ClipRect(
                                      child:
                                          ShaderMask(
                                            shaderCallback: (bounds) =>
                                                const LinearGradient(
                                                  colors: [
                                                    Color(
                                                      0xFF8B5CF6,
                                                    ), // Royal Purple
                                                    Color(
                                                      0xFFD946EF,
                                                    ), // Electric Magenta
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ).createShader(bounds),
                                            child: Text(
                                              'tream',
                                              style: textStyle?.copyWith(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ).animate().fadeIn(
                                            duration: 500.ms,
                                            delay: 400.ms,
                                          ),
                                    )
                                  : const SizedBox(width: 0),
                            ),
                          ],
                        )
                        .animate(delay: 1800.ms)
                        .shimmer(
                          duration: 1500.ms,
                          color: Colors.white.withOpacity(0.9),
                          size: 1.5,
                        ),
                    Text(
                      'by SOTER SYSTEMS',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),

              // Subtle Subtitle / Tagline reveal after expansion
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 1000),
                    opacity: _isExpanded ? 0.6 : 0.0,
                    child: Column(
                      children: [
                        Text(
                          'Grace in Every Stream',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w300,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeOut(delay: 3800.ms, duration: 600.ms),
      ),
    );
  }
}
