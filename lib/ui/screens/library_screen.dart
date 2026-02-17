import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/library/library_bloc.dart';
import '../../blocs/library/library_event.dart';
import '../../blocs/library/library_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../config/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_display.dart';
import 'favorites_screen.dart';
import 'playlists_screen.dart';
import 'favorite_artists_screen.dart';
import 'favorite_albums_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LibraryBloc>().add(LibraryLoadAll());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocBuilder<LibraryBloc, LibraryState>(
          builder: (context, libraryState) {
            return CustomScrollView(
              slivers: [
                // Header
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                    title: Text(
                      'My Library',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),

                // Profile Section
                SliverToBoxAdapter(
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, authState) {
                      if (authState is AuthAuthenticated) {
                        final user = authState.user;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: AppTheme.darkPrimary,
                                backgroundImage:
                                    user.profilePicUrl != null &&
                                        user.profilePicUrl!.isNotEmpty
                                    ? NetworkImage(user.profilePicUrl!)
                                    : null,
                                child:
                                    user.profilePicUrl == null ||
                                        user.profilePicUrl!.isEmpty
                                    ? Text(
                                        user.name.substring(0, 2).toUpperCase(),
                                        style: TextStyle(
                                          color: theme.colorScheme.surface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.phone ?? user.email,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.6),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.darkPrimary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.darkPrimary,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: AppTheme.darkPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Library Categories
                if (libraryState is LibraryLoading)
                  const SliverFillRemaining(
                    child: Center(child: LoadingIndicator()),
                  )
                else if (libraryState is LibraryError)
                  SliverFillRemaining(
                    child: ErrorDisplay(
                      message: libraryState.message,
                      onRetry: () {
                        context.read<LibraryBloc>().add(LibraryLoadAll());
                      },
                    ),
                  )
                else if (libraryState is LibraryLoaded) ...[
                  _buildCategoryItem(
                    context,
                    icon: Icons.favorite_rounded,
                    iconColor: Colors.pinkAccent,
                    title: 'Favorite Songs',
                    count: libraryState.favorites.length,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoritesScreen(),
                        ),
                      );
                    },
                  ),
                  _buildCategoryItem(
                    context,
                    icon: Icons.album_rounded,
                    iconColor: Colors.orangeAccent,
                    title: 'Albums',
                    count: libraryState.favoriteAlbums.length,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoriteAlbumsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildCategoryItem(
                    context,
                    icon: Icons.person_rounded,
                    iconColor: Colors.blueAccent,
                    title: 'Artists',
                    count: libraryState.favoriteArtists.length,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoriteArtistsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildCategoryItem(
                    context,
                    icon: Icons.playlist_play_rounded,
                    iconColor: Colors.greenAccent,
                    title: 'Playlists',
                    count: libraryState.playlists.length,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlaylistsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                count.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.38),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurface.withOpacity(0.24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
