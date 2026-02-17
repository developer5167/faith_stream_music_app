import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/library/library_bloc.dart';
import '../../blocs/library/library_event.dart';
import '../../blocs/library/library_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
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
    // Load library data on init
    context.read<LibraryBloc>().add(LibraryLoadAll());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, libraryState) {
          return CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: theme.colorScheme.background,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    'My Library',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () {
                      // Navigate to settings
                    },
                  ),
                ],
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
                              radius: 30,
                              backgroundColor: Colors.orange,
                              backgroundImage: user.profilePicUrl != null
                                  ? NetworkImage(user.profilePicUrl!)
                                  : null,
                              child: user.profilePicUrl == null
                                  ? Text(
                                      user.name.substring(0, 2).toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
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
                                  Row(
                                    children: [
                                      Text(
                                        user.phone ?? user.email,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                      // PRO Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withOpacity(0.2),
                                          border: Border.all(
                                            color: Colors.teal,
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.verified_user,
                                              size: 12,
                                              color: Colors.teal,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'PRO',
                                              style: TextStyle(
                                                color: Colors.teal,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Edit Profile
                              },
                              child: const Text(
                                'Edit',
                                style: TextStyle(color: Colors.teal),
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

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

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
                  icon: Icons.music_note_outlined,
                  title: 'Fav songs',
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
                  icon: Icons.album_outlined,
                  title: 'Fav albums',
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
                  icon: Icons.mic_external_on_outlined,
                  title: 'Fav artist',
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
                  icon: Icons.playlist_play_outlined,
                  title: 'Playlist',
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
    );
  }

  Widget _buildCategoryItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: [
              Icon(icon, size: 28, color: theme.colorScheme.onBackground),
              const SizedBox(width: 20),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                count.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onBackground.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
