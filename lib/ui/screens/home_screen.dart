import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/home/home_bloc.dart';
import '../../blocs/home/home_event.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_event.dart';
import '../../blocs/library/library_bloc.dart';
import '../../blocs/library/library_event.dart';
import '../../blocs/library/library_state.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../widgets/song_card.dart';
import '../widgets/album_card.dart';
import '../widgets/artist_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_display.dart';
import 'song_detail_screen.dart';
import 'album_detail_screen.dart';
import 'artist_profile_screen.dart';
import 'search_screen.dart';
import 'all_songs_screen.dart';
import 'all_albums_screen.dart';
import 'all_artists_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.appName),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
                },
              ),
            ],
          ),
          body: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              if (state is HomeLoading) {
                return const LoadingIndicator(message: 'Loading your music...');
              }

              if (state is HomeError) {
                return ErrorDisplay(
                  message: state.message,
                  onRetry: () {
                    context.read<HomeBloc>().add(const HomeLoadRequested());
                  },
                );
              }

              if (state is HomeLoaded) {
                final feed = state.feed;

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<HomeBloc>().add(const HomeRefreshRequested());
                  },
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.paddingMd,
                    ),
                    children: [
                      // Welcome Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingMd,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              user?.name ?? 'Music Lover',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBrown,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingLg),

                      // Recently Played (if available)
                      if (feed.recentlyPlayed.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          'Recently Played',
                          onSeeAll: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllSongsScreen(
                                  title: 'Recently Played',
                                  songs: feed.recentlyPlayed,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSizes.paddingSm),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingMd,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: feed.recentlyPlayed.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: AppSizes.paddingSm),
                            itemBuilder: (context, index) {
                              final song = feed.recentlyPlayed[index];
                              return SizedBox(
                                width: 300,
                                child: BlocBuilder<LibraryBloc, LibraryState>(
                                  builder: (context, libraryState) {
                                    final isFavorite =
                                        libraryState is LibraryLoaded &&
                                        libraryState.isFavorite(song.id);

                                    return SongCard(
                                      song: song,
                                      showFavoriteButton: true,
                                      isFavorite: isFavorite,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SongDetailScreen(song: song),
                                          ),
                                        );
                                      },
                                      onPlayTap: () {
                                        context.read<PlayerBloc>().add(
                                          PlayerPlaySong(
                                            song,
                                            queue: feed.recentlyPlayed,
                                          ),
                                        );
                                      },
                                      onFavoriteTap: () {
                                        context.read<LibraryBloc>().add(
                                          LibraryToggleFavorite(song),
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingLg),
                      ],

                      // Popular Songs
                      if (feed.songs.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          'Popular Songs',
                          onSeeAll: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllSongsScreen(
                                  title: 'Popular Songs',
                                  songs: feed.songs,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSizes.paddingSm),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingMd,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: feed.songs.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: AppSizes.paddingSm),
                            itemBuilder: (context, index) {
                              final song = feed.songs[index];
                              return SizedBox(
                                width: 300,
                                child: BlocBuilder<LibraryBloc, LibraryState>(
                                  builder: (context, libraryState) {
                                    final isFavorite =
                                        libraryState is LibraryLoaded &&
                                        libraryState.isFavorite(song.id);

                                    return SongCard(
                                      song: song,
                                      showFavoriteButton: true,
                                      isFavorite: isFavorite,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SongDetailScreen(song: song),
                                          ),
                                        );
                                      },
                                      onPlayTap: () {
                                        context.read<PlayerBloc>().add(
                                          PlayerPlaySong(
                                            song,
                                            queue: feed.songs,
                                          ),
                                        );
                                      },
                                      onFavoriteTap: () {
                                        context.read<LibraryBloc>().add(
                                          LibraryToggleFavorite(song),
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingLg),
                      ],

                      // New Releases (Albums)
                      if (feed.albums.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          'New Releases',
                          onSeeAll: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllAlbumsScreen(
                                  title: 'New Releases',
                                  albums: feed.albums,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSizes.paddingSm),
                        SizedBox(
                          height: 200,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingMd,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: feed.albums.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: AppSizes.paddingSm),
                            itemBuilder: (context, index) {
                              final album = feed.albums[index];
                              return SizedBox(
                                width: 130,
                                child: AlbumCard(
                                  album: album,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AlbumDetailScreen(album: album),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingLg),
                      ],

                      // Featured Artists
                      if (feed.artists.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          'Featured Artists',
                          onSeeAll: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllArtistsScreen(
                                  title: 'Featured Artists',
                                  artists: feed.artists,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSizes.paddingSm),
                        SizedBox(
                          height: 175,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingMd,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: feed.artists.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: AppSizes.paddingSm),
                            itemBuilder: (context, index) {
                              final artist = feed.artists[index];
                              return SizedBox(
                                width: 130,
                                child: ArtistCard(
                                  artist: artist,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ArtistProfileScreen(artist: artist),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingLg),
                      ],

                      // Debug button (only in development)
                      Padding(
                        padding: const EdgeInsets.all(AppSizes.paddingMd),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final storage = context.read<StorageService>();
                            final authBloc = context.read<AuthBloc>();

                            // Clear all storage first
                            await storage.clearAll();

                            // Navigate to onboarding immediately
                            if (context.mounted) {
                              context.go('/onboarding');
                              // Then trigger logout to reset auth state
                              authBloc.add(const AuthLogoutRequested());
                            }
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset & See Onboarding'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Initial state
              return const Center(child: Text('Welcome! Pull down to refresh'));
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: const Text('See All')),
        ],
      ),
    );
  }
}
