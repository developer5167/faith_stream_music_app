import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_state.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_state.dart';
import '../../blocs/player/player_event.dart';
import '../../services/ads_service.dart';
import '../../services/audio_player_service.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/app_open_ad_dialog.dart';
import 'ad_player_screen.dart';
import '../../config/app_theme.dart';
import '../../utils/version_helper.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../widgets/update_dialog.dart';

class MainNavigationScreen extends StatefulWidget {
  final Widget child;
  const MainNavigationScreen({super.key, required this.child});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // Cached value — only updated on definitive ProfileLoaded state.
  // Stays stable during ProfileLoading so the tab bar doesn't flicker.
  bool _showSubscriptionTab = true;

  StreamSubscription? _indexSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isShowingAd = false;
  bool _hasCheckedVersion = false;

  @override
  void initState() {
    super.initState();
    // Show the interstitial app-open ad once per session after the UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowAppOpenAd();
      _checkVersionUpdate();
    });
    // Global connectivity monitor – if internet drops, go to offline screen
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    if (!mounted) return;
    
    // Cross-check with a fresh check to be sure.
    final initialCheck = await Connectivity().checkConnectivity();
    final isPossiblyOffline = initialCheck.isEmpty || initialCheck.every((r) => r == ConnectivityResult.none);
    
    if (isPossiblyOffline && mounted) {
      // Wait 300ms and check again to avoid transient drops during navigation/radio handoff
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      
      final finalCheck = await Connectivity().checkConnectivity();
      final isStillOffline = finalCheck.isEmpty || finalCheck.every((r) => r == ConnectivityResult.none);
      
      if (isStillOffline) {
        // Only navigate if we are currently on a screen that REQUIRES internet
        final state = GoRouterState.of(context);
        final loc = state.matchedLocation;
        if (loc == '/home' || loc == '/search' || loc == '/premium' || loc == '/profile') {
          debugPrint('[MainNavigationScreen] Verified internet loss. Redirecting to offline downloads.');
          context.go('/offline-downloads');
        }
      }
    }
  }

  Future<void> _maybeShowAppOpenAd() async {
    if (!mounted) return;
    final profileState = context.read<ProfileBloc>().state;
    final bool isPremium =
        profileState is ProfileLoaded &&
        profileState.subscription != null &&
        profileState.subscription!.isActive;
    if (isPremium) return; // premium users never see ads
    await AppOpenAdDialog.showIfAvailable(context);
  }

  Future<void> _checkVersionUpdate() async {
    if (_hasCheckedVersion || !mounted) return;
    
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.bootstrapData?.appConfig != null) {
      _hasCheckedVersion = true;
      // Short delay to ensure home screen is 'peacefully settled'
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      
      try {
        final update = await VersionHelper(
          authState.bootstrapData!.appConfig!,
        ).getAvailableUpdate();
        
        if (update != null && mounted) {
          debugPrint('📡 [VersionCheck] Update found: ${update.versionName}');
          UpdateDialog.show(context, update);
        }
      } catch (e) {
        debugPrint('❌ [VersionCheck] Error: $e');
      }
    }
  }

  Future<void> _checkAndPlayVideoAd() async {
    if (_isShowingAd) return;

    final profileState = context.read<ProfileBloc>().state;
    // CRITICAL: Robust check for premium status
    final bool isPremium =
        profileState is ProfileLoaded &&
        profileState.subscription != null &&
        profileState.subscription!.isActive;

    if (isPremium) return;

    final adService = context.read<AdsService>();
    if (await adService.shouldPlayVideoAd()) {
      final ad = await adService.getNextAd('POWER_VIDEO');
      if (ad != null && mounted) {
        _isShowingAd = true;

        // Pause audio DIRECTLY via AudioPlayerService — this is synchronous
        // and guaranteed to stop audio before the video ad starts.
        // Using PlayerBloc.add(PlayerPause()) is async and arrives too late.
        await context.read<AudioPlayerService>().pause();

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AdPlayerScreen(ad: ad),
            fullscreenDialog: true,
          ),
        );

        _isShowingAd = false;
        await adService.markVideoAdPlayed();

        // Resume only if the player has a song loaded (Playing or Paused state)
        if (mounted) {
          final playerState = context.read<PlayerBloc>().state;
          if (playerState is PlayerPlaying || playerState is PlayerPaused) {
            context.read<PlayerBloc>().add(const PlayerPlay());
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _indexSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (_, state) =>
          state is ProfileLoaded || state is ProfileOperationSuccess,
      listener: (context, state) {
        final profileState = state is ProfileOperationSuccess
            ? state.previousState
            : state as ProfileLoaded;

        final hasActiveSub = profileState.subscription?.isActive ?? false;
        final shouldHide = hasActiveSub;

        if (shouldHide != !_showSubscriptionTab) {
          final newShow = !shouldHide;
          if (newShow != _showSubscriptionTab) {
            setState(() {
              _showSubscriptionTab = newShow;
            });
          }
        }
      },
      builder: (context, state) {
        // Map paths to tab indices
        final String location = GoRouterState.of(context).matchedLocation;
        int currentIndex = 0;
        if (location.startsWith('/search')) currentIndex = 1;
        else if (location.startsWith('/library')) currentIndex = 2;
        else if (_showSubscriptionTab && location.startsWith('/premium')) currentIndex = 3;
        else if (location.startsWith('/profile')) currentIndex = _showSubscriptionTab ? 4 : 3;
        else if (location.startsWith('/song') || location.startsWith('/album') || location.startsWith('/artist')) {
           // Detail screens preserve the "current" tab they were opened from, 
           // but for deep links, we might just stay on Home (0).
        }

        return MultiBlocListener(
          listeners: [
            BlocListener<PlayerBloc, PlayerState>(
              listenWhen: (previous, current) =>
                  (previous is! PlayerLoading) && (current is PlayerLoading),
              listener: (context, state) {
                _checkAndPlayVideoAd();
              },
            ),
            BlocListener<PlayerBloc, PlayerState>(
              listenWhen: (previous, current) => current is PlayerError,
              listener: (context, state) {
                if (state is PlayerError) {
                  if (state.message == 'DAILY_LIMIT_REACHED') {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        title: const Text('Daily Limit Reached'),
                        content: const Text(
                          'You have reached your daily free play limit (2 plays) for this song.\n\nUpgrade to Premium for unlimited ad-free plays!',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'CANCEL',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandMagenta,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              if (_showSubscriptionTab) {
                                context.go('/premium');
                              }
                            },
                            child: const Text('GO PREMIUM'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message)));
                  }
                }
              },
            ),
            BlocListener<AuthBloc, AuthState>(
              listenWhen: (previous, current) =>
                  !_hasCheckedVersion && current is AuthAuthenticated,
              listener: (context, state) async {
                _checkVersionUpdate();
              },
            ),
          ],
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: widget.child,
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MiniPlayerBar(),
                BottomNavigationBar(
                  currentIndex: currentIndex,
                  onTap: (index) {
                    switch (index) {
                      case 0: context.go('/home'); break;
                      case 1: context.go('/search'); break;
                      case 2: context.go('/library'); break;
                      case 3: 
                        if (_showSubscriptionTab) context.go('/premium');
                        else context.go('/profile'); 
                        break;
                      case 4: context.go('/profile'); break;
                    }
                  },
                  type: BottomNavigationBarType.fixed,
                  items: [
                    const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                    const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
                    const BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
                    if (_showSubscriptionTab)
                      const BottomNavigationBarItem(icon: Icon(Icons.workspace_premium), label: 'Premium'),
                    const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
