import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../services/storage_service.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/screens/onboarding_screen.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/register_screen.dart';
import '../ui/screens/main_navigation_screen.dart';
import '../ui/screens/support/support_hub_screen.dart';
import '../ui/screens/support/file_complaint_screen.dart';
import '../ui/screens/support/my_complaints_screen.dart';
import '../ui/screens/support/contact_support_screen.dart';
import '../ui/screens/support/my_tickets_screen.dart';
import '../ui/screens/support/help_center_screen.dart';

class AppRouter {
  final AuthBloc authBloc;
  final StorageService storageService;

  AppRouter(this.authBloc, this.storageService);

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnOnboarding = state.matchedLocation == '/onboarding';
      final isOnAuth =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // If loading, stay where we are
      if (authState is AuthLoading && isOnSplash) {
        return null;
      }

      // If authenticated, redirect to home unless already there
      if (authState is AuthAuthenticated) {
        if (isOnAuth || isOnSplash || isOnOnboarding) {
          return '/home';
        }
        return null;
      }

      // If unauthenticated, allow onboarding, splash, and auth pages
      if (authState is AuthUnauthenticated) {
        if (!isOnAuth && !isOnOnboarding && !isOnSplash) {
          return '/login';
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) =>
            OnboardingScreen(storageService: storageService),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      // Support & Complaints Routes
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportHubScreen(),
      ),
      GoRoute(
        path: '/support/file-complaint',
        builder: (context, state) => const FileComplaintScreen(),
      ),
      GoRoute(
        path: '/support/my-complaints',
        builder: (context, state) => const MyComplaintsScreen(),
      ),
      GoRoute(
        path: '/support/contact',
        builder: (context, state) => const ContactSupportScreen(),
      ),
      GoRoute(
        path: '/support/my-tickets',
        builder: (context, state) => const MyTicketsScreen(),
      ),
      GoRoute(
        path: '/support/help-center',
        builder: (context, state) => const HelpCenterScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.matchedLocation}')),
    ),
  );
}

// Helper class to refresh router when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
