import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../services/storage_service.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/screens/onboarding_screen.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/register_screen.dart';
import '../ui/screens/auth/forgot_password_screen.dart';
import '../ui/screens/auth/verify_reset_otp_screen.dart';
import '../ui/screens/auth/reset_password_screen.dart';
import '../ui/screens/main_navigation_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/search_screen.dart';
import '../ui/screens/library_screen.dart';
import '../ui/screens/user_profile_screen.dart';
import '../ui/screens/support/support_hub_screen.dart';
import '../ui/screens/support/file_complaint_screen.dart';
import '../ui/screens/support/my_complaints_screen.dart';

import '../ui/screens/support/contact_support_screen.dart';
import '../ui/screens/support/my_tickets_screen.dart';
import '../ui/screens/support/help_center_screen.dart';
import '../ui/screens/song_detail_screen.dart';
import '../ui/screens/subscription_screen.dart';
import '../ui/screens/album_detail_screen.dart';
import '../ui/screens/artist_profile_screen.dart';
import '../ui/screens/offline_downloads_screen.dart';
import '../ui/screens/notifications_screen.dart';
import '../ui/screens/suggest_song_screen.dart';
import '../ui/screens/all_songs_screen.dart';
import '../ui/screens/all_albums_screen.dart';
import '../ui/screens/all_artists_screen.dart';
import '../ui/screens/favorites_screen.dart';
import '../ui/screens/favorite_albums_screen.dart';
import '../ui/screens/favorite_artists_screen.dart';
import '../ui/screens/playlists_screen.dart';
import '../ui/screens/playlist_detail_screen.dart';
import '../ui/screens/earnings_screen.dart';
import '../ui/screens/artist_dashboard_screen.dart';
import '../ui/screens/create_playlist_screen.dart';
import '../ui/screens/edit_profile_screen.dart';
import '../ui/screens/artist_registration_screen.dart';
import '../ui/screens/create_album_screen.dart';
import '../ui/screens/upload_song_screen.dart';
import '../ui/screens/manage_songs_screen.dart';
import '../ui/screens/bank_details_screen.dart';
import '../blocs/payout/payout_bloc.dart';
import '../models/playlist.dart';
import '../models/user.dart';
import '../models/payout.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';

class AppRouter {
  final AuthBloc authBloc;
  final StorageService storageService;
  final String initialRoute;

  AppRouter(
    this.authBloc,
    this.storageService, {
    this.initialRoute = '/splash',
  });

  late final GoRouter router = GoRouter(
    initialLocation: initialRoute,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final loc = state.matchedLocation;
      final isOnSplash = loc == '/splash';
      final isOnOnboarding = loc == '/onboarding';
      final isOnAuth = loc.startsWith('/login') || 
                       loc.startsWith('/register') || 
                       loc.startsWith('/forgot-password');
      final isOnOffline = loc == '/offline-downloads';

      // Never redirect away from the offline downloads screen on launch
      if (isOnOffline) return null;

      // If loading, stay on splash
      if (authState is AuthLoading && isOnSplash) {
        return null;
      }

      // If authenticated, redirect to home unless already there
      if (authState is AuthAuthenticated) {
        if (isOnAuth || isOnOnboarding) {
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
        path: '/',
        redirect: (context, state) => '/home',
      ),
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
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/forgot-password/verify',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return VerifyResetOtpScreen(email: email);
        },
      ),
      GoRoute(
        path: '/forgot-password/reset',
        builder: (context, state) {
          final resetToken = state.extra as String? ?? '';
          return ResetPasswordScreen(resetToken: resetToken);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => MainNavigationScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const HomeScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const SearchScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const LibraryScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/premium',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const SubscriptionScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const UserProfileScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/song/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              final song = state.extra as Song?;
              return SongDetailScreen(songId: id, song: song);
            },
          ),
          GoRoute(
            path: '/album/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              final album = state.extra as Album?;
              return AlbumDetailScreen(albumId: id, album: album);
            },
          ),
          GoRoute(
            path: '/artist/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              final artist = state.extra as Artist?;
              return ArtistProfileScreen(artistId: id, artist: artist);
            },
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/offline-downloads',
            builder: (context, state) => const OfflineDownloadsScreen(),
          ),
          GoRoute(
            path: '/all-songs',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return AllSongsScreen(
                title: extra['title'] as String? ?? 'Songs',
                songs: (extra['songs'] as List?)?.cast<Song>() ?? [],
              );
            },
          ),
          GoRoute(
            path: '/all-albums',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return AllAlbumsScreen(
                title: extra['title'] as String? ?? 'Albums',
                albums: (extra['albums'] as List?)?.cast<Album>() ?? [],
              );
            },
          ),
          GoRoute(
            path: '/all-artists',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return AllArtistsScreen(
                title: extra['title'] as String? ?? 'Artists',
                artists: (extra['artists'] as List?)?.cast<Artist>() ?? [],
              );
            },
          ),
          GoRoute(
            path: '/suggest-song',
            builder: (context, state) {
              final initialName = state.extra as String?;
              return SuggestSongScreen(initialSongName: initialName);
            },
          ),
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/favorite-albums',
            builder: (context, state) => const FavoriteAlbumsScreen(),
          ),
          GoRoute(
            path: '/favorite-artists',
            builder: (context, state) => const FavoriteArtistsScreen(),
          ),
          GoRoute(
            path: '/playlists',
            builder: (context, state) => const PlaylistsScreen(),
          ),
          // Support & Complaints Routes
          GoRoute(
            path: '/support',
            builder: (context, state) => const SupportHubScreen(),
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
          GoRoute(
            path: '/support/file-complaint',
            builder: (context, state) {
              final title = state.uri.queryParameters['title'];
              final type = state.uri.queryParameters['type'];
              return FileComplaintScreen(
                initialTitle: title,
                initialContentType: type,
              );
            },
          ),
          GoRoute(
            path: '/support/my-complaints',
            builder: (context, state) => const MyComplaintsScreen(),
          ),
          GoRoute(
            path: '/playlist/:id',
            builder: (context, state) {
              final playlist = state.extra as Playlist;
              return PlaylistDetailScreen(playlist: playlist);
            },
          ),
          GoRoute(
            path: '/earnings',
            builder: (context, state) => const EarningsScreen(),
          ),
          GoRoute(
            path: '/artist-dashboard',
            builder: (context, state) => const ArtistDashboardScreen(),
          ),
          GoRoute(
            path: '/create-playlist',
            builder: (context, state) => const CreatePlaylistScreen(),
          ),
          GoRoute(
            path: '/edit-profile',
            builder: (context, state) {
              final user = state.extra as User;
              return EditProfileScreen(user: user);
            },
          ),
          GoRoute(
            path: '/artist-registration',
            builder: (context, state) => const ArtistRegistrationScreen(),
          ),
          GoRoute(
            path: '/upload-song',
            builder: (context, state) => const UploadSongScreen(),
          ),
          GoRoute(
            path: '/manage-songs',
            builder: (context, state) => const ManageSongsScreen(),
          ),
          GoRoute(
            path: '/create-album',
            builder: (context, state) => const CreateAlbumScreen(),
          ),
          GoRoute(
            path: '/bank-details',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              final payoutBloc = extra['bloc'] as PayoutBloc;
              final bankDetails = extra['details'] as ArtistBankDetails?;
              return BlocProvider.value(
                value: payoutBloc,
                child: BankDetailsScreen(existingDetails: bankDetails),
              );
            },
          ),
        ],
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
