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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        // Determine if we should show subscription tab
        bool showSubscriptionTab = true;
        if (state is ProfileLoaded || state is ProfileOperationSuccess) {
          final profileState = state is ProfileOperationSuccess
              ? state.previousState
              : state as ProfileLoaded;

          // Hide subscription tab if user has active subscription
          if (profileState.subscription != null &&
              profileState.subscription!.isActive) {
            showSubscriptionTab = false;
          }
        }

        final screens = [
          const HomeScreen(),
          const SearchScreen(),
          const LibraryScreen(),
          if (showSubscriptionTab) const SubscriptionScreen(),
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
          if (showSubscriptionTab)
            const BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium),
              label: 'Premium',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];

        // Adjust current index if subscription tab is hidden
        int adjustedIndex = _currentIndex;
        if (!showSubscriptionTab && _currentIndex >= 3) {
          adjustedIndex = _currentIndex;
        }

        return Scaffold(
          body: screens[adjustedIndex],
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayerBar(),
              BottomNavigationBar(
                currentIndex: adjustedIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
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
