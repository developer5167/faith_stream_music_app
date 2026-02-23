import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/constants.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_state.dart';
import '../widgets/mini_player_bar.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'user_profile_screen.dart';
import 'subscription_screen.dart';

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

        return Scaffold(
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
        );
      },
    );
  }
}
