import 'package:faith_stream_music_app/blocs/player/player_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/home/home_bloc.dart';
import '../../blocs/home/home_event.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_event.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../config/app_theme.dart';
import '../widgets/premium_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_display.dart';
import 'song_detail_screen.dart';
import 'album_detail_screen.dart';
import 'artist_profile_screen.dart';
import 'search_screen.dart';
import 'all_songs_screen.dart';
import 'all_albums_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              AppStrings.appName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: theme.colorScheme.onSurface),
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
                icon: Icon(Icons.logout, color: theme.colorScheme.onSurface),
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
                },
              ),
            ],
          ),
          body: BlocListener<PlayerBloc, PlayerState>(
            listenWhen: (previous, current) {
              String? prevId;
              String? currId;

              if (previous is PlayerPlaying) prevId = previous.song.id;
              if (previous is PlayerPaused) prevId = previous.song.id;
              if (previous is PlayerLoading) prevId = previous.song?.id;

              if (current is PlayerPlaying) currId = current.song.id;
              if (current is PlayerPaused) currId = current.song.id;
              if (current is PlayerLoading) currId = current.song?.id;

              return currId != null && currId != prevId;
            },
            listener: (context, state) {
              context.read<HomeBloc>().add(const HomeRefreshRequested());
            },
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                if (state is HomeLoading) {
                  return const LoadingIndicator(
                    message: 'Loading your music...',
                  );
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
                      context.read<HomeBloc>().add(
                        const HomeRefreshRequested(),
                      );
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
                                    'Good evening,',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                        ),
                                  ),
                                  Text(
                                    user?.name ?? 'Music Lover',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.darkPrimary,
                                        ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideX(begin: -0.1),
                        const SizedBox(height: AppSizes.paddingLg),

                        // Recently Played
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
                            height: 230,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.paddingMd,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: feed.recentlyPlayed.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: AppSizes.paddingMd),
                              itemBuilder: (context, index) {
                                final song = feed.recentlyPlayed[index];
                                return PremiumCard(
                                  title: song.title,
                                  subtitle: song.displayArtist,
                                  imageUrl: song.coverImageUrl,
                                  width: 150,
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
                                ).animate().fadeIn(delay: (index * 50).ms);
                              },
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingLg),
                        ],

                        // Popular Songs
                        if (feed.songs.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            'Trending Now',
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
                            height: 230,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.paddingMd,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: feed.songs.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: AppSizes.paddingMd),
                              itemBuilder: (context, index) {
                                final song = feed.songs[index];
                                return PremiumCard(
                                  title: song.title,
                                  subtitle: song.displayArtist,
                                  imageUrl: song.coverImageUrl,
                                  width: 150,
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
                                      PlayerPlaySong(song, queue: feed.songs),
                                    );
                                  },
                                ).animate().fadeIn(delay: (index * 50).ms);
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
                            height: 230,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.paddingMd,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: feed.albums.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: AppSizes.paddingMd),
                              itemBuilder: (context, index) {
                                final album = feed.albums[index];
                                return PremiumCard(
                                  title: album.title,
                                  subtitle: album.displayArtist,
                                  imageUrl: album.coverImageUrl,
                                  width: 150,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AlbumDetailScreen(album: album),
                                      ),
                                    );
                                  },
                                ).animate().fadeIn(delay: (index * 50).ms);
                              },
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingLg),
                        ],

                        // Featured Artists
                        if (feed.artists.isNotEmpty) ...[
                          _buildSectionHeader(context, 'Your Favorite Artists'),
                          const SizedBox(height: AppSizes.paddingSm),
                          SizedBox(
                            height: 210,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.paddingMd,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: feed.artists.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: AppSizes.paddingMd),
                              itemBuilder: (context, index) {
                                final artist = feed.artists[index];
                                return PremiumCard(
                                  title: artist.name,
                                  subtitle: 'Artist',
                                  imageUrl: artist.profilePicUrl,
                                  width: 130,
                                  isCircle: true,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ArtistProfileScreen(artist: artist),
                                      ),
                                    );
                                  },
                                ).animate().fadeIn(delay: (index * 50).ms);
                              },
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingLg),
                        ],

                        // Debug button
                        Padding(
                          padding: const EdgeInsets.all(AppSizes.paddingMd),
                          child: TextButton.icon(
                            onPressed: () async {
                              final storage = context.read<StorageService>();
                              final authBloc = context.read<AuthBloc>();
                              await storage.clearAll();
                              if (context.mounted) {
                                context.go('/onboarding');
                                authBloc.add(const AuthLogoutRequested());
                              }
                            },
                            icon: Icon(
                              Icons.refresh,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.38,
                              ),
                            ),
                            label: Text(
                              'Reset App',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.38,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return const Center(
                  child: Text('Welcome! Pull down to refresh'),
                );
              },
            ),
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
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See All',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.darkPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
