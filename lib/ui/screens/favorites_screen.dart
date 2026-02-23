import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/library/library_bloc.dart';
import '../../blocs/library/library_state.dart';
import '../../blocs/library/library_event.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_event.dart';
import '../../utils/constants.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/song_card.dart';
import 'song_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fav Songs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBar: const MiniPlayerBar(),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          if (state is LibraryFavoritesLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (state is LibraryLoaded) {
            if (state.favorites.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<LibraryBloc>().add(LibraryLoadFavorites());
                await Future.delayed(const Duration(seconds: 1));
              },
              child: Column(
                children: [
                  // Updated Header
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    child: Row(
                      children: [
                        Text(
                          '${state.favorites.length} Songs',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (state.favorites.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<PlayerBloc>().add(
                                PlayerPlaySong(
                                  state.favorites.first,
                                  queue: state.favorites,
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBrown,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Song list
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSizes.paddingMd),
                      itemCount: state.favorites.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSizes.paddingSm),
                      itemBuilder: (context, index) {
                        final song = state.favorites[index];
                        return SongCard(
                          song: song,
                          showFavoriteButton: true,
                          isFavorite: true,
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
                              PlayerPlaySong(song, queue: state.favorites),
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
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 100,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: AppSizes.paddingMd),
            Text(
              'No Favorites Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSm),
            Text(
              'Songs you like will appear here.\nTap the heart icon on any song to add it to your favorites.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppSizes.paddingLg),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.explore),
              label: const Text('Explore Music'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
