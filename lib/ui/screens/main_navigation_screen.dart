import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/constants.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_state.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_state.dart';
import '../../blocs/player/player_event.dart';
import '../../services/ads_service.dart';
import '../widgets/mini_player_bar.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'user_profile_screen.dart';
import 'subscription_screen.dart';
import 'ad_player_screen.dart';
import '../../config/app_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  // Cached value — only updated on definitive ProfileLoaded state.
  // Stays stable during ProfileLoading so the tab bar doesn't flicker.
  bool _showSubscriptionTab = true;

  StreamSubscription? _indexSubscription;
  bool _isShowingAd = false;

  @override
  void initState() {
    super.initState();
    // Ad trigger moved to BlocListener in build method for better state synchronization
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

        // Pause audio before showing ad
        context.read<PlayerBloc>().add(const PlayerPause());

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AdPlayerScreen(ad: ad),
            fullscreenDialog: true,
          ),
        );

        _isShowingAd = false;
        await adService.markVideoAdPlayed();

        // Resume playback after ad finishes
        if (mounted) {
          context.read<PlayerBloc>().add(const PlayerPlay());
        }
      }
    }
  }

  @override
  void dispose() {
    _indexSubscription?.cancel();
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
              // Clamp index if the tab at current position disappears
              final maxIndex = newShow ? 4 : 3;
              if (_currentIndex > maxIndex) _currentIndex = maxIndex;
            });
          }
        }
      },
      builder: (context, state) {
        final screens = [
          const HomeScreen(),
          const SearchScreen(),
          const LibraryScreen(),
          if (_showSubscriptionTab) const SubscriptionScreen(),
          const UserProfileScreen(),
        ];

        final navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Library',
          ),
          if (_showSubscriptionTab)
            const BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium),
              label: 'Premium',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];

        // Safety clamp in case state is read before listener fires
        final safeIndex = _currentIndex.clamp(0, screens.length - 1);

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
                              backgroundColor: AppTheme.darkPrimary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              if (_showSubscriptionTab) {
                                setState(() {
                                  _currentIndex = 3; // Navigate to Premium tab
                                });
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
          ],
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: screens[safeIndex],
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MiniPlayerBar(),
                BottomNavigationBar(
                  currentIndex: safeIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: AppColors.primaryBrown,
                  unselectedItemColor: Colors.grey,
                  type: BottomNavigationBarType.fixed,
                  items: navItems,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
