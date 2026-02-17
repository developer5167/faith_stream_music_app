import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/library/library_bloc.dart';
import '../../blocs/library/library_state.dart';
import '../../blocs/library/library_event.dart';
import '../../utils/constants.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/mini_player_bar.dart';
import 'album_detail_screen.dart';

class FavoriteAlbumsScreen extends StatelessWidget {
  const FavoriteAlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Fav Albums')),
      bottomNavigationBar: const MiniPlayerBar(),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          if (state is LibraryAlbumsLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (state is LibraryLoaded) {
            final albums = state.favoriteAlbums;

            if (albums.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<LibraryBloc>().add(LibraryLoadFavoriteAlbums());
                await Future.delayed(const Duration(seconds: 1));
              },
              child: Column(
                children: [
                  // Header with Play All
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    child: Row(
                      children: [
                        Text(
                          '${albums.length} Albums',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Albums list
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingMd,
                      ),
                      itemCount: albums.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final album = albums[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: album.coverImageUrl != null
                                ? Image.network(
                                    album.coverImageUrl!,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    color: theme.colorScheme.surfaceVariant,
                                    child: const Icon(Icons.album),
                                  ),
                          ),
                          title: Text(
                            album.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Album • ${album.displayArtist}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AlbumDetailScreen(album: album),
                              ),
                            );
                          },
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.favorite,
                              color: AppColors.primaryBrown,
                            ),
                            onPressed: () {
                              context.read<LibraryBloc>().add(
                                LibraryRemoveAlbumFromFavorites(album.id),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${album.title} removed from favorites',
                                  ),
                                ),
                              );
                            },
                          ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.album_outlined,
            size: 100,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppSizes.paddingMd),
          const Text(
            'No Favorite Albums',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSizes.paddingSm),
          Text(
            'Albums you favorite will appear here.',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
